extends BaseTest
## Capa 1 (elemento): la bodega nunca pasa de su capacidad y quitar libera masa.


var _hold: CargoHold


func before_each() -> void:
    _hold = CargoHold.new(100)


func test_add_never_exceeds_capacity() -> void:
    check(_hold.add("a", 60), "cabe el primero")
    check(not _hold.add("b", 41), "no cabe uno que excede por 1 kg")
    check(_hold.add("b", 40), "uno que llena justo sí cabe")
    check_equal(_hold.used(), 100, "masa usada")
    check_equal(_hold.free_capacity(), 0, "capacidad libre")


func test_duplicates_are_rejected_and_remove_frees_mass() -> void:
    _hold.add("a", 30)
    check(not _hold.add("a", 30), "el mismo id no se carga dos veces")
    check(_hold.remove("a"), "se puede quitar lo cargado")
    check(not _hold.remove("a"), "quitar lo que no está falla")
    check_equal(_hold.free_capacity(), 100, "al quitar se libera la masa")


func test_ids_keep_load_order_and_changed_signal_fires() -> void:
    var changes: Array[int] = [0]
    _hold.changed.connect(func() -> void: changes[0] += 1)
    _hold.add("b", 10)
    _hold.add("a", 10)
    check_equal(_hold.ids(), ["b", "a"] as Array[String], "orden de carga")
    check_equal(changes[0], 2, "cada cambio avisa")
