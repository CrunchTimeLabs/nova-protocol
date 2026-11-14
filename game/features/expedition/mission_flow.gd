class_name MissionFlow
extends RefCounted
## Secuencia completa de la campaña, de arriba abajo. Cada paso es una pantalla; las pantallas avisan
## al terminar y este objeto decide cuál sigue. Los pasos y sus transiciones legales se declaran en
## `TRANSITIONS`; una transición ilegal es un error visible (la `StateMachine` del toolkit).
##
##   INTRO -> MAZE_BRIEF -> MAZE -> FOUNDRY -> HOLD -> SHIP_READY -> LAUNCH
##   -> PRACTICE_BRIEF -> PRACTICE -> LEG_BRIEF -> LEG -> (DESTROYED -> REPORT) | ARRIVAL -> ORBIT
##   ORBIT -> REPORT (último planeta) | NO_JUMP -> REPORT | JUMP_BRIEF -> LEG_BRIEF (tramo 2)
##   REPORT -> INTRO (expedición nueva)


signal step_changed(step: Step)

enum Step {
    INTRO,
    MAZE_BRIEF,
    MAZE,
    FOUNDRY,
    HOLD,
    SHIP_READY,
    LAUNCH,
    PRACTICE_BRIEF,
    PRACTICE,
    LEG_BRIEF,
    LEG,
    DESTROYED,
    ARRIVAL,
    ORBIT,
    NO_JUMP,
    JUMP_BRIEF,
    REPORT,
}

## A qué pasos se puede ir desde cada uno.
const TRANSITIONS: Dictionary = {
    Step.INTRO: [Step.MAZE_BRIEF],
    Step.MAZE_BRIEF: [Step.MAZE],
    Step.MAZE: [Step.FOUNDRY],
    Step.FOUNDRY: [Step.HOLD],
    Step.HOLD: [Step.SHIP_READY],
    Step.SHIP_READY: [Step.LAUNCH],
    Step.LAUNCH: [Step.PRACTICE_BRIEF],
    Step.PRACTICE_BRIEF: [Step.PRACTICE],
    Step.PRACTICE: [Step.LEG_BRIEF],
    Step.LEG_BRIEF: [Step.LEG],
    Step.LEG: [Step.ARRIVAL, Step.DESTROYED],
    Step.DESTROYED: [Step.REPORT],
    Step.ARRIVAL: [Step.ORBIT],
    Step.ORBIT: [Step.REPORT, Step.JUMP_BRIEF, Step.NO_JUMP],
    Step.NO_JUMP: [Step.REPORT],
    Step.JUMP_BRIEF: [Step.LEG_BRIEF],
    Step.REPORT: [Step.INTRO],
}

## Paso actual (INTRO antes de start()).
var step: Step:
    get:
        return _machine.current_id() as Step if _machine.current != null else Step.INTRO
var expedition: Expedition
## Tramo en curso: 1 hacia el primer planeta, 2 hacia el segundo.
var leg: int = 1
var maze_end: MazeRun.End = MazeRun.End.NONE
## Motivo del informe cuando la nave se perdió; vacío si la campaña terminó normalmente.
var loss_reason: String = ""

var _machine: StateMachine = StateMachine.new()


func _init(p_expedition: Expedition) -> void:
    expedition = p_expedition
    for step_id: int in Step.values():
        _machine.add_state(State.new(step_id))
    for from_step: int in TRANSITIONS:
        _machine.allow(from_step, TRANSITIONS[from_step] as Array)
    _machine.state_changed.connect(_on_state_changed)


## Empieza (o reinicia) la campaña con una expedición vacía.
func start() -> void:
    expedition.reset()
    leg = 1
    maze_end = MazeRun.End.NONE
    loss_reason = ""
    _machine.force_state(Step.INTRO)


## Para los pasos que solo se leen y se cierran con un botón.
func advance() -> void:
    match step:
        Step.INTRO:
            _go(Step.MAZE_BRIEF)
        Step.MAZE_BRIEF:
            _go(Step.MAZE)
        Step.FOUNDRY:
            _go(Step.HOLD)
        Step.HOLD:
            expedition.prepare_ship()
            _go(Step.SHIP_READY)
        Step.SHIP_READY:
            _go(Step.LAUNCH)
        Step.LAUNCH:
            _go(Step.PRACTICE_BRIEF)
        Step.PRACTICE_BRIEF:
            _go(Step.PRACTICE)
        Step.PRACTICE:
            expedition.prepare_ship()
            _go(Step.LEG_BRIEF)
        Step.LEG_BRIEF:
            _go(Step.LEG)
        Step.DESTROYED:
            _go(Step.REPORT)
        Step.ARRIVAL:
            _go(Step.ORBIT)
        Step.ORBIT:
            _leave_orbit()
        Step.NO_JUMP:
            _go(Step.REPORT)
        Step.JUMP_BRIEF:
            if expedition.jump_to_next_planet():
                leg = 2
                _go(Step.LEG_BRIEF)
        Step.REPORT:
            start()
        Step.MAZE, Step.LEG:
            push_error("MissionFlow: %s termina con su propio resultado, no con advance()" % Step.keys()[step])


func finish_maze(end: MazeRun.End) -> void:
    if not _expect(Step.MAZE):
        return
    maze_end = end
    expedition.assign_engine()
    _go(Step.FOUNDRY)


func finish_leg(arrived: bool) -> void:
    if not _expect(Step.LEG):
        return
    if arrived:
        _go(Step.ARRIVAL)
        return
    loss_reason = "La nave se perdió en el primer tramo." if leg == 1 else "La nave se perdió camino del segundo planeta."
    _go(Step.DESTROYED)


func _leave_orbit() -> void:
    if expedition.next_planet() == null:
        _go(Step.REPORT)
    elif expedition.can_travel():
        _go(Step.JUMP_BRIEF)
    else:
        _go(Step.NO_JUMP)


func _expect(expected: Step) -> bool:
    if step == expected:
        return true
    push_error("MissionFlow: se esperaba %s y estamos en %s" % [Step.keys()[expected], Step.keys()[step]])
    return false


func _go(next: Step) -> void:
    _machine.transition_to(next)


func _on_state_changed(_previous_id: int, current_id: int) -> void:
    step_changed.emit(current_id as Step)
