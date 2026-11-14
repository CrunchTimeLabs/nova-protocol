class_name OrbitMatch
extends MatchRules
## Reglas de la misión de órbita: un cuerpo con motor y combustible bajo la gravedad de una estrella y una luna.
## El piloto manda su aceleración (la de su laboratorio de movimiento), relativa al rumbo de la nave (adelante, atrás, derecha, izquierda);
## aquí se escala y se limita para convertirla en empuje, que se suma a la gravedad.
## Sin nodos: la estación lee `body` y `attractors()`.


const STAR_CENTER: Vector2 = Vector2(0.5, 0.5)
const STAR_GM: float = 0.01
const MOON_CENTER: Vector2 = Vector2(0.85, 0.3)
const MOON_GM: float = 0.0008
const ORBIT_RADIUS: float = 0.25
const MAX_ACCELERATION: float = 0.05
const FUEL_CAPACITY: float = 1.0
## Segundos de empuje máximo que dura el depósito completo.
const FULL_BURN_SECONDS: float = 20.0
## Calibración: cuánto empuje produce una unidad de aceleración del piloto.
const THRUST_SCALE: float = 1.0
const MAX_THRUST_LENGTH: float = 1.0
## Claves de la instantánea: cada rol ve las suyas.
const KEY_ORBIT: String = "orbit"
const KEY_FUEL: String = "fuel"

var body: DynamicBody

var _manual: ManualThrustController = ManualThrustController.new()
var _fuel: ResourceMeter = ResourceMeter.new(FUEL_CAPACITY, FUEL_CAPACITY)
var _attractors: Array[CentralGravity] = []
var _thrusts: Dictionary = {}    # int (slot) -> Vector2


func _init() -> void:
    var engine: ThrustEngine = ThrustEngine.new(MAX_ACCELERATION, _fuel, FUEL_CAPACITY / FULL_BURN_SECONDS)
    _attractors = [CentralGravity.new(STAR_CENTER, STAR_GM), CentralGravity.new(MOON_CENTER, MOON_GM)]
    var sources: Array[AccelerationSource] = []
    sources.assign(_attractors)
    body = DynamicBody.new(
            HeadingThrustController.new(_manual),
            engine,
            sources,
            STAR_CENTER + Vector2(ORBIT_RADIUS, 0.0),
            Vector2(0.0, sqrt(STAR_GM / ORBIT_RADIUS)),
            )


func attractors() -> Array[CentralGravity]:
    return _attractors


func fuel_ratio() -> float:
    return _fuel.ratio()


## SET_THRUST con {"x", "y"}: aceleración que pide el jugador. Cualquier otra cosa se rechaza sin cambiar nada.
func apply(slot: int, command: Command) -> bool:
    if command.kind != OrbitCommand.Kind.SET_THRUST:
        return false
    var raw_x: Variant = command.payload.get("x")
    var raw_y: Variant = command.payload.get("y")
    if not (raw_x is int or raw_x is float) or not (raw_y is int or raw_y is float):
        return false
    var requested: Vector2 = Vector2(float(raw_x), float(raw_y))
    if not requested.is_finite():
        return false
    _thrusts[slot] = (requested * THRUST_SCALE).limit_length(MAX_THRUST_LENGTH)
    return true


func step(delta: float) -> void:
    var total: Vector2 = Vector2.ZERO
    for thrust: Variant in _thrusts.values():
        total += thrust as Vector2
    _manual.set_command(total)
    body.step(delta)


func release_slot(slot: int) -> void:
    _thrusts.erase(slot)


func snapshot() -> Dictionary:
    var saved: Dictionary = body.snapshot()
    var fuel: float = float(saved["fuel"])
    saved.erase("fuel")
    return {KEY_ORBIT: saved, KEY_FUEL: fuel}


## Acepta instantáneas parciales: un jugador solo recibe las claves de su rol.
func restore(saved: Dictionary) -> void:
    if saved.has(KEY_ORBIT):
        body.restore(saved[KEY_ORBIT] as Dictionary)
    if saved.has(KEY_FUEL):
        _fuel.set_value(float(saved[KEY_FUEL]))
