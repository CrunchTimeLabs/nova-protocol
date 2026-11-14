extends BaseTest
## Capa 1 (elemento): sin azar reproducible no hay partidas ni pruebas deterministas.


func test_same_seed_gives_same_sequence() -> void:
    var first: GameRandom = GameRandom.new(42)
    var second: GameRandom = GameRandom.new(42)
    for i: int in 10:
        check_equal(first.range_int(0, 1000), second.range_int(0, 1000), "misma semilla, mismo valor (tirada %d)" % i)


func test_range_int_stays_in_range_and_reaches_both_ends() -> void:
    var rng: GameRandom = GameRandom.new(7)
    var seen: Dictionary = {}
    for i: int in 200:
        var value: int = rng.range_int(1, 3)
        check(value >= 1 and value <= 3, "valor dentro de 1..3")
        seen[value] = true
    check_equal(seen.size(), 3, "en 200 tiradas aparecen los tres valores")


func test_shuffle_is_reproducible_and_keeps_items() -> void:
    var first: Array = [1, 2, 3, 4, 5, 6, 7, 8]
    var second: Array = first.duplicate()
    GameRandom.new(9).shuffle(first)
    GameRandom.new(9).shuffle(second)
    check_equal(first, second, "misma semilla, mismo orden")
    var sorted: Array = first.duplicate()
    sorted.sort()
    check_equal(sorted, [1, 2, 3, 4, 5, 6, 7, 8], "barajar no pierde ni repite elementos")
