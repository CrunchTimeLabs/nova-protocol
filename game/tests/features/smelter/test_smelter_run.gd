extends BaseTest
## Capa 3 (minijuego): fundición de la campaña: usa las menas recogidas, se teclea el elemento puro (sin tildes),
## la temperatura bloquea, el reloj no corre hasta empezar y cada metal extra desbloquea una pieza.


var _run: SmelterRun


func before_each() -> void:
    _run = SmelterRun.new(GameRandom.new(3), {Ores.Ore.BAUXITE: 2, Ores.Ore.PENTLANDITE: 1, Ores.Ore.HEMATITE: 10})


func _first_target() -> SmelterRun.Spawn:
    for i: int in 400:
        if not _run.active.is_empty():
            return _run.active[0]
        _run.tick(0.05)
    return null


func test_clock_waits_for_both_tutorials() -> void:
    for i: int in 100:
        _run.tick(0.1)
    check_approx(_run.remaining, SmelterRun.TIME_LIMIT, "sin empezar no corre el reloj")
    check(_run.active.is_empty() and _run.waiting.is_empty(), "ni salen menas")
    check(SmelterRun.TIME_LIMIT > 20.0, "hay más tiempo que antes")
    _run.start()
    _run.tick(1.0)
    check(_run.remaining < SmelterRun.TIME_LIMIT, "al empezar, corre")


func test_uses_the_collected_ores_only() -> void:
    _run.start()
    var seen: Dictionary = {}
    for i: int in 2000:
        _run.tick(0.05)
        for spawn: SmelterRun.Spawn in _run.active:
            seen[spawn.ore] = true
            _run.smelt(SmelterRun.answer(spawn.ore))
        if _run.is_finished:
            break
    for ore: int in seen.keys():
        check(ore in [Ores.Ore.BAUXITE, Ores.Ore.PENTLANDITE, Ores.Ore.HEMATITE], "%s estaba en lo recogido" % Ores.ore_name(ore))
    check(_run.total_metals() <= 13, "no salen más menas de las recogidas")
    check(_run.is_finished, "al acabarse las menas, termina")


func test_empty_inventory_still_plays() -> void:
    var run: SmelterRun = SmelterRun.new(GameRandom.new(1), {})
    check_equal(run.total_pool(), SmelterRun.FALLBACK_EACH * 5, "sin menas recogidas hay unas pocas de cada una")


func test_typing_the_pure_element_smelts_without_accents() -> void:
    _run.start()
    var spawn: SmelterRun.Spawn = _first_target()
    check(spawn != null, "hay un objetivo")
    check(not _run.smelt(Ores.ore_name(spawn.ore)), "el nombre de la mena no vale: hay que escribir el metal")
    check(_run.smelt(Ores.element(spawn.ore).to_upper()), "el elemento puro funde")
    check_equal(int(_run.metals[spawn.ore]), 1, "suma un metal de ese tipo")
    check_equal(SmelterRun.answer(Ores.Ore.PENTLANDITE), "niquel", "níquel sin tilde")
    check_equal(SmelterRun.plain("NÍQUEL"), "niquel", "con tilde también vale")


func test_blocked_by_temperature_does_not_smelt() -> void:
    _run.start()
    var spawn: SmelterRun.Spawn = _first_target()
    _run.blocked = true
    check(not _run.smelt(SmelterRun.answer(spawn.ore)), "con la temperatura fuera no se funde")
    _run.blocked = false
    check(_run.smelt(SmelterRun.answer(spawn.ore)), "al corregirla, sí")


func test_expired_target_is_lost() -> void:
    _run.start()
    var spawn: SmelterRun.Spawn = _first_target()
    _run.tick(spawn.remaining + 0.01)
    check_equal(spawn.status, SmelterRun.Status.LOST, "se enfría")
    check_equal(_run.lost, 1, "cuenta como perdida")


func test_each_metal_beyond_minimum_unlocks_the_next_part() -> void:
    var unlocked: Array[int] = []
    _run.part_unlocked.connect(func(part: RocketParts.Part) -> void: unlocked.append(part))
    _run.start()
    var made: int = 0
    while made < SmelterRun.MINIMUM + 2:
        var spawn: SmelterRun.Spawn = _first_target()
        if spawn == null:
            break
        _run.smelt(SmelterRun.answer(spawn.ore))
        made += 1
        if made <= SmelterRun.MINIMUM:
            check(unlocked.is_empty(), "hasta el mínimo no se desbloquea nada")
    check(_run.has_passed(), "pasó el mínimo")
    check_equal(unlocked.size(), 2, "dos metales extra, dos piezas")
    check_equal(unlocked[0], RocketParts.UNLOCK_ORDER[0], "en el orden de desbloqueo")
    check_equal(_run.unlocked.size(), 2, "quedan guardadas")
