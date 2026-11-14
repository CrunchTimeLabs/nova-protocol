class_name ManualController
extends MovementController
## Controlador con la dirección inyectada desde fuera: sirve para teclado, mando, replay o pruebas.


var _direction: Vector2 = Vector2.ZERO


## Una dirección no finita se descarta (queda quieto); una de magnitud mayor que 1 se limita a 1.
func set_direction(direction: Vector2) -> void:
    _direction = direction.limit_length(1.0) if direction.is_finite() else Vector2.ZERO


func desired_direction(_position: Vector2, _delta: float) -> Vector2:
    return _direction
