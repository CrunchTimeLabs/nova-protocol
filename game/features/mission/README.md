# mission

## Propósito
Misiones cooperativas para jugar en pantalla dividida (o LAN): Órbita (piloto + estación) y Circuito (rotador + intercambiador).

## Escenarios
- DADO el lobby CUANDO se elige misión y modo ENTONCES se crea el laboratorio de la misión (pantalla dividida por defecto).
- DADO un rol CUANDO envía un comando de otro rol ENTONCES se rechaza (`OrbitMatch`, `CircuitMatch`).
- DADO una sesión CUANDO se completa el objetivo ENTONCES la misión termina (`MissionSession`).

## Qué reutilizar
- `MissionSession`, `SessionOptions`, `OrbitMatch`, `CircuitMatch`, `SplitScreen`, `MissionLobby`.

## Depende de
`toolkit/session`, `net`, `dynamics`, `puzzle`, `circuit`.

## Cubierto por
Lab `Split screen`; `tests/features/mission/`.
