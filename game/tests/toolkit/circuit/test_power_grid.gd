extends BaseTest
## Capa 3 (entidad): reparto de potencia sobre un tablero de piezas, con apagón por consumidor.


const STRAIGHT: PipeTile.Shape = PipeTile.Shape.STRAIGHT
const ELBOW: PipeTile.Shape = PipeTile.Shape.ELBOW
const TEE: PipeTile.Shape = PipeTile.Shape.TEE
## Rotaciones de un recto: 0 y 2 = vertical, 1 y 3 = horizontal.
const HORIZONTAL: int = 1


## Componente de prueba: se queda con la mitad, para comprobar que la rejilla usa el contrato.
class HalfComponent:
    extends CircuitComponent

    func transmit(power: float) -> float:
        return power * 0.5


## Tablero 3x1: fuente al oeste de (0,0), destino al este de (2,0); cada recto lleva su componente.
func _line(first: CircuitComponent = null, second: CircuitComponent = null, third: CircuitComponent = null) -> PipeBoard:
    var sources: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST)]
    var targets: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(2, 0), PipeTile.Side.EAST)]
    var board: PipeBoard = PipeBoard.new(3, 1, sources, targets)
    var tiles: Array[PipeTile] = [
        CircuitTile.new(STRAIGHT, HORIZONTAL, first),
        CircuitTile.new(STRAIGHT, HORIZONTAL, second),
        CircuitTile.new(STRAIGHT, HORIZONTAL, third),
    ]
    board.load_layout(tiles, [HORIZONTAL, HORIZONTAL, HORIZONTAL])
    return board


## Tablero 3x2: un TEE en (1,0) reparte a dos destinos, (2,0) y (1,1). Piezas planas: conducen como cable.
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


func test_power_travels_by_wire_and_breaks_with_the_connection() -> void:
    var board: PipeBoard = _line()
    var grid: PowerGrid = PowerGrid.new(board, [100.0], [40.0])
    check_equal(grid.delivered_to(0), 100.0, "por cable llega toda la potencia")
    check(grid.is_solved(), "y el consumidor queda satisfecho")
    board.rotate_tile(Vector2i(1, 0))
    check_equal(grid.delivered_to(0), 0.0, "una pieza girada corta el paso y se recalcula sola")
    check(not grid.is_solved(), "sin potencia no hay solución")


func test_component_transforms_the_power_passing_through_it() -> void:
    var grid: PowerGrid = PowerGrid.new(_line(null, HalfComponent.new()), [100.0], [40.0])
    check_equal(grid.power_at(Vector2i(1, 0)), 100.0, "a la celda entra la potencia sin transformar")
    check_equal(grid.delivered_to(0), 50.0, "al consumidor llega lo que deja pasar el componente")
    check(grid.is_solved(), "50 cubre una demanda de 40")


func test_tee_splits_equally_and_each_load_blacks_out_on_its_own() -> void:
    var grid: PowerGrid = PowerGrid.new(_fork(), [100.0], [40.0, 60.0])
    check_equal(grid.delivered_to(0), 50.0, "cada rama del TEE recibe la mitad")
    check_equal(grid.delivered_to(1), 50.0, "la otra también")
    check(grid.is_satisfied(0), "50 cubre 40")
    check(not grid.is_satisfied(1), "50 no cubre 60: ese consumidor se apaga entero")
    check_equal(grid.satisfied_count(), 1, "el otro sigue encendido")
    check(not grid.is_solved(), "con uno apagado no está resuelto")


func test_loops_terminate_and_keep_the_best_power_per_cell() -> void:
    ## Anillo 2x2: TEE en (0,0) alimentado por el oeste, codos cerrando el lazo.
    var sources: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST)]
    var board: PipeBoard = PipeBoard.new(2, 2, sources, [])
    var tiles: Array[PipeTile] = [
        PipeTile.new(TEE, 2), PipeTile.new(ELBOW, 2),
        PipeTile.new(ELBOW, 0), PipeTile.new(ELBOW, 3),
    ]
    board.load_layout(tiles, [2, 2, 0, 3])
    var grid: PowerGrid = PowerGrid.new(board, [100.0], [])
    check_equal(grid.power_at(Vector2i(0, 0)), 100.0, "la fuente manda en su celda aunque el lazo vuelva")
    check_equal(grid.power_at(Vector2i(1, 0)), 50.0, "el lazo no suma: se queda el máximo por celda")


func test_sources_add_up_where_their_networks_join() -> void:
    ## Línea 3x1 con un TEE (hacia el norte, destino) en el centro y una fuente en cada extremo.
    var sources: Array[PipeTerminal] = [
        PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST),
        PipeTerminal.new(Vector2i(2, 0), PipeTile.Side.EAST),
    ]
    var targets: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(1, 0), PipeTile.Side.NORTH)]
    var board: PipeBoard = PipeBoard.new(3, 1, sources, targets)
    var tiles: Array[PipeTile] = [
        PipeTile.new(STRAIGHT, HORIZONTAL), PipeTile.new(TEE, 0), PipeTile.new(STRAIGHT, HORIZONTAL),
    ]
    board.load_layout(tiles, [HORIZONTAL, 0, HORIZONTAL])
    var grid: PowerGrid = PowerGrid.new(board, [100.0, 100.0], [100.0])
    check_equal(grid.delivered_to(0), 100.0, "cada fuente aporta su mitad y se suman")
    check(grid.is_solved(), "ninguna fuente sola cubría 100, juntas sí")


func test_resistors_cost_a_fraction_so_fewer_of_them_deliver_more() -> void:
    var with_one: PowerGrid = PowerGrid.new(_line(null, Resistor.new(0.15)), [100.0], [0.0])
    var with_two: PowerGrid = PowerGrid.new(_line(Resistor.new(0.15), Resistor.new(0.15)), [100.0], [72.25])
    check(is_equal_approx(with_one.delivered_to(0), 85.0), "una resistencia deja pasar el 85 %")
    check(is_equal_approx(with_two.delivered_to(0), 72.25), "las pérdidas se encadenan")
    check(with_one.delivered_to(0) > with_two.delivered_to(0), "el camino con menos resistencias entrega más")
    check(with_two.is_satisfied(0), "la demanda exacta se cubre pese al redondeo del float")
    var short: PowerGrid = PowerGrid.new(_line(Resistor.new(0.15), Resistor.new(0.15)), [100.0], [72.5])
    check(not short.is_satisfied(0), "y una unidad por encima de lo que llega no")


func test_a_resistor_travels_with_its_piece_when_tiles_swap() -> void:
    var board: PipeBoard = _line(null, Resistor.new(0.15))
    var grid: PowerGrid = PowerGrid.new(board, [100.0], [0.0])
    board.swap_tiles(Vector2i(1, 0), Vector2i(2, 0))
    check(grid.component_at(Vector2i(2, 0)) is Resistor, "la resistencia se fue con su pieza")
    check(not grid.component_at(Vector2i(1, 0)) is Resistor, "y la celda que dejó vuelve a conducir como cable")


func test_snapshot_survives_json_round_trip() -> void:
    var config: CircuitConfig = CircuitConfig.from_pipe(PipeBoardConfig.two_targets(5, 5, 3))
    config.shuffle_tiles = false
    var grid: PowerGrid = CircuitGenerator.new(config).build()
    var restored: PowerGrid = PowerGrid.new(PipeBoard.new(1, 1, [], []), [], [])
    restored.restore(JSON.parse_string(JSON.stringify(grid.snapshot())) as Dictionary)
    check_equal(restored.snapshot(), grid.snapshot(), "el circuito vuelve idéntico, resistencias incluidas")
    _solve(restored.board)
    check(restored.is_solved(), "y sigue siendo resoluble")
