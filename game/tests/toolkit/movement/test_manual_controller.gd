extends BaseTest
## Capa 2 (regla): la dirección inyectada siempre es segura para el cuerpo.


func test_direction_is_limited_to_unit_length_and_non_finite_means_idle() -> void:
    var controller: ManualController = ManualController.new()
    check_equal(controller.desired_direction(Vector2.ZERO, 0.1), Vector2.ZERO, "empieza quieto")
    controller.set_direction(Vector2(0.5, 0))
    check_equal(controller.desired_direction(Vector2.ZERO, 0.1), Vector2(0.5, 0), "una dirección parcial se conserva")
    controller.set_direction(Vector2(10, 0))
    check_approx(controller.desired_direction(Vector2.ZERO, 0.1).length(), 1.0, "pasar de 1 se limita a 1")
    controller.set_direction(Vector2(NAN, 1))
    check_equal(controller.desired_direction(Vector2.ZERO, 0.1), Vector2.ZERO, "una dirección no finita se descarta")
