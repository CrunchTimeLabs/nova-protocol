extends Node2D
## Laboratorio del circuito: clic izquierdo gira una pieza, derecho en sentido contrario, Mayús+clic en dos celdas las intercambia. 1 = una ruta, 2 = tres consumidores (uno en el centro), 3 = dos fuentes y cuatro consumidores (dos dentro), R = otro tablero, Esc vuelve al menú.
## Solo compone: el tablero, la rejilla de potencia y la vista; las reglas viven en el toolkit.


enum Preset { SINGLE_ROUTE, CENTER_TARGET, INNER_TARGETS }

const BOARD_SIZE: int = 5
const FIRST_SEED: int = 1
const NO_CELL: Vector2i = Vector2i(-1, -1)
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _board: PipeBoard
var _grid: PowerGrid
var _view: CircuitView
var _preset: Preset = Preset.SINGLE_ROUTE
var _seed_value: int = FIRST_SEED
var _hud: Label
## Celda marcada con Mayús+clic, a la espera de la segunda para intercambiar.
var _picked: Vector2i = NO_CELL


func _ready() -> void:
    _view = CircuitView.new()
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
            _preset = Preset.CENTER_TARGET
            _new_board()
        KEY_3:
            _preset = Preset.INNER_TARGETS
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
    if click.shift_pressed:
        _pick_for_swap(cell)
    elif _board.rotate_tile(cell, steps):
        _refresh_hud()


## Primera celda: se marca. Segunda: se intercambian (la misma celda desmarca).
func _pick_for_swap(cell: Vector2i) -> void:
    if not _board.contains(cell):
        return
    if _picked == NO_CELL:
        _picked = cell
    else:
        _board.swap_tiles(_picked, cell)
        _picked = NO_CELL
    _refresh_hud()


func _new_board() -> void:
    _picked = NO_CELL
    _grid = CircuitGenerator.new(CircuitConfig.from_pipe(_config_for(_preset))).build()
    _board = _grid.board
    _view.setup_grid(_grid)
    _view.position = (get_viewport_rect().size - _view.board_pixel_size()) / 2.0
    _refresh_hud()


func _refresh_hud() -> void:
    var picked_note: String = "" if _picked == NO_CELL else " · marcada %s: elige otra para intercambiar" % _picked
    var status: String = "¡ENERGIZADO!" if _grid.is_solved() else "consumidores apagados"
    status += picked_note
    _hud.text = "Circuito %s · semilla %d · consumidores satisfechos: %d/%d · %s\nClic: girar · Mayús+clic ×2: intercambiar · 1/2/3: preset · R: otro tablero · Esc: menú" % [
        Preset.keys()[_preset],
        _seed_value,
        _grid.satisfied_count(),
        _board.targets.size(),
        status,
    ]


func _config_for(preset: Preset) -> PipeBoardConfig:
    match preset:
        Preset.SINGLE_ROUTE:
            return PipeBoardConfig.single_route(BOARD_SIZE, BOARD_SIZE, _seed_value)
        Preset.CENTER_TARGET:
            return PipeBoardConfig.center_target(BOARD_SIZE, BOARD_SIZE, _seed_value)
        Preset.INNER_TARGETS:
            return PipeBoardConfig.two_sources_inner_targets(BOARD_SIZE, BOARD_SIZE, _seed_value)
    return PipeBoardConfig.single_route(BOARD_SIZE, BOARD_SIZE, _seed_value)
