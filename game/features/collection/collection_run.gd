class_name CollectionRun
extends RefCounted
## Recolección: el cochecito recorre un laberinto dinámico recogiendo minerales que aparecen y desaparecen,
## esquivando derrumbes temporales, hasta salir por la rampa. Coordenadas en píxeles de pantalla.
## Cada mineral vive justo lo necesario para llegar por el camino más corto: menos margen cuanto más vale.


signal collected(mineral: Mineral, amount: int, where: Vector2)
signal cave_in_started(cave_in: MazeCaveIns.CaveIn)
signal mineral_lost(mineral: Mineral, where: Vector2)
signal finished

## Del menos al más valioso.
enum Mineral { METAL, COPPER, CRYSTAL, GOLD, AMETHYST }

const MINERAL_NAMES: Dictionary = {
    Mineral.METAL: "Metal",
    Mineral.COPPER: "Cobre",
    Mineral.CRYSTAL: "Cristal",
    Mineral.GOLD: "Oro",
    Mineral.AMETHYST: "Amatista",
}
const MINERAL_VALUE: Dictionary = {
    Mineral.METAL: 10,
    Mineral.COPPER: 15,
    Mineral.CRYSTAL: 25,
    Mineral.GOLD: 40,
    Mineral.AMETHYST: 60,
}
## Margen sobre el tiempo justo del camino más corto: cuanto más vale, más aprieta.
const MINERAL_SLACK: Dictionary = {
    Mineral.METAL: 2.2,
    Mineral.COPPER: 1.8,
    Mineral.CRYSTAL: 1.35,
    Mineral.GOLD: 1.25,
    Mineral.AMETHYST: 1.15,
}
## Peso al aparecer (de cada 100): los valiosos son raros.
const MINERAL_WEIGHT: Dictionary = {
    Mineral.METAL: 40,
    Mineral.COPPER: 25,
    Mineral.CRYSTAL: 18,
    Mineral.GOLD: 11,
    Mineral.AMETHYST: 6,
}
## Segundos extra para reaccionar al verlo aparecer.
const REACTION_TIME := 1.5
## Los minerales caen a esta distancia (en pasos) del cochecito.
const SPAWN_DISTANCE_MIN := 2
const SPAWN_DISTANCE_MAX := 12
const SPAWN_INTERVAL := Vector2(1.5, 3.0)
const SPAWN_MAX_ALIVE := 6
const CAVE_IN_SEED_OFFSET := 11
const CAVE_IN_CLOCK_SEED_OFFSET := 37
const SPAWN_SEED_OFFSET := 23

## Radio del cochecito y distancia de recogida, en proporción a la celda (cabe en las celdas pequeñas).
const CAR_RADIUS_RATIO := 0.31
const PICKUP_RATIO := 0.57
const CAR_SPEED := 183.0
const WALL_THICKNESS := 5.0
## Holgura para que un derrumbe delantero nunca caiga encima del cochecito.
const FRONT_CLEARANCE := 3.0
const START_OFFSET := -70.0
const EXIT_GAP := 14.0
const EXIT_SIZE := Vector2(72, 84)
const BOUNDS_LEFT := 80.0
const BOUNDS_RIGHT := 110.0
const BOUNDS_VERTICAL := 40.0

var level: CollectionLevel
var maze: Maze
var cave_ins: MazeCaveIns
## Cuándo cae un derrumbe (una ventana de tiempo con probabilidad).
var cave_in_clock: ChanceWindow
var spawns: TimedSpawns
var tally: Tally = Tally.new()
var origin: Vector2
var cell_size: float
var car_radius: float
var walls: Array[Rect2] = []
var car: Vector2
var exit_rect: Rect2
var is_finished: bool = false
## Sin eventos al azar (la demo del tutorial los coloca a mano).
var has_random_events: bool = true

var _rng: GameRandom
var _bounds: Rect2
## Dirección de marcha (Maze.N/E/S/W): hacia dónde está el "delante".
var _heading_dir: int = Maze.E


func _init(p_origin: Vector2, p_level: CollectionLevel, seed_value: int) -> void:
    origin = p_origin
    level = p_level
    cell_size = level.cell_size
    car_radius = cell_size * CAR_RADIUS_RATIO
    maze = Maze.generate(level.size.x, level.size.y, GameRandom.new(seed_value))
    # El ritmo lo lleva `cave_in_clock` (con `drop`); el intervalo propio de MazeCaveIns no se usa.
    cave_ins = MazeCaveIns.new(
            maze,
            GameRandom.new(seed_value + CAVE_IN_SEED_OFFSET),
            Vector2(level.cave_in_window, level.cave_in_window),
            level.cave_in_duration,
            level.cave_in_max,
            level.front_chance,
            )
    cave_in_clock = ChanceWindow.new(
            GameRandom.new(seed_value + CAVE_IN_CLOCK_SEED_OFFSET),
            level.cave_in_window,
            level.cave_in_chance,
            )
    spawns = TimedSpawns.new(GameRandom.new(seed_value + SPAWN_SEED_OFFSET), SPAWN_INTERVAL, SPAWN_MAX_ALIVE)
    spawns.expired.connect(_on_spawn_expired)
    _rng = GameRandom.new(seed_value + SPAWN_SEED_OFFSET + 1)
    walls = maze.wall_rects(origin, cell_size, WALL_THICKNESS)
    var size: Vector2 = Vector2(maze.cols, maze.rows) * cell_size
    var entrance_y: float = center_of(maze.entrance()).y
    car = Vector2(origin.x + START_OFFSET, entrance_y)
    exit_rect = Rect2(Vector2(origin.x + size.x + EXIT_GAP, entrance_y - EXIT_SIZE.y / 2.0), EXIT_SIZE)
    _bounds = Rect2(
            origin - Vector2(BOUNDS_LEFT, BOUNDS_VERTICAL),
            size + Vector2(BOUNDS_LEFT + BOUNDS_RIGHT, 2.0 * BOUNDS_VERTICAL),
            )


## Avanza un paso: eventos del laberinto, movimiento con colisión, recogida y llegada a la rampa.
func step(delta: float, direction: Vector2) -> void:
    if is_finished:
        return
    if has_random_events:
        cave_ins.expire(delta)
        if cave_in_clock.tick(delta) > 0:
            for cave_in: MazeCaveIns.CaveIn in cave_ins.drop(car_cell(), front_passages(), level.passages_per_cave_in):
                cave_in_started.emit(cave_in)
        if spawns.tick(delta):
            _spawn_mineral()
    else:
        cave_ins.expire(delta)
        spawns.expire(delta)
    _move(delta, direction)
    _collect_nearby()
    if exit_rect.has_point(car):
        is_finished = true
        finished.emit()


## Coloca un mineral en `slot` con la vida justa desde donde está el cochecito. Null si no se puede.
func place_mineral(slot: Vector2i, mineral: Mineral) -> TimedSpawns.Spawn:
    var distances: Dictionary = cave_ins.distances_from(car_cell())
    if not distances.has(slot):
        return null
    return spawns.add(slot, mineral, lifetime_for(int(distances[slot]), mineral))


## Derrumbe con guion (sin azar) en `cell`→`dir`. Null si se rechaza (ver `MazeCaveIns.block`).
func add_cave_in(cell: Vector2i, dir: int, duration: float) -> MazeCaveIns.CaveIn:
    var cave_in: MazeCaveIns.CaveIn = cave_ins.block(cell, dir, duration, car_cell())
    if cave_in != null:
        cave_in_started.emit(cave_in)
    return cave_in


## Vida de un mineral a `steps` pasos: tiempo de recorrerlos a toda velocidad por su margen, más reacción.
func lifetime_for(steps: int, mineral: Mineral) -> float:
    var seconds_per_cell: float = cell_size / CAR_SPEED
    return float(steps + 1) * seconds_per_cell * float(MINERAL_SLACK[mineral]) + REACTION_TIME


## Pasos justo delante del cochecito (x, y, dirección), del más cercano al siguiente, sin los que
## caerían encima de él.
func front_passages() -> Array[Vector3i]:
    var fronts: Array[Vector3i] = []
    var cell: Vector2i = car_cell()
    var car_box: Rect2 = Rect2(car - Vector2.ONE * car_radius, Vector2.ONE * car_radius * 2.0).grow(FRONT_CLEARANCE)
    for ahead: int in 2:
        if not cave_ins.has_passage(cell, _heading_dir):
            break
        var rect: Rect2 = cave_ins.passage_rect(cell, _heading_dir, origin, cell_size, WALL_THICKNESS)
        if not rect.intersects(car_box):
            fronts.append(Vector3i(cell.x, cell.y, _heading_dir))
        cell += Maze.STEP[_heading_dir] as Vector2i
    return fronts


## Celda del laberinto bajo el cochecito (fuera del laberinto se cuenta la celda más cercana).
func car_cell() -> Vector2i:
    var raw: Vector2 = ((car - origin) / cell_size).floor()
    return Vector2i(clampi(int(raw.x), 0, maze.cols - 1), clampi(int(raw.y), 0, maze.rows - 1))


func center_of(cell: Vector2i) -> Vector2:
    return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func cave_in_rect(cave_in: MazeCaveIns.CaveIn) -> Rect2:
    return cave_ins.rect_of(cave_in, origin, cell_size, WALL_THICKNESS)


func _spawn_mineral() -> void:
    var distances: Dictionary = cave_ins.distances_from(car_cell())
    var options: Array[Vector2i] = []
    for cell: Vector2i in distances.keys():
        var steps: int = int(distances[cell])
        if steps >= SPAWN_DISTANCE_MIN and steps <= SPAWN_DISTANCE_MAX and spawns.at(cell) == null:
            options.append(cell)
    if options.is_empty():
        return
    options.sort()
    var slot: Vector2i = options[_rng.range_int(0, options.size() - 1)]
    var mineral: Mineral = _pick_mineral()
    spawns.add(slot, mineral, lifetime_for(int(distances[slot]), mineral))


func _pick_mineral() -> Mineral:
    var total: int = 0
    for weight: int in MINERAL_WEIGHT.values():
        total += weight
    var roll: int = _rng.range_int(1, total)
    for mineral: int in MINERAL_WEIGHT.keys():
        roll -= int(MINERAL_WEIGHT[mineral])
        if roll <= 0:
            return mineral as Mineral
    return Mineral.METAL


func _move(delta: float, direction: Vector2) -> void:
    var move: Vector2 = direction.limit_length(1.0) * CAR_SPEED * delta
    if absf(direction.x) > 0.0 or absf(direction.y) > 0.0:
        if absf(direction.x) >= absf(direction.y):
            _heading_dir = Maze.E if direction.x > 0.0 else Maze.W
        else:
            _heading_dir = Maze.S if direction.y > 0.0 else Maze.N
    var tried_x: Vector2 = Vector2(car.x + move.x, car.y)
    var is_blocked_x: bool = _collides(tried_x)
    if not is_blocked_x:
        car.x = clampf(tried_x.x, _bounds.position.x, _bounds.end.x)
    var tried_y: Vector2 = Vector2(car.x, car.y + move.y)
    var is_blocked_y: bool = _collides(tried_y)
    if not is_blocked_y:
        car.y = clampf(tried_y.y, _bounds.position.y, _bounds.end.y)
    # Asistencia de esquina: si empuja hacia un pasillo abierto y le frena el borde, se centra solo.
    if is_blocked_y and move.y != 0.0 and move.x == 0.0:
        _align_to_corridor(Maze.S if move.y > 0.0 else Maze.N, delta)
    elif is_blocked_x and move.x != 0.0 and move.y == 0.0:
        _align_to_corridor(Maze.E if move.x > 0.0 else Maze.W, delta)


## Desliza el cochecito hacia el centro de su celda, en perpendicular a `dir`, si ese paso está abierto.
func _align_to_corridor(dir: int, delta: float) -> void:
    if car.x < origin.x or not cave_ins.has_passage(car_cell(), dir):
        return
    var center: Vector2 = center_of(car_cell())
    var step_size: float = CAR_SPEED * delta
    var target: Vector2 = car
    if dir == Maze.N or dir == Maze.S:
        target.x = car.x + clampf(center.x - car.x, -step_size, step_size)
    else:
        target.y = car.y + clampf(center.y - car.y, -step_size, step_size)
    if not _collides(target):
        car = target


func _collect_nearby() -> void:
    for spawn: TimedSpawns.Spawn in spawns.items.duplicate():
        var where: Vector2 = center_of(spawn.slot)
        if where.distance_to(car) >= cell_size * PICKUP_RATIO:
            continue
        spawns.take(spawn)
        var mineral: Mineral = spawn.kind as Mineral
        var amount: int = int(MINERAL_VALUE[mineral])
        tally.add(mineral, amount)
        collected.emit(mineral, amount, where)


func _on_spawn_expired(spawn: TimedSpawns.Spawn) -> void:
    mineral_lost.emit(spawn.kind as Mineral, center_of(spawn.slot))


func _collides(center: Vector2) -> bool:
    var box: Rect2 = Rect2(center - Vector2(car_radius, car_radius), Vector2(car_radius, car_radius) * 2.0)
    for wall: Rect2 in walls:
        if box.intersects(wall):
            return true
    for cave_in: MazeCaveIns.CaveIn in cave_ins.active:
        if box.intersects(cave_in_rect(cave_in)):
            return true
    return false
