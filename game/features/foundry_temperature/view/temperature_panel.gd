class_name TemperaturePanel
extends Control
## Pantalla del laboratorio de temperatura: reloj con el rango objetivo, mensaje, progreso, aciertos, tiempo, bitácora
## y un foco arriba a la derecha (verde dentro del rango, rojo fuera). Solo lee el estado.


const DIAL_MIN: float = 0.0
const DIAL_MAX: float = 600.0
const DIAL_MARK_STEP: float = 100.0
const MARGIN: int = 16
const SEPARATION: int = 10
const TITLE_SIZE: int = 22
const MESSAGE_SIZE: int = 20
const PROGRESS_WIDTH: float = 320.0

var _state: TemperatureState
var _dial: DialView = DialView.new()
var _lamp: StatusLamp = StatusLamp.new()
var _title: Label = Label.new()
var _message: Label = Label.new()
var _status: Label = Label.new()
var _log: Label = Label.new()
var _progress: MeterBar = MeterBar.new()


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)


func setup(state: TemperatureState) -> void:
    _state = state
    _dial.set_range(DIAL_MIN, DIAL_MAX, DIAL_MARK_STEP)
    _dial.set_target(state.target_low, state.target_high)
    _progress.setup(state.progress)
    _build()
    state.targets.target_announced.connect(_on_target_announced)


func _process(_delta: float) -> void:
    if _state == null:
        return
    _dial.set_reading(_state.gauge.value)
    _lamp.set_ok(_state.is_in_range())
    _message.text = _state.message
    _log.text = "\n".join(_state.log.lines())
    if _state.is_over():
        _status.text = "Tiempo agotado — Aciertos: %d — R: reiniciar" % _state.hits
    else:
        _status.text = "Tiempo: %d s — Aciertos: %d" % [_state.time_left(), _state.hits]


func _build() -> void:
    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
        margin.add_theme_constant_override(side, MARGIN)
    add_child(margin)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", SEPARATION)
    margin.add_child(column)

    var top: HBoxContainer = HBoxContainer.new()
    _title.text = "Fundición — temperatura"
    _title.add_theme_font_size_override("font_size", TITLE_SIZE)
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(_title)
    top.add_child(_lamp)
    column.add_child(top)

    _message.add_theme_font_size_override("font_size", MESSAGE_SIZE)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(_message)

    _dial.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _dial.custom_minimum_size = Vector2(0, 280)
    column.add_child(_dial)

    _progress.custom_minimum_size = Vector2(PROGRESS_WIDTH, 0)
    _progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    column.add_child(_progress)

    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(_status)
    column.add_child(_log)
    var hint: Label = Label.new()
    hint.text = "Flecha arriba: subir · Flecha abajo: bajar · R: reiniciar · Esc: menú"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(hint)


func _on_target_announced(low: float, high: float, _text: String) -> void:
    _dial.set_target(low, high)
