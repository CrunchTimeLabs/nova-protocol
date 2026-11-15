extends BaseTest
## Capa 2 (regla): recolección a dos en el mismo laberinto: entradas, calentamiento, menas por jugador,
## mínimo para abrir la rampa, final con los dos en ella y derrumbes que no encierran a nadie.


const SEED := 7

var _run: DuoRun


func before_each() -> void:
    _run = DuoRun.new(DuoLevel.new(CollectionLevel.Level.EASY), SEED)


func _idle(seconds: float) -> void:
    var none: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
    var t: float = 0.0
    while t < seconds:
        _run.step(0.05, none)
        t += 0.05


func test_mazes_are_much_bigger_and_grow_with_difficulty() -> void:
    var previous: int = 0
    for level: CollectionLevel.Level in [CollectionLevel.Level.EASY, CollectionLevel.Level.MEDIUM, CollectionLevel.Level.HARD]:
        var duo: DuoLevel = DuoLevel.new(level)
        var solo: CollectionLevel = CollectionLevel.new(level)
        var cells: int = duo.size.x * duo.size.y
        check(cells >= 2 * solo.size.x * solo.size.y, "%s: al menos el doble de celdas que el de uno" % duo.title())
        check(cells > previous, "%s: más grande que el anterior" % duo.title())
        previous = cells
        var board: Vector2 = Vector2(duo.size) * duo.cell_size
        check(DuoLevel.BOARD.encloses(Rect2(duo.origin(), board)), "%s: cabe entero en pantalla" % duo.title())
        check(duo.minimum > 0, "%s: hay un mínimo" % duo.title())


func test_players_start_outside_on_opposite_sides() -> void:
    var left: MazeCar = _run.cars[0]
    var right: MazeCar = _run.cars[1]
    check_equal(left.player, 1, "el primero es el jugador 1")
    check(left.position.x < _run.origin.x, "el jugador 1 empieza a la izquierda, fuera")
    check(right.position.x > _run.origin.x + float(_run.maze.cols) * _run.cell_size, "el jugador 2 empieza a la derecha, fuera")
    check(not _run.both_entered(), "aún no ha entrado nadie")


func test_nothing_appears_while_warming_up() -> void:
    _idle(20.0)
    check(_run.spawns.items.is_empty(), "sin menas durante el tutorial")
    check(_run.cave_ins.active.is_empty(), "sin derrumbes durante el tutorial")


func test_both_players_entering_counts_each_one() -> void:
    var moves: Array[Vector2] = [Vector2.RIGHT, Vector2.ZERO]
    for i: int in 40:
        _run.step(0.05, moves)
    check(_run.cars[0].has_entered, "el jugador 1 entró")
    check(not _run.cars[1].has_entered, "el 2 todavía no")
    moves = [Vector2.ZERO, Vector2.LEFT]
    for i: int in 40:
        _run.step(0.05, moves)
    check(_run.both_entered(), "entraron los dos")


func test_collecting_goes_to_the_car_that_drove_over() -> void:
    _run.is_warming_up = false
    var car: MazeCar = _run.cars[1]
    var slot: Vector2i = _run.cell_of(car.position + Vector2(-_run.cell_size * 1.5, 0.0))
    car.position = _run.center_of(slot)
    _run.spawns.add(slot, Ores.Ore.ILMENITE, 10.0)
    _idle(0.05)
    check_equal(car.tally.count(Ores.Ore.ILMENITE), 1, "el jugador 2 suma la ilmenita")
    check_equal(_run.cars[0].units(), 0, "el jugador 1 no suma nada")
    check_equal(_run.total(), 1, "el total es la suma de los dos")


func test_exit_needs_minimum_and_both_players() -> void:
    _run.is_warming_up = false
    var ramp: Vector2 = _run.exit_rect.get_center()
    _run.cars[0].position = ramp
    _run.cars[1].position = ramp
    _idle(0.1)
    check(not _run.is_finished, "sin el mínimo la rampa está cerrada")
    for i: int in _run.level.minimum:
        _run.cars[i % 2].tally.add(Ores.Ore.HEMATITE, 1)
    _run.cars[1].position = _run.center_of(Vector2i(3, 3))
    _idle(0.1)
    check(_run.is_exit_open(), "con el mínimo se abre")
    check(not _run.is_finished, "falta que llegue el jugador 2")
    _run.cars[1].position = ramp
    _idle(0.1)
    check(_run.is_finished, "con los dos en la rampa termina")


func test_leader_is_who_collected_more() -> void:
    _run.cars[0].tally.add(Ores.Ore.BAUXITE, 1)
    check_equal(_run.leader(), 1, "gana el jugador 1")
    _run.cars[1].tally.add(Ores.Ore.BAUXITE, 2)
    check_equal(_run.leader(), 2, "gana el jugador 2")
    _run.cars[0].tally.add(Ores.Ore.BAUXITE, 1)
    check_equal(_run.leader(), 0, "empate")


func test_cave_ins_never_trap_either_player() -> void:
    _run.is_warming_up = false
    _run.cars[0].position = _run.center_of(Vector2i(2, 2))
    _run.cars[1].position = _run.center_of(Vector2i(_run.maze.cols - 3, _run.maze.rows - 3))
    for i: int in 30:
        _run._drop_cave_ins()
        _run.cave_ins.also_protected = [_run.cell_of(_run.cars[0].position), _run.cell_of(_run.cars[1].position)]
    check(_run.cave_ins.active.size() > 0, "caen derrumbes")
    for car: MazeCar in _run.cars:
        check(_run.cave_ins.distances_from(_run.cell_of(car.position)).has(_run.exit_cell), "el jugador %d llega a la rampa" % car.player)


func test_ores_spawn_after_warm_up_with_fair_lifetime() -> void:
    _run.is_warming_up = false
    _run.cars[0].position = _run.center_of(Vector2i(5, 5))
    _run.cars[1].position = _run.center_of(Vector2i(15, 7))
    _idle(6.0)
    check(not _run.spawns.items.is_empty(), "aparecen menas")
    for spawn: TimedSpawns.Spawn in _run.spawns.items:
        check(spawn.lifetime > DuoRun.REACTION_TIME, "cada mena da tiempo de reaccionar")
