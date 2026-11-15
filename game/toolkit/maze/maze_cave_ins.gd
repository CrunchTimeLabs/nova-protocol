class_name MazeCaveIns
extends RefCounted
## Derrumbes temporales sobre un `Maze`: tapan pasos abiertos al azar (con semilla) durante poco tiempo.
## No modifica el `Maze`: lleva sus propios bloqueos. Nunca acepta un bloqueo que deje la celda protegida
## sin camino a la salida, ni uno que toque la celda protegida o sus vecinas, salvo los "de frente":
## con probabilidad `front_chance` intenta primero tapar uno de los pasos que se le indican (el que tiene
## delante quien camina), que sí pueden estar pegados a él.
## El tiempo se inyecta con tick(delta).


## Un paso tapado. `cell`/`dir` es el lado N o W de una celda (forma normalizada).
class CaveIn:
    var cell: Vector2i
    var dir: int
    var duration: float
    var remaining: float

    func _init(p_cell: Vector2i, p_dir: int, p_duration: float) -> void:
        cell = p_cell
        dir = p_dir
        duration = p_duration
        remaining = p_duration

    func elapsed() -> float:
        return duration - remaining


## Intentos para encontrar un paso que se pueda tapar sin cortar el camino a la salida.
const MAX_ATTEMPTS := 24
## Distancia (en celdas, Manhattan) alrededor de la celda protegida donde no cae nada.
const SAFE_RADIUS := 1

var maze: Maze
var active: Array[CaveIn] = []

var _rng: GameRandom
var _interval_min: float
var _interval_max: float
var _duration_min: float
var _duration_max: float
var _max_active: int
var _front_chance: float
var _until_next: float


func _init(
        p_maze: Maze,
        rng: GameRandom,
        interval: Vector2,
        duration: Vector2,
        max_active: int,
        front_chance: float = 0.0,
        ) -> void:
    maze = p_maze
    _rng = rng
    _interval_min = interval.x
    _interval_max = interval.y
    _duration_min = duration.x
    _duration_max = duration.y
    _max_active = max_active
    _front_chance = front_chance
    _until_next = _rng.range_float(_interval_min, _interval_max)


## Avanza el tiempo: caducan los derrumbes viejos y, si toca, cae uno nuevo. Devuelve los que empezaron.
## `fronts`: pasos (x, y, dirección) que se intentan tapar primero, en orden, cuando sale `front_chance`.
func tick(delta: float, protected_cell: Vector2i, fronts: Array[Vector3i] = []) -> Array[CaveIn]:
    expire(delta)
    _until_next -= delta
    if _until_next > 0.0:
        return [] as Array[CaveIn]
    _until_next = _rng.range_float(_interval_min, _interval_max)
    return drop(protected_cell, fronts, 1)


## Hace caer ahora hasta `count` derrumbes (respetando el máximo a la vez). El primero, con probabilidad
## `front_chance`, en uno de los `fronts`; el resto al azar. Lo usa quien lleva su propio ritmo.
func drop(protected_cell: Vector2i, fronts: Array[Vector3i], count: int) -> Array[CaveIn]:
    var started: Array[CaveIn] = []
    for i: int in count:
        if active.size() >= _max_active:
            break
        var duration: float = _rng.range_float(_duration_min, _duration_max)
        var cave_in: CaveIn = null
        if i == 0 and _front_chance > 0.0 and not fronts.is_empty() and _rng.chance(_front_chance):
            for front: Vector3i in fronts:
                cave_in = block_in_front(Vector2i(front.x, front.y), front.z, duration, protected_cell)
                if cave_in != null:
                    break
        for attempt: int in MAX_ATTEMPTS:
            if cave_in != null:
                break
            var cell: Vector2i = Vector2i(_rng.range_int(0, maze.cols - 1), _rng.range_int(0, maze.rows - 1))
            var dir: int = Maze.N if _rng.chance(0.5) else Maze.W
            cave_in = block(cell, dir, duration, protected_cell)
        if cave_in != null:
            started.append(cave_in)
    return started


## Solo pasa el tiempo de los derrumbes activos (sin que caigan nuevos).
func expire(delta: float) -> void:
    for cave_in: CaveIn in active.duplicate():
        cave_in.remaining -= delta
        if cave_in.remaining <= 0.0:
            active.erase(cave_in)


## Tapa el paso `cell`→`dir` si está abierto, no toca la zona segura y sigue habiendo camino a la salida.
## Devuelve el derrumbe o null si se rechaza.
func block(cell: Vector2i, dir: int, duration: float, protected_cell: Vector2i) -> CaveIn:
    var other: Vector2i = cell + (Maze.STEP[dir] as Vector2i)
    if _near(cell, protected_cell) or _near(other, protected_cell):
        return null
    return block_in_front(cell, dir, duration, protected_cell)


## Como `block` pero puede caer pegado a la celda protegida (justo delante); la salida sigue alcanzable.
func block_in_front(cell: Vector2i, dir: int, duration: float, protected_cell: Vector2i) -> CaveIn:
    var other: Vector2i = cell + (Maze.STEP[dir] as Vector2i)
    if not maze.contains(cell) or not maze.contains(other) or maze.has_wall(cell, dir) or is_blocked(cell, dir):
        return null
    var cave_in: CaveIn = _normalized(cell, dir, duration)
    active.append(cave_in)
    if not distances_from(protected_cell).has(maze.exit_cell()):
        active.erase(cave_in)
        return null
    return cave_in


func is_blocked(cell: Vector2i, dir: int) -> bool:
    var key: CaveIn = _normalized(cell, dir, 0.0)
    for cave_in: CaveIn in active:
        if cave_in.cell == key.cell and cave_in.dir == key.dir:
            return true
    return false


## Se puede pasar de `cell` a su vecina en `dir`: dentro del laberinto, sin muro y sin derrumbe.
func has_passage(cell: Vector2i, dir: int) -> bool:
    var other: Vector2i = cell + (Maze.STEP[dir] as Vector2i)
    return maze.contains(other) and not maze.has_wall(cell, dir) and not is_blocked(cell, dir)


## Distancia en pasos desde `from` a cada celda alcanzable, respetando muros y derrumbes.
func distances_from(from: Vector2i) -> Dictionary:
    var distances: Dictionary = {from: 0}
    var queue: Array[Vector2i] = [from]
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        for dir: int in Maze.DIRECTIONS:
            var next: Vector2i = cell + (Maze.STEP[dir] as Vector2i)
            if has_passage(cell, dir) and not distances.has(next):
                distances[next] = int(distances[cell]) + 1
                queue.append(next)
    return distances


## Camino más corto de `from` a `to` (sin incluir `from`); vacío si no hay camino.
func path_between(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var distances: Dictionary = distances_from(to)
    if not distances.has(from):
        return path
    var cell: Vector2i = from
    while cell != to:
        for dir: int in Maze.DIRECTIONS:
            var next: Vector2i = cell + (Maze.STEP[dir] as Vector2i)
            if has_passage(cell, dir) and distances.has(next) and int(distances[next]) == int(distances[cell]) - 1:
                cell = next
                break
        path.append(cell)
    return path


## Rectángulo que ocuparía tapar `cell`→`dir` (para comprobar antes si cae encima de algo).
func passage_rect(cell: Vector2i, dir: int, origin: Vector2, cell_size: float, thickness: float) -> Rect2:
    return rect_of(_normalized(cell, dir, 0.0), origin, cell_size, thickness)


## Rectángulo de un derrumbe en pantalla, con la misma geometría que `Maze.wall_rects`.
func rect_of(cave_in: CaveIn, origin: Vector2, cell_size: float, thickness: float) -> Rect2:
    var corner: Vector2 = origin + Vector2(cave_in.cell) * cell_size
    if cave_in.dir == Maze.N:
        return Rect2(corner, Vector2(cell_size + thickness, thickness))
    return Rect2(corner, Vector2(thickness, cell_size + thickness))


func _normalized(cell: Vector2i, dir: int, duration: float) -> CaveIn:
    if dir == Maze.S or dir == Maze.E:
        return CaveIn.new(cell + (Maze.STEP[dir] as Vector2i), int(Maze.OPPOSITE[dir]), duration)
    return CaveIn.new(cell, dir, duration)


func _near(cell: Vector2i, protected_cell: Vector2i) -> bool:
    return absi(cell.x - protected_cell.x) + absi(cell.y - protected_cell.y) <= SAFE_RADIUS
