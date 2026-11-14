class_name RoleTable
extends RefCounted
## Qué puede hacer y qué ve cada rol. Un rol es un entero (el juego lo define como enum): el toolkit no lo conoce.
## Acciones: tipos de comando permitidos. Visibilidad: claves de primer nivel de la instantánea que recibe.


var _allowed: Dictionary = {}    # int (rol) -> Array[int] (tipos de comando)
var _visible: Dictionary = {}    # int (rol) -> Array[String] (claves)


func allow(role: int, kind: int) -> void:
    var kinds: Array = _allowed.get(role, []) as Array
    if not kinds.has(kind):
        kinds.append(kind)
    _allowed[role] = kinds


func show_key(role: int, key: String) -> void:
    var keys: Array = _visible.get(role, []) as Array
    if not keys.has(key):
        keys.append(key)
    _visible[role] = keys


func has_role(role: int) -> bool:
    return _allowed.has(role) or _visible.has(role)


func can_send(role: int, kind: int) -> bool:
    return (_allowed.get(role, []) as Array).has(kind)


## Copia de la instantánea con solo las claves visibles para el rol. Un rol desconocido no ve nada.
func filter(role: int, snapshot: Dictionary) -> Dictionary:
    var view: Dictionary = {}
    for key: Variant in _visible.get(role, []) as Array:
        if snapshot.has(key):
            view[key] = snapshot[key]
    return view
