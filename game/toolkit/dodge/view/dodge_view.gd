class_name DodgeView
extends Control
## Dibuja un `DodgeField` a su tamaño real: rocas (marrones, con giro y núcleo iluminado), ondas (banda con grosor) y nave en línea gris (punteada y azulada en fase) (la nave parpadea al ser golpeada). Solo lee.


const LINE_COLOR: Color = Color(0.8, 0.8, 0.8)
const SHIP_COLOR: Color = Color(1.0, 1.0, 1.0)
const BORDER_COLOR: Color = Color(0.35, 0.35, 0.35)
const WAVE_COLOR: Color = Color(1.0, 0.75, 0.3)
const WAVE_BAND_COLOR: Color = Color(1.0, 0.75, 0.3, 0.25)
const PHASE_COLOR: Color = Color(0.5, 0.88, 1.0)
const DASH_LENGTH: float = 4.0
const WAVE_SEGMENTS: int = 96
const ROCK_COLOR: Color = Color8(104, 82, 70)
const ROCK_LIT_COLOR: Color = Color8(124, 100, 86)
const ROCK_EDGE_COLOR: Color = Color8(156, 126, 104)
const ROCK_LIGHT_OFFSET: Vector2 = Vector2(-2.0, -2.0)
const ROCK_CORE_SCALE: float = 0.6
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
    for wave: DodgeWave in _field.waves:
        draw_arc(wave.center, wave.radius, 0.0, TAU, WAVE_SEGMENTS, WAVE_BAND_COLOR, DodgeWave.THICKNESS)
        draw_arc(wave.center, wave.radius, 0.0, TAU, WAVE_SEGMENTS, WAVE_COLOR, LINE_WIDTH)
    for rock: DodgeRock in _field.rocks:
        _draw_rock(rock)
    var is_hidden: bool = _field.is_protected() and int(_time / BLINK_SECONDS) % 2 == 0
    if not is_hidden:
        _draw_ship(_field.ship)


func _draw_rock(rock: DodgeRock) -> void:
    var points: PackedVector2Array = Transform2D(rock.spin, rock.position) * rock.outline
    draw_colored_polygon(points, ROCK_COLOR)
    var core: PackedVector2Array = Transform2D(rock.spin, rock.position + ROCK_LIGHT_OFFSET) * (Transform2D().scaled(Vector2.ONE * ROCK_CORE_SCALE) * rock.outline)
    draw_colored_polygon(core, ROCK_LIT_COLOR)
    points.append(points[0])
    draw_polyline(points, ROCK_EDGE_COLOR, LINE_WIDTH)


func _draw_ship(center: Vector2) -> void:
    var radius: float = DodgeField.SHIP_RADIUS
    var nose: Vector2 = center + Vector2(radius, 0.0)
    var top: Vector2 = center + Vector2(-radius, -radius * 0.8)
    var bottom: Vector2 = center + Vector2(-radius, radius * 0.8)
    if _field.in_phase:
        draw_dashed_line(nose, top, PHASE_COLOR, LINE_WIDTH, DASH_LENGTH)
        draw_dashed_line(top, bottom, PHASE_COLOR, LINE_WIDTH, DASH_LENGTH)
        draw_dashed_line(bottom, nose, PHASE_COLOR, LINE_WIDTH, DASH_LENGTH)
        return
    draw_polyline(PackedVector2Array([nose, top, bottom, nose]), SHIP_COLOR, LINE_WIDTH)
