extends BaseTest
## Capa 2 (regla): la ruta se recorre en orden y termina.


func test_visits_points_in_order_then_finishes_idle() -> void:
    var points: Array[Vector2] = [Vector2(100, 0), Vector2(100, 100)]
    var controller: WaypointController = WaypointController.new(points, 5.0)
    var reached: Array[int] = []
    controller.waypoint_reached.connect(func(index: int) -> void: reached.append(index))
    check_equal(controller.desired_direction(Vector2.ZERO, 0.1), Vector2(1, 0), "apunta al primer punto")
    check_equal(controller.desired_direction(Vector2(100, 0), 0.1), Vector2(0, 1), "al llegar al primero apunta al segundo")
    check(not controller.is_finished(), "falta el último punto")
    check_equal(controller.desired_direction(Vector2(100, 99), 0.1), Vector2.ZERO, "en el último punto se queda quieto")
    check(controller.is_finished(), "ruta terminada")
    check_equal(reached, [0, 1], "la señal sale una vez por punto, en orden")


func test_points_already_inside_the_radius_are_consumed_in_one_call_and_empty_route_is_finished() -> void:
    var points: Array[Vector2] = [Vector2(1, 0), Vector2(2, 0), Vector2(100, 0)]
    var controller: WaypointController = WaypointController.new(points, 5.0)
    var reached: Array[int] = []
    controller.waypoint_reached.connect(func(index: int) -> void: reached.append(index))
    controller.desired_direction(Vector2.ZERO, 0.1)
    check_equal(reached, [0, 1], "los dos primeros se consumen en la misma llamada")
    var empty: Array[Vector2] = []
    var idle: WaypointController = WaypointController.new(empty)
    check(idle.is_finished() and idle.desired_direction(Vector2.ZERO, 0.1) == Vector2.ZERO, "sin puntos no hay nada que hacer")
