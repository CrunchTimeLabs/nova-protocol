extends BaseTest
## Capa 4 (orquestador): se juega desde el principio con el tutorial al lado; cada paso se cumple
## haciendo lo que enseña; el primer derrumbe abre su lección (una vez) y se cierra al despejarse.


var session: CollectionSession


func before_each() -> void:
    session = CollectionSession.new(CollectionRun.new(Vector2(160, 140), CollectionLevel.custom(Vector2i(15, 9), 46.0), 1))
    session.run.has_random_events = false


func _goal() -> int:
    return session.active_lesson().current().goal


func _cave_in_far() -> MazeCaveIns.CaveIn:
    var maze: Maze = session.run.maze
    for y: int in maze.rows:
        for x: int in range(maze.cols - 1, 3, -1):
            var cave_in: MazeCaveIns.CaveIn = session.run.add_cave_in(Vector2i(x, y), Maze.W, 1.0)
            if cave_in != null:
                return cave_in
    return null


func test_tutorial_follows_what_the_player_does_without_pausing() -> void:
    check_equal(_goal(), CollectionSession.Goal.ENTER_MAZE, "primero: entrar")
    var start: Vector2 = session.run.car
    session.tick(1.0, Vector2.RIGHT)
    check(session.run.car != start, "no pausa")
    check_equal(_goal(), CollectionSession.Goal.COLLECT_ANY, "entró: ahora recoger")
    session.run.spawns.add(session.run.car_cell(), CollectionRun.Mineral.METAL, 5.0)
    session.tick(0.01, Vector2.ZERO)
    check_equal(_goal(), CollectionSession.Goal.COLLECT_CRYSTAL, "recogió: ahora un cristal")
    session.run.spawns.add(session.run.car_cell(), CollectionRun.Mineral.METAL, 5.0)
    session.tick(0.01, Vector2.ZERO)
    check_equal(_goal(), CollectionSession.Goal.COLLECT_CRYSTAL, "el metal no cumple el cristal")
    session.run.spawns.add(session.run.car_cell(), CollectionRun.Mineral.CRYSTAL, 5.0)
    session.tick(0.01, Vector2.ZERO)
    check_equal(_goal(), CollectionSession.Goal.EXIT, "cristal: ahora la salida")
    session.run.car = session.run.exit_rect.get_center()
    session.tick(0.01, Vector2.ZERO)
    check(session.intro == null, "tutorial cumplido")
    check_equal(session.phase(), CollectionSession.Phase.FINISHED, "final")


func test_cave_in_lesson_opens_once_and_closes_when_cleared() -> void:
    check(_cave_in_far() != null, "cae un derrumbe")
    check_equal(_goal(), CollectionSession.Goal.CAVE_IN_CLEARED, "manda la lección del derrumbe")
    session.tick(1.5, Vector2.ZERO)
    check(session.cave_in_lesson == null, "se cierra al despejarse")
    check_equal(_goal(), CollectionSession.Goal.ENTER_MAZE, "vuelve el tutorial inicial")
    check(_cave_in_far() != null, "cae otro")
    check(session.cave_in_lesson == null, "la lección sale una sola vez")


func test_restart_keeps_only_unseen_lessons() -> void:
    session = CollectionSession.new(CollectionRun.new(Vector2(160, 140), CollectionLevel.custom(Vector2i(15, 9), 46.0), 2), false, true)
    check(session.active_lesson() == null, "sin tutorial inicial")
    check(_cave_in_far() != null, "cae un derrumbe")
    check(session.cave_in_lesson != null, "la del derrumbe sigue pendiente")
    var replay: CollectionSession = CollectionSession.new(CollectionRun.new(Vector2(160, 140), CollectionLevel.custom(Vector2i(15, 9), 46.0), 3), false, false)
    session = replay
    check(_cave_in_far() != null, "cae un derrumbe")
    check(replay.active_lesson() == null, "sin lecciones")
