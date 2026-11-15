extends BaseTest
## Capa 2 (regla): cada paso se cumple con su objetivo y en orden; se puede saltar.


func _lesson() -> TutorialSteps:
    var steps: Array[TutorialSteps.Step] = [
        TutorialSteps.Step.new("A", "uno", 0, 10),
        TutorialSteps.Step.new("B", "dos", 1, 20),
    ]
    return TutorialSteps.new(steps)


func test_steps_complete_by_goal_in_order() -> void:
    var lesson: TutorialSteps = _lesson()
    check(not lesson.report(20), "el objetivo de otro paso no cuenta")
    check_equal(lesson.current().title, "A", "sigue en el primero")
    check(lesson.report(10), "cumple el primero")
    check_equal(lesson.current().title, "B", "pasa al segundo")
    check(lesson.report(20), "cumple el segundo")
    check(lesson.is_done(), "terminada")
    check(lesson.current() == null, "sin paso al terminar")
    check(not lesson.report(20), "tras el final no avanza")


func test_next_and_skip() -> void:
    var lesson: TutorialSteps = _lesson()
    check(lesson.next(), "saltar un paso")
    check_equal(lesson.current().tag, 1, "segundo paso")
    lesson.skip()
    check(lesson.is_done(), "saltada entera")
