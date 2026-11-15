class_name DodgeRock
extends RefCounted
## Roca que cruza el campo de derecha a izquierda. La silueta sale del generador con semilla (no cambia al dibujarla).
## Se duplica de la roca de la Expedición a propósito: aquella vive en una feature y pide un campo de tamaño fijo.


const VERTEX_COUNT: int = 9
const MIN_SHAPE: float = 0.75

var position: Vector2
var radius: float
## Velocidad horizontal hacia la izquierda (unidades/s) y deriva vertical (unidades/s).
var speed: float
var drift: float
## Puntos de la silueta relativos al centro.
var outline: PackedVector2Array = PackedVector2Array()


func _init(p_position: Vector2, p_radius: float, p_speed: float, p_drift: float, random: GameRandom) -> void:
    position = p_position
    radius = p_radius
    speed = p_speed
    drift = p_drift
    for k: int in range(VERTEX_COUNT):
        var angle: float = float(k) * TAU / float(VERTEX_COUNT)
        outline.append(Vector2.from_angle(angle) * radius * random.range_float(MIN_SHAPE, 1.0))


func hits(point: Vector2, point_radius: float) -> bool:
    return position.distance_to(point) < radius + point_radius
