class_name OrbitView
extends Node2D
## Dibuja el mundo normalizado [0, 1] de un DynamicBody: astros, estela y nave. Solo lee: la física la decide el dominio.


const BODY_RADIUS_PER_ROOT_GM: float = 120.0
const SHIP_RADIUS: float = 5.0
const MAX_TRAIL_POINTS: int = 200
const BODY_COLOR: Color = Color(1.0, 0.8, 0.4)
const SHIP_COLOR: Color = Color(0.4, 0.8, 1.0)
const TRAIL_COLOR: Color = Color(0.4, 0.8, 1.0, 0.4)
const GOAL_COLOR: Color = Color(0.4, 1.0, 0.5, 0.8)
const GOAL_WIDTH: float = 2.0
const GOAL_SEGMENTS: int = 64
const FORECAST_COLOR: Color = Color(1.0, 1.0, 1.0, 0.5)
const SPACE_COLOR: Color = Color8(6, 9, 18)
const MOON_COLOR: Color = Color(0.7, 0.74, 0.86)
const STARS: int = 90

var _body: DynamicBody
var _attractors: Array[CentralGravity] = []
var _trail: PackedVector2Array = PackedVector2Array()
var _forecast: PackedVector2Array = PackedVector2Array()
var _goal_center: Vector2 = Vector2.ZERO
var _goal_radius: float = 0.0
var _time: float = 0.0


func setup(body: DynamicBody, attractors: Array[CentralGravity]) -> void:
    _body = body
    _attractors = attractors.duplicate()


## La trayectoria prevista (puntos en mundo normalizado); se dibuja tal cual hasta que llegue otra.
func set_forecast(points: PackedVector2Array) -> void:
    _forecast = points


## Marca una zona (centro y radio en mundo normalizado) como un círculo de meta; radio 0 la quita.
func set_goal(center: Vector2, radius: float) -> void:
    _goal_center = center
    _goal_radius = radius


func clear_trail() -> void:
    _trail.clear()


func _process(delta: float) -> void:
    _time += delta
    if _body == null:
        return
    _trail.append(_body.position)
    if _trail.size() > MAX_TRAIL_POINTS:
        _trail.remove_at(0)
    queue_redraw()


func _draw() -> void:
    if _body == null:
        return
    var area: Vector2 = get_viewport_rect().size
    var side: float = area.y
    var origin: Vector2 = Vector2((area.x - side) / 2.0, 0.0)
    _draw_space(area)
    for index: int in _attractors.size():
        var attractor: CentralGravity = _attractors[index]
        _draw_attractor(origin + attractor.center * side, sqrt(attractor.gm) * BODY_RADIUS_PER_ROOT_GM, index == 0)
    if _goal_radius > 0.0:
        var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)
        var goal_center: Vector2 = origin + _goal_center * side
        draw_circle(goal_center, _goal_radius * side, Color(GOAL_COLOR, 0.05 + 0.04 * pulse))
        _dashed_circle(goal_center, _goal_radius * side, Color(GOAL_COLOR, 0.6 + 0.4 * pulse))
    if _forecast.size() > 1:
        var screen: PackedVector2Array = _to_screen(_forecast, origin, side)
        for i: int in range(0, screen.size(), 6):
            draw_circle(screen[i], 1.6, Color(FORECAST_COLOR, 0.85 - 0.6 * float(i) / float(screen.size())))
    if _trail.size() > 1:
        var trail: PackedVector2Array = _to_screen(_trail, origin, side)
        for i: int in range(1, trail.size()):
            var t: float = float(i) / float(trail.size())
            draw_line(trail[i - 1], trail[i], Color(TRAIL_COLOR, TRAIL_COLOR.a * t * 1.6), 1.0 + 2.0 * t)
    _draw_ship(origin + _body.position * side, _body.velocity)


func _draw_space(area: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, area), SPACE_COLOR)
    for i: int in STARS:
        var h: int = absi((i * 73856093) ^ (i * i * 19349663))
        var p: Vector2 = Vector2(float(h % 1000) / 1000.0 * area.x, float((h / 1000) % 1000) / 1000.0 * area.y)
        var twinkle: float = 0.35 + 0.3 * sin(_time * (1.0 + float(h % 7) * 0.3) + float(i))
        draw_rect(Rect2(p.floor(), Vector2(2, 2)), Color(0.8, 0.85, 1.0, twinkle))


## El primero (la estrella) con halo y rayos; los demás como lunas con luz y sombra.
func _draw_attractor(center: Vector2, radius: float, is_star: bool) -> void:
    if is_star:
        for k: int in 6:
            draw_circle(center, radius * (1.0 + 0.6 * float(6 - k)), Color(BODY_COLOR, 0.025 * float(k + 1)))
        for k: int in 12:
            var angle: float = float(k) / 12.0 * TAU + _time * 0.2
            var reach: float = radius * (1.9 + 0.3 * sin(_time * 2.0 + float(k)))
            draw_line(center + Vector2.from_angle(angle) * radius * 1.2, center + Vector2.from_angle(angle) * reach, Color(BODY_COLOR, 0.35), 2.0)
        draw_circle(center, radius, BODY_COLOR)
        draw_circle(center, radius * 0.6, Color(1.0, 0.95, 0.75))
        return
    draw_circle(center, radius * 1.6, Color(MOON_COLOR, 0.12))
    draw_circle(center, radius, MOON_COLOR.darkened(0.35))
    draw_circle(center + Vector2(-radius, -radius) * 0.25, radius * 0.75, MOON_COLOR)


## La nave apunta hacia donde va, con un brillo.
func _draw_ship(at: Vector2, velocity: Vector2) -> void:
    var heading: float = velocity.angle() if velocity.length() > 0.0001 else 0.0
    draw_circle(at, SHIP_RADIUS * 2.6, Color(SHIP_COLOR, 0.15))
    var points: PackedVector2Array = PackedVector2Array()
    for corner: Vector2 in [Vector2(9, 0), Vector2(-6, -5), Vector2(-3, 0), Vector2(-6, 5)]:
        points.append(at + corner.rotated(heading))
    draw_colored_polygon(points, Color(0.88, 0.94, 1.0))
    points.append(points[0])
    draw_polyline(points, SHIP_COLOR, 1.5)


func _dashed_circle(center: Vector2, radius: float, color: Color) -> void:
    var dashes: int = 36
    for k: int in dashes:
        var a0: float = float(k) / float(dashes) * TAU + _time * 0.3
        draw_arc(center, radius, a0, a0 + TAU / float(dashes) * 0.55, 4, color, GOAL_WIDTH)


func _to_screen(points: PackedVector2Array, origin: Vector2, side: float) -> PackedVector2Array:
    var screen: PackedVector2Array = PackedVector2Array()
    for point: Vector2 in points:
        screen.append(origin + point * side)
    return screen
