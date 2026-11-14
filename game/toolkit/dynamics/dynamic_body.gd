class_name DynamicBody
extends RefCounted
## Posición y velocidad de algo que se mueve por aceleraciones: el empuje del controlador más las fuentes externas.
## Sin tope de velocidad ni frenado propio: soltar el empuje conserva la velocidad. Sin nodos: la vista lee `position` y `velocity`.
## Mundo normalizado: posiciones en [0, 1], velocidades en mundos/s y aceleraciones en mundos/s²; la vista escala a píxeles.


## Un paso largo se divide en subpasos de a lo sumo esto: el resultado no depende de los fps y las órbitas aguantan.
const MAX_SUBSTEP: float = 1.0 / 120.0

## Solo lectura desde fuera: cambian con step() y restore().
var position: Vector2:
    get:
        return _position
var velocity: Vector2:
    get:
        return _velocity
var controller: ThrustController
var engine: ThrustEngine

var _sources: Array[AccelerationSource] = []
var _position: Vector2
var _velocity: Vector2


func _init(
        p_controller: ThrustController,
        p_engine: ThrustEngine,
        p_sources: Array[AccelerationSource] = [],
        p_position: Vector2 = Vector2.ZERO,
        p_velocity: Vector2 = Vector2.ZERO,
        ) -> void:
    assert(p_controller != null and p_engine != null, "DynamicBody necesita controlador y motor")
    controller = p_controller
    engine = p_engine
    _sources = p_sources.duplicate()
    _position = p_position
    _velocity = p_velocity


func set_controller(p_controller: ThrustController) -> void:
    assert(p_controller != null, "DynamicBody necesita controlador")
    controller = p_controller


## Avanza `delta` segundos. Devuelve false (y no cambia nada) si delta no es un número positivo y finito.
## La orden del controlador se lee una vez por llamada; cada subpaso integra con velocity Verlet.
func step(delta: float) -> bool:
    if not is_finite(delta) or delta <= 0.0:
        push_error("DynamicBody.step: delta inválido (%s)" % str(delta))
        return false
    var command: Vector2 = controller.thrust_command(_position, _velocity, delta)
    if not command.is_finite():
        command = Vector2.ZERO
    var substeps: int = ceili(delta / MAX_SUBSTEP)
    var h: float = delta / float(substeps)
    for _i: int in range(substeps):
        var thrust: Vector2 = engine.acceleration_for(command, h)
        var start_acceleration: Vector2 = thrust + _sources_acceleration(_position, _velocity)
        _position += _velocity * h + 0.5 * start_acceleration * h * h
        # Las fuentes que dependen de la velocidad usan la velocidad prevista al final del subpaso.
        var end_acceleration: Vector2 = thrust + _sources_acceleration(_position, _velocity + start_acceleration * h)
        _velocity += 0.5 * (start_acceleration + end_acceleration) * h
    return true


## Posiciones futuras si no se empuja más: `steps` pasos de `step_delta` segundos sobre una copia, incluido el punto actual.
## Solo actúan las fuentes. El cuerpo, su motor y su combustible no cambian; coincide con dejar correr al cuerpo real sin empuje.
func forecast(steps: int, step_delta: float) -> PackedVector2Array:
    var ghost: DynamicBody = DynamicBody.new(
            ManualThrustController.new(),
            ThrustEngine.new(0.0),
            _sources,
            _position,
            _velocity,
            )
    var points: PackedVector2Array = PackedVector2Array([_position])
    for _i: int in range(steps):
        ghost.step(step_delta)
        points.append(ghost.position)
    return points


## Posición, velocidad y, si el motor tiene medidor, la clave "fuel" con el combustible.
func snapshot() -> Dictionary:
    var saved: Dictionary = {"x": _position.x, "y": _position.y, "vx": _velocity.x, "vy": _velocity.y}
    saved.merge(engine.snapshot())
    return saved


func restore(saved: Dictionary) -> void:
    _position = Vector2(float(saved["x"]), float(saved["y"]))
    _velocity = Vector2(float(saved["vx"]), float(saved["vy"]))
    engine.restore(saved)


func _sources_acceleration(at_position: Vector2, at_velocity: Vector2) -> Vector2:
    var total: Vector2 = Vector2.ZERO
    for source: AccelerationSource in _sources:
        total += source.acceleration_at(at_position, at_velocity)
    return total
