class_name ScaleMap
extends RefCounted
## Escala por tramos: traduce un valor a su posición (0 a 1) en un instrumento. Se define con pares valor → posición y
## se interpola en línea recta entre ellos, así se puede ampliar la zona que importa y comprimir el resto.
## Es solo presentación: no cambia el valor ni cómo se mueve.


var _values: Array[float] = [0.0, 1.0]
var _fractions: Array[float] = [0.0, 1.0]


## `values` y `fractions` tienen el mismo tamaño (≥ 2) y ambos crecen estrictamente; `fractions` va de 0 a 1.
## Si no cumplen, se avisa y la escala queda lineal de 0 a 1.
func _init(p_values: Array[float] = [], p_fractions: Array[float] = []) -> void:
    if p_values.is_empty() and p_fractions.is_empty():
        return
    if not _is_valid(p_values, p_fractions):
        push_error("ScaleMap: los tramos deben ser ≥ 2, del mismo tamaño y crecientes, y las posiciones ir de 0 a 1")
        return
    _values = p_values.duplicate()
    _fractions = p_fractions.duplicate()


## Escala lineal entre `minimum` y `maximum`.
static func linear(minimum: float, maximum: float) -> ScaleMap:
    return ScaleMap.new([minimum, maximum] as Array[float], [0.0, 1.0] as Array[float])


## Posición de `value`; fuera de la escala se acota a los extremos.
func fraction(value: float) -> float:
    if value <= _values[0]:
        return 0.0
    var last: int = _values.size() - 1
    if value >= _values[last]:
        return 1.0
    for i: int in range(1, _values.size()):
        if value <= _values[i]:
            var span: float = _values[i] - _values[i - 1]
            var t: float = (value - _values[i - 1]) / span
            return lerpf(_fractions[i - 1], _fractions[i], t)
    return 1.0


func _is_valid(p_values: Array[float], p_fractions: Array[float]) -> bool:
    if p_values.size() < 2 or p_values.size() != p_fractions.size():
        return false
    if not is_equal_approx(p_fractions[0], 0.0) or not is_equal_approx(p_fractions[p_fractions.size() - 1], 1.0):
        return false
    for i: int in range(1, p_values.size()):
        if p_values[i] <= p_values[i - 1] or p_fractions[i] <= p_fractions[i - 1]:
            return false
    return true
