# mission

## Propósito
Misiones cooperativas para jugar en pantalla dividida (o LAN): Órbita (piloto + estación) y Circuito (rotador + intercambiador).

## Escenarios
- DADO el lobby CUANDO se elige misión y modo ENTONCES se crea el laboratorio de la misión (pantalla dividida por defecto).
- DADO un rol CUANDO envía un comando de otro rol ENTONCES se rechaza (`OrbitMatch`, `CircuitMatch`).
- DADO una sesión CUANDO se completa el objetivo ENTONCES la misión termina (`MissionSession`).
- DADO la estación CUANDO mantiene F en el nivel Meteoritos ENTONCES `OrbitMatch` publica `phase_held` y la nave del piloto hace el salto de fase (`OrbitCommand.PHASE_HOLD`).

## Qué reutilizar
- `MissionSession`, `SessionOptions`, `OrbitMatch`, `CircuitMatch`, `SplitScreen`, `MissionLobby`.

## Depende de
`toolkit/session`, `net`, `dynamics`, `puzzle`, `circuit`.

## Cubierto por
Lab `Split screen` y nivel `app/levels/meteor_mission.gd` (Órbita con el piloto esquivando meteoritos, de `toolkit/dodge`, y un `SplitHud`); `tests/features/mission/`.
