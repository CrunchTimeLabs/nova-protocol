class_name State
extends RefCounted
## Estado de una máquina de estados. `id` es el valor de un enum propio del juego (p. ej. un enum Id propio).


var id: int


func _init(p_id: int) -> void:
    id = p_id


func enter(_previous: State) -> void:
    pass


func exit(_next: State) -> void:
    pass
