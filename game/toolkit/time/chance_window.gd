class_name ChanceWindow
extends RefCounted
## Suceso que puede ocurrir una vez por ventana de tiempo: al empezar cada ventana se decide con
## `chance` (semilla) si habrá suceso y en qué momento al azar dentro de ella. El tiempo se inyecta
## con tick(delta); un delta grande procesa todas las ventanas completas.


var window: float
var chance: float

var _rng: GameRandom
var _elapsed: float = 0.0
## Momento del suceso dentro de la ventana actual (negativo: no hay o ya ocurrió).
var _event_at: float = -1.0


func _init(rng: GameRandom, p_window: float, p_chance: float) -> void:
    if p_window <= 0.0:
        push_error("ChanceWindow: la ventana debe ser positiva")
        p_window = 1.0
    _rng = rng
    window = p_window
    chance = clampf(p_chance, 0.0, 1.0)
    _plan_window()


## Avanza el tiempo. Devuelve cuántos sucesos ocurrieron (0 o 1 por ventana recorrida).
func tick(delta: float) -> int:
    var fired: int = 0
    _elapsed += delta
    while true:
        if _event_at >= 0.0 and _elapsed >= _event_at:
            _event_at = -1.0
            fired += 1
        if _elapsed < window:
            break
        _elapsed -= window
        _plan_window()
    return fired


## Segundos que faltan para el suceso de esta ventana (negativo si no hay).
func time_to_event() -> float:
    return _event_at - _elapsed if _event_at >= 0.0 else -1.0


func _plan_window() -> void:
    _event_at = _rng.range_float(0.0, window) if _rng.chance(chance) else -1.0
