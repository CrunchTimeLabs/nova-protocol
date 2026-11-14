# maze

## Propósito
Laberinto en cuadrícula con semilla, con entrada a la izquierda, salida a la derecha y algunos bucles.

## Escenarios
- DADO una semilla CUANDO se genera ENTONCES todo es alcanzable desde la entrada (`reachable_from`).
- DADO una celda y una dirección CUANDO hay muro ENTONCES no se puede pasar (`has_wall`).
- DADO un tamaño de celda CUANDO se piden los muros ENTONCES se devuelven como rectángulos para dibujar y colisionar (`wall_rects`).

## Qué reutilizar
- `Maze` (`generate`, `entrance`, `exit_cell`, `wall_rects`).

## Depende de
`GameRandom` (core).

## Cubierto por
Lab `Maze`; `tests/toolkit/maze/`.
