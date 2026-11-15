class_name TemperaturePanel
extends Control
## Pantalla de la temperatura: reloj con el rango objetivo, mensaje, progreso, aciertos, tiempo, bitácora y un foco
## arriba a la derecha (verde dentro del rango, rojo fuera). Solo lee el estado.
## El aspecto se configura antes de `setup`: fondo, paleta y textos. Sin configurar usa un aspecto neutro; así quien la
## compone (el nivel) puede darle el arte de otra feature sin que esta la importe.


const DIAL_MIN: float = 0.0
const DIAL_MAX: float = 600.0
const DIAL_MARK_STEP: float = 100.0
const MARGIN: int = 16
const SEPARATION: int = 10
const TITLE_SIZE: int = 22
const MESSAGE_SIZE: int = 20
const PROGRESS_WIDTH: float = 320.0
const PANEL_INSET: float = 8.0

## Aspecto (configurable): fondo (null = sin fondo), panel de vidrio, colores y texto de ayuda.
var background: Texture2D = null
var panel_fill: Color = Color(0.0, 0.0, 0.0, 0.0)
var panel_edge: Color = Color(0.0, 0.0, 0.0, 0.0)
var title_color: Color = Color(1.0, 1.0, 1.0)
var text_color: Color = Color(0.9, 0.9, 0.9)
var muted_color: Color = Color(0.6, 0.6, 0.6)
var dial_arc_color: Color = Color(0.6, 0.6, 0.6)
var dial_target_color: Color = Color(0.9, 0.9, 0.9, 0.55)
var dial_needle_color: Color = Color(1.0, 1.0, 1.0)
var title_text: String = "Fundición — temperatura"
var hint_text: String = "Flecha arriba: subir · Flecha abajo: bajar · R: reiniciar · Esc: menú"
## Aviso junto al foco cuando la aguja está fuera de rango (por ejemplo, qué se bloquea por ello).
var out_of_range_text: String = ""

var _state: TemperatureState
var _dial: DialView = DialView.new()
var _lamp: StatusLamp = StatusLamp.new()
var _title: Label = Label.new()
var _message: Label = Label.new()
var _status: Label = Label.new()
var _alert: Label = Label.new()
var _log: Label = Label.new()
var _hint: Label = Label.new()
var _progress: MeterBar = MeterBar.new()


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(state: TemperatureState) -> void:
    _state = state
    _dial.set_range(DIAL_MIN, DIAL_MAX, DIAL_MARK_STEP)
    _dial.set_colors(dial_arc_color, dial_target_color, dial_needle_color, muted_color)
    _dial.set_target(state.target_low, state.target_high)
    _progress.setup(state.progress)
    _build()
    state.targets.target_announced.connect(_on_target_announced)


func _draw() -> void:
    if background != null:
        draw_texture_rect(background, Rect2(Vector2.ZERO, size), false)
    UiDraw.panel(self, Rect2(Vector2.ONE * PANEL_INSET, size - Vector2.ONE * PANEL_INSET * 2.0), panel_fill, panel_edge)


func _process(_delta: float) -> void:
    if _state == null:
        return
    _dial.set_reading(_state.gauge.value)
    var is_in_range: bool = _state.is_in_range()
    _lamp.set_ok(is_in_range)
    _alert.text = "" if is_in_range or _state.is_over() else out_of_range_text
    _message.text = _state.message
    _log.text = "\n".join(_state.log.lines())
    if _state.is_over():
        _status.text = "Tiempo agotado — Aciertos: %d" % _state.hits
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
    _title.text = title_text
    _title.add_theme_font_size_override("font_size", TITLE_SIZE)
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _tint(_title, title_color)
    top.add_child(_title)
    _alert.add_theme_font_size_override("font_size", 14)
    _tint(_alert, Color(1.0, 0.35, 0.28))
    top.add_child(_alert)
    top.add_child(_lamp)
    column.add_child(top)

    _message.add_theme_font_size_override("font_size", MESSAGE_SIZE)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _tint(_message, text_color)
    column.add_child(_message)

    _dial.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _dial.custom_minimum_size = Vector2(0, 280)
    column.add_child(_dial)

    _progress.custom_minimum_size = Vector2(PROGRESS_WIDTH, 0)
    _progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    column.add_child(_progress)

    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _tint(_status, text_color)
    column.add_child(_status)
    _tint(_log, muted_color)
    column.add_child(_log)
    _hint.text = hint_text
    _hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _tint(_hint, muted_color)
    column.add_child(_hint)


## Mismo tipo de letra y color que el resto de pantallas con arte.
func _tint(label: Label, color: Color) -> void:
    label.add_theme_color_override("font_color", color)
    label.add_theme_font_override("font", UiDraw.font(true))


func _on_target_announced(low: float, high: float, _text: String) -> void:
    _dial.set_target(low, high)
