class_name ThrustEngine
extends RefCounted
## Motor: convierte la orden del controlador en aceleración. Con combustible, lo gasta y empuja menos al acabarse.


## Aceleración (unidades/s²) a empuje máximo.
var max_acceleration: float
## Sin combustible (null) el motor no se agota.
var fuel: ResourceMeter
## Combustible por segundo a empuje máximo.
var burn_rate: float


func _init(p_max_acceleration: float, p_fuel: ResourceMeter = null, p_burn_rate: float = 0.0) -> void:
    max_acceleration = maxf(p_max_acceleration, 0.0)
    fuel = p_fuel
    burn_rate = maxf(p_burn_rate, 0.0)


## Aceleración para `delta` segundos de la orden `command`. Si el combustible no alcanza, el empuje se reduce en proporción.
##
## Fórmula:
##   throttle = command limitado a longitud 1       (acelerador: dirección y magnitud de 0 a 1)
##   full     = throttle * max_acceleration         (aceleración si el tanque no limitara)
##   needed   = |throttle| * burn_rate * delta      (combustible que pide este instante)
##   burned   = lo que el tanque pudo entregar de `needed` (entre 0 y needed)
##   result   = full * (burned / needed)            (la fracción de empuje que el combustible sostuvo)
##
## `burned / needed` vale 1 con combustible de sobra, entre 0 y 1 en el paso en que el tanque se agota, y 0 con el tanque vacío.
## El empuje no tiene rampa: sube y baja de golpe con la orden. Es la velocidad, al integrarse, la que cambia gradualmente.
##
## Ejemplo: max_acceleration 0.05, burn_rate 10, delta 0.1, orden (1, 0) → needed 1.0. Con 0.5 en el tanque,
## burned 0.5 y el resultado es (0.025, 0): la mitad del empuje; el tanque queda en 0.
##
## Sin medidor de combustible, con burn_rate 0 o con el motor apagado devuelve `full` sin gastar nada.
func acceleration_for(command: Vector2, delta: float) -> Vector2:
    var throttle: Vector2 = command.limit_length(1.0)
    var full: Vector2 = throttle * max_acceleration
    if fuel == null or burn_rate <= 0.0 or throttle.is_zero_approx():
        return full
    var needed: float = throttle.length() * burn_rate * delta
    var burned: float = -fuel.add(-needed)
    return full * (burned / needed)


## Estado del motor: solo el combustible actual (el resto es configuración). Vacío si no hay medidor.
func snapshot() -> Dictionary:
    if fuel == null:
        return {}
    return {"fuel": fuel.current}


func restore(saved: Dictionary) -> void:
    if fuel != null and saved.has("fuel"):
        fuel.set_value(float(saved["fuel"]))
