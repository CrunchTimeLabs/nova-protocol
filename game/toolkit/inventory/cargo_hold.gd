class_name CargoHold
extends RefCounted
## Bodega con capacidad por masa: cada objeto (por id) pesa algo y no se puede pasar de la capacidad.
## Cambiar la capacidad no expulsa lo ya cargado; solo decide qué más cabe.


signal changed

var capacity: int

var _masses: Dictionary = {}     # id (String) -> masa (int)
var _order: Array[String] = []


func _init(p_capacity: int = 0) -> void:
    capacity = maxi(0, p_capacity)


func set_capacity(value: int) -> void:
    capacity = maxi(0, value)
    changed.emit()


func used() -> int:
    var total: int = 0
    for item_id: String in _order:
        total += int(_masses[item_id])
    return total


func free_capacity() -> int:
    return capacity - used()


func has(item_id: String) -> bool:
    return _masses.has(item_id)


func is_empty() -> bool:
    return _order.is_empty()


func size() -> int:
    return _order.size()


## Ids en el orden en que se cargaron.
func ids() -> Array[String]:
    return _order.duplicate()


func can_add(item_id: String, mass: int) -> bool:
    return not has(item_id) and mass >= 0 and mass <= free_capacity()


func add(item_id: String, mass: int) -> bool:
    if not can_add(item_id, mass):
        return false
    _masses[item_id] = mass
    _order.append(item_id)
    changed.emit()
    return true


func remove(item_id: String) -> bool:
    if not has(item_id):
        return false
    _masses.erase(item_id)
    _order.erase(item_id)
    changed.emit()
    return true


func clear() -> void:
    _masses.clear()
    _order.clear()
    changed.emit()
