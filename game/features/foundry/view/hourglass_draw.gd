class_name HourglassDraw
extends RefCounted
## Reloj de arena animado del tiempo total: marco pixel art (hourglass.png, 28x48) y arena dibujada encima,
## fila a fila con la misma forma del vidrio que `assets/foundry/source/pixel_art.py`.


const WIDTH := 28
const HEIGHT := 48
const GLASS_TOP := 6
const GLASS_BOTTOM := 41
const NECK := 23.5
const MAX_HALF := 9.0
const NECK_HALF := 1.0
const SAND := Color(0.95, 0.76, 0.4)
const SAND_DARK := Color(0.78, 0.55, 0.25)
const SAND_LIGHT := Color(1.0, 0.9, 0.62)
const CENTER_X := 13.5


## Medio ancho del interior del vidrio en la fila `y` (píxeles x1).
static func half_width(y: int) -> float:
    var t: float = minf(1.0, absf(float(y) + 0.5 - NECK) / (NECK - float(GLASS_TOP)))
    return NECK_HALF + (MAX_HALF - NECK_HALF) * pow(sin(t * PI / 2.0), 0.8)


static func _row_area(y: int) -> float:
    return floorf(half_width(y)) * 2.0


static func _bulb_area() -> float:
    var area: float = 0.0
    for y: int in range(GLASS_TOP, int(NECK)):
        area += _row_area(y)
    return area


## Dibuja el reloj con la esquina en `top_left` a `scale`. `ratio` 1 = lleno arriba, 0 = todo abajo.
static func draw(canvas: CanvasItem, top_left: Vector2, scale: float, ratio: float, time: float, running: bool) -> void:
    var frame: Texture2D = FoundryArt.texture(FoundryArt.HOURGLASS)
    var top_sand: float = _bulb_area() * clampf(ratio, 0.0, 1.0)
    var bottom_sand: float = _bulb_area() - top_sand
    # Arriba: la arena se apoya en el cuello y su superficie baja.
    var y: int = int(NECK) - 1
    while top_sand > 0.0 and y >= GLASS_TOP:
        var row: float = _row_area(y)
        var fill: float = minf(1.0, top_sand / row)
        _sand_row(canvas, top_left, scale, y, fill, y == int(NECK) - 1)
        top_sand -= row
        y -= 1
    # Abajo: se amontona desde el fondo, con forma de montículo en la fila de arriba.
    y = GLASS_BOTTOM
    while bottom_sand > 0.0 and y > int(NECK):
        var row: float = _row_area(y)
        var fill: float = minf(1.0, bottom_sand / row)
        _sand_row(canvas, top_left, scale, y, fill, false)
        bottom_sand -= row
        y -= 1
    var pile_top: int = y + 1
    # Chorro por el cuello mientras corre el tiempo.
    if running and ratio > 0.0 and ratio < 1.0:
        for row_y: int in range(int(NECK) - 1, pile_top):
            if (row_y + int(time * 30.0)) % 3 == 0:
                continue
            canvas.draw_rect(Rect2(top_left + Vector2(CENTER_X - 0.5, row_y) * scale, Vector2(1.0, 1.0) * scale), SAND_LIGHT)
    canvas.draw_texture_rect(frame, Rect2(top_left, Vector2(WIDTH, HEIGHT) * scale), false)


static func _sand_row(canvas: CanvasItem, top_left: Vector2, scale: float, y: int, fill: float, is_neck: bool) -> void:
    var half: float = floorf(half_width(y))
    var width: float = maxf(1.0, roundf(half * 2.0 * fill))
    if is_neck:
        width = maxf(width, 2.0)
    var x0: float = roundf(CENTER_X + 0.5 - width / 2.0)
    var rect: Rect2 = Rect2(top_left + Vector2(x0, y) * scale, Vector2(width, 1.0) * scale)
    canvas.draw_rect(rect, SAND if fill >= 1.0 else SAND_LIGHT)
    if width >= 3.0:
        canvas.draw_rect(Rect2(rect.position, Vector2(scale, scale)), SAND_DARK)
        canvas.draw_rect(Rect2(Vector2(rect.end.x - scale, rect.position.y), Vector2(scale, scale)), SAND_DARK)
