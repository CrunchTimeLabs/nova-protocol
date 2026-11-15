class_name TemperatureState
extends RefCounted
## Estado del laboratorio de temperatura: una aguja inestable, el objetivo anunciado y el progreso de estabilización.
## Dentro del rango el progreso sube; fuera se congela y solo se avisa. Dura MATCH_SECONDS y cuenta los aciertos.
## Sin nodos: la vista lee `gauge`, `progress`, `log`, `message`, `hits` y `time_left()`.


## Se estabilizó el objetivo (suma un acierto y se anuncia otro).
signal stabilized
## La aguja está fuera del rango: el mensaje dice hacia dónde corregir.
signal alert_raised(message: String)

## Unidades por segundo que mueve el jugador mientras mantiene la tecla.
const PLAYER_RATE: float = 80.0
const HOLD_SECONDS: float = 3.0
const ALERT_INTERVAL: float = 3.0
const MATCH_SECONDS: int = 20
const LOG_LINES: int = 6

var gauge: UnstableGauge
var progress: ResourceMeter = ResourceMeter.new(1.0, 0.0)
var log: MessageLog = MessageLog.new(LOG_LINES)
var targets: TemperatureTargets
var hits: int = 0
var message: String = ""
var target_low: float = 0.0
var target_high: float = 0.0

var _clock: Countdown = Countdown.new(MATCH_SECONDS, 1.0, 1)
var _has_own_clock: bool
var _is_finished: bool = false
var _external_left: int = MATCH_SECONDS
var _hold: float = 0.0
var _alert_elapsed: float = ALERT_INTERVAL


## `seed_value` < 0: semilla aleatoria. El primer objetivo se anuncia al crearlo.
## `own_clock` false: el tiempo lo lleva otro (un reloj compartido): se avisa con sync_time() y finish().
func _init(seed_value: int = -1, own_clock: bool = true) -> void:
    _has_own_clock = own_clock
    gauge = UnstableGauge.new(seed_value)
    targets = TemperatureTargets.new(seed_value + 1 if seed_value >= 0 else -1)
    targets.target_announced.connect(_on_target_announced)
    targets.announce_now()


func is_in_range() -> bool:
    return gauge.value >= target_low and gauge.value <= target_high


func is_over() -> bool:
    return _is_finished or _clock.is_exhausted()


## Segundos que quedan.
func time_left() -> int:
    return _clock.value if _has_own_clock else _external_left


## Termina la partida desde fuera (con reloj compartido).
func finish() -> void:
    _is_finished = true


## Con reloj compartido: segundos que quedan según quien lo lleva.
func sync_time(seconds_left: int) -> void:
    _external_left = seconds_left


## Un paso. `push_direction`: +1 sube, -1 baja, 0 nada (magnitud limitada a 1). Terminada la partida ya no cambia nada.
func step(delta: float, push_direction: float) -> void:
    if is_over() or delta <= 0.0:
        return
    if _has_own_clock:
        _clock.tick(delta)
    gauge.push(clampf(push_direction, -1.0, 1.0) * PLAYER_RATE * delta)
    gauge.step(delta)
    targets.tick(delta)
    if is_in_range():
        _hold_in_range(delta)
    else:
        _alert_out_of_range(delta)


func _hold_in_range(delta: float) -> void:
    _alert_elapsed = ALERT_INTERVAL    # al salir, el aviso es inmediato
    _hold += delta
    progress.set_value(_hold / HOLD_SECONDS)
    if _hold >= HOLD_SECONDS:
        hits += 1
        stabilized.emit()
        targets.announce_now()


func _alert_out_of_range(delta: float) -> void:
    _alert_elapsed += delta
    if _alert_elapsed < ALERT_INTERVAL:
        return
    _alert_elapsed = 0.0
    var hint: String = "sube" if gauge.value < target_low else "baja"
    var alert: String = "Fuera de rango: %s la temperatura" % hint
    log.add(alert, true)
    alert_raised.emit(alert)


func _on_target_announced(low: float, high: float, text: String) -> void:
    target_low = low
    target_high = high
    message = text
    _hold = 0.0
    progress.set_value(0.0)
    _alert_elapsed = ALERT_INTERVAL
    log.add(text, true)
