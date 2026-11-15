class_name TapMatch
extends MatchRules
## Reglas de la misión Tap: el emisor pide popups, el anfitrión los coloca al azar (con semilla) y el receptor los pulsa
## antes de que caduquen. Cada acierto suma un `hit`; un popup que caduca no resta. La partida dura MATCH_SECONDS.
## Sin nodos: las vistas leen `targets()`, `hits()` y `time_left()`.


const MATCH_SECONDS: float = 20.0
const TARGET_LIFETIME_SECONDS: float = 3.0
const MAX_TARGETS: int = 5
## Margen (fracción del lado) para que un popup no quede cortado en el borde.
const EDGE_MARGIN: float = 0.1
## Claves de la instantánea: cada rol ve las suyas.
const KEY_TARGETS: String = "targets"
const KEY_HITS: String = "hits"
const KEY_TIME_LEFT: String = "time_left"

var _targets: ExpiringSet = ExpiringSet.new()
var _hits: int = 0
var _time_left: float = MATCH_SECONDS
var _random: GameRandom


## `seed_value` < 0: semilla aleatoria (solo el anfitrión coloca popups; las réplicas no usan el azar).
func _init(seed_value: int = -1) -> void:
    _random = GameRandom.new(seed_value)


func targets() -> ExpiringSet:
    return _targets


func hits() -> int:
    return _hits


func time_left() -> float:
    return _time_left


func is_over() -> bool:
    return _time_left <= 0.0


## SPAWN: añade un popup si hay cupo. HIT con {"id"}: lo quita y suma un acierto. Todo lo demás se rechaza sin cambiar nada.
func apply(_slot: int, command: Command) -> bool:
    if is_over():
        return false
    match command.kind:
        TapCommand.Kind.SPAWN:
            return _spawn()
        TapCommand.Kind.HIT:
            return _hit(command.payload.get("id"))
        _:
            return false


func step(delta: float) -> void:
    if is_over():
        return
    _targets.tick(delta)
    _time_left = maxf(_time_left - delta, 0.0)


func release_slot(_slot: int) -> void:
    pass


func snapshot() -> Dictionary:
    return {KEY_TARGETS: _targets.snapshot(), KEY_HITS: _hits, KEY_TIME_LEFT: _time_left}


## Acepta instantáneas parciales: un jugador solo recibe las claves de su rol.
func restore(saved: Dictionary) -> void:
    if saved.has(KEY_TARGETS):
        _targets.restore(saved[KEY_TARGETS] as Dictionary)
    if saved.has(KEY_HITS):
        _hits = int(saved[KEY_HITS])
    if saved.has(KEY_TIME_LEFT):
        _time_left = float(saved[KEY_TIME_LEFT])


func _spawn() -> bool:
    if _targets.count() >= MAX_TARGETS:
        return false
    var position: Vector2 = Vector2(
            _random.range_float(EDGE_MARGIN, 1.0 - EDGE_MARGIN),
            _random.range_float(EDGE_MARGIN, 1.0 - EDGE_MARGIN),
            )
    _targets.spawn(position, TARGET_LIFETIME_SECONDS)
    return true


func _hit(raw_id: Variant) -> bool:
    if not (raw_id is int or raw_id is float) or not is_finite(float(raw_id)):
        return false
    if not _targets.remove(int(raw_id)):
        return false
    _hits += 1
    return true
