-- Purchase Order Studio v5 - concurrencia segura para múltiples usuarios
-- Ejecutar completo en Supabase > SQL Editor.
create table if not exists public.po_sequence (id int primary key default 1, last_group bigint not null default 0);
insert into public.po_sequence(id,last_group) values(1,0) on conflict(id) do nothing;

create table if not exists public.po_items (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  order_token uuid,
  group_no bigint not null,
  seller text not null,
  buyer text not null,
  supplier_id text not null,
  supplier_name text not null,
  currency text not null,
  product_id text not null,
  description text not null,
  qty numeric not null,
  cost numeric not null,
  total numeric not null,
  local_id text not null,
  alias text not null,
  note text default '',
  open_po text default '',
  emergency text default '',
  pc_code text default ''
);
alter table public.po_items add column if not exists order_token uuid;
create index if not exists po_items_order_token_idx on public.po_items(order_token);

-- Solo informa cuál sería el siguiente grupo. NO lo reserva.
create or replace function public.peek_next_po_group()
returns bigint language sql security definer set search_path=public as $$
  select last_group + 1 from public.po_sequence where id=1;
$$;

-- Inserta una línea y asigna/resuelve el grupo dentro de una única transacción.
-- El UPDATE bloquea po_sequence: dos usuarios que guardan al mismo tiempo no pueden recibir el mismo grupo.
-- Las líneas posteriores con el mismo order_token conservan el grupo ya asignado.
create or replace function public.add_po_item_atomic(
 p_order_token uuid, p_seller text, p_buyer text, p_supplier_id text, p_supplier_name text,
 p_currency text, p_product_id text, p_description text, p_qty numeric, p_cost numeric,
 p_total numeric, p_local_id text, p_alias text, p_note text, p_open_po text,
 p_emergency text, p_pc_code text
) returns bigint language plpgsql security definer set search_path=public as $$
declare g bigint;
begin
  select group_no into g from public.po_items where order_token=p_order_token order by id limit 1;
  if g is null then
    update public.po_sequence set last_group=last_group+1 where id=1 returning last_group into g;
  end if;
  insert into public.po_items(order_token,group_no,seller,buyer,supplier_id,supplier_name,currency,product_id,description,qty,cost,total,local_id,alias,note,open_po,emergency,pc_code)
  values(p_order_token,g,p_seller,p_buyer,p_supplier_id,p_supplier_name,p_currency,p_product_id,p_description,p_qty,p_cost,p_total,p_local_id,p_alias,coalesce(p_note,''),coalesce(p_open_po,''),coalesce(p_emergency,''),coalesce(p_pc_code,''));
  return g;
end $$;

-- Solo vuelve a 0 cuando no queda ninguna línea del lote.
-- No reutiliza huecos intermedios: 1,2,3 y borrar 2 => el siguiente sigue siendo 4.
create or replace function public.reset_po_group_if_empty()
returns boolean language plpgsql security definer set search_path=public as $$
begin
  if exists(select 1 from public.po_items limit 1) then return false; end if;
  update public.po_sequence set last_group=0 where id=1;
  return true;
end $$;

grant execute on function public.peek_next_po_group() to anon, authenticated;
grant execute on function public.add_po_item_atomic(uuid,text,text,text,text,text,text,text,numeric,numeric,numeric,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.reset_po_group_if_empty() to anon, authenticated;

alter table public.po_items enable row level security;
drop policy if exists "po read" on public.po_items;
drop policy if exists "po insert" on public.po_items;
drop policy if exists "po delete" on public.po_items;
create policy "po read" on public.po_items for select to anon, authenticated using (true);
-- La inserción normal queda disponible por RPC security definer. Se conserva insert para compatibilidad.
create policy "po insert" on public.po_items for insert to anon, authenticated with check (true);
create policy "po delete" on public.po_items for delete to anon, authenticated using (true);
grant select,insert,delete on public.po_items to anon, authenticated;
grant usage,select on sequence public.po_items_id_seq to anon, authenticated;

-- Realtime: además activa la tabla po_items en Database > Replication si tu proyecto no la añade automáticamente.
do $$ begin
  alter publication supabase_realtime add table public.po_items;
exception when duplicate_object then null;
end $$;
