extends BaseTest
## Capa 1 (elemento): invariantes de ResourceMeter, del que dependen todos los recursos del juego.


var _meter: ResourceMeter


func before_each() -> void:
    _meter = ResourceMeter.new(100.0, 50.0)


func test_value_never_leaves_range_and_add_reports_what_was_applied() -> void:
    check_equal(ResourceMeter.new(100.0, 150.0).current, 100.0, "el inicio no pasa del máximo")
    check_approx(_meter.add(500.0), 50.0, "al topar con el máximo devuelve solo lo aplicado")
    check_approx(_meter.add(-500.0), -100.0, "al topar con 0 devuelve solo lo aplicado")


func test_can_afford_is_exact() -> void:
    check(_meter.can_afford(50.0), "alcanza justo con el costo igual al valor")
    check(not _meter.can_afford(50.1), "no alcanza si el costo lo supera")


func test_signals_fire_once_and_only_on_real_changes() -> void:
    var hits: Dictionary = {"changed": 0, "emptied": 0, "filled": 0}
    _meter.changed.connect(func(_m: ResourceMeter) -> void: hits["changed"] += 1)
    _meter.emptied.connect(func(_m: ResourceMeter) -> void: hits["emptied"] += 1)
    _meter.filled.connect(func(_m: ResourceMeter) -> void: hits["filled"] += 1)
    _meter.set_value(50.0)
    check_equal(hits["changed"], 0, "poner el mismo valor no emite changed")
    _meter.add(-50.0)
    _meter.add(-10.0)
    check_equal(hits["emptied"], 1, "emptied se emite una sola vez al vaciarse")
    _meter.add(100.0)
    check_equal(hits["filled"], 1, "filled se emite al llegar al máximo")
