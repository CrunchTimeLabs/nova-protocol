class_name PipeBoard
extends RefCounted
## Tablero de piezas que se giran para llevar la energía de las fuentes a todos los destinos.
## Sin nodos: la vista lee piezas y estado de conexión, y el jugador solo llama a `rotate_tile`.


signal changed

var width: int
var height: int
var sources: Array[PipeTerminal]
var targets: Array[PipeTerminal]

var _tiles: Array[PipeTile] = []
var _solution: Array[int] = []
var _powered: Array[bool] = []
var _lit: Array[bool] = []


func _init(
        p_width: int,
        p_height: int,
        p_sources: Array[PipeTerminal],
        p_targets: Array[PipeTerminal],
        ) -> void:
    assert(p_width > 0 and p_height > 0, "PipeBoard necesita tamaño positivo")
    width = p_width
    height = p_height
    sources = p_sources
    targets = p_targets
    var blank: Array[PipeTile] = []
    for i: int in width * height:
        blank.append(PipeTile.new(PipeTile.Shape.STRAIGHT))
    load_layout(blank, _zero_rotations())


## Reemplaza todas las piezas (por fila) y la rotación de cada una que resuelve el tablero.
func load_layout(p_tiles: Array[PipeTile], p_solution: Array[int]) -> void:
    assert(p_tiles.size() == width * height and p_solution.size() == p_tiles.size(), "PipeBoard: tamaño de capa inválido")
    _tiles = p_tiles
    _solution = p_solution
    _refresh()


func contains(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## La pieza de una celda (las subclases de `PipeTile` conservan lo que añaden).
func tile_at(cell: Vector2i) -> PipeTile:
    return _tiles[_index(cell)]


func shape_at(cell: Vector2i) -> PipeTile.Shape:
    return _tiles[_index(cell)].shape


func rotation_at(cell: Vector2i) -> int:
    return _tiles[_index(cell)].rotation


func solution_rotation_at(cell: Vector2i) -> int:
    return _solution[_index(cell)]


func connects(cell: Vector2i, side: PipeTile.Side) -> bool:
    return _tiles[_index(cell)].connects(side)


## Gira la pieza `steps` cuartos de vuelta (negativo = antihorario). false si la celda no existe.
func rotate_tile(cell: Vector2i, steps: int = 1) -> bool:
    if not contains(cell):
        return false
    _tiles[_index(cell)].rotate_by(steps)
    _refresh()
    changed.emit()
    return true


## Intercambia las piezas (forma y rotación) de dos celdas. false si alguna no existe o son la misma.
func swap_tiles(first: Vector2i, second: Vector2i) -> bool:
    if not contains(first) or not contains(second) or first == second:
        return false
    var held: PipeTile = _tiles[_index(first)]
    _tiles[_index(first)] = _tiles[_index(second)]
    _tiles[_index(second)] = held
    _refresh()
    changed.emit()
    return true


func is_powered(cell: Vector2i) -> bool:
    return _powered[_index(cell)]


func is_target_lit(target_index: int) -> bool:
    return _lit[target_index]


func lit_count() -> int:
    return _lit.count(true)


func is_solved() -> bool:
    return lit_count() == targets.size()


func snapshot() -> Dictionary:
    var saved_tiles: Array[Dictionary] = []
    for tile: PipeTile in _tiles:
        saved_tiles.append({"shape": PipeTile.Shape.keys()[tile.shape], "rotation": tile.rotation})
    return {
        "width": width,
        "height": height,
        "tiles": saved_tiles,
        "solution": _solution,
        "sources": _terminal_snapshots(sources),
        "targets": _terminal_snapshots(targets),
    }


func restore(saved: Dictionary) -> void:
    width = int(saved["width"])
    height = int(saved["height"])
    sources = _terminals_from(saved["sources"] as Array)
    targets = _terminals_from(saved["targets"] as Array)
    var restored_tiles: Array[PipeTile] = []
    for entry: Variant in saved["tiles"] as Array:
        var tile_data: Dictionary = entry as Dictionary
        var shape_name: String = str(tile_data["shape"])
        restored_tiles.append(PipeTile.new(PipeTile.Shape[shape_name] as PipeTile.Shape, int(tile_data["rotation"])))
    var restored_solution: Array[int] = []
    for turns: Variant in saved["solution"] as Array:
        restored_solution.append(int(turns))
    load_layout(restored_tiles, restored_solution)
    changed.emit()


## Propaga desde cada fuente solo por lados recíprocos: A abre hacia B y B abre hacia A.
func _refresh() -> void:
    _powered.clear()
    _powered.resize(width * height)
    _powered.fill(false)
    var pending: Array[Vector2i] = []
    for source: PipeTerminal in sources:
        if connects(source.cell, source.side) and not is_powered(source.cell):
            _powered[_index(source.cell)] = true
            pending.append(source.cell)
    while not pending.is_empty():
        var cell: Vector2i = pending.pop_back()
        for side_value: int in PipeTile.SIDE_COUNT:
            var side: PipeTile.Side = side_value as PipeTile.Side
            var next: Vector2i = cell + PipeTile.offset(side)
            if not connects(cell, side) or not contains(next) or is_powered(next):
                continue
            if connects(next, PipeTile.opposite(side)):
                _powered[_index(next)] = true
                pending.append(next)
    _lit.clear()
    for target: PipeTerminal in targets:
        _lit.append(is_powered(target.cell) and connects(target.cell, target.side))


func _index(cell: Vector2i) -> int:
    return cell.y * width + cell.x


func _zero_rotations() -> Array[int]:
    var zeros: Array[int] = []
    zeros.resize(width * height)
    zeros.fill(0)
    return zeros


func _terminal_snapshots(terminals: Array[PipeTerminal]) -> Array[Dictionary]:
    var saved: Array[Dictionary] = []
    for terminal: PipeTerminal in terminals:
        saved.append(terminal.snapshot())
    return saved


func _terminals_from(saved: Array) -> Array[PipeTerminal]:
    var terminals: Array[PipeTerminal] = []
    for entry: Variant in saved:
        terminals.append(PipeTerminal.from_snapshot(entry as Dictionary))
    return terminals
