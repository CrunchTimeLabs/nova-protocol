class_name FoundryRun
extends RefCounted
## Minijuego de fundición (guion de MAYBER). Dos relojes independientes:
## - el del nivel (20 s, el reloj de arena): al agotarse se detiene todo;
## - el de cada mineral (4–7 s según su tipo), que solo arranca cuando el mineral es elegido y va al centro.
## Por ronda sale un grupo de 3 o 4 minerales a la tolva (cada mineral nuevo gasta recursos); de la tolva se
## eligen al azar 1 o 2 que pasan al centro como objetivos. Los no elegidos se quedan esperando y entran en el
## grupo siguiente. El jugador teclea el nombre para recoger un objetivo; si su tiempo se agota, desaparece y
## los recursos gastados en él se pierden. La ronda siguiente empieza cuando el centro queda vacío.


enum Mineral { IRON, COPPER, GOLD }
enum End { NONE, TIME }
enum Status { WAITING, TARGET, COLLECTED, LOST }

const NAMES: Dictionary = {
    Mineral.IRON: "Hierro",
    Mineral.COPPER: "Cobre",
    Mineral.GOLD: "Oro",
}
const TIME_LIMIT := 20.0
const MIN_LIFETIME := 4.0
const MAX_LIFETIME := 7.0
## Oro: raro, valioso y con poco tiempo. Cobre: común, barato y con más tiempo. Hierro: intermedio.
const WEIGHTS: Dictionary = {Mineral.IRON: 33, Mineral.COPPER: 50, Mineral.GOLD: 17}
const VALUES: Dictionary = {Mineral.IRON: 20, Mineral.COPPER: 10, Mineral.GOLD: 50}
const LIFETIMES: Dictionary = {
    Mineral.IRON: Vector2(5.0, 6.0),
    Mineral.COPPER: Vector2(6.0, 7.0),
    Mineral.GOLD: Vector2(4.0, 5.0),
}
## Recursos que cuesta generar cada mineral (no se devuelven si se pierde).
const COSTS: Dictionary = {Mineral.IRON: 2, Mineral.COPPER: 1, Mineral.GOLD: 4}
## Recursos totales del nivel: cada mineral nuevo gasta uno.
const RESOURCE_TOTAL := 100
const MIN_GROUP := 3
const MAX_GROUP := 4
const MIN_PICK := 1
const MAX_PICK := 2
## Pausa antes del primer grupo y entre una ronda y la siguiente.
const FIRST_DELAY := 0.8
const ROUND_DELAY := 0.6


class Spawn:
    ## Un mineral: su tipo y estado. `lifetime`/`remaining` valen 0 hasta que es elegido (su reloj arranca ahí).
    var mineral: Mineral
    var status: Status = Status.WAITING
    var lifetime: float = 0.0
    var remaining: float = 0.0

    func _init(p_mineral: Mineral, p_lifetime: float = 0.0) -> void:
        mineral = p_mineral
        if p_lifetime > 0.0:
            start(p_lifetime)

    ## Pasa al centro y arranca su reloj.
    func start(p_lifetime: float) -> void:
        status = Status.TARGET
        lifetime = p_lifetime
        remaining = p_lifetime

    func ratio() -> float:
        return clampf(remaining / lifetime, 0.0, 1.0) if lifetime > 0.0 else 0.0


signal group_spawned(added: Array[Spawn])
signal selected(spawn: Spawn)
signal collected(spawn: Spawn)
signal expired(spawn: Spawn)
signal run_ended(result: End)

## Segundos que quedan del nivel; nunca baja de cero.
var remaining: float = TIME_LIMIT
## Unidades recogidas por mineral.
var counts: Dictionary = {}
## Minerales en la tolva, esperando ser elegidos (sin reloj).
var waiting: Array[Spawn] = []
## Objetivos en el centro, cada uno con su reloj.
var active: Array[Spawn] = []
var lost: int = 0
## Recursos que quedan del total del nivel; baja de uno en uno con cada mineral nuevo.
var resources: int = RESOURCE_TOTAL
var resources_used: int = 0
var resources_lost: int = 0
var value: int = 0
var rounds: int = 0
var ended: End = End.NONE

var _random: GameRandom
var _wait: float = 0.0


func _init(p_random: GameRandom) -> void:
    _random = p_random
    for mineral: int in Mineral.values():
        counts[mineral] = 0
    _wait = ROUND_DELAY - FIRST_DELAY


func count(mineral: Mineral) -> int:
    return int(counts[mineral])


func is_ended() -> bool:
    return ended != End.NONE


## Avanza el reloj del nivel y el de cada objetivo; descarta los que se agotan y, con el centro vacío,
## lanza la ronda siguiente. Un delta no positivo se ignora. Al llegar a cero se detiene todo.
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
        spawn.remaining = maxf(spawn.remaining - delta, 0.0)
        if spawn.remaining > 0.0:
            continue
        active.remove_at(index)
        spawn.status = Status.LOST
        lost += 1
        resources_lost += int(COSTS[spawn.mineral])
        expired.emit(spawn)
    if not active.is_empty():
        return
    _wait += delta
    if _wait >= ROUND_DELAY:
        _wait = 0.0
        _next_round()


## Recoge el objetivo cuyo nombre coincide con la palabra, sin distinguir mayúsculas.
## Si hay varios iguales, se lleva el que tiene menos tiempo. Los demás relojes no cambian.
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
    chosen.status = Status.COLLECTED
    counts[chosen.mineral] = count(chosen.mineral) + 1
    value += int(VALUES[chosen.mineral])
    collected.emit(chosen)
    return true


## Completa la tolva hasta un grupo de 3 o 4 (lo nuevo gasta recursos) y elige 1 o 2 para el centro.
func _next_round() -> void:
    rounds += 1
    var size: int = _random.range_int(MIN_GROUP, MAX_GROUP)
    var added: Array[Spawn] = []
    while waiting.size() < size:
        var spawn: Spawn = Spawn.new(_random_mineral())
        resources = maxi(resources - 1, 0)
        resources_used += int(COSTS[spawn.mineral])
        waiting.append(spawn)
        added.append(spawn)
    group_spawned.emit(added)
    var picks: int = mini(_random.range_int(MIN_PICK, MAX_PICK), waiting.size())
    for i: int in picks:
        var spawn: Spawn = waiting[_random.range_int(0, waiting.size() - 1)]
        waiting.erase(spawn)
        var span: Vector2 = LIFETIMES[spawn.mineral]
        spawn.start(_random.range_float(span.x, span.y))
        active.append(spawn)
        selected.emit(spawn)


func _random_mineral() -> Mineral:
    var total: int = 0
    for mineral: int in WEIGHTS.keys():
        total += int(WEIGHTS[mineral])
    var roll: int = _random.range_int(1, total)
    for mineral: int in WEIGHTS.keys():
        roll -= int(WEIGHTS[mineral])
        if roll <= 0:
            return mineral as Mineral
    return Mineral.COPPER
