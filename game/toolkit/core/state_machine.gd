class_name StateMachine
extends RefCounted
## Máquina de estados con tabla de transiciones permitidas.
## Pedir una transición que no está en la tabla es un error (push_error) y no cambia nada:
## el flujo del juego es explícito y determinista. Una transición pedida desde enter()/exit() se encola.


signal state_changed(previous_id: int, current_id: int)

var current: State

var _states: Dictionary = {}       # int -> State
var _allowed: Dictionary = {}      # int -> Array de ids destino
var _pending: Array[int] = []
var _busy: bool = false


func add_state(state: State) -> void:
    _states[state.id] = state


## Declara a qué estados se puede pasar desde `from_id`.
func allow(from_id: int, to_ids: Array) -> void:
    _allowed[from_id] = to_ids


func current_id() -> int:
    return current.id if current != null else -1


func is_in(state_id: int) -> bool:
    return current != null and current.id == state_id


## Pasa a `to_id` si la tabla lo permite. Devuelve false (y avisa) si la transición es ilegal.
func transition_to(to_id: int) -> bool:
    if current != null and to_id != current.id and not (_allowed.get(current.id, []) as Array).has(to_id):
        push_error("Transición ilegal: %d -> %d" % [current.id, to_id])
        return false
    _request(to_id)
    return true


## Salta a un estado sin comprobar la tabla. Solo para restaurar una partida guardada.
func force_state(to_id: int) -> void:
    _request(to_id)


func _request(to_id: int) -> void:
    _pending.append(to_id)
    if _busy:
        return
    _busy = true
    while not _pending.is_empty():
        _apply(_pending.pop_front())
    _busy = false


func _apply(to_id: int) -> void:
    var next: State = _states[to_id]
    if next == current:
        return
    var previous: State = current
    if previous != null:
        previous.exit(next)
    current = next
    next.enter(previous)
    state_changed.emit(previous.id if previous != null else -1, next.id)
