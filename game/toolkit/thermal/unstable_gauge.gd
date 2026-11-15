class_name UnstableGauge
extends RefCounted
## Valor acotado con deriva aleatoria: cada CHANGE_INTERVAL elige al azar subir o bajar y se mueve a `drift_speed`.
## El jugador lo corrige con `push(amount)`. Sin nodos; el tiempo se avanza desde fuera con step(delta).


const SCALE_MIN: float = 0.0
const SCALE_MAX: float = 600.0
## Unidades por segundo que se mueve sola.
const DRIFT_SPEED: float = 25.0
## Segundos entre cambios de dirección.
const CHANGE_INTERVAL: float = 0.8

## Ajustables (las pruebas y los labs pueden cambiarlas sin tocar las constantes).
var drift_speed: float = DRIFT_SPEED
var change_interval: float = CHANGE_INTERVAL
## Solo lectura desde fuera: cambia con step() y push().
var value: float:
    get:
        return _value
## +1 sube, -1 baja.
var direction: float:
    get:
        return _direction

var _value: float
var _direction: float
var _elapsed: float = 0.0
var _random: GameRandom


## `seed_value` < 0: semilla aleatoria. Arranca a mitad de la escala salvo que se indique otro valor.
func _init(seed_value: int = -1, start: float = (SCALE_MIN + SCALE_MAX) * 0.5) -> void:
    _random = GameRandom.new(seed_value)
    _value = clampf(start, SCALE_MIN, SCALE_MAX)
    _direction = _pick_direction()


## Mueve el valor `amount` (positivo sube, negativo baja), sin salir de la escala.
func push(amount: float) -> void:
    _value = clampf(_value + amount, SCALE_MIN, SCALE_MAX)


## Avanza `delta` segundos: deriva en la dirección actual y la cambia al cumplirse cada intervalo. Un delta no positivo se ignora.
func step(delta: float) -> void:
    if delta <= 0.0:
        return
    _elapsed += delta
    while _elapsed >= change_interval:
        _elapsed -= change_interval
        _direction = _pick_direction()
    push(_direction * drift_speed * delta)


func _pick_direction() -> float:
    return 1.0 if _random.chance(0.5) else -1.0
