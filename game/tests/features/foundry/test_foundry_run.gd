extends BaseTest
## Capa 3 (minijuego): temporizador fijo, apariciones con vida, tecleo del nombre y fin por tiempo.


const SEED := 424242

var _run: FoundryRun
var _ended_count: int = 0


func before_each() -> void:
    _run = FoundryRun.new(GameRandom.new(SEED))
    _ended_count = 0
    _run.run_ended.connect(_on_run_ended)


func _on_run_ended(_result: FoundryRun.End) -> void:
    _ended_count += 1


func _spawn_one() -> FoundryRun.Spawn:
    for i: int in 400:
        if not _run.active.is_empty():
            return _run.active[0]
        _run.tick(0.05)
    return null


func _counts() -> Array[int]:
    var values: Array[int] = []
    for mineral: int in FoundryRun.Mineral.values():
        values.append(_run.count(mineral as FoundryRun.Mineral))
    return values


func test_timer_starts_at_twenty_and_spawns_do_not_pause_it() -> void:
    check_approx(_run.remaining, FoundryRun.TIME_LIMIT, "el temporizador empieza en su tope")
    check_equal(_counts(), [0, 0, 0], "los tres contadores empiezan en cero")
    var spawn: FoundryRun.Spawn = _spawn_one()
    check(spawn != null, "tras el primer intervalo aparece un mineral")
    var elapsed: float = FoundryRun.TIME_LIMIT - _run.remaining
    check(elapsed > 0.0, "el tiempo corre")
    check(elapsed <= FoundryRun.MAX_SPAWN_INTERVAL + 0.1, "la aparición no descuenta tiempo extra")


func test_same_seed_repeats_spawn_sequence() -> void:
    var first: FoundryRun = FoundryRun.new(GameRandom.new(SEED))
    var second: FoundryRun = FoundryRun.new(GameRandom.new(SEED))
    for i: int in 120:
        first.tick(0.05)
        second.tick(0.05)
    check_equal(first.active.size(), second.active.size(), "misma cantidad de activos")
    check_approx(first.remaining, second.remaining, "mismo tiempo restante")
    for index: int in first.active.size():
        check_equal(first.active[index].mineral, second.active[index].mineral, "mismo mineral en la posición %d" % index)
        check_approx(first.active[index].lifetime, second.active[index].lifetime, "misma vida total en la posición %d" % index)
        check_approx(first.active[index].remaining, second.active[index].remaining, "misma vida restante en la posición %d" % index)


func test_exact_name_collects_and_increments_counter() -> void:
    var spawn: FoundryRun.Spawn = _spawn_one()
    check(spawn != null, "hay un mineral")
    var remaining: float = _run.remaining
    var mineral: FoundryRun.Mineral = spawn.mineral
    var chosen_name: String = String(FoundryRun.NAMES[mineral])
    check(_run.collect(chosen_name.to_upper()), "el nombre completo recoge sin importar mayúsculas")
    check_equal(_run.count(mineral), 1, "sube el contador de ese mineral")
    check(not _run.active.has(spawn), "el mineral desaparece")
    check_approx(_run.remaining, remaining, "recoger no cambia el tiempo")
    for other: int in FoundryRun.Mineral.values():
        if other != mineral:
            check_equal(_run.count(other as FoundryRun.Mineral), 0, "los demás contadores no cambian")


func test_wrong_or_partial_name_changes_nothing() -> void:
    var spawn: FoundryRun.Spawn = _spawn_one()
    check(spawn != null, "hay un mineral")
    var before: int = _run.active.size()
    var remaining: float = _run.remaining
    var partial: String = String(FoundryRun.NAMES[spawn.mineral]).left(2)
    for word: String in [partial, "Plata", "", "   "]:
        check(not _run.collect(word), "«%s» no recoge" % word)
    check_equal(_run.active.size(), before, "no desaparece ningún mineral")
    check_approx(_run.remaining, remaining, "no se mueve el tiempo")
    check_equal(_counts(), [0, 0, 0], "ningún contador cambia")


func test_expired_mineral_is_lost_and_not_refunded() -> void:
    var spawn: FoundryRun.Spawn = _spawn_one()
    check(spawn != null, "hay un mineral")
    var lost_before: int = _run.lost
    _run.tick(spawn.lifetime + 0.01)
    check(not _run.active.has(spawn), "el mineral expira")
    check(_run.lost >= lost_before + 1, "se cuenta como perdido")
    check_equal(_run.count(spawn.mineral), 0, "no suma al contador")
    check(_run.remaining < FoundryRun.TIME_LIMIT, "el temporizador sigue corriendo")
    check(not _run.is_ended(), "aún queda tiempo")


func test_active_minerals_expire_independently() -> void:
    var brief: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, FoundryRun.MIN_LIFETIME)
    var lasting: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.GOLD, FoundryRun.MAX_LIFETIME)
    _run.active.append(brief)
    _run.active.append(lasting)
    _run.tick(brief.lifetime + 0.1)
    check(not _run.active.has(brief), "el de vida corta expira")
    check(_run.active.has(lasting), "el de vida larga sigue activo")
    check_equal(_run.lost, 1, "solo se pierde el que expiró")


func test_duplicate_name_collects_only_the_most_urgent() -> void:
    var urgent: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, 1.0)
    var relaxed: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, 3.0)
    _run.active.append(urgent)
    _run.active.append(relaxed)
    check(_run.collect("hierro"), "el nombre recoge uno de los dos")
    check_equal(_run.active.size(), 1, "solo desaparece uno")
    check(_run.active.has(relaxed), "se queda el que tenía más vida")
    check_equal(_run.count(FoundryRun.Mineral.IRON), 1, "suma una sola unidad")


func test_spawns_respect_interval_and_max_active() -> void:
    _run.tick(FoundryRun.MIN_SPAWN_INTERVAL - 0.05)
    check_equal(_run.active.size(), 0, "antes del intervalo mínimo no aparece nada")
    var max_seen: int = 0
    for i: int in 300:
        _run.tick(0.05)
        max_seen = maxi(max_seen, _run.active.size())
    check(max_seen > 0, "con el tiempo aparecen minerales")
    check(max_seen <= FoundryRun.MAX_ACTIVE, "nunca hay más de %d activos" % FoundryRun.MAX_ACTIVE)


func test_spawn_lifetimes_vary_within_range() -> void:
    var lifetimes: Dictionary = {}
    var remaining_exceeded: bool = false
    for i: int in 300:
        _run.tick(0.05)
        for spawn: FoundryRun.Spawn in _run.active:
            lifetimes[spawn.lifetime] = true
            remaining_exceeded = remaining_exceeded or spawn.remaining > spawn.lifetime
    check(not remaining_exceeded, "ninguna vida restante supera su vida total")
    check(lifetimes.size() > 1, "las apariciones no comparten siempre la misma vida")
    for lifetime: Variant in lifetimes.keys():
        check(
                float(lifetime) >= FoundryRun.MIN_LIFETIME and float(lifetime) <= FoundryRun.MAX_LIFETIME,
                "la vida sorteada queda entre %s y %s s" % [FoundryRun.MIN_LIFETIME, FoundryRun.MAX_LIFETIME],
                )


func test_session_ends_when_timer_reaches_zero() -> void:
    var ticks: int = 0
    while not _run.is_ended() and ticks < 1000:
        _run.tick(0.05)
        ticks += 1
    check_equal(_run.ended, FoundryRun.End.TIME, "el temporizador agotado termina la sesión")
    check_approx(_run.remaining, 0.0, "el tiempo llega a cero")
    check_equal(_ended_count, 1, "termina una sola vez")
    var active_count: int = _run.active.size()
    var counts: Array[int] = _counts()
    for i: int in 100:
        _run.tick(0.05)
    check_equal(_run.active.size(), active_count, "después de terminar no genera ni expira")
    check_equal(_counts(), counts, "los contadores no cambian")
    check_equal(_ended_count, 1, "no vuelve a emitir el final")
