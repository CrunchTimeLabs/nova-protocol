# foundry_temperature

## Propósito
(Distinta de `features/foundry`, el minijuego de teclear minerales: aquí se estabiliza una temperatura.) Laboratorio simple para evaluar la mecánica de estabilizar una temperatura: una aguja inestable, un objetivo anunciado y 20 s para lograr cuantas estabilizaciones se pueda.

## Escenarios
- DADO el lab CUANDO empieza ENTONCES se anuncia un objetivo (mensaje y rango en el reloj) (`TemperatureTargets`).
- DADO la aguja dentro del rango CUANDO se mantiene `HOLD_SECONDS` ENTONCES suma un acierto y se anuncia otro objetivo (`TemperatureState`).
- DADO la aguja fuera del rango ENTONCES el foco se pone en rojo, el progreso se congela y se avisa cada `ALERT_INTERVAL` hacia dónde corregir; al volver, continúa.
- DADO que pasan 20 s ENTONCES la partida termina y se muestran los aciertos; `R` reinicia.

## Qué reutilizar
- `TemperatureState` (orquestador), `TemperatureTargets` (objetivos con semilla) y la vista `TemperaturePanel`.
- Constantes ajustables: `PLAYER_RATE`, `HOLD_SECONDS`, `ALERT_INTERVAL`, `MATCH_SECONDS`, `TARGET_INTERVAL`, `TARGET_RANGES`.

## Depende de
`toolkit/thermal` (`UnstableGauge`, `DialView`), `toolkit/core` (`GameRandom`, `ResourceMeter`, `MessageLog`, `MeterBar`), `toolkit/time` (`Countdown`), `toolkit/ui` (`StatusLamp`).

## Cubierto por
Lab «Fundición temperatura» (`app/labs/foundry_temperature.gd`); `tests/features/foundry_temperature/`.
