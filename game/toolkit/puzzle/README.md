# puzzle

## Propósito
Tablero de tuberías: piezas que se giran o intercambian para llevar energía de fuentes a destinos.

## Escenarios
- DADO un tablero generado con semilla CUANDO se crea ENTONCES tiene solución garantizada y rotaciones desordenadas (`PipeBoardGenerator`).
- DADO una pieza CUANDO se gira ENTONCES cambia por qué lados conecta (`PipeTile`).
- DADO un tablero CUANDO todas las fuentes alcanzan todos los destinos ENTONCES está resuelto (`PipeBoard`).

## Qué reutilizar
- `PipeBoard`, `PipeBoardGenerator`, `PipeBoardConfig`, `PipeTile`, `PipeTerminal`; vista `PipeBoardView`.

## Depende de
Nada.

## Cubierto por
Lab `Wiring`; `tests/toolkit/puzzle/`.
