extends Node2D
## Laboratorio de la bodega: 1-4 intentan cargar un objeto (cuadrado, su masa es su lado), Retroceso quita el último,
## C vacía, Esc vuelve al menú. Solo compone y dibuja; las reglas viven en CargoHold.


const CAPACITY: int = 10
const MASSES: Dictionary = {"a": 2, "b": 3, "c": 4, "d": 6}
const UNIT: float = 24.0
const ORIGIN: Vector2 = Vector2(80, 200)

var _hold: CargoHold
var _hud: Label


func _ready() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = Vector2(12, 8)
    layer.add_child(_hud)
    _hold = CargoHold.new(CAPACITY)
    _hold.changed.connect(_refresh)
    _refresh()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_1:
            _try_add("a")
        KEY_2:
            _try_add("b")
        KEY_3:
            _try_add("c")
        KEY_4:
            _try_add("d")
        KEY_BACKSPACE:
            var ids: Array[String] = _hold.ids()
            if not ids.is_empty():
                _hold.remove(ids[ids.size() - 1])
        KEY_C:
            _hold.clear()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _draw() -> void:
    draw_rect(Rect2(ORIGIN, Vector2(CAPACITY * UNIT, UNIT * 2.0)), Color.DIM_GRAY, false, 2.0)
    var x: float = 0.0
    for item_id: String in _hold.ids():
        var width: float = float(MASSES[item_id]) * UNIT
        draw_rect(Rect2(ORIGIN + Vector2(x + 2.0, 2.0), Vector2(width - 4.0, UNIT * 2.0 - 4.0)), Color.YELLOW)
        x += width


func _try_add(item_id: String) -> void:
    _hold.add(item_id, int(MASSES[item_id]))


func _refresh() -> void:
    _hud.text = "1-4: cargar a(2) b(3) c(4) d(6) · Retroceso: quitar último · C: vaciar · Esc: menú\nUsado %d / %d" % [_hold.used(), _hold.capacity]
    queue_redraw()
