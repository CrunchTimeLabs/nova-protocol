class_name Maze
extends RefCounted
## Laberinto en cuadrícula con semilla: backtracker recursivo con algunos bucles abiertos al final
## (un laberinto perfecto es un callejón constante). Entrada a la izquierda y salida a la derecha,
## las dos en la fila del medio.


const N := 1
const E := 2
const S := 4
const W := 8
const DIRECTIONS: Array[int] = [N, E, S, W]
const STEP: Dictionary = {N: Vector2i(0, -1), E: Vector2i(1, 0), S: Vector2i(0, 1), W: Vector2i(-1, 0)}
const OPPOSITE: Dictionary = {N: S, S: N, E: W, W: E}
## Una apertura extra por cada tantas celdas.
const CELLS_PER_LOOP := 6
const ALL_WALLS := N | E | S | W

var cols: int
var rows: int
var _walls: PackedInt32Array = PackedInt32Array()


func _init(p_cols: int, p_rows: int) -> void:
    cols = p_cols
    rows = p_rows
    _walls.resize(cols * rows)
    _walls.fill(ALL_WALLS)


static func generate(p_cols: int, p_rows: int, rng: GameRandom) -> Maze:
    var maze: Maze = Maze.new(p_cols, p_rows)
    var seen: Dictionary = {}
    var start: Vector2i = maze.entrance()
    seen[start] = true
    var stack: Array[Vector2i] = [start]
    while not stack.is_empty():
        var cell: Vector2i = stack[-1]
        var options: Array[int] = []
        for dir: int in DIRECTIONS:
            var next: Vector2i = cell + (STEP[dir] as Vector2i)
            if maze.contains(next) and not seen.has(next):
                options.append(dir)
        if options.is_empty():
            stack.pop_back()
            continue
        var chosen: int = options[rng.range_int(0, options.size() - 1)]
        var target: Vector2i = cell + (STEP[chosen] as Vector2i)
        maze.open(cell, chosen)
        seen[target] = true
        stack.append(target)

    for i: int in floori(float(p_cols * p_rows) / CELLS_PER_LOOP):
        var cell: Vector2i = Vector2i(rng.range_int(1, p_cols - 2), rng.range_int(1, p_rows - 2))
        var dir: int = DIRECTIONS[rng.range_int(0, DIRECTIONS.size() - 1)]
        if maze.contains(cell + (STEP[dir] as Vector2i)):
            maze.open(cell, dir)

    maze._clear(maze.entrance(), W)
    maze._clear(maze.exit_cell(), E)
    return maze


func entrance() -> Vector2i:
    return Vector2i(0, floori(rows / 2.0))


func exit_cell() -> Vector2i:
    return Vector2i(cols - 1, floori(rows / 2.0))


func contains(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < cols and cell.y >= 0 and cell.y < rows


func has_wall(cell: Vector2i, dir: int) -> bool:
    return (_walls[_index(cell)] & dir) != 0


## Abre el paso entre `cell` y su vecina en `dir` (los dos lados).
func open(cell: Vector2i, dir: int) -> void:
    _clear(cell, dir)
    _clear(cell + (STEP[dir] as Vector2i), int(OPPOSITE[dir]))


## Celdas a las que se llega desde `from` sin atravesar muros.
func reachable_from(from: Vector2i) -> int:
    var seen: Dictionary = {from: true}
    var stack: Array[Vector2i] = [from]
    while not stack.is_empty():
        var cell: Vector2i = stack.pop_back()
        for dir: int in DIRECTIONS:
            var next: Vector2i = cell + (STEP[dir] as Vector2i)
            if contains(next) and not has_wall(cell, dir) and not seen.has(next):
                seen[next] = true
                stack.append(next)
    return seen.size()


## Rectángulos de los muros en coordenadas de pantalla, para colisión y dibujo.
func wall_rects(origin: Vector2, cell_size: float, thickness: float) -> Array[Rect2]:
    var rects: Array[Rect2] = []
    for y: int in rows:
        for x: int in cols:
            var cell: Vector2i = Vector2i(x, y)
            var corner: Vector2 = origin + Vector2(x, y) * cell_size
            if has_wall(cell, N):
                rects.append(Rect2(corner, Vector2(cell_size + thickness, thickness)))
            if has_wall(cell, W):
                rects.append(Rect2(corner, Vector2(thickness, cell_size + thickness)))
            if y == rows - 1 and has_wall(cell, S):
                rects.append(Rect2(corner + Vector2(0, cell_size), Vector2(cell_size + thickness, thickness)))
            if x == cols - 1 and has_wall(cell, E):
                rects.append(Rect2(corner + Vector2(cell_size, 0), Vector2(thickness, cell_size + thickness)))
    return rects


## Abre el muro del borde de `cell` en `dir` (una entrada o salida extra hacia fuera del laberinto).
func open_border(cell: Vector2i, dir: int) -> void:
    if contains(cell) and not contains(cell + (STEP[dir] as Vector2i)):
        _clear(cell, dir)


func _index(cell: Vector2i) -> int:
    return cell.y * cols + cell.x


func _clear(cell: Vector2i, dir: int) -> void:
    _walls[_index(cell)] &= ~dir
