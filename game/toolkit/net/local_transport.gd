class_name LocalTransport
extends SessionTransport
## Transporte en memoria sobre un LocalHub. Los mensajes se codifican y decodifican como en la red.


var _hub: LocalHub
var _peer_id: int


func _init(p_hub: LocalHub, p_peer_id: int) -> void:
    _hub = p_hub
    _peer_id = p_peer_id


func is_host() -> bool:
    return _peer_id == LocalHub.HOST_ID


func local_peer_id() -> int:
    return _peer_id


func send(peer_id: int, message: Dictionary, _is_reliable: bool) -> void:
    var bytes: PackedByteArray = MessageCodec.encode(message)
    var targets: Array[int] = []
    if peer_id == 0:
        targets = _hub.everyone_but(_peer_id)
    else:
        targets.append(peer_id)
    for target: int in targets:
        _hub.push(target, LocalHub.Event.MESSAGE, _peer_id, bytes)


func poll() -> void:
    for entry: Variant in _hub.take(_peer_id):
        var event: Dictionary = entry as Dictionary
        var peer: int = int(event["peer"])
        match int(event["event"]):
            LocalHub.Event.CONNECTED:
                peer_connected.emit(peer)
            LocalHub.Event.DISCONNECTED:
                peer_disconnected.emit(peer)
            LocalHub.Event.MESSAGE:
                message_received.emit(peer, MessageCodec.decode(event["bytes"] as PackedByteArray))


func close() -> void:
    _hub.leave(_peer_id)
