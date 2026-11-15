class_name SmelterOverlay
extends Control
## Capa de arriba de la fundición a dos: la línea que separa las mitades, la cuenta atrás al terminar los dos
## tutoriales y el resumen final (metales por elemento, piezas ganadas, si se llegó al mínimo).


var run: SmelterRun
## Segundos de cuenta atrás que quedan (< 0: ninguna).
var countdown: float = -1.0
var _time: float = 0.0
var _ended_at: float = -1.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
    _time += delta
    if run != null and run.is_finished and _ended_at < 0.0:
        _ended_at = _time
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(511, 0, 2, SmelterStyle.HALF.y), Color(0, 0, 0, 0.8))
    if countdown > 0.0:
        var number: int = ceili(countdown)
        var beat: float = fmod(countdown, 1.0)
        var text: String = str(number) if number > 0 else ""
        var center: Vector2 = Vector2(512, 260)
        draw_circle(center, 90.0, Color(0.03, 0.02, 0.02, 0.85))
        draw_arc(center, 90.0, -PI / 2.0, -PI / 2.0 + TAU * beat, 48, FoundryArt.TITLE, 5.0)
        UiDraw.text_centered(self, center.x, center.y - 60.0, text, 96, FoundryArt.TITLE, true)
        UiDraw.text_centered(self, center.x, center.y + 104.0, "¡PREPÁRENSE PARA FUNDIR!", 18, FoundryArt.TEXT, true)
    if run != null and run.is_finished:
        _draw_results()


func _draw_results() -> void:
    var t: float = clampf((_time - _ended_at) / 0.5, 0.0, 1.0)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7 * t))
    var box: Rect2 = Rect2(212, 70 + 20.0 * (1.0 - t), 600, 440)
    var passed: bool = run.has_passed()
    UiDraw.panel(self, box, Color(0.08, 0.045, 0.035, 0.97 * t), Color(FoundryArt.TITLE if passed else FoundryArt.DANGER, t))
    var cx: float = box.get_center().x
    UiDraw.text_centered(self, cx, box.position.y + 20, "¡FUNDICIÓN TERMINADA!" if passed else "NO LLEGARON AL MÍNIMO", 28, Color(FoundryArt.TITLE if passed else FoundryArt.DANGER, t), true)
    UiDraw.text_centered(self, cx, box.position.y + 60, "Metales puros: %d (mínimo %d)" % [run.total_metals(), SmelterRun.MINIMUM], 15, Color(FoundryArt.TEXT, t))
    var column: float = box.size.x / 5.0
    for index: int in Ores.all().size():
        var ore: Ores.Ore = Ores.all()[index]
        var x: float = box.position.x + column * (float(index) + 0.5)
        SmelterStyle.ore(self, ore, Vector2(x, box.position.y + 120), 2.2, Color(1, 1, 1, t))
        UiDraw.text_centered(self, x, box.position.y + 154, str(int(run.metals[ore])), 26, Color(Ores.color(ore), t), true)
        UiDraw.text_centered(self, x, box.position.y + 188, Ores.element(ore).to_upper(), 11, Color(FoundryArt.MUTED, t), true)
    UiDraw.text_centered(self, cx, box.position.y + 228, "Piezas desbloqueadas: %d" % run.unlocked.size(), 18, Color(FoundryArt.TITLE, t), true)
    var x0: float = cx - float(run.unlocked.size()) * 26.0
    for index: int in run.unlocked.size():
        var texture: Texture2D = RocketView.part_texture(run.unlocked[index])
        var scale: float = minf(48.0 / float(texture.get_width()), 70.0 / float(texture.get_height()))
        var shown: Vector2 = Vector2(texture.get_size()) * scale
        draw_texture_rect(texture, Rect2(Vector2(x0 + float(index) * 52.0, box.position.y + 262), shown), false, Color(1, 1, 1, t))
    var hint: String = "ENTER: armar el cohete →" if passed else "ENTER: intentarlo otra vez"
    UiDraw.text_centered(self, cx, box.end.y - 60, "Más rápido y coordinados = más piezas" if passed else "Fundan al menos %d metales" % SmelterRun.MINIMUM, 13, Color(FoundryArt.MUTED, t))
    UiDraw.text_centered(self, cx, box.end.y - 34, hint, 17, Color(FoundryArt.GOOD if passed else FoundryArt.TEXT, t), true)
