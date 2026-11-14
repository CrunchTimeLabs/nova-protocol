class_name Starfield
extends Node2D
## Sin fondo: conserva `field`, `velocity` y `offset()` para que las pantallas no cambien.


var field: Vector2 = Vector2(1280, 760)
var velocity: Vector2 = Vector2.ZERO


func offset() -> Vector2:
    return Vector2.ZERO
