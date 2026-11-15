extends BaseTest
## Capa 4: la temperatura fuera de rango bloquea la fundición de forma continua y el reloj de la fundición termina todo.


var _duo: FoundryDuo
var _run: FoundryRun


func before_each() -> void:
    _duo = FoundryDuo.new(1)
    _duo.temperature.gauge.drift_speed = 0.0    # sin deriva: la aguja la mueve cada prueba
    _run = FoundryRun.new(GameRandom.new(7))
    _duo.bind(_run)


func _put_in_range() -> void:
    var temperature: TemperatureState = _duo.temperature
    temperature.gauge.push((temperature.target_low + temperature.target_high) * 0.5 - temperature.gauge.value)


func _put_out_of_range() -> void:
    _duo.temperature.gauge.push(UnstableGauge.SCALE_MAX)    # todos los rangos acaban antes del máximo


func test_lock_follows_the_range_continuously() -> void:
    _put_out_of_range()
    _duo.step(0.1, 0.0)
    check(_duo.is_locked() and _run.blocked, "fuera de rango, la fundición queda bloqueada")
    _duo.step(0.1, 0.0)
    check(_duo.is_locked(), "y sigue bloqueada mientras no se corrija (no es un evento)")
    _put_in_range()
    _duo.step(0.1, 0.0)
    check(not _duo.is_locked() and not _run.blocked, "al volver al rango, se desbloquea de inmediato")


func test_run_clock_ends_the_temperature_too() -> void:
    _duo.step(0.1, 0.0)
    check(not _duo.temperature.is_over(), "con tiempo, la temperatura sigue")
    check_equal(_duo.temperature.time_left(), ceili(_run.remaining), "la temperatura muestra el tiempo de la fundición")
    _run.tick(FoundryRun.TIME_LIMIT)
    _duo.step(0.1, 1.0)
    check(_duo.is_over() and _duo.temperature.is_over(), "al agotarse el reloj de la fundición, todo termina")
    var frozen: float = _duo.temperature.gauge.value
    _duo.step(0.1, 1.0)
    check_equal(_duo.temperature.gauge.value, frozen, "la temperatura queda congelada")


func test_rebinding_after_restart_links_the_new_run() -> void:
    _put_out_of_range()
    _duo.step(0.1, 0.0)
    var next_run: FoundryRun = FoundryRun.new(GameRandom.new(8))
    _duo.bind(next_run)
    check(next_run.blocked, "la sesión nueva queda enlazada y bloqueada según la aguja")
