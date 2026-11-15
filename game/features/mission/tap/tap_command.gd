class_name TapCommand
extends RefCounted
## Comandos de la misión Tap. Viajan como enteros en `Command.kind`.


## SPAWN: el emisor pide un popup (sin posición). HIT: el receptor pulsó el popup `{"id"}`.
enum Kind { SPAWN, HIT }
