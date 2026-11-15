extends BaseTest
## Capa 3-4: popups con cupo y caducidad, aciertos que suman una sola vez, fin a los 20 s, azar con semilla y guardado.


func _spawn(game: TapMatch) -> bool:
    return game.apply(0, Command.new(0, TapCommand.Kind.SPAWN))


func _hit(game: TapMatch, id: Variant) -> bool:
    return game.apply(1, Command.new(1, TapCommand.Kind.HIT, {"id": id}))


func test_hit_scores_once_and_expiry_does_not_subtract() -> void:
    var game: TapMatch = TapMatch.new(1)
    _spawn(game)
    _spawn(game)
    var ids: Array[int] = game.targets().ids()
    check(_hit(game, ids[0]), "acierto sobre un popup vivo")
    check(not _hit(game, ids[0]), "el mismo popup no cuenta dos veces")
    game.step(TapMatch.TARGET_LIFETIME_SECONDS - 0.1)
    check(game.targets().has(ids[1]), "sigue vivo antes de caducar")
    game.step(0.2)
    check(not _hit(game, ids[1]), "un popup caducado no cuenta")
    check_equal(game.hits(), 1, "solo el primer acierto sumó; caducar no resta")


func test_spawn_is_capped() -> void:
    var game: TapMatch = TapMatch.new(1)
    for _i: int in range(TapMatch.MAX_TARGETS):
        check(_spawn(game), "cabe un popup más")
    check(not _spawn(game), "con el cupo lleno se rechaza")
    check_equal(game.targets().count(), TapMatch.MAX_TARGETS, "no pasa del cupo")


func test_invalid_hit_payloads_change_nothing() -> void:
    var game: TapMatch = TapMatch.new(1)
    _spawn(game)
    for bad: Variant in ["x", null, NAN, 999]:
        check(not _hit(game, bad), "id inválido o desconocido se rechaza")
    check(not game.apply(1, Command.new(1, TapCommand.Kind.HIT)), "sin id se rechaza")
    check(not game.apply(1, Command.new(1, 99)), "tipo desconocido se rechaza")
    check_equal(game.hits(), 0, "nada sumó")
    check_equal(game.targets().count(), 1, "el popup sigue")


func test_match_ends_after_match_seconds() -> void:
    var game: TapMatch = TapMatch.new(1)
    _spawn(game)
    game.step(TapMatch.MATCH_SECONDS - 0.5)
    check(not game.is_over(), "aún en curso")
    check(_spawn(game), "todavía acepta comandos")
    game.step(0.5)
    check(game.is_over(), "terminó a los 20 s")
    check(not _spawn(game), "terminada: rechaza SPAWN")
    check(not _hit(game, 1), "terminada: rechaza HIT")


func test_same_seed_gives_same_positions() -> void:
    var snapshots: Array[Dictionary] = []
    for _run: int in range(2):
        var game: TapMatch = TapMatch.new(5)
        for _i: int in range(3):
            _spawn(game)
        snapshots.append(game.snapshot())
    check_equal(snapshots[0], snapshots[1], "misma semilla, mismos popups")


func test_snapshot_survives_json() -> void:
    var game: TapMatch = TapMatch.new(3)
    _spawn(game)
    _spawn(game)
    _hit(game, game.targets().ids()[0])
    game.step(1.0)
    var parsed: Dictionary = JSON.parse_string(JSON.stringify(game.snapshot())) as Dictionary
    var copy: TapMatch = TapMatch.new()
    copy.restore(parsed)
    check_equal(copy.hits(), 1, "aciertos")
    check_equal(copy.targets().ids(), game.targets().ids(), "popups")
    check_approx(copy.time_left(), TapMatch.MATCH_SECONDS - 1.0, "tiempo restante")
