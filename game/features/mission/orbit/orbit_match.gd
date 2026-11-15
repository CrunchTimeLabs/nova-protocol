class_name OrbitMatch
extends MatchRules
## Reglas de la misión de órbita: un cuerpo con motor y combustible bajo la gravedad de una estrella y una luna.
## El piloto manda su aceleración (la de su laboratorio de movimiento), relativa al rumbo de la nave (adelante, atrás, derecha, izquierda);
## aquí se escala y se limita para convertirla en empuje, que se suma a la gravedad.
## La partida se gana al cruzar el radio de meta alrededor de la luna y se pierde al agotarse el combustible, al salir del mapa o al avisar el piloto de que se destruyó.
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
const KEY_PHASE: String = "phase"
const KEY_OUTCOME: String = "outcome"
## Radio (en el mapa normalizado) alrededor de la luna que la nave debe cruzar para ganar.
const MOON_GOAL_RADIUS: float = 0.14
## La nave pierde si sale del mapa normalizado [0, 1] por más que este margen: ya no hay órbita que recuperar.
const ESCAPE_MARGIN: float = 0.0

enum Outcome { PLAYING, WON, LOST }

var body: DynamicBody
var outcome: Outcome = Outcome.PLAYING
## Hay alguna estación manteniendo el salto de fase (el piloto lo lee de su réplica).
var phase_held: bool = false

var _manual: ManualThrustController = ManualThrustController.new()
var _fuel: ResourceMeter = ResourceMeter.new(FUEL_CAPACITY, FUEL_CAPACITY)
var _attractors: Array[CentralGravity] = []
var _thrusts: Dictionary = {}    # int (slot) -> Vector2
var _phase_holds: Dictionary = {}    # int (slot) -> bool
var _time_scale: float


## `time_scale` (> 0) acelera o frena toda la simulación (movimiento, gravedad, empuje y gasto) sin cambiar la órbita: 1.0 es el ritmo normal.
func _init(time_scale: float = 1.0) -> void:
    assert(time_scale > 0.0, "OrbitMatch necesita una escala de tiempo positiva")
    _time_scale = time_scale
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


func distance_to_moon() -> float:
    return body.position.distance_to(MOON_CENTER)


## La nave salió del mapa.
func is_lost_in_space() -> bool:
    var position: Vector2 = body.position
    var low: float = -ESCAPE_MARGIN
    var high: float = 1.0 + ESCAPE_MARGIN
    return position.x < low or position.x > high or position.y < low or position.y > high


func fuel_ratio() -> float:
    return _fuel.ratio()


## SET_THRUST con {"x", "y"}: aceleración que pide el jugador; PHASE_HOLD con {"on"}: mantener la fase.
## Cualquier otra cosa se rechaza sin cambiar nada.
func apply(slot: int, command: Command) -> bool:
    if command.kind == OrbitCommand.Kind.PHASE_HOLD:
        return _apply_phase_hold(slot, command)
    if command.kind == OrbitCommand.Kind.REPORT_CRASH:
        if outcome == Outcome.PLAYING:
            outcome = Outcome.LOST
        return true
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


func _apply_phase_hold(slot: int, command: Command) -> bool:
    var raw_on: Variant = command.payload.get("on")
    if not raw_on is bool:
        return false
    _phase_holds[slot] = raw_on
    phase_held = _phase_holds.values().has(true)
    return true


func step(delta: float) -> void:
    if outcome != Outcome.PLAYING:
        return
    var total: Vector2 = Vector2.ZERO
    for thrust: Variant in _thrusts.values():
        total += thrust as Vector2
    _manual.set_command(total)
    body.step(delta * _time_scale)
    _check_outcome()


## La meta se comprueba antes que el combustible: si llega con el último gramo, gana.
func _check_outcome() -> void:
    if distance_to_moon() < MOON_GOAL_RADIUS:
        outcome = Outcome.WON
    elif is_lost_in_space() or _fuel.current <= 0.0:
        outcome = Outcome.LOST


func release_slot(slot: int) -> void:
    _thrusts.erase(slot)
    _phase_holds.erase(slot)
    phase_held = _phase_holds.values().has(true)


func snapshot() -> Dictionary:
    var saved: Dictionary = body.snapshot()
    var fuel: float = float(saved["fuel"])
    saved.erase("fuel")
    return {KEY_ORBIT: saved, KEY_FUEL: fuel, KEY_PHASE: phase_held, KEY_OUTCOME: Outcome.find_key(outcome)}


## Acepta instantáneas parciales: un jugador solo recibe las claves de su rol.
func restore(saved: Dictionary) -> void:
    if saved.has(KEY_ORBIT):
        body.restore(saved[KEY_ORBIT] as Dictionary)
    if saved.has(KEY_FUEL):
        _fuel.set_value(float(saved[KEY_FUEL]))
    if saved.has(KEY_PHASE):
        phase_held = bool(saved[KEY_PHASE])
    if saved.has(KEY_OUTCOME):
        outcome = Outcome[str(saved[KEY_OUTCOME])] as Outcome
