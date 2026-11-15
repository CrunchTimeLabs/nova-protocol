class_name SmelterStyle
extends RefCounted
## Paleta y piezas de dibujo compartidas por las dos mitades de la fundición a dos (arte de la fundición).


const J1 := Color(0.98, 0.76, 0.2)
const J2 := Color(0.3, 0.78, 1.0)
const HALF := Vector2(512, 548)
const TOP := 44.0


## Fondo de una mitad: el interior de la fundición (x4) desplazado a la parte que toca, más el vidrio.
static func backdrop(canvas: CanvasItem, offset_x: float, time: float) -> void:
    var background: Texture2D = FoundryArt.texture(FoundryArt.BACKGROUND)
    canvas.draw_texture_rect(background, Rect2(Vector2(-offset_x, 0), background.get_size() * 4.0), false)
    canvas.draw_rect(Rect2(Vector2.ZERO, HALF), Color(0.03, 0.015, 0.01, 0.35))
    var flicker: float = 0.5 + 0.25 * sin(time * 7.0) + 0.25 * sin(time * 13.3)
    canvas.draw_circle(Vector2(512 - offset_x, 84), 60.0 + 8.0 * flicker, Color(1.0, 0.5, 0.15, 0.05 + 0.05 * flicker))


static func top_bar(canvas: CanvasItem, player: int, title: String, keys: String) -> void:
    var color: Color = J1 if player == 1 else J2
    canvas.draw_rect(Rect2(0, 0, HALF.x, TOP), Color(0.04, 0.02, 0.02, 0.88))
    canvas.draw_rect(Rect2(0, TOP - 3, HALF.x, 3), color)
    UiDraw.text(canvas, Vector2(12, 11), "J%d" % player, 18, color, true)
    UiDraw.text(canvas, Vector2(48, 13), title, 15, FoundryArt.TITLE, true)
    UiDraw.text(canvas, Vector2(HALF.x - 12 - UiDraw.font(true).get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, 15), keys, 13, FoundryArt.MUTED, true)


static func ore(canvas: CanvasItem, which: Ores.Ore, center: Vector2, scale: float, tint: Color = Color.WHITE) -> void:
    var size: float = 24.0 * scale
    canvas.draw_rect(Rect2(center.x - size * 0.36, center.y + size * 0.36, size * 0.72, scale * 2.0), Color(0, 0, 0, 0.35 * tint.a))
    canvas.draw_texture_rect(Ores.texture(which), Rect2(center - Vector2(size, size) / 2.0, Vector2(size, size)), false, tint)
