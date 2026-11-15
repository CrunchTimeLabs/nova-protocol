extends BaseTest
## Capa 3 (entidad): el cochecito recoge, choca con derrumbes y solo termina en la rampa;
## cada mineral da el tiempo justo del camino más corto, con menos margen el más valioso.


var run: CollectionRun


func before_each() -> void:
    run = CollectionRun.new(Vector2(160, 140), CollectionLevel.custom(Vector2i(15, 9), 46.0), 1)


func _drive_into_maze() -> void:
    run.has_random_events = false
    for i: int in 120:
        run.step(1.0 / 60.0, Vector2.RIGHT)


func test_lifetime_is_enough_and_tighter_for_crystal() -> void:
    var seconds_per_cell: float = run.cell_size / CollectionRun.CAR_SPEED
    for steps: int in [2, 6, 12]:
        var metal: float = run.lifetime_for(steps, CollectionRun.Mineral.METAL)
        var crystal: float = run.lifetime_for(steps, CollectionRun.Mineral.CRYSTAL)
        check(crystal >= float(steps) * seconds_per_cell, "%d pasos: da tiempo a llegar" % steps)
        check(crystal < metal, "%d pasos: el cristal aprieta más" % steps)


func test_collect_adds_to_tally() -> void:
    _drive_into_maze()
    var cell: Vector2i = run.car_cell()
    run.spawns.add(cell, CollectionRun.Mineral.CRYSTAL, 5.0)
    run.step(1.0 / 60.0, Vector2.ZERO)
    check_equal(run.tally.count(CollectionRun.Mineral.CRYSTAL), CollectionRun.MINERAL_VALUE[CollectionRun.Mineral.CRYSTAL], "suma al almacén")
    check(run.spawns.items.is_empty(), "el mineral desaparece al recogerlo")


func test_cave_in_blocks_the_car() -> void:
    _drive_into_maze()
    var cell: Vector2i = run.car_cell()
    var dir: int = -1
    for candidate: int in Maze.DIRECTIONS:
        if run.cave_ins.has_passage(cell, candidate):
            dir = candidate
    check(dir != -1, "hay un paso abierto")
    # El derrumbe no puede caer junto al cochecito: se coloca directamente para probar la colisión.
    var cave_in: MazeCaveIns.CaveIn = run.cave_ins._normalized(cell, dir, 10.0)
    run.cave_ins.active.append(cave_in)
    var target: Vector2 = run.center_of(cell + (Maze.STEP[dir] as Vector2i))
    for i: int in 120:
        run.step(1.0 / 60.0, (target - run.car).normalized())
    check_equal(run.car_cell(), cell, "no atraviesa el derrumbe")


func test_random_events_happen_and_finish_only_at_exit() -> void:
    var quick: CollectionLevel = CollectionLevel.custom(Vector2i(15, 9), 46.0)
    quick.cave_in_window = 5.0
    quick.cave_in_chance = 1.0
    run = CollectionRun.new(Vector2(160, 140), quick, 1)
    var cave_ins: Array[int] = [0]
    run.cave_in_started.connect(func(_c: MazeCaveIns.CaveIn) -> void: cave_ins[0] += 1)
    var minerals: int = 0
    for i: int in 60 * 30:
        run.step(1.0 / 60.0, Vector2.ZERO)
        minerals = maxi(minerals, run.spawns.items.size())
    check(cave_ins[0] > 0, "hay derrumbes")
    check(minerals > 0, "aparecen minerales")
    check(not run.is_finished, "quieto no termina")
    run.car = run.exit_rect.get_center()
    run.step(1.0 / 60.0, Vector2.ZERO)
    check(run.is_finished, "termina en la rampa")


func test_unpicked_mineral_is_lost() -> void:
    run.has_random_events = false
    var lost: Array[int] = [0]
    run.mineral_lost.connect(func(_m: CollectionRun.Mineral, _w: Vector2) -> void: lost[0] += 1)
    run.spawns.add(Vector2i(10, 4), CollectionRun.Mineral.METAL, 0.5)
    run.step(1.0, Vector2.ZERO)
    check_equal(lost[0], 1, "avisa al esfumarse")
    check_equal(run.tally.total(), 0, "no suma")


func test_front_cave_in_never_lands_on_the_car() -> void:
    var hard: CollectionLevel = CollectionLevel.new(CollectionLevel.Level.HARD)
    hard.front_chance = 1.0
    hard.cave_in_window = 1.0
    hard.cave_in_chance = 1.0
    var tight: CollectionRun = CollectionRun.new(Vector2(115, 100), hard, 4)
    var walker: GameRandom = GameRandom.new(4)
    var overlaps: Array[int] = [0]
    var started: Array[int] = [0]
    tight.cave_in_started.connect(func(cave_in: MazeCaveIns.CaveIn) -> void:
        started[0] += 1
        var box: Rect2 = Rect2(tight.car - Vector2.ONE * tight.car_radius, Vector2.ONE * tight.car_radius * 2.0)
        if box.intersects(tight.cave_in_rect(cave_in)):
            overlaps[0] += 1
    )
    var direction: Vector2 = Vector2.RIGHT
    for i: int in 60 * 60:
        if i % 30 == 0:
            direction = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN][walker.range_int(0, 3)]
        tight.step(1.0 / 60.0, direction)
    check(started[0] > 20, "caen derrumbes (%d)" % started[0])
    check_equal(overlaps[0], 0, "ninguno encima del cochecito")


func test_cave_ins_follow_the_two_minute_clock() -> void:
    # Una partida larga en Difícil: como mucho un derrumbe (de 3 pasos) por cada ventana.
    var hard: CollectionLevel = CollectionLevel.new(CollectionLevel.Level.HARD)
    var long_run: CollectionRun = CollectionRun.new(Vector2(115, 100), hard, 9)
    long_run.car = long_run.center_of(long_run.maze.entrance())
    var events: Array[float] = []
    var now: Array[float] = [0.0]
    long_run.cave_in_started.connect(func(_c: MazeCaveIns.CaveIn) -> void:
        if events.is_empty() or now[0] - events[-1] > 0.01:
            events.append(now[0])
    )
    var windows: int = 20
    var dt: float = 0.1
    for i: int in int(float(windows) * hard.cave_in_window / dt):
        now[0] += dt
        long_run.step(dt, Vector2.ZERO)
    check(events.size() <= windows, "como mucho uno por ventana (%d)" % events.size())
    check(events.size() >= 16, "con 95 %% caen en buena parte de las ventanas (%d de %d)" % [events.size(), windows])


## Regresión: al llegar de lado a una celda y querer subir, el cochecito queda corrido respecto al pasillo
## de arriba; el borde del muro lo frenaba y se quedaba quieto.
func test_off_center_car_still_enters_an_open_corridor() -> void:
    for level_id: int in [CollectionLevel.Level.EASY, CollectionLevel.Level.MEDIUM, CollectionLevel.Level.HARD]:
        var data: CollectionLevel = CollectionLevel.new(level_id as CollectionLevel.Level)
        for side: int in [Maze.W, Maze.E]:
            var tight: CollectionRun = CollectionRun.new(Vector2(85, 60), data, 5)
            tight.has_random_events = false
            var start: Vector2i = Vector2i(-1, -1)
            for y: int in range(1, tight.maze.rows):
                for x: int in range(1, tight.maze.cols - 1):
                    var cell: Vector2i = Vector2i(x, y)
                    if start.x < 0 and tight.cave_ins.has_passage(cell, Maze.N) and tight.cave_ins.has_passage(cell, side):
                        start = cell
            check(start.x >= 0, "hay una celda de prueba")
            # Llega de lado: centrado en la vecina y avanzando hasta medio camino hacia la celda.
            var neighbour: Vector2i = start + (Maze.STEP[side] as Vector2i)
            tight.car = tight.center_of(neighbour).lerp(tight.center_of(start), 0.7)
            check(not tight._collides(tight.car), "%s: posición de partida libre" % data.title())
            for i: int in 60:
                tight.step(1.0 / 60.0, Vector2.UP)
            check(tight.car_cell().y < start.y, "%s: sube viniendo por %s" % [data.title(), "la izquierda" if side == Maze.W else "la derecha"])
