extends BaseTest
## Capa 3 (entidad): orden, tiempos y señales del semáforo de tres luces.


var _traffic_light: TrafficLight


func before_each() -> void:
    _traffic_light = TrafficLight.new()


func test_starts_red_without_elapsed_time() -> void:
    check(_traffic_light.current() == TrafficLight.Light.RED, "arranca en rojo")
    check_approx(_traffic_light.elapsed(), 0.0, "arranca sin tiempo acumulado")


func test_does_not_change_before_three_seconds() -> void:
    _traffic_light.tick(2.999)
    check(_traffic_light.current() == TrafficLight.Light.RED, "aún no cambia antes de 3 s")
    check_approx(_traffic_light.elapsed(), 2.999, "acumula el tiempo parcial")


func test_changes_every_three_seconds_in_order() -> void:
    var expected: Array[TrafficLight.Light] = [
        TrafficLight.Light.YELLOW,
        TrafficLight.Light.GREEN,
        TrafficLight.Light.RED,
    ]
    for light: TrafficLight.Light in expected:
        _traffic_light.tick(3.0)
        check(_traffic_light.current() == light, "tras 3 s debe estar en la luz %d" % int(light))


func test_emits_previous_and_current_light() -> void:
    var changes: Array[Vector2i] = []
    _traffic_light.light_changed.connect(func(previous: TrafficLight.Light, current: TrafficLight.Light) -> void: changes.append(Vector2i(previous, current)))
    _traffic_light.tick(3.0)
    var expected: Array[Vector2i] = [Vector2i(TrafficLight.Light.RED, TrafficLight.Light.YELLOW)]
    check_equal(changes, expected, "emite la luz anterior y la nueva")


func test_large_delta_emits_one_change_per_step() -> void:
    var changes: Array[int] = [0]
    _traffic_light.light_changed.connect(func(_previous: TrafficLight.Light, _current: TrafficLight.Light) -> void: changes[0] += 1)
    _traffic_light.tick(6.0)
    check(_traffic_light.current() == TrafficLight.Light.GREEN, "6 s desde rojo llega a verde")
    check_equal(changes[0], 2, "emite un cambio por cada paso completado")
    check_approx(_traffic_light.elapsed(), 0.0, "sin resto justo en el límite")


func test_ignores_non_positive_delta() -> void:
    _traffic_light.tick(0.0)
    _traffic_light.tick(-3.0)
    check(_traffic_light.current() == TrafficLight.Light.RED, "un delta no positivo no cambia la luz")
    check_approx(_traffic_light.elapsed(), 0.0, "un delta no positivo no acumula tiempo")


func test_reset_returns_to_red_and_notifies_change() -> void:
    var changes: Array[int] = [0]
    _traffic_light.light_changed.connect(func(_previous: TrafficLight.Light, _current: TrafficLight.Light) -> void: changes[0] += 1)
    _traffic_light.tick(3.0)
    _traffic_light.reset()
    check(_traffic_light.current() == TrafficLight.Light.RED, "reset vuelve a rojo")
    check_approx(_traffic_light.elapsed(), 0.0, "reset borra el tiempo acumulado")
    check_equal(changes[0], 2, "reset avisa del cambio a rojo")
