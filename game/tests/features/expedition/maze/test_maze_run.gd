extends BaseTest
## Capa 3 (minijuego): la batería manda, la precisión cuesta batería y la rampa termina el laberinto.


var _expedition: Expedition
var _run: MazeRun


func before_each() -> void:
    _expedition = Expedition.new(Catalog.new())
    _run = MazeRun.new(_expedition, Vector2(157, 150))


func test_first_vein_is_reachable_and_taken_only_once() -> void:
    var first: MazeRun.Vein = _run.veins[0]
    check(first.is_first and first.res == Catalog.Res.METAL, "la primera veta es la chatarra frente a la entrada")
    for i: int in 120:
        if _run.nearby_vein() != null:
            break
        _run.step(1.0 / 60.0, Vector2.RIGHT)
    check(_run.nearby_vein() == first, "avanzando hacia la entrada se llega a ella")
    check_equal(_run.collect(first, 1.0, false), Catalog.FIRST_VEIN[1], "recogida tal cual da la base")
    check_equal(_expedition.amount(Catalog.Res.METAL), int(Catalog.FIRST_VEIN[1]), "y va a la expedición")
    check(_run.nearby_vein() == null, "una veta tomada no se vuelve a ofrecer")


func test_precision_costs_battery_and_counts_perfect_veins() -> void:
    var vein: MazeRun.Vein = _run.veins[3]
    var battery: float = _run.battery
    var multiplier: float = PrecisionStop.best_multiplier()
    check_equal(_run.collect(vein, multiplier, true), int(float(vein.base) * multiplier), "la mejor nota multiplica la base")
    check_approx(_run.battery, battery - MazeRun.PRECISION_BATTERY_COST, "la precisión cuesta batería")
    check_equal(_expedition.perfect_veins, 1, "cuenta como perfecta")
    check_equal(_run.precision_uses, 1, "y acelera la siguiente")


func test_battery_and_ramp_end_the_level() -> void:
    var end: MazeRun.End = MazeRun.End.NONE
    for i: int in int(Catalog.MAZE_BATTERY * 60.0) + 2:
        end = _run.step(1.0 / 60.0, Vector2.UP)
    check_equal(end, MazeRun.End.BATTERY, "la batería se agota")
    var fresh: MazeRun = MazeRun.new(_expedition, Vector2(157, 150))
    fresh.car = fresh.exit_rect.get_center() - Vector2(40, 0)
    for i: int in 60:
        end = fresh.step(1.0 / 60.0, Vector2.RIGHT)
    check_equal(end, MazeRun.End.EXIT, "llegar a la rampa termina el laberinto")
