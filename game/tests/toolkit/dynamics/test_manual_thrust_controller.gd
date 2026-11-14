extends BaseTest
## Capa 2 (regla): la orden inyectada siempre es segura para el motor.


func test_command_is_limited_to_unit_length_and_non_finite_means_off() -> void:
    var controller: ManualThrustController = ManualThrustController.new()
    check_equal(controller.thrust_command(Vector2.ZERO, Vector2.ZERO, 0.1), Vector2.ZERO, "empieza apagado")
    controller.set_command(Vector2(0.5, 0))
    check_equal(controller.thrust_command(Vector2.ZERO, Vector2.ZERO, 0.1), Vector2(0.5, 0), "una orden parcial se conserva")
    controller.set_command(Vector2(10, 0))
    check_approx(controller.thrust_command(Vector2.ZERO, Vector2.ZERO, 0.1).length(), 1.0, "pasar de 1 se limita a 1")
    controller.set_command(Vector2(NAN, 1))
    check_equal(controller.thrust_command(Vector2.ZERO, Vector2.ZERO, 0.1), Vector2.ZERO, "una orden no finita se descarta")
