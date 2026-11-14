extends BaseTest
## Capa 1 (elemento): la atracción apunta al centro, cae con el cuadrado de la distancia y no explota en el centro.


func test_points_to_center_and_falls_with_inverse_square() -> void:
    var gravity: CentralGravity = CentralGravity.new(Vector2.ZERO, 1.0, 0.0)
    check_approx(gravity.acceleration_at(Vector2(0.1, 0), Vector2.ZERO).x, -100.0, "gm/r² hacia el centro")
    check_approx(gravity.acceleration_at(Vector2(0.2, 0), Vector2.ZERO).x, -25.0, "al doble de distancia, un cuarto")
    check_equal(gravity.acceleration_at(Vector2(0, 0.1), Vector2.ZERO).normalized(), Vector2(0, -1), "la dirección es hacia el centro")


func test_softening_keeps_acceleration_finite_at_the_center() -> void:
    var gravity: CentralGravity = CentralGravity.new(Vector2.ZERO, 1.0)
    check(gravity.acceleration_at(Vector2.ZERO, Vector2.ZERO).is_zero_approx(), "en el centro exacto no hay aceleración")
    check(gravity.acceleration_at(Vector2(0.00001, 0), Vector2.ZERO).is_finite(), "muy cerca del centro sigue finita")
