class_name MazeRun
extends RefCounted
## Minijuego del laberinto: el cochecito recorre el laberinto recogiendo vetas mientras la batería se agota.
## Termina al vaciarse la batería o al llegar a la rampa de salida. Coordenadas en píxeles de pantalla.


enum End { NONE, BATTERY, EXIT }

const CAR_RADIUS := 13.0
## 3.05 px por fotograma a 60 FPS.
const CAR_SPEED := 183.0
const WALL_THICKNESS := 5.0
const PICKUP_DISTANCE := 30.0
const PRECISION_BATTERY_COST := 4.0
const START_OFFSET := -118.0
const FIRST_VEIN_OFFSET := -62.0
## La rampa: a la derecha del laberinto.
const EXIT_GAP := 14.0
const EXIT_SIZE := Vector2(72, 84)
## Margen que puede salir el cochecito fuera del laberinto.
const BOUNDS_LEFT := 150.0
const BOUNDS_RIGHT := 110.0
const BOUNDS_VERTICAL := 40.0
## Las vetas no caen en las dos primeras columnas.
const VEIN_MIN_COLUMN := 2
const VEIN_SEED_OFFSET := 7


class Vein:
    var res: Catalog.Res
    var base: int
    var position: Vector2
    var is_first: bool
    var taken: bool = false

    func _init(p_res: Catalog.Res, p_base: int, p_position: Vector2, p_is_first: bool) -> void:
        res = p_res
        base = p_base
        position = p_position
        is_first = p_is_first


var maze: Maze
var origin: Vector2
var cell_size: float
var walls: Array[Rect2] = []
var veins: Array[Vein] = []
var car: Vector2
var battery: float
var exit_rect: Rect2
var precision_uses: int = 0
var ended: End = End.NONE

var _expedition: Expedition
var _bounds: Rect2


func _init(expedition: Expedition, p_origin: Vector2) -> void:
    _expedition = expedition
    origin = p_origin
    cell_size = Catalog.MAZE_CELL
    battery = Catalog.MAZE_BATTERY
    maze = Maze.generate(Catalog.MAZE_COLS, Catalog.MAZE_ROWS, GameRandom.new(Catalog.MAZE_SEED))
    walls = maze.wall_rects(origin, cell_size, WALL_THICKNESS)
    var size: Vector2 = Vector2(maze.cols, maze.rows) * cell_size
    var entrance_y: float = origin.y + float(floori(maze.rows / 2.0)) * cell_size + cell_size / 2.0
    car = Vector2(origin.x + START_OFFSET, entrance_y)
    exit_rect = Rect2(Vector2(origin.x + size.x + EXIT_GAP, entrance_y - EXIT_SIZE.y / 2.0), EXIT_SIZE)
    _bounds = Rect2(
            origin - Vector2(BOUNDS_LEFT, BOUNDS_VERTICAL),
            size + Vector2(BOUNDS_LEFT + BOUNDS_RIGHT, 2.0 * BOUNDS_VERTICAL),
            )
    _place_veins(entrance_y)


func _place_veins(entrance_y: float) -> void:
    var first: Array = Catalog.FIRST_VEIN
    veins.append(Vein.new(int(first[0]) as Catalog.Res, int(first[1]), Vector2(origin.x + FIRST_VEIN_OFFSET, entrance_y), true))
    var cells: Array[Vector2i] = []
    for y: int in maze.rows:
        for x: int in range(VEIN_MIN_COLUMN, maze.cols):
            cells.append(Vector2i(x, y))
    GameRandom.new(Catalog.MAZE_SEED + VEIN_SEED_OFFSET).shuffle(cells)
    for i: int in Catalog.VEINS.size():
        var raw: Array = Catalog.VEINS[i]
        var center: Vector2 = origin + (Vector2(cells[i]) + Vector2(0.5, 0.5)) * cell_size
        veins.append(Vein.new(int(raw[0]) as Catalog.Res, int(raw[1]), center, false))


## Avanza un paso con la dirección pedida (cada eje en -1..1). Devuelve cómo terminó, si terminó.
func step(delta: float, direction: Vector2) -> End:
    if ended != End.NONE:
        return ended
    var move: Vector2 = direction.limit_length(1.0) * CAR_SPEED * delta
    var tried_x: Vector2 = Vector2(car.x + move.x, car.y)
    if not _collides(tried_x):
        car.x = clampf(tried_x.x, _bounds.position.x, _bounds.end.x)
    var tried_y: Vector2 = Vector2(car.x, car.y + move.y)
    if not _collides(tried_y):
        car.y = clampf(tried_y.y, _bounds.position.y, _bounds.end.y)
    battery -= delta
    if battery <= 0.0:
        ended = End.BATTERY
    elif exit_rect.has_point(car):
        ended = End.EXIT
    return ended


func nearby_vein() -> Vein:
    for vein: Vein in veins:
        if not vein.taken and vein.position.distance_to(car) < PICKUP_DISTANCE:
            return vein
    return null


## Recoge la veta multiplicando su base; devuelve lo ganado. La precisión cuesta batería.
func collect(vein: Vein, multiplier: float, used_precision: bool) -> int:
    var gained: int = int(float(vein.base) * multiplier)
    vein.taken = true
    _expedition.add_resource(vein.res, gained)
    _expedition.veins_taken += 1
    if used_precision:
        precision_uses += 1
        battery -= PRECISION_BATTERY_COST
        if multiplier >= PrecisionStop.best_multiplier():
            _expedition.perfect_veins += 1
    return gained


func _collides(center: Vector2) -> bool:
    var box: Rect2 = Rect2(center - Vector2(CAR_RADIUS, CAR_RADIUS), Vector2(CAR_RADIUS, CAR_RADIUS) * 2.0)
    for wall: Rect2 in walls:
        if box.intersects(wall):
            return true
    return false
