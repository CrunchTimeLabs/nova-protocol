class_name OrbitCommand
extends RefCounted
## Comandos de la misión de órbita. Viajan como enteros en `Command.kind`.


## PHASE_HOLD {"on": bool}: la estación mantiene (o suelta) el salto de fase de la nave del piloto.
enum Kind { SET_THRUST, PHASE_HOLD }
