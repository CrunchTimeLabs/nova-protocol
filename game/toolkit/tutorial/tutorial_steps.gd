class_name TutorialSteps
extends RefCounted
## Lección en pasos que se cumplen haciendo: cada paso tiene título, texto, una etiqueta (qué demostración
## enseñar) y un objetivo (entero del juego). `report(goal)` avanza si es el objetivo del paso actual.


signal step_completed(step: Step)

class Step:
    var title: String
    var body: String
    var tag: int
    var goal: int

    func _init(p_title: String, p_body: String, p_tag: int, p_goal: int) -> void:
        title = p_title
        body = p_body
        tag = p_tag
        goal = p_goal


var index: int:
    get:
        return _index

var _steps: Array[Step] = []
var _index: int = 0


func _init(steps: Array[Step]) -> void:
    if steps.is_empty():
        push_error("TutorialSteps: necesita al menos un paso")
    _steps.assign(steps)


func count() -> int:
    return _steps.size()


func is_done() -> bool:
    return _index >= _steps.size()


## Paso actual; null si ya terminó.
func current() -> Step:
    return null if is_done() else _steps[_index]


## El jugador cumplió `goal`: si es el del paso actual, pasa al siguiente. Devuelve si avanzó.
func report(goal: int) -> bool:
    var step: Step = current()
    if step == null or step.goal != goal:
        return false
    _index += 1
    step_completed.emit(step)
    return true


## Salta el paso actual sin cumplirlo. Devuelve false si ya no quedan.
func next() -> bool:
    if is_done():
        return false
    _index += 1
    return not is_done()


func skip() -> void:
    _index = _steps.size()
