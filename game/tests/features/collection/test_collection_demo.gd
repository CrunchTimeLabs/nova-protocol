extends BaseTest
## Capa 3 (entidad): cada demostración del tutorial es determinista y enseña lo que dice.


const MAX_SECONDS := 30.0
const DT := 1.0 / 60.0


func _play(scene: CollectionDemo.Scene) -> CollectionDemo:
    var demo: CollectionDemo = CollectionDemo.new(scene)
    var t: float = 0.0
    while t < MAX_SECONDS and not demo.step(DT):
        t += DT
    check(t < MAX_SECONDS, "escena %d termina" % scene)
    return demo


func test_drive_and_collect_takes_both() -> void:
    var demo: CollectionDemo = _play(CollectionDemo.Scene.DRIVE_AND_COLLECT)
    check_equal(demo.run.tally.total(), 35, "recoge metal y cristal")


func test_vanish_gets_away() -> void:
    var demo: CollectionDemo = _play(CollectionDemo.Scene.VANISH)
    check_equal(demo.run.tally.total(), 0, "no llega a tiempo")
    check(demo.run.spawns.items.is_empty(), "se esfumó")


func test_cave_in_then_exit() -> void:
    var demo: CollectionDemo = CollectionDemo.new(CollectionDemo.Scene.CAVE_IN)
    var seen: Array[int] = [0]
    demo.run.cave_in_started.connect(func(_c: MazeCaveIns.CaveIn) -> void: seen[0] += 1)
    var t: float = 0.0
    while t < MAX_SECONDS and not demo.step(DT):
        t += DT
    check_equal(seen[0], 1, "cae un derrumbe")
    check(demo.run.is_finished, "aun así llega a la salida")


func test_exit() -> void:
    check(_play(CollectionDemo.Scene.EXIT).run.is_finished, "llega a la rampa")
