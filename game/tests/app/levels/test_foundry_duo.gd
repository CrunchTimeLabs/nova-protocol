extends BaseTest
## Capa 4: la fundición manda a la temperatura el punto de fusión del mineral disponible, la temperatura fuera de rango
## la bloquea de forma continua y el reloj de la fundición termina todo.


var _duo: FoundryDuo
var _run: FoundryRun


func before_each() -> void:
    _duo = FoundryDuo.new(1)
    _duo.temperature.gauge.drift_speed = 0.0    # sin deriva: la aguja la mueve cada prueba
    _run = FoundryRun.new(GameRandom.new(7))
    _duo.bind(_run)


## Avanza la fundición hasta que haya minerales en el centro.
func _wait_for_targets() -> void:
    for _i: int in range(400):
        if not _run.active.is_empty():
            return
        _run.tick(0.05)


func _urgent() -> FoundryRun.Spawn:
    var urgent: FoundryRun.Spawn = _run.active[0]
    for spawn: FoundryRun.Spawn in _run.active:
        if spawn.remaining < urgent.remaining:
            urgent = spawn
    return urgent


func _put_in_range() -> void:
    var temperature: TemperatureState = _duo.temperature
    temperature.gauge.push((temperature.target_low + temperature.target_high) * 0.5 - temperature.gauge.value)


func _put_out_of_range() -> void:
    _duo.temperature.gauge.push(1.0e6)    # la escala acaba en 1800, por encima de todos los rangos


func test_available_mineral_sets_its_melting_point_as_target() -> void:
    check(not _duo.temperature.has_target, "sin minerales no hay objetivo")
    _wait_for_targets()
    var point: float = float(FoundryDuo.MELTING_POINTS[_urgent().mineral])
    check_approx(_duo.temperature.target_low, point - FoundryDuo.TARGET_HALF_WIDTH, "el rango empieza en su punto de fusión menos el semiancho")
    check_approx(_duo.temperature.target_high, point + FoundryDuo.TARGET_HALF_WIDTH, "y acaba en el punto más el semiancho")
    check(_duo.temperature.message.begins_with(String(FoundryRun.NAMES[_urgent().mineral])), "el mensaje nombra el elemento")


func test_most_urgent_mineral_leads_and_next_takes_over() -> void:
    for _i: int in range(40):
        _run = FoundryRun.new(GameRandom.new(10 + _i))
        _duo.bind(_run)
        _wait_for_targets()
        if _run.active.size() == 2 and _run.active[0].mineral != _run.active[1].mineral:
            break
    check_equal(_run.active.size(), 2, "hay dos minerales distintos en el centro")
    var first: FoundryRun.Spawn = _urgent()
    var second: FoundryRun.Spawn = _run.active[0] if _run.active[0] != first else _run.active[1]
    check_approx(_duo.temperature.target_low, float(FoundryDuo.MELTING_POINTS[first.mineral]) - FoundryDuo.TARGET_HALF_WIDTH, "manda el más urgente")
    _run.active.erase(first)
    _run.collected.emit(first)
    check_approx(_duo.temperature.target_low, float(FoundryDuo.MELTING_POINTS[second.mineral]) - FoundryDuo.TARGET_HALF_WIDTH, "al salir el primero, pasa al siguiente")


func test_lock_follows_the_range_continuously_and_only_with_something_to_collect() -> void:
    _wait_for_targets()
    _put_out_of_range()
    _duo.step(0.1, 0.0)
    check(_duo.is_locked() and _run.blocked, "fuera de rango, la fundición queda bloqueada")
    _duo.step(0.1, 0.0)
    check(_duo.is_locked(), "y sigue bloqueada mientras no se corrija (no es un evento)")
    _put_in_range()
    _duo.step(0.1, 0.0)
    check(not _duo.is_locked(), "al volver al rango, se desbloquea de inmediato")
    _put_out_of_range()
    _run.active.clear()
    _duo.step(0.1, 0.0)
    check(not _duo.is_locked(), "sin minerales que recoger no bloquea y se conserva el último rango")
    check(_duo.temperature.has_target, "el último objetivo sigue ahí")


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
    _wait_for_targets()
    _put_out_of_range()
    _duo.step(0.1, 0.0)
    var next_run: FoundryRun = FoundryRun.new(GameRandom.new(8))
    _duo.bind(next_run)
    for _i: int in range(400):
        if not next_run.active.is_empty():
            break
        next_run.tick(0.05)
    check(not next_run.active.is_empty() and next_run.blocked, "la sesión nueva queda enlazada y bloqueada según la aguja")


func test_needs_min_hits_collected_to_pass() -> void:
    for hit: int in range(FoundryDuo.MIN_HITS):
        check(not _duo.has_passed(), "con %d aciertos aún no pasa" % hit)
        _wait_for_targets()
        var spawn: FoundryRun.Spawn = _urgent()
        var point: float = float(FoundryDuo.MELTING_POINTS[spawn.mineral])
        _duo.temperature.gauge.push(point - _duo.temperature.gauge.value)
        _duo.step(0.0, 0.0)
        check(_run.collect(String(FoundryRun.NAMES[spawn.mineral])), "se recoge con la aguja en rango")
    check_equal(_duo.hits, FoundryDuo.MIN_HITS, "cuenta los minerales recogidos")
    check(_duo.has_passed(), "con el mínimo de aciertos pasa")
