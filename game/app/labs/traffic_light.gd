extends Control
## Laboratorio del semáforo: compone un TrafficLight y dibuja sus tres luces.
## Avanza solo con el tiempo real; R lo reinicia y Esc vuelve al menú.
## Solo compone y lee: las reglas viven en TrafficLight.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const HOUSING_COLOR := Color(0.10, 0.11, 0.15)
const HOUSING_BORDER := Color(0.22, 0.24, 0.30)
const HINT_COLOR := Color(0.6, 0.65, 0.75)
const HOUSING_SIZE := Vector2(180.0, 460.0)
const LIGHT_RADIUS: float = 56.0
const LIGHT_GAP: float = 26.0
const INACTIVE_DARKEN: float = 0.72
const STATUS_FONT_SIZE: int = 28
const HINT_FONT_SIZE: int = 16
const STATUS_GAP: float = 36.0
const HINT_MARGIN: float = 24.0
const CENTER_OFFSET_Y: float = 20.0

var _traffic_light: TrafficLight


func _ready() -> void:
    _traffic_light = TrafficLight.new()
    _traffic_light.light_changed.connect(_on_light_changed)
    resized.connect(queue_redraw)


func _process(delta: float) -> void:
    _traffic_light.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_R:
            _restart()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND, true)
    var center: Vector2 = Vector2(size.x * 0.5, size.y * 0.5 - CENTER_OFFSET_Y)
    var housing: Rect2 = Rect2(center - HOUSING_SIZE * 0.5, HOUSING_SIZE)
    draw_rect(housing, HOUSING_COLOR, true)
    draw_rect(housing, HOUSING_BORDER, false, 2.0)

    var lights: Array[TrafficLight.Light] = [
        TrafficLight.Light.RED,
        TrafficLight.Light.YELLOW,
        TrafficLight.Light.GREEN,
    ]
    var step: float = LIGHT_RADIUS * 2.0 + LIGHT_GAP
    var total_height: float = step * float(lights.size() - 1) + LIGHT_RADIUS * 2.0
    var first_y: float = center.y - total_height * 0.5 + LIGHT_RADIUS
    var active: TrafficLight.Light = _traffic_light.current()
    for i: int in lights.size():
        var light: TrafficLight.Light = lights[i]
        var color: Color = _light_color(light)
        if light != active:
            color = color.darkened(INACTIVE_DARKEN)
        draw_circle(Vector2(center.x, first_y + step * float(i)), LIGHT_RADIUS, color)

    draw_string(
            ThemeDB.fallback_font,
            Vector2(0.0, housing.end.y + STATUS_GAP),
            _light_name(active),
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x,
            STATUS_FONT_SIZE,
            _light_color(active),
            )
    draw_string(
            ThemeDB.fallback_font,
            Vector2(0.0, size.y - HINT_MARGIN),
            "R: reiniciar · Esc: menú",
            HORIZONTAL_ALIGNMENT_CENTER,
            size.x,
            HINT_FONT_SIZE,
            HINT_COLOR,
            )


func _restart() -> void:
    _traffic_light.reset()
    queue_redraw()


func _on_light_changed(_previous: TrafficLight.Light, _current: TrafficLight.Light) -> void:
    queue_redraw()


func _light_color(light: TrafficLight.Light) -> Color:
    match light:
        TrafficLight.Light.RED:
            return Color(1.0, 0.16, 0.16)
        TrafficLight.Light.YELLOW:
            return Color(1.0, 0.82, 0.1)
        TrafficLight.Light.GREEN:
            return Color(0.2, 0.95, 0.35)
    return Color.WHITE


func _light_name(light: TrafficLight.Light) -> String:
    match light:
        TrafficLight.Light.RED:
            return "ROJO"
        TrafficLight.Light.YELLOW:
            return "AMARILLO"
        TrafficLight.Light.GREEN:
            return "VERDE"
    return ""
