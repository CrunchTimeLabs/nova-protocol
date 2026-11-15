class_name ExpiringSet
extends RefCounted
## Conjunto de elementos con vida propia: cada uno tiene un id, una posición normalizada (0 a 1) y los segundos que le quedan.
## El tiempo se avanza desde fuera con tick(delta); lo que se agota sale solo. No usa Timer, nodos ni autoloads.


const KEY_NEXT_ID: String = "next_id"
const KEY_ITEMS: String = "items"

var _items: Dictionary = {}    # int (id) -> {"position": Vector2, "left": float}
var _next_id: int = 1


## Añade un elemento y devuelve su id (nunca se reutiliza).
func spawn(position: Vector2, lifetime: float) -> int:
    var id: int = _next_id
    _next_id += 1
    _items[id] = {"position": position, "left": lifetime}
    return id


func count() -> int:
    return _items.size()


func has(id: int) -> bool:
    return _items.has(id)


## Ids vivos, del más antiguo al más nuevo.
func ids() -> Array[int]:
    var result: Array[int] = []
    for id: Variant in _items.keys():
        result.append(id as int)
    return result


func position_of(id: int) -> Vector2:
    return (_items[id] as Dictionary)["position"] as Vector2


## Quita un elemento antes de que caduque. false si no existe (ya caducó o nunca estuvo).
func remove(id: int) -> bool:
    return _items.erase(id)


## Resta tiempo a todos y quita los agotados. Devuelve los ids que caducaron. Un delta no positivo se ignora.
func tick(delta: float) -> Array[int]:
    var expired: Array[int] = []
    if delta <= 0.0:
        return expired
    for id: int in ids():
        var item: Dictionary = _items[id] as Dictionary
        item["left"] = float(item["left"]) - delta
        if float(item["left"]) <= 0.0:
            _items.erase(id)
            expired.append(id)
    return expired


func snapshot() -> Dictionary:
    var saved_items: Array = []
    for id: int in ids():
        var item: Dictionary = _items[id] as Dictionary
        var position: Vector2 = item["position"] as Vector2
        saved_items.append({"id": id, "x": position.x, "y": position.y, "left": float(item["left"])})
    return {KEY_NEXT_ID: _next_id, KEY_ITEMS: saved_items}


func restore(saved: Dictionary) -> void:
    _items.clear()
    _next_id = int(saved.get(KEY_NEXT_ID, 1))
    for raw: Variant in saved.get(KEY_ITEMS, []) as Array:
        var entry: Dictionary = raw as Dictionary
        _items[int(entry["id"])] = {
                "position": Vector2(float(entry["x"]), float(entry["y"])),
                "left": float(entry["left"]),
                }
