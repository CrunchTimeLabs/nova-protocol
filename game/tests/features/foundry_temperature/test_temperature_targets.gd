extends BaseTest
## Capa 2: el generador anuncia rangos válidos cada intervalo, de forma determinista, con un mensaje que nombra el rango.


func _collect(seed_value: int) -> Array[Vector2]:
    var generator: TemperatureTargets = TemperatureTargets.new(seed_value)
    var announced: Array[Vector2] = []
    generator.target_announced.connect(func(low: float, high: float, _message: String) -> void: announced.append(Vector2(low, high)))
    for _i: int in range(5):
        generator.tick(TemperatureTargets.TARGET_INTERVAL)
    return announced


func test_announces_every_interval_with_a_message() -> void:
    var generator: TemperatureTargets = TemperatureTargets.new(1)
    var messages: Array[String] = []
    generator.target_announced.connect(func(_low: float, _high: float, message: String) -> void: messages.append(message))
    generator.tick(TemperatureTargets.TARGET_INTERVAL - 0.1)
    check_equal(messages.size(), 0, "antes del intervalo no anuncia")
    generator.tick(0.1)
    check_equal(messages.size(), 1, "al cumplirse el intervalo anuncia")
    var sample: Vector2 = TemperatureTargets.TARGET_RANGES[0]
    var named: bool = false
    for range_option: Vector2 in TemperatureTargets.TARGET_RANGES:
        named = named or messages[0].contains(str(int(range_option.x)))
    check(named and sample != Vector2.ZERO, "el mensaje nombra el rango")


func test_same_seed_same_targets_and_all_from_the_table() -> void:
    var first: Array[Vector2] = _collect(6)
    check_equal(first, _collect(6), "misma semilla, mismos objetivos")
    for announced: Vector2 in first:
        check(TemperatureTargets.TARGET_RANGES.has(announced), "el rango sale de la tabla")
