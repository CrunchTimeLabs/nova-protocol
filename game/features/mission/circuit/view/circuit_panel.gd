class_name CircuitPanel
extends Node2D
## Vista de un jugador del circuito. El rotador gira con clic izquierdo (derecho, en sentido contrario);
## el intercambiador marca una celda y luego otra con clic izquierdo (derecho desmarca). Delega todo en comandos.


const NO_CELL: Vector2i = Vector2i(-1, -1)
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _client: MatchClient
var _replica: CircuitMatch
var _view: CircuitView = CircuitView.new()
var _hud: Label = Label.new()
var _picked: Vector2i = NO_CELL


func setup(client: MatchClient) -> void:
    _client = client
    _replica = client.replica as CircuitMatch
    _view.setup_grid(_replica.grid)
    add_child(_view)
    _hud.position = HUD_MARGIN
    add_child(_hud)
    _client.snapshot_applied.connect(func(_tick: int) -> void: _refresh_hud())
    _refresh_hud()


func _process(_delta: float) -> void:
    _view.position = (get_viewport_rect().size - _view.board_pixel_size()) / 2.0


func _unhandled_input(event: InputEvent) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click == null or not click.pressed or not _client.is_joined():
        return
    var cell: Vector2i = _view.cell_at(_view.to_local(click.position))
    if _client.role == CircuitRole.Role.ROTATOR:
        _rotate(click, cell)
    else:
        _swap(click, cell)


func _rotate(click: InputEventMouseButton, cell: Vector2i) -> void:
    var steps: int = 0
    if click.button_index == MOUSE_BUTTON_LEFT:
        steps = 1
    elif click.button_index == MOUSE_BUTTON_RIGHT:
        steps = -1
    if steps != 0:
        _client.send_command(CircuitCommand.Kind.ROTATE_TILE, {"x": cell.x, "y": cell.y, "steps": steps}, true)


func _swap(click: InputEventMouseButton, cell: Vector2i) -> void:
    if click.button_index == MOUSE_BUTTON_RIGHT:
        _picked = NO_CELL
    elif click.button_index == MOUSE_BUTTON_LEFT:
        if _picked == NO_CELL:
            _picked = cell
        else:
            var payload: Dictionary = {"ax": _picked.x, "ay": _picked.y, "bx": cell.x, "by": cell.y}
            _client.send_command(CircuitCommand.Kind.SWAP_TILES, payload, true)
            _picked = NO_CELL
    _refresh_hud()


func _refresh_hud() -> void:
    var action: String = "clic: girar (derecho: al revés)" if _client.role == CircuitRole.Role.ROTATOR else "clic en dos celdas: intercambiar (derecho: desmarcar)"
    var picked_note: String = "" if _picked == NO_CELL else " · marcada %s" % _picked
    var status: String = "¡ENERGIZADO!" if _replica.grid.is_solved() else "consumidores apagados"
    _hud.text = "%s · %d/%d satisfechos · %s%s" % [status, _replica.grid.satisfied_count(), _replica.grid.board.targets.size(), action, picked_note]
