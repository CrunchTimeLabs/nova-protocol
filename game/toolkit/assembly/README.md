# assembly

## Propósito
Montaje por ranuras: una lista ordenada de ranuras, cada una acepta piezas de una sola categoría.

## Escenarios
- DADO una ranura CUANDO se coloca una pieza de su categoría ENTONCES se acepta (sustituye lo que hubiera); de otra categoría se rechaza.
- DADO una ranura llena CUANDO se quita ENTONCES devuelve la pieza y queda vacía.
- DADO todas las ranuras llenas CUANDO se consulta ENTONCES `is_complete`.
- DADO un montaje CUANDO se guarda y se carga por JSON ENTONCES queda igual.

## Qué reutilizar
- `SlotAssembly` (`place`, `remove`, `item_at`, `slot_for`, `is_complete`, `clear`, `snapshot`/`restore`, señal `changed`). Nuevo: `CargoHold` limita por masa sin orden ni categorías por hueco.

## Depende de
Nada.

## Cubierto por
Lab `Nave`; `tests/toolkit/assembly/`.
