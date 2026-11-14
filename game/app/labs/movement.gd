extends Node2D
## Laboratorio del movimiento: compone controlador, perfil, cuerpo y vista. WASD mueve; 1, 2 y 3 cambian el perfil; Esc vuelve al menú.


enum Preset { SNAPPY, HEAVY, ICY }

const START_POSITION: Vector2 = Vector2(512, 320)
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _controller: ManualController
var _body: MovementBody
var _preset: Preset = Preset.SNAPPY
var _hud: Label


func _ready() -> void:
    _controller = ManualController.new()
    _body = MovementBody.new(_controller, _profile_for(_preset), START_POSITION)
    var square: SquareView = SquareView.new()
    square.setup(_body)
    add_child(square)
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = HUD_MARGIN
    layer.add_child(_hud)


func _physics_process(delta: float) -> void:
    _controller.set_direction(_read_direction())
    _body.step(delta)
    _hud.text = "Perfil: %s   velocidad: %.0f\nWASD: mover · 1/2/3: perfil · Esc: menú" % [Preset.keys()[_preset], _body.velocity.length()]


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_1:
            _use_preset(Preset.SNAPPY)
        KEY_2:
            _use_preset(Preset.HEAVY)
        KEY_3:
            _use_preset(Preset.ICY)
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


## Teclas físicas: WASD sirve igual en cualquier distribución de teclado.
func _read_direction() -> Vector2:
    var horizontal: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var vertical: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    return Vector2(horizontal, vertical)


func _use_preset(preset: Preset) -> void:
    _preset = preset
    _body.set_profile(_profile_for(preset))


func _profile_for(preset: Preset) -> MovementProfile:
    match preset:
        Preset.SNAPPY:
            return MovementProfile.snappy()
        Preset.HEAVY:
            return MovementProfile.heavy()
        Preset.ICY:
            return MovementProfile.icy()
    return MovementProfile.snappy()
