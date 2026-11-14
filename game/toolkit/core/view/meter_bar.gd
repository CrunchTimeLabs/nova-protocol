class_name MeterBar
extends VBoxContainer
## Vista genérica de un ResourceMeter: etiqueta con valor/máximo y barra proporcional.


const SEPARATION: int = 4
const BAR_HEIGHT: float = 20.0

var _meter: ResourceMeter
var _label: Label
var _bar: ProgressBar


func _ready() -> void:
    add_theme_constant_override("separation", SEPARATION)
    if _bar == null:
        _build()
    _refresh()


func setup(meter: ResourceMeter) -> void:
    if _meter != null and _meter.changed.is_connected(_on_changed):
        _meter.changed.disconnect(_on_changed)
    _meter = meter
    _meter.changed.connect(_on_changed)
    _refresh()


func _build() -> void:
    _label = Label.new()
    add_child(_label)

    _bar = ProgressBar.new()
    _bar.show_percentage = false
    _bar.custom_minimum_size = Vector2(0.0, BAR_HEIGHT)
    _bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(_bar)


func _on_changed(_meter: ResourceMeter) -> void:
    _refresh()


func _refresh() -> void:
    if _meter == null or _bar == null:
        return
    _bar.max_value = 1.0
    _bar.value = _meter.ratio()
    _label.text = "%s / %s" % [_format_value(_meter.current), _format_value(_meter.max_value)]


func _format_value(value: float) -> String:
    return String.num(value, 1).trim_suffix(".0")
