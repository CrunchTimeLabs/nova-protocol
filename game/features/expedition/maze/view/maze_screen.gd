class_name MazeScreen
extends Screen
## Nivel 0: el cochecito en la cantera. Lee y mueve un `MazeRun`; la extracción de precisión se abre
## encima y pausa el laberinto. Avisa con `ended` cuando se agota la batería o se sale por la rampa.


signal ended(end: MazeRun.End)

const ORIGIN := Vector2(157, 150)
const HUD_HEIGHT := 110.0
const WALL_FILL := Color(0.37, 0.37, 0.37)
const WALL_EDGE := Color(0.66, 0.66, 0.66)
const CAR_BODY := Color(0.76, 0.76, 0.76)

var run: MazeRun
var _precision: PrecisionOverlay
var _time: float = 0.0
var _heading: float = 0.0
var _dust: CPUParticles2D


func _ready() -> void:
    run = MazeRun.new(expedition, ORIGIN)
    stars.velocity = Vector2.ZERO
    _dust = Bursts.stream(Color(0.51, 0.51, 0.51, 0.5), Vector2.LEFT, 30, 40.0, 0.7, 4.0, 40.0)
    add_child(_dust)


func _process(delta: float) -> void:
    _time += delta
    update_notices(delta)
    if _precision == null and run.ended == MazeRun.End.NONE:
        var direction: Vector2 = move_input()
        var before: Vector2 = run.car
        var end: MazeRun.End = run.step(delta, direction)
        var moved: Vector2 = run.car - before
        _dust.emitting = moved.length() > 0.1
        _dust.position = run.car - Vector2.from_angle(_heading) * 14.0
        if moved.length() > 0.1:
            _heading = lerp_angle(_heading, moved.angle(), minf(1.0, delta * 14.0))
        if end != MazeRun.End.NONE:
            sfx.play(Sfx.Sound.GO if end == MazeRun.End.EXIT else Sfx.Sound.ALARM)
            ended.emit(end)
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo or _precision != null or run.ended != MazeRun.End.NONE:
        return
    var vein: MazeRun.Vein = run.nearby_vein()
    if vein == null:
        return
    if key.keycode == KEY_E:
        _take(vein, 1.0, false)
    elif key.keycode == KEY_SPACE:
        get_viewport().set_input_as_handled()
        _precision = PrecisionOverlay.new(vein, run.precision_uses, sfx)
        _precision.resolved.connect(_on_precision_resolved.bind(vein))
        add_child(_precision)


func _on_precision_resolved(multiplier: float, grade: PrecisionStop.Grade, vein: MazeRun.Vein) -> void:
    _precision.queue_free()
    _precision = null
    _take(vein, multiplier, true, PrecisionOverlay.grade_name(grade) + "  ")


func _take(vein: MazeRun.Vein, multiplier: float, used_precision: bool, prefix: String = "") -> void:
    var gained: int = run.collect(vein, multiplier, used_precision)
    var color: Color = UiPalette.resource_color(vein.res)
    var label: String = "%s+%d %s" % [prefix, gained, String(Catalog.RES_NAMES[vein.res]).to_lower()]
    if not used_precision:
        sfx.play(Sfx.Sound.VEIN)
    notify(label, color, 1.5)
    Bursts.burst(self, vein.position, UiPalette.glow(color, 2.0), 36, 220.0, 0.8, 4.0)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.06, 0.06))
    for x: int in range(0, int(size.x), 64):
        draw_line(Vector2(x, HUD_HEIGHT), Vector2(x, size.y), Color(0.08, 0.08, 0.08), 1.0)
    for y: int in range(int(HUD_HEIGHT), int(size.y), 64):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.08, 0.08, 0.08), 1.0)
    var floor_size: Vector2 = Vector2(run.maze.cols, run.maze.rows) * run.cell_size
    UiPalette.card(self, Rect2(ORIGIN - Vector2(6, 6), floor_size + Vector2(12, 12)), Color(0.1, 0.1, 0.1), Color(0.16, 0.16, 0.16), 6)
    _draw_walls()
    _draw_exit()
    _draw_veins()
    _draw_car()
    _draw_hud()
    draw_notices(size.y - 140.0)


func _draw_walls() -> void:
    for wall: Rect2 in run.walls:
        draw_rect(wall, WALL_FILL)
        draw_rect(wall, WALL_EDGE, false, 1.0)


func _draw_exit() -> void:
    var rect: Rect2 = run.exit_rect
    var pulse: float = 0.5 + 0.5 * sin(_time * 4.0)
    UiPalette.card(self, rect, Color(0.14, 0.14, 0.14), UiPalette.glow(UiPalette.OK, 1.0 + pulse * 0.8), 6)
    for i: int in 3:
        var x: float = rect.position.x + 14.0 + float(i) * 16.0 + fmod(_time * 20.0, 16.0)
        if x > rect.end.x - 12.0:
            continue
        var y: float = rect.position.y + 12.0
        draw_polyline(PackedVector2Array([Vector2(x, y), Vector2(x + 6, y + 6), Vector2(x, y + 12)]), Color(UiPalette.OK, 0.7), 2.0)
    UiPalette.text(self, rect.position + Vector2(10, 34), "RAMPA", UiPalette.TINY, UiPalette.OK, true)
    UiPalette.text(self, rect.position + Vector2(10, 52), "SALIDA", UiPalette.TINY, UiPalette.GRAY)


func _draw_veins() -> void:
    var pulse: float = 3.0 + 2.0 * sin(_time * 6.0)
    for vein: MazeRun.Vein in run.veins:
        if vein.taken:
            continue
        var color: Color = UiPalette.resource_color(vein.res)
        var p: Vector2 = vein.position
        var crystal: PackedVector2Array = PackedVector2Array([
                p + Vector2(0, -13), p + Vector2(11, -3), p + Vector2(7, 12), p + Vector2(-7, 12), p + Vector2(-11, -3)])
        draw_colored_polygon(crystal, UiPalette.glow(color, 1.25))
        draw_polyline(crystal + PackedVector2Array([crystal[0]]), Color.WHITE, 1.0)
        draw_line(p + Vector2(0, -13), p + Vector2(0, 12), Color(1.0, 1.0, 1.0, 0.35), 1.0)
        if vein.is_first:
            UiPalette.text_centered(self, p.x, p.y + 20.0, "CHATARRA DE ACERO", UiPalette.TINY, color, true)


func _draw_car() -> void:
    var at: Vector2 = run.car
    var cone: PackedVector2Array = PackedVector2Array([Vector2(14, -6), Vector2(90, -38), Vector2(90, 38), Vector2(14, 6)])
    draw_set_transform(at, _heading, Vector2.ONE)
    draw_colored_polygon(cone, Color(0.94, 0.94, 0.94, 0.07))
    UiPalette.card(self, Rect2(-15, -10, 30, 20), CAR_BODY, Color(0.28, 0.28, 0.28), 4)
    for wheel: Vector2 in [Vector2(-8, -11), Vector2(8, -11), Vector2(-8, 11), Vector2(8, 11)]:
        draw_rect(Rect2(wheel - Vector2(4, 2.5), Vector2(8, 5)), Color(0.17, 0.17, 0.17))
    draw_rect(Rect2(2, -6, 7, 12), Color(0.33, 0.33, 0.33))
    draw_circle(Vector2(14, -6), 2.5, UiPalette.glow(Color(0.94, 0.94, 0.94), 2.0))
    draw_circle(Vector2(14, 6), 2.5, UiPalette.glow(Color(0.94, 0.94, 0.94), 2.0))
    draw_circle(Vector2(-6, 0), 3.0, UiPalette.glow(UiPalette.BORDER, 1.6 + 0.4 * sin(_time * 8.0)))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hud() -> void:
    UiPalette.header(self, HUD_HEIGHT)
    UiPalette.text(self, Vector2(30, 14), "NIVEL 0 — RECOLECCIÓN EN LA TIERRA", UiPalette.TITLE, UiPalette.glow(UiPalette.BORDER, 1.2), true)
    UiPalette.text(self, Vector2(32, 52), "FLECHAS/WASD mover   |   E recoger   |   ESPACIO extracción de precisión   |   rampa verde para despegar", UiPalette.SMALL, UiPalette.GRAY)
    UiPalette.text(self, Vector2(32, 76), "Con el metal que saques se funde tu primer motor: más metal, más masa útil en la nave.   F11 pantalla completa", UiPalette.TINY, UiPalette.WARNING)
    var ratio: float = run.battery / Catalog.MAZE_BATTERY
    var battery_color: Color = UiPalette.health_color(ratio + 0.15)
    UiPalette.text(self, Vector2(size.x - 330, 14), "BATERÍA  %05.1f s" % maxf(0.0, run.battery), UiPalette.SMALL, battery_color, true)
    UiPalette.bar(self, Rect2(size.x - 330, 36, 290, 16), ratio, battery_color)
    UiPalette.resources_row(self, Vector2(size.x - 330, 60), expedition.resources, 100.0)

    var vein: MazeRun.Vein = run.nearby_vein()
    if vein != null and _precision == null:
        var color: Color = UiPalette.resource_color(vein.res)
        var box: Rect2 = Rect2(size.x / 2.0 - 290.0, size.y - 96.0, 580, 72)
        UiPalette.panel(self, box, color)
        UiPalette.text_centered(self, box.get_center().x, box.position.y + 10, "VETA DE %s — base %d" % [String(Catalog.RES_NAMES[vein.res]).to_upper(), vein.base], UiPalette.SUBTITLE, color, true)
        UiPalette.text_centered(self, box.get_center().x, box.position.y + 42, "E = recoger tal cual    |    ESPACIO = extracción de precisión (hasta x3, cuesta 4 s)", UiPalette.SMALL, UiPalette.TEXT)
