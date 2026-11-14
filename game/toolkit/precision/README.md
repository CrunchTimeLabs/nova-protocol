# precision

## Propósito
Parada de precisión: una marca oscila y se detiene con un toque; más cerca del centro, mejor nota.

## Escenarios
- DADO una marca oscilando CUANDO se detiene ENTONCES la nota depende de la distancia al centro (`Grade`).
- DADO una nota CUANDO se pide el multiplicador ENTONCES se obtiene según la zona.
- DADO usos previos CUANDO se crea una parada nueva ENTONCES oscila más rápido.

## Qué reutilizar
- `PrecisionStop` (`advance`, `stop`, `grade`, `multiplier`).

## Depende de
Nada.

## Cubierto por
Lab `Precision`; `tests/toolkit/precision/`.
