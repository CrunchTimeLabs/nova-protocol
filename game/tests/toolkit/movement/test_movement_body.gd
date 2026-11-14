extends BaseTest
## Capa 3 (entidad): la aceleración, el frenado y el relevo de controlador con un perfil configurable.


class FixedController extends MovementController:
    var direction: Vector2

    func _init(p_direction: Vector2) -> void:
        direction = p_direction

    func desired_direction(_position: Vector2, _delta: float) -> Vector2:
        return direction


const MAX_SPEED := 100.0

var _input: ManualController
var _body: MovementBody


func before_each() -> void:
    _input = ManualController.new()
    _body = MovementBody.new(_input, MovementProfile.new(MAX_SPEED, 1.0, 0.5, 2.0))


func _run(body: MovementBody, seconds: float, steps: int) -> void:
    for i: int in steps:
        body.step(seconds / steps)


func test_accelerates_to_max_speed_in_accel_time_and_never_beyond() -> void:
    _input.set_direction(Vector2.RIGHT)
    _run(_body, 0.5, 1)
    check_approx(_body.velocity.x, 50.0, "a mitad del tiempo, mitad de velocidad")
    _run(_body, 0.5, 1)
    check_approx(_body.velocity.x, MAX_SPEED, "tras accel_time alcanza la velocidad máxima")
    _run(_body, 5.0, 5)
    check_approx(_body.velocity.x, MAX_SPEED, "seguir empujando no la supera")


func test_brakes_to_a_stop_in_decel_time_without_reversing() -> void:
    _input.set_direction(Vector2.RIGHT)
    _run(_body, 1.0, 1)
    _input.set_direction(Vector2.ZERO)
    _run(_body, 0.25, 1)
    check_approx(_body.velocity.x, 50.0, "a mitad del tiempo de frenado, mitad de velocidad")
    _run(_body, 1.0, 4)
    check_equal(_body.velocity, Vector2.ZERO, "frenado completo y sin pasar a negativo")


func test_reversing_uses_turn_response_and_instant_profile_responds_in_one_step() -> void:
    _input.set_direction(Vector2.RIGHT)
    _run(_body, 1.0, 1)
    _input.set_direction(Vector2.LEFT)
    _run(_body, 0.5, 1)
    check_approx(_body.velocity.x, 0.0, "con turn_response 2 invertir va el doble de rápido que arrancar")
    var instant: MovementBody = MovementBody.new(_input, MovementProfile.new(MAX_SPEED, 0.0, 0.0))
    instant.step(0.016)
    check_approx(instant.velocity.x, -MAX_SPEED, "tiempos 0: respuesta inmediata")


func test_swapping_profile_changes_later_steps_and_swapping_controller_keeps_velocity() -> void:
    _input.set_direction(Vector2.RIGHT)
    _run(_body, 1.0, 1)
    _body.set_profile(MovementProfile.new(MAX_SPEED, 1.0, 4.0))
    _input.set_direction(Vector2.ZERO)
    _run(_body, 1.0, 1)
    check_approx(_body.velocity.x, 75.0, "con decel_time 4 frenar 1 s quita solo un cuarto")
    _body.set_controller(FixedController.new(Vector2.RIGHT))
    check_approx(_body.velocity.x, 75.0, "cambiar de controlador no toca la velocidad")


func test_controller_output_is_sanitized() -> void:
    _body.set_controller(FixedController.new(Vector2(50, 0)))
    _run(_body, 5.0, 5)
    check_approx(_body.velocity.length(), MAX_SPEED, "una dirección enorme se limita a la velocidad máxima")
    _body.set_controller(FixedController.new(Vector2(NAN, NAN)))
    _run(_body, 5.0, 5)
    check_equal(_body.velocity, Vector2.ZERO, "una dirección no finita cuenta como quieto")


func test_invalid_delta_is_rejected_without_changing_state() -> void:
    _input.set_direction(Vector2.RIGHT)
    _run(_body, 0.5, 1)
    var before: Dictionary = _body.snapshot()
    for bad_delta: float in [0.0, -0.1, NAN, INF]:
        check(not _body.step(bad_delta), "delta %s se rechaza" % str(bad_delta))
    check_equal(_body.snapshot(), before, "el estado no cambia")


func test_velocity_is_independent_of_step_size_and_runs_are_deterministic() -> void:
    var coarse: MovementBody = MovementBody.new(_input, _body.profile)
    var fine: MovementBody = MovementBody.new(_input, _body.profile)
    _input.set_direction(Vector2(1, 1))
    _run(coarse, 0.6, 1)
    _run(fine, 0.6, 60)
    check(coarse.velocity.is_equal_approx(fine.velocity), "un paso grande o muchos pequeños dan la misma velocidad")
    var twin: MovementBody = MovementBody.new(_input, _body.profile)
    _run(twin, 0.6, 60)
    check_equal(twin.snapshot(), fine.snapshot(), "misma secuencia, mismo estado exacto")


func test_follows_a_waypoint_route_to_the_end() -> void:
    var points: Array[Vector2] = [Vector2(100, 0), Vector2(100, 100)]
    var route: WaypointController = WaypointController.new(points, 5.0)
    var reached: Array[int] = []
    route.waypoint_reached.connect(func(index: int) -> void: reached.append(index))
    var body: MovementBody = MovementBody.new(route, MovementProfile.snappy())
    var steps: int = 0
    while not route.is_finished() and steps < 600:
        body.step(1.0 / 60.0)
        steps += 1
    check(route.is_finished(), "completa la ruta")
    check_equal(reached, [0, 1], "pasa por los puntos en orden")
    _run(body, 1.0, 60)
    check_equal(body.velocity, Vector2.ZERO, "al terminar la ruta se detiene")
    check(body.position.distance_to(points[1]) <= 15.0, "queda cerca del destino")


func test_confine_keeps_the_body_inside_and_stops_that_axis() -> void:
    var area: Rect2 = Rect2(Vector2.ZERO, Vector2(10, 10))
    _input.set_direction(Vector2(1, 0.5))
    _run(_body, 2.0, 20)
    _body.confine(area)
    check(area.grow(0.001).has_point(_body.position), "el cuerpo no sale del área (borde incluido)")
    check_equal(_body.position.x, 10.0, "queda en el borde derecho")
    check_equal(_body.velocity.x, 0.0, "la componente que choca se anula")


func test_snapshot_survives_json_round_trip() -> void:
    _input.set_direction(Vector2(1, 0.5))
    _run(_body, 0.7, 7)
    var restored: MovementBody = MovementBody.new(_input, _body.profile)
    restored.restore(JSON.parse_string(JSON.stringify(_body.snapshot())) as Dictionary)
    check_equal(restored.snapshot(), _body.snapshot(), "posición y velocidad vuelven idénticas")
