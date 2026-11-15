extends BaseTest
## Capa 4: la temperatura apunta al punto de fusión del objetivo más urgente, bloquea fuera de rango, acelera al
## mantener la tecla y la práctica del tutorial mueve la aguja de verdad.


func test_target_is_the_melting_point_and_lock_follows_range() -> void:
    var run: SmelterRun = SmelterRun.new(GameRandom.new(5), {Ores.Ore.ILMENITE: 5})
    var duo: SmelterDuo = SmelterDuo.new(run, 1)
    duo.temperature.gauge.drift_speed = 0.0
    run.start()
    for i: int in 200:
        run.tick(0.05)
        duo.step(0.05, 0.0)
        if not run.active.is_empty():
            break
    check_approx(duo.temperature.target_low, float(Ores.MELTING_POINTS[Ores.Ore.ILMENITE]) - SmelterDuo.TARGET_HALF_WIDTH, "rango del titanio")
    check(run.blocked, "la aguja empieza lejos: bloquea")
    duo.temperature.gauge.push(float(Ores.MELTING_POINTS[Ores.Ore.ILMENITE]) - duo.temperature.gauge.value)
    duo.step(0.01, 0.0)
    check(not run.blocked, "en rango, desbloquea")


func test_holding_the_key_speeds_up() -> void:
    check(SmelterDuo.rate_after(0.0) < SmelterDuo.rate_after(SmelterDuo.RAMP_TIME), "mantener acelera")
    check(SmelterDuo.rate_after(SmelterDuo.RAMP_TIME) * 2.0 >= 1000.0, "cruza la escala en ~2 s")
    check_approx(SmelterDuo.rate_after(10.0), SmelterDuo.RATE_FULL, "con tope")


func test_practice_moves_the_needle_before_the_start() -> void:
    var run: SmelterRun = SmelterRun.new(GameRandom.new(5), {})
    var duo: SmelterDuo = SmelterDuo.new(run, 1)
    duo.temperature.gauge.drift_speed = 0.0
    var before: float = duo.temperature.gauge.value
    for i: int in 20:
        duo.practice(0.05, -1.0)
    check(duo.temperature.gauge.value < before - 50.0, "la práctica baja la aguja")
    check(duo.temperature.has_target, "con su zona de práctica")
    duo.step(0.5, 1.0)
    check(not run.is_started, "step no arranca nada")
