extends BaseTest
## Capa 4: estabilizar dentro del rango suma un acierto; fuera solo avisa y congela el progreso; la partida dura 20 s.


var _state: TemperatureState


func before_each() -> void:
    _state = TemperatureState.new(1)
    _state.gauge.drift_speed = 0.0    # sin deriva: el movimiento de la aguja lo decide cada prueba


func _put_in_range() -> void:
    _state.gauge.push((_state.target_low + _state.target_high) * 0.5 - _state.gauge.value)


func _put_out_of_range() -> void:
    _state.gauge.push(UnstableGauge.SCALE_MAX)    # los rangos acaban todos antes del máximo


func test_holding_in_range_stabilizes_once() -> void:
    _put_in_range()
    for _i: int in range(int(TemperatureState.HOLD_SECONDS)):
        _state.step(1.0, 0.0)
    check_equal(_state.hits, 1, "mantenerse en el rango suma un acierto")
    check_equal(_state.progress.current, 0.0, "el progreso se reinicia con el objetivo nuevo")


func test_out_of_range_freezes_progress_and_only_alerts() -> void:
    var alerts: Array[String] = []
    _state.alert_raised.connect(func(message: String) -> void: alerts.append(message))
    _put_in_range()
    _state.step(1.0, 0.0)
    var held: float = _state.progress.current
    _put_out_of_range()
    _state.step(1.0, 0.0)
    check_approx(_state.progress.current, held, "fuera del rango el progreso se congela")
    check_equal(alerts.size(), 1, "avisa al salir")
    _state.step(1.0, 0.0)
    check_equal(alerts.size(), 1, "no repite antes del intervalo")
    _state.step(TemperatureState.ALERT_INTERVAL - 1.0, 0.0)
    check_equal(alerts.size(), 2, "repite cada intervalo hasta corregir")
    _put_in_range()
    _state.step(1.0, 0.0)
    check(_state.progress.current > held, "al volver al rango continúa")
    check_equal(alerts.size(), 2, "dentro del rango no avisa")


func test_new_target_resets_progress() -> void:
    _put_in_range()
    _state.step(1.0, 0.0)
    check(_state.progress.current > 0.0, "hay progreso")
    _state.targets.announce_now()
    check_equal(_state.progress.current, 0.0, "un objetivo nuevo lo reinicia")


func test_match_ends_after_twenty_seconds_and_stops() -> void:
    _state.step(float(TemperatureState.MATCH_SECONDS), 0.0)
    check(_state.is_over(), "termina a los 20 s")
    var value_then: float = _state.gauge.value
    _state.step(1.0, 1.0)
    check_equal(_state.gauge.value, value_then, "terminada, ya nada cambia")
