class_name TimedCycle
extends RefCounted
## Ciclo de pasos, cada uno con su duración, que avanza al acumular tiempo.
## El tiempo se inyecta desde fuera con tick(delta); no usa Timer, nodos ni autoloads.
## Un delta grande procesa todos los pasos completos y conserva el resto.


signal stepped(previous_index: int, current_index: int)

## Solo lectura desde fuera: cambia con tick() y reset().
var index: int:
    get:
        return _index

var _durations: Array[float] = []
var _index: int = 0
var _elapsed: float = 0.0


func _init(p_durations: Array[float]) -> void:
    if p_durations.is_empty():
        push_error("TimedCycle: necesita al menos un paso")
        return
    for duration: float in p_durations:
        if duration <= 0.0:
            push_error("TimedCycle: cada duración debe ser positiva")
            return
    _durations.assign(p_durations)


func step_count() -> int:
    return _durations.size()


func elapsed() -> float:
    return _elapsed


func reset() -> void:
    _index = 0
    _elapsed = 0.0


## Acumula tiempo y avanza un paso por cada duración completa.
## Un delta no positivo se ignora.
func tick(delta: float) -> void:
    if delta <= 0.0 or _durations.is_empty():
        return
    var remaining: float = delta
    while remaining > 0.0:
        var until_next: float = _durations[_index] - _elapsed
        if remaining < until_next:
            _elapsed += remaining
            return
        remaining -= until_next
        _elapsed = 0.0
        var previous: int = _index
        _index = (_index + 1) % _durations.size()
        stepped.emit(previous, _index)
