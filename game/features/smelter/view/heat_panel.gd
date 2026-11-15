class_name HeatPanel
extends Control
## Mitad derecha (J2): la temperatura del horno. Un reloj grande y lineal (0–1800 °C) con las marcas de los 5
## metales, la zona objetivo y la aguja; debajo una lupa (±200 °C alrededor del objetivo) para afinar, la lectura
## en grande y un aviso enorme de hacia dónde corregir. El color del metal del crisol sigue a la temperatura.


const DIAL_CENTER := Vector2(250, 270)
const DIAL_RADIUS := 138.0
const START := 150.0
const SWEEP := 240.0
const LENS := Rect2(36, 458, 440, 28)
const LENS_SPAN := 200.0

var temperature: TemperatureState
var _time: float = 0.0


func setup(p_temperature: TemperatureState) -> void:
    temperature = p_temperature


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    size = SmelterStyle.HALF
    clip_contents = true


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _angle(value: float) -> float:
    var fraction: float = clampf(value / temperature.scale_max, 0.0, 1.0)
    return deg_to_rad(START + fraction * SWEEP)


## Color de un metal a esa temperatura (rojo oscuro → naranja → amarillo → blanco).
static func heat_color(value: float) -> Color:
    var t: float = clampf(value / 1800.0, 0.0, 1.0)
    if t < 0.4:
        return Color(0.3, 0.05, 0.03).lerp(Color(0.9, 0.2, 0.05), t / 0.4)
    if t < 0.75:
        return Color(0.9, 0.2, 0.05).lerp(Color(1.0, 0.65, 0.15), (t - 0.4) / 0.35)
    return Color(1.0, 0.65, 0.15).lerp(Color(1.0, 0.97, 0.85), (t - 0.75) / 0.25)


func _draw() -> void:
    SmelterStyle.backdrop(self, 520.0, _time)
    SmelterStyle.top_bar(self, 2, "HORNO · TEMPERATURA", "↑ subir  ↓ bajar  (mantén)")
    if temperature == null:
        return
    var value: float = temperature.gauge.value
    var heat: Color = heat_color(value)
    # Crisol que brilla según la temperatura.
    draw_circle(DIAL_CENTER, DIAL_RADIUS + 18.0, Color(0.05, 0.03, 0.03, 0.85))
    draw_circle(DIAL_CENTER, DIAL_RADIUS - 30.0, Color(heat, 0.08 + 0.04 * sin(_time * 5.0)))
    draw_arc(DIAL_CENTER, DIAL_RADIUS + 18.0, 0.0, TAU, 64, Color(FoundryArt.EDGE, 0.8), 2.0)
    # Arco con degradado de calor.
    var steps: int = 48
    for i: int in steps:
        var a0: float = float(i) / float(steps) * temperature.scale_max
        var a1: float = float(i + 1) / float(steps) * temperature.scale_max
        draw_arc(DIAL_CENTER, DIAL_RADIUS, _angle(a0), _angle(a1), 3, Color(heat_color(a0), 0.65), 10.0)
    if temperature.has_target:
        var pulse: float = 0.6 + 0.4 * sin(_time * 6.0)
        draw_arc(DIAL_CENTER, DIAL_RADIUS + 1.0, _angle(temperature.target_low), _angle(temperature.target_high), 12,
                Color(0.35, 1.0, 0.5, pulse), 22.0)
    for mark: int in range(0, 1801, 300):
        var dir: Vector2 = Vector2.from_angle(_angle(float(mark)))
        draw_line(DIAL_CENTER + dir * (DIAL_RADIUS - 16.0), DIAL_CENTER + dir * (DIAL_RADIUS - 6.0), FoundryArt.MUTED, 2.0)
        UiDraw.text_centered(self, DIAL_CENTER.x + dir.x * (DIAL_RADIUS - 34.0), DIAL_CENTER.y + dir.y * (DIAL_RADIUS - 34.0) - 7.0, str(mark), 10, FoundryArt.MUTED)
    for ore: Ores.Ore in Ores.all():
        var point: float = float(Ores.MELTING_POINTS[ore])
        var dir: Vector2 = Vector2.from_angle(_angle(point))
        draw_line(DIAL_CENTER + dir * (DIAL_RADIUS + 6.0), DIAL_CENTER + dir * (DIAL_RADIUS + 16.0), Ores.color(ore), 3.0)
        var label: Vector2 = DIAL_CENTER + dir * (DIAL_RADIUS + 30.0)
        UiDraw.text_centered(self, label.x, label.y - 8.0, String(Ores.SYMBOLS[ore]), 13, Ores.color(ore), true)
    # Aguja.
    var tip: Vector2 = DIAL_CENTER + Vector2.from_angle(_angle(value)) * (DIAL_RADIUS - 8.0)
    draw_line(DIAL_CENTER, tip, Color(0, 0, 0, 0.5), 7.0)
    draw_line(DIAL_CENTER, tip, heat.lightened(0.3), 4.0)
    draw_circle(DIAL_CENTER, 12.0, heat)
    draw_circle(DIAL_CENTER, 5.0, Color(0.1, 0.05, 0.03))
    # Lectura y objetivo.
    UiDraw.text_centered(self, DIAL_CENTER.x, DIAL_CENTER.y + 34.0, "%d °C" % roundi(value), 30, FoundryArt.TEXT, true)
    var goal: String = temperature.message if temperature.has_target else "Esperando una mena…"
    UiDraw.text_centered(self, DIAL_CENTER.x, 54.0, goal, 18, FoundryArt.TITLE, true)
    _draw_lens(value)
    _draw_hint(value)


## Lupa: ±LENS_SPAN alrededor del objetivo, para el ajuste fino.
func _draw_lens(value: float) -> void:
    if not temperature.has_target:
        return
    var middle: float = (temperature.target_low + temperature.target_high) * 0.5
    var low: float = middle - LENS_SPAN
    UiDraw.panel(self, LENS.grow(4.0), Color(0.05, 0.03, 0.025, 0.9), Color(FoundryArt.EDGE, 0.7))
    for i: int in 40:
        var v: float = low + LENS_SPAN * 2.0 * float(i) / 40.0
        draw_rect(Rect2(LENS.position.x + LENS.size.x * float(i) / 40.0, LENS.position.y, LENS.size.x / 40.0 + 1.0, LENS.size.y), Color(heat_color(v), 0.5))
    var band_x0: float = LENS.position.x + LENS.size.x * (temperature.target_low - low) / (LENS_SPAN * 2.0)
    var band_x1: float = LENS.position.x + LENS.size.x * (temperature.target_high - low) / (LENS_SPAN * 2.0)
    draw_rect(Rect2(band_x0, LENS.position.y - 3, band_x1 - band_x0, LENS.size.y + 6), Color(0.35, 1.0, 0.5, 0.45))
    var x: float = LENS.position.x + LENS.size.x * clampf((value - low) / (LENS_SPAN * 2.0), 0.0, 1.0)
    draw_rect(Rect2(x - 3, LENS.position.y - 8, 6, LENS.size.y + 16), FoundryArt.TEXT)
    if value < low:
        UiDraw.text(self, LENS.position + Vector2(4, 6), "◄ muy frío", 12, FoundryArt.TEXT, true)
    elif value > middle + LENS_SPAN:
        UiDraw.text(self, LENS.position + Vector2(LENS.size.x - 100, 6), "muy caliente ►", 12, FoundryArt.TEXT, true)
    UiDraw.text_centered(self, LENS.get_center().x, LENS.end.y + 8, "LUPA ±%d °C" % int(LENS_SPAN), 10, FoundryArt.MUTED, true)


func _draw_hint(value: float) -> void:
    if not temperature.has_target or temperature.is_over():
        return
    var at: Vector2 = Vector2(450, 360)
    if temperature.is_in_range():
        draw_circle(at, 30.0, Color(FoundryArt.GOOD, 0.85))
        UiDraw.text_centered(self, at.x, at.y - 15.0, "✔", 24, Color(0.05, 0.15, 0.05), true)
        UiDraw.text_centered(self, at.x, at.y + 34.0, "EN RANGO", 12, FoundryArt.GOOD, true)
        return
    var up: bool = value < temperature.target_low
    var bob: float = sin(_time * 10.0) * 4.0 * (-1.0 if up else 1.0)
    var color: Color = FoundryArt.DANGER
    var points: PackedVector2Array
    if up:
        points = PackedVector2Array([at + Vector2(0, -28 + bob), at + Vector2(24, 4 + bob), at + Vector2(-24, 4 + bob)])
    else:
        points = PackedVector2Array([at + Vector2(0, 28 + bob), at + Vector2(24, -4 + bob), at + Vector2(-24, -4 + bob)])
    draw_colored_polygon(points, color)
    UiDraw.text_centered(self, at.x, at.y + 34.0, "¡SUBE!" if up else "¡BAJA!", 14, color, true)
