extends Node2D
## Laboratorio del laberinto: un círculo se mueve por celdas con las flechas hasta la salida (cuadrado).
## R genera otro laberinto, Esc vuelve al menú. Solo compone y dibuja; las reglas viven en Maze.


const COLS: int = 12
const ROWS: int = 8
const CELL: float = 48.0
const WALL: float = 4.0
const ORIGIN: Vector2 = Vector2(224, 120)
const FIRST_SEED: int = 1

var _maze: Maze
var _cell: Vector2i
var _seed_value: int = FIRST_SEED
var _hud: Label


func _ready() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = Vector2(12, 8)
    layer.add_child(_hud)
    _new_maze()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_UP:
            _try_move(Maze.N)
        KEY_RIGHT:
            _try_move(Maze.E)
        KEY_DOWN:
            _try_move(Maze.S)
        KEY_LEFT:
            _try_move(Maze.W)
        KEY_R:
            _seed_value += 1
            _new_maze()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _draw() -> void:
    for rect: Rect2 in _maze.wall_rects(ORIGIN, CELL, WALL):
        draw_rect(rect, Color.WHITE)
    draw_rect(_cell_rect(_maze.exit_cell()).grow(-12.0), Color.GREEN)
    draw_circle(_center(_cell), CELL * 0.25, Color.YELLOW)


func _new_maze() -> void:
    _maze = Maze.generate(COLS, ROWS, GameRandom.new(_seed_value))
    _cell = _maze.entrance()
    _refresh()


func _try_move(dir: int) -> void:
    if _maze.has_wall(_cell, dir):
        return
    _cell += Maze.STEP[dir] as Vector2i
    _refresh()


func _refresh() -> void:
    _hud.text = "Flechas: mover · R: otro laberinto · Esc: menú" + ("\n¡Salida!" if _cell == _maze.exit_cell() else "")
    queue_redraw()


func _cell_rect(cell: Vector2i) -> Rect2:
    return Rect2(ORIGIN + Vector2(cell) * CELL, Vector2(CELL, CELL))


func _center(cell: Vector2i) -> Vector2:
    return _cell_rect(cell).get_center()
