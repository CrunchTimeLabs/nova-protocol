class_name SlotAssembly
extends RefCounted
## Montaje por ranuras: una lista ordenada de ranuras, cada una acepta piezas de una categoría.
## Las piezas y categorías son enteros del juego que lo use. Una ranura vacía guarda EMPTY.


signal changed(slot: int)

const EMPTY := -1

var _categories: Array[int] = []
var _items: Array[int] = []


func _init(categories: Array[int]) -> void:
    _categories.assign(categories)
    _items.resize(_categories.size())
    _items.fill(EMPTY)


func slot_count() -> int:
    return _categories.size()


func category_of(slot: int) -> int:
    return _categories[slot]


## Primera ranura que acepta `category`; -1 si ninguna.
func slot_for(category: int) -> int:
    return _categories.find(category)


func item_at(slot: int) -> int:
    return _items[slot]


## Coloca `item` (de `category`) en `slot`, sustituyendo lo que hubiera. Rechaza otra categoría o ranura inválida.
func place(slot: int, item: int, category: int) -> bool:
    if slot < 0 or slot >= _categories.size() or _categories[slot] != category or item == EMPTY:
        return false
    _items[slot] = item
    changed.emit(slot)
    return true


## Vacía `slot`. Devuelve la pieza que había (EMPTY si no había).
func remove(slot: int) -> int:
    if slot < 0 or slot >= _items.size():
        return EMPTY
    var item: int = _items[slot]
    if item != EMPTY:
        _items[slot] = EMPTY
        changed.emit(slot)
    return item


func is_complete() -> bool:
    return not _items.has(EMPTY)


func clear() -> void:
    for slot: int in _items.size():
        remove(slot)


func snapshot() -> Dictionary:
    return {"items": Array(_items)}


func restore(data: Dictionary) -> void:
    var items: Array = data.get("items", []) as Array
    for slot: int in mini(items.size(), _items.size()):
        _items[slot] = int(items[slot])
