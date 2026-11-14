class_name LossyTransport
extends SessionTransport
## Decorador de pruebas de robustez: pierde, duplica y retrasa mensajes (con azar de semilla, así es reproducible).
## Los mensajes fiables no se pierden ni se duplican, pero sí se retrasan y pueden llegar desordenados.


var loss_probability: float
var duplicate_probability: float
## Un mensaje espera entre 0 y esto `poll()`s antes de salir.
var max_delay_polls: int

var _inner: SessionTransport
var _random: GameRandom
var _queue: Array[Dictionary] = []


func _init(
        p_inner: SessionTransport,
        p_random: GameRandom,
        p_loss_probability: float,
        p_duplicate_probability: float,
        p_max_delay_polls: int,
        ) -> void:
    _inner = p_inner
    _random = p_random
    loss_probability = p_loss_probability
    duplicate_probability = p_duplicate_probability
    max_delay_polls = maxi(p_max_delay_polls, 0)
    _inner.peer_connected.connect(func(peer_id: int) -> void: peer_connected.emit(peer_id))
    _inner.peer_disconnected.connect(func(peer_id: int) -> void: peer_disconnected.emit(peer_id))
    _inner.message_received.connect(func(peer_id: int, message: Dictionary) -> void: message_received.emit(peer_id, message))


func is_host() -> bool:
    return _inner.is_host()


func local_peer_id() -> int:
    return _inner.local_peer_id()


func send(peer_id: int, message: Dictionary, is_reliable: bool) -> void:
    var copies: int = 1
    if not is_reliable:
        if _random.chance(loss_probability):
            return
        if _random.chance(duplicate_probability):
            copies = 2
    for _i: int in range(copies):
        _queue.append({
            "wait": _random.range_int(0, max_delay_polls),
            "peer": peer_id,
            "message": message,
            "reliable": is_reliable,
        })


func poll() -> void:
    var pending: Array[Dictionary] = []
    for entry: Dictionary in _queue:
        var wait: int = int(entry["wait"])
        if wait <= 0:
            _inner.send(int(entry["peer"]), entry["message"] as Dictionary, bool(entry["reliable"]))
        else:
            entry["wait"] = wait - 1
            pending.append(entry)
    _queue = pending
    _inner.poll()


func close() -> void:
    _queue.clear()
    _inner.close()
