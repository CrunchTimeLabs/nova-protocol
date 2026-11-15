extends BaseTest
## Capa 1: cada elemento caduca exactamente al agotar su vida, los ids no se reutilizan y el guardado conserva todo.


func test_item_expires_exactly_when_its_life_runs_out() -> void:
    var set: ExpiringSet = ExpiringSet.new()
    var id: int = set.spawn(Vector2(0.5, 0.5), 2.0)
    check_equal(set.tick(1.5).size(), 0, "antes de agotarse sigue vivo")
    check(set.has(id), "vivo a 0.5 s de caducar")
    check_equal(set.tick(0.5), [id] as Array[int], "caduca justo al agotarse")
    check(not set.has(id), "ya no está")
    check_equal(set.tick(-1.0).size(), 0, "un delta no positivo se ignora")


func test_remove_rejects_unknown_id_and_ids_are_not_reused() -> void:
    var set: ExpiringSet = ExpiringSet.new()
    var first: int = set.spawn(Vector2.ZERO, 1.0)
    check(set.remove(first), "quitar uno vivo")
    check(not set.remove(first), "quitarlo otra vez se rechaza")
    check(set.spawn(Vector2.ZERO, 1.0) != first, "el id nuevo es distinto")


func test_snapshot_survives_json() -> void:
    var set: ExpiringSet = ExpiringSet.new()
    set.spawn(Vector2(0.25, 0.75), 3.0)
    var second: int = set.spawn(Vector2(0.5, 0.5), 1.5)
    set.tick(1.0)
    var parsed: Dictionary = JSON.parse_string(JSON.stringify(set.snapshot())) as Dictionary
    var copy: ExpiringSet = ExpiringSet.new()
    copy.restore(parsed)
    check_equal(copy.ids(), set.ids(), "mismos ids")
    check_approx(copy.position_of(second).x, 0.5, "misma posición")
    check_equal(copy.tick(0.5), [second] as Array[int], "conserva la vida restante")
    check(copy.spawn(Vector2.ZERO, 1.0) > second, "los ids siguen creciendo")
