class_name UniformAcceleration
extends AccelerationSource
## Aceleración constante en una dirección: gravedad plana, viento sostenido.


var acceleration: Vector2


func _init(p_acceleration: Vector2) -> void:
    acceleration = p_acceleration


func acceleration_at(_position: Vector2, _velocity: Vector2) -> Vector2:
    return acceleration
