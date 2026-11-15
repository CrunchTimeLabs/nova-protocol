extends BaseTest
## Capa 3: la aceleración del piloto se convierte en empuje con escala y tope; sin la orden correcta nada cambia; es determinista.


var _match: OrbitMatch


func before_each() -> void:
    _match = OrbitMatch.new()


func test_same_commands_give_same_state() -> void:
    var finals: Array[Dictionary] = []
    for _run: int in range(2):
        var game: OrbitMatch = OrbitMatch.new()
        game.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 0.0, "y": 1.0}))
        for _i: int in range(120):
            game.step(1.0 / 60.0)
        game.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 0.0, "y": 0.0}))
        for _i: int in range(120):
            game.step(1.0 / 60.0)
        finals.append(game.snapshot())
    check_equal(finals[0], finals[1], "misma secuencia, mismo estado")


func test_thrust_is_scaled_and_capped() -> void:
    var gentle: OrbitMatch = OrbitMatch.new()
    var strong: OrbitMatch = OrbitMatch.new()
    gentle.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 1.0, "y": 0.0}))
    strong.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 100.0, "y": 0.0}))
    gentle.step(0.1)
    strong.step(0.1)
    check_equal(strong.snapshot(), gentle.snapshot(), "pedir 100 empuja lo mismo que el tope (%s)" % str(OrbitMatch.MAX_THRUST_LENGTH))


func test_invalid_payloads_are_refused_without_effect() -> void:
    var untouched: OrbitMatch = OrbitMatch.new()
    var invalid: Array[Dictionary] = [{}, {"x": 1.0}, {"x": "a", "y": 0.0}, {"x": NAN, "y": 0.0}, {"x": 0.0, "y": INF}]
    for payload: Dictionary in invalid:
        check(not _match.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, payload)), "se rechaza %s" % str(payload))
    check(not _match.apply(1, Command.new(1, 99, {"x": 0.0, "y": 0.0})), "un tipo de comando desconocido se rechaza")
    _match.step(0.5)
    untouched.step(0.5)
    check_equal(_match.snapshot(), untouched.snapshot(), "sin órdenes válidas solo actúa la gravedad")


func test_releasing_a_slot_stops_its_thrust() -> void:
    _match.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 1.0, "y": 0.0}))
    _match.release_slot(1)
    var other: OrbitMatch = OrbitMatch.new()
    _match.step(0.5)
    other.step(0.5)
    check_equal(_match.snapshot(), other.snapshot(), "tras salir el piloto, la nave no recibe su empuje")


func test_partial_snapshot_restores_only_what_it_carries() -> void:
    _match.apply(1, Command.new(1, OrbitCommand.Kind.SET_THRUST, {"x": 1.0, "y": 0.0}))
    for _i: int in range(60):
        _match.step(1.0 / 60.0)
    var replica: OrbitMatch = OrbitMatch.new()
    replica.restore({OrbitMatch.KEY_FUEL: 0.25})
    check_approx(replica.fuel_ratio(), 0.25, "solo combustible")
    check_equal((replica.snapshot()[OrbitMatch.KEY_ORBIT] as Dictionary)["x"], OrbitMatch.STAR_CENTER.x + OrbitMatch.ORBIT_RADIUS, "la órbita no se tocó")
    replica.restore({OrbitMatch.KEY_ORBIT: _match.snapshot()[OrbitMatch.KEY_ORBIT]})
    check_equal(replica.snapshot()[OrbitMatch.KEY_ORBIT], _match.snapshot()[OrbitMatch.KEY_ORBIT], "solo órbita")


func test_time_scale_slows_the_whole_orbit() -> void:
    var normal: OrbitMatch = OrbitMatch.new()
    var slow: OrbitMatch = OrbitMatch.new(0.25)
    for _i: int in range(120):
        normal.step(1.0 / 60.0)
        slow.step(1.0 / 60.0)
    var start: Vector2 = OrbitMatch.new().body.position
    var moved_normal: float = normal.body.position.distance_to(start)
    var moved_slow: float = slow.body.position.distance_to(start)
    check(moved_slow > 0.0 and moved_slow < moved_normal * 0.5, "con un cuarto de ritmo recorre mucho menos")


func test_phase_hold_is_validated_and_published() -> void:
    for payload: Dictionary in [{}, {"on": 1}, {"on": "true"}]:
        check(not _match.apply(0, Command.new(0, OrbitCommand.Kind.PHASE_HOLD, payload)), "se rechaza %s" % str(payload))
    check(not _match.phase_held, "lo rechazado no cambia nada")
    check(_match.apply(0, Command.new(0, OrbitCommand.Kind.PHASE_HOLD, {"on": true})), "on=true se acepta")
    check(_match.phase_held, "queda mantenida")
    var replica: OrbitMatch = OrbitMatch.new()
    replica.restore(JSON.parse_string(JSON.stringify(_match.snapshot())) as Dictionary)
    check(replica.phase_held, "la réplica la recibe por JSON")
    _match.apply(0, Command.new(0, OrbitCommand.Kind.PHASE_HOLD, {"on": false}))
    check(not _match.phase_held, "al soltar se apaga")
    _match.apply(0, Command.new(0, OrbitCommand.Kind.PHASE_HOLD, {"on": true}))
    _match.release_slot(0)
    check(not _match.phase_held, "si la estación se va, se suelta")
