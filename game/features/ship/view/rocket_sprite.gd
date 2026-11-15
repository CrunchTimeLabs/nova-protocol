class_name RocketSprite
extends RefCounted
## El cohete armado (pixel art, de lado con la nariz a la derecha) para otras pantallas: llama animada debajo del
## motor y, en fase, un brillo cian (colores del vuelo de game-mechanics). Solo dibuja.


const PHASE_GLOW := Color(0.5, 0.88, 1.0)


## Piezas en orden de apilado (carga útil arriba … propulsión abajo) desde un diccionario Section -> Part;
## lo que falte se completa con la pieza base de esa sección.
static func parts_from(rocket: Dictionary) -> Array[RocketParts.Part]:
    var parts: Array[RocketParts.Part] = []
    for index: int in RocketParts.sections().size():
        var section: RocketParts.Section = RocketParts.sections()[index]
        var part: int = int(rocket.get(section, -1))
        parts.append(RocketParts.BASE_PARTS[index] if part < 0 else part as RocketParts.Part)
    return parts


static func draw_sideways(
        canvas: CanvasItem,
        parts: Array[RocketParts.Part],
        center: Vector2,
        scale: float,
        time: float,
        flame: float,
        in_phase: bool,
        ) -> void:
    var length: float = float(RocketParts.total_height()) * scale
    var width: float = float(RocketParts.WIDTH) * scale
    if in_phase:
        canvas.draw_circle(center, length * 0.55, Color(PHASE_GLOW, 0.12))
        for k: int in 3:
            canvas.draw_arc(center, length * 0.42 + float(k) * 6.0, 0.0, TAU, 40, Color(PHASE_GLOW, 0.35 - 0.1 * float(k)), 2.0)
    canvas.draw_set_transform(center, PI / 2.0, Vector2.ONE)
    if flame > 0.0:
        var frame: int = int(time * 14.0) % RocketParts.FLAME_FRAMES.size()
        var texture: Texture2D = RocketView.texture(RocketParts.TEXTURE_DIR + RocketParts.FLAME_FRAMES[frame])
        var size: Vector2 = Vector2(texture.get_size()) * scale
        size.y *= 0.6 + flame
        canvas.draw_texture_rect(texture, Rect2(Vector2(-size.x / 2.0, length / 2.0 - 4.0 * scale), size), false)
    var tint: Color = Color(0.75, 0.95, 1.0, 0.55) if in_phase else Color.WHITE
    for part: RocketParts.Part in parts:
        var section: RocketParts.Section = RocketParts.section_of(part)
        var top: float = -length / 2.0 + float(RocketParts.section_top(section)) * scale
        var height: float = float(RocketParts.SECTION_HEIGHTS[section]) * scale
        canvas.draw_texture_rect(RocketView.part_texture(part), Rect2(-width / 2.0, top, width, height), false, tint)
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
