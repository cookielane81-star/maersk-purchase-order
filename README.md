# Purchase Order Studio v5

Versión preparada para trabajo simultáneo de múltiples usuarios con GitHub Pages + Supabase.

## Qué cambia en v5
- El número mostrado antes de guardar es **Grupo previsto**; no está reservado.
- Al agregar el primer ítem, Supabase asigna el grupo **atómicamente**. Si otro usuario tomó ese número mientras llenabas el formulario, tu orden recibe automáticamente el siguiente.
- Todos los ítems posteriores de esa misma orden conservan el grupo asignado mediante `order_token`.
- La bandeja se actualiza mediante **Supabase Realtime** y además tiene sincronización de respaldo cada 30 s.
- No se reutilizan huecos intermedios durante un lote. Si existen 1,2,3 y se borra 2, el siguiente es 4.
- Si la bandeja queda completamente vacía, la secuencia puede volver a 1.
- La exportación conserva la renumeración del Excel desde 1 y limpia las líneas exportadas.

## Configuración
1. Crea/abre tu proyecto Supabase.
2. Ejecuta completo `reference/supabase_setup.sql` en SQL Editor.
3. En `data/config.js`, pega `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
4. Prueba con Live Server en dos ventanas/navegadores.
5. Después publica la carpeta en GitHub Pages.

## Prueba de concurrencia recomendada
Abre la web en 3 navegadores. Los tres pueden ver, por ejemplo, `Grupo previsto 2`. Guarda primero en A: recibe 2. Guarda después en B: recibe 3. Guarda en C: recibe 4. Ninguno debe sobrescribir al otro.

## Próxima etapa
Agregar Supabase Auth y `created_by` para que cada usuario solo pueda modificar/eliminar sus propias líneas, con rol administrador para exportación y gestión global.

## v6 — Orden activa y múltiples líneas por grupo
- El primer ítem confirma/reserva el grupo.
- La orden queda ACTIVA y los siguientes ítems conservan el mismo `order_token` y grupo.
- La cabecera se bloquea mientras la orden está activa para evitar mezclar comprador, proveedor, moneda, local o PC dentro de una misma OC.
- Producto, descripción, cantidad y costo siguen disponibles para añadir tantas líneas como sean necesarias.
- `Finalizar y crear nueva orden` cierra la orden activa y prepara un nuevo grupo previsto.
- En Supabase, `add_po_item_atomic` ya conserva el grupo para todas las líneas con el mismo `order_token` y asigna el grupo de forma atómica para la primera línea.


## Actualización: Moneda y Alias / PC por línea
- `PC / Analítica` de la web corresponde a `Alias` en el Excel de salida.
- `Moneda` y `Alias / PC Analítica` ahora pertenecen al detalle de cada línea y pueden variar dentro del mismo Grupo.
- Al activar una orden, estos dos campos permanecen editables; la cabecera de la OC continúa bloqueada.
- La exportación conserva cada Alias en la columna `Alias` y cada moneda en `Id Moneda`.


## v8 — Moneda por orden y Alias por línea
- `Moneda` vuelve a ser un dato de cabecera: una OC/grupo utiliza una sola moneda.
- Al confirmar el primer ítem, la moneda queda bloqueada junto con el resto de la cabecera hasta finalizar la orden.
- `Alias / PC Analítica` continúa siendo un dato por línea y puede cambiar dentro del mismo grupo.
- Después de agregar cada ítem, el selector de Alias / PC se limpia y obliga a seleccionar explícitamente el Alias de la siguiente línea; no se reutiliza silenciosamente el anterior.
- En el Excel, todas las líneas de un grupo conservan la moneda de la orden y cada línea exporta su Alias individual.


## Cambios v9
- Producto se muestra como selector buscable con flecha desplegable visible.
- Al abrir el selector se muestran las opciones del catálogo de productos.
- Al elegir un producto, su concepto actualiza automáticamente el campo Descripción.
- Producto y Descripción se limpian después de agregar cada línea para obligar una nueva selección en la siguiente línea.
- La descripción queda editable después de autocompletarse para permitir el texto específico solicitado por el comprador.

## v10 — actualización visual Maersk
- Branding actualizado con el logo proporcionado por el usuario.
- Sistema visual corporativo más limpio y profesional.
- Botones rediseñados y alineados con alturas consistentes.
- Mejoras de espaciado, tarjetas, formularios, tablas, estados hover/focus y modo oscuro.
- No se modificó la lógica funcional de la v9.
