# inventory

## Propósito
Bodega con capacidad por masa (`CargoHold`) y almacén de cantidades por tipo (`Tally`).

## Escenarios
- DADO una bodega con capacidad CUANDO se añade un objeto que no cabe ENTONCES se rechaza (`add` devuelve false).
- DADO objetos cargados CUANDO se quita uno ENTONCES se libera su masa.
- DADO un cambio de capacidad CUANDO ya hay carga ENTONCES no se expulsa nada, solo cambia qué más cabe.
- DADO un almacén CUANDO se suma una cantidad positiva ENTONCES crece su tipo y el total; cero o negativo se rechaza (`Tally`).

## Qué reutilizar
- `CargoHold` (`can_add`, `add`, `remove`, `used`, `free_capacity`, señal `changed`).
- `Tally` (`add`, `count`, `total`, `snapshot`/`restore`, señal `changed`): cuenta por clave entera sin capacidad. Nuevo porque `CargoHold` limita por masa y guarda objetos, no cantidades.

## Depende de
Nada.

## Cubierto por
Labs `Cargo hold` y `Recolección`; `tests/toolkit/inventory/`.
