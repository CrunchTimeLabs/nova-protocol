# maze

## Propósito
Laberinto en cuadrícula con semilla, con entrada a la izquierda, salida a la derecha y algunos bucles.

## Escenarios
- DADO una semilla CUANDO se genera ENTONCES todo es alcanzable desde la entrada (`reachable_from`).
- DADO una celda y una dirección CUANDO hay muro ENTONCES no se puede pasar (`has_wall`).
- DADO un tamaño de celda CUANDO se piden los muros ENTONCES se devuelven como rectángulos para dibujar y colisionar (`wall_rects`).
- DADO un derrumbe CUANDO cae ENTONCES tapa el paso unos segundos y nunca deja la celda protegida sin camino a la salida (`MazeCaveIns`).
- DADO pasos "de frente" y `front_chance` CUANDO toca un derrumbe ENTONCES con esa probabilidad intenta primero taparlos (pueden estar pegados a la celda protegida), si no, cae al azar.

## Qué reutilizar
- `Maze` (`generate`, `entrance`, `exit_cell`, `wall_rects`).
- `MazeCaveIns`: derrumbes temporales al azar (con semilla) sobre un `Maze` sin modificarlo; nunca tapan junto a la celda protegida ni le cortan el camino a la salida (`tick` con pasos de frente opcionales, `drop` para quien lleva su propio ritmo, `expire`, `block`, `block_in_front`, `passage_rect`, `is_blocked`, `has_passage`, `distances_from`, `path_between`, `rect_of`). Nuevo porque `Maze` es estático y lo usan otros labs tal cual.

## Depende de
`GameRandom` (core).

## Cubierto por
Labs `Maze` y `Recolección`; `tests/toolkit/maze/`.
