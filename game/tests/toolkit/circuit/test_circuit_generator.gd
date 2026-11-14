extends BaseTest
## Capa 3 (entidad): circuito generado con solución garantizada, holgura y semilla.


## Deshace los intercambios usando como referencia el mismo circuito sin mezclar piezas, y luego gira.
func _solve(board: PipeBoard, reference: PipeBoard) -> void:
    for y: int in board.height:
        for x: int in board.width:
            var cell: Vector2i = Vector2i(x, y)
            if board.shape_at(cell) == reference.shape_at(cell):
                continue
            for j: int in board.width * board.height:
                var other: Vector2i = Vector2i(j % board.width, j / board.width)
                if board.shape_at(other) == reference.shape_at(cell) and board.shape_at(other) != reference.shape_at(other):
                    board.swap_tiles(cell, other)
                    break
    for y: int in board.height:
        for x: int in board.width:
            var cell: Vector2i = Vector2i(x, y)
            board.rotate_tile(cell, board.solution_rotation_at(cell) - board.rotation_at(cell))


func _rotate_to_solution(board: PipeBoard) -> void:
    for y: int in board.height:
        for x: int in board.width:
            var cell: Vector2i = Vector2i(x, y)
            board.rotate_tile(cell, board.solution_rotation_at(cell) - board.rotation_at(cell))


func _config(factory: Callable, seed_value: int, shuffle_tiles: bool) -> CircuitConfig:
    var config: CircuitConfig = CircuitConfig.from_pipe(factory.call(5, 5, seed_value) as PipeBoardConfig)
    config.shuffle_tiles = shuffle_tiles
    return config




func test_generated_circuit_is_solvable_with_margin_and_reproducible() -> void:
    var factories: Array[Callable] = [
            PipeBoardConfig.single_route,
            PipeBoardConfig.two_targets,
            PipeBoardConfig.center_target,
            PipeBoardConfig.two_sources_inner_targets,
            ]
    var displaced: int = 0
    for factory: Callable in factories:
        for seed_value: int in [1, 2, 3, 4, 5, 6, 7, 8]:
            var grid: PowerGrid = CircuitGenerator.new(_config(factory, seed_value, true)).build()
            var twin: PowerGrid = CircuitGenerator.new(_config(factory, seed_value, true)).build()
            var plain: PowerGrid = CircuitGenerator.new(_config(factory, seed_value, false)).build()
            check_equal(grid.snapshot(), twin.snapshot(), "misma semilla %d, mismo circuito" % seed_value)
            check(not grid.is_solved(), "el circuito %d nace sin satisfacer" % seed_value)
            _rotate_to_solution(plain.board)
            for y: int in grid.board.height:
                for x: int in grid.board.width:
                    var cell: Vector2i = Vector2i(x, y)
                    if grid.board.shape_at(cell) != plain.board.shape_at(cell):
                        displaced += 1
                        check(plain.board.is_powered(cell), "solo se mueven piezas del tramo correcto (semilla %d)" % seed_value)
            _solve(grid.board, plain.board)
            check(grid.is_solved(), "con intercambios y giros el circuito %d se resuelve" % seed_value)
            var tightest: float = INF
            for i: int in grid.board.targets.size():
                tightest = minf(tightest, grid.delivered_to(i) / grid.demand_of(i))
            check(tightest >= 1.0 + CircuitConfig.DEFAULT_MARGIN - PowerGrid.EPSILON, "queda al menos el margen de holgura (semilla %d)" % seed_value)
    check(displaced > 0, "con shuffle_tiles activo hay piezas fuera de su celda")


func test_without_shuffle_tiles_rotating_is_enough() -> void:
    for seed_value: int in [1, 2, 3, 4]:
        var grid: PowerGrid = CircuitGenerator.new(_config(PipeBoardConfig.two_targets, seed_value, false)).build()
        for y: int in grid.board.height:
            for x: int in grid.board.width:
                var cell: Vector2i = Vector2i(x, y)
                grid.board.rotate_tile(cell, grid.board.solution_rotation_at(cell) - grid.board.rotation_at(cell))
        check(grid.is_solved(), "sin mezclar piezas el circuito %d se resuelve solo girando" % seed_value)


func test_loss_is_configurable_and_the_supply_covers_it() -> void:
    var lossless: PowerGrid = CircuitGenerator.new(CircuitConfig.new(PipeBoardConfig.single_route(5, 5, 2), 20.0, 0.0, 0.1, false)).build()
    var lossy: PowerGrid = CircuitGenerator.new(CircuitConfig.new(PipeBoardConfig.single_route(5, 5, 2), 20.0, 0.15, 0.1, false)).build()
    for grid: PowerGrid in [lossless, lossy]:
        for y: int in grid.board.height:
            for x: int in grid.board.width:
                var cell: Vector2i = Vector2i(x, y)
                grid.board.rotate_tile(cell, grid.board.solution_rotation_at(cell) - grid.board.rotation_at(cell))
    check(lossless.is_solved() and lossy.is_solved(), "con o sin pérdida la solución tallada se resuelve")
    check(is_equal_approx(lossless.delivered_to(0), 20.0 * 1.1), "sin pérdida la fuente es la demanda más el margen")
    check(lossy.supply_of(0) > lossless.supply_of(0), "con pérdida la fuente crece para compensarla")
