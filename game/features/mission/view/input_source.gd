class_name InputSource
extends RefCounted
## Traduce teclas o un mando a una dirección. Teclado: WASD, flechas o ambos; mando: el stick izquierdo del `device` indicado.
## Solo lee la entrada: lo que se hace con ella lo decide el dominio.


enum Scheme { BOTH, ARROWS, WASD }

const DEADZONE: float = 0.2
const NO_DEVICE: int = -1

var _scheme: Scheme
var _device: int


## `scheme` elige qué teclas cuentan (en pantalla dividida con un solo teclado, cada jugador usa las suyas).
func _init(p_scheme: Scheme = Scheme.BOTH, p_device: int = NO_DEVICE) -> void:
    _scheme = p_scheme
    _device = p_device


## Dirección con magnitud de 0 a 1. Teclas físicas: sirven igual en cualquier distribución de teclado.
func read_direction() -> Vector2:
    if _device != NO_DEVICE:
        var stick: Vector2 = Vector2(
                Input.get_joy_axis(_device, JOY_AXIS_LEFT_X),
                Input.get_joy_axis(_device, JOY_AXIS_LEFT_Y),
                )
        return stick if stick.length() > DEADZONE else Vector2.ZERO
    var horizontal: float = _axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT)
    var vertical: float = _axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP)
    return Vector2(horizontal, vertical).limit_length(1.0)


func _axis(wasd_key: Key, arrow_key: Key) -> float:
    var wasd: bool = _scheme != Scheme.ARROWS and Input.is_physical_key_pressed(wasd_key)
    var arrow: bool = _scheme != Scheme.WASD and Input.is_physical_key_pressed(arrow_key)
    return float(wasd or arrow)
