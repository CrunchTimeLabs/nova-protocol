class_name CollectionDraw
extends RefCounted
## Dibujo de una `CollectionRun` sobre cualquier lienzo: lo usan la partida y la demo del tutorial (con zoom).
## Solo lee el estado. `Look` lleva lo que es solo de la vista (rumbo del cochecito, tamaño de las rocas).


class Look:
    var heading: float = 0.0
    ## La demo del tutorial exagera las rocas y las hace caer más despacio.
    var rock_scale: float = 1.35
    var fall_time: float = RocksDraw.FALL_TIME
    ## Tamaño del cochecito respecto a la celda de referencia (celdas más pequeñas, coche más pequeño).
    var car_scale: float = 1.0


const FLOOR := Color(0.11, 0.095, 0.08)
const FLOOR_SPECK := Color(0.16, 0.14, 0.12)
const FLOOR_EDGE := Color(0.26, 0.22, 0.17)
const WALL_SHADOW := Color(0, 0, 0, 0.45)
const WALL_FILL := Color(0.42, 0.37, 0.31)
const WALL_TOP := Color(0.62, 0.56, 0.47)
const CAR_BODY := Color(0.95, 0.74, 0.18)
const CAR_DARK := Color(0.16, 0.16, 0.18)
const CAR_GLASS := Color(0.45, 0.8, 1.0)
const HEADLIGHT := Color(1.0, 0.95, 0.7, 0.16)
const EXIT := Color(0.3, 0.88, 0.45)
const MINERAL_COLORS: Dictionary = {
    CollectionRun.Mineral.METAL: Color(0.72, 0.76, 0.84),
    CollectionRun.Mineral.COPPER: Color(0.93, 0.52, 0.25),
    CollectionRun.Mineral.CRYSTAL: Color(0.35, 0.92, 1.0),
    CollectionRun.Mineral.GOLD: Color(1.0, 0.84, 0.2),
    CollectionRun.Mineral.AMETHYST: Color(0.72, 0.42, 1.0),
}
## Tamaño de cada mineral (el metal, el más común, es el más pequeño).
const MINERAL_SCALE: Dictionary = {
    CollectionRun.Mineral.METAL: 0.6,
    CollectionRun.Mineral.COPPER: 0.75,
    CollectionRun.Mineral.CRYSTAL: 0.9,
    CollectionRun.Mineral.GOLD: 0.9,
    CollectionRun.Mineral.AMETHYST: 1.0,
}
const BAR_SIZE := Vector2(30, 5)
const BAR_FULL := Color(0.35, 0.9, 0.45)
const BAR_MID := Color(0.98, 0.82, 0.25)
const BAR_LOW := Color(0.95, 0.3, 0.25)
## Con menos de esto, el mineral parpadea.
const BLINK_TIME := 1.5
const BLINK_RATE := 8.0
const SPECKS_PER_CELL := 3


static func mineral_color(mineral: CollectionRun.Mineral) -> Color:
    return MINERAL_COLORS[mineral]


static func board(canvas: CanvasItem, run: CollectionRun, time: float, look: Look) -> void:
    _floor(canvas, run)
    for wall: Rect2 in run.walls:
        canvas.draw_rect(Rect2(wall.position + Vector2(2, 3), wall.size), WALL_SHADOW)
    for wall: Rect2 in run.walls:
        canvas.draw_rect(wall, WALL_FILL)
        canvas.draw_line(wall.position, wall.position + Vector2(wall.size.x, 0), WALL_TOP, 1.5)
    _exit(canvas, run, time)
    for spawn: TimedSpawns.Spawn in run.spawns.items:
        _mineral(canvas, run, spawn, time)
    _car(canvas, run.car, look.heading, look.car_scale)
    for cave_in: MazeCaveIns.CaveIn in run.cave_ins.active:
        RocksDraw.cave_in(canvas, run.cave_in_rect(cave_in), cave_in, run.cell_size, look.rock_scale, look.fall_time)


## Silueta de cada mineral (centrada en el origen, a tamaño 1).
static func mineral_shape(mineral: CollectionRun.Mineral) -> PackedVector2Array:
    match mineral:
        CollectionRun.Mineral.METAL:
            return PackedVector2Array([Vector2(-8, -4), Vector2(0, -9), Vector2(8, -4), Vector2(8, 4), Vector2(0, 8), Vector2(-8, 4)])
        CollectionRun.Mineral.COPPER:
            return PackedVector2Array([Vector2(-6, -8), Vector2(5, -9), Vector2(10, -2), Vector2(7, 7), Vector2(-3, 9), Vector2(-10, 2)])
        CollectionRun.Mineral.CRYSTAL:
            return PackedVector2Array([Vector2(0, -11), Vector2(7, -2), Vector2(0, 9), Vector2(-7, -2)])
        CollectionRun.Mineral.GOLD:
            return PackedVector2Array([Vector2(-9, 2), Vector2(-5, -7), Vector2(3, -9), Vector2(10, -3), Vector2(8, 6), Vector2(-1, 9)])
        CollectionRun.Mineral.AMETHYST:
            return PackedVector2Array([Vector2(-5, -12), Vector2(5, -12), Vector2(8, 0), Vector2(5, 10), Vector2(-5, 10), Vector2(-8, 0)])
    return PackedVector2Array()


## Barra de tiempo: verde llena → amarilla → roja vacía.
static func time_bar(canvas: CanvasItem, center: Vector2, ratio: float) -> void:
    var rect: Rect2 = Rect2(center - BAR_SIZE / 2.0, BAR_SIZE)
    var color: Color = BAR_FULL.lerp(BAR_MID, clampf((1.0 - ratio) * 2.0, 0.0, 1.0))
    if ratio < 0.5:
        color = BAR_MID.lerp(BAR_LOW, clampf((0.5 - ratio) * 2.0, 0.0, 1.0))
    canvas.draw_rect(rect.grow(1.5), Color(0, 0, 0, 0.75))
    canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
    canvas.draw_rect(rect.grow(1.5), Color(1, 1, 1, 0.35), false, 1.0)


static func _floor(canvas: CanvasItem, run: CollectionRun) -> void:
    var size: Vector2 = Vector2(run.maze.cols, run.maze.rows) * run.cell_size
    var area: Rect2 = Rect2(run.origin - Vector2(8, 8), size + Vector2(16, 16))
    canvas.draw_rect(Rect2(area.position + Vector2(5, 7), area.size), Color(0, 0, 0, 0.5))
    canvas.draw_rect(area, FLOOR)
    # Motas fijas por celda: textura de roca sin azar en tiempo de ejecución.
    for y: int in run.maze.rows:
        for x: int in run.maze.cols:
            var corner: Vector2 = run.origin + Vector2(x, y) * run.cell_size
            for i: int in SPECKS_PER_CELL:
                var h: int = absi((x * 73856093) ^ (y * 19349663) ^ (i * 83492791))
                var p: Vector2 = corner + Vector2(float(h % 97) / 97.0, float((h / 97) % 89) / 89.0) * run.cell_size
                canvas.draw_circle(p, 1.0 + float(h % 3) * 0.6, FLOOR_SPECK)
    canvas.draw_rect(area, FLOOR_EDGE, false, 2.0)


static func _exit(canvas: CanvasItem, run: CollectionRun, time: float) -> void:
    var rect: Rect2 = run.exit_rect
    var pulse: float = 0.5 + 0.5 * sin(time * 4.0)
    canvas.draw_rect(rect.grow(4.0 + 3.0 * pulse), Color(EXIT, 0.08))
    canvas.draw_rect(rect, Color(0.1, 0.17, 0.11))
    for i: int in 4:
        var y: float = rect.position.y + 30.0 + float(i) * 12.0
        canvas.draw_line(Vector2(rect.position.x + 6, y), Vector2(rect.end.x - 6, y), Color(EXIT, 0.15), 1.0)
    for i: int in 3:
        var x: float = rect.position.x + 14.0 + float(i) * 16.0 + fmod(time * 24.0, 16.0)
        if x > rect.end.x - 14.0:
            continue
        var y: float = rect.get_center().y + 4.0
        canvas.draw_polyline(PackedVector2Array([Vector2(x, y - 7), Vector2(x + 7, y), Vector2(x, y + 7)]), EXIT, 2.5, true)
    canvas.draw_rect(rect, Color(EXIT, 0.55 + 0.45 * pulse), false, 2.0)
    UiDraw.text(canvas, rect.position + Vector2(8, 6), "RAMPA", 12, EXIT, true)


static func _mineral(canvas: CanvasItem, run: CollectionRun, spawn: TimedSpawns.Spawn, time: float) -> void:
    var ratio: float = clampf(spawn.remaining / spawn.lifetime, 0.0, 1.0)
    var p: Vector2 = run.center_of(spawn.slot)
    time_bar(canvas, p + Vector2(0, 16), ratio)
    if spawn.remaining < BLINK_TIME and fmod(time * BLINK_RATE, 1.0) < 0.35:
        return
    var mineral: CollectionRun.Mineral = spawn.kind as CollectionRun.Mineral
    var color: Color = mineral_color(mineral)
    var bob: Vector2 = Vector2(0, sin(time * 3.0 + float(spawn.slot.x)) * 1.5 - 3.0)
    var scale: float = float(MINERAL_SCALE[mineral]) * run.cell_size / CollectionScreen.REFERENCE_CELL
    canvas.draw_circle(p + bob, 13.0 * scale, Color(color, 0.12))
    canvas.draw_circle(p + bob, 9.0 * scale, Color(color, 0.12))
    var shape: PackedVector2Array = mineral_shape(mineral)
    for i: int in shape.size():
        shape[i] = p + bob + shape[i] * scale
    canvas.draw_colored_polygon(shape, color.darkened(0.15))
    canvas.draw_colored_polygon(PackedVector2Array([shape[0], shape[1], p + bob]), color.lightened(0.35))
    shape.append(shape[0])
    canvas.draw_polyline(shape, color.lightened(0.6), 1.2, true)
    var twinkle: float = maxf(0.0, sin(time * 5.0 + float(spawn.slot.y) * 1.7))
    if twinkle > 0.8:
        var spark: Vector2 = p + bob + Vector2(5, -7)
        canvas.draw_line(spark - Vector2(3, 0), spark + Vector2(3, 0), Color(1, 1, 1, twinkle), 1.0)
        canvas.draw_line(spark - Vector2(0, 3), spark + Vector2(0, 3), Color(1, 1, 1, twinkle), 1.0)


## Cochecito visto desde arriba, girado hacia donde va.
static func _car(canvas: CanvasItem, car: Vector2, heading: float, scale: float) -> void:
    var beam: PackedVector2Array = _turned([Vector2(11, -5), Vector2(46, -20), Vector2(46, 20), Vector2(11, 5)], car, heading, scale)
    canvas.draw_colored_polygon(beam, HEADLIGHT)
    canvas.draw_colored_polygon(_turned([Vector2(-11, -9), Vector2(13, -9), Vector2(13, 11), Vector2(-11, 11)], car + Vector2(2, 3) * scale, heading, scale), Color(0, 0, 0, 0.35))
    for wheel: Vector2 in [Vector2(-7, -11), Vector2(7, -11), Vector2(-7, 11), Vector2(7, 11)]:
        canvas.draw_colored_polygon(_turned([Vector2(-4, -2.5), Vector2(4, -2.5), Vector2(4, 2.5), Vector2(-4, 2.5)], car + wheel.rotated(heading) * scale, heading, scale), CAR_DARK)
    canvas.draw_colored_polygon(_turned([Vector2(-11, -8), Vector2(9, -8), Vector2(12, -4), Vector2(12, 4), Vector2(9, 8), Vector2(-11, 8)], car, heading, scale), CAR_BODY)
    canvas.draw_colored_polygon(_turned([Vector2(1, -5), Vector2(7, -4), Vector2(7, 4), Vector2(1, 5)], car, heading, scale), CAR_GLASS)
    canvas.draw_colored_polygon(_turned([Vector2(-9, -6), Vector2(-3, -6), Vector2(-3, 6), Vector2(-9, 6)], car, heading, scale), CAR_BODY.darkened(0.25))
    canvas.draw_polyline(_turned([Vector2(-11, -8), Vector2(9, -8), Vector2(12, -4), Vector2(12, 4), Vector2(9, 8), Vector2(-11, 8), Vector2(-11, -8)], car, heading, scale), CAR_BODY.darkened(0.5), 1.2, true)


static func _turned(points: Array[Vector2], center: Vector2, angle: float, scale: float) -> PackedVector2Array:
    var out: PackedVector2Array = PackedVector2Array()
    for point: Vector2 in points:
        out.append(center + point.rotated(angle) * scale)
    return out
