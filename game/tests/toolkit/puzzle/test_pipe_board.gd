extends BaseTest
## Capa 3 (entidad): tablero de piezas giratorias con camino garantizado, uno o varios destinos.


const STRAIGHT: PipeTile.Shape = PipeTile.Shape.STRAIGHT
const TEE: PipeTile.Shape = PipeTile.Shape.TEE
## Rotaciones de un recto: 0 y 2 = vertical, 1 y 3 = horizontal.
const HORIZONTAL: int = 1
const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]


## Tablero 3x1 a mano: fuente al oeste de (0,0), destino al este de (2,0).
func _line() -> PipeBoard:
    var sources: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST)]
    var targets: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(2, 0), PipeTile.Side.EAST)]
    var board: PipeBoard = PipeBoard.new(3, 1, sources, targets)
    var tiles: Array[PipeTile] = []
    var solution: Array[int] = []
    for i: int in 3:
        tiles.append(PipeTile.new(STRAIGHT, HORIZONTAL))
        solution.append(HORIZONTAL)
    board.load_layout(tiles, solution)
    return board


## Tablero 3x2 a mano: un TEE en (1,0) reparte a dos destinos, (2,0) y (1,1).
func _fork() -> PipeBoard:
    var sources: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST)]
    var targets: Array[PipeTerminal] = [
        PipeTerminal.new(Vector2i(2, 0), PipeTile.Side.EAST),
        PipeTerminal.new(Vector2i(1, 1), PipeTile.Side.SOUTH),
    ]
    var board: PipeBoard = PipeBoard.new(3, 2, sources, targets)
    var tiles: Array[PipeTile] = [
        PipeTile.new(STRAIGHT, HORIZONTAL), PipeTile.new(TEE, 2), PipeTile.new(STRAIGHT, HORIZONTAL),
        PipeTile.new(STRAIGHT, 0), PipeTile.new(STRAIGHT, 0), PipeTile.new(STRAIGHT, 0),
    ]
    var solution: Array[int] = [HORIZONTAL, 2, HORIZONTAL, 0, 0, 0]
    board.load_layout(tiles, solution)
    return board


func _solve(board: PipeBoard) -> void:
    for y: int in board.height:
        for x: int in board.width:
            var cell: Vector2i = Vector2i(x, y)
            board.rotate_tile(cell, board.solution_rotation_at(cell) - board.rotation_at(cell))


func test_same_seed_same_board_and_it_is_solvable_by_rotating() -> void:
    var factories: Array[Callable] = [
            PipeBoardConfig.single_route,
            PipeBoardConfig.two_targets,
            PipeBoardConfig.center_target,
            PipeBoardConfig.two_sources_inner_targets,
            ]
    for factory: Callable in factories:
        for seed_value: int in SEEDS:
            var first: PipeBoard = PipeBoardGenerator.new(factory.call(5, 5, seed_value) as PipeBoardConfig).build()
            var twin: PipeBoard = PipeBoardGenerator.new(factory.call(5, 5, seed_value) as PipeBoardConfig).build()
            check_equal(first.snapshot(), twin.snapshot(), "misma semilla %d, mismo tablero" % seed_value)
            check(not first.is_solved(), "el tablero %d nace desordenado" % seed_value)
            _solve(first)
            check(first.is_solved(), "girando piezas el tablero %d se resuelve" % seed_value)


func test_connection_is_detected_and_broken_by_rotation() -> void:
    var board: PipeBoard = _line()
    check(board.is_solved() and board.is_powered(Vector2i(2, 0)), "recto de punta a punta conduce")
    board.rotate_tile(Vector2i(1, 0))
    check(not board.is_solved() and not board.is_powered(Vector2i(1, 0)), "una pieza girada corta el paso")
    check(board.is_powered(Vector2i(0, 0)), "lo anterior a la rotura sigue con energía")
    board.rotate_tile(Vector2i(1, 0), -1)
    check(board.is_solved(), "volver a girar reconecta")
    var before: Dictionary = board.snapshot()
    check(not board.rotate_tile(Vector2i(3, 0)), "una celda fuera del tablero se rechaza")
    check_equal(board.snapshot(), before, "y no cambia nada")


func test_swapping_tiles_moves_pieces_and_is_reversible() -> void:
    var board: PipeBoard = _fork()
    var before: Dictionary = board.snapshot()
    check(board.swap_tiles(Vector2i(1, 0), Vector2i(0, 1)), "dos celdas válidas se intercambian")
    check(board.shape_at(Vector2i(0, 1)) == TEE and not board.is_solved(), "la pieza viaja con su forma y rompe la conexión")
    board.swap_tiles(Vector2i(0, 1), Vector2i(1, 0))
    check_equal(board.snapshot(), before, "intercambiar de nuevo lo deja igual")
    check(not board.swap_tiles(Vector2i(0, 0), Vector2i(9, 9)) and not board.swap_tiles(Vector2i(0, 0), Vector2i(0, 0)), "fuera del tablero o la misma celda se rechaza")
    check_equal(board.snapshot(), before, "y no cambia nada")


func test_source_only_feeds_when_its_tile_faces_the_entry_side() -> void:
    var board: PipeBoard = _line()
    board.rotate_tile(Vector2i(0, 0))
    check_equal(board.lit_count(), 0, "si la pieza de la fuente no mira a la entrada, no hay energía")
    check(not board.is_powered(Vector2i(0, 0)), "ni siquiera esa celda")


func test_every_target_must_be_lit_to_solve() -> void:
    var board: PipeBoard = _fork()
    check_equal(board.lit_count(), 2, "con el TEE bien puesto los dos destinos se encienden")
    check(board.is_solved(), "resuelto")
    board.rotate_tile(Vector2i(1, 0), 1)
    check_equal(board.lit_count(), 1, "girar el TEE apaga solo el destino que dependía de su lado")
    check(board.is_target_lit(1) and not board.is_target_lit(0), "queda el de abajo")
    check(not board.is_solved(), "con uno apagado no está resuelto")


func test_snapshot_survives_json_round_trip() -> void:
    var board: PipeBoard = PipeBoardGenerator.new(PipeBoardConfig.two_targets(5, 5, 3)).build()
    var restored: PipeBoard = PipeBoard.new(1, 1, [], [])
    restored.restore(JSON.parse_string(JSON.stringify(board.snapshot())) as Dictionary)
    check_equal(restored.snapshot(), board.snapshot(), "el tablero vuelve idéntico")
    _solve(restored)
    check(restored.is_solved(), "y sigue siendo resoluble")
