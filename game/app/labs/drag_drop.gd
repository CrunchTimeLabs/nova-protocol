extends Node2D
## Laboratorio de arrastrar y soltar: el círculo azul solo se acepta en la zona derecha; en la izquierda se rechaza.
## Arrastra con el ratón, Esc vuelve al menú. Solo compone y dibuja; las reglas viven en DragSession.


const ZONE_ORIGIN: Dictionary = {&"origin": Vector2(80, 200), &"left": Vector2(80, 400), &"right": Vector2(560, 400)}
const ZONE_SIZE: Vector2 = Vector2(320, 160)
const TOKEN_RADIUS: float = 24.0
const ORIGIN_CENTER: Vector2 = Vector2(240, 280)

var _session: DragSession
var _token: Vector2 = ORIGIN_CENTER
var _hud: Label


func _ready() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = Vector2(12, 8)
    layer.add_child(_hud)
    _session = DragSession.new(_accepts)
    _session.dropped.connect(_on_dropped)
    _refresh("Arrastra el círculo · Esc: menú")


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key != null and key.pressed and key.keycode == KEY_ESCAPE:
        SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click != null and click.button_index == MOUSE_BUTTON_LEFT:
        if click.pressed and _token.distance_to(click.position) <= TOKEN_RADIUS:
            _session.begin("token", &"origin")
        elif not click.pressed and _session.is_dragging():
            _session.drop(_zone_at(click.position))
    var motion: InputEventMouseMotion = event as InputEventMouseMotion
    if motion != null and _session.is_dragging():
        _token = motion.position
        queue_redraw()


func _draw() -> void:
    for zone: StringName in ZONE_ORIGIN:
        draw_rect(Rect2(ZONE_ORIGIN[zone] as Vector2, ZONE_SIZE), Color.DIM_GRAY, false, 2.0)
    draw_circle(_token, TOKEN_RADIUS, Color.DEEP_SKY_BLUE)


func _accepts(_payload: Variant, _from_zone: StringName, to_zone: StringName) -> bool:
    return to_zone == &"right"


func _zone_at(point: Vector2) -> StringName:
    for zone: StringName in ZONE_ORIGIN:
        if Rect2(ZONE_ORIGIN[zone] as Vector2, ZONE_SIZE).has_point(point):
            return zone
    return &""


func _on_dropped(result: DragSession.Result, _payload: Variant, _from_zone: StringName, to_zone: StringName) -> void:
    if result != DragSession.Result.ACCEPTED:
        _token = ORIGIN_CENTER
    else:
        _token = (ZONE_ORIGIN[to_zone] as Vector2) + ZONE_SIZE * 0.5
    _refresh("Resultado: %s" % DragSession.Result.keys()[result])


func _refresh(text: String) -> void:
    _hud.text = text
    queue_redraw()
