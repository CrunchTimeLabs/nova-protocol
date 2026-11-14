class_name PrecisionOverlay
extends Control
## Extracción de precisión sobre el laberinto: una broca oscila y ESPACIO la detiene.
## Avisa con `resolved(multiplicador, nota)` cuando termina de mostrar el resultado.


signal resolved(multiplier: float, grade: PrecisionStop.Grade)

const BAR := Rect2(320, 400, 640, 56)
const ZONE_COLORS: Dictionary = {
    PrecisionStop.Grade.PERFECT: UiPalette.OK,
    PrecisionStop.Grade.VERY_GOOD: Color(0.78, 0.78, 0.78),
    PrecisionStop.Grade.ACCEPTABLE: UiPalette.WARNING,
    PrecisionStop.Grade.POOR: Color(0.65, 0.65, 0.65),
    PrecisionStop.Grade.FAILED: UiPalette.DANGER,
}
const GRADE_NAMES: Dictionary = {
    PrecisionStop.Grade.PERFECT: "EXTRACCIÓN PERFECTA",
    PrecisionStop.Grade.VERY_GOOD: "MUY BUENA",
    PrecisionStop.Grade.ACCEPTABLE: "ACEPTABLE",
    PrecisionStop.Grade.POOR: "POBRE",
    PrecisionStop.Grade.FAILED: "FALLIDA",
}

var drill: PrecisionStop
var _vein: MazeRun.Vein
var _sfx: Sfx
var _was_resolved: bool = false


func _init(vein: MazeRun.Vein, previous_uses: int, sfx: Sfx) -> void:
    _vein = vein
    _sfx = sfx
    drill = PrecisionStop.new(previous_uses)
    size = UiPalette.SCREEN
    mouse_filter = Control.MOUSE_FILTER_STOP


static func grade_name(grade: PrecisionStop.Grade) -> String:
    return String(GRADE_NAMES[grade])


static func grade_color(grade: PrecisionStop.Grade) -> Color:
    return ZONE_COLORS[grade]


func _process(delta: float) -> void:
    drill.advance(delta)
    if drill.is_finished() and not _was_resolved:
        _was_resolved = true
        resolved.emit(drill.multiplier(), drill.grade())
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key.pressed and not key.echo and key.keycode == KEY_SPACE and not drill.is_stopped():
        get_viewport().set_input_as_handled()
        drill.stop()
        var grade: PrecisionStop.Grade = drill.grade()
        match grade:
            PrecisionStop.Grade.PERFECT:
                _sfx.play(Sfx.Sound.PERFECT)
            PrecisionStop.Grade.VERY_GOOD, PrecisionStop.Grade.ACCEPTABLE:
                _sfx.play(Sfx.Sound.VEIN)
            PrecisionStop.Grade.POOR, PrecisionStop.Grade.FAILED:
                _sfx.play(Sfx.Sound.DENIED)


func _draw() -> void:
    var color: Color = UiPalette.resource_color(_vein.res)
    var name: String = String(Catalog.RES_NAMES[_vein.res]).to_lower()
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.04, 0.86))
    var center_x: float = size.x / 2.0
    UiPalette.text_centered(self, center_x, 230, "EXTRACCIÓN DE PRECISIÓN", UiPalette.TITLE, UiPalette.glow(color, 1.3), true)
    UiPalette.text_centered(self, center_x, 274, "Veta de %s — base %d unidades" % [name, _vein.base], UiPalette.SMALL, UiPalette.GRAY)
    var hint_color: Color = UiPalette.WARNING if not drill.is_stopped() else UiPalette.GRAY
    UiPalette.text_centered(self, center_x, 330, "PULSA ESPACIO PARA DETENER LA BROCA", UiPalette.SUBTITLE, hint_color, true)

    UiPalette.card(self, BAR, Color(0.13, 0.13, 0.13), Color.TRANSPARENT)
    var zones: Array = PrecisionStop.ZONES.duplicate()
    zones.reverse()
    for zone: Array in zones:
        var grade: PrecisionStop.Grade = int(zone[2]) as PrecisionStop.Grade
        if grade == PrecisionStop.Grade.FAILED:
            continue
        var half: float = BAR.size.x * float(zone[0])
        var tint: Color = grade_color(grade)
        if grade == PrecisionStop.Grade.PERFECT:
            tint = UiPalette.glow(tint, 1.5)
        UiPalette.card(self, Rect2(center_x - half, BAR.position.y, 2.0 * half, BAR.size.y), tint, Color.TRANSPARENT)
    UiPalette.card(self, BAR, Color.TRANSPARENT, UiPalette.BORDER)
    draw_line(Vector2(center_x, BAR.position.y - 8), Vector2(center_x, BAR.end.y + 8), Color.WHITE, 1.0)
    for zone: Array in PrecisionStop.ZONES:
        var label_x: float = center_x + BAR.size.x * float(zone[0]) - 24.0
        UiPalette.text(self, Vector2(label_x, BAR.end.y + 12), "x%.1f" % float(zone[1]), UiPalette.TINY, grade_color(int(zone[2]) as PrecisionStop.Grade))

    var marker_x: float = center_x + drill.position() * BAR.size.x / 2.0
    var marker_color: Color = UiPalette.glow(Color.WHITE, 1.4)
    draw_colored_polygon(PackedVector2Array([
            Vector2(marker_x, BAR.position.y - 16),
            Vector2(marker_x - 9, BAR.position.y - 32),
            Vector2(marker_x + 9, BAR.position.y - 32),
            ]), marker_color)
    draw_rect(Rect2(marker_x - 3, BAR.position.y - 6, 6, BAR.size.y + 12), marker_color)

    if drill.is_stopped():
        var grade_now: PrecisionStop.Grade = drill.grade()
        var total: int = int(float(_vein.base) * drill.multiplier())
        UiPalette.text_centered(self, center_x, BAR.end.y + 50, "%s   x%.1f" % [grade_name(grade_now), drill.multiplier()], UiPalette.HUGE, UiPalette.glow(grade_color(grade_now), 1.3), true)
        UiPalette.text_centered(self, center_x, BAR.end.y + 104, "+%d de %s" % [total, name], UiPalette.TITLE, color, true)
