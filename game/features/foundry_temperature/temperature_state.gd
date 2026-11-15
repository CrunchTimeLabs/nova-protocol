class_name TemperatureState
extends RefCounted
## Estado de la temperatura: una aguja inestable, el objetivo anunciado y el progreso de estabilización.
## Dentro del rango el progreso sube; fuera se congela y solo se avisa. Dura MATCH_SECONDS y cuenta los aciertos.
## Modo independiente (por defecto): los objetivos salen de un generador aleatorio y se puntúa estabilizar.
## Modo no independiente: quien lo compone fija los objetivos con set_target() y no hay progreso ni aciertos.
## Sin nodos: la vista lee `gauge`, `progress`, `log`, `message`, `hits` y `time_left()`.


## Se estabilizó el objetivo (suma un acierto y se anuncia otro).
signal stabilized
## La aguja está fuera del rango: el mensaje dice hacia dónde corregir.
signal alert_raised(message: String)
## Hay un objetivo nuevo (anunciado por el generador o fijado con set_target).
signal target_changed(low: float, high: float, message: String)

## Unidades por segundo que mueve el jugador mientras mantiene la tecla.
const PLAYER_RATE: float = 80.0
## Cuántas veces más rápido mueve el jugador con la ayuda activa (por ejemplo, la tecla Shift).
const BOOST_FACTOR: float = 2.5
const HOLD_SECONDS: float = 3.0
const ALERT_INTERVAL: float = 3.0
const MATCH_SECONDS: int = 20
const LOG_LINES: int = 6

## °C/s que mueve el jugador (sin la ayuda); quien compone puede cambiarla en cada paso (aceleración).
var player_rate: float = PLAYER_RATE
var gauge: UnstableGauge
var progress: ResourceMeter = ResourceMeter.new(1.0, 0.0)
var log: MessageLog = MessageLog.new(LOG_LINES)
var targets: TemperatureTargets
var hits: int = 0
var message: String = ""
var target_low: float = 0.0
var target_high: float = 0.0
## Sin objetivo todavía, cualquier valor cuenta como dentro del rango (no hay nada que corregir).
var has_target: bool = false
## Máximo de la escala de la aguja.
var scale_max: float

var _clock: Countdown = Countdown.new(MATCH_SECONDS, 1.0, 1)
var _has_own_clock: bool
var _is_finished: bool = false
var _external_left: int = MATCH_SECONDS
var _hold: float = 0.0
var _alert_elapsed: float = ALERT_INTERVAL
var _is_standalone: bool


## `seed_value` < 0: semilla aleatoria. En modo independiente el primer objetivo se anuncia al crearlo.
## `own_clock` false: el tiempo lo lleva otro (un reloj compartido): se avisa con sync_time() y finish().
## `is_standalone` false: sin generador, progreso ni aciertos; los objetivos llegan con set_target().
## `p_scale_max`: máximo de la escala de la aguja (arranca a la mitad).
func _init(
        seed_value: int = -1,
        own_clock: bool = true,
        is_standalone: bool = true,
        p_scale_max: float = UnstableGauge.SCALE_MAX,
        ) -> void:
    _has_own_clock = own_clock
    _is_standalone = is_standalone
    scale_max = p_scale_max
    gauge = UnstableGauge.new(seed_value, p_scale_max * 0.5, p_scale_max)
    targets = TemperatureTargets.new(seed_value + 1 if seed_value >= 0 else -1)
    targets.target_announced.connect(_on_target_announced)
    if _is_standalone:
        targets.announce_now()


func is_in_range() -> bool:
    if not has_target:
        return true
    return gauge.value >= target_low and gauge.value <= target_high


## Fija el objetivo desde fuera (modo no independiente): reinicia el aviso y lo anota en la bitácora.
func set_target(low: float, high: float, text: String) -> void:
    _on_target_announced(low, high, text)


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


## Un paso. `push_direction`: +1 sube, -1 baja, 0 nada (magnitud limitada a 1); `is_boosted` lo multiplica por BOOST_FACTOR.
## Terminada la partida ya no cambia nada.
func step(delta: float, push_direction: float, is_boosted: bool = false) -> void:
    if is_over() or delta <= 0.0:
        return
    if _has_own_clock:
        _clock.tick(delta)
    var rate: float = player_rate * (BOOST_FACTOR if is_boosted else 1.0)
    gauge.push(clampf(push_direction, -1.0, 1.0) * rate * delta)
    gauge.step(delta, push_direction != 0.0)
    if _is_standalone:
        targets.tick(delta)
    if not is_in_range():
        _alert_out_of_range(delta)
    elif _is_standalone:
        _hold_in_range(delta)
    else:
        _alert_elapsed = ALERT_INTERVAL    # al salir, el aviso es inmediato


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
    has_target = true
    target_low = low
    target_high = high
    message = text
    _hold = 0.0
    progress.set_value(0.0)
    _alert_elapsed = ALERT_INTERVAL
    log.add(text, true)
    target_changed.emit(low, high, text)
