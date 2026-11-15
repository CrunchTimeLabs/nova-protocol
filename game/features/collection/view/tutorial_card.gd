class_name TutorialCard
extends Control
## Tarjeta del tutorial en la columna lateral: título del paso, demostración con zoom que sigue al
## cochecito y el texto de qué hacer. No pausa nada: el paso se cumple jugando. Solo lee la sesión.


const ZOOM := 1.5
const PADDING := 12.0
const FRAME_HEIGHT := 130.0
const BACKGROUND := Color(0.06, 0.06, 0.08)
const BORDER := Color(0.95, 0.74, 0.18)
const CAVE_IN_BORDER := Color(0.95, 0.45, 0.25)
const TEXT := Color(0.92, 0.92, 0.9)
const HINT := Color(0.6, 0.6, 0.62)
const DONE := Color(0.35, 0.9, 0.45)
const DONE_TIME := 1.1
## La demo exagera: rocas grandes que caen despacio.
const DEMO_ROCK_SCALE := 1.9
const DEMO_FALL_TIME := 1.1
const DEMO_CRASH_DB := -10.0
const SLIDE_TIME := 0.3
## Cuánto se desvía la cámara de la demo hacia el derrumbe.
const CAVE_IN_FOCUS := 0.7

var _session: CollectionSession
var _sfx: CollectionSfx
var _demo: CollectionDemo
var _demo_tag: int = -1
var _frame: Control
var _look: CollectionDraw.Look = CollectionDraw.Look.new()
var _done_text: String = ""
var _done_left: float = 0.0
var _slide: float = 0.0
var _demo_car: Vector2 = Vector2.ZERO


func _init(session: CollectionSession, sfx: CollectionSfx) -> void:
    _session = session
    _sfx = sfx
    _look.rock_scale = DEMO_ROCK_SCALE
    _look.fall_time = DEMO_FALL_TIME


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame = Control.new()
    _frame.position = Vector2(PADDING, 44)
    _frame.size = Vector2(size.x - 2.0 * PADDING, FRAME_HEIGHT)
    _frame.clip_contents = true
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _frame.draw.connect(_draw_demo)
    add_child(_frame)


## Felicita por un paso cumplido (se ve un momento encima de la tarjeta).
func celebrate(title: String) -> void:
    _done_text = title
    _done_left = DONE_TIME


func _process(delta: float) -> void:
    _done_left = maxf(0.0, _done_left - delta)
    var step: TutorialSteps.Step = _current_step()
    var is_playing: bool = _session.phase() == CollectionSession.Phase.PLAYING
    visible = is_playing and (step != null or _done_left > 0.0)
    if step == null:
        _slide = 0.0
        return
    _slide = minf(1.0, _slide + delta / SLIDE_TIME)
    if _demo == null or _demo_tag != step.tag:
        _demo_tag = step.tag
        _new_demo()
    elif _demo.step(delta):
        _new_demo()
    _update_heading()
    position.x = get_parent_area_size().x - size.x - 12.0 + (1.0 - _ease(_slide)) * (size.x + 20.0)
    queue_redraw()
    _frame.queue_redraw()


func _draw() -> void:
    var step: TutorialSteps.Step = _current_step()
    var is_cave_in: bool = _session.cave_in_lesson != null
    var border: Color = CAVE_IN_BORDER if is_cave_in else BORDER
    UiDraw.panel(self, Rect2(Vector2.ZERO, size), BACKGROUND, border)
    if step != null and _done_left <= 0.0:
        var lesson: TutorialSteps = _session.active_lesson()
        var label: String = "TUTORIAL" if not is_cave_in else "ATENCIÓN"
        UiDraw.text(self, Vector2(PADDING, 8), label, 11, HINT, true)
        UiDraw.text(self, Vector2(size.x - PADDING - 40, 8), "%d/%d" % [lesson.index + 1, lesson.count()], 11, HINT, true)
        UiDraw.text(self, Vector2(PADDING, 22), step.title, 16, border, true)
        _frame.visible = _done_left <= 0.0
        draw_rect(Rect2(_frame.position, _frame.size).grow(2.0), border, false, 1.5)
        var body_top: float = _frame.position.y + FRAME_HEIGHT + 12.0
        UiDraw.wrapped(self, Vector2(PADDING, body_top), step.body, 14, TEXT, size.x - 2.0 * PADDING)
        UiDraw.text(self, Vector2(PADDING, size.y - 26), "► Hazlo para seguir · ENTER salta", 11, HINT)
    else:
        _frame.visible = false
    if _done_left > 0.0:
        var alpha: float = minf(1.0, _done_left / 0.3)
        UiDraw.panel(self, Rect2(Vector2.ZERO, size), Color(0.04, 0.1, 0.06), Color(DONE, alpha))
        UiDraw.text_centered(self, size.x / 2.0, size.y / 2.0 - 30.0, "✔ ¡BIEN!", 26, Color(DONE, alpha), true)
        UiDraw.text_centered(self, size.x / 2.0, size.y / 2.0 + 10.0, _done_text, 13, Color(TEXT, alpha), true)


## Cámara con zoom que sigue al cochecito sin salirse del área de la demo.
func _draw_demo() -> void:
    _frame.draw_rect(Rect2(Vector2.ZERO, _frame.size), Color(0.03, 0.03, 0.04))
    if _demo == null:
        return
    var view: Vector2 = _frame.size / ZOOM
    var area: Rect2 = CollectionDemo.AREA
    var top_left: Vector2 = _focus() - view / 2.0
    top_left.x = clampf(top_left.x, area.position.x, maxf(area.position.x, area.end.x - view.x))
    top_left.y = clampf(top_left.y, area.position.y, maxf(area.position.y, area.end.y - view.y))
    _frame.draw_set_transform(-top_left * ZOOM, 0.0, Vector2(ZOOM, ZOOM))
    CollectionDraw.board(_frame, _demo.run, _demo.time, _look)
    if _demo.run.tally.total() > 0:
        UiDraw.text(_frame, _demo.run.car + Vector2(-14, -34), "+%d" % _demo.run.tally.total(), 13, BORDER, true)
    _frame.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    UiDraw.text(_frame, Vector2(6, _frame.size.y - 18), "DEMO x%.1f" % ZOOM, 10, Color(BORDER, 0.8), true)


## Mira al cochecito; si hay un derrumbe, se acerca a él para que se vean caer las rocas.
func _focus() -> Vector2:
    var focus: Vector2 = _demo.run.car
    for cave_in: MazeCaveIns.CaveIn in _demo.run.cave_ins.active:
        var rocks: Vector2 = _demo.run.cave_in_rect(cave_in).get_center()
        var lift: float = (1.0 - clampf(cave_in.elapsed() / DEMO_FALL_TIME, 0.0, 1.0)) * RocksDraw.FALL_HEIGHT * DEMO_ROCK_SCALE * 0.5
        focus = focus.lerp(rocks - Vector2(0, lift), CAVE_IN_FOCUS)
    return focus


func _current_step() -> TutorialSteps.Step:
    var lesson: TutorialSteps = _session.active_lesson()
    return null if lesson == null else lesson.current()


func _new_demo() -> void:
    _demo = CollectionDemo.new(_demo_tag as CollectionDemo.Scene)
    _demo.run.cave_in_started.connect(_on_demo_cave_in)
    _demo_car = _demo.run.car


func _update_heading() -> void:
    var moved: Vector2 = _demo.run.car - _demo_car
    if moved.length() > 0.2:
        _look.heading = lerp_angle(_look.heading, moved.angle(), 0.3)
    _demo_car = _demo.run.car


func _on_demo_cave_in(_cave_in: MazeCaveIns.CaveIn) -> void:
    _sfx.play(CollectionSfx.Sound.RUMBLE, DEMO_CRASH_DB)


static func _ease(t: float) -> float:
    return 1.0 - pow(1.0 - t, 3.0)
