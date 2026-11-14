# time

## Propósito
Tiempo de juego sin nodos: cuenta atrás, ciclo de pasos con duración y semáforo.

## Escenarios
- DADO un contador CUANDO pasa el intervalo ENTONCES baja un paso hasta llegar a 0 (`Countdown`).
- DADO un ciclo de pasos CUANDO se acumula la duración de uno ENTONCES avanza al siguiente (`TimedCycle`).
- DADO un semáforo CUANDO pasan 3 s por luz ENTONCES va rojo → amarillo → verde → rojo (`TrafficLight`).

## Qué reutilizar
- `Countdown`, `TimedCycle`, `TrafficLight`.

## Depende de
Nada.

## Cubierto por
Labs `Countdown` y `Traffic light`; `tests/toolkit/time/`.
