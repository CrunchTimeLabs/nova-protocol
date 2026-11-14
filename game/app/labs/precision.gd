extends Node2D
## Laboratorio de la parada de precisión: una marca (círculo) oscila y Espacio la detiene.
## Cuanto más al centro, mejor nota. R repite (cada intento acelera), Esc vuelve al menú.


const BAR_ORIGIN: Vector2 = Vector2(192, 300)
const BAR_SIZE: Vector2 = Vector2(640, 24)

var _stop: PrecisionStop
var _uses: int = 0
var _hud: Label


func _ready() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = Vector2(12, 8)
    layer.add_child(_hud)
    _restart()


func _process(delta: float) -> void:
    _stop.advance(delta)
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_SPACE:
            _stop.stop()
        KEY_R:
            _uses += 1
            _restart()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _draw() -> void:
    var half: float = BAR_SIZE.x * 0.5
    draw_rect(Rect2(BAR_ORIGIN, BAR_SIZE), Color.DIM_GRAY)
    draw_rect(Rect2(BAR_ORIGIN.x + half - 2.0, BAR_ORIGIN.y - 8.0, 4.0, BAR_SIZE.y + 16.0), Color.WHITE)
    var mark: Vector2 = BAR_ORIGIN + Vector2(half + _stop.position() * half, BAR_SIZE.y * 0.5)
    draw_circle(mark, 14.0, Color.YELLOW)
    var text: String = "Espacio: parar · R: repetir (más rápido) · Esc: menú"
    if _stop.is_stopped():
        text += "\nNota: %s · x%.1f" % [PrecisionStop.Grade.keys()[_stop.grade()], _stop.multiplier()]
    _hud.text = text


func _restart() -> void:
    _stop = PrecisionStop.new(_uses)
