class_name OrbitMission
extends RefCounted
## Configuración de la misión de órbita: quién puede hacer y ver qué. Pilota la nave el piloto; la estación monitorea.


## Orden en que los jugadores reciben rol al entrar.
const ROLE_ORDER: Array[int] = [OrbitRole.Role.STATION, OrbitRole.Role.PILOT]


## De las flechas del piloto (x derecha, y abajo) a su orden relativa al rumbo (-y adelante, +y atrás, +x derecha, -x izquierda):
## → adelante, ← frenar, ↓ a la derecha del rumbo (hacia dentro), ↑ a la izquierda (hacia fuera).
static func thrust_from_arrows(arrows: Vector2) -> Vector2:
    return Vector2(arrows.y, -arrows.x)


static func roles() -> RoleTable:
    var table: RoleTable = RoleTable.new()
    table.show_key(OrbitRole.Role.STATION, OrbitMatch.KEY_ORBIT)
    table.allow(OrbitRole.Role.PILOT, OrbitCommand.Kind.SET_THRUST)
    table.show_key(OrbitRole.Role.PILOT, OrbitMatch.KEY_FUEL)
    table.allow(OrbitRole.Role.STATION, OrbitCommand.Kind.PHASE_HOLD)
    table.show_key(OrbitRole.Role.PILOT, OrbitMatch.KEY_PHASE)
    return table
