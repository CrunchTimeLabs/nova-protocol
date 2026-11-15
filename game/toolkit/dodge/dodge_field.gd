class_name DodgeField
extends RefCounted
## Campo de esquivar: una nave se mueve dentro de un recuadro de tamaño dado y cruzan rocas de derecha a izquierda.
## Cada golpe resta casco y da unos segundos de invulnerabilidad. Termina al llegar a `duration` o al quedarse sin casco.
## Todo el azar usa la semilla; el tamaño del campo es un parámetro (rocas, velocidades y nave se escalan con él).
## Sin nodos: la vista lee `ship`, `rocks`, `hull`, `elapsed` y `is_protected()`.


enum Status { RUNNING, ARRIVED, DESTROYED }

const SHIP_RADIUS: float = 12.0
## Anchos de campo que recorre la nave por segundo.
const SHIP_SPEED_WIDTHS: float = 0.5
const SHIP_START: Vector2 = Vector2(0.15, 0.5)
const HULL_MAX: float = 100.0
const ROCK_DAMAGE: float = 25.0
const INVULNERABILITY_SECONDS: float = 1.2
const FIRST_ROCK_SECONDS: float = 1.0
## Segundos entre rocas con densidad 1.0 (a menor densidad, más espacio).
const ROCK_INTERVAL_SECONDS: float = 1.2
const INTERVAL_JITTER: float = 0.2
## Sin rocas nuevas en los últimos segundos.
const ROCK_CUTOFF_SECONDS: float = 1.5
## Alturas del campo que miden los radios de las rocas.
const ROCK_RADII_HEIGHTS: Array[float] = [0.03, 0.045, 0.06]
const ROCK_SPEED_MIN_WIDTHS: float = 0.18
const ROCK_SPEED_MAX_WIDTHS: float = 0.30
const ROCK_DRIFT_HEIGHTS: float = 0.08
const ROCK_MARGIN_HEIGHTS: float = 0.05

var field_size: Vector2
var density: float
var duration: float
var hull: ResourceMeter = ResourceMeter.new(HULL_MAX, HULL_MAX)
var elapsed: float = 0.0
var status: Status = Status.RUNNING
var rocks: Array[DodgeRock] = []
## Cuántas rocas han nacido (para medir la frecuencia).
var spawned: int = 0
var ship: Vector2:
    get:
        return _body.position

var _random: GameRandom
var _controller: ManualController = ManualController.new()
var _body: MovementBody
var _ship_area: Rect2
var _invulnerable: float = 0.0
var _next_rock: float = FIRST_ROCK_SECONDS


func _init(p_size: Vector2, p_density: float, p_duration: float, seed_value: int) -> void:
    field_size = p_size
    density = maxf(p_density, 0.01)
    duration = p_duration
    _random = GameRandom.new(seed_value)
    _ship_area = Rect2(
            Vector2(SHIP_RADIUS, SHIP_RADIUS),
            p_size - Vector2(SHIP_RADIUS, SHIP_RADIUS) * 2.0,
            )
    _body = MovementBody.new(_controller, MovementProfile.new(p_size.x * SHIP_SPEED_WIDTHS, 0.0, 0.0), p_size * SHIP_START)


func is_protected() -> bool:
    return _invulnerable > 0.0


## Un paso. `move` en -1..1 por eje. Terminada la partida ya no cambia nada.
func step(delta: float, move: Vector2) -> Status:
    if status != Status.RUNNING or delta <= 0.0:
        return status
    _controller.set_direction(move)
    _body.step(delta)
    _body.confine(_ship_area)
    _spawn()
    _update_rocks(delta)
    _invulnerable = maxf(0.0, _invulnerable - delta)
    elapsed += delta
    if hull.current <= 0.0:
        status = Status.DESTROYED
    elif elapsed >= duration:
        status = Status.ARRIVED
    return status


func _spawn() -> void:
    if elapsed < _next_rock or elapsed >= duration - ROCK_CUTOFF_SECONDS:
        return
    var jitter: float = _random.range_float(1.0 - INTERVAL_JITTER, 1.0 + INTERVAL_JITTER)
    _next_rock = elapsed + ROCK_INTERVAL_SECONDS / density * jitter
    var radius: float = float(_random.pick(ROCK_RADII_HEIGHTS)) * field_size.y
    var margin: float = ROCK_MARGIN_HEIGHTS * field_size.y
    var y: float = _random.range_float(margin, field_size.y - margin)
    var speed: float = _random.range_float(ROCK_SPEED_MIN_WIDTHS, ROCK_SPEED_MAX_WIDTHS) * field_size.x
    var drift: float = _random.range_float(-ROCK_DRIFT_HEIGHTS, ROCK_DRIFT_HEIGHTS) * field_size.y
    rocks.append(DodgeRock.new(Vector2(field_size.x + radius, y), radius, speed, drift, _random))
    spawned += 1


func _update_rocks(delta: float) -> void:
    var alive: Array[DodgeRock] = []
    for rock: DodgeRock in rocks:
        rock.position += Vector2(-rock.speed, rock.drift) * delta
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
