class_name DodgeRock
extends RefCounted
## Roca que cruza el campo de derecha a izquierda. La silueta sale del generador con semilla (no cambia al dibujarla).
## Se duplica de la roca de la Expedición a propósito: aquella vive en una feature y pide un campo de tamaño fijo.


const VERTEX_COUNT: int = 9
const MIN_SHAPE: float = 0.74
const MAX_SHAPE: float = 1.05
const SPIN_MAX: float = 3.0

var position: Vector2
var radius: float
## Velocidad horizontal hacia la izquierda (unidades/s) y deriva vertical (unidades/s).
var speed: float
var drift: float
## Giro actual y velocidad de giro (rad y rad/s); solo afecta al dibujo.
var spin: float = 0.0
var spin_speed: float
## Puntos de la silueta relativos al centro.
var outline: PackedVector2Array = PackedVector2Array()


func _init(p_position: Vector2, p_radius: float, p_speed: float, p_drift: float, random: GameRandom) -> void:
    position = p_position
    radius = p_radius
    speed = p_speed
    drift = p_drift
    spin_speed = random.range_float(-SPIN_MAX, SPIN_MAX)
    for k: int in range(VERTEX_COUNT):
        var angle: float = float(k) * TAU / float(VERTEX_COUNT)
        outline.append(Vector2.from_angle(angle) * radius * random.range_float(MIN_SHAPE, MAX_SHAPE))


func hits(point: Vector2, point_radius: float) -> bool:
    return position.distance_to(point) < radius + point_radius
