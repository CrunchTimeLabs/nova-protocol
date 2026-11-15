class_name DialView
extends Control
## Reloj analógico genérico: arco de 270°, marcas numéricas por intervalo, un rango objetivo resaltado y una aguja.
## Se configura con set_scale / set_target / set_reading; solo dibuja, no conoce ningún juego.


const START_DEGREES: float = 135.0
const SWEEP_DEGREES: float = 270.0
const RADIUS_RATIO: float = 0.42
const ARC_POINTS: int = 64
const ARC_WIDTH: float = 3.0
const TARGET_WIDTH: float = 12.0
const NEEDLE_WIDTH: float = 3.0
const MARK_LENGTH: float = 10.0
const LABEL_SIZE: int = 14
const ARC_COLOR: Color = Color(0.6, 0.6, 0.6)
const TARGET_COLOR: Color = Color(0.9, 0.9, 0.9, 0.55)
const NEEDLE_COLOR: Color = Color(1.0, 1.0, 1.0)
const TEXT_COLOR: Color = Color(0.8, 0.8, 0.8)

var _min: float = 0.0
var _max: float = 100.0
var _step: float = 10.0
var _low: float = 0.0
var _high: float = 0.0
var _has_target: bool = false
var _reading: float = 0.0


func set_range(minimum: float, maximum: float, mark_step: float) -> void:
    _min = minimum
    _max = maximum
    _step = maxf(mark_step, 0.001)
    queue_redraw()


func set_target(low: float, high: float) -> void:
    _low = low
    _high = high
    _has_target = true
    queue_redraw()


func set_reading(value: float) -> void:
    _reading = value
    queue_redraw()


func _draw() -> void:
    var center: Vector2 = size * 0.5
    var radius: float = minf(size.x, size.y) * RADIUS_RATIO
    draw_arc(center, radius, _angle(_min), _angle(_max), ARC_POINTS, ARC_COLOR, ARC_WIDTH)
    if _has_target:
        draw_arc(center, radius, _angle(_low), _angle(_high), ARC_POINTS, TARGET_COLOR, TARGET_WIDTH)
    var mark: float = _min
    while mark <= _max + 0.0001:
        _draw_mark(center, radius, mark)
        mark += _step
    var tip: Vector2 = center + Vector2.from_angle(_angle(_reading)) * radius * 0.9
    draw_line(center, tip, NEEDLE_COLOR, NEEDLE_WIDTH)
    draw_circle(center, NEEDLE_WIDTH * 2.0, NEEDLE_COLOR)


func _draw_mark(center: Vector2, radius: float, value: float) -> void:
    var direction: Vector2 = Vector2.from_angle(_angle(value))
    draw_line(center + direction * (radius - MARK_LENGTH), center + direction * radius, ARC_COLOR, ARC_WIDTH)
    var label_center: Vector2 = center + direction * (radius + MARK_LENGTH + LABEL_SIZE)
    UiDraw.text(self, label_center - Vector2(LABEL_SIZE * 1.5, LABEL_SIZE * 0.5), str(int(value)), LABEL_SIZE, TEXT_COLOR, false, HORIZONTAL_ALIGNMENT_CENTER, LABEL_SIZE * 3.0)


## Ángulo (radianes, sentido horario en pantalla) de un valor sobre el arco.
func _angle(value: float) -> float:
    var fraction: float = clampf((value - _min) / maxf(_max - _min, 0.001), 0.0, 1.0)
    return deg_to_rad(START_DEGREES + fraction * SWEEP_DEGREES)
