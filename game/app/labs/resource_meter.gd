extends Control
## Laboratorio de la barra de progreso: compone un ResourceMeter y su MeterBar.
## La barra queda arriba a la izquierda; ↑/↓ cambian el valor, R reinicia y Esc vuelve al menú.
## Solo compone y lee: las reglas viven en ResourceMeter.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const HINT_COLOR := Color(0.6, 0.65, 0.75)
const MARGIN: int = 24
const MAX_VALUE: float = 100.0
const START_VALUE: float = 50.0
const STEP: float = 10.0
const BAR_WIDTH: float = 280.0

var _meter: ResourceMeter
var _bar: MeterBar


func _ready() -> void:
    _build_ui()
    _restart()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_UP:
            _meter.add(STEP)
        KEY_DOWN:
            _meter.add(-STEP)
        KEY_R:
            _restart()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _build_ui() -> void:
    var background: ColorRect = ColorRect.new()
    background.color = BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", MARGIN)
    margin.add_theme_constant_override("margin_top", MARGIN)
    add_child(margin)

    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    margin.add_child(column)

    _bar = MeterBar.new()
    _bar.custom_minimum_size = Vector2(BAR_WIDTH, 0.0)
    column.add_child(_bar)

    var hint: Label = Label.new()
    hint.text = "↑/↓: ±10 · R: reiniciar · Esc: menú"
    hint.add_theme_color_override("font_color", HINT_COLOR)
    column.add_child(hint)


func _restart() -> void:
    if _meter == null:
        _meter = ResourceMeter.new(MAX_VALUE, START_VALUE)
        _bar.setup(_meter)
    else:
        _meter.set_value(START_VALUE)
