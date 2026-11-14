class_name PipeBoardView
extends Node2D
## Dibuja un PipeBoard con círculos y trazos: un círculo por celda, un trazo por lado abierto.
## Solo lee el tablero; girar piezas lo decide quien llama a `board.rotate_tile`.


const CELL_SIZE: float = 96.0
const NODE_RADIUS: float = 9.0
const TERMINAL_RADIUS: float = 14.0
const STROKE_WIDTH: float = 6.0
const STUB_LENGTH: float = 22.0
const COLOR_LIVE: Color = Color(1.0, 0.85, 0.25)
const COLOR_DEAD: Color = Color(0.35, 0.4, 0.5)
const COLOR_CELL: Color = Color(0.12, 0.15, 0.22)
const COLOR_TARGET_OFF: Color = Color(0.9, 0.3, 0.3)
const COLOR_TARGET_ON: Color = Color(0.4, 1.0, 0.5)

var _board: PipeBoard


func setup(board: PipeBoard) -> void:
    _board = board
    _board.changed.connect(queue_redraw)
    queue_redraw()


func board_pixel_size() -> Vector2:
    return Vector2(_board.width, _board.height) * CELL_SIZE


## Celda bajo una posición local de la vista; (-1, -1) si cae fuera del tablero.
func cell_at(local_position: Vector2) -> Vector2i:
    var cell: Vector2i = Vector2i((local_position / CELL_SIZE).floor())
    return cell if _board.contains(cell) else Vector2i(-1, -1)


func _draw() -> void:
    if _board == null:
        return
    for y: int in _board.height:
        for x: int in _board.width:
            _draw_cell(Vector2i(x, y))
    for source: PipeTerminal in _board.sources:
        _draw_terminal(source, COLOR_LIVE)
    for i: int in _board.targets.size():
        _draw_terminal(_board.targets[i], COLOR_TARGET_ON if _board.is_target_lit(i) else COLOR_TARGET_OFF)


func _draw_cell(cell: Vector2i) -> void:
    var center: Vector2 = _center_of(cell)
    var color: Color = COLOR_LIVE if _board.is_powered(cell) else COLOR_DEAD
    draw_arc(center, CELL_SIZE * 0.45, 0.0, TAU, 32, COLOR_CELL, 2.0)
    for side_value: int in PipeTile.SIDE_COUNT:
        var side: PipeTile.Side = side_value as PipeTile.Side
        if _board.connects(cell, side):
            draw_line(center, center + Vector2(PipeTile.offset(side)) * CELL_SIZE * 0.5, color, STROKE_WIDTH)
    draw_circle(center, NODE_RADIUS, color)


## Un tramo corto hacia fuera del tablero y un círculo en su punta.
func _draw_terminal(terminal: PipeTerminal, color: Color) -> void:
    var edge: Vector2 = _center_of(terminal.cell) + Vector2(PipeTile.offset(terminal.side)) * CELL_SIZE * 0.5
    var tip: Vector2 = _terminal_tip(terminal)
    draw_line(edge, tip, color, STROKE_WIDTH)
    draw_circle(tip, TERMINAL_RADIUS, color)


func _terminal_tip(terminal: PipeTerminal) -> Vector2:
    var edge: Vector2 = _center_of(terminal.cell) + Vector2(PipeTile.offset(terminal.side)) * CELL_SIZE * 0.5
    return edge + Vector2(PipeTile.offset(terminal.side)) * STUB_LENGTH


func _center_of(cell: Vector2i) -> Vector2:
    return (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE
