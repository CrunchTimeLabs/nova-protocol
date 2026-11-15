class_name LevelSelect
extends Control
## Elección de dificultad dentro del nivel, justo antes de conducir: se ve el laberinto del nivel marcado
## (vista previa) y encima tres tarjetas. ←/→ o 1/2/3 eligen, ENTER (o clic) empieza, Esc sale al menú.


signal chosen(level: CollectionLevel.Level)
signal exit_requested

const LEVELS: Array[CollectionLevel.Level] = [
    CollectionLevel.Level.EASY,
    CollectionLevel.Level.MEDIUM,
    CollectionLevel.Level.HARD,
]
const DETAILS: Dictionary = {
    CollectionLevel.Level.EASY: "Laberinto pequeño\nTapa 2 pasos, 8–14 s",
    CollectionLevel.Level.MEDIUM: "Laberinto mediano\nTapa 4 pasos, 10–18 s",
    CollectionLevel.Level.HARD: "Laberinto grande\nTapa 6 pasos, 12–22 s",
}
const COLORS: Dictionary = {
    CollectionLevel.Level.EASY: Color(0.35, 0.9, 0.45),
    CollectionLevel.Level.MEDIUM: Color(0.98, 0.78, 0.25),
    CollectionLevel.Level.HARD: Color(0.95, 0.35, 0.28),
}
const CARD_SIZE := Vector2(190, 150)
const CARD_GAP := 18.0
const TEXT := Color(0.92, 0.92, 0.9)
const HINT := Color(0.6, 0.6, 0.62)
const PREVIEW_SEED := 1

var _index: int = 0
var _previews: Dictionary = {}       # Level -> CollectionRun
var _look: CollectionDraw.Look = CollectionDraw.Look.new()
var _time: float = 0.0


func _init(start_level: CollectionLevel.Level) -> void:
    _index = LEVELS.find(start_level)


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for level: CollectionLevel.Level in LEVELS:
        var data: CollectionLevel = CollectionLevel.new(level)
        var preview: CollectionRun = CollectionRun.new(CollectionScreen.board_origin(data), data, PREVIEW_SEED)
        preview.has_random_events = false
        _previews[level] = preview


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
        KEY_LEFT, KEY_A:
            _index = maxi(0, _index - 1)
        KEY_RIGHT, KEY_D:
            _index = mini(LEVELS.size() - 1, _index + 1)
        KEY_1, KEY_2, KEY_3:
            _index = key.keycode - KEY_1
            chosen.emit(LEVELS[_index])
        KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
            chosen.emit(LEVELS[_index])
        KEY_ESCAPE:
            exit_requested.emit()


func _draw() -> void:
    var level: CollectionLevel.Level = LEVELS[_index]
    var preview: CollectionRun = _previews[level]
    draw_rect(Rect2(Vector2.ZERO, size), CollectionScreen.BACKGROUND)
    _look.car_scale = preview.cell_size / CollectionScreen.REFERENCE_CELL
    CollectionDraw.board(self, preview, _time, _look)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
    UiDraw.text_centered(self, size.x / 2.0, 120, "RECOLECCIÓN", 34, CollectionScreen.ACCENT, true)
    UiDraw.text_centered(self, size.x / 2.0, 168, "Elige la dificultad antes de conducir", 16, TEXT)
    for i: int in LEVELS.size():
        _draw_card(i)
    var rhythm: String = "Cada %d s de juego: %d %% de que caiga un derrumbe" % [
            int(CollectionLevel.CAVE_IN_WINDOW),
            int(CollectionLevel.CAVE_IN_CHANCE * 100.0),
            ]
    UiDraw.text_centered(self, size.x / 2.0, size.y - 150, rhythm, 14, TEXT)
    UiDraw.text_centered(self, size.x / 2.0, size.y - 120, "←/→ o 1/2/3: elegir    ENTER: conducir    Esc: menú", 14, HINT, true)


func _draw_card(i: int) -> void:
    var level: CollectionLevel.Level = LEVELS[i]
    var data: CollectionLevel = CollectionLevel.new(level)
    var rect: Rect2 = _card_rect(i)
    var color: Color = COLORS[level]
    var is_selected: bool = i == _index
    var pulse: float = 0.5 + 0.5 * sin(_time * 5.0)
    if is_selected:
        draw_rect(rect.grow(4.0 + 3.0 * pulse), Color(color, 0.15))
    UiDraw.panel(self, rect, Color(0.06, 0.06, 0.08, 0.95), color if is_selected else Color(color, 0.35))
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 14, "%d · %s" % [i + 1, data.title()], 20, color, true)
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 46, "%d × %d" % [data.size.x, data.size.y], 14, TEXT, true)
    var lines: PackedStringArray = String(DETAILS[level]).split("\n")
    for k: int in lines.size():
        UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 72 + float(k) * 20.0, lines[k], 13, HINT)
    for k: int in data.passages_per_cave_in:
        var x: float = rect.get_center().x - float(data.passages_per_cave_in - 1) * 8.0 + float(k) * 16.0
        draw_circle(Vector2(x, rect.end.y - 20), 6.0, Color(RocksDraw.ROCK, 0.9 if is_selected else 0.5))


func _card_rect(i: int) -> Rect2:
    var total: float = float(LEVELS.size()) * CARD_SIZE.x + float(LEVELS.size() - 1) * CARD_GAP
    var left: float = size.x / 2.0 - total / 2.0 + float(i) * (CARD_SIZE.x + CARD_GAP)
    return Rect2(Vector2(left, size.y / 2.0 - CARD_SIZE.y / 2.0 + 20.0), CARD_SIZE)
