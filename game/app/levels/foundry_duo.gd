class_name FoundryDuo
extends RefCounted
## Une la fundición (FoundryRun) y la temperatura (TemperatureState) del nivel «Fundición dúo».
## - Objetivos: cuando un mineral pasa al centro (se puede recoger), la fundición manda a la temperatura el punto de
##   fusión de ese elemento (lista fija). Con dos activos manda el más urgente; sin ninguno, se conserva el último rango.
## - Señal continua: mientras la aguja está fuera del rango y hay algo que recoger, la fundición no deja recoger (`run.blocked`).
## - Reloj compartido: manda el de la fundición; la temperatura lo sigue y termina con él.
## Compone dos features, por eso vive en `app/`. Sin nodos: el nivel llama a `step` cada paso.


## Máximo de la escala de la aguja (°C): contiene el punto de fusión más alto.
const SCALE_MAX: float = 1800.0
## Puntos de fusión (°C) de cada mineral.
const MELTING_POINTS: Dictionary = {
    FoundryRun.Mineral.GOLD: 1064.0,
    FoundryRun.Mineral.COPPER: 1085.0,
    FoundryRun.Mineral.IRON: 1538.0,
}
## Semiancho del rango objetivo alrededor del punto de fusión.
const TARGET_HALF_WIDTH: float = 25.0
## Cómo se siente la aguja: la deriva cambia suavemente (1/s) y, mientras el jugador empuja, queda en esta fracción,
## para que el azar se note sin frenar las teclas ni chocar con el turbo.
const WANDER_RESPONSE: float = 4.0
const PUSH_DAMPING: float = 0.3

var temperature: TemperatureState
var _run: FoundryRun
var _current: FoundryRun.Spawn = null


func _init(seed_value: int = -1) -> void:
    temperature = TemperatureState.new(seed_value, false, false, SCALE_MAX)
    temperature.gauge.wander_response = WANDER_RESPONSE
    temperature.gauge.push_damping = PUSH_DAMPING


## Enlaza la sesión de fundición actual (se vuelve a llamar si la sesión se reinicia).
func bind(run: FoundryRun) -> void:
    if _run != null:
        for source: Signal in [_run.selected, _run.collected, _run.expired]:
            for connection: Dictionary in source.get_connections():
                if (connection["callable"] as Callable).get_object() == self:
                    source.disconnect(connection["callable"] as Callable)
    _run = run
    _current = null
    _run.selected.connect(_on_active_changed)
    _run.collected.connect(_on_active_changed)
    _run.expired.connect(_on_active_changed)
    _refresh_target()
    _sync()


func is_locked() -> bool:
    return _run != null and _run.blocked


func is_over() -> bool:
    return _run != null and _run.is_ended()


## Un paso: avanza la temperatura con el empuje del jugador (-1 baja, +1 sube; `is_boosted` lo acelera), salvo que el reloj ya haya terminado.
func step(delta: float, push_direction: float, is_boosted: bool = false) -> void:
    if _run == null:
        return
    if _run.is_ended():
        temperature.finish()
    else:
        temperature.step(delta, push_direction, is_boosted)
    _sync()


func _sync() -> void:
    temperature.sync_time(ceili(_run.remaining))
    _run.blocked = not temperature.is_in_range() and not _run.active.is_empty()


func _on_active_changed(_spawn: FoundryRun.Spawn) -> void:
    _refresh_target()
    _sync()


## El objetivo es el del mineral más urgente; si no hay ninguno, se queda el último.
func _refresh_target() -> void:
    var urgent: FoundryRun.Spawn = null
    for spawn: FoundryRun.Spawn in _run.active:
        if urgent == null or spawn.remaining < urgent.remaining:
            urgent = spawn
    if urgent == null or urgent == _current:
        return
    _current = urgent
    var point: float = float(MELTING_POINTS[urgent.mineral])
    var low: float = point - TARGET_HALF_WIDTH
    var high: float = point + TARGET_HALF_WIDTH
    var element: String = String(FoundryRun.NAMES[urgent.mineral])
    temperature.set_target(low, high, "%s: lleva la temperatura a %d–%d °C" % [element, int(low), int(high)])
