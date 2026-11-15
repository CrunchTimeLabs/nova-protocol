class_name CollectionDemo
extends RefCounted
## Demostración del tutorial: una recolección pequeña sin eventos al azar donde el cochecito se conduce solo
## (piloto automático por el camino más corto) y los minerales y derrumbes se colocan con guion.
## Determinista: misma escena, misma película.


enum Scene { DRIVE_AND_COLLECT, VANISH, CAVE_IN, EXIT }

const SIZE := Vector2i(7, 5)
const CELL := 46.0
const ORIGIN := Vector2(120, 40)
const SEED := 4
## El área que ocupa la demo, para que la vista la amplíe.
const AREA := Rect2(0, 0, 540, 310)
## Segundos de pausa al terminar antes de repetir.
const HOLD := 1.2
## Segundos que conduce hacia el cristal antes de que se esfume (no le da para llegar).
const VANISH_HEAD_START := 1.5
const CAVE_IN_TRIGGER_STEPS := 2
const CAVE_IN_DURATION := 3.5
const ARRIVE_DISTANCE := 3.0

var scene: Scene
var run: CollectionRun
var time: float = 0.0

var _targets: Array[Vector2i] = []
var _wait: float = 0.0
var _has_caved_in: bool = false
var _over_at: float = -1.0
var _vanishing: TimedSpawns.Spawn


func _init(p_scene: Scene) -> void:
    scene = p_scene
    run = CollectionRun.new(ORIGIN, CollectionLevel.custom(SIZE, CELL), SEED)
    run.has_random_events = false
    var start: Vector2i = run.maze.entrance()
    match scene:
        Scene.DRIVE_AND_COLLECT:
            var near: Vector2i = _cell_at(2)
            var far: Vector2i = _cell_at(5)
            run.spawns.add(near, CollectionRun.Mineral.METAL, 60.0)
            run.spawns.add(far, CollectionRun.Mineral.CRYSTAL, 60.0)
            _targets = [start, near, far]
        Scene.VANISH:
            var far: Vector2i = _cell_at(7)
            _vanishing = run.place_mineral(far, CollectionRun.Mineral.CRYSTAL)
            _wait = _vanishing.lifetime - VANISH_HEAD_START
            _targets = [start, far]
        Scene.CAVE_IN, Scene.EXIT:
            _targets = [start, run.maze.exit_cell()]


## Avanza la película. Devuelve true cuando ha terminado y se puede repetir.
func step(delta: float) -> bool:
    time += delta
    if _over_at >= 0.0:
        run.step(delta, Vector2.ZERO)
        return time - _over_at >= HOLD
    var direction: Vector2 = Vector2.ZERO if time < _wait else _autopilot()
    run.step(delta, direction)
    if scene == Scene.CAVE_IN and not _has_caved_in:
        _try_cave_in()
    if _is_scene_done():
        _over_at = time
    return false


func _is_scene_done() -> bool:
    match scene:
        Scene.DRIVE_AND_COLLECT:
            return run.spawns.items.is_empty()
        Scene.VANISH:
            return not run.spawns.items.has(_vanishing)
        Scene.CAVE_IN, Scene.EXIT:
            return run.is_finished
    return run.is_finished


## Dirección hacia el centro de la siguiente celda del camino más corto al objetivo actual.
func _autopilot() -> Vector2:
    if _targets.is_empty():
        return Vector2.ZERO
    var target: Vector2i = _targets[0]
    var goal: Vector2 = run.center_of(target)
    if run.car.x >= run.origin.x:
        var path: Array[Vector2i] = run.cave_ins.path_between(run.car_cell(), target)
        if not path.is_empty():
            goal = run.center_of(path[0])
    if target == run.maze.exit_cell() and run.car_cell() == target:
        goal = run.exit_rect.get_center()
    var offset: Vector2 = goal - run.car
    if offset.length() < ARRIVE_DISTANCE:
        if goal == run.center_of(target):
            _targets.pop_front()
        return Vector2.ZERO
    return offset.normalized()


## Tapa un paso del camino a la salida un poco por delante del cochecito (obliga a rodear o esperar).
func _try_cave_in() -> void:
    var path: Array[Vector2i] = run.cave_ins.path_between(run.car_cell(), run.maze.exit_cell())
    if run.car.x < run.origin.x or path.size() <= CAVE_IN_TRIGGER_STEPS + 1:
        return
    for i: int in range(CAVE_IN_TRIGGER_STEPS, path.size() - 1):
        var from: Vector2i = path[i]
        var to: Vector2i = path[i + 1]
        for dir: int in Maze.DIRECTIONS:
            if from + (Maze.STEP[dir] as Vector2i) != to:
                continue
            if run.add_cave_in(from, dir, CAVE_IN_DURATION) != null:
                _has_caved_in = true
                return


## Primera celda (en orden) a `steps` pasos de la entrada; si no hay, la más lejana.
func _cell_at(steps: int) -> Vector2i:
    var distances: Dictionary = run.cave_ins.distances_from(run.maze.entrance())
    var cells: Array[Vector2i] = []
    cells.assign(distances.keys())
    cells.sort()
    var best: Vector2i = run.maze.entrance()
    for cell: Vector2i in cells:
        if int(distances[cell]) == steps:
            return cell
        if int(distances[cell]) > int(distances[best]):
            best = cell
    return best
