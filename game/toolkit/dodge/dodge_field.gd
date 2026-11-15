class_name DodgeField
extends RefCounted
## Campo de esquivar: una nave se mueve dentro de un recuadro de tamaño dado y cruzan rocas de derecha a izquierda.
## Cada golpe resta casco y da unos segundos de invulnerabilidad. Termina al llegar a `duration` (si es > 0) o al quedarse sin casco;
## con `duration` <= 0 no hay final por tiempo y la dificultad sube durante `RAMP_SECONDS` y se queda en el máximo.
## Todo el azar usa la semilla; el tamaño del campo es un parámetro (rocas, velocidades y nave se escalan con él).
## Con `wants_phase` la nave hace un salto de fase: intangible y más rápida mientras dura su carga, que se recarga despacio.
## Con `wind` > 0 también nacen ondas expansivas (viento solar) que golpean una vez al alcanzar la nave.
## Sin nodos: la vista lee `ship`, `rocks`, `waves`, `wave_warning`, `hull`, `elapsed` y `is_protected()`.


enum Status { RUNNING, ARRIVED, DESTROYED }

const SHIP_RADIUS: float = 12.0
## Anchos de campo que recorre la nave por segundo.
const SHIP_SPEED_WIDTHS: float = 0.5
const SHIP_START: Vector2 = Vector2(0.15, 0.5)
const HULL_MAX: float = 100.0
const ROCK_DAMAGE: float = 11.0
const INVULNERABILITY_SECONDS: float = 1.15
const FIRST_ROCK_SECONDS: float = 1.0
## Dificultad (del original): a medida que avanza el progreso (0..1) las rocas caen más seguido y más rápido.
## Segundos entre rocas = (INTERVAL_START - INTERVAL_DROP * progreso^INTERVAL_CURVE) / densidad.
## Segundos que tarda la dificultad en llegar al máximo cuando no hay duración.
const RAMP_SECONDS: float = 68.0
const INTERVAL_START: float = 0.92
const INTERVAL_DROP: float = 0.62
const INTERVAL_CURVE: float = 1.1
## Sin rocas nuevas en los últimos segundos.
const ROCK_CUTOFF_SECONDS: float = 1.5
## Pasado este progreso, cada vez hay una probabilidad de que caigan dos rocas juntas.
const PAIR_FROM_PROGRESS: float = 0.55
const PAIR_CHANCE: float = 0.4
## Pasado este progreso, las rocas llevan deriva vertical.
const DRIFT_FROM_PROGRESS: float = 0.4
## Alturas del campo que miden los radios de las rocas (14, 18, 22, 28, 34 y 42 px sobre un campo de 760 de alto).
const ROCK_RADII_HEIGHTS: Array[float] = [0.0184, 0.0237, 0.0289, 0.0368, 0.0447, 0.0553]
## Anchos de campo por segundo: (SPEED_BASE + SPEED_GAIN * progreso) * (0.8 + 0.3 * densidad) * variación.
const SPEED_BASE_WIDTHS: float = 0.1688
const SPEED_GAIN_WIDTHS: float = 0.2063
const SPEED_JITTER_MIN: float = 0.85
const SPEED_JITTER_MAX: float = 1.2
const SPEED_DENSITY_BASE: float = 0.8
const SPEED_DENSITY_GAIN: float = 0.3
const ROCK_DRIFT_HEIGHTS: float = 0.079
const ROCK_MARGIN_HEIGHTS: float = 0.05

## Fase (carga 120 y velocidad x1.8 como el original; consumo y recarga ajustados para que sea escasa) cuando no se usa.
const PHASE_MAX: float = 120.0
const PHASE_DRAIN: float = 50.0
const PHASE_RECHARGE: float = 3.0
const PHASE_SPEED_BOOST: float = 1.8
## Ondas (viento solar): daño, invulnerabilidad, intervalo (a mayor `wind`, más seguido) y velocidad en anchos por segundo.
const WAVE_DAMAGE: float = 15.0
const WAVE_INVULNERABILITY_SECONDS: float = 1.0
const WAVE_FIRST_SECONDS: float = 4.0
const WAVE_INTERVAL_MIN_SECONDS: float = 8.0
const WAVE_INTERVAL_MAX_SECONDS: float = 12.0
const WAVE_MIN_WIND: float = 0.6
const WAVE_SPEED_WIDTHS: float = 0.35
## Sin ondas nuevas en los últimos segundos.
const WAVE_CUTOFF_SECONDS: float = 3.0
## La onda nace este múltiplo de su radio inicial fuera del borde; su alcance es el largo de la diagonal por este factor.
const WAVE_OUTSIDE_MARGIN: float = 6.0
const WAVE_REACH_FACTOR: float = 1.2

var field_size: Vector2
var density: float
var wind: float
var duration: float
var hull: ResourceMeter = ResourceMeter.new(HULL_MAX, HULL_MAX)
var elapsed: float = 0.0
var status: Status = Status.RUNNING
var phase: ResourceMeter = ResourceMeter.new(PHASE_MAX, PHASE_MAX)
var in_phase: bool = false
var rocks: Array[DodgeRock] = []
var waves: Array[DodgeWave] = []
## Cuántas ondas han nacido.
var waves_spawned: int = 0
## Cuántas rocas han nacido (para medir la frecuencia).
var spawned: int = 0
## Hay al menos una onda en camino que aún no ha golpeado.
var wave_warning: bool:
    get:
        for wave: DodgeWave in waves:
            if not wave.has_hit:
                return true
        return false
var ship: Vector2:
    get:
        return _body.position

var _random: GameRandom
var _controller: ManualController = ManualController.new()
var _body: MovementBody
var _ship_speed: float
var _ship_area: Rect2
var _invulnerable: float = 0.0
var _next_rock: float = FIRST_ROCK_SECONDS
var _next_wave: float = WAVE_FIRST_SECONDS


func _init(
        p_size: Vector2,
        p_density: float,
        p_duration: float,
        seed_value: int,
        p_wind: float = 0.0,
        ) -> void:
    field_size = p_size
    wind = maxf(p_wind, 0.0)
    density = maxf(p_density, 0.01)
    duration = p_duration
    _random = GameRandom.new(seed_value)
    _ship_area = Rect2(
            Vector2(SHIP_RADIUS, SHIP_RADIUS),
            p_size - Vector2(SHIP_RADIUS, SHIP_RADIUS) * 2.0,
            )
    _ship_speed = p_size.x * SHIP_SPEED_WIDTHS
    _body = MovementBody.new(_controller, MovementProfile.new(_ship_speed, 0.0, 0.0), p_size * SHIP_START)


func is_protected() -> bool:
    return in_phase or _invulnerable > 0.0


## Un paso. `move` en -1..1 por eje; `wants_phase` mientras se mantiene el salto de fase. Terminada la partida ya no cambia nada.
func step(delta: float, move: Vector2, wants_phase: bool = false) -> Status:
    if status != Status.RUNNING or delta <= 0.0:
        return status
    _update_phase(delta, wants_phase)
    _body.profile.max_speed = maxf(_ship_speed * (PHASE_SPEED_BOOST if in_phase else 1.0), MovementProfile.MIN_SPEED)
    _controller.set_direction(move)
    _body.step(delta)
    _body.confine(_ship_area)
    _spawn()
    _update_rocks(delta)
    _spawn_wave()
    _update_waves(delta)
    _invulnerable = maxf(0.0, _invulnerable - delta)
    elapsed += delta
    if hull.current <= 0.0:
        status = Status.DESTROYED
    elif duration > 0.0 and elapsed >= duration:
        status = Status.ARRIVED
    return status


func _update_phase(delta: float, wants_phase: bool) -> void:
    in_phase = wants_phase and phase.current > 0.0
    phase.add(-PHASE_DRAIN * delta if in_phase else PHASE_RECHARGE * delta)


func progress() -> float:
    var span: float = duration if duration > 0.0 else RAMP_SECONDS
    return clampf(elapsed / span, 0.0, 1.0)


func _is_near_end(cutoff: float) -> bool:
    return duration > 0.0 and elapsed >= duration - cutoff


func _spawn() -> void:
    if elapsed < _next_rock or _is_near_end(ROCK_CUTOFF_SECONDS):
        return
    var p: float = progress()
    _next_rock = elapsed + (INTERVAL_START - INTERVAL_DROP * pow(p, INTERVAL_CURVE)) / density
    var count: int = 2 if p > PAIR_FROM_PROGRESS and _random.chance(PAIR_CHANCE) else 1
    for _i: int in range(count):
        _spawn_rock(p)


func _spawn_rock(p: float) -> void:
    var radius: float = float(_random.pick(ROCK_RADII_HEIGHTS)) * field_size.y
    var margin: float = ROCK_MARGIN_HEIGHTS * field_size.y
    var y: float = _random.range_float(margin, field_size.y - margin)
    var base_speed: float = (SPEED_BASE_WIDTHS + SPEED_GAIN_WIDTHS * p) * (SPEED_DENSITY_BASE + SPEED_DENSITY_GAIN * density)
    var speed: float = base_speed * _random.range_float(SPEED_JITTER_MIN, SPEED_JITTER_MAX) * field_size.x
    var drift: float = 0.0
    if p > DRIFT_FROM_PROGRESS:
        drift = _random.range_float(-ROCK_DRIFT_HEIGHTS, ROCK_DRIFT_HEIGHTS) * field_size.y
    rocks.append(DodgeRock.new(Vector2(field_size.x + radius, y), radius, speed, drift, _random))
    spawned += 1


func _update_rocks(delta: float) -> void:
    var alive: Array[DodgeRock] = []
    for rock: DodgeRock in rocks:
        rock.position += Vector2(-rock.speed, rock.drift) * delta
        rock.spin += rock.spin_speed * delta
        if rock.position.y < 0.0 or rock.position.y > field_size.y:
            rock.drift = -rock.drift
        if rock.position.x + rock.radius < 0.0:
            continue
        if not is_protected() and rock.hits(ship, SHIP_RADIUS):
            hull.add(-ROCK_DAMAGE)
            _invulnerable = INVULNERABILITY_SECONDS
            continue
        alive.append(rock)
    rocks = alive


func _spawn_wave() -> void:
    if wind <= 0.0 or elapsed < _next_wave or _is_near_end(WAVE_CUTOFF_SECONDS):
        return
    var interval: float = _random.range_float(WAVE_INTERVAL_MIN_SECONDS, WAVE_INTERVAL_MAX_SECONDS)
    _next_wave = elapsed + interval / maxf(WAVE_MIN_WIND, wind)
    var outside: float = DodgeWave.START_RADIUS * WAVE_OUTSIDE_MARGIN
    var x: float = -outside if _random.chance(0.5) else field_size.x + outside
    var center: Vector2 = Vector2(x, _random.range_float(0.0, field_size.y))
    waves.append(DodgeWave.new(center, field_size.x * WAVE_SPEED_WIDTHS, field_size.length() * WAVE_REACH_FACTOR))
    waves_spawned += 1


func _update_waves(delta: float) -> void:
    var alive: Array[DodgeWave] = []
    for wave: DodgeWave in waves:
        wave.advance(delta)
        if wave.is_gone():
            continue
        if not is_protected() and not wave.has_hit and wave.reaches(ship, SHIP_RADIUS):
            wave.has_hit = true
            hull.add(-WAVE_DAMAGE)
            _invulnerable = WAVE_INVULNERABILITY_SECONDS
        alive.append(wave)
    waves = alive
