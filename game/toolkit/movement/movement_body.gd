class_name MovementBody
extends RefCounted
## Posición y velocidad de algo que se mueve: lee la intención del controlador y la alcanza según el perfil.
## Sin nodos: la vista lee `position` y `velocity`.


## Solo lectura desde fuera: cambian con step() y restore().
var position: Vector2:
    get:
        return _position
var velocity: Vector2:
    get:
        return _velocity
var profile: MovementProfile
var controller: MovementController

var _position: Vector2
var _velocity: Vector2 = Vector2.ZERO


func _init(p_controller: MovementController, p_profile: MovementProfile, p_position: Vector2 = Vector2.ZERO) -> void:
    assert(p_controller != null and p_profile != null, "MovementBody necesita controlador y perfil")
    controller = p_controller
    profile = p_profile
    _position = p_position


## Cambiar de controlador conserva la velocidad: el relevo teclado <-> IA es suave.
func set_controller(p_controller: MovementController) -> void:
    assert(p_controller != null, "MovementBody necesita controlador")
    controller = p_controller


func set_profile(p_profile: MovementProfile) -> void:
    assert(p_profile != null, "MovementBody necesita perfil")
    profile = p_profile


## Avanza `delta` segundos. Devuelve false (y no cambia nada) si delta no es un número positivo y finito.
func step(delta: float) -> bool:
    if not is_finite(delta) or delta <= 0.0:
        push_error("MovementBody.step: delta inválido (%s)" % str(delta))
        return false
    var direction: Vector2 = controller.desired_direction(_position, delta)
    if not direction.is_finite():
        direction = Vector2.ZERO
    var target: Vector2 = direction.limit_length(1.0) * profile.max_speed
    _velocity = _velocity.move_toward(target, _rate_toward(target) * delta)
    _position += _velocity * delta
    return true


## Mantiene el cuerpo dentro de `area` (bordes incluidos): lo que se sale vuelve al borde y esa componente de la velocidad se anula.
func confine(area: Rect2) -> void:
    var clamped: Vector2 = _position.clamp(area.position, area.end)
    if clamped.x != _position.x:
        _velocity.x = 0.0
    if clamped.y != _position.y:
        _velocity.y = 0.0
    _position = clamped


func snapshot() -> Dictionary:
    return {"x": _position.x, "y": _position.y, "vx": _velocity.x, "vy": _velocity.y}


func restore(saved: Dictionary) -> void:
    _position = Vector2(float(saved["x"]), float(saved["y"]))
    _velocity = Vector2(float(saved["vx"]), float(saved["vy"]))


## Frenar (objetivo menor en el mismo sentido o quieto) usa decel; invertir el sentido, accel * turn_response; el resto, accel.
func _rate_toward(target: Vector2) -> float:
    var alignment: float = _velocity.dot(target)
    if alignment < 0.0:
        return profile.accel_rate() * profile.turn_response
    if target.length_squared() < _velocity.length_squared():
        return profile.decel_rate()
    return profile.accel_rate()
