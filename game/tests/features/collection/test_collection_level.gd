extends BaseTest
## Datos: cada nivel es más duro que el anterior solo en tamaño y derrumbes; lo demás es igual.


func test_each_level_is_harder_only_in_size_and_cave_ins() -> void:
    var levels: Array[CollectionLevel] = [
        CollectionLevel.new(CollectionLevel.Level.EASY),
        CollectionLevel.new(CollectionLevel.Level.MEDIUM),
        CollectionLevel.new(CollectionLevel.Level.HARD),
    ]
    for i: int in range(1, levels.size()):
        var easier: CollectionLevel = levels[i - 1]
        var harder: CollectionLevel = levels[i]
        check(harder.size.x * harder.size.y > easier.size.x * easier.size.y, "%s: laberinto más grande" % harder.title())
        check(harder.passages_per_cave_in > easier.passages_per_cave_in, "%s: cada derrumbe tapa más pasos" % harder.title())
        check(harder.big_rocks > easier.big_rocks, "%s: más rocas en pantalla" % harder.title())
        check(harder.cave_in_duration.y > easier.cave_in_duration.y, "%s: los bloqueos duran más" % harder.title())
        check(harder.cave_in_max > easier.cave_in_max, "%s: más bloqueos a la vez" % harder.title())
    for level: CollectionLevel in levels:
        check(level.cave_in_max >= 2 * level.passages_per_cave_in, "%s: se acumulan de un derrumbe a otro" % level.title())
        check(level.cave_in_duration.x > level.cave_in_window * 0.5, "%s: un bloqueo dura más de medio ciclo" % level.title())
        check_approx(level.front_chance, 0.3, "%s: 30 %% delante" % level.title())
        check_approx(level.cave_in_window, 15.0, "%s: ventana de 15 s" % level.title())
        check_approx(level.cave_in_chance, 0.95, "%s: 95 %% por ventana" % level.title())
        var width: float = float(level.size.x) * level.cell_size
        check(width <= CollectionScreen.BOARD_AREA.size.x, "%s: cabe a lo ancho" % level.title())
        check(float(level.size.y) * level.cell_size <= CollectionScreen.BOARD_AREA.size.y - 40.0, "%s: cabe a lo alto" % level.title())
        check(level.cell_size - CollectionRun.WALL_THICKNESS > 2.0 * level.cell_size * CollectionRun.CAR_RADIUS_RATIO, "%s: el cochecito cabe por los pasillos" % level.title())
