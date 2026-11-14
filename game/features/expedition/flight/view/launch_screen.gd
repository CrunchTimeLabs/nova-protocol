class_name LaunchScreen
extends Screen
## Despegue: cuenta atrás, encendido y ascenso con humo, llama y temblor. Dura unos segundos y sigue sola.


const DURATION := 8.0
const IGNITION := 2.5
const CLIMB := 4.5
const GROUND_UNTIL := 5.0
const GROUND_HEIGHT := 90.0

var _time: float = 0.0
var _last_count: int = 4
var _flame: CPUParticles2D
var _smoke: CPUParticles2D


func _ready() -> void:
    stars.velocity = Vector2.ZERO
    _smoke = Bursts.stream(Color(0.73, 0.73, 0.73, 0.55), Vector2.DOWN, 90, 160.0, 1.8, 14.0, 70.0)
    _smoke.gravity = Vector2(0, -30)
    _smoke.damping_min = 60.0
    _smoke.damping_max = 120.0
    _smoke.emitting = false
    add_child(_smoke)
    _flame = Bursts.stream(UiPalette.glow(Color(0.7, 0.7, 0.7), 2.2), Vector2.DOWN, 70, 420.0, 0.35, 6.0, 12.0)
    _flame.emitting = false
    add_child(_flame)


func _rocket_y() -> float:
    var lift: float = 0.0 if _time < IGNITION else minf(1.0, pow((_time - IGNITION) / CLIMB, 2.0))
    return (size.y - 150.0) - lift * (size.y - 40.0)


func _process(delta: float) -> void:
    _time += delta
    var count: int = 3 - int(_time)
    if _time < IGNITION and count != _last_count:
        _last_count = count
        sfx.play(Sfx.Sound.BEEP)
    if _time >= IGNITION and _last_count > 0:
        _last_count = 0
        sfx.play(Sfx.Sound.GO)
        sfx.play(Sfx.Sound.EXPLOSION, 0.6, -4.0)
        sfx.set_loop(Sfx.Loop.ENGINE, true, -2.0)
    var nozzle: Vector2 = Vector2(size.x / 2.0, _rocket_y() + 36.0)
    _flame.position = nozzle
    _flame.emitting = _time >= IGNITION
    _smoke.position = Vector2(size.x / 2.0, size.y - GROUND_HEIGHT)
    _smoke.emitting = _time >= IGNITION - 0.3 and _time < GROUND_UNTIL
    stars.velocity = Vector2(0, -maxf(0.0, (_time - IGNITION) * 140.0))
    if _time >= IGNITION:
        shake(maxf(0.0, 7.0 - (_time - IGNITION) * 1.4))
    update_shake(delta)
    if _time >= DURATION:
        sfx.set_loop(Sfx.Loop.ENGINE, false)
        done()
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    if is_continue_key(event) and _time > IGNITION + 1.0:
        sfx.set_loop(Sfx.Loop.ENGINE, false)
        done()


func _draw() -> void:
    var center_x: float = size.x / 2.0
    var y: float = _rocket_y()
    if _time < GROUND_UNTIL:
        var fade: float = clampf((GROUND_UNTIL - _time) / 1.0, 0.0, 1.0)
        draw_rect(Rect2(0, size.y - GROUND_HEIGHT, size.x, GROUND_HEIGHT), Color(Color(0.08, 0.08, 0.08), fade))
        draw_line(Vector2(0, size.y - GROUND_HEIGHT), Vector2(size.x, size.y - GROUND_HEIGHT), Color(0.4, 0.3, 0.22, fade), 2.0)
        var tower: Rect2 = Rect2(center_x + 62, size.y - 350, 22, 260)
        draw_rect(tower, Color(Color(0.25, 0.25, 0.25), fade))
        for i: int in 9:
            var ty: float = tower.position.y + float(i) * 29.0
            draw_line(Vector2(tower.position.x, ty), Vector2(tower.end.x, ty + 29.0), Color(0.15, 0.17, 0.22, fade), 2.0)
        draw_circle(Vector2(tower.get_center().x, tower.position.y - 4), 4.0, Color(UiPalette.glow(UiPalette.DANGER, 2.0), fade * (0.5 + 0.5 * sin(_time * 6.0))))
    _draw_rocket(Vector2(center_x, y))
    if _time < IGNITION:
        UiPalette.text_centered(self, center_x, 150, "T - %d" % (3 - int(_time)), UiPalette.HUGE + 20, UiPalette.glow(UiPalette.WARNING, 1.5), true)
    elif _time < IGNITION + 1.2:
        UiPalette.text_centered(self, center_x, 150, "IGNICIÓN", UiPalette.HUGE + 20, UiPalette.glow(UiPalette.OK, 1.6), true)
    UiPalette.text_centered(self, center_x, size.y - 40, "%s   ->   %s" % [expedition.engine.name, expedition.planet().name], UiPalette.SMALL, UiPalette.GRAY)


func _draw_rocket(at: Vector2) -> void:
    if _time >= IGNITION:
        var flicker: float = sin(_time * 36.0)
        var length: float = 40.0 + 70.0 * flicker * flicker + 60.0 * minf(1.0, (_time - IGNITION) / CLIMB)
        draw_colored_polygon(PackedVector2Array([at + Vector2(-14, 34), at + Vector2(0, 34 + length), at + Vector2(14, 34)]), UiPalette.glow(Color(0.69, 0.69, 0.69), 2.0))
        draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 34), at + Vector2(0, 34 + length / 2.0), at + Vector2(7, 34)]), UiPalette.glow(Color(0.95, 0.95, 0.95), 3.0))
    var body: PackedVector2Array = PackedVector2Array([
            at + Vector2(0, -46), at + Vector2(16, -10), at + Vector2(16, 34), at + Vector2(-16, 34), at + Vector2(-16, -10)])
    draw_colored_polygon(body, Color(0.92, 0.92, 0.92))
    draw_colored_polygon(PackedVector2Array([at + Vector2(0, -46), at + Vector2(16, -10), at + Vector2(16, 34), at + Vector2(4, 34), at + Vector2(4, -20)]), Color(0.78, 0.78, 0.78))
    for side: float in [-1.0, 1.0]:
        draw_colored_polygon(PackedVector2Array([at + Vector2(16 * side, 14), at + Vector2(32 * side, 36), at + Vector2(16 * side, 36)]), Color(0.36, 0.36, 0.36))
    draw_circle(at + Vector2(0, -4), 7.0, UiPalette.glow(UiPalette.BORDER, 1.4))
    draw_circle(at + Vector2(-2, -6), 2.5, Color(1.0, 1.0, 1.0, 0.7))
