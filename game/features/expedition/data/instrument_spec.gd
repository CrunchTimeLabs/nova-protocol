class_name InstrumentSpec
extends RefCounted
## Algo que se puede embarcar en la bodega: un analizador, un apoyo o una mejora de la nave.


enum Group { ANALYZER, SUPPORT, SHIP }

var id: String
var name: String
var mass: int
var group: Group
var description: String


func _init(p_id: String, p_name: String, p_mass: int, p_group: Group, p_description: String) -> void:
    id = p_id
    name = p_name
    mass = p_mass
    group = p_group
    description = p_description
