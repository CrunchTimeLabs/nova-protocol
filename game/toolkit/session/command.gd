class_name Command
extends RefCounted
## Lo que un jugador quiere hacer: quién lo envía, de qué tipo (enum del juego, aquí un entero) y sus datos.
## Solo datos primitivos: nunca cambia el estado por sí mismo; el anfitrión lo valida y lo aplica.


var slot: int
var kind: int
var payload: Dictionary


func _init(p_slot: int, p_kind: int, p_payload: Dictionary = {}) -> void:
    slot = p_slot
    kind = p_kind
    payload = p_payload


func to_dict() -> Dictionary:
    return {"slot": slot, "kind": kind, "payload": payload}


## Reconstruye un comando recibido de la red. null si falta un campo o tiene un tipo inválido.
static func from_dict(saved: Dictionary) -> Command:
    if not (saved.has("slot") and saved.has("kind") and saved.has("payload")):
        return null
    var raw_slot: Variant = saved["slot"]
    var raw_kind: Variant = saved["kind"]
    var raw_payload: Variant = saved["payload"]
    if not (raw_slot is int or raw_slot is float) or not (raw_kind is int or raw_kind is float):
        return null
    if not raw_payload is Dictionary:
        return null
    if not is_finite(float(raw_slot)) or not is_finite(float(raw_kind)):
        return null
    return Command.new(int(raw_slot), int(raw_kind), raw_payload as Dictionary)
