class_name StatsPanel
extends RefCounted
## Panel de los 4 aspectos del cohete (durabilidad, empuje, combustible, estabilidad), de 0 a 100, bajo el panel
## del cohete. Con una pieza en la mano (o bajo el ratón) enseña cuánto cambiaría cada aspecto al ponerla.


const PANEL := Rect2(740, 400, 268, 228)
const BAR := Vector2(236, 12)
const COLORS: Dictionary = {
    RocketParts.Stat.DURABILITY: Color(0.95, 0.45, 0.35),
    RocketParts.Stat.THRUST: Color(1.0, 0.72, 0.25),
    RocketParts.Stat.FUEL: Color(0.4, 0.75, 1.0),
    RocketParts.Stat.STABILITY: Color(0.5, 0.95, 0.6),
}
const UP := Color(0.45, 1.0, 0.5)
const DOWN := Color(1.0, 0.4, 0.35)


static func draw(canvas: CanvasItem, build: RocketBuild, preview: int, time: float) -> void:
    UiDraw.panel(canvas, PANEL, PartsPalette.GLASS, PartsPalette.EDGE)
    UiDraw.text(canvas, PANEL.position + Vector2(16, 12), "ASPECTOS", 16, PartsPalette.ACCENT, true)
    var tried: RocketBuild = null
    if preview != -1:
        tried = RocketBuild.new()
        for section: RocketParts.Section in RocketParts.sections():
            var part: int = build.part_at(section)
            if part != -1:
                tried.place(part as RocketParts.Part)
        tried.place(preview as RocketParts.Part)
        UiDraw.text(canvas, PANEL.position + Vector2(110, 15), "con %s" % RocketParts.TITLES[preview], 10, PartsPalette.TEXT)
    var y: float = PANEL.position.y + 46.0
    for stat: RocketParts.Stat in RocketParts.stats():
        var value: int = build.stat(stat)
        var color: Color = COLORS[stat]
        UiDraw.text(canvas, Vector2(PANEL.position.x + 16, y), String(RocketParts.STAT_TITLES[stat]), 12, color, true)
        UiDraw.text(canvas, Vector2(PANEL.position.x + 16, y - 1), str(value), 14, PartsPalette.TEXT, true, HORIZONTAL_ALIGNMENT_RIGHT, BAR.x)
        var bar: Rect2 = Rect2(Vector2(PANEL.position.x + 16, y + 18), BAR)
        UiDraw.bar(canvas, bar, float(value) / 100.0, color, Color(0.08, 0.08, 0.14), Color(color, 0.5))
        if tried != null:
            var next: int = tried.stat(stat)
            var change: int = next - value
            if change != 0:
                var x0: float = bar.position.x + bar.size.x * float(mini(value, next)) / 100.0
                var width: float = bar.size.x * float(absi(change)) / 100.0
                var pulse: float = 0.6 + 0.4 * sin(time * 8.0)
                canvas.draw_rect(Rect2(x0, bar.position.y, width, bar.size.y), Color(UP if change > 0 else DOWN, 0.75 * pulse))
                UiDraw.text(canvas, Vector2(PANEL.position.x + 16, y - 1), "%+d   " % change, 12, UP if change > 0 else DOWN, true, HORIZONTAL_ALIGNMENT_RIGHT, BAR.x - 24.0)
        y += 44.0
