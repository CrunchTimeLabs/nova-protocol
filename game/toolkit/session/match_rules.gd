@abstract
class_name MatchRules
extends RefCounted
## Contrato de las reglas de una partida compartida. El anfitrión las usa sin saber de qué juego son.
## Todo valor que llega en un comando es no confiable: `apply` lo valida y devuelve false si no es válido.


## Aplica el comando de un jugador. false si el contenido no es válido (el estado no cambia).
@abstract func apply(slot: int, command: Command) -> bool
## Avanza un paso fijo de `delta` segundos.
@abstract func step(delta: float) -> void
## El jugador se fue: sus órdenes en curso dejan de valer.
@abstract func release_slot(slot: int) -> void
@abstract func snapshot() -> Dictionary
@abstract func restore(saved: Dictionary) -> void
