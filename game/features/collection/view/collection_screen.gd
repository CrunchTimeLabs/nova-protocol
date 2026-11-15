class_name CollectionScreen
extends Control
## Pantalla de la recolección: laberinto a la izquierda; columna lateral con el almacén y la tarjeta del
## tutorial (que acompaña sin pausar). Lee la sesión, le pasa la entrada y suena; no decide reglas.


signal restart_requested
signal exit_requested

const BACKGROUND := Color(0.035, 0.035, 0.045)
const TOP_BAR := 56.0
const SIDEBAR_WIDTH := 228.0
const SIDEBAR_MARGIN := 12.0
const STORE_HEIGHT := 200.0
const STORE_ROW := 27.0
const TEXT := Color(0.92, 0.92, 0.9)
const HINT := Color(0.58, 0.58, 0.6)
const ACCENT := Color(0.95, 0.74, 0.18)
const NOTICE_LIFE := 1.1
const NOTICE_RISE := 36.0
const SHAKE_TIME := 0.35
const SHAKE_STRENGTH := 5.0
const TURN_RATE := 14.0
const DUST := Color(0.55, 0.47, 0.38, 0.6)
const STORE_FLASH_TIME := 0.5
## Hueco del laberinto a la izquierda de la columna lateral (deja sitio a la salida del cochecito y la rampa).
const BOARD_AREA := Rect2(85, TOP_BAR, 605, 584)
## Celda con la que se dibujó el cochecito a tamaño 1.
const REFERENCE_CELL := 42.0
## Temblor máximo mientras cruzan las rocas grandes.
const RAIN_SHAKE := 9.0
## Un derrumbe que tapa varios pasos a la vez trae una sola lluvia.
const RAIN_COOLDOWN := 0.5

var _session: CollectionSession
var _sfx: CollectionSfx
var _card: TutorialCard
var _rain: RockRain
var _fx: CollectionFx = CollectionFx.new()
var _look: CollectionDraw.Look = CollectionDraw.Look.new()
var _time: float = 0.0
var _notices: Array[Dictionary] = []      # {text, where, color, age}
var _shake: float = 0.0
## Caídas de rocas pendientes de llegar al suelo: [segundos que faltan, punto].
var _impacts: Array[Array] = []
var _store_flash: Dictionary = {}         # Mineral -> segundos
var _last_rain: float = -INF


func _init(session: CollectionSession) -> void:
    _session = session


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _sfx = CollectionSfx.new()
    add_child(_sfx)
    _card = TutorialCard.new(_session, _sfx)
    _card.size = Vector2(SIDEBAR_WIDTH, 0)
    add_child(_card)
    _rain = RockRain.new()
    add_child(_rain)
    _look.car_scale = _session.run.cell_size / REFERENCE_CELL
    _session.run.collected.connect(_on_collected)
    _session.run.mineral_lost.connect(_on_mineral_lost)
    _session.run.cave_in_started.connect(_on_cave_in_started)
    _session.lesson_changed.connect(_on_lesson_changed)
    _session.lesson_step_completed.connect(_on_step_completed)
    _session.phase_changed.connect(_on_phase_changed)
    resized.connect(_layout)
    _layout()
    _on_lesson_changed()


func _layout() -> void:
    var top: float = TOP_BAR + SIDEBAR_MARGIN + STORE_HEIGHT + SIDEBAR_MARGIN
    _card.position = Vector2(size.x - SIDEBAR_WIDTH - SIDEBAR_MARGIN, top)
    _card.size = Vector2(SIDEBAR_WIDTH, size.y - top - SIDEBAR_MARGIN)


func _process(delta: float) -> void:
    _time += delta
    _shake = maxf(0.0, _shake - delta)
    var before: Vector2 = _session.run.car
    _session.tick(delta, move_input())
    var moved: Vector2 = _session.run.car - before
    var is_moving: bool = moved.length() > 0.1 and _session.phase() == CollectionSession.Phase.PLAYING
    if is_moving:
        _look.heading = lerp_angle(_look.heading, moved.angle(), minf(1.0, delta * TURN_RATE))
        _fx.trail(_session.run.car - Vector2.from_angle(_look.heading) * 12.0, -moved.normalized(), DUST)
    _sfx.set_engine(is_moving)
    _fx.update(delta)
    _update_impacts(delta)
    for notice: Dictionary in _notices.duplicate():
        notice["age"] = float(notice["age"]) + delta
        if float(notice["age"]) > NOTICE_LIFE:
            _notices.erase(notice)
    for mineral: int in _store_flash.keys():
        _store_flash[mineral] = maxf(0.0, float(_store_flash[mineral]) - delta)
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
            if _session.active_lesson() != null:
                _sfx.play(CollectionSfx.Sound.CLICK)
                _session.skip_step()


## Dónde va el laberinto de un nivel: pegado a la izquierda y centrado en vertical.
static func board_origin(level: CollectionLevel) -> Vector2:
    var height: float = float(level.size.y) * level.cell_size
    return Vector2(BOARD_AREA.position.x, BOARD_AREA.position.y + (BOARD_AREA.size.y - height) / 2.0)


static func move_input() -> Vector2:
    var x: float = float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
    var y: float = float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
    return Vector2(x, y)


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)
    var strength: float = maxf(SHAKE_STRENGTH * (_shake / SHAKE_TIME), RAIN_SHAKE * _rain.intensity())
    var offset: Vector2 = Vector2(sin(_time * 90.0), cos(_time * 70.0)) * strength
    draw_set_transform(offset, 0.0, Vector2.ONE)
    CollectionDraw.board(self, _session.run, _time, _look)
    _fx.draw(self)
    for notice: Dictionary in _notices:
        var age: float = float(notice["age"])
        var color: Color = notice["color"]
        var where: Vector2 = notice["where"]
        UiDraw.text(self, where - Vector2(24, 30 + age * NOTICE_RISE), str(notice["text"]), 16, Color(color, 1.0 - age / NOTICE_LIFE), true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_top_bar()
    _draw_store()
    if _session.phase() == CollectionSession.Phase.FINISHED:
        _draw_end()


func _draw_top_bar() -> void:
    draw_rect(Rect2(0, 0, size.x, TOP_BAR), Color(0.06, 0.06, 0.08))
    draw_line(Vector2(0, TOP_BAR), Vector2(size.x, TOP_BAR), Color(ACCENT, 0.4), 1.0)
    UiDraw.text(self, Vector2(20, 10), "RECOLECCIÓN", 22, ACCENT, true)
    var level: CollectionLevel = _session.run.level
    UiDraw.text(self, Vector2(200, 14), level.title(), 16, LevelSelect.COLORS[level.level], true)
    UiDraw.text(self, Vector2(310, 18), "Flechas/WASD: mover    R: otro laberinto    Esc: dificultad", 13, HINT)


## Almacén con una barra por mineral: cada barra se llena hacia el siguiente múltiplo de su escala.
func _draw_store() -> void:
    var box: Rect2 = Rect2(size.x - SIDEBAR_WIDTH - SIDEBAR_MARGIN, TOP_BAR + SIDEBAR_MARGIN, SIDEBAR_WIDTH, STORE_HEIGHT)
    UiDraw.panel(self, box, Color(0.06, 0.06, 0.08), Color(0.3, 0.3, 0.34))
    UiDraw.text(self, box.position + Vector2(12, 8), "ALMACÉN → FUNDICIÓN", 11, HINT, true)
    var tally: Tally = _session.run.tally
    var y: float = box.position.y + 28.0
    for mineral: int in CollectionRun.MINERAL_NAMES.keys():
        var color: Color = CollectionDraw.mineral_color(mineral as CollectionRun.Mineral)
        var amount: int = tally.count(mineral)
        var flash: float = float(_store_flash.get(mineral, 0.0)) / STORE_FLASH_TIME
        UiDraw.text(self, Vector2(box.position.x + 12, y), String(CollectionRun.MINERAL_NAMES[mineral]), 13, color, true)
        UiDraw.text(self, Vector2(box.end.x - 52, y), "%d" % amount, 13, TEXT.lerp(Color.WHITE, flash), true, HORIZONTAL_ALIGNMENT_RIGHT, 40.0)
        var bar: Rect2 = Rect2(box.position.x + 88, y + 4, box.size.x - 88 - 58, 10)
        var scale: float = float(CollectionRun.MINERAL_VALUE[mineral]) * 10.0
        var ratio: float = fmod(float(amount), scale) / scale if amount > 0 else 0.0
        if amount > 0 and is_zero_approx(ratio):
            ratio = 1.0
        UiDraw.bar(self, bar, ratio, color.lerp(Color.WHITE, flash * 0.6), Color(0.12, 0.12, 0.14), Color(color, 0.6))
        y += STORE_ROW
    UiDraw.text(self, Vector2(box.position.x + 12, box.end.y - 26), "TOTAL", 14, HINT, true)
    UiDraw.text(self, Vector2(box.end.x - 60, box.end.y - 26), "%d" % tally.total(), 16, ACCENT, true, HORIZONTAL_ALIGNMENT_RIGHT, 48.0)


func _draw_end() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
    var box: Rect2 = Rect2(size.x / 2.0 - 250.0, size.y / 2.0 - 170.0, 500, 340)
    UiDraw.panel(self, box, Color(0.06, 0.06, 0.08), ACCENT)
    var center: float = box.get_center().x
    UiDraw.text_centered(self, center, box.position.y + 24, "¡SALIDA!", 30, ACCENT, true)
    var tally: Tally = _session.run.tally
    var y: float = box.position.y + 84
    for mineral: int in CollectionRun.MINERAL_NAMES.keys():
        var color: Color = CollectionDraw.mineral_color(mineral as CollectionRun.Mineral)
        UiDraw.text_centered(self, center, y, "%s: %d" % [CollectionRun.MINERAL_NAMES[mineral], tally.count(mineral)], 18, color, true)
        y += 28.0
    UiDraw.text_centered(self, center, y + 6, "Al almacén para la fundición: %d" % tally.total(), 18, TEXT)
    UiDraw.text_centered(self, center, box.end.y - 34, "R: otro laberinto    Esc: dificultad", 16, HINT, true)


func _update_impacts(delta: float) -> void:
    for impact: Array in _impacts.duplicate():
        impact[0] = float(impact[0]) - delta
        if float(impact[0]) > 0.0:
            continue
        _impacts.erase(impact)
        _shake = SHAKE_TIME
        _sfx.play(CollectionSfx.Sound.CRASH)
        _fx.burst(impact[1] as Vector2, RocksDraw.DUST, 26, 160.0, 0.7, 5.0)


func _on_collected(mineral: CollectionRun.Mineral, amount: int, where: Vector2) -> void:
    var color: Color = CollectionDraw.mineral_color(mineral)
    _notices.append({
        "text": "+%d %s" % [amount, String(CollectionRun.MINERAL_NAMES[mineral]).to_lower()],
        "where": where,
        "color": color,
        "age": 0.0,
    })
    _store_flash[mineral] = STORE_FLASH_TIME
    _fx.burst(where, color, 22, 170.0, 0.6, 3.0)
    match mineral:
        CollectionRun.Mineral.METAL:
            _sfx.play(CollectionSfx.Sound.METAL)
        CollectionRun.Mineral.CRYSTAL:
            _sfx.play(CollectionSfx.Sound.CRYSTAL)


func _on_mineral_lost(mineral: CollectionRun.Mineral, where: Vector2) -> void:
    _fx.burst(where, Color(CollectionDraw.mineral_color(mineral), 0.5), 10, 50.0, 0.5, 3.0)
    _sfx.play(CollectionSfx.Sound.LOST, -6.0)


## Retumba al empezar; el golpe, el polvo y el temblor llegan cuando las rocas tocan el suelo.
func _on_cave_in_started(cave_in: MazeCaveIns.CaveIn) -> void:
    _sfx.play(CollectionSfx.Sound.RUMBLE, -4.0)
    if _time - _last_rain >= RAIN_COOLDOWN:
        _last_rain = _time
        _rain.pour(_session.run.level.big_rocks)
    _impacts.append([_look.fall_time, _session.run.cave_in_rect(cave_in).get_center()])


func _on_lesson_changed() -> void:
    if _session.active_lesson() != null:
        _sfx.play(CollectionSfx.Sound.LESSON, -4.0)


func _on_step_completed(step: TutorialSteps.Step) -> void:
    _card.celebrate(step.title)


func _on_phase_changed(phase: CollectionSession.Phase) -> void:
    match phase:
        CollectionSession.Phase.FINISHED:
            _sfx.set_engine(false)
            _sfx.play(CollectionSfx.Sound.FINISH)
        CollectionSession.Phase.PLAYING:
            pass
