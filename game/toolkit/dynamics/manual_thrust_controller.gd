class_name ManualThrustController
extends ThrustController
## Orden de empuje inyectada desde fuera: sirve para teclado, mando, replay o pruebas.


var _command: Vector2 = Vector2.ZERO


## Una orden no finita se descarta (motor apagado); una de magnitud mayor que 1 se limita a 1.
func set_command(command: Vector2) -> void:
    _command = command.limit_length(1.0) if command.is_finite() else Vector2.ZERO


func thrust_command(_position: Vector2, _velocity: Vector2, _delta: float) -> Vector2:
    return _command
