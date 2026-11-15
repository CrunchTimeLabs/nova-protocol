extends BaseTest
## Capa 1 (elemento): como mucho un suceso por ventana, en un momento al azar, con la probabilidad dada.


func test_at_most_one_per_window_and_about_the_chance() -> void:
    var clock: ChanceWindow = ChanceWindow.new(GameRandom.new(3), 120.0, 0.65)
    var fired: int = 0
    var windows: int = 400
    for w: int in windows:
        var in_window: int = 0
        for i: int in 120:
            in_window += clock.tick(1.0)
        check(in_window <= 1, "ventana %d: como mucho uno" % w)
        fired += in_window
    var ratio: float = float(fired) / float(windows)
    check(ratio > 0.58 and ratio < 0.72, "cerca del 65 %% (%.2f)" % ratio)


func test_event_lands_anywhere_inside_the_window() -> void:
    var early: int = 0
    var late: int = 0
    for seed_value: int in range(1, 200):
        var clock: ChanceWindow = ChanceWindow.new(GameRandom.new(seed_value), 120.0, 1.0)
        var at: float = clock.time_to_event()
        check(at >= 0.0 and at < 120.0, "dentro de la ventana")
        if at < 60.0:
            early += 1
        else:
            late += 1
    check(early > 50 and late > 50, "reparto a lo largo de la ventana (%d / %d)" % [early, late])


func test_big_delta_and_determinism() -> void:
    var first: ChanceWindow = ChanceWindow.new(GameRandom.new(8), 10.0, 0.65)
    var second: ChanceWindow = ChanceWindow.new(GameRandom.new(8), 10.0, 0.65)
    var by_steps: int = 0
    for i: int in 1000:
        by_steps += first.tick(0.1)
    check_equal(second.tick(100.0), by_steps, "un delta grande da lo mismo que pasos pequeños")
    check(by_steps <= 10, "como mucho uno por ventana")
