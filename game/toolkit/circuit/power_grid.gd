class_name PowerGrid
extends RefCounted
## Reparte potencia sobre un `PipeBoard`: cada fuente entrega sus vatios, cada celda los transforma
## con su componente y cada TEE los divide a partes iguales entre sus salidas. Es un juego, no un
## simulador: dentro de una fuente, cada celda conserva la mayor potencia que le llega por cualquier
## ruta; las potencias de fuentes distintas se suman.
## Un consumidor con menos de lo que exige queda apagado (todo o nada). Sin nodos; la topología
## la pone el tablero y se recalcula sola cuando este emite `changed`.


signal changed

## Margen para comparar potencias en coma flotante tras repartir.
const EPSILON: float = 0.0001
## Se sube al cambiar el formato de `snapshot()`.
const SAVE_VERSION: int = 1
## Las potencias se guardan redondeadas a este paso: JSON no conserva todos los decimales de un float.
const SAVE_PRECISION: float = 0.000001

var board: PipeBoard

var _supplies: Array[float]
var _demands: Array[float]
var _power: Array[float] = []
var _delivered: Array[float] = []


## `p_supplies[i]` va con `p_board.sources[i]` y `p_demands[i]` con `p_board.targets[i]`.
## Una pieza que no sea `CircuitTile` conduce como un cable.
func _init(p_board: PipeBoard, p_supplies: Array[float], p_demands: Array[float]) -> void:
    assert(p_supplies.size() == p_board.sources.size(), "PowerGrid: una potencia por fuente")
    assert(p_demands.size() == p_board.targets.size(), "PowerGrid: una demanda por destino")
    board = p_board
    _supplies = p_supplies
    _demands = p_demands
    board.changed.connect(refresh)
    refresh()


## Potencia que entra en la celda (0 si no le llega ninguna).
func power_at(cell: Vector2i) -> float:
    return _power[_index(cell)]


## Componente de la pieza de la celda, o null si conduce como un cable.
func component_at(cell: Vector2i) -> CircuitComponent:
    var tile: CircuitTile = board.tile_at(cell) as CircuitTile
    return null if tile == null else tile.component


func delivered_to(target_index: int) -> float:
    return _delivered[target_index]


func supply_of(source_index: int) -> float:
    return _supplies[source_index]


func demand_of(target_index: int) -> float:
    return _demands[target_index]


func is_satisfied(target_index: int) -> bool:
    return _delivered[target_index] + EPSILON >= _demands[target_index]


func satisfied_count() -> int:
    var count: int = 0
    for i: int in _demands.size():
        if is_satisfied(i):
            count += 1
    return count


func is_solved() -> bool:
    return satisfied_count() == _demands.size()


func snapshot() -> Dictionary:
    var saved_tiles: Array[Dictionary] = []
    for y: int in board.height:
        for x: int in board.width:
            var tile: PipeTile = board.tile_at(Vector2i(x, y))
            var circuit_tile: CircuitTile = tile as CircuitTile
            if circuit_tile == null:
                circuit_tile = CircuitTile.new(tile.shape, tile.rotation)
            saved_tiles.append(circuit_tile.snapshot())
    return {
        "version": SAVE_VERSION,
        "board": board.snapshot(),
        "tiles": saved_tiles,
        "supplies": _rounded(_supplies),
        "demands": _rounded(_demands),
    }


func restore(saved: Dictionary) -> void:
    _supplies = _floats_from(saved["supplies"] as Array)
    _demands = _floats_from(saved["demands"] as Array)
    board.restore(saved["board"] as Dictionary)
    var restored_tiles: Array[PipeTile] = []
    var solution: Array[int] = []
    var saved_tiles: Array = saved["tiles"] as Array
    for i: int in saved_tiles.size():
        var cell: Vector2i = Vector2i(i % board.width, i / board.width)
        restored_tiles.append(CircuitTile.from_snapshot(
                board.shape_at(cell),
                board.rotation_at(cell),
                saved_tiles[i] as Dictionary,
                ))
        solution.append(board.solution_rotation_at(cell))
    board.load_layout(restored_tiles, solution)
    refresh()


func refresh() -> void:
    _power.clear()
    _power.resize(board.width * board.height)
    _power.fill(0.0)
    _delivered.clear()
    _delivered.resize(board.targets.size())
    _delivered.fill(0.0)
    for i: int in board.sources.size():
        _add_source(i)
    changed.emit()


## Propaga una fuente por separado (máximo por celda dentro de ella) y suma su aporte al total:
## las potencias de fuentes distintas se suman donde sus redes se unen.
func _add_source(source_index: int) -> void:
    var source: PipeTerminal = board.sources[source_index]
    if not board.connects(source.cell, source.side) or _supplies[source_index] <= 0.0:
        return
    var best: Array[float] = []
    best.resize(_power.size())
    best.fill(0.0)
    var reached: Array[float] = []
    reached.resize(_delivered.size())
    reached.fill(0.0)
    var entry: Array[int] = []
    entry.resize(_power.size())
    best[_index(source.cell)] = _supplies[source_index]
    entry[_index(source.cell)] = source.side
    var pending: Array[Vector2i] = [source.cell]
    while not pending.is_empty():
        _spread_from(pending.pop_back(), best, reached, entry, pending)
    for i: int in _power.size():
        _power[i] += best[i]
    for i: int in _delivered.size():
        _delivered[i] += reached[i]


## Reparte la salida de `cell` entre sus salidas (todo lado abierto salvo por donde entró).
func _spread_from(
        cell: Vector2i,
        best: Array[float],
        reached: Array[float],
        entry: Array[int],
        pending: Array[Vector2i],
        ) -> void:
    var came_from: PipeTile.Side = entry[_index(cell)] as PipeTile.Side
    var outputs: Array[PipeTile.Side] = _exits(cell, came_from)
    if outputs.is_empty():
        return
    var share: float = _transmit(cell, best[_index(cell)]) / outputs.size()
    for side: PipeTile.Side in outputs:
        var target_index: int = _target_index(cell, side)
        if target_index >= 0:
            reached[target_index] = maxf(reached[target_index], share)
            continue
        var next: Vector2i = cell + PipeTile.offset(side)
        if share > best[_index(next)]:
            best[_index(next)] = share
            entry[_index(next)] = PipeTile.opposite(side)
            pending.append(next)


## Lados por los que puede salir: abiertos, y con vecino que abre de vuelta o con un destino.
func _exits(cell: Vector2i, came_from: PipeTile.Side) -> Array[PipeTile.Side]:
    var outputs: Array[PipeTile.Side] = []
    for side_value: int in PipeTile.SIDE_COUNT:
        var side: PipeTile.Side = side_value as PipeTile.Side
        if side == came_from or not board.connects(cell, side):
            continue
        var next: Vector2i = cell + PipeTile.offset(side)
        var reaches_neighbor: bool = board.contains(next) and board.connects(next, PipeTile.opposite(side))
        if reaches_neighbor or _target_index(cell, side) >= 0:
            outputs.append(side)
    return outputs


func _target_index(cell: Vector2i, side: PipeTile.Side) -> int:
    for i: int in board.targets.size():
        var target: PipeTerminal = board.targets[i]
        if target.cell == cell and target.side == side:
            return i
    return -1


func _transmit(cell: Vector2i, power: float) -> float:
    var component: CircuitComponent = component_at(cell)
    if component == null:
        return power
    return component.transmit(power)


func _rounded(values: Array[float]) -> Array[float]:
    var rounded: Array[float] = []
    for value: float in values:
        rounded.append(snappedf(value, SAVE_PRECISION))
    return rounded


func _floats_from(values: Array) -> Array[float]:
    var floats: Array[float] = []
    for value: Variant in values:
        floats.append(float(value))
    return floats


func _index(cell: Vector2i) -> int:
    return cell.y * board.width + cell.x
