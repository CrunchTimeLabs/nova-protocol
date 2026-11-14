extends BaseTest
## Integración de la misión de órbita en pantalla dividida con el protocolo real: cada rol recibe su vista y el piloto mueve la nave.


func test_split_screen_pilot_thrust_reaches_the_station() -> void:
    var session: MissionSession = MissionSession.build(
            SessionOptions.new(),
            func() -> MatchRules: return OrbitMatch.new(),
            OrbitMission.roles(),
            OrbitMission.ROLE_ORDER,
            )
    for _i: int in range(3):
        session.poll()
    var station: MatchClient = session.clients[0]
    var pilot: MatchClient = session.clients[1]
    check(station.is_joined() and pilot.is_joined(), "ambos jugadores entraron")
    check_equal(station.role, OrbitRole.Role.STATION, "el primero es la estación")
    check_equal(pilot.role, OrbitRole.Role.PILOT, "el segundo es el piloto")
    var untouched: OrbitMatch = OrbitMatch.new()
    pilot.send_command(OrbitCommand.Kind.SET_THRUST, {"x": 0.0, "y": 1.0})
    station.send_command(OrbitCommand.Kind.SET_THRUST, {"x": 0.0, "y": 1.0})
    for _i: int in range(60):
        session.poll()
        session.step(1.0 / 60.0)
        untouched.step(1.0 / 60.0)
    session.poll()
    var seen: OrbitMatch = station.replica as OrbitMatch
    var pilot_view: OrbitMatch = pilot.replica as OrbitMatch
    check(seen.body.position.distance_to(untouched.body.position) > 0.001, "la estación ve la nave desviada por el piloto")
    check(pilot_view.fuel_ratio() < 1.0, "el piloto ve gastarse el combustible")
    check_equal(pilot_view.body.position, OrbitMatch.new().body.position, "el piloto no recibe la órbita")
    check_equal(seen.fuel_ratio(), 1.0, "la estación no recibe el combustible")
    session.close()


func test_circuit_roles_split_by_action() -> void:
    var session: MissionSession = MissionSession.build(
            SessionOptions.new(),
            func() -> MatchRules: return CircuitMission.new_match(),
            CircuitMission.roles(),
            CircuitMission.ROLE_ORDER,
            )
    for _i: int in range(3):
        session.poll()
    var rotator: MatchClient = session.clients[0]
    var swapper: MatchClient = session.clients[1]
    var host_board: PipeBoard = ((session.host as MatchHost).rules() as CircuitMatch).grid.board
    var turns_before: int = host_board.rotation_at(Vector2i(0, 0))
    swapper.send_command(CircuitCommand.Kind.ROTATE_TILE, {"x": 0, "y": 0, "steps": 1})
    for _i: int in range(2):
        session.poll()
    check_equal(host_board.rotation_at(Vector2i(0, 0)), turns_before, "el intercambiador no puede girar")
    rotator.send_command(CircuitCommand.Kind.ROTATE_TILE, {"x": 0, "y": 0, "steps": 1})
    for _i: int in range(2):
        session.poll()
        session.step(1.0 / 60.0)
    session.poll()
    check_equal((host_board.rotation_at(Vector2i(0, 0)) - turns_before + 4) % 4, 1, "el rotador gira una vez")
    var seen_board: PipeBoard = (swapper.replica as CircuitMatch).grid.board
    check_equal(seen_board.rotation_at(Vector2i(0, 0)), host_board.rotation_at(Vector2i(0, 0)), "el otro jugador ve el giro")
    session.close()
