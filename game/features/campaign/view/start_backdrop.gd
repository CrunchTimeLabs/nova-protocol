class_name StartBackdrop
extends Control
## Fondo animado de la pantalla de inicio: estrellas en tres capas, nebulosa y un planeta, y el cohete de pixel art
## (piezas base, de lado) que esquiva asteroides: mira el que se le acerca, se aparta con el propulsor lateral y
## acelera con su llama. Solo decorativo: ignora el ratón y no lee nada del juego.


const SKY_TOP := Color(0.02, 0.02, 0.07)
const SKY_BOTTOM := Color(0.07, 0.03, 0.12)
const STAR_LAYERS: Array[float] = [12.0, 30.0, 70.0]
const STARS_PER_LAYER := 70
const ROCK_COUNT := 7
const ROCKET_PARTS: Array[RocketParts.Part] = [
    RocketParts.Part.C2, RocketParts.Part.A1, RocketParts.Part.T1, RocketParts.Part.P1, RocketParts.Part.M2,
]
const ROCKET_SCALE := 1.6
const ROCKET_X := 0.3
const DODGE_LOOKAHEAD := 360.0
const PIXEL := 4.0

var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _stars: Array[Dictionary] = []
var _rocks: Array[Dictionary] = []
var _puffs: Array[Dictionary] = []
var _ship_y: float = 0.0
var _ship_vy: float = 0.0
var _side_burn: float = 0.0
var _boost: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _rng.seed = 2026
    for layer: int in STAR_LAYERS.size():
        for i: int in STARS_PER_LAYER:
            _stars.append({"layer": layer, "pos": Vector2(_rng.randf_range(0, 1024), _rng.randf_range(0, 640)),
                    "twinkle": _rng.randf_range(0.0, TAU)})
    for i: int in ROCK_COUNT:
        _rocks.append(_new_rock(true))
    _ship_y = 320.0


func _area() -> Vector2:
    return size if size.x > 1.0 else Vector2(1024, 640)


func _new_rock(anywhere: bool) -> Dictionary:
    var area: Vector2 = _area()
    var radius: float = _rng.randf_range(14.0, 42.0)
    var outline: PackedVector2Array = PackedVector2Array()
    var sides: int = _rng.randi_range(7, 10)
    for i: int in sides:
        var angle: float = TAU * float(i) / float(sides)
        outline.append(Vector2.from_angle(angle) * radius * _rng.randf_range(0.72, 1.08))
    var x: float = _rng.randf_range(area.x * 0.4, area.x * 1.6) if anywhere else area.x + radius + _rng.randf_range(0, 300)
    return {
        "pos": Vector2(x, _rng.randf_range(60.0, area.y - 60.0)),
        "speed": _rng.randf_range(90.0, 190.0),
        "spin": _rng.randf_range(-1.2, 1.2),
        "angle": 0.0,
        "radius": radius,
        "outline": outline,
    }


func _process(delta: float) -> void:
    _time += delta
    var area: Vector2 = _area()
    for star: Dictionary in _stars:
        var pos: Vector2 = star["pos"]
        pos.x -= STAR_LAYERS[int(star["layer"])] * delta * (1.0 + _boost)
        if pos.x < 0.0:
            pos = Vector2(area.x, _rng.randf_range(0, area.y))
        star["pos"] = pos
    for index: int in _rocks.size():
        var rock: Dictionary = _rocks[index]
        var pos: Vector2 = rock["pos"]
        pos.x -= float(rock["speed"]) * delta
        rock["pos"] = pos
        rock["angle"] = float(rock["angle"]) + float(rock["spin"]) * delta
        if pos.x < -80.0:
            _rocks[index] = _new_rock(false)
    _steer(delta, area)
    for index: int in range(_puffs.size() - 1, -1, -1):
        var puff: Dictionary = _puffs[index]
        puff["pos"] = (puff["pos"] as Vector2) + (puff["vel"] as Vector2) * delta
        puff["life"] = float(puff["life"]) - delta
        if float(puff["life"]) <= 0.0:
            _puffs.remove_at(index)
    queue_redraw()


## Busca la roca que viene hacia el cohete y se aparta hacia el lado con más hueco.
func _steer(delta: float, area: Vector2) -> void:
    var ship: Vector2 = Vector2(area.x * ROCKET_X, _ship_y)
    var wanted: float = area.y * 0.5 + sin(_time * 0.6) * area.y * 0.18
    var threat: float = 0.0
    for rock: Dictionary in _rocks:
        var pos: Vector2 = rock["pos"]
        var ahead: float = pos.x - ship.x
        if ahead < -40.0 or ahead > DODGE_LOOKAHEAD:
            continue
        var gap: float = float(rock["radius"]) + 70.0
        if absf(pos.y - ship.y) < gap:
            var away: float = -1.0 if pos.y > ship.y else 1.0
            if ship.y + away * gap < 50.0 or ship.y + away * gap > area.y - 50.0:
                away = -away
            wanted = pos.y + away * gap
            threat = maxf(threat, 1.0 - ahead / DODGE_LOOKAHEAD)
    var accel: float = clampf((wanted - _ship_y) * 6.0 - _ship_vy * 3.5, -900.0, 900.0)
    _ship_vy += accel * delta
    _ship_y = clampf(_ship_y + _ship_vy * delta, 50.0, area.y - 50.0)
    _side_burn = clampf(absf(accel) / 900.0, 0.0, 1.0)
    _boost = lerpf(_boost, threat, 1.0 - exp(-delta * 4.0))
    if _side_burn > 0.35 and _rng.randf() < 0.6:
        var side: float = -signf(accel)
        _puffs.append({"pos": ship + Vector2(-10.0, side * 26.0), "vel": Vector2(-60.0, side * 120.0), "life": 0.45})
    if _rng.randf() < 0.8:
        _puffs.append({"pos": ship + Vector2(-_rocket_length() * 0.5 - 6.0, _rng.randf_range(-6, 6)),
                "vel": Vector2(-220.0 - 200.0 * _boost, _rng.randf_range(-20, 20)), "life": 0.6})


func _rocket_length() -> float:
    return float(RocketParts.total_height()) * ROCKET_SCALE


func _draw() -> void:
    var area: Vector2 = _area()
    var bands: int = 16
    for i: int in bands:
        var t: float = float(i) / float(bands - 1)
        draw_rect(Rect2(0, area.y * float(i) / float(bands), area.x, area.y / float(bands) + 1.0), SKY_TOP.lerp(SKY_BOTTOM, t))
    _draw_nebula(area)
    for star: Dictionary in _stars:
        var layer: int = int(star["layer"])
        var bright: float = 0.35 + 0.25 * float(layer) + 0.2 * sin(_time * 3.0 + float(star["twinkle"]))
        var pos: Vector2 = (star["pos"] as Vector2).floor()
        var length: float = 1.0 + float(layer) * 2.0 * _boost
        draw_rect(Rect2(pos, Vector2(maxf(2.0, length * 2.0), 2.0)), Color(0.85, 0.9, 1.0, bright))
    _draw_planet(area)
    for rock: Dictionary in _rocks:
        _draw_rock(rock)
    for puff: Dictionary in _puffs:
        var life: float = float(puff["life"])
        var p: Vector2 = ((puff["pos"] as Vector2) / PIXEL).floor() * PIXEL
        draw_rect(Rect2(p, Vector2(PIXEL, PIXEL) * (1.0 + (0.6 - life) * 3.0)), Color(0.9, 0.85, 0.8, life * 0.6))
    _draw_rocket(Vector2(area.x * ROCKET_X, _ship_y))
    draw_rect(Rect2(Vector2.ZERO, area), Color(0, 0, 0, 0.18))


func _draw_nebula(area: Vector2) -> void:
    for i: int in 6:
        var center: Vector2 = Vector2(area.x * (0.55 + 0.08 * float(i)), area.y * (0.3 + 0.07 * sin(float(i) * 1.7)))
        _soft_blob(center, 120.0 + 30.0 * float(i % 3), Color(0.45, 0.2, 0.6, 0.012))
    _soft_blob(Vector2(area.x * 0.2, area.y * 0.85), 220.0, Color(0.15, 0.3, 0.6, 0.014))


## Mancha difusa: círculos concéntricos muy tenues (el borde no se nota).
func _soft_blob(center: Vector2, radius: float, color: Color) -> void:
    for k: int in 6:
        draw_circle(center, radius * (1.0 - 0.15 * float(k)), color)


func _draw_planet(area: Vector2) -> void:
    var center: Vector2 = Vector2(area.x * 0.84, area.y * 0.2)
    var radius: float = 70.0
    draw_circle(center, radius + 10.0, Color(0.4, 0.6, 1.0, 0.08))
    draw_circle(center, radius, Color(0.22, 0.32, 0.55))
    draw_circle(center + Vector2(-14, -14), radius * 0.82, Color(0.3, 0.45, 0.72))
    draw_circle(center + Vector2(-26, -26), radius * 0.45, Color(0.45, 0.62, 0.88))
    draw_arc(center, radius + 26.0, deg_to_rad(200), deg_to_rad(340), 48, Color(0.8, 0.75, 0.6, 0.5), 3.0)


func _draw_rock(rock: Dictionary) -> void:
    var xf: Transform2D = Transform2D(float(rock["angle"]), rock["pos"] as Vector2)
    var outline: PackedVector2Array = rock["outline"]
    draw_colored_polygon(xf * outline, Color8(92, 74, 66))
    draw_colored_polygon(Transform2D(float(rock["angle"]), (rock["pos"] as Vector2) + Vector2(-3, -3)) * (Transform2D().scaled(Vector2.ONE * 0.62) * outline), Color8(124, 100, 86))
    var closed: PackedVector2Array = xf * outline
    closed.append(closed[0])
    draw_polyline(closed, Color8(160, 128, 104), 2.0)


## El cohete se dibuja con la nariz a la derecha: rota -90° las piezas apiladas (arriba = carga útil).
func _draw_rocket(center: Vector2) -> void:
    var tilt: float = clampf(_ship_vy / 900.0, -0.35, 0.35)
    var length: float = _rocket_length()
    var width: float = float(RocketParts.WIDTH) * ROCKET_SCALE
    draw_set_transform(center, PI / 2.0 + tilt, Vector2.ONE)
    # Llama (en coordenadas del cohete vertical: la base está en +length/2).
    var frame: int = int(_time * 14.0) % RocketParts.FLAME_FRAMES.size()
    var flame: Texture2D = RocketView.texture(RocketParts.TEXTURE_DIR + RocketParts.FLAME_FRAMES[frame])
    var flame_size: Vector2 = Vector2(flame.get_width(), flame.get_height()) * ROCKET_SCALE
    flame_size.y *= 0.8 + _boost * 1.2
    draw_texture_rect(flame, Rect2(Vector2(-flame_size.x / 2.0, length / 2.0 - 6.0), flame_size), false)
    var top: float = -length / 2.0
    for part: RocketParts.Part in ROCKET_PARTS:
        var section: RocketParts.Section = RocketParts.section_of(part)
        var y: float = top + float(RocketParts.section_top(section)) * ROCKET_SCALE
        var height: float = float(RocketParts.SECTION_HEIGHTS[section]) * ROCKET_SCALE
        draw_texture_rect(RocketView.part_texture(part), Rect2(-width / 2.0, y, width, height), false)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
