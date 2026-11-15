class_name UnstableGauge
extends RefCounted
## Valor acotado con deriva aleatoria: cada CHANGE_INTERVAL elige al azar subir o bajar y se mueve a `drift_speed`.
## El jugador lo corrige con `push(amount)`. Sin nodos; el tiempo se avanza desde fuera con step(delta).
## Dos ajustes opcionales (por defecto desactivados, la deriva es la de siempre) para que el azar no choque con el jugador:
## - `wander_response` > 0: la deriva cambia de forma suave hacia una velocidad aleatoria (entre -drift_speed y +drift_speed)
##   en vez de saltar de golpe de +drift_speed a -drift_speed.
## - `push_damping` < 1: mientras el jugador empuja (step con `is_pushed`), la deriva se reduce a esa fracción.


const SCALE_MIN: float = 0.0
const SCALE_MAX: float = 600.0
## Unidades por segundo que se mueve sola.
const DRIFT_SPEED: float = 60.0
## Segundos entre cambios de dirección.
const CHANGE_INTERVAL: float = 0.6

## Ajustables (las pruebas y los labs pueden cambiarlas sin tocar las constantes).
var drift_speed: float = DRIFT_SPEED
var change_interval: float = CHANGE_INTERVAL
## Rapidez (1/s) con que la deriva alcanza su velocidad nueva; 0 = de golpe (comportamiento original).
var wander_response: float = 0.0
## Fracción de la deriva que queda mientras el jugador empuja (1 = igual que sin empujar).
var push_damping: float = 1.0
## Solo lectura desde fuera: cambia con step() y push().
var value: float:
    get:
        return _value
## Hacia dónde apunta la deriva en este tramo: +1 sube y -1 baja (con `wander_response` > 0, un valor entre -1 y 1).
var direction: float:
    get:
        return _direction

## Límites de la escala de esta aguja (por defecto SCALE_MIN a SCALE_MAX).
var scale_min: float = SCALE_MIN
var scale_max: float = SCALE_MAX

var _value: float
var _direction: float
var _drift: float = 0.0
var _elapsed: float = 0.0
var _random: GameRandom


## `seed_value` < 0: semilla aleatoria. Arranca a mitad de la escala por defecto, salvo que se indique otro valor.
## `p_scale_max` (> 0) cambia el máximo de la escala (el mínimo sigue en SCALE_MIN).
func _init(seed_value: int = -1, start: float = (SCALE_MIN + SCALE_MAX) * 0.5, p_scale_max: float = SCALE_MAX) -> void:
    assert(p_scale_max > scale_min, "UnstableGauge necesita un máximo mayor que el mínimo")
    scale_max = p_scale_max
    _random = GameRandom.new(seed_value)
    _value = clampf(start, scale_min, scale_max)
    _direction = _pick_direction()


## Mueve el valor `amount` (positivo sube, negativo baja), sin salir de la escala.
func push(amount: float) -> void:
    _value = clampf(_value + amount, scale_min, scale_max)


## Avanza `delta` segundos: deriva en la dirección actual y la cambia al cumplirse cada intervalo.
## `is_pushed`: el jugador está empujando (la deriva se reduce según `push_damping`). Un delta no positivo se ignora.
func step(delta: float, is_pushed: bool = false) -> void:
    if delta <= 0.0:
        return
    _elapsed += delta
    while _elapsed >= change_interval:
        _elapsed -= change_interval
        _direction = _pick_direction()
    var target: float = _direction * drift_speed
    if wander_response <= 0.0:
        _drift = target
    else:
        _drift = lerpf(_drift, target, 1.0 - exp(-wander_response * delta))
    var damping: float = push_damping if is_pushed else 1.0
    push(_drift * damping * delta)


func _pick_direction() -> float:
    if wander_response > 0.0:
        return _random.range_float(-1.0, 1.0)
    return 1.0 if _random.chance(0.5) else -1.0
