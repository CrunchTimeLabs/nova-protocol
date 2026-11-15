class_name CollectionSession
extends RefCounted
## Orquestador de la recolección. Se juega desde el principio; el tutorial acompaña al lado sin pausar:
## cada paso se cumple al hacer lo que enseña. El primer derrumbe abre su propia lección, que tiene
## prioridad y se cierra cuando ese derrumbe se despeja.


signal phase_changed(phase: Phase)
## Se cumplió un paso de alguna lección (para felicitar en pantalla).
signal lesson_step_completed(step: TutorialSteps.Step)
## Cambió la lección visible (abrir, cerrar o pasar de paso).
signal lesson_changed

enum Phase { PLAYING, FINISHED }
## Objetivos de los pasos del tutorial.
enum Goal { ENTER_MAZE, COLLECT_ANY, COLLECT_CRYSTAL, CAVE_IN_CLEARED, EXIT }

const TRANSITIONS: Dictionary = {
    Phase.PLAYING: [Phase.FINISHED],
    Phase.FINISHED: [],
}

var run: CollectionRun
## Tutorial inicial (null si no hay o ya se cumplió).
var intro: TutorialSteps
## Lección del derrumbe (null si no está abierta).
var cave_in_lesson: TutorialSteps

var _machine: StateMachine = StateMachine.new()
var _has_seen_cave_in: bool = false
var _lesson_cave_in: MazeCaveIns.CaveIn


## Al reiniciar se pasan en false las lecciones que ya se vieron.
func _init(p_run: CollectionRun, with_intro: bool = true, with_cave_in_lesson: bool = true) -> void:
    run = p_run
    _has_seen_cave_in = not with_cave_in_lesson
    for phase: int in TRANSITIONS.keys():
        _machine.add_state(State.new(phase))
        _machine.allow(phase, TRANSITIONS[phase])
    _machine.state_changed.connect(_on_state_changed)
    run.collected.connect(_on_collected)
    run.cave_in_started.connect(_on_cave_in_started)
    run.finished.connect(_on_finished)
    if with_intro:
        intro = intro_lesson()
        intro.step_completed.connect(_on_step_completed)
    _machine.force_state(Phase.PLAYING)


func phase() -> Phase:
    return _machine.current_id() as Phase


func has_seen_cave_in() -> bool:
    return _has_seen_cave_in


## La lección que se enseña ahora: la del derrumbe manda sobre la inicial.
func active_lesson() -> TutorialSteps:
    return cave_in_lesson if cave_in_lesson != null else intro


## Avanza la partida (el tutorial no la pausa) y comprueba los objetivos que dependen de la posición.
func tick(delta: float, direction: Vector2) -> void:
    if phase() != Phase.PLAYING:
        return
    run.step(delta, direction)
    if run.car.x >= run.origin.x:
        _report(Goal.ENTER_MAZE)
    if _lesson_cave_in != null and not run.cave_ins.active.has(_lesson_cave_in):
        _lesson_cave_in = null
        _report(Goal.CAVE_IN_CLEARED)


## Salta el paso visible sin cumplirlo.
func skip_step() -> void:
    var lesson: TutorialSteps = active_lesson()
    if lesson == null:
        return
    if lesson == cave_in_lesson:
        _lesson_cave_in = null
    lesson.next()
    _tidy()


static func intro_lesson() -> TutorialSteps:
    var steps: Array[TutorialSteps.Step] = [
        TutorialSteps.Step.new(
                "CONDUCE",
                "Usa las flechas o WASD y entra al laberinto.",
                CollectionDemo.Scene.EXIT,
                Goal.ENTER_MAZE,
                ),
        TutorialSteps.Step.new(
                "RECOGE UN MINERAL",
                "Pasa por encima de un mineral para recogerlo. La barra bajo él es el tiempo que le queda.",
                CollectionDemo.Scene.DRIVE_AND_COLLECT,
                Goal.COLLECT_ANY,
                ),
        TutorialSteps.Step.new(
                "RECOGE UN CRISTAL",
                "Si la barra se vacía, el mineral se esfuma. El cristal vale 25 pero dura menos: ve por el camino más corto.",
                CollectionDemo.Scene.VANISH,
                Goal.COLLECT_CRYSTAL,
                ),
        TutorialSteps.Step.new(
                "LA SALIDA",
                "Lo recogido va al almacén para la fundición. Cuando quieras, llega a la rampa verde para terminar.",
                CollectionDemo.Scene.EXIT,
                Goal.EXIT,
                ),
    ]
    return TutorialSteps.new(steps)


static func make_cave_in_lesson() -> TutorialSteps:
    var steps: Array[TutorialSteps.Step] = [
        TutorialSteps.Step.new(
                "¡DERRUMBE!",
                "Caen rocas y tapan pasillos un buen rato. Busca otro camino: nunca te dejan sin salida.",
                CollectionDemo.Scene.CAVE_IN,
                Goal.CAVE_IN_CLEARED,
                ),
    ]
    return TutorialSteps.new(steps)


## Pasa el objetivo a las lecciones abiertas (la inicial sigue contando aunque se vea la del derrumbe).
func _report(goal: Goal) -> void:
    var has_advanced: bool = false
    for lesson: TutorialSteps in [cave_in_lesson, intro]:
        if lesson != null and lesson.report(goal):
            has_advanced = true
    if has_advanced:
        _tidy()


func _tidy() -> void:
    if cave_in_lesson != null and cave_in_lesson.is_done():
        cave_in_lesson = null
    if intro != null and intro.is_done():
        intro = null
    lesson_changed.emit()


## Un cristal cuenta como "recoger un mineral" y como "recoger un cristal": lo que pida el paso actual.
func _on_collected(mineral: CollectionRun.Mineral, _amount: int, _where: Vector2) -> void:
    if mineral == CollectionRun.Mineral.CRYSTAL:
        _report(Goal.COLLECT_CRYSTAL)
    _report(Goal.COLLECT_ANY)


func _on_cave_in_started(cave_in: MazeCaveIns.CaveIn) -> void:
    if _has_seen_cave_in:
        return
    _has_seen_cave_in = true
    _lesson_cave_in = cave_in
    cave_in_lesson = make_cave_in_lesson()
    cave_in_lesson.step_completed.connect(_on_step_completed)
    lesson_changed.emit()


func _on_finished() -> void:
    _report(Goal.EXIT)
    _machine.transition_to(Phase.FINISHED)


func _on_step_completed(step: TutorialSteps.Step) -> void:
    lesson_step_completed.emit(step)


func _on_state_changed(_previous_id: int, current_id: int) -> void:
    phase_changed.emit(current_id as Phase)
