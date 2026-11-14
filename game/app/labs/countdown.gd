extends Control
## Laboratorio del contador: compone un Countdown y muestra su valor.
## Avanza solo con el tiempo real; R lo reinicia y Esc vuelve al menú.
## Solo compone y lee: las reglas viven en Countdown.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const VALUE_FONT_SIZE: int = 96
const HINT_COLOR := Color(0.6, 0.65, 0.75)

var _countdown: Countdown
var _value_label: Label
var _bar: ProgressBar
var _status_label: Label


func _ready() -> void:
    _build_ui()
    _restart()


func _process(delta: float) -> void:
    _countdown.tick(delta)
    _refresh()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_R:
            _restart()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _build_ui() -> void:
    var background: ColorRect = ColorRect.new()
    background.color = BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var center: CenterContainer = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var column: VBoxContainer = VBoxContainer.new()
    column.alignment = BoxContainer.ALIGNMENT_CENTER
    column.add_theme_constant_override("separation", 12)
    column.custom_minimum_size = Vector2(320, 0)
    center.add_child(column)

    _value_label = Label.new()
    _value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _value_label.add_theme_font_size_override("font_size", VALUE_FONT_SIZE)
    column.add_child(_value_label)

    _bar = ProgressBar.new()
    _bar.max_value = float(Countdown.START_VALUE)
    _bar.show_percentage = false
    _bar.custom_minimum_size = Vector2(0, 8)
    column.add_child(_bar)

    _status_label = Label.new()
    _status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(_status_label)

    var hint: Label = Label.new()
    hint.text = "R: reiniciar · Esc: menú"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", HINT_COLOR)
    column.add_child(hint)


func _restart() -> void:
    _countdown = Countdown.new()
    _refresh()


func _refresh() -> void:
    _value_label.text = str(_countdown.value)
    _bar.value = float(_countdown.value)
    _status_label.text = "AGOTADO" if _countdown.is_exhausted() else "-1 cada 2 s"
