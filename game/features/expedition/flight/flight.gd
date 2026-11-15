class_name Flight
extends RefCounted
## Tramo espacial hacia un planeta. La dificultad sale de la expedición (motor e instrumentos) y del
## destino (densidad y radiación). La FASE hace la nave intangible mientras se mantiene, y su carga no
## se recupera durante el tramo. Cada `step` deja en `events` lo que la vista debe contar.


enum Status { RUNNING, ARRIVED, DESTROYED }
enum EventKind { ROCK_HIT, WAVE_HIT, LASER_HIT, PICKUP, LASER_WARNING, WAVE_WARNING, FRONT_WARNING, PHASE_EMPTY }

const FIELD := Vector2(1280, 760)
const PLAY_AREA := Rect2(46, 100, 1174, 610)
const SHIP_RADIUS := 17.0
const SHIP_START := Vector2(180, 380)
const SEED := 44117
const SEED_PER_LEG := 9173

const PRACTICE_DURATION := 14.0
const PRACTICE_DENSITY := 0.45
## Sin generar peligros en los últimos segundos del tramo.
const ROCK_CUTOFF := 1.5
const ORB_CUTOFF := 1.0
const HAZARD_CUTOFF := 3.0

const ROCK_RADII: Array[float] = [14.0, 18.0, 22.0, 28.0, 34.0, 42.0]
const ROCK_DAMAGE := 11
const ROCK_INVULNERABILITY := 1.15
const WAVE_DAMAGE := 15
const WAVE_INVULNERABILITY := 1.0
const LASER_DAMAGE := 26
const LASER_INVULNERABILITY := 1.1
const RADIATION_DPS := 17.0
## Fracción de la distancia que el imán acerca un orbe en cada fotograma de 60 FPS.
const MAGNET_PULL := 0.14
const PICKUP_MARGIN := 15.0
const ORB_RESOURCES: Array[Catalog.Res] = [Catalog.Res.CRYSTAL, Catalog.Res.CRYSTAL, Catalog.Res.METAL, Catalog.Res.FUEL]


class Event:
    var kind: EventKind
    var position: Vector2
    var quantity: int
    var res: Catalog.Res
    var side: FlightHazards.Side

    func _init(p_kind: EventKind, p_position: Vector2, p_quantity: int = 0) -> void:
        kind = p_kind
        position = p_position
        quantity = p_quantity


var planet: PlanetSpec
var leg: int
var is_practice: bool
var duration: float
var density: float
var radiation: float
## Solo meteoritos: sin orbes, cañones, ondas ni radiación. Las rocas siguen haciendo daño.
var rocks_only: bool = false

## Posición de la nave: la lleva un `MovementBody` del toolkit, confinado al área de juego.
var ship: Vector2:
    get:
        return _body.position
var elapsed: float = 0.0
var in_phase: bool = false
var invulnerable: float = 0.0
var collected: Dictionary = {Catalog.Res.METAL: 0, Catalog.Res.CRYSTAL: 0, Catalog.Res.FUEL: 0}
var events: Array[Event] = []

var rocks: Array[FlightHazards.Rock] = []
var orbs: Array[FlightHazards.Orb] = []
var waves: Array[FlightHazards.Wave] = []
var lasers: Array[FlightHazards.Laser] = []
var fronts: Array[FlightHazards.Front] = []

var _expedition: Expedition
var _rng: GameRandom
var _input: ManualController = ManualController.new()
var _body: MovementBody
var _phase_ran_dry: bool = false
var _next_rock: float = 1.0
var _next_orb: float = 2.0
var _next_laser: float
var _next_wave: float
var _next_front: float


func _init(expedition: Expedition, p_planet: PlanetSpec, p_leg: int, p_is_practice: bool) -> void:
    _expedition = expedition
    planet = p_planet
    leg = p_leg
    is_practice = p_is_practice
    _rng = GameRandom.new(SEED + leg * SEED_PER_LEG)
    _body = MovementBody.new(_input, MovementProfile.new(expedition.speed(), 0.0, 0.0), SHIP_START)
    duration = PRACTICE_DURATION if is_practice else planet.travel_seconds
    density = PRACTICE_DENSITY if is_practice else planet.density
    radiation = 0.0 if is_practice else planet.radiation
    _next_laser = duration * 0.22
    _next_wave = duration * 0.33
    _next_front = duration * 0.16


## Tramo de solo meteoritos con la frecuencia (`p_density`) y la duración que se pidan, sobre un planeta de fondo.
static func meteor_field(expedition: Expedition, p_planet: PlanetSpec, p_density: float, seconds: float) -> Flight:
    var flight: Flight = Flight.new(expedition, p_planet, 1, false)
    flight.rocks_only = true
    flight.density = p_density
    flight.radiation = 0.0
    flight.duration = seconds
    return flight


func progress() -> float:
    return minf(1.0, elapsed / duration)


func is_protected() -> bool:
    return in_phase or invulnerable > 0.0


## Un paso de simulación. `move` en -1..1 por eje; `wants_phase` mientras se mantiene la tecla.
func step(delta: float, move: Vector2, wants_phase: bool) -> Status:
    events.clear()
    var t: float = elapsed
    var p: float = progress()
    _update_phase(delta, wants_phase)
    var speed: float = _expedition.speed() * (Expedition.PHASE_BOOST if in_phase else 1.0)
    _body.profile.max_speed = maxf(speed, MovementProfile.MIN_SPEED)
    _input.set_direction(move)
    if delta > 0.0:
        _body.step(delta)
        _body.confine(PLAY_AREA)

    _spawn(t, p)
    _update_rocks(delta)
    _update_orbs(delta)
    _update_waves(delta)
    _update_lasers(delta)
    _update_fronts(delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    elapsed += delta

    if _expedition.is_destroyed():
        return Status.DESTROYED
    if t >= duration:
        return Status.ARRIVED
    return Status.RUNNING


func _update_phase(delta: float, wants_phase: bool) -> void:
    in_phase = wants_phase and _expedition.phase.current > 0.0
    if not in_phase:
        return
    _expedition.phase.add(-_expedition.phase_drain() * delta)
    if _expedition.phase.current <= 0.0 and not _phase_ran_dry:
        _phase_ran_dry = true
        events.append(Event.new(EventKind.PHASE_EMPTY, ship))


func _spawn(t: float, p: float) -> void:
    if t >= _next_rock and t < duration - ROCK_CUTOFF:
        _next_rock = t + (0.92 - 0.62 * pow(p, 1.1)) / density
        var count: int = 2 if p > 0.55 and _rng.chance(0.4) else 1
        for i: int in count:
            _spawn_rock(p)
    if is_practice or rocks_only:
        return
    if t >= _next_orb and t < duration - ORB_CUTOFF:
        _next_orb = t + _rng.range_float(1.5, 2.8)
        var y: float = _rng.range_float(PLAY_AREA.position.y + 30.0, PLAY_AREA.end.y - 30.0)
        var res: Catalog.Res = ORB_RESOURCES[_rng.range_int(0, ORB_RESOURCES.size() - 1)]
        orbs.append(FlightHazards.Orb.new(Vector2(FIELD.x + 20.0, y), res, _rng.range_int(4, 9), (3.0 + 1.4 * p) * 60.0))
    if t >= duration - HAZARD_CUTOFF:
        return
    if t >= _next_laser:
        _next_laser = t + _rng.range_float(7.5, 11.5) / maxf(0.6, density)
        var horizontal: bool = _rng.chance(0.5)
        lasers.append(FlightHazards.Laser.new(horizontal, ship.y if horizontal else ship.x))
        events.append(Event.new(EventKind.LASER_WARNING, ship))
    if t >= _next_wave:
        _next_wave = t + _rng.range_float(8.0, 12.0) / maxf(0.6, density)
        var x: float = -60.0 if _rng.chance(0.5) else FIELD.x + 60.0
        var center: Vector2 = Vector2(x, _rng.range_float(PLAY_AREA.position.y, PLAY_AREA.end.y))
        waves.append(FlightHazards.Wave.new(center, _expedition.speed() * 1.35 + 48.0))
        events.append(Event.new(EventKind.WAVE_WARNING, center))
    if radiation > 0.0 and t >= _next_front:
        _next_front = t + _rng.range_float(9.0, 13.0) / maxf(0.6, radiation)
        var side: FlightHazards.Side = _rng.range_int(0, 3) as FlightHazards.Side
        var thickness: float = float(_rng.range_int(130, 210))
        fronts.append(FlightHazards.Front.new(side, thickness, (1.5 + 1.1 * radiation) * 60.0, FIELD))
        var warning: Event = Event.new(EventKind.FRONT_WARNING, ship)
        warning.side = side
        events.append(warning)


func _spawn_rock(p: float) -> void:
    var radius: float = ROCK_RADII[_rng.range_int(0, ROCK_RADII.size() - 1)]
    var y: float = _rng.range_float(PLAY_AREA.position.y + 20.0, PLAY_AREA.end.y - 20.0)
    var speed: float = (3.6 + 4.4 * p) * (0.8 + 0.3 * density) * _rng.range_float(0.85, 1.2) * 60.0
    var drift: float = _rng.range_float(-60.0, 60.0) if p > 0.4 else 0.0
    rocks.append(FlightHazards.Rock.new(Vector2(FIELD.x + radius, y), radius, speed, drift, _rng))


func _update_rocks(delta: float) -> void:
    var alive: Array[FlightHazards.Rock] = []
    for rock: FlightHazards.Rock in rocks:
        rock.position += Vector2(-rock.speed, rock.drift) * delta
        rock.spin += rock.spin_speed * delta
        if rock.position.y < PLAY_AREA.position.y or rock.position.y > PLAY_AREA.end.y:
            rock.drift = -rock.drift
        if rock.position.x + rock.radius < -20.0:
            continue
        if not is_protected() and not is_practice and rock.hits(ship, SHIP_RADIUS):
            _hurt(EventKind.ROCK_HIT, ROCK_DAMAGE, ROCK_INVULNERABILITY, rock.position)
            _expedition.damage_rocks += ROCK_DAMAGE
            continue
        alive.append(rock)
    rocks = alive


func _update_orbs(delta: float) -> void:
    var alive: Array[FlightHazards.Orb] = []
    var magnet: float = _expedition.magnet_radius()
    var pull: float = 1.0 - pow(1.0 - MAGNET_PULL, delta * 60.0)
    for orb: FlightHazards.Orb in orbs:
        orb.position.x -= orb.speed * delta
        var distance: float = orb.position.distance_to(ship)
        if magnet > 0.0 and distance < magnet:
            orb.position += (ship - orb.position) * pull
        if distance < SHIP_RADIUS + PICKUP_MARGIN:
            var quantity: int = orb.quantity * _expedition.pickup_factor()
            _expedition.add_resource(orb.res, quantity)
            _expedition.orbs_taken += 1
            collected[orb.res] = int(collected[orb.res]) + quantity
            var pickup: Event = Event.new(EventKind.PICKUP, orb.position, quantity)
            pickup.res = orb.res
            events.append(pickup)
            continue
        if orb.position.x >= -30.0:
            alive.append(orb)
    orbs = alive


func _update_waves(delta: float) -> void:
    var alive: Array[FlightHazards.Wave] = []
    for wave: FlightHazards.Wave in waves:
        wave.radius += wave.speed * delta
        if wave.radius > FlightHazards.Wave.MAX_RADIUS:
            continue
        if not is_protected() and not wave.has_hit and wave.reaches(ship, SHIP_RADIUS):
            wave.has_hit = true
            _hurt(EventKind.WAVE_HIT, WAVE_DAMAGE, WAVE_INVULNERABILITY, ship)
        alive.append(wave)
    waves = alive


func _update_lasers(delta: float) -> void:
    var alive: Array[FlightHazards.Laser] = []
    for laser: FlightHazards.Laser in lasers:
        laser.elapsed += delta
        if laser.is_over():
            continue
        if laser.is_firing() and not is_protected() and laser.rect(FIELD).has_point(ship):
            _hurt(EventKind.LASER_HIT, LASER_DAMAGE, LASER_INVULNERABILITY, ship)
            _expedition.damage_laser += LASER_DAMAGE
        alive.append(laser)
    lasers = alive


func _update_fronts(delta: float) -> void:
    var alive: Array[FlightHazards.Front] = []
    for front: FlightHazards.Front in fronts:
        front.advance(delta)
        if front.is_gone(FIELD):
            continue
        if not is_protected() and front.rect(FIELD).has_point(ship):
            var dose: float = RADIATION_DPS * radiation * (1.0 - _expedition.radiation_mitigation()) * delta
            _expedition.damage(dose)
            _expedition.damage_radiation += dose
        alive.append(front)
    fronts = alive


func _hurt(kind: EventKind, quantity: int, invulnerability: float, where: Vector2) -> void:
    _expedition.damage(float(quantity))
    invulnerable = invulnerability
    events.append(Event.new(kind, where, quantity))


## Segundos de fase que quedan con la carga actual.
func phase_seconds_left() -> float:
    return _expedition.phase.current / _expedition.phase_drain()
