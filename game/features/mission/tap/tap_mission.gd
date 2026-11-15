class_name TapMission
extends RefCounted
## Configuración de la misión Tap: quién puede hacer y ver qué. El emisor (izquierda) crea popups y solo ve el tiempo;
## el receptor (derecha) los pulsa y ve popups, aciertos y tiempo.


## Orden en que los jugadores reciben rol al entrar.
const ROLE_ORDER: Array[int] = [TapRole.Role.SENDER, TapRole.Role.RECEIVER]


static func roles() -> RoleTable:
    var table: RoleTable = RoleTable.new()
    table.allow(TapRole.Role.SENDER, TapCommand.Kind.SPAWN)
    table.show_key(TapRole.Role.SENDER, TapMatch.KEY_TIME_LEFT)
    table.allow(TapRole.Role.RECEIVER, TapCommand.Kind.HIT)
    table.show_key(TapRole.Role.RECEIVER, TapMatch.KEY_TARGETS)
    table.show_key(TapRole.Role.RECEIVER, TapMatch.KEY_HITS)
    table.show_key(TapRole.Role.RECEIVER, TapMatch.KEY_TIME_LEFT)
    return table
