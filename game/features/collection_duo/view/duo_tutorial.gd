class_name DuoTutorial
extends Control
## Tutorial grande en el centro de la pantalla para los dos: una demo con zoom (la del tutorial de la
## recolección), las teclas de cada jugador y qué hay que hacer. No pausa: se cumple cuando los dos han
## entrado al laberinto; entonces felicita y desaparece. Solo lee la partida.


const PANEL_SIZE := Vector2(600, 440)
const ZOOM := 1.15
const FRAME_SIZE := Vector2(560, 190)
const DONE_TIME := 1.2
const BORDER := Color(0.95, 0.74, 0.18)
const TEXT := Color(0.94, 0.94, 0.92)
const HINT := Color(0.65, 0.65, 0.68)
const DONE := Color(0.35, 0.9, 0.45)

var _run: DuoRun
var _demo: CollectionDemo
var _look: CollectionDraw.Look = CollectionDraw.Look.new()
var _demo_car: Vector2
var _done_left: float = 0.0
var _is_done: bool = false
var _time: float = 0.0
var _appear: float = 0.0
var _frame: Control


func _init(run: DuoRun) -> void:
    _run = run


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame = Control.new()
    _frame.clip_contents = true
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame.draw.connect(_draw_demo)
    add_child(_frame)
    _new_demo()


func is_showing() -> bool:
    return not _is_done or _done_left > 0.0


func _process(delta: float) -> void:
    _time += delta
    _appear = minf(1.0, _appear + delta * 3.0)
    if not _is_done and _run.both_entered():
        _is_done = true
        _done_left = DONE_TIME
    if _is_done:
        _done_left = maxf(0.0, _done_left - delta)
        visible = _done_left > 0.0
    if _demo.step(delta):
        _new_demo()
    var moved: Vector2 = _demo.run.car - _demo_car
    if moved.length() > 0.2:
        _look.heading = lerp_angle(_look.heading, moved.angle(), 0.3)
    _demo_car = _demo.run.car
    var rect: Rect2 = _panel_rect()
    _frame.visible = not _is_done
    _frame.position = Vector2(rect.get_center().x - FRAME_SIZE.x / 2.0, rect.position.y + 76)
    _frame.size = FRAME_SIZE
    queue_redraw()
    _frame.queue_redraw()


func _new_demo() -> void:
    _demo = CollectionDemo.new(CollectionDemo.Scene.DRIVE_AND_COLLECT)
    _demo_car = _demo.run.car


func _panel_rect() -> Rect2:
    var scale: float = 0.85 + 0.15 * (1.0 - pow(1.0 - _appear, 3.0))
    var panel_size: Vector2 = PANEL_SIZE * scale
    return Rect2(size / 2.0 - panel_size / 2.0 + Vector2(0, 12), panel_size)


func _draw() -> void:
    var rect: Rect2 = _panel_rect()
    if _is_done:
        var alpha: float = minf(1.0, _done_left / 0.4)
        UiDraw.panel(self, rect, Color(0.03, 0.09, 0.05, 0.92 * alpha), Color(DONE, alpha))
        UiDraw.text_centered(self, rect.get_center().x, rect.get_center().y - 50, "✔ ¡ADENTRO!", 44, Color(DONE, alpha), true)
        UiDraw.text_centered(self, rect.get_center().x, rect.get_center().y + 14, "¡A recolectar menas!", 22, Color(TEXT, alpha), true)
        return
    UiDraw.panel(self, rect, Color(0.04, 0.04, 0.06, 0.93), BORDER)
    var x: float = rect.position.x
    var cx: float = rect.get_center().x
    UiDraw.text(self, Vector2(x + 20, rect.position.y + 12), "TUTORIAL", 13, HINT, true)
    UiDraw.text_centered(self, cx, rect.position.y + 30, "ENTREN LOS DOS AL LABERINTO", 26, BORDER, true)
    var frame: Rect2 = Rect2(_frame.position, FRAME_SIZE)
    draw_rect(frame.grow(2.0), BORDER, false, 1.5)
    var row_y: float = frame.end.y + 18.0
    _player_row(Vector2(x + 30, row_y), 1, "W A S D")
    _player_row(Vector2(cx + 10, row_y), 2, "I J K L")
    UiDraw.wrapped(
            self,
            Vector2(x + 30, row_y + 70),
            "Pasen por encima de las menas para recogerlas: la barra es su tiempo. Junten el mínimo entre los dos y lleguen juntos a la rampa de abajo.",
            14,
            TEXT,
            rect.size.x - 60.0,
            )


func _player_row(at: Vector2, player: int, keys: String) -> void:
    var car: MazeCar = _run.cars[player - 1]
    var color: Color = DuoDraw.player_color(player)
    var box: Rect2 = Rect2(at, Vector2(250, 56))
    UiDraw.panel(self, box, Color(color, 0.08), Color(color, 0.7))
    CollectionDraw.car(self, box.position + Vector2(28, 28), 0.0 if player == 1 else PI, 1.0, color, false)
    UiDraw.text(self, box.position + Vector2(56, 6), "JUGADOR %d" % player, 13, color, true)
    UiDraw.text(self, box.position + Vector2(56, 24), keys, 20, TEXT, true)
    if car.has_entered:
        UiDraw.text(self, box.position + Vector2(204, 12), "✔", 26, DONE, true)
    else:
        var dots: String = ".".repeat(1 + int(_time * 3.0) % 3)
        UiDraw.text(self, box.position + Vector2(196, 18), dots, 18, HINT, true)


## Cámara con zoom que sigue al cochecito de la demo (recortada al recuadro).
func _draw_demo() -> void:
    _frame.draw_rect(Rect2(Vector2.ZERO, _frame.size), Color(0.03, 0.03, 0.04))
    var view: Vector2 = _frame.size / ZOOM
    var area: Rect2 = CollectionDemo.AREA
    var top_left: Vector2 = _demo.run.car - view / 2.0
    top_left.x = clampf(top_left.x, area.position.x, maxf(area.position.x, area.end.x - view.x))
    top_left.y = clampf(top_left.y, area.position.y, maxf(area.position.y, area.end.y - view.y))
    _frame.draw_set_transform(-top_left * ZOOM, 0.0, Vector2(ZOOM, ZOOM))
    CollectionDraw.board(_frame, _demo.run, _demo.time, _look)
    _frame.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    UiDraw.text(_frame, Vector2(6, _frame.size.y - 18), "DEMO", 10, Color(BORDER, 0.8), true)
