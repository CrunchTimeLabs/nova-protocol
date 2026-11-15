class_name PartsPalette
extends RefCounted
## Paleta de piezas a la izquierda: una fila por sección con su título simple y una tarjeta por pieza.
## Solo calcula dónde va cada tarjeta y la dibuja; el arrastre lo decide la pantalla.


const PANEL := Rect2(16, 68, 268, 560)
const PADDING := 12.0
const HEADER := 18.0
const CARD := Vector2(76, 78)
const GAP := 8.0
const ROW_SPACING := 10.0
const SPRITE_BOX := Vector2(64, 48)
const GLASS := Color(0.03, 0.03, 0.09, 0.8)
const EDGE := Color(0.6, 0.75, 1.0, 0.35)
const ACCENT := Color(0.98, 0.78, 0.3)
const TEXT := Color(0.88, 0.9, 1.0)
const CARD_FILL := Color(0.1, 0.11, 0.2, 0.9)
const CARD_HOVER := Color(0.16, 0.18, 0.32, 0.95)
const IN_USE := Color(0.45, 0.9, 0.55)


## Rectángulo de la tarjeta de cada pieza (Part -> Rect2).
static func card_rects() -> Dictionary:
    var rects: Dictionary = {}
    var y: float = PANEL.position.y + PADDING
    for section: RocketParts.Section in RocketParts.sections():
        y += HEADER
        var parts: Array[RocketParts.Part] = RocketParts.parts_of(section)
        for i: int in parts.size():
            var x: float = PANEL.position.x + PADDING + float(i) * (CARD.x + GAP)
            rects[parts[i]] = Rect2(Vector2(x, y), CARD)
        y += CARD.y + ROW_SPACING
    return rects


## Pieza bajo `point` o -1.
static func part_at(point: Vector2) -> int:
    var rects: Dictionary = card_rects()
    for part: int in rects.keys():
        if (rects[part] as Rect2).has_point(point):
            return part
    return -1


static func draw(canvas: CanvasItem, build: RocketBuild, hover: int, dragging: int) -> void:
    UiDraw.panel(canvas, PANEL, GLASS, EDGE)
    var rects: Dictionary = card_rects()
    for section: RocketParts.Section in RocketParts.sections():
        var first: Rect2 = rects[RocketParts.parts_of(section)[0]]
        UiDraw.text(canvas, Vector2(first.position.x, first.position.y - HEADER + 2.0), String(RocketParts.SECTION_TITLES[section]).to_upper(), 11, ACCENT, true)
    for part: int in rects.keys():
        _card(canvas, rects[part], part as RocketParts.Part, part == hover, build.part_at(RocketParts.section_of(part as RocketParts.Part)) == part, part == dragging)


static func _card(canvas: CanvasItem, rect: Rect2, part: RocketParts.Part, is_hover: bool, is_in_use: bool, is_dragging: bool) -> void:
    canvas.draw_rect(rect, CARD_HOVER if is_hover else CARD_FILL)
    canvas.draw_rect(rect, IN_USE if is_in_use else (ACCENT if is_hover else EDGE), false, 2.0 if is_in_use or is_hover else 1.0)
    var texture: Texture2D = RocketView.part_texture(part)
    var size: Vector2 = Vector2(texture.get_width(), texture.get_height())
    var fit: float = floorf(minf(SPRITE_BOX.x / size.x, SPRITE_BOX.y / size.y) * 4.0) / 4.0
    var drawn: Vector2 = size * fit
    var box_center: Vector2 = Vector2(rect.get_center().x, rect.position.y + 6.0 + SPRITE_BOX.y / 2.0)
    var alpha: float = 0.35 if is_dragging else 1.0
    canvas.draw_texture_rect(texture, Rect2(box_center - drawn / 2.0, drawn), false, Color(1, 1, 1, alpha))
    var title: String = String(RocketParts.TITLES[part])
    var font: Font = UiDraw.font()
    canvas.draw_multiline_string(
            font,
            Vector2(rect.position.x + 2.0, rect.end.y - 20.0 + font.get_ascent(9)),
            title,
            HORIZONTAL_ALIGNMENT_CENTER,
            rect.size.x - 4.0,
            9,
            2,
            TEXT,
            )
    if is_in_use:
        canvas.draw_circle(rect.position + Vector2(rect.size.x - 9, 9), 5.0, IN_USE)
