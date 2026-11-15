class_name RocketView
extends RefCounted
## Dibujo del cohete apilado con las piezas del pixel art (x1 escaladas): huecos vacíos, piezas y llama.
## Solo lee `RocketBuild`; quien dibuja pone `texture_filter = NEAREST` para que el píxel se vea nítido.


const SLOT_FILL := Color(0.55, 0.75, 1.0, 0.06)
const SLOT_EDGE := Color(0.6, 0.8, 1.0, 0.45)
const SLOT_HOVER := Color(1.0, 0.85, 0.35)
const SLOT_TEXT := Color(0.75, 0.85, 1.0, 0.8)
const DASH := 8.0

static var _textures: Dictionary = {}       # ruta -> Texture2D


static func texture(path: String) -> Texture2D:
    if not _textures.has(path):
        _textures[path] = load(path) as Texture2D
    return _textures[path]


static func part_texture(part: RocketParts.Part) -> Texture2D:
    return texture(RocketParts.texture_path(part))


## Rectángulo en pantalla de una sección del cohete cuya base (abajo, centro) está en `base`.
static func section_rect(section: RocketParts.Section, base: Vector2, scale: float) -> Rect2:
    var top: float = base.y - float(RocketParts.total_height()) * scale + float(RocketParts.section_top(section)) * scale
    var height: float = float(RocketParts.SECTION_HEIGHTS[section]) * scale
    var width: float = float(RocketParts.WIDTH) * scale
    return Rect2(base.x - width / 2.0, top, width, height)


static func bounds(base: Vector2, scale: float) -> Rect2:
    var size: Vector2 = Vector2(RocketParts.WIDTH, RocketParts.total_height()) * scale
    return Rect2(base.x - size.x / 2.0, base.y - size.y, size.x, size.y)


## Dibuja el cohete: piezas puestas y, si `show_slots`, los huecos vacíos con su nombre.
static func draw(
        canvas: CanvasItem,
        build: RocketBuild,
        base: Vector2,
        scale: float,
        show_slots: bool,
        hover: int,
        time: float,
        ) -> void:
    for section: RocketParts.Section in RocketParts.sections():
        var rect: Rect2 = section_rect(section, base, scale)
        var part: int = build.part_at(section)
        if part == -1:
            if show_slots:
                _empty_slot(canvas, rect, section, section == hover, time)
            continue
        canvas.draw_texture_rect(part_texture(part as RocketParts.Part), rect, false)
        if section == hover:
            canvas.draw_rect(rect.grow(2.0), Color(SLOT_HOVER, 0.5 + 0.3 * sin(time * 8.0)), false, 2.0)


## Llama animada bajo el motor `engine` (3 cuadros de los assets), pegada a su boquera. `strength` 0..1 la estira.
static func draw_flame(
        canvas: CanvasItem,
        base: Vector2,
        scale: float,
        time: float,
        strength: float,
        engine: RocketParts.Part,
        ) -> void:
    var frame: int = int(time * 14.0) % RocketParts.FLAME_FRAMES.size()
    var flame: Texture2D = texture(RocketParts.TEXTURE_DIR + RocketParts.FLAME_FRAMES[frame])
    var size: Vector2 = Vector2(flame.get_width(), flame.get_height()) * scale
    size.y *= 0.6 + strength * 1.2
    var engine_height: int = int(RocketParts.SECTION_HEIGHTS[RocketParts.Section.PROPULSION])
    var gap: float = float(engine_height - 1 - int(RocketParts.NOZZLE_BOTTOM[engine])) * scale
    canvas.draw_texture_rect(flame, Rect2(base.x - size.x / 2.0, base.y - gap - scale, size.x, size.y), false)


static func _empty_slot(canvas: CanvasItem, rect: Rect2, section: RocketParts.Section, is_hover: bool, time: float) -> void:
    var edge: Color = SLOT_EDGE
    if is_hover:
        edge = Color(SLOT_HOVER, 0.7 + 0.3 * sin(time * 8.0))
        canvas.draw_rect(rect, Color(SLOT_HOVER, 0.12))
    else:
        canvas.draw_rect(rect, SLOT_FILL)
    _dashed_rect(canvas, rect, edge, time)
    var title: String = String(RocketParts.SECTION_TITLES[section])
    var font_size: int = 12 if rect.size.y >= 30.0 else 10
    UiDraw.text_centered(canvas, rect.get_center().x, rect.get_center().y - float(font_size) * 0.65, title, font_size, SLOT_TEXT, true)


## Borde discontinuo que avanza despacio (marca de "pon algo aquí").
static func _dashed_rect(canvas: CanvasItem, rect: Rect2, color: Color, time: float) -> void:
    var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
    var shift: float = fmod(time * 12.0, DASH * 2.0)
    for i: int in 4:
        var a: Vector2 = corners[i]
        var b: Vector2 = corners[(i + 1) % 4]
        var length: float = a.distance_to(b)
        var along: float = -shift
        while along < length:
            var from: float = maxf(0.0, along)
            var to: float = minf(length, along + DASH)
            if to > from:
                canvas.draw_line(a.lerp(b, from / length), a.lerp(b, to / length), color, 1.5)
            along += DASH * 2.0
