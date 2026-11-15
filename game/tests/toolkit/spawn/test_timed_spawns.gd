extends BaseTest
## Capa 1 (elemento): aparecen con ritmo y máximo, caducan solos y se recogen una sola vez.


func test_due_respects_interval_and_max() -> void:
    var spawns: TimedSpawns = TimedSpawns.new(GameRandom.new(1), Vector2(1.0, 1.0), 2)
    check(spawns.tick(0.1), "el primero toca enseguida")
    check(not spawns.tick(0.5), "antes del intervalo no toca")
    check(spawns.tick(0.6), "pasado el intervalo toca")
    check(spawns.add(Vector2i(0, 0), 0, 10.0) != null, "se coloca")
    check(spawns.add(Vector2i(0, 0), 1, 10.0) == null, "casilla ocupada")
    check(spawns.add(Vector2i(1, 0), 1, 10.0) != null, "se coloca otro")
    check(spawns.add(Vector2i(2, 0), 1, 10.0) == null, "lleno")
    check(not spawns.tick(5.0), "lleno: no toca")


func test_expire_and_take() -> void:
    var spawns: TimedSpawns = TimedSpawns.new(GameRandom.new(1), Vector2(1.0, 2.0), 4)
    var short: TimedSpawns.Spawn = spawns.add(Vector2i(0, 0), 0, 1.0)
    var long: TimedSpawns.Spawn = spawns.add(Vector2i(1, 0), 0, 5.0)
    check(spawns.add(Vector2i(2, 0), 0, 0.0) == null, "vida no positiva")
    spawns.expire(1.5)
    check(not spawns.items.has(short), "caduca")
    check(spawns.take(long), "se recoge")
    check(not spawns.take(long), "no se recoge dos veces")
