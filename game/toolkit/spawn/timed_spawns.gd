class_name TimedSpawns
extends RefCounted
## Objetos que aparecen en casillas y desaparecen al acabar su vida, con un ritmo al azar (semilla) y un
## máximo a la vez. No sabe qué son: cada uno lleva un `kind` entero del juego que los use.
## Quien los usa decide dónde y cuánto viven: `tick` avisa cuándo toca uno nuevo y `add` lo coloca.


## Uno se agotó sin que lo recogieran.
signal expired(spawn: Spawn)


class Spawn:
    var slot: Vector2i
    var kind: int
    var lifetime: float
    var remaining: float

    func _init(p_slot: Vector2i, p_kind: int, p_lifetime: float) -> void:
        slot = p_slot
        kind = p_kind
        lifetime = p_lifetime
        remaining = p_lifetime


var items: Array[Spawn] = []

var _rng: GameRandom
var _interval_min: float
var _interval_max: float
var _max_alive: int
var _until_next: float = 0.0


func _init(rng: GameRandom, interval: Vector2, max_alive: int) -> void:
    _rng = rng
    _interval_min = interval.x
    _interval_max = interval.y
    _max_alive = max_alive


## Avanza el tiempo: quita los caducados y devuelve true si toca colocar uno nuevo.
func tick(delta: float) -> bool:
    expire(delta)
    _until_next -= delta
    if _until_next > 0.0 or items.size() >= _max_alive:
        return false
    _until_next = _rng.range_float(_interval_min, _interval_max)
    return true


## Solo pasa el tiempo de los que hay (sin pedir nuevos).
func expire(delta: float) -> void:
    for spawn: Spawn in items.duplicate():
        spawn.remaining -= delta
        if spawn.remaining <= 0.0:
            items.erase(spawn)
            expired.emit(spawn)


## Coloca uno en `slot`. Devuelve null si la casilla está ocupada, está lleno o la vida no es positiva.
func add(slot: Vector2i, kind: int, lifetime: float) -> Spawn:
    if lifetime <= 0.0 or items.size() >= _max_alive or at(slot) != null:
        return null
    var spawn: Spawn = Spawn.new(slot, kind, lifetime)
    items.append(spawn)
    return spawn


func at(slot: Vector2i) -> Spawn:
    for spawn: Spawn in items:
        if spawn.slot == slot:
            return spawn
    return null


## Retira uno (recogido). Devuelve false si ya no estaba.
func take(spawn: Spawn) -> bool:
    if not items.has(spawn):
        return false
    items.erase(spawn)
    return true
