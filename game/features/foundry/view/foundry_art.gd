class_name FoundryArt
extends RefCounted
## Paleta e imágenes pixel art de la fundición (minerales, reloj de arena, fondo) y el color de las barras.


const DIR := "res://assets/foundry/"
const BACKGROUND := DIR + "foundry_hall.png"
const HOURGLASS := DIR + "hourglass.png"
const MINERAL_FILES: Dictionary = {
    FoundryRun.Mineral.IRON: "mineral_iron.png",
    FoundryRun.Mineral.COPPER: "mineral_copper.png",
    FoundryRun.Mineral.GOLD: "mineral_gold.png",
}
const COLORS: Dictionary = {
    FoundryRun.Mineral.IRON: Color(0.75, 0.8, 0.88),
    FoundryRun.Mineral.COPPER: Color(0.95, 0.55, 0.3),
    FoundryRun.Mineral.GOLD: Color(1.0, 0.82, 0.25),
}
const RARITY: Dictionary = {
    FoundryRun.Mineral.IRON: "Intermedio",
    FoundryRun.Mineral.COPPER: "Común",
    FoundryRun.Mineral.GOLD: "Raro",
}
## Orden en el almacén y en el resumen: del más valioso al menos.
const ORDER: Array[FoundryRun.Mineral] = [FoundryRun.Mineral.GOLD, FoundryRun.Mineral.IRON, FoundryRun.Mineral.COPPER]
const MINERAL_SIZE := 24.0

const GLASS := Color(0.07, 0.045, 0.04, 0.82)
const EDGE := Color(0.85, 0.5, 0.2, 0.55)
const TITLE := Color(1.0, 0.72, 0.3)
const TEXT := Color(0.96, 0.9, 0.82)
const MUTED := Color(0.72, 0.62, 0.55)
const GOOD := Color(0.4, 0.95, 0.5)
const DANGER := Color(1.0, 0.35, 0.28)
const BAR_GREEN := Color(0.3, 0.9, 0.4)
const BAR_YELLOW := Color(1.0, 0.85, 0.2)
const BAR_RED := Color(1.0, 0.25, 0.2)

static var _textures: Dictionary = {}


static func texture(path: String) -> Texture2D:
    if not _textures.has(path):
        _textures[path] = load(path) as Texture2D
    return _textures[path]


static func mineral_texture(mineral: FoundryRun.Mineral) -> Texture2D:
    return texture(DIR + String(MINERAL_FILES[mineral]))


static func color(mineral: FoundryRun.Mineral) -> Color:
    return COLORS[mineral]


## Mineral centrado en `center` a `scale` (24 px x scale), con sombra suave debajo.
static func draw_mineral(
        canvas: CanvasItem,
        mineral: FoundryRun.Mineral,
        center: Vector2,
        scale: float,
        tint: Color = Color.WHITE,
        ) -> void:
    var size: float = MINERAL_SIZE * scale
    canvas.draw_rect(
            Rect2(center.x - size * 0.36, center.y + size * 0.36, size * 0.72, scale * 2.0),
            Color(0, 0, 0, 0.35 * tint.a),
            )
    canvas.draw_texture_rect(mineral_texture(mineral), Rect2(center - Vector2(size, size) / 2.0, Vector2(size, size)), false, tint)


## Verde con tiempo de sobra, amarillo con tiempo justo, rojo al final; pasa de uno a otro poco a poco.
static func timer_color(ratio: float) -> Color:
    if ratio > 0.5:
        return BAR_YELLOW.lerp(BAR_GREEN, clampf((ratio - 0.5) / 0.25, 0.0, 1.0))
    return BAR_RED.lerp(BAR_YELLOW, clampf((ratio - 0.2) / 0.2, 0.0, 1.0))


static func panel(canvas: CanvasItem, rect: Rect2, alpha: float = 1.0) -> void:
    UiDraw.panel(canvas, rect, Color(GLASS, GLASS.a * alpha), Color(EDGE, EDGE.a * alpha))
    canvas.draw_line(rect.position + Vector2(2, 2), Vector2(rect.end.x - 2, rect.position.y + 2), Color(TITLE, 0.35 * alpha), 2.0)
