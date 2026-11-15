class_name DodgeWave
extends RefCounted
## Onda expansiva: un círculo que nace en `center` y crece. Golpea una sola vez cuando su banda alcanza un punto.
## Se duplica de la onda de la Expedición a propósito: aquella vive en una feature (regla 1) y el alcance aquí es un parámetro.


const START_RADIUS: float = 10.0
## Grosor de la banda: golpea a quien esté dentro de ella (el viento solar tiene cuerpo, no es una línea).
const THICKNESS: float = 40.0

var center: Vector2
var radius: float = START_RADIUS
## Unidades de radio por segundo.
var speed: float
var max_radius: float
var has_hit: bool = false


func _init(p_center: Vector2, p_speed: float, p_max_radius: float) -> void:
    center = p_center
    speed = p_speed
    max_radius = p_max_radius


func advance(delta: float) -> void:
    radius += speed * delta


func is_gone() -> bool:
    return radius > max_radius


func reaches(point: Vector2, other_radius: float) -> bool:
    return absf(point.distance_to(center) - radius) < other_radius + THICKNESS * 0.5
