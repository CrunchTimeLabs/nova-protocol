class_name StatusLamp
extends Control
## Foco de dos estados: verde (ok) o rojo (no ok). Solo dibuja.


const LAMP_SIZE: float = 28.0
const OK_COLOR: Color = Color(0.2, 0.85, 0.35)
const FAIL_COLOR: Color = Color(0.9, 0.2, 0.2)
const RIM_COLOR: Color = Color(0.9, 0.9, 0.9)
const RIM_WIDTH: float = 2.0

var _is_ok: bool = false


func _init() -> void:
    custom_minimum_size = Vector2(LAMP_SIZE, LAMP_SIZE)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_ok(is_ok: bool) -> void:
    if is_ok == _is_ok:
        return
    _is_ok = is_ok
    queue_redraw()


func _draw() -> void:
    var center: Vector2 = size * 0.5
    var radius: float = minf(size.x, size.y) * 0.5 - RIM_WIDTH
    draw_circle(center, radius, OK_COLOR if _is_ok else FAIL_COLOR)
    draw_arc(center, radius, 0.0, TAU, 32, RIM_COLOR, RIM_WIDTH)
