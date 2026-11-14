extends BaseTest
## La tabla de roles del circuito cubre todos los roles y todas las órdenes: un rol o comando nuevo sin configurar falla aquí.


func test_every_role_and_command_is_configured() -> void:
    var table: RoleTable = CircuitMission.roles()
    for role: int in CircuitRole.Role.values():
        check(table.has_role(role), "el rol %s tiene permisos o visibilidad" % CircuitRole.Role.find_key(role))
    for kind: int in CircuitCommand.Kind.values():
        var is_allowed: bool = false
        for role: int in CircuitRole.Role.values():
            is_allowed = is_allowed or table.can_send(role, kind)
        check(is_allowed, "la orden %s la puede enviar algún rol" % CircuitCommand.Kind.find_key(kind))
