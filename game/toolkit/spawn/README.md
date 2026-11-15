# spawn

## Propósito
Objetos que aparecen en casillas con un ritmo al azar (semilla), con máximo a la vez, y caducan solos.

## Escenarios
- DADO el intervalo CUANDO pasa el tiempo ENTONCES `tick` avisa que toca uno (no si está lleno).
- DADO una casilla ocupada o vida no positiva CUANDO se añade ENTONCES se rechaza.
- DADO uno con vida CUANDO se agota ENTONCES desaparece; `take` lo retira una sola vez.

## Qué reutilizar
- `TimedSpawns` (`tick`, `expire`, `add`, `at`, `take`, señal `expired`). Nuevo: no había aparición temporal de objetos en el toolkit.

## Depende de
`GameRandom` (core).

## Cubierto por
Lab `Recolección`; `tests/toolkit/spawn/`.
