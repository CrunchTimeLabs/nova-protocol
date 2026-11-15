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
    var hits: int = int(DodgeField.HULL_MAX / DodgeField.ROCK_DAMAGE)
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
