class_name ResourceMeter
extends RefCounted
## Valor acotado entre 0 y max_value (energía, vida, dinero…). Avisa al cambiar, vaciarse o llenarse.


signal changed(meter: ResourceMeter)
signal emptied(meter: ResourceMeter)
signal filled(meter: ResourceMeter)

var max_value: float
## Solo lectura desde fuera: se modifica con add() / set_value().
var current: float:
    get:
        return _current

var _current: float


func _init(p_max: float, p_start: float) -> void:
    max_value = p_max
    _current = clampf(p_start, 0.0, p_max)


func ratio() -> float:
    return _current / max_value if max_value > 0.0 else 0.0


func can_afford(cost: float) -> bool:
    return _current - cost >= 0.0


## Devuelve el cambio realmente aplicado (tras limitar al rango).
func add(amount: float) -> float:
    var before: float = _current
    set_value(_current + amount)
    return _current - before


func set_value(value: float) -> void:
    var previous: float = _current
    _current = clampf(value, 0.0, max_value)
    if is_equal_approx(_current, previous):
        return
    changed.emit(self)
    if _current <= 0.0:
        emptied.emit(self)
    elif _current >= max_value:
        filled.emit(self)
