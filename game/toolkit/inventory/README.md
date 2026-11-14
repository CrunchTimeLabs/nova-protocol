# inventory

## Propósito
Bodega con capacidad por masa.

## Escenarios
- DADO una bodega con capacidad CUANDO se añade un objeto que no cabe ENTONCES se rechaza (`add` devuelve false).
- DADO objetos cargados CUANDO se quita uno ENTONCES se libera su masa.
- DADO un cambio de capacidad CUANDO ya hay carga ENTONCES no se expulsa nada, solo cambia qué más cabe.

## Qué reutilizar
- `CargoHold` (`can_add`, `add`, `remove`, `used`, `free_capacity`, señal `changed`).

## Depende de
Nada.

## Cubierto por
Lab `Cargo hold`; `tests/toolkit/inventory/`.
