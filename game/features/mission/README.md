# mission

## Propósito
Misiones cooperativas para jugar en pantalla dividida (o LAN): Órbita (piloto + estación) y Circuito (rotador + intercambiador).

## Escenarios
- DADO el lobby CUANDO se elige misión y modo ENTONCES se crea el laboratorio de la misión (pantalla dividida por defecto).
- DADO un rol CUANDO envía un comando de otro rol ENTONCES se rechaza (`OrbitMatch`, `CircuitMatch`).
- DADO una sesión CUANDO se completa el objetivo ENTONCES la misión termina (`MissionSession`).
- DADO la estación CUANDO mantiene F en el nivel Meteoritos ENTONCES `OrbitMatch` publica `phase_held` y la nave del piloto hace el salto de fase (`OrbitCommand.PHASE_HOLD`).

- DADO la nave de la estación CUANDO cruza `OrbitMatch.MOON_GOAL_RADIUS` alrededor de la luna ENTONCES se gana; si el casco del piloto (`REPORT_CRASH`) o el combustible llegan a cero antes, o la nave sale del mapa [0, 1] (`ESCAPE_MARGIN`), se pierde; resuelto, la simulación se congela y ambos lados ven `outcome`.
## Qué reutilizar
- `MissionSession`, `SessionOptions`, `OrbitMatch`, `CircuitMatch`, `SplitScreen`, `MissionLobby`.

## Depende de
`toolkit/session`, `net`, `dynamics`, `puzzle`, `circuit`.

## Cubierto por
Lab `Split screen` y nivel `app/levels/meteor_mission.gd` (Órbita con el piloto esquivando meteoritos, de `toolkit/dodge`, y un `SplitHud`); `tests/features/mission/`.
