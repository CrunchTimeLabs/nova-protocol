class_name GameRandom
extends RefCounted
## Azar inyectable: partidas reproducibles con semilla y tests deterministas.


var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## seed_value < 0 -> semilla aleatoria.
func _init(seed_value: int = -1) -> void:
    if seed_value >= 0:
        _rng.seed = seed_value
    else:
        _rng.randomize()


## Entero aleatorio, ambos extremos incluidos.
func range_int(low: int, high: int) -> int:
    return _rng.randi_range(low, high)


func chance(probability: float) -> bool:
    return _rng.randf() < probability


func pick(items: Array) -> Variant:
    return items[_rng.randi() % items.size()]


## Real en [low, high].
func range_float(low: float, high: float) -> float:
    return _rng.randf_range(low, high)


## Baraja `items` en sitio (Fisher-Yates) con este generador, no con el global.
func shuffle(items: Array) -> void:
    for i: int in range(items.size() - 1, 0, -1):
        var j: int = _rng.randi_range(0, i)
        var held: Variant = items[i]
        items[i] = items[j]
        items[j] = held
