extends BaseTest
## Capa 1 (elemento): invariantes de TimedCycle, ciclo que avanza al acumular tiempo.


var _cycle: TimedCycle


func before_each() -> void:
    var durations: Array[float] = [3.0, 1.0, 2.0]
    _cycle = TimedCycle.new(durations)


func test_starts_at_first_step_without_elapsed_time() -> void:
    check_equal(_cycle.index, 0, "arranca en el primer paso")
    check_approx(_cycle.elapsed(), 0.0, "arranca sin tiempo acumulado")


func test_advances_at_exact_boundary_not_before() -> void:
    _cycle.tick(2.999)
    check_equal(_cycle.index, 0, "no avanza antes de cumplir el intervalo")
    _cycle.tick(0.001)
    check_equal(_cycle.index, 1, "avanza justo al cumplir el intervalo")


func test_partial_time_accumulates() -> void:
    _cycle.tick(1.5)
    _cycle.tick(1.5)
    check_equal(_cycle.index, 1, "el tiempo parcial se acumula entre ticks")


func test_large_delta_processes_every_step_and_keeps_rest() -> void:
    var visited: Array[int] = []
    _cycle.stepped.connect(func(_previous: int, new_index: int) -> void: visited.append(new_index))
    _cycle.tick(7.5)
    var expected: Array[int] = [1, 2, 0]
    check_equal(visited, expected, "emite un paso por cada intervalo completado")
    check_equal(_cycle.index, 0, "vuelve al primer paso tras dar la vuelta")
    check_approx(_cycle.elapsed(), 1.5, "conserva el resto de tiempo")


func test_wraps_to_first_step_at_cycle_boundary() -> void:
    _cycle.tick(6.0)
    check_equal(_cycle.index, 0, "vuelve al inicio al completar todos los pasos")
    check_approx(_cycle.elapsed(), 0.0, "sin tiempo sobrante en el límite")


func test_ignores_non_positive_delta() -> void:
    _cycle.tick(0.0)
    _cycle.tick(-2.0)
    check_equal(_cycle.index, 0, "un delta no positivo no avanza")
    check_approx(_cycle.elapsed(), 0.0, "un delta no positivo no acumula")


func test_reset_returns_to_first_step() -> void:
    _cycle.tick(4.0)
    _cycle.reset()
    check_equal(_cycle.index, 0, "reset vuelve al primer paso")
    check_approx(_cycle.elapsed(), 0.0, "reset borra el tiempo acumulado")
