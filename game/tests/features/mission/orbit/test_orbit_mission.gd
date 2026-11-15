extends BaseTest
## Las flechas del piloto se traducen a órdenes relativas al rumbo: → adelante, ← frenar, ↓ hacia dentro, ↑ hacia fuera.


func test_arrows_map_to_heading_commands() -> void:
    var cases: Array = [
        [Vector2(1, 0), Vector2(0, -1)],     # → adelante
        [Vector2(-1, 0), Vector2(0, 1)],     # ← frenar
        [Vector2(0, 1), Vector2(1, 0)],      # ↓ derecha del rumbo
        [Vector2(0, -1), Vector2(-1, 0)],    # ↑ izquierda del rumbo
        [Vector2.ZERO, Vector2.ZERO],
    ]
    for case: Array in cases:
        var command: Vector2 = OrbitMission.thrust_from_arrows(case[0] as Vector2)
        check(command.distance_to(case[1] as Vector2) < 0.0001, "flecha %s -> %s" % [str(case[0]), str(command)])


func test_every_role_is_configured() -> void:
    var table: RoleTable = OrbitMission.roles()
    for role: int in OrbitRole.Role.values():
        check(table.has_role(role), "el rol %s tiene permisos o visibilidad" % OrbitRole.Role.find_key(role))


func test_only_the_station_holds_phase_and_the_pilot_sees_it() -> void:
    var table: RoleTable = OrbitMission.roles()
    check(table.can_send(OrbitRole.Role.STATION, OrbitCommand.Kind.PHASE_HOLD), "la estación puede mantener la fase")
    check(not table.can_send(OrbitRole.Role.PILOT, OrbitCommand.Kind.PHASE_HOLD), "el piloto no")
    var seen: Dictionary = table.filter(OrbitRole.Role.PILOT, {OrbitMatch.KEY_PHASE: true, OrbitMatch.KEY_ORBIT: {}})
    check(seen.has(OrbitMatch.KEY_PHASE) and not seen.has(OrbitMatch.KEY_ORBIT), "el piloto recibe la fase y no la órbita")


func test_only_the_pilot_reports_a_crash_and_everyone_sees_the_outcome() -> void:
    var table: RoleTable = OrbitMission.roles()
    check(table.can_send(OrbitRole.Role.PILOT, OrbitCommand.Kind.REPORT_CRASH), "el piloto avisa del choque")
    check(not table.can_send(OrbitRole.Role.STATION, OrbitCommand.Kind.REPORT_CRASH), "la estación no")
    for role: int in OrbitRole.Role.values():
        check(table.filter(role, {OrbitMatch.KEY_OUTCOME: "WON"}).has(OrbitMatch.KEY_OUTCOME), "el rol %d ve el resultado" % role)
