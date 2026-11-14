class_name MovementProfile
extends RefCounted
## Parámetros del movimiento: velocidad tope y qué tan rápido responde el cuerpo.
## Los tiempos se piensan como "tarda X segundos"; 0 significa respuesta instantánea.
## Valores fuera de rango se limitan en el constructor, no se aceptan en silencio.


const MIN_SPEED: float = 0.001
const MIN_TURN_RESPONSE: float = 1.0

const SNAPPY_SPEED: float = 220.0
const SNAPPY_ACCEL_TIME: float = 0.05
const SNAPPY_DECEL_TIME: float = 0.05
const HEAVY_SPEED: float = 140.0
const HEAVY_ACCEL_TIME: float = 0.8
const HEAVY_DECEL_TIME: float = 0.6
const HEAVY_TURN_RESPONSE: float = 1.5
const ICY_SPEED: float = 180.0
const ICY_ACCEL_TIME: float = 0.4
const ICY_DECEL_TIME: float = 2.5

## Velocidad máxima (unidades/s).
var max_speed: float
## Segundos para pasar de quieto a max_speed.
var accel_time: float
## Segundos para pasar de max_speed a quieto.
var decel_time: float
## Multiplica la aceleración al invertir el sentido (>= 1): mayor = giro más ágil que el arranque.
var turn_response: float


func _init(p_max_speed: float, p_accel_time: float, p_decel_time: float, p_turn_response: float = MIN_TURN_RESPONSE) -> void:
    max_speed = maxf(p_max_speed, MIN_SPEED)
    accel_time = maxf(p_accel_time, 0.0)
    decel_time = maxf(p_decel_time, 0.0)
    turn_response = maxf(p_turn_response, MIN_TURN_RESPONSE)


static func snappy() -> MovementProfile:
    return MovementProfile.new(SNAPPY_SPEED, SNAPPY_ACCEL_TIME, SNAPPY_DECEL_TIME)


static func heavy() -> MovementProfile:
    return MovementProfile.new(HEAVY_SPEED, HEAVY_ACCEL_TIME, HEAVY_DECEL_TIME, HEAVY_TURN_RESPONSE)


static func icy() -> MovementProfile:
    return MovementProfile.new(ICY_SPEED, ICY_ACCEL_TIME, ICY_DECEL_TIME)


## Unidades/s² para acelerar hasta max_speed; INF si es instantáneo.
func accel_rate() -> float:
    return _rate_for(accel_time)


## Unidades/s² para frenar desde max_speed; INF si es instantáneo.
func decel_rate() -> float:
    return _rate_for(decel_time)


func _rate_for(time: float) -> float:
    return INF if time <= 0.0 else max_speed / time
