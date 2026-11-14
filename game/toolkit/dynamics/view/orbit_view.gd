class_name OrbitView
extends Node2D
## Dibuja el mundo normalizado [0, 1] de un DynamicBody: astros, estela y nave. Solo lee: la física la decide el dominio.


const BODY_RADIUS_PER_ROOT_GM: float = 120.0
const SHIP_RADIUS: float = 5.0
const MAX_TRAIL_POINTS: int = 200
const BODY_COLOR: Color = Color(1.0, 0.8, 0.4)
const SHIP_COLOR: Color = Color(0.4, 0.8, 1.0)
const TRAIL_COLOR: Color = Color(0.4, 0.8, 1.0, 0.4)
const FORECAST_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)

var _body: DynamicBody
var _attractors: Array[CentralGravity] = []
var _trail: PackedVector2Array = PackedVector2Array()
var _forecast: PackedVector2Array = PackedVector2Array()


func setup(body: DynamicBody, attractors: Array[CentralGravity]) -> void:
    _body = body
    _attractors = attractors.duplicate()


## La trayectoria prevista (puntos en mundo normalizado); se dibuja tal cual hasta que llegue otra.
func set_forecast(points: PackedVector2Array) -> void:
    _forecast = points


func clear_trail() -> void:
    _trail.clear()


func _process(_delta: float) -> void:
    if _body == null:
        return
    _trail.append(_body.position)
    if _trail.size() > MAX_TRAIL_POINTS:
        _trail.remove_at(0)
    queue_redraw()


func _draw() -> void:
    if _body == null:
        return
    var side: float = get_viewport_rect().size.y
    var origin: Vector2 = Vector2((get_viewport_rect().size.x - side) / 2.0, 0.0)
    for attractor: CentralGravity in _attractors:
        draw_circle(origin + attractor.center * side, sqrt(attractor.gm) * BODY_RADIUS_PER_ROOT_GM, BODY_COLOR)
    if _forecast.size() > 1:
        draw_polyline(_to_screen(_forecast, origin, side), FORECAST_COLOR)
    if _trail.size() > 1:
        draw_polyline(_to_screen(_trail, origin, side), TRAIL_COLOR)
    draw_circle(origin + _body.position * side, SHIP_RADIUS, SHIP_COLOR)


func _to_screen(points: PackedVector2Array, origin: Vector2, side: float) -> PackedVector2Array:
    var screen: PackedVector2Array = PackedVector2Array()
    for point: Vector2 in points:
        screen.append(origin + point * side)
    return screen
