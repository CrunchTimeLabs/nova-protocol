class_name CircuitMission
extends RefCounted
## Configuración de la misión del circuito: reparto por acción (D14). Ambos jugadores ven el mismo tablero.


const ROLE_ORDER: Array[int] = [CircuitRole.Role.ROTATOR, CircuitRole.Role.SWAPPER]
const BOARD_SIZE: int = 5
const BOARD_SEED: int = 1


static func roles() -> RoleTable:
    var table: RoleTable = RoleTable.new()
    table.allow(CircuitRole.Role.ROTATOR, CircuitCommand.Kind.ROTATE_TILE)
    table.allow(CircuitRole.Role.SWAPPER, CircuitCommand.Kind.SWAP_TILES)
    table.show_key(CircuitRole.Role.ROTATOR, CircuitMatch.KEY_GRID)
    table.show_key(CircuitRole.Role.SWAPPER, CircuitMatch.KEY_GRID)
    return table


## Reglas nuevas con el tablero de la misión (el anfitrión y cada réplica parten del mismo).
static func new_match() -> CircuitMatch:
    var config: PipeBoardConfig = PipeBoardConfig.center_target(BOARD_SIZE, BOARD_SIZE, BOARD_SEED)
    return CircuitMatch.new(CircuitGenerator.new(CircuitConfig.from_pipe(config)).build())
