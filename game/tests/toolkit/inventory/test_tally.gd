extends BaseTest
## Capa 1 (elemento): el almacén solo suma y sobrevive al viaje por JSON.


func test_add_count_total() -> void:
    var tally: Tally = Tally.new()
    check(tally.add(0, 10), "suma")
    check(tally.add(0, 5), "suma otra vez")
    check(tally.add(1, 25), "otra clave")
    check(not tally.add(1, 0), "rechaza cero")
    check(not tally.add(1, -3), "rechaza negativo")
    check_equal(tally.count(0), 15, "cuenta por clave")
    check_equal(tally.count(2), 0, "clave vacía")
    check_equal(tally.total(), 40, "total")


func test_snapshot_round_trip() -> void:
    var tally: Tally = Tally.new()
    tally.add(0, 10)
    tally.add(1, 25)
    var copy: Tally = Tally.new()
    copy.restore(JSON.parse_string(JSON.stringify(tally.snapshot())) as Dictionary)
    check_equal(copy.count(0), 10, "clave 0")
    check_equal(copy.count(1), 25, "clave 1")
