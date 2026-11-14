class_name CentralGravity
extends AccelerationSource
## Atracción hacia un punto fijo: a = gm * d / (|d|² + softening²)^(3/2).
## El suavizado evita que la aceleración explote al pasar por el centro.


const DEFAULT_SOFTENING: float = 0.001

var center: Vector2
## Parámetro gravitacional (G * masa), en mundos³/s² (mundo normalizado).
var gm: float
var softening: float


func _init(p_center: Vector2, p_gm: float, p_softening: float = DEFAULT_SOFTENING) -> void:
    center = p_center
    gm = p_gm
    softening = maxf(p_softening, 0.0)


func acceleration_at(position: Vector2, _velocity: Vector2) -> Vector2:
    var offset: Vector2 = center - position
    var distance_squared: float = offset.length_squared() + softening * softening
    if distance_squared <= 0.0:
        return Vector2.ZERO
    return offset * (gm / (distance_squared * sqrt(distance_squared)))
