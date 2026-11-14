@abstract
class_name SessionTransport
extends RefCounted
## Canal de mensajes entre el anfitrión y los jugadores. Los mensajes son diccionarios de primitivos.
## El anfitrión tiene siempre peer_id 1 (como en ENet).


# Las señales las emiten las implementaciones concretas, no esta clase base.
@warning_ignore("unused_signal")
signal peer_connected(peer_id: int)
@warning_ignore("unused_signal")
signal peer_disconnected(peer_id: int)
@warning_ignore("unused_signal")
signal message_received(peer_id: int, message: Dictionary)

@abstract func is_host() -> bool
@abstract func local_peer_id() -> int
## peer_id 0 = a todos los demás.
@abstract func send(peer_id: int, message: Dictionary, is_reliable: bool) -> void
## Se llama una vez por frame desde el dueño de la sesión.
@abstract func poll() -> void
@abstract func close() -> void
