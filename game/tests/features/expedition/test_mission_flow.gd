extends BaseTest
## Capa 4 (orquestador): la campaña completa en orden, con sus finales y sin transiciones ilegales.


var _flow: MissionFlow
var _seen: Array[MissionFlow.Step] = []


func before_each() -> void:
    _flow = MissionFlow.new(Expedition.new(Catalog.new()))
    _seen.clear()
    _flow.step_changed.connect(func(step: MissionFlow.Step) -> void: _seen.append(step))
    _flow.start()


func _to_first_leg() -> void:
    _flow.advance()                  # INTRO -> MAZE_BRIEF
    _flow.advance()                  # -> MAZE
    _flow.expedition.add_resource(Catalog.Res.METAL, 300)
    _flow.finish_maze(MazeRun.End.EXIT)
    _flow.advance()                  # FOUNDRY -> HOLD
    _flow.expedition.load_instrument("deposito")
    _flow.expedition.load_instrument("radiometro")
    for i: int in 5:                 # HOLD, SHIP_READY, LAUNCH, PRACTICE_BRIEF, PRACTICE
        _flow.advance()
    _flow.advance()                  # LEG_BRIEF -> LEG


func test_full_campaign_follows_the_declared_order_and_restarts() -> void:
    _to_first_leg()
    check_equal(_flow.expedition.engine.id, "rd4", "la fundición asigna motor con el metal recogido")
    _flow.finish_leg(true)
    _flow.advance()                  # ARRIVAL -> ORBIT
    _flow.expedition.add_resource(Catalog.Res.FUEL, 60)
    _flow.advance()                  # ORBIT -> JUMP_BRIEF
    _flow.advance()                  # -> LEG_BRIEF (tramo 2)
    check_equal(_flow.leg, 2, "segundo tramo")
    _flow.advance()
    _flow.finish_leg(true)
    _flow.advance()                  # ARRIVAL -> ORBIT (último planeta)
    _flow.advance()                  # -> REPORT
    var steps: Dictionary = MissionFlow.Step
    var expected: Array = [
        steps.INTRO, steps.MAZE_BRIEF, steps.MAZE, steps.FOUNDRY, steps.HOLD, steps.SHIP_READY, steps.LAUNCH,
        steps.PRACTICE_BRIEF, steps.PRACTICE, steps.LEG_BRIEF, steps.LEG, steps.ARRIVAL, steps.ORBIT,
        steps.JUMP_BRIEF, steps.LEG_BRIEF, steps.LEG, steps.ARRIVAL, steps.ORBIT, steps.REPORT,
    ]
    check_equal(_seen, expected, "secuencia completa")
    _flow.advance()
    check_equal(_flow.step, MissionFlow.Step.INTRO, "el informe abre una expedición nueva")
    check_equal(_flow.expedition.amount(Catalog.Res.METAL), 0, "y vacía")


func test_endings_without_fuel_and_with_the_ship_lost() -> void:
    _to_first_leg()
    _flow.finish_leg(true)
    _flow.advance()
    _flow.advance()
    check_equal(_flow.step, MissionFlow.Step.NO_JUMP, "sin combustible no hay salto")
    _flow.advance()
    check_equal(_flow.step, MissionFlow.Step.REPORT, "y se va al informe")
    _flow.start()
    _to_first_leg()
    _flow.finish_leg(false)
    check_equal(_flow.step, MissionFlow.Step.DESTROYED, "nave destruida")
    check(_flow.loss_reason.contains("primer tramo"), "el informe dice dónde se perdió")


func test_illegal_calls_do_not_move() -> void:
    _flow.finish_leg(true)
    check_equal(_flow.step, MissionFlow.Step.INTRO, "acabar un tramo desde la portada no hace nada")
    _flow.advance()
    _flow.advance()
    _flow.advance()
    check_equal(_flow.step, MissionFlow.Step.MAZE, "el laberinto no se salta con advance()")
