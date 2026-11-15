extends BaseTest
## Capa 1: la aguja deriva al azar (con semilla), cambia de dirección solo por intervalos, no sale de la escala y obedece al jugador.


func test_same_seed_gives_same_path() -> void:
    var paths: Array[Array] = []
    for _run: int in range(2):
        var gauge: UnstableGauge = UnstableGauge.new(9)
        var path: Array = []
        for _i: int in range(120):
            gauge.step(0.1)
            path.append(gauge.value)
        paths.append(path)
    check_equal(paths[0], paths[1], "misma semilla, misma trayectoria")


func test_direction_changes_only_once_per_interval() -> void:
    var gauge: UnstableGauge = UnstableGauge.new(4)
    var changes: int = 0
    var previous: float = gauge.direction
    for _i: int in range(40):    # 4 s en pasos de 0.1 s
        gauge.step(0.1)
        if gauge.direction != previous:
            changes += 1
        previous = gauge.direction
    check(changes <= int(4.0 / UnstableGauge.CHANGE_INTERVAL), "como mucho un cambio por intervalo")


func test_never_leaves_the_scale_and_push_moves_it() -> void:
    var gauge: UnstableGauge = UnstableGauge.new(2)
    gauge.push(1.0e6)
    check_equal(gauge.value, UnstableGauge.SCALE_MAX, "el impulso se acota al máximo")
    gauge.push(-1.0e6)
    check_equal(gauge.value, UnstableGauge.SCALE_MIN, "y al mínimo")
    for _i: int in range(600):
        gauge.step(0.1)
        check(gauge.value >= UnstableGauge.SCALE_MIN and gauge.value <= UnstableGauge.SCALE_MAX, "la deriva no sale de la escala")
    var calm: UnstableGauge = UnstableGauge.new(2, 300.0)
    calm.push(25.0)
    check_equal(calm.value, 325.0, "push suma")
