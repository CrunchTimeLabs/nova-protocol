class_name Countdown
extends RefCounted
## Contador que empieza en un valor fijo y baja un paso cada intervalo de tiempo.
## El tiempo se avanza desde fuera con tick(delta); no usa Timer, nodos ni autoloads.
## Al llegar a 0 se detiene y emite exhausted una sola vez.


signal exhausted(countdown: Countdown)

const START_VALUE: int = 10
const INTERVAL_SECONDS: float = 2.0
const STEP: int = 1

## Solo lectura desde fuera: cambia con tick().
var value: int:
    get:
        return _value

var _value: int
var _interval: float
var _step: int
var _elapsed: float = 0.0
var _is_exhausted: bool = false


## Sin argumentos usa los valores por defecto (10, cada 2 s, de 1 en 1).
func _init(p_start: int = START_VALUE, p_interval: float = INTERVAL_SECONDS, p_step: int = STEP) -> void:
    assert(p_interval > 0.0 and p_step > 0, "Countdown necesita intervalo y paso positivos")
    _value = p_start
    _interval = p_interval
    _step = p_step


func is_exhausted() -> bool:
    return _is_exhausted


## Acumula tiempo y descuenta un paso por cada intervalo completo.
## Un delta no positivo se ignora; al agotarse, no se vuelve a procesar.
func tick(delta: float) -> void:
    if _is_exhausted or delta <= 0.0:
        return
    _elapsed += delta
    while _elapsed >= _interval:
        _elapsed -= _interval
        _value = maxi(_value - _step, 0)
        if _value == 0:
            _is_exhausted = true
            _elapsed = 0.0
            exhausted.emit(self)
            return
