class_name HangarSession
extends RefCounted
## Orquestador del hangar: se arma el cohete; con las 5 secciones llenas puede despegar. Durante el despegue
## no se toca el cohete; al llegar a órbita, un momento después, se vuelve a armar (el cohete se conserva).


signal phase_changed(phase: Phase)

enum Phase { BUILDING, LAUNCHING, IN_ORBIT }

const TRANSITIONS: Dictionary = {
    Phase.BUILDING: [Phase.LAUNCHING],
    Phase.LAUNCHING: [Phase.IN_ORBIT],
    Phase.IN_ORBIT: [Phase.BUILDING],
}
## Segundos del despegue (cuenta atrás + ascenso).
const LAUNCH_TIME := 7.5
const COUNTDOWN_TIME := 3.0
## Segundos mostrando "en órbita" antes de volver al hangar.
const ORBIT_TIME := 2.5

var build: RocketBuild = RocketBuild.new()
## Segundos en la fase actual.
var phase_time: float = 0.0

var _machine: StateMachine = StateMachine.new()


func _init() -> void:
    for phase: int in TRANSITIONS.keys():
        _machine.add_state(State.new(phase))
        _machine.allow(phase, TRANSITIONS[phase])
    _machine.state_changed.connect(_on_state_changed)
    _machine.force_state(Phase.BUILDING)


func phase() -> Phase:
    return _machine.current_id() as Phase


func can_edit() -> bool:
    return phase() == Phase.BUILDING


## Coloca una pieza (solo armando). Devuelve si se colocó.
func place(part: RocketParts.Part) -> bool:
    if not can_edit():
        return false
    build.place(part)
    return true


func remove(section: RocketParts.Section) -> bool:
    if not can_edit():
        return false
    return build.remove(section) != -1


func clear() -> void:
    if can_edit():
        build.clear()


## Despega si se está armando y el cohete está completo.
func launch() -> bool:
    if phase() != Phase.BUILDING or not build.is_complete():
        return false
    return _machine.transition_to(Phase.LAUNCHING)


func tick(delta: float) -> void:
    phase_time += delta
    match phase():
        Phase.LAUNCHING:
            if phase_time >= LAUNCH_TIME:
                _machine.transition_to(Phase.IN_ORBIT)
        Phase.IN_ORBIT:
            if phase_time >= ORBIT_TIME:
                _machine.transition_to(Phase.BUILDING)
        Phase.BUILDING:
            pass


## 0 durante la cuenta atrás; de 0 a 1 mientras sube.
func ascent() -> float:
    if phase() != Phase.LAUNCHING:
        return 0.0
    return clampf((phase_time - COUNTDOWN_TIME) / (LAUNCH_TIME - COUNTDOWN_TIME), 0.0, 1.0)


## Segundos de cuenta atrás que quedan (0 si ya despegó o no se está despegando).
func countdown() -> float:
    if phase() != Phase.LAUNCHING:
        return 0.0
    return maxf(0.0, COUNTDOWN_TIME - phase_time)


func _on_state_changed(_previous_id: int, current_id: int) -> void:
    phase_time = 0.0
    phase_changed.emit(current_id as Phase)
