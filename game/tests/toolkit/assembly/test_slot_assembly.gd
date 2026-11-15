extends BaseTest
## Capa 1 (elemento): cada ranura solo acepta su categoría; se sustituye, se quita, se completa y se guarda.


func _assembly() -> SlotAssembly:
    var categories: Array[int] = [10, 20, 30]
    return SlotAssembly.new(categories)


func test_place_only_in_its_category_and_replace() -> void:
    var assembly: SlotAssembly = _assembly()
    check(not assembly.place(0, 5, 20), "rechaza otra categoría")
    check(not assembly.place(7, 5, 10), "rechaza ranura inexistente")
    check(assembly.place(0, 5, 10), "acepta su categoría")
    check(assembly.place(0, 6, 10), "sustituye")
    check_equal(assembly.item_at(0), 6, "queda la nueva")
    check_equal(assembly.slot_for(30), 2, "ranura de una categoría")


func test_complete_remove_and_snapshot() -> void:
    var assembly: SlotAssembly = _assembly()
    assembly.place(0, 1, 10)
    assembly.place(1, 2, 20)
    check(not assembly.is_complete(), "falta una")
    assembly.place(2, 3, 30)
    check(assembly.is_complete(), "completo")
    var copy: SlotAssembly = _assembly()
    copy.restore(JSON.parse_string(JSON.stringify(assembly.snapshot())) as Dictionary)
    check_equal(copy.item_at(2), 3, "viaje por JSON")
    check_equal(assembly.remove(1), 2, "quita y devuelve la pieza")
    check_equal(assembly.remove(1), SlotAssembly.EMPTY, "ya estaba vacía")
    check(not assembly.is_complete(), "deja de estar completo")
