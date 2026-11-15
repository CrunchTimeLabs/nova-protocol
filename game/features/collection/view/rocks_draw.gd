class_name RocksDraw
extends RefCounted
## Derrumbe dibujado: sombra que crece, rocas grandes que caen girando, polvo al chocar y escombros.
## Todo sale del tiempo transcurrido del derrumbe (no guarda estado); la forma de cada roca es fija por posición.


const FALL_TIME := 0.55
const FALL_HEIGHT := 150.0
const ROCKS := 3
## Radio de una roca respecto a la celda.
const ROCK_RADIUS := 0.27
const ROCK_SIDES := 7
const DUST_TIME := 0.45
const FADE_TIME := 0.5
const ROCK := Color(0.56, 0.43, 0.31)
const ROCK_LIGHT := Color(0.74, 0.6, 0.45)
const ROCK_DARK := Color(0.3, 0.22, 0.16)
const DUST := Color(0.7, 0.6, 0.48)


static func cave_in(
        canvas: CanvasItem,
        rect: Rect2,
        cave_in: MazeCaveIns.CaveIn,
        cell_size: float,
        scale: float,
        fall_time: float,
        ) -> void:
    var alpha: float = clampf(cave_in.remaining / FADE_TIME, 0.0, 1.0)
    var fall: float = clampf(cave_in.elapsed() / fall_time, 0.0, 1.0)
    var is_vertical: bool = cave_in.dir == Maze.W
    var length: float = rect.size.y if is_vertical else rect.size.x
    var seed_value: int = absi(cave_in.cell.x * 92821 + cave_in.cell.y * 68917 + cave_in.dir * 31)
    var radius: float = cell_size * ROCK_RADIUS * scale
    if fall >= 1.0:
        _rubble(canvas, rect, radius, seed_value, alpha)
    for i: int in ROCKS:
        var along: float = (float(i) + 0.5) / float(ROCKS) * length
        var wobble: float = float((seed_value >> i) % 7) - 3.0
        var rest: Vector2 = rect.position + (Vector2(rect.size.x / 2.0 + wobble, along) if is_vertical else Vector2(along, rect.size.y / 2.0 + wobble))
        # Cada roca cae con un pequeño retraso: parece un derrumbe y no un bloque.
        var own: float = clampf(fall * 1.3 - float(i) * 0.15, 0.0, 1.0)
        var size: float = radius * (0.85 + 0.1 * float((seed_value >> (i + 2)) % 4))
        if own < 1.0:
            var shadow: float = 0.25 + 0.75 * own
            _ellipse(canvas, rest + Vector2(0, size * 0.6), Vector2(size * shadow, size * 0.4 * shadow), Color(0, 0, 0, 0.45 * own))
        var height: float = (1.0 - own * own) * FALL_HEIGHT * scale
        var spin: float = (1.0 - own) * 2.5 * (1.0 if i % 2 == 0 else -1.0)
        rock(canvas, rest - Vector2(0, height), size, spin, seed_value + i * 17, alpha)
    var since_impact: float = cave_in.elapsed() - fall_time
    if since_impact >= 0.0 and since_impact < DUST_TIME:
        var t: float = since_impact / DUST_TIME
        for i: int in 10:
            var angle: float = float(i) / 10.0 * TAU
            var p: Vector2 = rect.get_center() + Vector2.from_angle(angle) * (radius + t * radius * 2.2) * Vector2(1.4, 0.8)
            canvas.draw_circle(p, radius * 0.45 * (1.0 - t * 0.5), Color(DUST, 0.5 * (1.0 - t)))


## Roca irregular con luz arriba a la izquierda.
static func rock(canvas: CanvasItem, center: Vector2, size: float, spin: float, seed_value: int, alpha: float) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for k: int in ROCK_SIDES:
        var jag: float = 0.75 + 0.25 * float((seed_value * (k + 3)) % 5) / 4.0
        points.append(center + Vector2.from_angle(float(k) / ROCK_SIDES * TAU + spin) * size * jag)
    canvas.draw_colored_polygon(points, Color(ROCK, alpha))
    var light: PackedVector2Array = PackedVector2Array()
    for point: Vector2 in points:
        light.append(center + (point - center) * 0.55 + Vector2(-size * 0.18, -size * 0.2))
    canvas.draw_colored_polygon(light, Color(ROCK_LIGHT, alpha * 0.8))
    points.append(points[0])
    canvas.draw_polyline(points, Color(ROCK_DARK, alpha), 1.5, true)
    canvas.draw_line(center + Vector2(-size * 0.2, size * 0.1), center + Vector2(size * 0.3, size * 0.35), Color(ROCK_DARK, alpha * 0.8), 1.2)


## Montón de piedras pequeñas bajo las rocas, a lo largo del paso tapado.
static func _rubble(canvas: CanvasItem, rect: Rect2, radius: float, seed_value: int, alpha: float) -> void:
    var area: Rect2 = rect.grow(radius * 0.5)
    for i: int in 9:
        var h: int = absi(seed_value * (i + 7) * 2654435761) % 10007
        var p: Vector2 = area.position + Vector2(float(h % 101) / 101.0 * area.size.x, float(h % 89) / 89.0 * area.size.y)
        canvas.draw_circle(p, radius * (0.2 + 0.1 * float(h % 3)), Color(ROCK_DARK.lerp(ROCK, float(h % 4) / 4.0), alpha))


static func _ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for k: int in 16:
        points.append(center + Vector2.from_angle(float(k) / 16.0 * TAU) * radii)
    canvas.draw_colored_polygon(points, color)
