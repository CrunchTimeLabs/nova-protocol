class_name DuoRun
extends RefCounted
## Recolección a dos en el mismo laberinto, a la vez y sin pantalla dividida. El jugador 1 entra por la
## izquierda y el 2 por la derecha. Hay menas (las 5 de `Ores`) que aparecen cerca de alguno de los dos con
## la vida justa para llegar, y derrumbes que no caen junto a ninguno ni dejan a nadie sin camino.
## Mientras dura el tutorial (`is_warming_up`) no aparece nada: solo se conduce.
## La rampa de abajo se abre al juntar el mínimo entre los dos; termina cuando ambos están en ella.
## Coordenadas en píxeles de pantalla.


signal collected(car: MazeCar, ore: Ores.Ore, where: Vector2)
signal ore_lost(ore: Ores.Ore, where: Vector2)
signal cave_in_started(cave_in: MazeCaveIns.CaveIn)
signal exit_opened
signal finished

const PLAYERS := 2
const CAR_RADIUS_RATIO := 0.31
const PICKUP_RATIO := 0.57
const CAR_SPEED := 175.0
const WALL_THICKNESS := 4.0
const FRONT_CLEARANCE := 3.0
## Distancia desde el borde del laberinto donde arranca cada cochecito (fuera de él).
const START_GAP := 40.0
const REACTION_TIME := 1.8
const SPAWN_DISTANCE := Vector2i(3, 14)
const SPAWN_INTERVAL := Vector2(0.8, 1.7)
const SPAWN_MAX_ALIVE := 10
const EXIT_DEPTH := 46.0
const CAVE_IN_SEED_OFFSET := 11
const CAVE_IN_CLOCK_SEED_OFFSET := 37
const SPAWN_SEED_OFFSET := 23

var level: DuoLevel
var maze: Maze
var cave_ins: MazeCaveIns
var cave_in_clock: ChanceWindow
var spawns: TimedSpawns
var origin: Vector2
var cell_size: float
var car_radius: float
var walls: Array[Rect2] = []
var cars: Array[MazeCar] = []
## Celda de abajo al centro por la que se sale, y la rampa bajo ella.
var exit_cell: Vector2i
var exit_rect: Rect2
var is_warming_up: bool = true
var is_finished: bool = false

var _rng: GameRandom
var _bounds: Rect2
var _next_spawn_player: int = 0
var _was_exit_open: bool = false


func _init(p_level: DuoLevel, seed_value: int) -> void:
    level = p_level
    origin = level.origin()
    cell_size = level.cell_size
    car_radius = cell_size * CAR_RADIUS_RATIO
    maze = Maze.generate(level.size.x, level.size.y, GameRandom.new(seed_value))
    exit_cell = Vector2i(level.size.x / 2, level.size.y - 1)
    maze.open_border(exit_cell, Maze.S)
    cave_ins = MazeCaveIns.new(
            maze,
            GameRandom.new(seed_value + CAVE_IN_SEED_OFFSET),
            Vector2(level.cave_in_window, level.cave_in_window),
            level.cave_in_duration,
            level.cave_in_max,
            level.front_chance,
            )
    cave_ins.goal = exit_cell
    cave_in_clock = ChanceWindow.new(
            GameRandom.new(seed_value + CAVE_IN_CLOCK_SEED_OFFSET),
            level.cave_in_window,
            level.cave_in_chance,
            )
    spawns = TimedSpawns.new(GameRandom.new(seed_value + SPAWN_SEED_OFFSET), SPAWN_INTERVAL, SPAWN_MAX_ALIVE)
    spawns.expired.connect(_on_spawn_expired)
    _rng = GameRandom.new(seed_value + SPAWN_SEED_OFFSET + 1)
    walls = maze.wall_rects(origin, cell_size, WALL_THICKNESS)
    var board: Vector2 = Vector2(maze.cols, maze.rows) * cell_size
    var left_y: float = center_of(maze.entrance()).y
    var right_y: float = center_of(maze.exit_cell()).y
    cars.append(MazeCar.new(1, Vector2(origin.x - START_GAP, left_y), Maze.E))
    cars.append(MazeCar.new(2, Vector2(origin.x + board.x + START_GAP, right_y), Maze.W))
    var exit_center: Vector2 = center_of(exit_cell)
    exit_rect = Rect2(exit_center.x - cell_size * 0.8, origin.y + board.y + WALL_THICKNESS + 2.0, cell_size * 1.6, EXIT_DEPTH)
    # Sin margen arriba: nadie puede rodear el laberinto por encima del muro.
    _bounds = Rect2(
            origin - Vector2(START_GAP + 20.0, 0.0),
            board + Vector2(2.0 * (START_GAP + 20.0), 10.0 + EXIT_DEPTH),
            )


func total() -> int:
    var sum: int = 0
    for car: MazeCar in cars:
        sum += car.units()
    return sum


func ore_total(ore: Ores.Ore) -> int:
    var sum: int = 0
    for car: MazeCar in cars:
        sum += car.tally.count(ore)
    return sum


func is_exit_open() -> bool:
    return total() >= level.minimum


## Avanza un paso con la dirección de cada jugador (índice 0 = jugador 1).
func step(delta: float, directions: Array[Vector2]) -> void:
    if is_finished:
        return
    cave_ins.expire(delta)
    if not is_warming_up:
        cave_ins.also_protected = [cell_of(cars[0].position), cell_of(cars[1].position)]
        if cave_in_clock.tick(delta) > 0:
            _drop_cave_ins()
        if spawns.tick(delta):
            _spawn_ore()
    else:
        spawns.expire(delta)
    for index: int in cars.size():
        var car: MazeCar = cars[index]
        _move(car, delta, directions[index] if index < directions.size() else Vector2.ZERO)
        if not car.has_entered and _inside_board(car.position):
            car.has_entered = true
        _collect_nearby(car)
        car.is_on_exit = exit_rect.has_point(car.position)
    if is_exit_open() and not _was_exit_open:
        _was_exit_open = true
        exit_opened.emit()
    if is_exit_open() and cars[0].is_on_exit and cars[1].is_on_exit:
        is_finished = true
        finished.emit()


func both_entered() -> bool:
    return cars[0].has_entered and cars[1].has_entered


## Quien recogió más menas: 1, 2 o 0 si empatan.
func leader() -> int:
    var first: int = cars[0].units()
    var second: int = cars[1].units()
    if first == second:
        return 0
    return 1 if first > second else 2


func cell_of(point: Vector2) -> Vector2i:
    var raw: Vector2 = ((point - origin) / cell_size).floor()
    return Vector2i(clampi(int(raw.x), 0, maze.cols - 1), clampi(int(raw.y), 0, maze.rows - 1))


func center_of(cell: Vector2i) -> Vector2:
    return origin + (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func cave_in_rect(cave_in: MazeCaveIns.CaveIn) -> Rect2:
    return cave_ins.rect_of(cave_in, origin, cell_size, WALL_THICKNESS)


func lifetime_for(steps: int, ore: Ores.Ore) -> float:
    return float(steps + 1) * (cell_size / CAR_SPEED) * float(Ores.SLACK[ore]) + REACTION_TIME


func _inside_board(point: Vector2) -> bool:
    return Rect2(origin, Vector2(maze.cols, maze.rows) * cell_size).has_point(point)


## Un derrumbe por cada jugador, por turnos: cada uno puede tenerlo delante (con `front_chance`).
func _drop_cave_ins() -> void:
    var count: int = level.passages_per_cave_in
    for index: int in cars.size():
        var car: MazeCar = cars[index]
        var share: int = count / 2 + (count % 2 if index == 0 else 0)
        for cave_in: MazeCaveIns.CaveIn in cave_ins.drop(cell_of(car.position), _front_passages(car), share):
            cave_in_started.emit(cave_in)


func _front_passages(car: MazeCar) -> Array[Vector3i]:
    var fronts: Array[Vector3i] = []
    if not _inside_board(car.position):
        return fronts
    var cell: Vector2i = cell_of(car.position)
    var boxes: Array[Rect2] = []
    for other: MazeCar in cars:
        boxes.append(Rect2(other.position - Vector2.ONE * car_radius, Vector2.ONE * car_radius * 2.0).grow(FRONT_CLEARANCE))
    for ahead: int in 2:
        if not cave_ins.has_passage(cell, car.heading_dir):
            break
        var rect: Rect2 = cave_ins.passage_rect(cell, car.heading_dir, origin, cell_size, WALL_THICKNESS)
        var is_clear: bool = true
        for box: Rect2 in boxes:
            if rect.intersects(box):
                is_clear = false
        if is_clear:
            fronts.append(Vector3i(cell.x, cell.y, car.heading_dir))
        cell += Maze.STEP[car.heading_dir] as Vector2i
    return fronts


## Aparece una mena cerca de uno de los dos (por turnos) con la vida justa desde el más cercano.
func _spawn_ore() -> void:
    var car: MazeCar = cars[_next_spawn_player]
    _next_spawn_player = (_next_spawn_player + 1) % cars.size()
    var distances: Dictionary = cave_ins.distances_from(cell_of(car.position))
    var options: Array[Vector2i] = []
    for cell: Vector2i in distances.keys():
        var steps: int = int(distances[cell])
        if steps >= SPAWN_DISTANCE.x and steps <= SPAWN_DISTANCE.y and spawns.at(cell) == null and cell != exit_cell:
            options.append(cell)
    if options.is_empty():
        return
    options.sort()
    var slot: Vector2i = options[_rng.range_int(0, options.size() - 1)]
    var ore: Ores.Ore = Ores.pick(_rng)
    var nearest: int = int(distances[slot])
    for other: MazeCar in cars:
        var other_distances: Dictionary = cave_ins.distances_from(cell_of(other.position))
        if other_distances.has(slot):
            nearest = mini(nearest, int(other_distances[slot]))
    spawns.add(slot, ore, lifetime_for(nearest, ore))


func _move(car: MazeCar, delta: float, direction: Vector2) -> void:
    var move: Vector2 = direction.limit_length(1.0) * CAR_SPEED * delta
    if absf(direction.x) > 0.0 or absf(direction.y) > 0.0:
        if absf(direction.x) >= absf(direction.y):
            car.heading_dir = Maze.E if direction.x > 0.0 else Maze.W
        else:
            car.heading_dir = Maze.S if direction.y > 0.0 else Maze.N
    var tried_x: Vector2 = Vector2(car.position.x + move.x, car.position.y)
    var is_blocked_x: bool = _collides(tried_x)
    if not is_blocked_x:
        car.position.x = clampf(tried_x.x, _bounds.position.x, _bounds.end.x)
    var tried_y: Vector2 = Vector2(car.position.x, car.position.y + move.y)
    var is_blocked_y: bool = _collides(tried_y)
    if not is_blocked_y:
        car.position.y = clampf(tried_y.y, _bounds.position.y, _bounds.end.y)
    if is_blocked_y and move.y != 0.0 and move.x == 0.0:
        _align_to_corridor(car, Maze.S if move.y > 0.0 else Maze.N, delta)
    elif is_blocked_x and move.x != 0.0 and move.y == 0.0:
        _align_to_corridor(car, Maze.E if move.x > 0.0 else Maze.W, delta)


## Asistencia de esquina: si empuja hacia un pasillo abierto y le frena el borde, se centra solo.
func _align_to_corridor(car: MazeCar, dir: int, delta: float) -> void:
    var cell: Vector2i = cell_of(car.position)
    var is_exit_way: bool = cell == exit_cell and dir == Maze.S
    if not _inside_board(car.position) and not _near_exit(car.position):
        return
    if not is_exit_way and not cave_ins.has_passage(cell, dir):
        if not (dir == Maze.W and cell == maze.entrance()) and not (dir == Maze.E and cell == maze.exit_cell()):
            return
    var center: Vector2 = center_of(cell)
    var step_size: float = CAR_SPEED * delta
    var target: Vector2 = car.position
    if dir == Maze.N or dir == Maze.S:
        target.x = car.position.x + clampf(center.x - car.position.x, -step_size, step_size)
    else:
        target.y = car.position.y + clampf(center.y - car.position.y, -step_size, step_size)
    if not _collides(target):
        car.position = target


func _near_exit(point: Vector2) -> bool:
    return exit_rect.grow(cell_size).has_point(point)


func _collect_nearby(car: MazeCar) -> void:
    for spawn: TimedSpawns.Spawn in spawns.items.duplicate():
        var where: Vector2 = center_of(spawn.slot)
        if where.distance_to(car.position) >= cell_size * PICKUP_RATIO:
            continue
        spawns.take(spawn)
        var ore: Ores.Ore = spawn.kind as Ores.Ore
        car.tally.add(ore, 1)
        collected.emit(car, ore, where)


func _on_spawn_expired(spawn: TimedSpawns.Spawn) -> void:
    ore_lost.emit(spawn.kind as Ores.Ore, center_of(spawn.slot))


func _collides(center: Vector2) -> bool:
    var box: Rect2 = Rect2(center - Vector2(car_radius, car_radius), Vector2(car_radius, car_radius) * 2.0)
    for wall: Rect2 in walls:
        if box.intersects(wall):
            return true
    for cave_in: MazeCaveIns.CaveIn in cave_ins.active:
        if box.intersects(cave_in_rect(cave_in)):
            return true
    # La rampa tiene paredes a los lados: solo se baja por la celda de salida.
    var below: float = origin.y + float(maze.rows) * cell_size
    if box.end.y > below + WALL_THICKNESS:
        # El carril empieza una celda dentro del laberinto: el coche cruza el borde con parte del cuerpo aún dentro.
        var lane: Rect2 = Rect2(exit_rect.position.x, below - cell_size, exit_rect.size.x, cell_size + EXIT_DEPTH + WALL_THICKNESS + 4.0)
        if not lane.encloses(box) and _inside_horizontal_board(box):
            return true
    return false


func _inside_horizontal_board(box: Rect2) -> bool:
    return box.end.x > origin.x and box.position.x < origin.x + float(maze.cols) * cell_size
