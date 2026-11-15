class_name DuoLevelSelect
extends Control
## Elección de dificultad de la recolección a dos, justo antes de conducir: de fondo el laberinto del nivel
## marcado y encima tres tarjetas. ←/→ o 1/2/3 eligen, ENTER (o clic) empieza, Esc sale al menú.


signal chosen(level: CollectionLevel.Level)
signal exit_requested

const LEVELS: Array[CollectionLevel.Level] = [
    CollectionLevel.Level.EASY,
    CollectionLevel.Level.MEDIUM,
    CollectionLevel.Level.HARD,
]
const CARD_SIZE := Vector2(200, 150)
const CARD_GAP := 18.0
const TEXT := Color(0.92, 0.92, 0.9)
const HINT := Color(0.62, 0.62, 0.64)

var _index: int = 0
var _previews: Dictionary = {}
var _look: DuoDraw.Look = DuoDraw.Look.new()
var _time: float = 0.0


func _init(start_level: CollectionLevel.Level) -> void:
    _index = LEVELS.find(start_level)


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for level: CollectionLevel.Level in LEVELS:
        _previews[level] = DuoRun.new(DuoLevel.new(level), 1)


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
        return
    for i: int in LEVELS.size():
        if _card_rect(i).has_point(click.position):
            _index = i
            chosen.emit(LEVELS[_index])


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_LEFT, KEY_A, KEY_J:
            _index = maxi(0, _index - 1)
        KEY_RIGHT, KEY_D, KEY_L:
            _index = mini(LEVELS.size() - 1, _index + 1)
        KEY_1, KEY_2, KEY_3:
            _index = key.keycode - KEY_1
            chosen.emit(LEVELS[_index])
        KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
            chosen.emit(LEVELS[_index])
        KEY_ESCAPE:
            exit_requested.emit()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), DuoScreen.BACKGROUND)
    DuoDraw.board(self, _previews[LEVELS[_index]] as DuoRun, _time, _look)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.58))
    UiDraw.text_centered(self, size.x / 2.0, 92, "RECOLECCIÓN A DOS", 34, DuoScreen.ACCENT, true)
    UiDraw.text_centered(self, size.x / 2.0, 140, "Jugador 1 (WASD) entra por la izquierda · Jugador 2 (IJKL) por la derecha", 15, TEXT)
    for i: int in LEVELS.size():
        _draw_card(i)
    UiDraw.text_centered(self, size.x / 2.0, size.y - 120, "Juntos deben recoger el mínimo de menas para abrir la rampa", 14, TEXT)
    UiDraw.text_centered(self, size.x / 2.0, size.y - 92, "←/→ o 1/2/3: elegir    ENTER: conducir    Esc: menú", 14, HINT, true)


func _draw_card(i: int) -> void:
    var level: CollectionLevel.Level = LEVELS[i]
    var data: DuoLevel = DuoLevel.new(level)
    var rect: Rect2 = _card_rect(i)
    var color: Color = LevelSelect.COLORS[level]
    var is_selected: bool = i == _index
    var pulse: float = 0.5 + 0.5 * sin(_time * 5.0)
    if is_selected:
        draw_rect(rect.grow(4.0 + 3.0 * pulse), Color(color, 0.15))
    UiDraw.panel(self, rect, Color(0.06, 0.06, 0.08, 0.95), color if is_selected else Color(color, 0.35))
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 14, "%d · %s" % [i + 1, data.title()], 20, color, true)
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 46, "%d × %d" % [data.size.x, data.size.y], 15, TEXT, true)
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 72, "Mínimo: %d menas" % data.minimum, 13, HINT)
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 92, "Derrumbe: %d pasos" % data.passages_per_cave_in, 13, HINT)
    for k: int in data.passages_per_cave_in:
        var x: float = rect.get_center().x - float(data.passages_per_cave_in - 1) * 7.0 + float(k) * 14.0
        draw_circle(Vector2(x, rect.end.y - 18), 5.0, Color(RocksDraw.ROCK, 0.9 if is_selected else 0.5))


func _card_rect(i: int) -> Rect2:
    var total: float = float(LEVELS.size()) * CARD_SIZE.x + float(LEVELS.size() - 1) * CARD_GAP
    var left: float = size.x / 2.0 - total / 2.0 + float(i) * (CARD_SIZE.x + CARD_GAP)
    return Rect2(Vector2(left, size.y / 2.0 - CARD_SIZE.y / 2.0 + 10.0), CARD_SIZE)
