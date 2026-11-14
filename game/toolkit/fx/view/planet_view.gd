class_name PlanetView
extends Control
## Un planeta como círculo plano de un color. Se coloca con `place(centro, radio)`.


var _surface: Color
var _radius: float = 0.0


func _init(surface: Color, _dark: Color, _seed_value: int) -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _surface = surface


func place(center: Vector2, radius: float) -> void:
    _radius = radius
    position = center - Vector2(radius, radius)
    size = Vector2(radius, radius) * 2.0
    queue_redraw()


func _draw() -> void:
    draw_circle(Vector2(_radius, _radius), _radius, _surface)
