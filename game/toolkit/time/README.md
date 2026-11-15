# time

## Propósito
Tiempo de juego sin nodos: cuenta atrás, ciclo de pasos con duración, semáforo y suceso con probabilidad por ventana.

## Escenarios
- DADO un contador CUANDO pasa el intervalo ENTONCES baja un paso hasta llegar a 0 (`Countdown`).
- DADO un ciclo de pasos CUANDO se acumula la duración de uno ENTONCES avanza al siguiente (`TimedCycle`).
- DADO una ventana de tiempo y una probabilidad CUANDO empieza la ventana ENTONCES se decide si habrá un suceso y en qué momento al azar; como mucho uno por ventana (`ChanceWindow`).
- DADO un semáforo CUANDO pasan 3 s por luz ENTONCES va rojo → amarillo → verde → rojo (`TrafficLight`).

## Qué reutilizar
- `Countdown`, `TimedCycle`, `TrafficLight`.
- `ChanceWindow` (`tick`, `time_to_event`). Nuevo porque `TimedCycle` y `Countdown` son de ritmo fijo, sin probabilidad ni momento al azar.

## Depende de
Nada.

## Cubierto por
Labs `Countdown`, `Traffic light` y `Recolección`; `tests/toolkit/time/`.
