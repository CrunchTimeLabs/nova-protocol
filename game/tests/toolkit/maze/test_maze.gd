extends BaseTest
## Capa 3 (entidad): el laberinto debe poder recorrerse entero y ser reproducible con la semilla.


func test_every_cell_is_reachable_and_doors_are_open() -> void:
    for seed_value: int in [90210, 1, 2, 3]:
        var maze: Maze = Maze.generate(21, 13, GameRandom.new(seed_value))
        check_equal(maze.reachable_from(maze.entrance()), maze.cols * maze.rows, "semilla %d: todo alcanzable" % seed_value)
        check(not maze.has_wall(maze.entrance(), Maze.W), "semilla %d: entrada abierta" % seed_value)
        check(not maze.has_wall(maze.exit_cell(), Maze.E), "semilla %d: salida abierta" % seed_value)


func test_same_seed_same_walls() -> void:
    var first: Maze = Maze.generate(9, 7, GameRandom.new(5))
    var second: Maze = Maze.generate(9, 7, GameRandom.new(5))
    check_equal(first.wall_rects(Vector2.ZERO, 10.0, 2.0), second.wall_rects(Vector2.ZERO, 10.0, 2.0), "misma semilla, mismos muros")
