class_name PipeBoardGenerator
extends RefCounted
## Fabrica un tablero con solución garantizada: talla un camino por destino y desordena las rotaciones.
## Todo el azar sale de `GameRandom` con la semilla de la configuración.


## Probabilidad de ignorar el sesgo hacia la meta y explorar un lado al azar (caminos menos rectos).
const WANDER_CHANCE: float = 0.3
## Lados que puede tener una celda tallada: con 4 no existe pieza.
const MAX_CELL_CONNECTIONS: int = 3
const MAX_SCRAMBLE_TRIES: int = 20

var _config: PipeBoardConfig
var _rng: GameRandom
var _masks: Array[int] = []
var _visited: Dictionary = {}


func _init(p_config: PipeBoardConfig) -> void:
    _config = p_config
    _rng = GameRandom.new(p_config.seed_value)


func build() -> PipeBoard:
    _carve_routes()
    var board: PipeBoard = PipeBoard.new(_config.width, _config.height, _config.sources, _config.targets)
    var tiles: Array[PipeTile] = []
    var solution: Array[int] = []
    for mask_value: int in _masks:
        var tile: PipeTile = _tile_for(mask_value)
        tiles.append(tile)
        solution.append(tile.rotation)
    board.load_layout(tiles, solution)
    _scramble(board)
    return board


func _carve_routes() -> void:
    _masks.clear()
    _masks.resize(_config.width * _config.height)
    _masks.fill(0)
    for terminal: PipeTerminal in _config.sources + _config.targets:
        _masks[_index(terminal.cell)] |= PipeTile.side_bit(terminal.side)
    for i: int in _config.targets.size():
        var source: PipeTerminal = _config.sources[i % _config.sources.size()]
        _visited = {source.cell: true}
        if not _search(source.cell, _config.targets[i].cell):
            push_error("PipeBoardGenerator: no hay camino al destino %d" % i)


## DFS simple: las aristas se anotan al avanzar y se deshacen al retroceder, así el límite de lados
## cuenta también las que el propio camino ya puso. Como las celdas visitadas no se liberan,
## encuentra camino si existe alguno.
func _search(cell: Vector2i, goal: Vector2i) -> bool:
    if cell == goal:
        return true
    for side: PipeTile.Side in _ordered_sides(cell, goal):
        var next: Vector2i = cell + PipeTile.offset(side)
        if not _is_inside(next) or _visited.has(next) or not _can_link(cell, side, next):
            continue
        var cell_before: int = _masks[_index(cell)]
        var next_before: int = _masks[_index(next)]
        _masks[_index(cell)] |= PipeTile.side_bit(side)
        _masks[_index(next)] |= PipeTile.side_bit(PipeTile.opposite(side))
        _visited[next] = true
        if _search(next, goal):
            return true
        _masks[_index(cell)] = cell_before
        _masks[_index(next)] = next_before
    return false


## Barajados; salvo que toque deambular, los que acercan a la meta van primero.
func _ordered_sides(cell: Vector2i, goal: Vector2i) -> Array[PipeTile.Side]:
    var sides: Array[PipeTile.Side] = [
        PipeTile.Side.NORTH,
        PipeTile.Side.EAST,
        PipeTile.Side.SOUTH,
        PipeTile.Side.WEST,
    ]
    for i: int in range(sides.size() - 1, 0, -1):
        var j: int = _rng.range_int(0, i)
        var swapped: PipeTile.Side = sides[i]
        sides[i] = sides[j]
        sides[j] = swapped
    if not _rng.chance(WANDER_CHANCE):
        sides.sort_custom(func(a: PipeTile.Side, b: PipeTile.Side) -> bool:
            return _distance(cell + PipeTile.offset(a), goal) < _distance(cell + PipeTile.offset(b), goal))
    return sides


func _can_link(cell: Vector2i, side: PipeTile.Side, next: Vector2i) -> bool:
    if _is_terminal_side(cell, side) or _is_terminal_side(next, PipeTile.opposite(side)):
        return false
    var from_mask: int = _masks[_index(cell)] | PipeTile.side_bit(side)
    var to_mask: int = _masks[_index(next)] | PipeTile.side_bit(PipeTile.opposite(side))
    return PipeTile.bit_count(from_mask) <= MAX_CELL_CONNECTIONS and PipeTile.bit_count(to_mask) <= MAX_CELL_CONNECTIONS


## El lado de un terminal queda reservado a él: un camino no puede cruzarlo (importa en terminales dentro del tablero).
func _is_terminal_side(cell: Vector2i, side: PipeTile.Side) -> bool:
    for terminal: PipeTerminal in _config.sources + _config.targets:
        if terminal.cell == cell and terminal.side == side:
            return true
    return false


## Celda tallada = la pieza que produce su máscara; celda libre = relleno al azar.
func _tile_for(mask_value: int) -> PipeTile:
    if PipeTile.can_form(mask_value):
        var shape: PipeTile.Shape = PipeTile.shape_for(mask_value)
        return PipeTile.new(shape, PipeTile.rotation_for(shape, mask_value))
    var filler: PipeTile.Shape = _rng.pick(PipeTile.Shape.values()) as PipeTile.Shape
    return PipeTile.new(filler, _rng.range_int(0, PipeTile.SIDE_COUNT - 1))


## Gira cada pieza al azar; si por casualidad queda resuelto, repite (con tope).
func _scramble(board: PipeBoard) -> void:
    for attempt: int in MAX_SCRAMBLE_TRIES:
        for y: int in board.height:
            for x: int in board.width:
                board.rotate_tile(Vector2i(x, y), _rng.range_int(0, PipeTile.SIDE_COUNT - 1))
        if not board.is_solved():
            return


func _distance(from: Vector2i, to: Vector2i) -> int:
    return absi(from.x - to.x) + absi(from.y - to.y)


func _is_inside(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < _config.width and cell.y < _config.height


func _index(cell: Vector2i) -> int:
    return cell.y * _config.width + cell.x
