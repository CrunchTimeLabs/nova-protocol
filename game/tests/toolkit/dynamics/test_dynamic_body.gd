extends BaseTest
## Capa 3 (entidad): el cuerpo integra empuje y fuentes; sin fuerzas conserva la velocidad y una órbita se sostiene.

const ORBIT_RADIUS: float = 0.25
const ORBIT_GM: float = 0.01
const ORBIT_SPEED: float = 0.2


var _controller: ManualThrustController


func before_each() -> void:
    _controller = ManualThrustController.new()


func test_without_forces_velocity_is_conserved() -> void:
    var body: DynamicBody = DynamicBody.new(
            _controller,
            ThrustEngine.new(50.0),
            [],
            Vector2.ZERO,
            Vector2(0.1, 0.05),
            )
    for _i: int in range(60):
        body.step(1.0 / 60.0)
    check_equal(body.velocity, Vector2(0.1, 0.05), "soltar el empuje no frena")
    check(body.position.distance_to(Vector2(0.1, 0.05)) < 0.0001, "la posición avanza con la velocidad constante")


func test_thrust_and_uniform_sources_add_up() -> void:
    var sources: Array[AccelerationSource] = [UniformAcceleration.new(Vector2(0, 0.01))]
    var body: DynamicBody = DynamicBody.new(_controller, ThrustEngine.new(0.05), sources)
    _controller.set_command(Vector2(1, 0))
    for _i: int in range(60):
        body.step(1.0 / 60.0)
    check(body.velocity.distance_to(Vector2(0.05, 0.01)) < 0.0001, "en 1 s: empuje en x y gravedad en y (%s)" % str(body.velocity))


func test_orbit_holds_radius_and_does_not_depend_on_frame_rate() -> void:
    var period: float = TAU * ORBIT_RADIUS / ORBIT_SPEED
    var finals: Array[Vector2] = []
    for frame_delta: float in [1.0 / 60.0, 1.0 / 30.0]:
        var body: DynamicBody = _orbiting_body()
        var worst_radius_error: float = 0.0
        var elapsed: float = 0.0
        while elapsed < period:
            body.step(frame_delta)
            elapsed += frame_delta
            worst_radius_error = maxf(worst_radius_error, absf(body.position.length() - ORBIT_RADIUS))
        check(worst_radius_error < ORBIT_RADIUS * 0.01, "la órbita circular mantiene el radio (error %s)" % str(worst_radius_error))
        finals.append(body.position)
    check(finals[0].distance_to(finals[1]) < 0.005, "con otros fps termina en el mismo sitio")


func test_pilot_thrust_changes_the_orbit() -> void:
    var body: DynamicBody = _orbiting_body(ThrustEngine.new(0.05))
    _controller.set_command(Vector2(0, 1))
    for _i: int in range(60):
        body.step(1.0 / 60.0)
    _controller.set_command(Vector2.ZERO)
    var apoapsis: float = 0.0
    for _i: int in range(60 * 15):
        body.step(1.0 / 60.0)
        apoapsis = maxf(apoapsis, body.position.length())
    check(apoapsis > ORBIT_RADIUS * 1.1, "empujar en el sentido del movimiento eleva el apoastro (%s)" % str(apoapsis))


func test_invalid_delta_is_rejected_and_snapshot_survives_json() -> void:
    var body: DynamicBody = _orbiting_body()
    body.step(0.5)
    var before: Dictionary = body.snapshot()
    check(not body.step(-1.0) and not body.step(NAN), "delta inválido se rechaza")
    check_equal(body.snapshot(), before, "un delta inválido no cambia nada")
    var restored: DynamicBody = _orbiting_body()
    restored.restore(JSON.parse_string(JSON.stringify(before)))
    check_equal(restored.snapshot(), before, "el viaje por JSON conserva el estado")


func test_snapshot_keeps_fuel_through_json() -> void:
    var fuel: ResourceMeter = ResourceMeter.new(1.0, 1.0)
    var body: DynamicBody = _orbiting_body(ThrustEngine.new(0.05, fuel, 0.5))
    _controller.set_command(Vector2(0, 1))
    for _i: int in range(60):
        body.step(1.0 / 60.0)
    var saved: Dictionary = JSON.parse_string(JSON.stringify(body.snapshot()))
    var other_fuel: ResourceMeter = ResourceMeter.new(1.0, 1.0)
    var other: DynamicBody = _orbiting_body(ThrustEngine.new(0.05, other_fuel, 0.5))
    other.restore(saved)
    check(fuel.current < 1.0, "el cuerpo gastó combustible")
    check_approx(other_fuel.current, fuel.current, "el combustible viaja en la instantánea")
    for key: String in ["x", "y", "vx", "vy", "fuel"]:
        check_approx(float(other.snapshot()[key]), float(body.snapshot()[key]), "coincide %s" % key)
    check(not _orbiting_body().snapshot().has("fuel"), "sin medidor no hay clave de combustible")
    other.restore({"x": 0.0, "y": 0.0, "vx": 0.0, "vy": 0.0})
    check_approx(other_fuel.current, fuel.current, "una instantánea sin combustible lo deja como estaba")


func test_forecast_matches_coasting_and_leaves_the_body_untouched() -> void:
    var fuel: ResourceMeter = ResourceMeter.new(1.0, 1.0)
    var body: DynamicBody = _orbiting_body(ThrustEngine.new(0.05, fuel, 0.1))
    _controller.set_command(Vector2(0, 1))
    for _i: int in range(30):
        body.step(1.0 / 60.0)
    var state: Dictionary = body.snapshot()
    var fuel_before: float = fuel.current
    var points: PackedVector2Array = body.forecast(120, 1.0 / 60.0)
    check_equal(points.size(), 121, "incluye el punto actual y un punto por paso")
    check_equal(points[0], body.position, "empieza donde está el cuerpo")
    check_equal(body.snapshot(), state, "predecir no mueve al cuerpo")
    check_equal(fuel.current, fuel_before, "predecir no gasta combustible")
    _controller.set_command(Vector2.ZERO)
    for _i: int in range(120):
        body.step(1.0 / 60.0)
    check(points[120].distance_to(body.position) < 0.0001, "el final de la predicción es donde llega el cuerpo sin empujar más")


func _orbiting_body(engine: ThrustEngine = ThrustEngine.new(0.0)) -> DynamicBody:
    var sources: Array[AccelerationSource] = [CentralGravity.new(Vector2.ZERO, ORBIT_GM, 0.0)]
    return DynamicBody.new(
            _controller,
            engine,
            sources,
            Vector2(ORBIT_RADIUS, 0),
            Vector2(0, ORBIT_SPEED),
            )
