extends BaseTest
## Capa 3: las órdenes del circuito se validan y el tablero decide; lo inválido no cambia nada y el estado viaja por JSON.

var _match: CircuitMatch


func before_each() -> void:
    _match = CircuitMission.new_match()


func test_rotate_and_swap_commands() -> void:
    var board: PipeBoard = _match.grid.board
    var turns: int = board.rotation_at(Vector2i(1, 1))
    check(_match.apply(0, Command.new(0, CircuitCommand.Kind.ROTATE_TILE, {"x": 1, "y": 1, "steps": 1})), "gira")
    check_equal((board.rotation_at(Vector2i(1, 1)) - turns + 4) % 4, 1, "un cuarto de vuelta")
    var first: PipeTile.Shape = board.shape_at(Vector2i(0, 0))
    var second: PipeTile.Shape = board.shape_at(Vector2i(1, 0))
    check(_match.apply(0, Command.new(0, CircuitCommand.Kind.SWAP_TILES, {"ax": 0, "ay": 0, "bx": 1, "by": 0})), "intercambia")
    check_equal(board.shape_at(Vector2i(0, 0)), second, "la primera celda tiene la forma de la segunda")
    check_equal(board.shape_at(Vector2i(1, 0)), first, "y al revés")


func test_invalid_commands_change_nothing() -> void:
    var before: Dictionary = _match.snapshot()
    var invalid: Array[Command] = [
        Command.new(0, CircuitCommand.Kind.ROTATE_TILE, {"x": 99, "y": 0, "steps": 1}),
        Command.new(0, CircuitCommand.Kind.ROTATE_TILE, {"x": 0, "y": 0}),
        Command.new(0, CircuitCommand.Kind.ROTATE_TILE, {"x": "a", "y": 0, "steps": 1}),
        Command.new(0, CircuitCommand.Kind.SWAP_TILES, {"ax": 0, "ay": 0, "bx": 0, "by": 0}),
        Command.new(0, CircuitCommand.Kind.SWAP_TILES, {"ax": 0, "ay": 0, "bx": -1, "by": 0}),
        Command.new(0, 99, {}),
    ]
    for command: Command in invalid:
        check(not _match.apply(0, command), "se rechaza %s" % str(command.to_dict()))
    check_equal(_match.snapshot(), before, "nada cambió")


func test_snapshot_survives_json_into_a_replica() -> void:
    _match.apply(0, Command.new(0, CircuitCommand.Kind.ROTATE_TILE, {"x": 2, "y": 2, "steps": 1}))
    var replica: CircuitMatch = CircuitMission.new_match()
    replica.restore(JSON.parse_string(JSON.stringify(_match.snapshot())))
    check_equal(replica.grid.board.rotation_at(Vector2i(2, 2)), _match.grid.board.rotation_at(Vector2i(2, 2)), "la réplica refleja el giro")
    check_equal(replica.grid.is_solved(), _match.grid.is_solved(), "y el estado de energía")
