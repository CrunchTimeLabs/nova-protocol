extends Node2D
## Laboratorio del cableado: clic izquierdo gira una pieza, derecho en sentido contrario. 1 = una ruta, 2 = dos destinos, R = otro tablero, Esc vuelve al menú.


enum Preset { SINGLE_ROUTE, TWO_TARGETS }

const BOARD_SIZE: int = 5
const FIRST_SEED: int = 1
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _board: PipeBoard
var _view: PipeBoardView
var _preset: Preset = Preset.SINGLE_ROUTE
var _seed_value: int = FIRST_SEED
var _hud: Label


func _ready() -> void:
    _view = PipeBoardView.new()
    add_child(_view)
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = HUD_MARGIN
    layer.add_child(_hud)
    _new_board()


func _unhandled_input(event: InputEvent) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click != null and click.pressed:
        _rotate_under(click)
        return
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_1:
            _preset = Preset.SINGLE_ROUTE
            _new_board()
        KEY_2:
            _preset = Preset.TWO_TARGETS
            _new_board()
        KEY_R:
            _seed_value += 1
            _new_board()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _rotate_under(click: InputEventMouseButton) -> void:
    var steps: int = 0
    if click.button_index == MOUSE_BUTTON_LEFT:
        steps = 1
    elif click.button_index == MOUSE_BUTTON_RIGHT:
        steps = -1
    if steps == 0:
        return
    var cell: Vector2i = _view.cell_at(_view.to_local(click.position))
    if _board.rotate_tile(cell, steps):
        _refresh_hud()


func _new_board() -> void:
    var config: PipeBoardConfig = _config_for(_preset)
    _board = PipeBoardGenerator.new(config).build()
    _view.setup(_board)
    _view.position = (get_viewport_rect().size - _view.board_pixel_size()) / 2.0
    _refresh_hud()


func _refresh_hud() -> void:
    var status: String = "¡CONECTADO!" if _board.is_solved() else "sin conexión"
    _hud.text = "Cableado %s · semilla %d · destinos encendidos: %d/%d · %s\nClic: girar · 1/2: preset · R: otro tablero · Esc: menú" % [
        Preset.keys()[_preset],
        _seed_value,
        _board.lit_count(),
        _board.targets.size(),
        status,
    ]


func _config_for(preset: Preset) -> PipeBoardConfig:
    match preset:
        Preset.SINGLE_ROUTE:
            return PipeBoardConfig.single_route(BOARD_SIZE, BOARD_SIZE, _seed_value)
        Preset.TWO_TARGETS:
            return PipeBoardConfig.two_targets(BOARD_SIZE, BOARD_SIZE, _seed_value)
    return PipeBoardConfig.single_route(BOARD_SIZE, BOARD_SIZE, _seed_value)
