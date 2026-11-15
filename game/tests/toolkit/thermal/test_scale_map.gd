extends BaseTest
## Capa 1: la escala por tramos es creciente, interpola dentro de cada tramo y acota fuera de la escala.


func _stepped() -> ScaleMap:
    return ScaleMap.new([0.0, 100.0, 200.0] as Array[float], [0.0, 0.8, 1.0] as Array[float])


func test_passes_through_its_stops_and_interpolates_inside_each_span() -> void:
    var map: ScaleMap = _stepped()
    check_approx(map.fraction(0.0), 0.0, "primer tramo")
    check_approx(map.fraction(100.0), 0.8, "pasa por el segundo punto")
    check_approx(map.fraction(50.0), 0.4, "interpola dentro del primer tramo (ampliado)")
    check_approx(map.fraction(150.0), 0.9, "interpola dentro del segundo tramo (comprimido)")
    check_approx(map.fraction(200.0), 1.0, "último punto")


func test_is_increasing_and_clamped_outside() -> void:
    var map: ScaleMap = _stepped()
    var previous: float = -1.0
    for value: int in range(0, 201, 10):
        var fraction: float = map.fraction(float(value))
        check(fraction >= previous, "crece con el valor (%d)" % value)
        previous = fraction
    check_equal(map.fraction(-50.0), 0.0, "por debajo se acota a 0")
    check_equal(map.fraction(500.0), 1.0, "por encima se acota a 1")
    check_approx(ScaleMap.linear(0.0, 10.0).fraction(5.0), 0.5, "linear() reparte parejo")
