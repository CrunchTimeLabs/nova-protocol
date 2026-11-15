extends BaseTest
## Capa 1 (elemento): invariantes de Countdown, contador de tiempo que se agota en 0.


var _countdown: Countdown


func before_each() -> void:
    _countdown = Countdown.new()


func test_starts_at_ten_and_not_exhausted() -> void:
    check_equal(_countdown.value, 10, "arranca en 10")
    check(not _countdown.is_exhausted(), "no arranca agotado")


func test_reduces_one_every_two_seconds() -> void:
    _countdown.tick(1.9)
    check_equal(_countdown.value, 10, "aún no baja antes de completar el intervalo")
    _countdown.tick(0.1)
    check_equal(_countdown.value, 9, "baja 1 al completar 2.0 segundos")
    _countdown.tick(2.0)
    check_equal(_countdown.value, 8, "vuelve a bajar en el siguiente intervalo")


func test_partial_time_accumulates() -> void:
    _countdown.tick(1.5)
    _countdown.tick(0.5)
    check_equal(_countdown.value, 9, "el tiempo parcial se acumula entre ticks")


func test_large_delta_processes_every_interval() -> void:
    _countdown.tick(6.0)
    check_equal(_countdown.value, 7, "un delta grande descuenta todos los intervalos que caben")


func test_stops_at_zero_and_emits_exhausted_once() -> void:
    var emissions: Array[int] = [0]
    _countdown.exhausted.connect(func(_c: Countdown) -> void: emissions[0] += 1)
    _countdown.tick(20.0)
    check_equal(_countdown.value, 0, "se detiene en 0")
    check(_countdown.is_exhausted(), "queda marcado como agotado")
    check_equal(emissions[0], 1, "exhausted se emite una sola vez")
    _countdown.tick(2.0)
    check_equal(_countdown.value, 0, "no baja de 0 tras agotarse")
    check_equal(emissions[0], 1, "no vuelve a emitir exhausted")


func test_ignores_non_positive_delta() -> void:
    _countdown.tick(0.0)
    _countdown.tick(-5.0)
    check_equal(_countdown.value, 10, "un delta no positivo no altera el contador")


func test_configurable_start_interval_and_step() -> void:
    var custom: Countdown = Countdown.new(20, 1.0, 1)
    custom.tick(1.0)
    check_equal(custom.value, 19, "baja 1 por segundo")
    var exhausted_count: Array[int] = [0]
    custom.exhausted.connect(func(_countdown: Countdown) -> void: exhausted_count[0] += 1)
    custom.tick(30.0)
    check_equal(custom.value, 0, "llega a 0")
    check_equal(exhausted_count[0], 1, "avisa una sola vez")
