extends BaseTest
## Capa 2 (regla): las transiciones de StateMachine solo ocurren si están declaradas.


var _machine: StateMachine


func before_each() -> void:
    _machine = StateMachine.new()
    _machine.add_state(State.new(0))
    _machine.add_state(State.new(1))
    _machine.add_state(State.new(2))
    _machine.allow(0, [1])
    _machine.transition_to(0)


func test_rejects_illegal_transition_and_keeps_state() -> void:
    check(not _machine.transition_to(2), "0 -> 2 no está permitido")
    check(_machine.is_in(0), "una transición ilegal no cambia el estado")


func test_accepts_declared_transition() -> void:
    check(_machine.transition_to(1) and _machine.is_in(1), "0 -> 1 sí está permitido")
