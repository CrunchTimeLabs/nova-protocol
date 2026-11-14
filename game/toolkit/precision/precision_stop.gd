class_name PrecisionStop
extends RefCounted
## Parada de precisión: una marca oscila de lado a lado y se detiene con un toque.
## Cuanto más cerca del centro, mejor nota y mayor multiplicador. Cada uso previo la acelera.


enum Grade { PERFECT, VERY_GOOD, ACCEPTABLE, POOR, FAILED }

const BASE_SPEED := 3.1
const SPEED_PER_USE := 0.42
## Distancia máxima al centro (0-1) y multiplicador de cada nota, de mejor a peor.
const ZONES: Array = [
    [0.055, 3.0, Grade.PERFECT],
    [0.150, 2.2, Grade.VERY_GOOD],
    [0.300, 1.6, Grade.ACCEPTABLE],
    [0.520, 1.1, Grade.POOR],
    [1.001, 0.7, Grade.FAILED],
]
## Segundos que se muestra el resultado antes de terminar.
const RESULT_HOLD := 1.7

var speed: float
var elapsed: float = 0.0
var _stopped_at: float = -1.0


func _init(previous_uses: int) -> void:
    speed = BASE_SPEED + SPEED_PER_USE * float(previous_uses)


func advance(delta: float) -> void:
    elapsed += delta


func stop() -> void:
    if not is_stopped():
        _stopped_at = elapsed


func is_stopped() -> bool:
    return _stopped_at >= 0.0


func is_finished() -> bool:
    return is_stopped() and elapsed > _stopped_at + RESULT_HOLD


## Posición de la marca entre -1 (izquierda) y 1 (derecha).
func position() -> float:
    var t: float = _stopped_at if is_stopped() else elapsed
    return sin(t * speed)


func grade() -> Grade:
    return grade_for(absf(position()))


func multiplier() -> float:
    return multiplier_for(grade())


## Multiplicador de la mejor nota.
static func best_multiplier() -> float:
    return float((ZONES[0] as Array)[1])


static func grade_for(distance: float) -> Grade:
    for zone: Array in ZONES:
        if distance <= float(zone[0]):
            return int(zone[2]) as Grade
    return Grade.FAILED


static func multiplier_for(stop_grade: Grade) -> float:
    for zone: Array in ZONES:
        if int(zone[2]) == stop_grade:
            return float(zone[1])
    return 1.0
