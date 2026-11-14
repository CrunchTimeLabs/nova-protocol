class_name UiPalette
extends RefCounted
## Colores, tema y estilo de Nova Protocol. El dibujo genérico (texto, paneles, barras) vive en `UiDraw`
## del toolkit; aquí solo se le pasan los colores de la consola de la misión.
## Los colores con componentes > 1 brillan con el glow del WorldEnvironment (HDR 2D).


const SCREEN := Vector2(1280, 760)

const BACKGROUND := Color8(0, 0, 0)
const PANEL := Color8(24, 24, 24)
const PANEL_ALT := Color8(48, 48, 48)
const BORDER := Color8(200, 200, 200)
const BORDER_DIM := Color8(96, 96, 96)
const TEXT := Color8(255, 255, 255)
const GRAY := Color8(160, 160, 160)
const OK := Color8(220, 220, 220)
const WARNING := Color8(170, 170, 170)
const DANGER := Color8(120, 120, 120)
const SCIENCE := Color8(200, 200, 200)
const BEACON := Color8(230, 230, 230)

const BAR_BACK := Color8(40, 40, 40)
const HULL_BAR_BACK := Color8(40, 40, 40)
const PANEL_ALPHA := 1.0
const HEADER_ALPHA := 1.0

const RES_COLORS: Dictionary = {
    Catalog.Res.METAL: Color8(230, 230, 230),
    Catalog.Res.CRYSTAL: Color8(180, 180, 180),
    Catalog.Res.FUEL: Color8(130, 130, 130),
}

## Tamaños de letra, como en la versión pygame.
const HUGE := 44
const TITLE := 28
const SUBTITLE := 19
const BODY := 15
const SMALL := 13
const TINY := 11


static func font(bold: bool = false) -> Font:
    return UiDraw.font(bold)


## Color con brillo extra para que lo recoja el glow.
static func glow(color: Color, strength: float = 1.6) -> Color:
    return UiDraw.glow(color, strength)


static func resource_color(res: Catalog.Res) -> Color:
    return RES_COLORS[res]


## Verde, ámbar o rojo según lo lleno que esté algo bueno (vida, batería).
static func health_color(ratio: float) -> Color:
    if ratio > 0.55:
        return OK
    return WARNING if ratio > 0.25 else DANGER


static func make_theme() -> Theme:
    return Theme.new()


## Los botones usan el estilo por defecto de Godot.
static func style_button(_button: Button, _color: Color) -> void:
    pass


# ------------------------------------------------------------------ dibujo (con la paleta del juego)

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
    UiDraw.text(canvas, top_left, value, size, color, bold, align, width)


static func text_centered(
        canvas: CanvasItem,
        center_x: float,
        top: float,
        value: String,
        size: int,
        color: Color,
        bold: bool = false,
        ) -> void:
    UiDraw.text_centered(canvas, center_x, top, value, size, color, bold)


## Texto ajustado al ancho. Devuelve la Y donde termina.
static func wrapped(canvas: CanvasItem, top_left: Vector2, value: String, size: int, color: Color, width: float) -> float:
    return UiDraw.wrapped(canvas, top_left, value, size, color, width)


static func wrapped_height(value: String, size: int, width: float) -> float:
    return UiDraw.wrapped_height(value, size, width)


static func panel(canvas: CanvasItem, rect: Rect2, border: Color = BORDER_DIM, alpha: float = PANEL_ALPHA) -> void:
    UiDraw.panel(canvas, rect, Color(PANEL, alpha), border)


static func card(canvas: CanvasItem, rect: Rect2, background: Color, border: Color, radius: int = 8) -> void:
    UiDraw.card(canvas, rect, background, border, radius)


static func bar(canvas: CanvasItem, rect: Rect2, ratio: float, color: Color, back: Color = BAR_BACK) -> void:
    UiDraw.bar(canvas, rect, ratio, color, back, BORDER_DIM)


## Barra de integridad con etiqueta y valor, coloreada según lo que queda.
static func hull_bar(canvas: CanvasItem, rect: Rect2, value: float, maximum: float, label: String = "INTEGRIDAD") -> void:
    var ratio: float = clampf(value / maxf(1.0, maximum), 0.0, 1.0)
    text(canvas, rect.position - Vector2(0, 15), label, TINY, GRAY)
    bar(canvas, rect, ratio, health_color(ratio), HULL_BAR_BACK)
    for i: int in range(1, 4):
        var x: float = rect.position.x + rect.size.x * float(i) / 4.0
        canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color8(12, 18, 30), 1.0)
    text(canvas, Vector2(rect.end.x + 8, rect.position.y + 1), "%d/%d" % [int(maxf(0.0, value)), int(maximum)], TINY, TEXT)


## Los tres recursos en fila: punto de color, cantidad y nombre.
static func resources_row(canvas: CanvasItem, origin: Vector2, amounts: Dictionary, step: float, prefix: String = "") -> void:
    var x: float = origin.x
    for res: int in [Catalog.Res.METAL, Catalog.Res.CRYSTAL, Catalog.Res.FUEL]:
        canvas.draw_circle(Vector2(x + 6, origin.y + 8), 6.0, glow(resource_color(res), 1.3))
        text(canvas, Vector2(x + 18, origin.y), "%s%d" % [prefix, int(amounts[res])], SMALL, TEXT, true)
        text(canvas, Vector2(x + 18, origin.y + 17), String(Catalog.RES_NAMES[res]), TINY, GRAY)
        x += step


## Barra superior de una pantalla, con línea de acento abajo.
static func header(canvas: CanvasItem, height: float) -> void:
    canvas.draw_rect(Rect2(0, 0, SCREEN.x, height), Color(PANEL, HEADER_ALPHA))
    canvas.draw_line(Vector2(0, height), Vector2(SCREEN.x, height), glow(BORDER, 1.2), 2.0)


## Longitud de onda (nm) a color aproximado.
static func wavelength_color(nm: float, brightness: float = 1.0) -> Color:
    return UiDraw.wavelength_color(nm, brightness)


## Rampa común a todos los ejes que no son longitudes de onda: violeta -> rojo.
static func axis_color(fraction: float, brightness: float = 1.0) -> Color:
    return UiDraw.axis_color(fraction, brightness)
