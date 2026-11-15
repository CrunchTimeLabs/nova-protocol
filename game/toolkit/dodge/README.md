# dodge

## Propósito
Campo de esquivar: una nave dentro de un recuadro de tamaño dado y rocas que cruzan con una frecuencia configurable; los golpes restan casco.

## Escenarios
- DADO un campo CUANDO avanza el progreso (0..1) ENTONCES las rocas caen más seguido y más rápido (curva del original), a partir de la mitad a veces en pareja y con deriva vertical; la densidad baja la frecuencia. Las rocas giran (`DodgeField`).
- DADO una roca CUANDO toca la nave sin protección ENTONCES resta casco una vez y da invulnerabilidad; la nave no sale del campo.
- DADO un campo CUANDO el casco llega a 0 ENTONCES se destruye; si pasa `duration` ENTONCES llega; terminado, ya no cambia.
- DADO la misma semilla y los mismos movimientos ENTONCES el resultado es el mismo.
- DADO `wind` > 0 CUANDO pasa el intervalo ENTONCES nace una onda expansiva fuera del borde izquierdo o derecho que crece y golpea una sola vez a la nave al alcanzarla (`DodgeWave`); `wave_warning` indica que hay una en camino.

## Qué reutilizar
- `DodgeField` (entidad, tamaño y densidad como parámetros), `DodgeRock`, `DodgeWave` (viento solar), y la vista `DodgeView`.
- No reutiliza `Flight`/`FlightHazards` de la Expedición: son de una feature, piden `Expedition` y un campo fijo de 1280×760; tampoco `FlightHazards.Wave` por lo mismo (alcance como parámetro aquí).

## Depende de
`toolkit/core` (`GameRandom`, `ResourceMeter`), `toolkit/movement` (`MovementBody`, `ManualController`).

## Cubierto por
Nivel `app/levels/meteor_mission.gd`; `tests/toolkit/dodge/`.
