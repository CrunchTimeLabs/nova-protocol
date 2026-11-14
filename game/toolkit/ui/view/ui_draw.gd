class_name UiDraw
extends RefCounted
## Utilidades de dibujo genéricas (texto, paneles, tarjetas, barras, colores de espectro).
## No conocen ningún juego: cada estilo pasa sus colores. Un juego las envuelve con su paleta.


const MONO_FONTS: PackedStringArray = ["DejaVu Sans Mono", "Consolas", "Liberation Mono", "Menlo", "monospace"]
const PANEL_RADIUS := 0
const CARD_RADIUS := 0
const BAR_RADIUS := 0

static var _regular: Font
static var _bold: Font


static func font(bold: bool = false) -> Font:
    if _regular == null:
        _regular = _system_font(400)
        _bold = _system_font(700)
    return _bold if bold else _regular


static func _system_font(weight: int) -> SystemFont:
    var system: SystemFont = SystemFont.new()
    system.font_names = MONO_FONTS
    system.font_weight = weight
    system.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
    return system


## Color con brillo extra (componentes > 1) para que lo recoja un glow HDR.
static func glow(color: Color, strength: float = 1.6) -> Color:
    return color


## Texto con la esquina superior izquierda en `top_left`. `width` > 0 permite alinear dentro de ese ancho.
static func text(
        canvas: CanvasItem,
        top_left: Vector2,
        value: String,
        size: int,
        color: Color,
        bold: bool = false,
        align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT,
        width: float = -1.0,
        ) -> void:
    var used: Font = font(bold)
    canvas.draw_string(used, top_left + Vector2(0, used.get_ascent(size)), value, align, width, size, color)


static func text_centered(
        canvas: CanvasItem,
        center_x: float,
        top: float,
        value: String,
        size: int,
        color: Color,
        bold: bool = false,
        ) -> void:
    var used: Font = font(bold)
    var width: float = used.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
    canvas.draw_string(
            used,
            Vector2(center_x - width / 2.0, top + used.get_ascent(size)),
            value,
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            size,
            color,
            )


## Texto ajustado al ancho. Devuelve la Y donde termina.
static func wrapped(canvas: CanvasItem, top_left: Vector2, value: String, size: int, color: Color, width: float) -> float:
    var used: Font = font()
    canvas.draw_multiline_string(
            used,
            top_left + Vector2(0, used.get_ascent(size)),
            value,
            HORIZONTAL_ALIGNMENT_LEFT,
            width,
            size,
            -1,
            color,
            )
    return top_left.y + wrapped_height(value, size, width)


static func wrapped_height(value: String, size: int, width: float) -> float:
    return font().get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, width, size).y


static func panel(canvas: CanvasItem, rect: Rect2, background: Color, border: Color) -> void:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = background
    box.border_color = border
    box.set_border_width_all(2)
    box.set_corner_radius_all(PANEL_RADIUS)
    canvas.draw_style_box(box, rect)


static func card(canvas: CanvasItem, rect: Rect2, background: Color, border: Color, radius: int = CARD_RADIUS) -> void:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = background
    box.border_color = border
    box.set_border_width_all(2)
    box.set_corner_radius_all(CARD_RADIUS)
    canvas.draw_style_box(box, rect)


## Barra de progreso: fondo, relleno proporcional con un brillo fino arriba y marco.
static func bar(
        canvas: CanvasItem,
        rect: Rect2,
        ratio: float,
        fill_color: Color,
        back_color: Color,
        frame_color: Color,
        ) -> void:
    card(canvas, rect, back_color, Color.TRANSPARENT, BAR_RADIUS)
    var filled: float = rect.size.x * clampf(ratio, 0.0, 1.0)
    if filled > 1.0:
        var fill: StyleBoxFlat = StyleBoxFlat.new()
        fill.bg_color = fill_color
        fill.set_corner_radius_all(BAR_RADIUS)
        canvas.draw_style_box(fill, Rect2(rect.position, Vector2(filled, rect.size.y)))
    var frame: StyleBoxFlat = StyleBoxFlat.new()
    frame.draw_center = false
    frame.border_color = frame_color
    frame.set_border_width_all(1)
    frame.set_corner_radius_all(BAR_RADIUS)
    canvas.draw_style_box(frame, rect)


## Longitud de onda (nm) a color aproximado. Fuera del visible: violeta apagado o rojo que vira a gris.
static func wavelength_color(nm: float, brightness: float = 1.0) -> Color:
    var rgb: Vector3
    if nm < 380.0:
        rgb = Vector3(0.25, 0.0, 0.35)
    elif nm < 440.0:
        rgb = Vector3(-(nm - 440.0) / 60.0, 0.0, 1.0)
    elif nm < 490.0:
        rgb = Vector3(0.0, (nm - 440.0) / 50.0, 1.0)
    elif nm < 510.0:
        rgb = Vector3(0.0, 1.0, -(nm - 510.0) / 20.0)
    elif nm < 580.0:
        rgb = Vector3((nm - 510.0) / 70.0, 1.0, 0.0)
    elif nm < 645.0:
        rgb = Vector3(1.0, -(nm - 645.0) / 65.0, 0.0)
    elif nm < 781.0:
        rgb = Vector3(1.0, 0.0, 0.0)
    else:
        var f: float = minf(1.0, (nm - 780.0) / 1600.0)
        rgb = Vector3(0.72 - 0.30 * f, 0.10 + 0.22 * f, 0.10 + 0.26 * f)
    var attenuation: float = 1.0
    if nm >= 380.0 and nm < 420.0:
        attenuation = 0.3 + 0.7 * (nm - 380.0) / 40.0
    elif nm > 700.0 and nm <= 780.0:
        attenuation = 0.3 + 0.7 * (780.0 - nm) / 80.0
    var k: float = attenuation * clampf(brightness, 0.0, 1.0)
    var gray: float = (0.299 * rgb.x + 0.587 * rgb.y + 0.114 * rgb.z) * k
    return Color(gray, gray, gray)


## Rampa para ejes que no son longitudes de onda: violeta -> rojo.
static func axis_color(fraction: float, brightness: float = 1.0) -> Color:
    return wavelength_color(380.0 + clampf(fraction, 0.0, 1.0) * 320.0, brightness)
