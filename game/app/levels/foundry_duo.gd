class_name FoundryDuo
extends RefCounted
## Une la fundición (FoundryRun) y la temperatura (TemperatureState) del nivel «Fundición dúo».
## - Señal continua: mientras la aguja está fuera de rango, la fundición no deja recoger (`run.blocked`).
## - Reloj compartido: manda el de la fundición; la temperatura lo sigue y termina con él.
## Compone dos features, por eso vive en `app/`. Sin nodos: el nivel llama a `step` cada paso.


var temperature: TemperatureState
var _run: FoundryRun


func _init(seed_value: int = -1) -> void:
    temperature = TemperatureState.new(seed_value, false)


## Enlaza la sesión de fundición actual (se vuelve a llamar si la sesión se reinicia).
func bind(run: FoundryRun) -> void:
    _run = run
    _sync()


func is_locked() -> bool:
    return _run != null and _run.blocked


func is_over() -> bool:
    return _run != null and _run.is_ended()


## Un paso: avanza la temperatura con el empuje del jugador (-1 baja, +1 sube), salvo que el reloj ya haya terminado.
func step(delta: float, push_direction: float) -> void:
    if _run == null:
        return
    if _run.is_ended():
        temperature.finish()
    else:
        temperature.step(delta, push_direction)
    _sync()


func _sync() -> void:
    temperature.sync_time(ceili(_run.remaining))
    _run.blocked = not temperature.is_in_range()
