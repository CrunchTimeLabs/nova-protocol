class_name SmelterDuo
extends RefCounted
## Une la fundición de la campaña (`SmelterRun`) con la temperatura (`TemperatureState`, sin reloj propio):
## el objetivo de temperatura es el punto de fusión del elemento del objetivo más urgente; fuera de rango la
## fundición queda bloqueada. El empuje acelera mientras se mantiene la tecla (toques cortos = ajuste fino).


const SCALE_MAX := 1800.0
const TARGET_HALF_WIDTH := 40.0
## °C/s al empezar a pulsar y al cabo de RAMP_TIME manteniendo.
const RATE_START := 140.0
const RATE_FULL := 620.0
const RAMP_TIME := 0.9
const WANDER_RESPONSE := 3.0
const PUSH_DAMPING := 0.15
const DRIFT_SPEED := 45.0
## Mena con la que se practica en los tutoriales (bauxita → aluminio, 660 °C).
const PRACTICE_ORE := Ores.Ore.BAUXITE

var run: SmelterRun
var temperature: TemperatureState
var _held: float = 0.0
var _last_direction: float = 0.0
var _current: SmelterRun.Spawn = null


func _init(p_run: SmelterRun, seed_value: int = -1) -> void:
    run = p_run
    temperature = TemperatureState.new(seed_value, false, false, SCALE_MAX)
    temperature.gauge.wander_response = WANDER_RESPONSE
    temperature.gauge.push_damping = PUSH_DAMPING
    temperature.gauge.drift_speed = DRIFT_SPEED
    run.selected.connect(_on_changed)
    run.smelted.connect(_on_changed)
    run.expired.connect(_on_changed)


## Velocidad del empuje según cuánto se lleva pulsando en la misma dirección.
static func rate_after(held: float) -> float:
    return lerpf(RATE_START, RATE_FULL, clampf(held / RAMP_TIME, 0.0, 1.0))


## Un paso: `direction` +1 sube, -1 baja, 0 nada. Antes de empezar y al terminar la aguja no se mueve.
func step(delta: float, direction: float) -> void:
    if direction != 0.0 and signf(direction) == signf(_last_direction):
        _held += delta
    else:
        _held = 0.0
    _last_direction = direction
    if run.is_finished:
        temperature.finish()
    elif run.is_started:
        temperature.player_rate = rate_after(_held)
        temperature.step(delta, direction)
    temperature.sync_time(ceili(run.remaining))
    run.blocked = not temperature.is_in_range() and not run.active.is_empty()


## Práctica del tutorial (antes de empezar): la aguja se mueve de verdad hacia el punto del aluminio.
func practice(delta: float, direction: float) -> void:
    if not temperature.has_target:
        var point: float = float(Ores.MELTING_POINTS[PRACTICE_ORE])
        temperature.set_target(point - TARGET_HALF_WIDTH, point + TARGET_HALF_WIDTH, "Práctica: %d °C" % int(point))
    if direction != 0.0 and signf(direction) == signf(_last_direction):
        _held += delta
    else:
        _held = 0.0
    _last_direction = direction
    temperature.player_rate = rate_after(_held)
    temperature.step(delta, direction)


func _on_changed(_spawn: SmelterRun.Spawn) -> void:
    var urgent: SmelterRun.Spawn = null
    for spawn: SmelterRun.Spawn in run.active:
        if urgent == null or spawn.remaining < urgent.remaining:
            urgent = spawn
    if urgent == null or urgent == _current:
        return
    _current = urgent
    var point: float = float(Ores.MELTING_POINTS[urgent.ore])
    temperature.set_target(point - TARGET_HALF_WIDTH, point + TARGET_HALF_WIDTH,
            "%s: %d °C" % [Ores.element(urgent.ore), int(point)])
