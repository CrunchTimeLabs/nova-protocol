class_name DodgeView
extends Control
## Dibuja un `DodgeField` a su tamaño real: rocas y nave en línea gris (la nave parpadea al ser golpeada). Solo lee.


const LINE_COLOR: Color = Color(0.8, 0.8, 0.8)
const SHIP_COLOR: Color = Color(1.0, 1.0, 1.0)
const BORDER_COLOR: Color = Color(0.35, 0.35, 0.35)
const LINE_WIDTH: float = 2.0
const BLINK_SECONDS: float = 0.1

var _field: DodgeField
var _time: float = 0.0


func _init() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(field: DodgeField) -> void:
    _field = field


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, LINE_WIDTH)
    if _field == null:
        return
    for rock: DodgeRock in _field.rocks:
        var points: PackedVector2Array = rock.outline.duplicate()
        for i: int in range(points.size()):
            points[i] += rock.position
        points.append(points[0])
        draw_polyline(points, LINE_COLOR, LINE_WIDTH)
    var is_hidden: bool = _field.is_protected() and int(_time / BLINK_SECONDS) % 2 == 0
    if not is_hidden:
        _draw_ship(_field.ship)


func _draw_ship(center: Vector2) -> void:
    var radius: float = DodgeField.SHIP_RADIUS
    var nose: Vector2 = center + Vector2(radius, 0.0)
    var top: Vector2 = center + Vector2(-radius, -radius * 0.8)
    var bottom: Vector2 = center + Vector2(-radius, radius * 0.8)
    draw_polyline(PackedVector2Array([nose, top, bottom, nose]), SHIP_COLOR, LINE_WIDTH)
