class_name OrbitCommand
extends RefCounted
## Comandos de la misión de órbita. Viajan como enteros en `Command.kind`.


## PHASE_HOLD {"on": bool}: la estación mantiene (o suelta) el salto de fase de la nave del piloto.
## REPORT_CRASH: el piloto avisa de que su nave se quedó sin casco (la partida se pierde).
enum Kind { SET_THRUST, PHASE_HOLD, REPORT_CRASH }
