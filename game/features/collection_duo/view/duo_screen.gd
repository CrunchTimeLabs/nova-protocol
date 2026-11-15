class_name DuoScreen
extends Control
## Recolección a dos en una sola pantalla: arriba el marcador (jugador 1, total y mínimo, jugador 2), abajo
## el laberinto entero. El tutorial grande del centro se va cuando los dos entran. Al terminar, el resumen
## dice quién recogió más. Lee la partida, le pasa las teclas y suena; no decide reglas.
## J1: WASD · J2: IJKL · R: otro laberinto · Esc: dificultad · Enter al final: continuar.


signal restart_requested
signal exit_requested
signal continue_requested

const TOP_BAR := 64.0
const BACKGROUND := Color(0.035, 0.035, 0.045)
const TEXT := Color(0.94, 0.94, 0.92)
const HINT := Color(0.6, 0.6, 0.63)
const ACCENT := Color(0.95, 0.74, 0.18)
const TURN_RATE := 14.0
const NOTICE_LIFE := 1.1
const SHAKE_TIME := 0.35
const SHAKE_STRENGTH := 5.0
const RAIN_SHAKE := 8.0
const RAIN_COOLDOWN := 0.5
const BANNER_TIME := 2.6
const DUST := Color(0.55, 0.47, 0.38, 0.6)

var _run: DuoRun
var _sfx: CollectionSfx
var _tutorial: DuoTutorial
var _rain: RockRain
var _fx: CollectionFx = CollectionFx.new()
var _look: DuoDraw.Look = DuoDraw.Look.new()
var _time: float = 0.0
var _notices: Array[Dictionary] = []
var _shake: float = 0.0
var _impacts: Array[Array] = []
var _last_rain: float = -INF
var _flash: Array[float] = [0.0, 0.0]
var _banner: String = ""
var _banner_left: float = 0.0
var _has_seen_cave_in: bool = false
var _ended_at: float = -1.0


func _init(run: DuoRun) -> void:
    _run = run


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sfx = CollectionSfx.new()
    add_child(_sfx)
    _rain = RockRain.new()
    add_child(_rain)
    _tutorial = DuoTutorial.new(_run)
    add_child(_tutorial)
    _run.collected.connect(_on_collected)
    _run.ore_lost.connect(_on_ore_lost)
    _run.cave_in_started.connect(_on_cave_in_started)
    _run.exit_opened.connect(_on_exit_opened)
    _run.finished.connect(_on_finished)
    _sfx.play(CollectionSfx.Sound.LESSON, -4.0)


static func input_for(player: int) -> Vector2:
    var keys: Array[Key] = [KEY_D, KEY_A, KEY_S, KEY_W]
    if player == 2:
        keys = [KEY_L, KEY_J, KEY_K, KEY_I]
    var x: float = float(Input.is_physical_key_pressed(keys[0])) - float(Input.is_physical_key_pressed(keys[1]))
    var y: float = float(Input.is_physical_key_pressed(keys[2])) - float(Input.is_physical_key_pressed(keys[3]))
    return Vector2(x, y)


func _process(delta: float) -> void:
    _time += delta
    _shake = maxf(0.0, _shake - delta)
    _banner_left = maxf(0.0, _banner_left - delta)
    if _run.is_warming_up and _run.both_entered():
        _run.is_warming_up = false
    var before: Array[Vector2] = [_run.cars[0].position, _run.cars[1].position]
    var directions: Array[Vector2] = [input_for(1), input_for(2)]
    _run.step(delta, directions)
    var any_moving: bool = false
    for index: int in _run.cars.size():
        var moved: Vector2 = _run.cars[index].position - before[index]
        if moved.length() > 0.1 and not _run.is_finished:
            any_moving = true
            _look.headings[index] = lerp_angle(_look.headings[index], moved.angle(), minf(1.0, delta * TURN_RATE))
            _fx.trail(_run.cars[index].position - Vector2.from_angle(_look.headings[index]) * 10.0, -moved.normalized(), DUST)
        _flash[index] = maxf(0.0, _flash[index] - delta)
    _sfx.set_engine(any_moving)
    _fx.update(delta)
    _update_impacts(delta)
    for notice: Dictionary in _notices.duplicate():
        notice["age"] = float(notice["age"]) + delta
        if float(notice["age"]) > NOTICE_LIFE:
            _notices.erase(notice)
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_R:
            restart_requested.emit()
        KEY_ESCAPE:
            exit_requested.emit()
        KEY_ENTER, KEY_KP_ENTER:
            if _run.is_finished:
                continue_requested.emit()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
    var strength: float = maxf(SHAKE_STRENGTH * (_shake / SHAKE_TIME), RAIN_SHAKE * _rain.intensity())
    draw_set_transform(Vector2(sin(_time * 90.0), cos(_time * 70.0)) * strength, 0.0, Vector2.ONE)
    DuoDraw.board(self, _run, _time, _look)
    _fx.draw(self)
    for notice: Dictionary in _notices:
        var age: float = float(notice["age"])
        UiDraw.text_centered(self, (notice["where"] as Vector2).x, (notice["where"] as Vector2).y - 26.0 - age * 34.0,
                str(notice["text"]), 14, Color(notice["color"] as Color, 1.0 - age / NOTICE_LIFE), true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_scoreboard()
    _draw_exit_hint()
    if _banner_left > 0.0:
        _draw_banner()
    if _run.is_finished:
        _draw_results()


func _draw_scoreboard() -> void:
    draw_rect(Rect2(0, 0, size.x, TOP_BAR), Color(0.05, 0.05, 0.07))
    draw_line(Vector2(0, TOP_BAR), Vector2(size.x, TOP_BAR), Color(ACCENT, 0.4), 1.0)
    _player_box(Rect2(10, 6, 330, 52), 1, "WASD")
    _player_box(Rect2(size.x - 340, 6, 330, 52), 2, "IJKL")
    var cx: float = size.x / 2.0
    var total: int = _run.total()
    var minimum: int = _run.level.minimum
    UiDraw.text_centered(self, cx, 4, "RECOLECCIÓN · %s" % _run.level.title(), 12, HINT, true)
    UiDraw.text_centered(self, cx, 18, "%d / %d" % [total, minimum], 22, ACCENT if total < minimum else DuoDraw.OPEN, true)
    var bar: Rect2 = Rect2(cx - 140, 48, 280, 8)
    UiDraw.bar(self, bar, float(total) / float(minimum), ACCENT if total < minimum else DuoDraw.OPEN, Color(0.12, 0.12, 0.14), Color(0.4, 0.4, 0.42))
    var share: float = float(_run.cars[0].units()) / float(maxi(1, total))
    if total > 0:
        draw_rect(Rect2(bar.position, Vector2(bar.size.x * minf(1.0, float(total) / float(minimum)) * share, 3)), DuoDraw.P1)


func _player_box(rect: Rect2, player: int, keys: String) -> void:
    var car: MazeCar = _run.cars[player - 1]
    var color: Color = DuoDraw.player_color(player)
    var flash: float = _flash[player - 1] / 0.4
    UiDraw.panel(self, rect, Color(color, 0.07 + 0.2 * flash), Color(color, 0.6))
    var is_left: bool = player == 1
    var car_x: float = rect.position.x + 26 if is_left else rect.end.x - 26
    CollectionDraw.car(self, Vector2(car_x, rect.get_center().y), 0.0 if is_left else PI, 0.9, color, false)
    var text_x: float = rect.position.x + 52 if is_left else rect.position.x + 14
    UiDraw.text(self, Vector2(text_x, rect.position.y + 4), "JUGADOR %d · %s" % [player, keys], 11, color, true)
    var x: float = text_x
    for ore: Ores.Ore in Ores.all():
        draw_texture_rect(Ores.texture(ore), Rect2(x, rect.position.y + 22, 22, 22), false)
        UiDraw.text(self, Vector2(x + 22, rect.position.y + 26), str(car.tally.count(ore)), 12, TEXT, true)
        x += 44.0
    var count_right: float = rect.end.x - 12 if is_left else rect.end.x - 52
    UiDraw.text(self, Vector2(count_right - 54, rect.position.y + 10), str(car.units()), 28 + int(6.0 * flash), color, true, HORIZONTAL_ALIGNMENT_RIGHT, 54.0)


func _draw_exit_hint() -> void:
    if _run.is_warming_up or _run.is_finished:
        return
    var rect: Rect2 = _run.exit_rect
    var left: int = _run.level.minimum - _run.total()
    var text: String = "Faltan %d" % left if left > 0 else "¡Los dos a la rampa!"
    if left <= 0:
        var on_ramp: Array[int] = []
        for car: MazeCar in _run.cars:
            if car.is_on_exit:
                on_ramp.append(car.player)
        if on_ramp.size() == 1:
            text = "J%d listo · falta J%d" % [on_ramp[0], 3 - on_ramp[0]]
    var color: Color = DuoDraw.LOCKED if left > 0 else DuoDraw.OPEN
    UiDraw.text(self, Vector2(rect.end.x + 10, rect.position.y + 12), text, 14, color, true)


func _draw_banner() -> void:
    var alpha: float = minf(1.0, _banner_left / 0.4)
    var band: Rect2 = Rect2(0, size.y / 2.0 - 40, size.x, 80)
    draw_rect(band, Color(0.08, 0.03, 0.02, 0.75 * alpha))
    UiDraw.text_centered(self, size.x / 2.0, band.position.y + 10, _banner, 30, Color(1.0, 0.55, 0.3, alpha), true)
    UiDraw.text_centered(self, size.x / 2.0, band.position.y + 50, "Las rocas tapan pasillos un rato: busquen otro camino", 14, Color(TEXT, alpha))


func _draw_results() -> void:
    var t: float = clampf((_time - _ended_at) / 0.5, 0.0, 1.0)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65 * t))
    var box: Rect2 = Rect2(size.x / 2.0 - 330, size.y / 2.0 - 220 + 20.0 * (1.0 - t), 660, 440)
    UiDraw.panel(self, box, Color(0.05, 0.05, 0.07, 0.97 * t), Color(ACCENT, t))
    var cx: float = box.get_center().x
    var leader: int = _run.leader()
    var title: String = "¡EMPATE!" if leader == 0 else "¡JUGADOR %d RECOGIÓ MÁS!" % leader
    var title_color: Color = ACCENT if leader == 0 else DuoDraw.player_color(leader)
    UiDraw.text_centered(self, cx, box.position.y + 20, title, 30, Color(title_color, t), true)
    UiDraw.text_centered(self, cx, box.position.y + 62, "Juntaron %d menas (mínimo %d)" % [_run.total(), _run.level.minimum], 15, Color(TEXT, t))
    for index: int in 2:
        var car: MazeCar = _run.cars[index]
        var color: Color = DuoDraw.player_color(car.player)
        var column: Rect2 = Rect2(box.position.x + 24 + float(index) * 312, box.position.y + 96, 300, 250)
        var is_winner: bool = leader == car.player
        UiDraw.panel(self, column, Color(color, 0.06 * t), Color(color, (0.9 if is_winner else 0.35) * t))
        if is_winner:
            UiDraw.text_centered(self, column.get_center().x, column.position.y - 12, "★ GANADOR ★", 13, Color(color, t), true)
        UiDraw.text_centered(self, column.get_center().x, column.position.y + 12, "JUGADOR %d" % car.player, 16, Color(color, t), true)
        UiDraw.text_centered(self, column.get_center().x, column.position.y + 34, str(car.units()), 40, Color(TEXT, t), true)
        var y: float = column.position.y + 92
        for ore: Ores.Ore in Ores.all():
            draw_texture_rect(Ores.texture(ore), Rect2(column.position.x + 30, y - 4, 24, 24), false, Color(1, 1, 1, t))
            UiDraw.text(self, Vector2(column.position.x + 62, y), Ores.ore_name(ore), 13, Color(Ores.color(ore), t), true)
            UiDraw.text(self, Vector2(column.position.x + 62, y), "%d" % car.tally.count(ore), 14, Color(TEXT, t), true, HORIZONTAL_ALIGNMENT_RIGHT, 200.0)
            y += 30.0
    UiDraw.text_centered(self, cx, box.end.y - 60, "Las menas van a la fundición →", 15, Color(ACCENT, t), true)
    UiDraw.text_centered(self, cx, box.end.y - 32, "ENTER: continuar    R: otro laberinto    Esc: dificultad", 14, Color(HINT, t), true)


func _update_impacts(delta: float) -> void:
    for impact: Array in _impacts.duplicate():
        impact[0] = float(impact[0]) - delta
        if float(impact[0]) > 0.0:
            continue
        _impacts.erase(impact)
        _shake = SHAKE_TIME
        _sfx.play(CollectionSfx.Sound.CRASH, -3.0)
        _fx.burst(impact[1] as Vector2, RocksDraw.DUST, 18, 130.0, 0.6, 4.0)


func _on_collected(car: MazeCar, ore: Ores.Ore, where: Vector2) -> void:
    var color: Color = DuoDraw.player_color(car.player)
    _notices.append({"text": "+1 %s" % Ores.ore_name(ore), "where": where, "color": color, "age": 0.0})
    _flash[car.player - 1] = 0.4
    _fx.burst(where, Ores.color(ore), 18, 150.0, 0.5, 3.0)
    _sfx.play(CollectionSfx.Sound.CRYSTAL if ore == Ores.Ore.ILMENITE else CollectionSfx.Sound.METAL, -2.0, 1.0 if car.player == 1 else 1.15)


func _on_ore_lost(ore: Ores.Ore, where: Vector2) -> void:
    _fx.burst(where, Color(Ores.color(ore), 0.5), 8, 40.0, 0.5, 3.0)
    _sfx.play(CollectionSfx.Sound.LOST, -8.0)


func _on_cave_in_started(cave_in: MazeCaveIns.CaveIn) -> void:
    _sfx.play(CollectionSfx.Sound.RUMBLE, -4.0)
    if _time - _last_rain >= RAIN_COOLDOWN:
        _last_rain = _time
        _rain.pour(_run.level.big_rocks)
    _impacts.append([RocksDraw.FALL_TIME, _run.cave_in_rect(cave_in).get_center()])
    if not _has_seen_cave_in:
        _has_seen_cave_in = true
        _banner = "¡DERRUMBE!"
        _banner_left = BANNER_TIME


func _on_exit_opened() -> void:
    _sfx.play(CollectionSfx.Sound.LESSON)
    _banner = "¡RAMPA ABIERTA!"
    _banner_left = 0.0
    _notices.append({"text": "¡RAMPA ABIERTA!", "where": _run.exit_rect.get_center() - Vector2(0, 20), "color": DuoDraw.OPEN, "age": 0.0})


func _on_finished() -> void:
    _ended_at = _time
    _rain.visible = false
    _sfx.set_engine(false)
    _sfx.play(CollectionSfx.Sound.FINISH)
