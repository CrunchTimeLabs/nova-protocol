class_name MatchProtocol
extends RefCounted
## Vocabulario del protocolo anfitrión <-> jugador: tipos de mensaje, motivos de rechazo y claves.
## Un mensaje es un Dictionary de primitivos con su tipo en la clave "t".


## Se sube al cambiar el formato de los mensajes; un cliente con otra versión es rechazado.
const PROTOCOL_VERSION: int = 1

enum Type { HELLO, WELCOME, REJECT, COMMAND, SNAPSHOT, ERROR }
enum Reason { VERSION_MISMATCH, SESSION_FULL, NOT_JOINED, NOT_RUNNING, INVALID_COMMAND, FORBIDDEN, RATE_LIMITED, REFUSED }

const KEY_TYPE: String = "t"
const KEY_VERSION: String = "version"
const KEY_SLOT: String = "slot"
const KEY_ROLE: String = "role"
const KEY_REASON: String = "reason"
const KEY_COMMAND: String = "command"
const KEY_TICK: String = "tick"
const KEY_STATE: String = "state"


static func make(type: Type, fields: Dictionary = {}) -> Dictionary:
    var message: Dictionary = fields.duplicate()
    message[KEY_TYPE] = type
    return message


## El tipo del mensaje, o -1 si falta o no es válido.
static func type_of(message: Dictionary) -> int:
    var raw: Variant = message.get(KEY_TYPE)
    if not (raw is int or raw is float) or not is_finite(float(raw)):
        return -1
    var type: int = int(raw)
    return type if type >= 0 and type < Type.size() else -1


## Un número del mensaje convertido a entero; `fallback` si falta o no es número finito.
static func int_of(message: Dictionary, key: String, fallback: int = -1) -> int:
    var raw: Variant = message.get(key)
    if (raw is int or raw is float) and is_finite(float(raw)):
        return int(raw)
    return fallback
