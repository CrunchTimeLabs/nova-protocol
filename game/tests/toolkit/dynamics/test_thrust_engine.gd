extends BaseTest
## Capa 2 (regla): el empuje cuesta combustible y se reduce cuando no alcanza.


func test_acceleration_is_limited_to_max_and_free_without_fuel_meter() -> void:
    var engine: ThrustEngine = ThrustEngine.new(50.0)
    check_equal(engine.acceleration_for(Vector2(1, 0), 0.1), Vector2(50, 0), "empuje máximo")
    check_equal(engine.acceleration_for(Vector2(0.5, 0), 0.1), Vector2(25, 0), "empuje parcial")
    check_approx(engine.acceleration_for(Vector2(10, 0), 0.1).length(), 50.0, "pasar de 1 se limita a 1")
    check_equal(engine.acceleration_for(Vector2.ZERO, 0.1), Vector2.ZERO, "apagado no empuja")


func test_burns_fuel_scales_thrust_on_the_last_drop_and_stops_when_empty() -> void:
    var fuel: ResourceMeter = ResourceMeter.new(10.0, 1.0)
    var engine: ThrustEngine = ThrustEngine.new(50.0, fuel, 10.0)
    check_equal(engine.acceleration_for(Vector2(1, 0), 0.05), Vector2(50, 0), "con combustible de sobra, empuje completo")
    check_approx(fuel.current, 0.5, "gastó burn_rate * throttle * delta")
    check_approx(engine.acceleration_for(Vector2(1, 0), 0.1).x, 25.0, "con la mitad del combustible necesario, la mitad del empuje")
    check_approx(fuel.current, 0.0, "el combustible se vació")
    check_equal(engine.acceleration_for(Vector2(1, 0), 0.1), Vector2.ZERO, "sin combustible no empuja")
