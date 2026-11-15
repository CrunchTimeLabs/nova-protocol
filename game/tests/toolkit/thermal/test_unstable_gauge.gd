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


func test_scale_maximum_is_configurable() -> void:
    var wide: UnstableGauge = UnstableGauge.new(2, 900.0, 1800.0)
    wide.push(1.0e6)
    check_equal(wide.value, 1800.0, "el máximo configurado acota el impulso")
    for _i: int in range(100):
        wide.step(0.1)
        check(wide.value <= 1800.0 and wide.value >= UnstableGauge.SCALE_MIN, "la deriva respeta la escala configurada")


func test_pushing_dampens_the_drift_so_the_player_is_not_held_back() -> void:
    var free: UnstableGauge = UnstableGauge.new(3, 900.0, 1800.0)
    var damped: UnstableGauge = UnstableGauge.new(3, 900.0, 1800.0)
    damped.push_damping = 0.25
    free.step(0.1, true)
    damped.step(0.1, true)
    var free_move: float = absf(free.value - 900.0)
    var damped_move: float = absf(damped.value - 900.0)
    check_approx(damped_move, free_move * 0.25, "empujando, la deriva queda en la fracción pedida")
    var idle_free: UnstableGauge = UnstableGauge.new(3, 900.0, 1800.0)
    var idle_damped: UnstableGauge = UnstableGauge.new(3, 900.0, 1800.0)
    idle_damped.push_damping = 0.25
    idle_free.step(0.1)
    idle_damped.step(0.1)
    check_equal(idle_damped.value, idle_free.value, "sin empujar no cambia nada")


func test_smooth_wander_changes_speed_gradually() -> void:
    var gauge: UnstableGauge = UnstableGauge.new(5, 900.0, 1800.0)
    gauge.wander_response = 2.0
    gauge.drift_speed = 100.0
    var delta: float = 0.05
    var previous_value: float = gauge.value
    var previous_step: float = 0.0
    var largest_jump: float = 0.0
    for _i: int in range(400):
        gauge.step(delta)
        var current_step: float = gauge.value - previous_value
        largest_jump = maxf(largest_jump, absf(current_step - previous_step))
        previous_value = gauge.value
        previous_step = current_step
    check(largest_jump < 0.5 * gauge.drift_speed * delta, "la velocidad de la deriva no salta de golpe")
