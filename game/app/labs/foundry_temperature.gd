extends Control
## Laboratorio de la fundición de temperatura: compone el estado y su panel y lee las flechas.
## Flecha arriba sube, flecha abajo baja; R reinicia y Esc vuelve al menú.
## Solo compone y lee la entrada: las reglas viven en TemperatureState.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const SEED: int = 2026

var _state: TemperatureState
var _panel: TemperaturePanel
var _runs: int = 0


func _ready() -> void:
    var background: ColorRect = ColorRect.new()
    background.color = BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    _restart()


func _physics_process(delta: float) -> void:
    var raise: float = float(Input.is_physical_key_pressed(KEY_UP))
    var lower: float = float(Input.is_physical_key_pressed(KEY_DOWN))
    _state.step(delta, raise - lower)


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_R:
            _restart()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _restart() -> void:
    _runs += 1
    if _panel != null:
        _panel.queue_free()
    _state = TemperatureState.new(SEED + _runs)
    _panel = TemperaturePanel.new()
    add_child(_panel)
    _panel.setup(_state)
