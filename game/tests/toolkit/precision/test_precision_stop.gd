extends BaseTest
## Capa 3 (minijuego): la nota y el multiplicador salen de la distancia al centro y mejoran hacia él.


func test_grade_and_multiplier_follow_the_zone_table() -> void:
    var cases: Array = [
        [0.0, PrecisionStop.Grade.PERFECT, 3.0],
        [0.05, PrecisionStop.Grade.PERFECT, 3.0],
        [0.1, PrecisionStop.Grade.VERY_GOOD, 2.2],
        [0.25, PrecisionStop.Grade.ACCEPTABLE, 1.6],
        [0.4, PrecisionStop.Grade.POOR, 1.1],
        [0.9, PrecisionStop.Grade.FAILED, 0.7],
    ]
    for row: Array in cases:
        var grade: PrecisionStop.Grade = PrecisionStop.grade_for(float(row[0]))
        check_equal(grade, row[1], "nota a distancia %s" % str(row[0]))
        check_approx(PrecisionStop.multiplier_for(grade), float(row[2]), "multiplicador a distancia %s" % str(row[0]))


func test_stop_freezes_the_mark_and_finishes_after_the_hold() -> void:
    var stop: PrecisionStop = PrecisionStop.new(0)
    stop.advance(0.4)
    stop.stop()
    var frozen: float = stop.position()
    stop.advance(0.5)
    check_approx(stop.position(), frozen, "una vez detenida, la marca no se mueve")
    check(not stop.is_finished(), "no termina antes del tiempo de resultado")
    stop.advance(PrecisionStop.RESULT_HOLD)
    check(stop.is_finished(), "termina tras mostrar el resultado")


func test_each_previous_use_makes_it_faster() -> void:
    check(PrecisionStop.new(3).speed > PrecisionStop.new(0).speed, "más usos, más velocidad")
