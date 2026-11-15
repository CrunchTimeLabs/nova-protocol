extends BaseTest
## Capa 3 (minijuego): dos relojes independientes, grupos de 3–4 en la tolva, 1–2 objetivos al centro,
## tecleo del nombre, pérdida de recursos al expirar y fin a los 20 s.


const SEED := 424242

var _run: FoundryRun
var _ended_count: int = 0


func before_each() -> void:
    _run = FoundryRun.new(GameRandom.new(SEED))
    _ended_count = 0
    _run.run_ended.connect(_on_run_ended)


func _on_run_ended(_result: FoundryRun.End) -> void:
    _ended_count += 1


## Avanza hasta que haya objetivos en el centro y devuelve el primero.
func _first_target() -> FoundryRun.Spawn:
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


func _clear_center() -> void:
    _run.active.clear()


func test_starts_at_twenty_seconds_with_counters_at_zero() -> void:
    check_approx(_run.remaining, FoundryRun.TIME_LIMIT, "el reloj de arena empieza en su tope")
    check_approx(FoundryRun.TIME_LIMIT, 20.0, "el nivel dura 20 s")
    check_equal(_counts(), [0, 0, 0], "los tres contadores empiezan en cero")
    check(_run.waiting.is_empty() and _run.active.is_empty(), "aún no hay minerales")
    _run.tick(FoundryRun.FIRST_DELAY - 0.05)
    check(_run.active.is_empty(), "el primer grupo espera su pausa")
    check(_first_target() != null, "luego aparece el primer grupo")


func test_group_has_three_or_four_and_one_or_two_go_to_center() -> void:
    var seen_groups: Dictionary = {}
    var seen_picks: Dictionary = {}
    for seed_value: int in 60:
        var run: FoundryRun = FoundryRun.new(GameRandom.new(seed_value))
        while run.active.is_empty():
            run.tick(0.05)
        var group: int = run.waiting.size() + run.active.size()
        seen_groups[group] = true
        seen_picks[run.active.size()] = true
        check(group >= FoundryRun.MIN_GROUP and group <= FoundryRun.MAX_GROUP, "el grupo tiene 3 o 4")
        check(run.active.size() >= 1 and run.active.size() <= 2, "van 1 o 2 al centro")
        for spawn: FoundryRun.Spawn in run.waiting:
            check_equal(spawn.status, FoundryRun.Status.WAITING, "los no elegidos esperan en la tolva")
            check_approx(spawn.lifetime, 0.0, "y su reloj no ha arrancado")
    check_equal(seen_groups.size(), 2, "salen grupos de 3 y de 4")
    check_equal(seen_picks.size(), 2, "a veces 1 y a veces 2 objetivos")


func test_waiting_minerals_stay_for_the_next_group_without_new_cost() -> void:
    _first_target()
    var left: Array[FoundryRun.Spawn] = _run.waiting.duplicate()
    var used: int = _run.resources_used
    var resources_before: int = _run.resources
    _clear_center()
    for i: int in 40:
        _run.tick(0.05)
        if _run.rounds >= 2:
            break
    check_equal(_run.rounds, 2, "con el centro vacío llega la ronda siguiente")
    var group: Array[FoundryRun.Spawn] = _run.waiting + _run.active
    var new_cost: int = 0
    var new_minerals: int = 0
    for spawn: FoundryRun.Spawn in group:
        if not left.has(spawn):
            new_cost += int(FoundryRun.COSTS[spawn.mineral])
            new_minerals += 1
    for spawn: FoundryRun.Spawn in left:
        check(group.has(spawn), "el que esperaba sigue en el grupo nuevo")
    check_equal(_run.resources_used, used + new_cost, "solo los minerales nuevos gastan recursos")
    check_equal(_run.resources, resources_before - new_minerals, "el total baja de uno en uno con cada mineral nuevo")


func test_same_seed_repeats_rounds() -> void:
    var first: FoundryRun = FoundryRun.new(GameRandom.new(SEED))
    var second: FoundryRun = FoundryRun.new(GameRandom.new(SEED))
    for i: int in 160:
        first.tick(0.05)
        second.tick(0.05)
    check_equal(first.active.size(), second.active.size(), "misma cantidad de objetivos")
    check_equal(first.waiting.size(), second.waiting.size(), "misma tolva")
    check_equal(first.resources_used, second.resources_used, "mismos recursos")
    for index: int in first.active.size():
        check_equal(first.active[index].mineral, second.active[index].mineral, "mismo mineral en %d" % index)
        check_approx(first.active[index].remaining, second.active[index].remaining, "mismo tiempo en %d" % index)


func test_lifetime_depends_on_mineral_and_stays_between_four_and_seven() -> void:
    var gold: Vector2 = FoundryRun.LIFETIMES[FoundryRun.Mineral.GOLD]
    var iron: Vector2 = FoundryRun.LIFETIMES[FoundryRun.Mineral.IRON]
    var copper: Vector2 = FoundryRun.LIFETIMES[FoundryRun.Mineral.COPPER]
    check(gold.y <= iron.x and iron.y <= copper.x, "oro con menos tiempo, cobre con más, hierro en medio")
    check(gold.x >= FoundryRun.MIN_LIFETIME and copper.y <= FoundryRun.MAX_LIFETIME, "todo entre 4 y 7 s")
    var lifetimes: Dictionary = {}
    for seed_value: int in 40:
        var run: FoundryRun = FoundryRun.new(GameRandom.new(seed_value))
        while run.active.is_empty():
            run.tick(0.05)
        for spawn: FoundryRun.Spawn in run.active:
            var span: Vector2 = FoundryRun.LIFETIMES[spawn.mineral]
            check(spawn.lifetime >= span.x and spawn.lifetime <= span.y, "la vida respeta el rango de su mineral")
            lifetimes[spawn.lifetime] = true
    check(lifetimes.size() > 1, "las vidas se sortean")


func test_rarity_and_value_follow_the_script() -> void:
    var weights: Dictionary = FoundryRun.WEIGHTS
    var values: Dictionary = FoundryRun.VALUES
    var gold: FoundryRun.Mineral = FoundryRun.Mineral.GOLD
    var iron: FoundryRun.Mineral = FoundryRun.Mineral.IRON
    var copper: FoundryRun.Mineral = FoundryRun.Mineral.COPPER
    check(int(weights[gold]) < int(weights[iron]) and int(weights[iron]) < int(weights[copper]), "oro raro, cobre común")
    check(int(values[gold]) > int(values[iron]) and int(values[iron]) > int(values[copper]), "oro vale más, cobre menos")
    var seen: Dictionary = {}
    var run: FoundryRun = FoundryRun.new(GameRandom.new(7))
    for i: int in 400:
        seen[run._random_mineral()] = int(seen.get(run._random_mineral(), 0)) + 1
    check(int(seen.get(copper, 0)) > int(seen.get(gold, 0)), "en la práctica sale más cobre que oro")


func test_exact_name_collects_and_increments_counter() -> void:
    var spawn: FoundryRun.Spawn = _first_target()
    check(spawn != null, "hay un objetivo")
    var remaining: float = _run.remaining
    var mineral: FoundryRun.Mineral = spawn.mineral
    check(_run.collect(String(FoundryRun.NAMES[mineral]).to_upper()), "el nombre recoge sin importar mayúsculas")
    check_equal(_run.count(mineral), 1, "sube el contador de ese mineral")
    check_equal(_run.value, int(FoundryRun.VALUES[mineral]), "suma su valor")
    check_equal(spawn.status, FoundryRun.Status.COLLECTED, "queda como recolectado")
    check(not _run.active.has(spawn), "sale del centro")
    check_approx(_run.remaining, remaining, "recoger no cambia el reloj de arena")


func test_collected_mineral_cannot_be_collected_again() -> void:
    var spawn: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.GOLD, 4.0)
    _run.active.append(spawn)
    check(_run.collect("oro"), "se recoge una vez")
    check(not _run.collect("oro"), "no se puede volver a recoger")
    check_equal(_run.count(FoundryRun.Mineral.GOLD), 1, "cuenta una sola unidad")


func test_wrong_partial_or_waiting_names_change_nothing() -> void:
    var spawn: FoundryRun.Spawn = _first_target()
    var before: int = _run.active.size()
    var partial: String = String(FoundryRun.NAMES[spawn.mineral]).left(2)
    for word: String in [partial, "Plata", "", "   "]:
        check(not _run.collect(word), "«%s» no recoge" % word)
    _clear_center()
    _run.waiting.append(FoundryRun.Spawn.new(FoundryRun.Mineral.GOLD))
    check(not _run.collect("oro"), "un mineral en la tolva no se puede recoger")
    check_equal(_counts(), [0, 0, 0], "ningún contador cambia")
    check(before > 0, "había objetivos")


func test_collecting_one_does_not_touch_the_other_timer() -> void:
    var gold: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.GOLD, 4.0)
    var iron: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, 6.0)
    _run.active.append(gold)
    _run.active.append(iron)
    _run.tick(1.0)
    check(_run.collect("oro"), "se recoge el oro")
    check_approx(iron.remaining, 5.0, "el hierro conserva su tiempo")
    _run.tick(1.0)
    check_approx(iron.remaining, 4.0, "y sigue bajando a su ritmo")


func test_expired_mineral_disappears_and_its_resources_are_lost() -> void:
    _clear_center()
    var spawn: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.GOLD, 4.0)
    _run.active.append(spawn)
    _run.tick(4.01)
    check(not _run.active.has(spawn), "el mineral desaparece")
    check_equal(spawn.status, FoundryRun.Status.LOST, "queda como perdido")
    check_equal(_run.lost, 1, "se cuenta como perdido")
    check_equal(_run.resources_lost, int(FoundryRun.COSTS[FoundryRun.Mineral.GOLD]), "sus recursos no se devuelven")
    check_equal(_run.count(FoundryRun.Mineral.GOLD), 0, "no suma al contador")


func test_duplicate_name_collects_only_the_most_urgent() -> void:
    var urgent: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, 1.0)
    var relaxed: FoundryRun.Spawn = FoundryRun.Spawn.new(FoundryRun.Mineral.IRON, 3.0)
    _run.active.append(urgent)
    _run.active.append(relaxed)
    check(_run.collect("hierro"), "el nombre recoge uno de los dos")
    check(_run.active.has(relaxed), "se queda el que tenía más tiempo")
    check_approx(relaxed.remaining, 3.0, "sin tocar su reloj")


func test_next_round_waits_until_center_is_empty() -> void:
    _first_target()
    var rounds: int = _run.rounds
    var target: FoundryRun.Spawn = _run.active[0]
    _run.tick(minf(1.0, target.remaining * 0.5))
    check_equal(_run.rounds, rounds, "con objetivos en el centro no sale otro grupo")


func test_level_ends_at_twenty_seconds_and_stops_everything() -> void:
    var ticks: int = 0
    while not _run.is_ended() and ticks < 1000:
        _run.tick(0.05)
        ticks += 1
    check_equal(_run.ended, FoundryRun.End.TIME, "la arena agotada termina el nivel")
    check_approx(_run.remaining, 0.0, "el tiempo llega a cero")
    check_equal(_ended_count, 1, "termina una sola vez")
    var timers: Array[float] = []
    for spawn: FoundryRun.Spawn in _run.active:
        timers.append(spawn.remaining)
    var rounds: int = _run.rounds
    var counts: Array[int] = _counts()
    for i: int in 100:
        _run.tick(0.05)
    for index: int in _run.active.size():
        check_approx(_run.active[index].remaining, timers[index], "los relojes individuales se detienen")
    check_equal(_run.rounds, rounds, "no salen más grupos")
    check_equal(_counts(), counts, "los contadores quedan con el total final")
    check(not _run.collect("oro") and not _run.collect("cobre") and not _run.collect("hierro"), "ya no se recoge")
    check_equal(_ended_count, 1, "no vuelve a emitir el final")
