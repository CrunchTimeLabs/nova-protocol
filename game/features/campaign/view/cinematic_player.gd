class_name CinematicPlayer
extends Control
## Reproduce una cinemática de `Cinematics`: cuadros de pixel art (x4, nearest) a 12 fps, entrada y salida
## desde negro, subtítulos cortos abajo y etiquetas sobre la imagen. ENTER o ESPACIO la saltan.
## Emite `finished` una sola vez (al acabar o al saltar).


signal finished

const FADE := 0.5
const HOLD := 0.4
const SUBTITLE_FADE := 0.25
const BAND := Color(0, 0, 0, 0.55)
const SUBTITLE := Color(1.0, 0.95, 0.85)
const HINT := Color(0.8, 0.8, 0.85, 0.6)

var _id: Cinematics.Id
var _frames: Array[Texture2D] = []
var _time: float = 0.0
var _is_done: bool = false


func _init(id: Cinematics.Id) -> void:
    _id = id


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    for index: int in Cinematics.frame_count(_id):
        _frames.append(load(Cinematics.frame_path(_id, index)) as Texture2D)


func _process(delta: float) -> void:
    _time += delta
    if _time >= Cinematics.duration(_id) + HOLD:
        _finish()
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key != null and key.pressed and not key.echo and key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
        _finish()


func _finish() -> void:
    if _is_done:
        return
    _is_done = true
    finished.emit()


func _image_rect() -> Rect2:
    var image: Vector2 = Vector2(256, 160)
    var scale: float = minf(size.x / image.x, size.y / image.y)
    var shown: Vector2 = image * scale
    return Rect2((size - shown) / 2.0, shown)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
    if _frames.is_empty():
        return
    var index: int = clampi(int(_time * Cinematics.FPS), 0, _frames.size() - 1)
    var rect: Rect2 = _image_rect()
    draw_texture_rect(_frames[index], rect, false)
    _draw_labels(rect)
    _draw_subtitle(rect)
    var total: float = Cinematics.duration(_id) + HOLD
    var fade: float = maxf(1.0 - _time / FADE, (_time - (total - FADE)) / FADE)
    if fade > 0.0:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf(fade, 0.0, 1.0)))
    UiDraw.text(self, Vector2(size.x - 160, size.y - 26), "ENTER: saltar", 12, HINT, true)


func _draw_subtitle(rect: Rect2) -> void:
    var entry: Array = Cinematics.subtitle_at(_id, _time)
    if entry.is_empty():
        return
    var alpha: float = clampf(minf(_time - float(entry[0]), float(entry[1]) - _time) / SUBTITLE_FADE, 0.0, 1.0)
    var text: String = str(entry[2])
    var font_size: int = 26
    var width: float = UiDraw.font(true).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var band: Rect2 = Rect2(size.x / 2.0 - width / 2.0 - 24.0, rect.end.y - 84.0, width + 48.0, 50.0)
    draw_rect(band, Color(BAND, BAND.a * alpha))
    UiDraw.text_centered(self, size.x / 2.0, band.position.y + 10.0, text, font_size, Color(SUBTITLE, alpha), true)


func _draw_labels(rect: Rect2) -> void:
    for entry: Array in Cinematics.DATA[_id]["labels"]:
        if _time < float(entry[0]) or _time >= float(entry[1]):
            continue
        var alpha: float = clampf((_time - float(entry[0])) / 0.3, 0.0, 1.0)
        var at: Vector2 = rect.position + (entry[3] as Vector2) * rect.size
        var color: Color = entry[4]
        var rise: float = (1.0 - alpha) * 10.0
        UiDraw.text_centered(self, at.x + 2.0, at.y + 2.0 + rise, str(entry[2]), 28, Color(0, 0, 0, 0.7 * alpha), true)
        UiDraw.text_centered(self, at.x, at.y + rise, str(entry[2]), 28, Color(color, alpha), true)
