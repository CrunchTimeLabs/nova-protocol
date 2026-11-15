extends BaseTest
## Capa 3: campo determinista, frecuencia según densidad, nave confinada, un golpe por ventana de invulnerabilidad y final.


const SIZE: Vector2 = Vector2(600, 400)
const FRAME: float = 1.0 / 60.0


func _rock_on_ship(field: DodgeField) -> void:
    field.rocks.append(DodgeRock.new(field.ship, 20.0, 0.0, 0.0, GameRandom.new(1)))


func test_same_seed_and_moves_give_same_state() -> void:
    var states: Array[Array] = []
    for _run: int in range(2):
        var field: DodgeField = DodgeField.new(SIZE, 1.0, 20.0, 3)
        field.hull = ResourceMeter.new(1.0e9, 1.0e9)
        for frame: int in range(600):
            field.step(FRAME, Vector2(sin(float(frame) * 0.05), cos(float(frame) * 0.03)))
        var positions: Array = [field.ship, field.spawned]
        for rock: DodgeRock in field.rocks:
            positions.append(rock.position)
        states.append(positions)
    check_equal(states[0], states[1], "misma semilla y mismos movimientos, mismo estado")


func test_lower_density_spawns_fewer_rocks() -> void:
    var counts: Array[int] = []
    for density: float in [1.0, 0.5]:
        var field: DodgeField = DodgeField.new(SIZE, density, 30.0, 5)
        field.hull = ResourceMeter.new(1.0e9, 1.0e9)
        while field.step(FRAME, Vector2.ZERO) == DodgeField.Status.RUNNING:
            pass
        counts.append(field.spawned)
    check(counts[1] > 0, "con densidad baja sí caen rocas")
    check(counts[1] < counts[0], "con menos densidad caen menos")


func test_ship_stays_inside_the_field() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 0.5, 20.0, 1)
    field.hull = ResourceMeter.new(1.0e9, 1.0e9)
    var area: Rect2 = Rect2(Vector2.ZERO, SIZE).grow(0.001)
    for frame: int in range(600):
        field.step(FRAME, Vector2(1.0, 1.0) if frame < 300 else Vector2(-1.0, -1.0))
        check(area.has_point(field.ship), "la nave no sale del campo (fotograma %d)" % frame)


func test_a_hit_hurts_once_per_invulnerability_window() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 0.5, 60.0, 1)
    _rock_on_ship(field)
    field.step(FRAME, Vector2.ZERO)
    check_approx(field.hull.current, DodgeField.HULL_MAX - DodgeField.ROCK_DAMAGE, "el golpe resta casco")
    check(field.is_protected(), "queda protegida")
    _rock_on_ship(field)
    field.step(FRAME, Vector2.ZERO)
    check_approx(field.hull.current, DodgeField.HULL_MAX - DodgeField.ROCK_DAMAGE, "protegida: no se resta otra vez")
    field.step(DodgeField.INVULNERABILITY_SECONDS, Vector2.ZERO)
    _rock_on_ship(field)
    field.step(FRAME, Vector2.ZERO)
    check_approx(field.hull.current, DodgeField.HULL_MAX - 2.0 * DodgeField.ROCK_DAMAGE, "pasada la ventana, vuelve a restar")


func test_ends_destroyed_or_arrived_and_then_stops() -> void:
    var doomed: DodgeField = DodgeField.new(SIZE, 0.5, 60.0, 1)
    var hits: int = ceili(DodgeField.HULL_MAX / DodgeField.ROCK_DAMAGE)
    for _i: int in range(hits):
        _rock_on_ship(doomed)
        doomed.step(DodgeField.INVULNERABILITY_SECONDS + 0.01, Vector2.ZERO)
    check_equal(doomed.status, DodgeField.Status.DESTROYED, "sin casco se destruye")
    var elapsed_then: float = doomed.elapsed
    doomed.step(FRAME, Vector2.ZERO)
    check_equal(doomed.elapsed, elapsed_then, "terminado, ya no cambia")
    var calm: DodgeField = DodgeField.new(SIZE, 0.5, 0.5, 1)
    check_equal(calm.step(1.0, Vector2.ZERO), DodgeField.Status.ARRIVED, "al pasar la duración llega")


func test_rocks_are_born_at_the_right_edge_of_any_size() -> void:
    for size: Vector2 in [Vector2(400, 300), Vector2(900, 500)]:
        var field: DodgeField = DodgeField.new(size, 1.0, 20.0, 2)
        field.hull = ResourceMeter.new(1.0e9, 1.0e9)
        var frames: int = 0
        while field.rocks.is_empty() and frames < 600:
            field.step(FRAME, Vector2.ZERO)
            frames += 1
        check(not field.rocks.is_empty(), "nace una roca (%s)" % str(size))
        var rock: DodgeRock = field.rocks[0]
        check(rock.position.x <= size.x + rock.radius and rock.position.x > size.x * 0.5, "nace en el borde derecho (%s)" % str(size))
        check(rock.position.y >= 0.0 and rock.position.y <= size.y, "dentro del alto (%s)" % str(size))


func _wave_on_ship(field: DodgeField) -> DodgeWave:
    var wave: DodgeWave = DodgeWave.new(field.ship + Vector2(DodgeWave.START_RADIUS, 0.0), 100.0, 1000.0)
    field.waves.append(wave)
    return wave


func test_wind_controls_how_many_waves_are_born() -> void:
    var counts: Array[int] = []
    for wind: float in [0.0, 0.6, 2.0]:
        var field: DodgeField = DodgeField.new(SIZE, 0.01, 90.0, 4, wind)
        field.hull = ResourceMeter.new(1.0e9, 1.0e9)
        while field.step(FRAME, Vector2.ZERO) == DodgeField.Status.RUNNING:
            pass
        counts.append(field.waves_spawned)
    check_equal(counts[0], 0, "sin viento no nace ninguna onda")
    check(counts[1] > 0, "con viento nacen ondas")
    check(counts[2] > counts[1], "con más viento nacen más seguido")


func test_a_wave_hits_once_then_protects_and_is_removed() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 0.01, 60.0, 1)
    var wave: DodgeWave = _wave_on_ship(field)
    check(field.wave_warning, "con una onda en camino hay aviso")
    field.step(FRAME, Vector2.ZERO)
    check(wave.has_hit, "el borde de la onda alcanza la nave")
    check_approx(field.hull.current, DodgeField.HULL_MAX - DodgeField.WAVE_DAMAGE, "el golpe resta casco")
    check(not field.wave_warning, "tras golpear ya no hay aviso")
    field.step(FRAME, Vector2.ZERO)
    check_approx(field.hull.current, DodgeField.HULL_MAX - DodgeField.WAVE_DAMAGE, "la misma onda no golpea dos veces")
    field.step(10.0, Vector2.ZERO)
    check(field.waves.is_empty(), "pasado su alcance máximo se elimina")


func test_waves_are_deterministic_and_stop_before_the_end() -> void:
    var logs: Array[Array] = []
    for _run: int in range(2):
        var field: DodgeField = DodgeField.new(SIZE, 0.01, 40.0, 9, 1.0)
        field.hull = ResourceMeter.new(1.0e9, 1.0e9)
        var born: Array = []
        while field.step(FRAME, Vector2.ZERO) == DodgeField.Status.RUNNING:
            if field.waves_spawned > born.size():
                born.append(field.elapsed)
        logs.append(born)
    check_equal(logs[0], logs[1], "misma semilla, mismas ondas")
    for moment: float in logs[0]:
        check(moment < 40.0 - DodgeField.WAVE_CUTOFF_SECONDS + 0.1, "no nace onda en los últimos segundos")


func test_rocks_get_harder_as_the_run_advances() -> void:
    var counts: Array[int] = []
    for _half: int in range(2):
        counts.append(0)
    var field: DodgeField = DodgeField.new(SIZE, 1.0, 68.0, 6)
    field.hull = ResourceMeter.new(1.0e9, 1.0e9)
    while field.step(FRAME, Vector2.ZERO) == DodgeField.Status.RUNNING:
        var half: int = 0 if field.progress() < 0.5 else 1
        if field.spawned > counts[0] + counts[1]:
            counts[half] += field.spawned - counts[0] - counts[1]
    check(counts[1] > counts[0], "en la segunda mitad caen más rocas que en la primera")
    var early: DodgeField = DodgeField.new(SIZE, 1.0, 100.0, 2)
    var late: DodgeField = DodgeField.new(SIZE, 1.0, 100.0, 2)
    early.step(1.5, Vector2.ZERO)
    late.step(95.0, Vector2.ZERO)
    check(late.rocks.is_empty() or early.rocks.is_empty() or late.rocks[0].speed > early.rocks[0].speed, "más tarde las rocas son más rápidas")


func test_phase_protects_drains_recharges_and_speeds_up() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 0.01, 60.0, 1)
    _rock_on_ship(field)
    var wave: DodgeWave = _wave_on_ship(field)
    field.step(FRAME, Vector2.ZERO, true)
    check(field.in_phase and field.is_protected(), "en fase está protegida")
    check_approx(field.hull.current, DodgeField.HULL_MAX, "en fase no la dañan ni rocas ni ondas")
    check(not wave.has_hit, "la onda no se marca como golpeada: sigue su camino")
    check(field.phase.current < DodgeField.PHASE_MAX, "la fase consume carga")
    var drained: float = field.phase.current
    field.step(1.0, Vector2.ZERO, false)
    check(not field.in_phase, "sin mantener, no hay fase")
    check(field.phase.current > drained, "sin fase la carga se recarga despacio")
    var held: DodgeField = DodgeField.new(SIZE, 0.01, 60.0, 1)
    var normal: DodgeField = DodgeField.new(SIZE, 0.01, 60.0, 1)
    held.step(0.5, Vector2.RIGHT, true)
    normal.step(0.5, Vector2.RIGHT, false)
    check(held.ship.x > normal.ship.x, "en fase la nave va más rápida")


func test_phase_ends_when_the_charge_runs_out() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 0.01, 60.0, 1)
    field.phase.set_value(0.0)
    field.step(FRAME, Vector2.ZERO, true)
    check(not field.in_phase, "sin carga no hay fase aunque se mantenga")
    field.phase.set_value(DodgeField.PHASE_DRAIN * FRAME * 0.5)
    field.step(FRAME, Vector2.ZERO, true)
    field.step(FRAME, Vector2.ZERO, true)
    check_approx(field.phase.current, DodgeField.PHASE_RECHARGE * FRAME, "al vaciarse deja de proteger y recarga")
    check(not field.in_phase, "tras vaciarse ya no está en fase")


func test_a_wave_band_has_thickness() -> void:
    var wave: DodgeWave = DodgeWave.new(Vector2.ZERO, 0.0, 1000.0)
    wave.radius = 100.0
    var inside: Vector2 = Vector2(100.0 + DodgeWave.THICKNESS * 0.4, 0.0)
    var outside: Vector2 = Vector2(100.0 + DodgeWave.THICKNESS * 0.5 + 1.0, 0.0)
    check(wave.reaches(inside, 0.0), "dentro de la banda la alcanza")
    check(not wave.reaches(outside, 0.0), "fuera de la banda no")


func test_without_duration_the_run_never_arrives_and_difficulty_plateaus() -> void:
    var field: DodgeField = DodgeField.new(SIZE, 1.0, 0.0, 3, 1.0)
    field.hull = ResourceMeter.new(1.0e9, 1.0e9)
    var late_rocks: int = 0
    for frame: int in range(int((DodgeField.RAMP_SECONDS + 60.0) / FRAME)):
        check_equal(field.step(FRAME, Vector2.ZERO), DodgeField.Status.RUNNING, "sin duración no llega (fotograma %d)" % frame) if frame % 600 == 0 else field.step(FRAME, Vector2.ZERO)
    check_equal(field.progress(), 1.0, "la dificultad se queda en el máximo")
    check(field.spawned > 0 and field.waves_spawned > 0, "pasada la rampa siguen cayendo rocas y ondas")
    var doomed: DodgeField = DodgeField.new(SIZE, 0.5, 0.0, 1)
    doomed.hull.set_value(0.0)
    check_equal(doomed.step(FRAME, Vector2.ZERO), DodgeField.Status.DESTROYED, "sin casco sigue siendo destruida")
