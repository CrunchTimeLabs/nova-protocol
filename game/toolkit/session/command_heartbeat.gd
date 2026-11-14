class_name CommandHeartbeat
extends RefCounted
## Decide cuándo reenviar una orden que describe un estado (p. ej. el acelerador): al cambiar y cada cierto tiempo,
## así un mensaje perdido se corrige solo.


var interval: float

var _last: Dictionary = {}
var _has_last: bool = false
var _elapsed: float = 0.0


func _init(p_interval: float) -> void:
    interval = maxf(p_interval, 0.001)


## true si hay que enviar `payload` ahora: es la primera vez, cambió o venció el latido.
func should_send(payload: Dictionary, delta: float) -> bool:
    _elapsed += delta
    if _has_last and payload == _last and _elapsed < interval:
        return false
    _last = payload.duplicate()
    _has_last = true
    _elapsed = 0.0
    return true
