class_name DragSession
extends RefCounted
## Arrastrar y soltar sin pantalla: una carga sale de una zona de origen y se suelta en otra.
## La regla `rule(payload, from_zone, to_zone) -> bool` decide si el soltado vale; la vista solo traduce
## el ratón a begin() / drop() / cancel() y dibuja. Las zonas son nombres que elige quien la usa.


signal dropped(result: Result, payload: Variant, from_zone: StringName, to_zone: StringName)

enum Result { NOT_DRAGGING, ACCEPTED, REJECTED, CANCELLED }

var payload: Variant = null
var from_zone: StringName = &""

var _rule: Callable
var _is_dragging: bool = false


func _init(rule: Callable) -> void:
    _rule = rule


func is_dragging() -> bool:
    return _is_dragging


## Empieza a arrastrar `p_payload` desde `zone`. Devuelve false (y avisa) si ya había un arrastre.
func begin(p_payload: Variant, zone: StringName) -> bool:
    if _is_dragging:
        push_error("DragSession: ya hay un arrastre en curso")
        return false
    payload = p_payload
    from_zone = zone
    _is_dragging = true
    return true


## Suelta en `to_zone`. ACCEPTED o REJECTED según la regla; en ambos casos el arrastre termina.
func drop(to_zone: StringName) -> Result:
    if not _is_dragging:
        return Result.NOT_DRAGGING
    var accepted: bool = bool(_rule.call(payload, from_zone, to_zone))
    var result: Result = Result.ACCEPTED if accepted else Result.REJECTED
    _finish(result, to_zone)
    return result


func cancel() -> Result:
    if not _is_dragging:
        return Result.NOT_DRAGGING
    _finish(Result.CANCELLED, &"")
    return Result.CANCELLED


func _finish(result: Result, to_zone: StringName) -> void:
    var released: Variant = payload
    var origin: StringName = from_zone
    payload = null
    from_zone = &""
    _is_dragging = false
    dropped.emit(result, released, origin, to_zone)
