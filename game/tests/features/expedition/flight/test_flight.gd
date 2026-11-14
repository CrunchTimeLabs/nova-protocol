extends BaseTest
## Capa 3 (minijuego): el tramo es determinista, la nave no sale del área, la fase no se recarga y la práctica no hace daño.


var _catalog: Catalog
var _expedition: Expedition


func before_each() -> void:
    _catalog = Catalog.new()
    _expedition = _new_ready_expedition()


func _new_ready_expedition() -> Expedition:
    var expedition: Expedition = Expedition.new(_catalog)
    expedition.add_resource(Catalog.Res.METAL, 160)
    expedition.assign_engine()
    expedition.prepare_ship()
    return expedition


func _fly(flight: Flight, phase_every: int) -> Flight.Status:
    var status: Flight.Status = Flight.Status.RUNNING
    var frame: int = 0
    while status == Flight.Status.RUNNING:
        var wobble: Vector2 = Vector2(0.0, sin(float(frame) * 0.05))
        status = flight.step(1.0 / 60.0, wobble, phase_every > 0 and frame % phase_every == 0)
        frame += 1
    return status


func test_same_inputs_give_the_same_outcome() -> void:
    var first: Flight = Flight.new(_expedition, _catalog.planet("luna"), 1, false)
    var status: Flight.Status = _fly(first, 0)
    var second_expedition: Expedition = _new_ready_expedition()
    var second: Flight = Flight.new(second_expedition, _catalog.planet("luna"), 1, false)
    check_equal(_fly(second, 0), status, "mismo final")
    check_approx(second_expedition.hull.current, _expedition.hull.current, "mismo daño")
    check_equal(second_expedition.amount(Catalog.Res.METAL), _expedition.amount(Catalog.Res.METAL), "mismos orbes")


func test_practice_arrives_unhurt_and_the_ship_stays_inside_the_play_area() -> void:
    var flight: Flight = Flight.new(_expedition, _catalog.planet("luna"), 0, true)
    var status: Flight.Status = Flight.Status.RUNNING
    while status == Flight.Status.RUNNING:
        status = flight.step(1.0 / 60.0, Vector2(1.0, 1.0), false)
        check(Flight.PLAY_AREA.grow(0.001).has_point(flight.ship), "la nave no sale del área de juego")
    check_equal(status, Flight.Status.ARRIVED, "la práctica siempre llega")
    check_approx(_expedition.hull.current, float(_expedition.max_hull()), "sin daño")
    check(flight.elapsed >= Flight.PRACTICE_DURATION, "dura lo que dice")


func test_phase_drains_once_and_never_recharges() -> void:
    var flight: Flight = Flight.new(_expedition, _catalog.planet("luna"), 0, true)
    var empty_events: int = 0
    var lowest: float = _expedition.phase.current
    for frame: int in 60 * 6:
        flight.step(1.0 / 60.0, Vector2.ZERO, frame < 60 * 5)
        for event: Flight.Event in flight.events:
            if event.kind == Flight.EventKind.PHASE_EMPTY:
                empty_events += 1
        check(_expedition.phase.current <= lowest + 0.0001, "la fase nunca sube (fotograma %d)" % frame)
        lowest = minf(lowest, _expedition.phase.current)
    check_approx(_expedition.phase.current, 0.0, "5 s seguidos agotan la carga")
    check_equal(empty_events, 1, "el aviso de fase agotada sale una sola vez")
    check(not flight.in_phase, "sin carga no hay fase aunque se pida")


func test_damage_destroys_the_ship() -> void:
    _expedition.hull = ResourceMeter.new(1.0, 1.0)
    var flight: Flight = Flight.new(_expedition, _catalog.planet("marte"), 2, false)
    check_equal(_fly(flight, 0), Flight.Status.DESTROYED, "con 1 de integridad, Marte destruye la nave")
