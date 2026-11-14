extends BaseTest
## Capa 1 (elemento): los parámetros se limitan a rangos válidos y los presets son utilizables.


func test_out_of_range_values_are_clamped() -> void:
    var profile: MovementProfile = MovementProfile.new(-5.0, -1.0, -2.0, 0.2)
    check(profile.max_speed > 0.0, "la velocidad máxima siempre es positiva")
    check_equal(profile.accel_time, 0.0, "un tiempo de aceleración negativo queda instantáneo")
    check_equal(profile.decel_time, 0.0, "un tiempo de frenado negativo queda instantáneo")
    check_equal(profile.turn_response, MovementProfile.MIN_TURN_RESPONSE, "el giro nunca es más lento que el arranque")


func test_presets_are_valid_and_feel_different() -> void:
    var snappy: MovementProfile = MovementProfile.snappy()
    var heavy: MovementProfile = MovementProfile.heavy()
    var icy: MovementProfile = MovementProfile.icy()
    for profile: MovementProfile in [snappy, heavy, icy]:
        check(profile.max_speed > 0.0 and profile.accel_time > 0.0 and profile.decel_time > 0.0, "preset con valores positivos")
    check(snappy.accel_time < heavy.accel_time, "snappy arranca antes que heavy")
    check(icy.decel_time > icy.accel_time, "icy frena mucho más lento de lo que arranca")
