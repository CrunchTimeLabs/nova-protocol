class_name SmelterRun
extends RefCounted
## Fundición de la campaña a dos: las menas recogidas en el laberinto (`pool`) pasan por la tolva en grupos de
## 3 o 4; de cada grupo, 1 o 2 van al centro con su propio reloj. Quien teclea escribe el ELEMENTO PURO de la
## mena (Bauxita → aluminio; sin tildes también vale). Mientras la temperatura está fuera de rango (`blocked`),
## no se puede fundir. Cada metal fundido por encima del mínimo desbloquea la siguiente pieza de cohete.
## El reloj del nivel no corre hasta `start()` (los dos terminaron su tutorial).


signal group_spawned(added: Array[Spawn])
signal selected(spawn: Spawn)
signal smelted(spawn: Spawn)
signal expired(spawn: Spawn)
signal part_unlocked(part: RocketParts.Part)
signal finished

enum Status { WAITING, TARGET, SMELTED, LOST }

const TIME_LIMIT := 45.0
## Metales que hay que fundir para pasar; desde ahí, cada uno desbloquea una pieza.
const MINIMUM := 3
const MIN_GROUP := 3
const MAX_GROUP := 4
const MIN_PICK := 1
const MAX_PICK := 2
const FIRST_DELAY := 0.6
const ROUND_DELAY := 0.7
## Segundos para fundir cada mena en el centro: la rara aprieta más.
const LIFETIMES: Dictionary = {
    Ores.Ore.ILMENITE: Vector2(7.0, 8.0),
    Ores.Ore.PENTLANDITE: Vector2(8.0, 9.0),
    Ores.Ore.CHALCOPYRITE: Vector2(8.5, 9.5),
    Ores.Ore.BAUXITE: Vector2(9.0, 10.0),
    Ores.Ore.HEMATITE: Vector2(9.5, 10.5),
}
## Si se juega sin pasar por el laberinto: unas pocas de cada una.
const FALLBACK_EACH := 3


class Spawn:
    var ore: Ores.Ore
    var status: Status = Status.WAITING
    var lifetime: float = 0.0
    var remaining: float = 0.0

    func _init(p_ore: Ores.Ore) -> void:
        ore = p_ore

    func start(p_lifetime: float) -> void:
        status = Status.TARGET
        lifetime = p_lifetime
        remaining = p_lifetime

    func ratio() -> float:
        return clampf(remaining / lifetime, 0.0, 1.0) if lifetime > 0.0 else 0.0


## Menas que quedan por entrar (Ores.Ore -> unidades).
var pool: Dictionary = {}
var waiting: Array[Spawn] = []
var active: Array[Spawn] = []
## Metales puros fundidos (Ores.Ore -> unidades).
var metals: Dictionary = {}
var lost: int = 0
var remaining: float = TIME_LIMIT
var is_started: bool = false
var is_finished: bool = false
## Lo pone quien lleva la temperatura: fuera de rango no se funde.
var blocked: bool = false
var unlocked: Array[RocketParts.Part] = []

var _random: GameRandom
var _wait: float = ROUND_DELAY - FIRST_DELAY


func _init(p_random: GameRandom, ores: Dictionary = {}) -> void:
    _random = p_random
    for ore: Ores.Ore in Ores.all():
        pool[ore] = int(ores.get(ore, 0))
        metals[ore] = 0
    if total_pool() == 0:
        for ore: Ores.Ore in Ores.all():
            pool[ore] = FALLBACK_EACH


func total_pool() -> int:
    var total: int = 0
    for amount: int in pool.values():
        total += amount
    return total


func total_metals() -> int:
    var total: int = 0
    for amount: int in metals.values():
        total += amount
    return total


func has_passed() -> bool:
    return total_metals() >= MINIMUM


func start() -> void:
    is_started = true


## Quita tildes y pasa a minúsculas: «Níquel» y «niquel» valen igual (el teclado del juego no escribe tildes).
static func plain(text: String) -> String:
    var lowered: String = text.strip_edges().to_lower()
    for pair: Array in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"]]:
        lowered = lowered.replace(str(pair[0]), str(pair[1]))
    return lowered


## La respuesta de una mena: el nombre de su elemento puro, sin tildes.
static func answer(ore: Ores.Ore) -> String:
    return plain(Ores.element(ore))


func tick(delta: float) -> void:
    if not is_started or is_finished or delta <= 0.0:
        return
    remaining = maxf(0.0, remaining - delta)
    if remaining <= 0.0:
        _finish()
        return
    for index: int in range(active.size() - 1, -1, -1):
        var spawn: Spawn = active[index]
        spawn.remaining = maxf(0.0, spawn.remaining - delta)
        if spawn.remaining > 0.0:
            continue
        active.remove_at(index)
        spawn.status = Status.LOST
        lost += 1
        expired.emit(spawn)
    if not active.is_empty():
        return
    if waiting.is_empty() and total_pool() == 0:
        _finish()
        return
    _wait += delta
    if _wait >= ROUND_DELAY:
        _wait = 0.0
        _next_round()


## Funde el objetivo cuyo elemento coincide con la palabra (el más urgente si hay varios). Bloqueado no funde.
func smelt(word: String) -> bool:
    if not is_started or is_finished or blocked:
        return false
    var wanted: String = plain(word)
    if wanted.is_empty():
        return false
    var chosen: Spawn = null
    for spawn: Spawn in active:
        if answer(spawn.ore) == wanted and (chosen == null or spawn.remaining < chosen.remaining):
            chosen = spawn
    if chosen == null:
        return false
    active.erase(chosen)
    chosen.status = Status.SMELTED
    metals[chosen.ore] = int(metals[chosen.ore]) + 1
    smelted.emit(chosen)
    var extra: int = total_metals() - MINIMUM
    if extra > 0 and extra <= RocketParts.UNLOCK_ORDER.size():
        var part: RocketParts.Part = RocketParts.UNLOCK_ORDER[extra - 1]
        unlocked.append(part)
        part_unlocked.emit(part)
    return true


## ¿Puede `typed` ser el comienzo de la respuesta de algún objetivo?
func is_prefix(typed: String) -> bool:
    var wanted: String = plain(typed)
    for spawn: Spawn in active:
        if answer(spawn.ore).begins_with(wanted):
            return true
    return false


func _next_round() -> void:
    var size: int = _random.range_int(MIN_GROUP, MAX_GROUP)
    var added: Array[Spawn] = []
    while waiting.size() < size and total_pool() > 0:
        var spawn: Spawn = Spawn.new(_draw_ore())
        waiting.append(spawn)
        added.append(spawn)
    if not added.is_empty():
        group_spawned.emit(added)
    var picks: int = mini(_random.range_int(MIN_PICK, MAX_PICK), waiting.size())
    for i: int in picks:
        var spawn: Spawn = waiting[_random.range_int(0, waiting.size() - 1)]
        waiting.erase(spawn)
        var span: Vector2 = LIFETIMES[spawn.ore]
        spawn.start(_random.range_float(span.x, span.y))
        active.append(spawn)
        selected.emit(spawn)


## Saca una mena del montón, con probabilidad según cuántas quedan de cada tipo.
func _draw_ore() -> Ores.Ore:
    var roll: int = _random.range_int(1, total_pool())
    for ore: Ores.Ore in Ores.all():
        roll -= int(pool[ore])
        if roll <= 0:
            pool[ore] = int(pool[ore]) - 1
            return ore
    return Ores.Ore.HEMATITE


func _finish() -> void:
    if is_finished:
        return
    is_finished = true
    finished.emit()
