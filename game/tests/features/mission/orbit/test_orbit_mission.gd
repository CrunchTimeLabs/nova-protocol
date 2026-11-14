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
