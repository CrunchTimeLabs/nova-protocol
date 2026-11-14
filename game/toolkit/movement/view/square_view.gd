class_name SquareView
extends Node2D
## Dibuja un cuadrado en la posición de un MovementBody. Solo lee: el movimiento lo decide el dominio.


const SIZE: float = 40.0
const COLOR: Color = Color(0.4, 0.8, 1.0)

var _body: MovementBody


func setup(body: MovementBody) -> void:
    _body = body


func _process(_delta: float) -> void:
    queue_redraw()


## El límite de pantalla es solo visual: el cuerpo no sabe de pantallas.
func _draw() -> void:
    if _body == null:
        return
    var half: Vector2 = Vector2(SIZE, SIZE) / 2.0
    var center: Vector2 = _body.position.clamp(half, get_viewport_rect().size - half)
    draw_rect(Rect2(center - half, Vector2(SIZE, SIZE)), COLOR)
