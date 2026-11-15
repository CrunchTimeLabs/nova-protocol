class_name UnlockStrip
extends Control
## Franja de abajo (ancho completo): el mínimo de metales y las piezas de cohete desbloqueadas (pixel art). Cada
## desbloqueo salta en grande al centro: «¡DESBLOQUEADO! Motor triple».


const HEIGHT := 92.0
const POPUP_TIME := 2.4

var run: SmelterRun
var _time: float = 0.0
var _popups: Array[Dictionary] = []


func setup(p_run: SmelterRun) -> void:
    run = p_run
    run.part_unlocked.connect(_on_unlocked)


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
    _time += delta
    for popup: Dictionary in _popups.duplicate():
        if _time - float(popup["at"]) > POPUP_TIME:
            _popups.erase(popup)
    queue_redraw()


func _on_unlocked(part: RocketParts.Part) -> void:
    _popups.append({"part": part, "at": _time})


func _draw() -> void:
    var strip: Rect2 = Rect2(0, size.y - HEIGHT, size.x, HEIGHT)
    draw_rect(strip, Color(0.04, 0.025, 0.02, 0.95))
    draw_rect(Rect2(strip.position, Vector2(strip.size.x, 2)), FoundryArt.TITLE)
    var metals: int = run.total_metals()
    var reached: bool = metals >= SmelterRun.MINIMUM
    UiDraw.text(self, strip.position + Vector2(14, 10), "MÍNIMO", 12, FoundryArt.MUTED, true)
    UiDraw.text(self, strip.position + Vector2(14, 28), "%d / %d" % [mini(metals, SmelterRun.MINIMUM), SmelterRun.MINIMUM], 26, FoundryArt.GOOD if reached else FoundryArt.TITLE, true)
    UiDraw.text(self, strip.position + Vector2(14, 64), "metales", 11, FoundryArt.MUTED)
    UiDraw.text(self, strip.position + Vector2(126, 10), "PIEZAS DESBLOQUEADAS — cada metal extra = una pieza para el cohete", 12, FoundryArt.MUTED, true)
    var x: float = strip.position.x + 126.0
    for index: int in RocketParts.UNLOCK_ORDER.size():
        var part: RocketParts.Part = RocketParts.UNLOCK_ORDER[index]
        var slot: Rect2 = Rect2(x + float(index) * 80.0, strip.position.y + 28, 72, 58)
        var has_it: bool = run.unlocked.has(part)
        draw_rect(slot, Color(0.1, 0.07, 0.06, 0.9) if has_it else Color(0.08, 0.06, 0.05, 0.6))
        draw_rect(slot, Color(FoundryArt.TITLE, 0.8) if has_it else Color(0.3, 0.25, 0.22, 0.6), false, 1.5)
        var texture: Texture2D = RocketView.part_texture(part)
        var scale: float = minf(66.0 / float(texture.get_width()), 52.0 / float(texture.get_height()))
        var shown: Vector2 = Vector2(texture.get_size()) * scale
        var tint: Color = Color.WHITE if has_it else Color(0, 0, 0, 0.55)
        draw_texture_rect(texture, Rect2(slot.get_center() - shown / 2.0, shown), false, tint)
        if not has_it:
            UiDraw.text_centered(self, slot.get_center().x, slot.get_center().y - 8, "?", 16, Color(0.6, 0.5, 0.45, 0.8), true)
    for popup: Dictionary in _popups:
        _draw_popup(popup)


func _draw_popup(popup: Dictionary) -> void:
    var t: float = (_time - float(popup["at"])) / POPUP_TIME
    var alpha: float = clampf(minf(t / 0.12, (1.0 - t) / 0.2), 0.0, 1.0)
    var pop: float = 1.0 + 0.25 * maxf(0.0, 1.0 - t * 6.0)
    var part: RocketParts.Part = popup["part"]
    var center: Vector2 = Vector2(size.x / 2.0, size.y / 2.0 - 30.0)
    var box: Rect2 = Rect2(center - Vector2(260, 130) * pop, Vector2(520, 260) * pop)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35 * alpha))
    UiDraw.panel(self, box, Color(0.08, 0.05, 0.02, 0.96 * alpha), Color(FoundryArt.TITLE, alpha))
    for i: int in 12:
        var angle: float = float(i) / 12.0 * TAU + _time
        draw_line(center + Vector2.from_angle(angle) * 70.0, center + Vector2.from_angle(angle) * (100.0 + 20.0 * sin(_time * 6.0 + float(i))), Color(FoundryArt.TITLE, 0.35 * alpha), 3.0)
    var texture: Texture2D = RocketView.part_texture(part)
    var shown: Vector2 = Vector2(texture.get_size()) * 3.0
    draw_texture_rect(texture, Rect2(center - shown / 2.0 - Vector2(140, 0), shown), false, Color(1, 1, 1, alpha))
    UiDraw.text(self, Vector2(center.x - 50, center.y - 50), "¡DESBLOQUEADO!", 30, Color(FoundryArt.TITLE, alpha), true)
    UiDraw.text(self, Vector2(center.x - 50, center.y), String(RocketParts.TITLES[part]), 24, Color(FoundryArt.TEXT, alpha), true)
    UiDraw.text(self, Vector2(center.x - 50, center.y + 36), "Para tu cohete · %s" % RocketParts.SECTION_TITLES[RocketParts.section_of(part)], 13, Color(FoundryArt.MUTED, alpha))
