class_name HangarPanel
extends RefCounted
## Panel de la derecha: qué lleva el cohete por sección y el botón de despegue cuando está completo.


const PANEL := Rect2(740, 68, 268, 330)
const BUTTON := Rect2(756, 330, 236, 52)
const ROW := 34.0
const GOOD := Color(0.45, 0.9, 0.55)
const MISSING := Color(0.55, 0.6, 0.75)
const LAUNCH := Color(0.98, 0.45, 0.25)


static func draw(canvas: CanvasItem, build: RocketBuild, time: float, is_button_hover: bool) -> void:
    UiDraw.panel(canvas, PANEL, PartsPalette.GLASS, PartsPalette.EDGE)
    UiDraw.text(canvas, PANEL.position + Vector2(16, 12), "TU COHETE", 16, PartsPalette.ACCENT, true)
    var y: float = PANEL.position.y + 46.0
    var missing: int = 0
    for section: RocketParts.Section in RocketParts.sections():
        var part: int = build.part_at(section)
        var is_set: bool = part != -1
        if not is_set:
            missing += 1
        var dot: Vector2 = Vector2(PANEL.position.x + 22, y + 10)
        if is_set:
            canvas.draw_circle(dot, 6.0, GOOD)
        else:
            canvas.draw_arc(dot, 6.0, 0.0, TAU, 16, MISSING, 1.5)
        UiDraw.text(canvas, Vector2(PANEL.position.x + 36, y), String(RocketParts.SECTION_TITLES[section]), 11, MISSING, true)
        var name: String = String(RocketParts.TITLES[part]) if is_set else "—"
        UiDraw.text(canvas, Vector2(PANEL.position.x + 36, y + 13), name, 12, PartsPalette.TEXT if is_set else MISSING)
        y += ROW
    if missing > 0:
        var label: String = "Falta 1 pieza" if missing == 1 else "Faltan %d piezas" % missing
        UiDraw.text_centered(canvas, BUTTON.get_center().x, BUTTON.position.y + 16, label, 14, MISSING, true)
        return
    var pulse: float = 0.5 + 0.5 * sin(time * 5.0)
    canvas.draw_rect(BUTTON.grow(3.0 + 3.0 * pulse), Color(LAUNCH, 0.18))
    canvas.draw_rect(BUTTON, LAUNCH.lightened(0.15) if is_button_hover else LAUNCH)
    canvas.draw_rect(BUTTON, LAUNCH.lightened(0.5), false, 2.0)
    UiDraw.text_centered(canvas, BUTTON.get_center().x, BUTTON.position.y + 8, "DESPEGAR", 20, Color(0.1, 0.03, 0.02), true)
    UiDraw.text_centered(canvas, BUTTON.get_center().x, BUTTON.position.y + 32, "o pulsa ESPACIO", 10, Color(0.15, 0.05, 0.03))
