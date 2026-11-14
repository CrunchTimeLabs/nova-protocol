class_name MessageLog
extends RefCounted
## Bitácora para el jugador: conserva las últimas `capacity` líneas.


signal line_added(line: String)

var capacity: int
var _prefix: Callable
var _lines: Array[String] = []


func _init(p_capacity: int = 6, p_prefix: Callable = Callable()) -> void:
    capacity = p_capacity
    _prefix = p_prefix


func add(text: String, raw: bool = false) -> void:
    var line: String = text
    if not raw and _prefix.is_valid():
        line = "%s %s" % [_prefix.call(), text]
    _lines.append(line)
    while _lines.size() > capacity:
        _lines.pop_front()
    line_added.emit(line)


func clear() -> void:
    _lines.clear()


func lines() -> Array[String]:
    var copy: Array[String] = []
    copy.assign(_lines)
    return copy


func restore(saved: Array) -> void:
    _lines.clear()
    for line: Variant in saved:
        _lines.append(str(line))
