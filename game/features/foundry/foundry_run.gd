class_name FoundryRun
extends RefCounted
## Minijuego de fundición: los minerales aparecen con una vida corta y el jugador teclea su nombre para
## recogerlos. La sesión dura un temporizador fijo; las apariciones no consumen tiempo extra. Si un mineral
## expira, se pierde y no suma al contador.


enum Mineral { IRON, COPPER, GOLD }
enum End { NONE, TIME }

const NAMES: Dictionary = {
    Mineral.IRON: "Hierro",
    Mineral.COPPER: "Cobre",
    Mineral.GOLD: "Oro",
}
const TIME_LIMIT := 20.0
const MIN_LIFETIME := 4.0
const MAX_LIFETIME := 6.0
const MIN_SPAWN_INTERVAL := 0.8
const MAX_SPAWN_INTERVAL := 1.6
const MAX_ACTIVE := 3


class Spawn:
    ## Un mineral en pantalla: su tipo, la vida total que le tocó y los segundos que le quedan.
    var mineral: Mineral
    var lifetime: float
    var remaining: float

    func _init(p_mineral: Mineral, p_lifetime: float) -> void:
        mineral = p_mineral
        lifetime = p_lifetime
        remaining = p_lifetime


signal spawned(spawn: Spawn)
signal collected(spawn: Spawn)
signal expired(spawn: Spawn)
signal run_ended(result: End)

## Segundos que quedan de la sesión; nunca baja de cero.
var remaining: float = TIME_LIMIT
## Contadores por mineral: empiezan en cero y no se gastan.
var counts: Dictionary = {}
## Minerales visibles, en orden de aparición.
var active: Array[Spawn] = []
var lost: int = 0
var ended: End = End.NONE

var _random: GameRandom
var _spawn_elapsed: float = 0.0
var _next_interval: float


func _init(p_random: GameRandom) -> void:
    _random = p_random
    remaining = TIME_LIMIT
    for mineral: int in Mineral.values():
        counts[mineral] = 0
    _next_interval = _random.range_float(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)


func count(mineral: Mineral) -> int:
    return int(counts[mineral])


func is_ended() -> bool:
    return ended != End.NONE


## Avanza el temporizador, gasta la vida de cada mineral, descarta los que expiran y genera apariciones.
## Un delta no positivo se ignora. Al llegar a cero, la sesión termina y no procesa más.
func tick(delta: float) -> void:
    if is_ended() or delta <= 0.0:
        return
    remaining = maxf(remaining - delta, 0.0)
    if remaining <= 0.0:
        ended = End.TIME
        run_ended.emit(ended)
        return
    for index: int in range(active.size() - 1, -1, -1):
        var spawn: Spawn = active[index]
        spawn.remaining -= delta
        if spawn.remaining > 0.0:
            continue
        active.remove_at(index)
        lost += 1
        expired.emit(spawn)
    _spawn_elapsed += delta
    while _spawn_elapsed >= _next_interval:
        _spawn_elapsed -= _next_interval
        _next_interval = _random.range_float(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)
        _try_spawn()


## Recoge el mineral activo cuyo nombre coincide con la palabra, sin distinguir mayúsculas.
## Si hay varios iguales, se lleva el que tiene menos vida. Devuelve si recogió algo.
func collect(word: String) -> bool:
    if is_ended():
        return false
    var wanted: String = word.strip_edges().to_lower()
    if wanted.is_empty():
        return false
    var chosen: Spawn = null
    for spawn: Spawn in active:
        if String(NAMES[spawn.mineral]).to_lower() != wanted:
            continue
        if chosen == null or spawn.remaining < chosen.remaining:
            chosen = spawn
    if chosen == null:
        return false
    active.erase(chosen)
    counts[chosen.mineral] = count(chosen.mineral) + 1
    collected.emit(chosen)
    return true


func _try_spawn() -> void:
    if active.size() >= MAX_ACTIVE:
        return
    var picked: Variant = _random.pick(Mineral.values())
    var mineral: Mineral = int(picked) as Mineral
    var lifetime: float = _random.range_float(MIN_LIFETIME, MAX_LIFETIME)
    var spawn: Spawn = Spawn.new(mineral, lifetime)
    active.append(spawn)
    spawned.emit(spawn)
