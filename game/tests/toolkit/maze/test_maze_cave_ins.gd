extends BaseTest
## Capa 2 (regla): los derrumbes tapan pasos un rato, son reproducibles y nunca encierran a nadie.


const STEP_TIME := 0.25


func _cave_ins(seed_value: int) -> MazeCaveIns:
    var maze: Maze = Maze.generate(15, 9, GameRandom.new(seed_value))
    return MazeCaveIns.new(maze, GameRandom.new(seed_value), Vector2(0.5, 1.0), Vector2(2.0, 4.0), 3)


func test_never_cuts_the_way_to_the_exit() -> void:
    for seed_value: int in [1, 2, 3, 90210]:
        var cave_ins: MazeCaveIns = _cave_ins(seed_value)
        var walker: GameRandom = GameRandom.new(seed_value)
        var started: int = 0
        var cell: Vector2i = cave_ins.maze.entrance()
        for i: int in 400:
            # Quien camina solo cruza pasos abiertos (como el cochecito).
            var dir: int = Maze.DIRECTIONS[walker.range_int(0, 3)]
            if cave_ins.has_passage(cell, dir):
                cell += Maze.STEP[dir] as Vector2i
            started += cave_ins.tick(STEP_TIME, cell).size()
            check(cave_ins.distances_from(cell).has(cave_ins.maze.exit_cell()), "semilla %d: salida alcanzable desde %s" % [seed_value, str(cell)])
            check(cave_ins.active.size() <= 3, "semilla %d: máximo de derrumbes" % seed_value)
        check(started > 10, "semilla %d: hay derrumbes (%d)" % [seed_value, started])


func test_blocked_passage_stops_and_expires() -> void:
    var cave_ins: MazeCaveIns = _cave_ins(5)
    var far: Vector2i = Vector2i(0, 0)
    var cave_in: MazeCaveIns.CaveIn = null
    for y: int in range(3, 9):
        for x: int in range(5, 14):
            for dir: int in [Maze.E, Maze.S]:
                if cave_in == null:
                    cave_in = cave_ins.block(Vector2i(x, y), dir, 1.0, far)
                    if cave_in != null:
                        check(not cave_ins.has_passage(Vector2i(x, y), dir), "tapado desde un lado")
                        check(cave_ins.is_blocked(Vector2i(x, y) + (Maze.STEP[dir] as Vector2i), int(Maze.OPPOSITE[dir])), "tapado desde el otro")
    check(cave_in != null, "se pudo tapar algún paso")
    cave_ins.expire(1.1)
    check(cave_ins.active.is_empty(), "el derrumbe caduca")


func test_rejects_walls_and_safe_zone() -> void:
    var cave_ins: MazeCaveIns = _cave_ins(7)
    var maze: Maze = cave_ins.maze
    var protected_cell: Vector2i = Vector2i(7, 4)
    for dir: int in Maze.DIRECTIONS:
        check(cave_ins.block(protected_cell, dir, 2.0, protected_cell) == null, "no cae junto al protegido")
    for y: int in maze.rows:
        for x: int in maze.cols:
            if maze.has_wall(Vector2i(x, y), Maze.N) and y > 0:
                check(cave_ins.block(Vector2i(x, y), Maze.N, 2.0, Vector2i(0, 0)) == null, "no tapa un muro")
                return


func test_same_seed_same_cave_ins() -> void:
    var first: MazeCaveIns = _cave_ins(9)
    var second: MazeCaveIns = _cave_ins(9)
    for i: int in 100:
        first.tick(STEP_TIME, Vector2i(0, 4))
        second.tick(STEP_TIME, Vector2i(0, 4))
    check_equal(first.active.size(), second.active.size(), "mismo número")
    for i: int in first.active.size():
        check_equal(first.active[i].cell, second.active[i].cell, "misma celda")
        check_equal(first.active[i].dir, second.active[i].dir, "misma dirección")


func test_path_respects_cave_ins() -> void:
    var cave_ins: MazeCaveIns = _cave_ins(3)
    var from: Vector2i = cave_ins.maze.entrance()
    var to: Vector2i = cave_ins.maze.exit_cell()
    var path: Array[Vector2i] = cave_ins.path_between(from, to)
    check_equal(path.size(), int(cave_ins.distances_from(from)[to]), "camino más corto")
    check_equal(path[-1], to, "acaba en el destino")


func _front_cave_ins(seed_value: int, chance: float) -> MazeCaveIns:
    var maze: Maze = Maze.generate(15, 9, GameRandom.new(seed_value))
    return MazeCaveIns.new(maze, GameRandom.new(seed_value), Vector2(0.5, 1.0), Vector2(2.0, 4.0), 3, chance)


func test_front_is_blocked_first_but_never_cuts_the_exit() -> void:
    for seed_value: int in [1, 2, 3]:
        var cave_ins: MazeCaveIns = _front_cave_ins(seed_value, 1.0)
        var walker: GameRandom = GameRandom.new(seed_value + 100)
        var cell: Vector2i = cave_ins.maze.entrance()
        var in_front: int = 0
        var total: int = 0
        for i: int in 400:
            var dir: int = Maze.DIRECTIONS[walker.range_int(0, 3)]
            if cave_ins.has_passage(cell, dir):
                cell += Maze.STEP[dir] as Vector2i
            var heading: int = Maze.DIRECTIONS[walker.range_int(0, 3)]
            var fronts: Array[Vector3i] = [Vector3i(cell.x, cell.y, heading)]
            var could_block: bool = cave_ins.has_passage(cell, heading)
            for cave_in: MazeCaveIns.CaveIn in cave_ins.tick(0.25, cell, fronts):
                total += 1
                if cave_ins.is_blocked(cell, heading) and could_block:
                    in_front += 1
            check(cave_ins.distances_from(cell).has(cave_ins.maze.exit_cell()), "semilla %d: salida alcanzable" % seed_value)
        check(total > 10, "semilla %d: hay derrumbes" % seed_value)
        check(in_front > 0, "semilla %d: alguno cae justo delante" % seed_value)


func test_front_chance_is_about_thirty_percent() -> void:
    # Paso delantero siempre tapable (lejos de la salida y con bucles): cuenta cuántas veces se elige.
    var hits: int = 0
    var draws: int = 0
    for seed_value: int in range(1, 41):
        var cave_ins: MazeCaveIns = _front_cave_ins(seed_value, 0.3)
        var maze: Maze = cave_ins.maze
        var front: Vector3i = Vector3i(-1, -1, -1)
        for y: int in maze.rows:
            for x: int in maze.cols:
                if front.z == -1 and maze.contains(Vector2i(x + 1, y)) and not maze.has_wall(Vector2i(x, y), Maze.E):
                    var probe: MazeCaveIns.CaveIn = cave_ins.block_in_front(Vector2i(x, y), Maze.E, 1.0, Vector2i(0, 0))
                    if probe != null:
                        cave_ins.active.erase(probe)
                        front = Vector3i(x, y, Maze.E)
        var fronts: Array[Vector3i] = [front]
        for i: int in 30:
            for cave_in: MazeCaveIns.CaveIn in cave_ins.tick(1.0, Vector2i(0, 0), fronts):
                draws += 1
                if cave_ins.is_blocked(Vector2i(front.x, front.y), front.z):
                    hits += 1
            cave_ins.active.clear()
    var ratio: float = float(hits) / float(draws)
    check(draws > 200, "suficientes derrumbes (%d)" % draws)
    check(ratio > 0.22 and ratio < 0.38, "cerca del 30 %% delante (%.2f)" % ratio)
