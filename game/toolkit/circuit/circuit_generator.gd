class_name CircuitGenerator
extends RefCounted
## Fabrica un circuito con solución garantizada: toma el tablero que talla `PipeBoardGenerator`,
## convierte cada pieza en `CircuitTile` con la pérdida configurada y dimensiona las fuentes
## calculando la solución tallada con el propio `PowerGrid`, así que la garantía ya cuenta las
## pérdidas de cada pieza por la que pasa el camino. El cálculo es homogéneo (k veces más
## potencia entrega k veces más), así que con 1 W por fuente basta escalar por lo que falta.
## `PipeBoardGenerator` ya deja las rotaciones desordenadas; si `shuffle_tiles` está activo, aquí se
## intercambian además algunas piezas **del tramo correcto** (las celdas con energía en la solución tallada; con `GameRandom` y la misma semilla). `solution_rotation_at`
## sigue siendo la rotación que debe tener la pieza que corresponde a cada celda.


const UNIT_SUPPLY: float = 1.0
## Intercambios al mezclar, como fracción de las celdas del tramo correcto (al menos uno).
const SWAP_RATIO: float = 0.3

var _config: CircuitConfig


func _init(p_config: CircuitConfig) -> void:
    _config = p_config


func build() -> PowerGrid:
    var board: PipeBoard = PipeBoardGenerator.new(_config.pipe).build()
    var shuffled: Array[PipeTile] = []
    var solved: Array[PipeTile] = []
    var solution: Array[int] = []
    for y: int in board.height:
        for x: int in board.width:
            var cell: Vector2i = Vector2i(x, y)
            var component: CircuitComponent = Resistor.new(_config.loss_fraction)
            solution.append(board.solution_rotation_at(cell))
            shuffled.append(CircuitTile.new(board.shape_at(cell), board.rotation_at(cell), component))
            solved.append(CircuitTile.new(board.shape_at(cell), board.solution_rotation_at(cell), component))
    var reference: PipeBoard = PipeBoard.new(board.width, board.height, board.sources, board.targets)
    reference.load_layout(solved, solution)
    var supply: float = _required_supply(reference)
    board.load_layout(shuffled, solution)
    if _config.shuffle_tiles:
        _swap_some_tiles(board, _route_cells(reference))
    return PowerGrid.new(board, _filled(board.sources.size(), supply), _filled(board.targets.size(), _config.demand))


## Celdas por las que pasa la energía en la solución tallada.
func _route_cells(reference: PipeBoard) -> Array[Vector2i]:
    var cells: Array[Vector2i] = []
    for y: int in reference.height:
        for x: int in reference.width:
            if reference.is_powered(Vector2i(x, y)):
                cells.append(Vector2i(x, y))
    return cells


## Intercambia pares de celdas del tramo correcto; el azar sale de la semilla del tablero.
func _swap_some_tiles(board: PipeBoard, route: Array[Vector2i]) -> void:
    if route.size() < 2:
        return
    var rng: GameRandom = GameRandom.new(_config.pipe.seed_value)
    var swaps: int = maxi(1, roundi(route.size() * SWAP_RATIO))
    for _i: int in swaps:
        board.swap_tiles(rng.pick(route) as Vector2i, rng.pick(route) as Vector2i)


## Potencia por fuente que deja satisfecho al consumidor más exigente de la solución, más el margen.
func _required_supply(reference: PipeBoard) -> float:
    var unit: PowerGrid = PowerGrid.new(
            reference,
            _filled(reference.sources.size(), UNIT_SUPPLY),
            _filled(reference.targets.size(), _config.demand),
            )
    var scale: float = 0.0
    for i: int in reference.targets.size():
        if unit.delivered_to(i) <= 0.0:
            push_error("CircuitGenerator: la solución tallada no llega al destino %d" % i)
            return _config.demand
        scale = maxf(scale, _config.demand / unit.delivered_to(i))
    return scale * UNIT_SUPPLY * (1.0 + _config.margin)


func _filled(count: int, value: float) -> Array[float]:
    var values: Array[float] = []
    values.resize(count)
    values.fill(value)
    return values
