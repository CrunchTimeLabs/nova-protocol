# dodge

## Propósito
Campo de esquivar: una nave dentro de un recuadro de tamaño dado y rocas que cruzan con una frecuencia configurable; los golpes restan casco.

## Escenarios
- DADO un campo CUANDO pasa el tiempo ENTONCES nacen rocas a una frecuencia que baja con la densidad y se mueven a la izquierda (`DodgeField`).
- DADO una roca CUANDO toca la nave sin protección ENTONCES resta casco una vez y da invulnerabilidad; la nave no sale del campo.
- DADO un campo CUANDO el casco llega a 0 ENTONCES se destruye; si pasa `duration` ENTONCES llega; terminado, ya no cambia.
- DADO la misma semilla y los mismos movimientos ENTONCES el resultado es el mismo.

## Qué reutilizar
- `DodgeField` (entidad, tamaño y densidad como parámetros), `DodgeRock`, y la vista `DodgeView`.
- No reutiliza `Flight`/`FlightHazards` de la Expedición: son de una feature, piden `Expedition` y un campo fijo de 1280×760.

## Depende de
`toolkit/core` (`GameRandom`, `ResourceMeter`), `toolkit/movement` (`MovementBody`, `ManualController`).

## Cubierto por
Nivel `app/levels/meteor_mission.gd`; `tests/toolkit/dodge/`.
