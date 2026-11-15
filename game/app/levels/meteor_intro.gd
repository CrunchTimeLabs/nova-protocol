class_name MeteorIntro
extends Control
## Presentación del nivel Meteoritos (encima de la pantalla dividida, el juego en pausa):
## 1. Tutorial en la pantalla del piloto: una demo del cohete esquivando y la tarea «muévete con las flechas».
## 2. Un panel que ocupa el 70 % de la pantalla y explica, con un dibujo animado, los desvíos de trayectoria.
## ENTER en el panel empieza el juego (`finished`).


signal finished

enum Step { PILOT, DEVIATION, DONE }

const PILOT_AREA := Rect2(516, 72, 504, 564)
const MOVE_NEEDED := 1.2
const PANEL_RATIO := 0.7
const CYAN := Color8(0, 200, 240)
const TEXT := Color8(224, 238, 252)
const GRAY := Color8(140, 163, 190)
const OK := Color8(60, 230, 140)
const DANGER := Color8(255, 80, 80)
const WARNING := Color8(255, 185, 50)
const PANEL_FILL := Color8(14, 22, 36)

var step: Step = Step.PILOT
var _moved: float = 0.0
var _time: float = 0.0
var _step_time: float = 0.0
var _rocket: Array[RocketParts.Part] = RocketSprite.parts_from(CampaignState.rocket)


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
    _time += delta
    _step_time += delta
    if step == Step.PILOT:
        var arrows: bool = Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_DOWN) \
                or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
        if arrows:
            _moved += delta
        if _moved >= MOVE_NEEDED and _step_time > 0.5:
            _moved = MOVE_NEEDED
            if _step_time > 0.0:
                step = Step.DEVIATION
                _step_time = 0.0
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    if step == Step.DEVIATION and _step_time > 0.6 and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
        step = Step.DONE
        visible = false
        finished.emit()
        get_viewport().set_input_as_handled()


func _draw() -> void:
    match step:
        Step.PILOT:
            _draw_pilot()
        Step.DEVIATION:
            _draw_deviation()


## Tutorial del piloto, solo en su pantalla: demo animada + tarea.
func _draw_pilot() -> void:
    var area: Rect2 = PILOT_AREA
    draw_rect(area, Color(0.01, 0.02, 0.05, 0.86))
    UiDraw.panel(self, area.grow(-10.0), Color(PANEL_FILL, 0.95), CYAN)
    var cx: float = area.get_center().x
    UiDraw.text(self, area.position + Vector2(24, 20), "TUTORIAL · PILOTO", 12, GRAY, true)
    UiDraw.text_centered(self, cx, area.position.y + 44, "ESQUIVA LOS METEORITOS", 24, CYAN, true)
    var demo: Rect2 = Rect2(area.position.x + 30, area.position.y + 90, area.size.x - 60, 220)
    draw_rect(demo, Color8(6, 9, 18))
    for i: int in 40:
        var h: int = absi(i * 2654435761) % 100000
        var x: float = demo.end.x - fmod(float(h % 997) + _time * (30.0 + float(h % 3) * 30.0), demo.size.x)
        draw_rect(Rect2(x, demo.position.y + float(h % 211) / 211.0 * demo.size.y, 2, 2), Color(0.8, 0.85, 1.0, 0.6))
    # Una roca que cruza y el cohete que se aparta.
    var cycle: float = fmod(_time, 3.0) / 3.0
    var rock: Vector2 = Vector2(demo.end.x + 30.0 - cycle * (demo.size.x + 60.0), demo.get_center().y)
    var dodge: float = clampf(1.0 - absf(rock.x - (demo.position.x + 110.0)) / 160.0, 0.0, 1.0)
    var ship: Vector2 = Vector2(demo.position.x + 110.0, demo.get_center().y - 60.0 * (dodge * dodge * (3.0 - 2.0 * dodge)))
    draw_circle(rock, 22.0, Color8(104, 82, 70))
    draw_circle(rock + Vector2(-4, -4), 13.0, Color8(124, 100, 86))
    draw_arc(rock, 22.0, 0.0, TAU, 20, Color8(156, 126, 104), 2.0)
    RocketSprite.draw_sideways(self, _rocket, ship, 0.4, _time, 0.8, false)
    UiDraw.text_centered(self, ship.x, ship.y - 46.0, "↑", 22, Color(CYAN, dodge), true)
    UiDraw.text_centered(self, cx, demo.end.y + 18, "Flechas: mover · Tu cohete es el que armaste", 15, TEXT)
    UiDraw.text_centered(self, cx, demo.end.y + 44, "La ESTACIÓN (F) activa la fase: atraviesas rocas un rato", 13, GRAY)
    var bar: Rect2 = Rect2(area.position.x + 60, area.end.y - 110, area.size.x - 120, 16)
    UiDraw.text_centered(self, cx, bar.position.y - 30, "Tu turno: mueve el cohete con las flechas", 15, WARNING, true)
    UiDraw.bar(self, bar, _moved / MOVE_NEEDED, OK, Color8(26, 38, 56), Color(CYAN, 0.6))
    # La estación espera.
    var wait: Rect2 = Rect2(40, 280, 420, 90)
    UiDraw.panel(self, wait, Color(PANEL_FILL, 0.92), Color8(48, 76, 110))
    UiDraw.text_centered(self, wait.get_center().x, wait.position.y + 20, "ESTACIÓN: el piloto está practicando", 15, TEXT, true)
    UiDraw.text_centered(self, wait.get_center().x, wait.position.y + 52, "Esperen" + ".".repeat(1 + int(_time * 3.0) % 3), 14, GRAY)


## Panel del 70 %: los desvíos de trayectoria, simple y visual.
func _draw_deviation() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
    var panel_size: Vector2 = size * PANEL_RATIO
    var appear: float = clampf(_step_time / 0.35, 0.0, 1.0)
    var box: Rect2 = Rect2((size - panel_size) / 2.0 + Vector2(0, 20.0 * (1.0 - appear)), panel_size)
    UiDraw.panel(self, box, Color(PANEL_FILL, 0.97), CYAN)
    var cx: float = box.get_center().x
    UiDraw.text_centered(self, cx, box.position.y + 16, "¡CUIDADO CON LOS DESVÍOS!", 26, WARNING, true)
    # Dibujo: sol, ruta planeada (recta, cian) y ruta real (curvada hacia el sol, roja) con el cohete recorriéndola.
    var map: Rect2 = Rect2(box.position.x + 24, box.position.y + 60, box.size.x * 0.58, box.size.y - 120)
    draw_rect(map, Color8(6, 9, 18))
    var sun: Vector2 = map.position + Vector2(map.size.x * 0.55, map.size.y * 0.78)
    for k: int in 5:
        draw_circle(sun, 18.0 + float(k) * 9.0, Color(1.0, 0.8, 0.4, 0.06))
    draw_circle(sun, 18.0, Color(1.0, 0.82, 0.4))
    var start: Vector2 = map.position + Vector2(30, map.size.y * 0.3)
    var goal: Vector2 = map.position + Vector2(map.size.x - 34, map.size.y * 0.3)
    draw_arc(goal, 22.0, 0.0, TAU, 32, OK, 2.0)
    UiDraw.text_centered(self, goal.x, goal.y + 26, "LUNA", 11, OK, true)
    for i: int in 24:
        var t: float = float(i) / 23.0
        draw_circle(start.lerp(goal, t), 2.0, Color(CYAN, 0.9))
    var real: PackedVector2Array = PackedVector2Array()
    for i: int in 40:
        var t: float = float(i) / 39.0
        var p: Vector2 = start.lerp(goal, t)
        p = p.lerp(sun, 0.55 * sin(t * PI) * minf(1.0, t * 1.4))
        real.append(p)
    for i: int in range(1, real.size()):
        draw_line(real[i - 1], real[i], Color(DANGER, 0.85), 2.5)
    var loop: float = fmod(_step_time * 0.35, 1.0)
    var index: int = clampi(int(loop * float(real.size() - 1)), 0, real.size() - 2)
    var at: Vector2 = real[index]
    var dir: Vector2 = (real[index + 1] - at).normalized()
    var warn: float = 0.5 + 0.5 * sin(_time * 10.0)
    draw_arc(at, 20.0, 0.0, TAU, 24, Color(DANGER, 0.4 + 0.4 * warn), 2.0)
    draw_set_transform(at, dir.angle(), Vector2.ONE)
    RocketSprite.draw_sideways(self, _rocket, Vector2.ZERO, 0.22, _time, 0.6, false)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    UiDraw.text(self, map.position + Vector2(10, 8), "- - -  ruta planeada", 12, CYAN, true)
    UiDraw.text(self, map.position + Vector2(10, 26), "——  ruta real", 12, DANGER, true)
    # Tres pasos cortos.
    var x: float = map.end.x + 22.0
    var width: float = box.end.x - x - 22.0
    var y: float = map.position.y + 4.0
    var steps: Array = [
        ["1", "La gravedad del sol curva tu ruta", WARNING],
        ["2", "ESTACIÓN: ESPACIO recalcula la ruta y avisa al piloto", CYAN],
        ["3", "PILOTO: corrige con las flechas hasta el círculo verde", OK],
    ]
    for entry: Array in steps:
        var color: Color = entry[2]
        draw_circle(Vector2(x + 16, y + 16), 16.0, Color(color, 0.25))
        UiDraw.text_centered(self, x + 16, y + 4, str(entry[0]), 20, color, true)
        UiDraw.wrapped(self, Vector2(x + 42, y + 2), str(entry[1]), 15, TEXT, width - 42.0)
        y += 86.0
    var pulse: float = 0.6 + 0.4 * sin(_time * 4.0)
    UiDraw.text_centered(self, cx, box.end.y - 42, "ENTER: ¡a volar!", 20, Color(OK, pulse), true)
