class_name DuoDraw
extends RefCounted
## Dibujo del laberinto a dos (`DuoRun`): suelo, muros, entradas de cada jugador, rampa de salida (cerrada
## hasta juntar el mínimo), menas en pixel art con su barra de tiempo, los dos cochecitos y los derrumbes.


const P1 := Color(0.98, 0.76, 0.2)
const P2 := Color(0.3, 0.78, 1.0)
const LOCKED := Color(0.95, 0.35, 0.3)
const OPEN := Color(0.3, 0.88, 0.45)
const BLINK_TIME := 1.5

## Rumbo de cada cochecito (solo vista).
class Look:
    var headings: Array[float] = [0.0, PI]
    var rock_scale: float = 1.2


static func player_color(player: int) -> Color:
    return P1 if player == 1 else P2


static func board(canvas: CanvasItem, run: DuoRun, time: float, look: Look) -> void:
    var size: Vector2 = Vector2(run.maze.cols, run.maze.rows) * run.cell_size
    var area: Rect2 = Rect2(run.origin - Vector2(6, 6), size + Vector2(12, 12))
    canvas.draw_rect(Rect2(area.position + Vector2(5, 7), area.size), Color(0, 0, 0, 0.5))
    canvas.draw_rect(area, CollectionDraw.FLOOR)
    for y: int in run.maze.rows:
        for x: int in run.maze.cols:
            var corner: Vector2 = run.origin + Vector2(x, y) * run.cell_size
            var h: int = absi((x * 73856093) ^ (y * 19349663))
            for i: int in 2:
                var k: int = absi(h ^ (i * 83492791))
                var p: Vector2 = corner + Vector2(float(k % 97) / 97.0, float((k / 97) % 89) / 89.0) * run.cell_size
                canvas.draw_rect(Rect2(p.floor(), Vector2(2, 2)), CollectionDraw.FLOOR_SPECK)
    canvas.draw_rect(area, CollectionDraw.FLOOR_EDGE, false, 2.0)
    _entrances(canvas, run, time)
    for wall: Rect2 in run.walls:
        canvas.draw_rect(Rect2(wall.position + Vector2(2, 2), wall.size), CollectionDraw.WALL_SHADOW)
    for wall: Rect2 in run.walls:
        canvas.draw_rect(wall, CollectionDraw.WALL_FILL)
        canvas.draw_line(wall.position, wall.position + Vector2(wall.size.x, 0), CollectionDraw.WALL_TOP, 1.0)
    _exit(canvas, run, time)
    for spawn: TimedSpawns.Spawn in run.spawns.items:
        _ore(canvas, run, spawn, time)
    for index: int in run.cars.size():
        var car: MazeCar = run.cars[index]
        var color: Color = player_color(car.player)
        canvas.draw_circle(car.position, run.cell_size * 0.55, Color(color, 0.1))
        CollectionDraw.car(canvas, car.position, look.headings[index], run.cell_size / CollectionScreen.REFERENCE_CELL, color)
        UiDraw.text_centered(canvas, car.position.x, car.position.y - run.cell_size * 0.95, "J%d" % car.player, 11, color, true)
    for cave_in: MazeCaveIns.CaveIn in run.cave_ins.active:
        RocksDraw.cave_in(canvas, run.cave_in_rect(cave_in), cave_in, run.cell_size, look.rock_scale, RocksDraw.FALL_TIME)


## Flechas de color en la entrada de cada jugador mientras aún no han entrado.
static func _entrances(canvas: CanvasItem, run: DuoRun, time: float) -> void:
    var pulse: float = 0.5 + 0.5 * sin(time * 5.0)
    var spots: Array = [
        [run.cars[0], run.center_of(run.maze.entrance()) - Vector2(run.cell_size, 0), 1.0],
        [run.cars[1], run.center_of(run.maze.exit_cell()) + Vector2(run.cell_size, 0), -1.0],
    ]
    for spot: Array in spots:
        var car: MazeCar = spot[0]
        if car.has_entered:
            continue
        var at: Vector2 = spot[1]
        var dir: float = spot[2]
        var color: Color = Color(player_color(car.player), 0.4 + 0.5 * pulse)
        for i: int in 3:
            var x: float = at.x + dir * (float(i) * 10.0 + fmod(time * 30.0, 10.0))
            canvas.draw_polyline(PackedVector2Array([Vector2(x, at.y - 7), Vector2(x + dir * 7, at.y), Vector2(x, at.y + 7)]), color, 2.5)


static func _exit(canvas: CanvasItem, run: DuoRun, time: float) -> void:
    var rect: Rect2 = run.exit_rect
    var is_open: bool = run.is_exit_open()
    var color: Color = OPEN if is_open else LOCKED
    var pulse: float = 0.5 + 0.5 * sin(time * 4.0)
    canvas.draw_rect(rect.grow(3.0 + 3.0 * pulse), Color(color, 0.1))
    canvas.draw_rect(rect, Color(color.darkened(0.75), 0.95))
    if is_open:
        for i: int in 3:
            var y: float = rect.position.y + 8.0 + float(i) * 12.0 + fmod(time * 20.0, 12.0)
            if y > rect.end.y - 6.0:
                continue
            var cx: float = rect.get_center().x
            canvas.draw_polyline(PackedVector2Array([Vector2(cx - 7, y), Vector2(cx, y + 7), Vector2(cx + 7, y)]), color, 2.5)
    else:
        var c: Vector2 = rect.get_center()
        canvas.draw_rect(Rect2(c - Vector2(7, 2), Vector2(14, 11)), color)
        canvas.draw_arc(c - Vector2(0, 2), 5.0, PI, TAU, 10, color, 2.0)
    canvas.draw_rect(rect, Color(color, 0.6 + 0.4 * pulse), false, 2.0)
    for car: MazeCar in run.cars:
        if car.is_on_exit:
            canvas.draw_rect(rect.grow(-3.0), Color(player_color(car.player), 0.25))


static func _ore(canvas: CanvasItem, run: DuoRun, spawn: TimedSpawns.Spawn, time: float) -> void:
    var ratio: float = clampf(spawn.remaining / spawn.lifetime, 0.0, 1.0)
    var p: Vector2 = run.center_of(spawn.slot)
    var bar_scale: float = run.cell_size / 40.0
    var bar: Rect2 = Rect2(p + Vector2(-13, 11) * bar_scale, Vector2(26, 4) * bar_scale)
    canvas.draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.75))
    canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), FoundryArt.timer_color(ratio))
    if spawn.remaining < BLINK_TIME and fmod(time * 8.0, 1.0) < 0.35:
        return
    var ore: Ores.Ore = spawn.kind as Ores.Ore
    var side: float = run.cell_size * 0.72
    var bob: float = sin(time * 3.0 + float(spawn.slot.x)) * 1.5 - 3.0
    canvas.draw_circle(p + Vector2(0, bob), side * 0.55, Color(Ores.color(ore), 0.14))
    canvas.draw_texture_rect(Ores.texture(ore), Rect2(p + Vector2(-side / 2.0, -side / 2.0 + bob), Vector2(side, side)), false)
