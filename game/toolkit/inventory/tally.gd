class_name Tally
extends RefCounted
## Almacén de cantidades por clave entera (un enum del juego): solo suma, nunca resta.


signal changed(key: int, count: int)

var _counts: Dictionary = {}       # int -> int


## Suma `amount` a `key`. Rechaza cantidades no positivas.
func add(key: int, amount: int) -> bool:
    if amount <= 0:
        return false
    _counts[key] = count(key) + amount
    changed.emit(key, count(key))
    return true


func count(key: int) -> int:
    return int(_counts.get(key, 0))


func total() -> int:
    var sum: int = 0
    for value: int in _counts.values():
        sum += value
    return sum


## Claves como texto para que el viaje por JSON no cambie nada.
func snapshot() -> Dictionary:
    var data: Dictionary = {}
    for key: int in _counts.keys():
        data[str(key)] = count(key)
    return data


func restore(data: Dictionary) -> void:
    _counts.clear()
    for key: String in data.keys():
        _counts[int(key)] = int(data[key])
