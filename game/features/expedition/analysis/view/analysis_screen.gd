class_name AnalysisScreen
extends Screen
## Un análisis en órbita, sobre una `AnalysisSession`: elegir el patrón del rack y encontrar su pareja
## entre seis ventanas, o declarar que no está. Termina (`finished`) al pulsar CONTINUAR o al cancelar.


const HEADER := 124.0
const RESULT_TEXT: Dictionary = {
    AnalysisLedger.Outcome.HIT: ["IDENTIFICACIÓN CORRECTA", UiPalette.OK],
    AnalysisLedger.Outcome.ABSENT_OK: ["AUSENCIA CONFIRMADA", UiPalette.BEACON],
    AnalysisLedger.Outcome.ABSENT_WRONG: ["ERROR: SÍ ESTABA PRESENTE", UiPalette.DANGER],
    AnalysisLedger.Outcome.MISS: ["VENTANA EQUIVOCADA", UiPalette.DANGER],
}

var session: AnalysisSession
var was_cancelled: bool = false
var _views: Array[PatternView] = []
var _buttons: Array[Button] = []


func _init(p_session: AnalysisSession) -> void:
    super._init()
    session = p_session


func _ready() -> void:
    _rebuild()


func _rack_rect(index: int) -> Rect2:
    return Rect2(50 + (index % 4) * 296, 200 + (index / 4) * 96, 284, 88)


func _window_rect(index: int) -> Rect2:
    return Rect2(50 + (index % 2) * 600, 268 + (index / 2) * 124, 578, 108)


## Rehace las vistas de patrones y los botones del paso actual.
func _rebuild() -> void:
    for view: PatternView in _views:
        view.queue_free()
    for button: Button in _buttons:
        button.queue_free()
    _views.clear()
    _buttons.clear()
    var spec: AnalyzerSpec = session.analyzer
    var ruler: bool = expedition.has_alignment()
    match session.step:
        AnalysisSession.Step.CHOOSE:
            for i: int in session.pending.size():
                var rect: Rect2 = _rack_rect(i)
                _add_view(PatternView.new(spec.pattern(session.pending[i]), spec, false), Rect2(rect.position + Vector2(12, 46), Vector2(rect.size.x - 24, 34)))
            _buttons.append(make_button("CANCELAR", Rect2(40, size.y - 66, 210, 46), UiPalette.BORDER_DIM, _cancel))
        AnalysisSession.Step.COMPARE, AnalysisSession.Step.DONE:
            var held: PatternSpec = spec.pattern(session.chosen)
            _add_view(PatternView.new(held, spec, ruler), Rect2(50, 168, size.x - 100, 58))
            var marks: PackedFloat32Array = held.positions() if ruler else PackedFloat32Array()
            for i: int in session.windows.size():
                var rect: Rect2 = _window_rect(i)
                var view: PatternView = PatternView.new(session.windows[i], spec, ruler, 1 + i)
                view.marks = marks
                view.dimmed = session.discarded.has(i)
                _add_view(view, Rect2(rect.position + Vector2(42, 8), Vector2(rect.size.x - 54, 92)))
            if session.step == AnalysisSession.Step.COMPARE:
                _buttons.append(make_button("< CAMBIAR PATRÓN", Rect2(40, size.y - 66, 210, 46), UiPalette.BORDER_DIM, _back))
                _buttons.append(make_button("NINGUNA COINCIDE — DECLARAR AUSENTE", Rect2(size.x - 440, size.y - 66, 400, 46), UiPalette.WARNING, _declare_absent))
            else:
                _buttons.append(make_button("CONTINUAR", Rect2(size.x / 2.0 - 150, size.y - 66, 300, 46), UiPalette.OK, done))


func _add_view(view: PatternView, rect: Rect2) -> void:
    view.position = rect.position
    view.size = rect.size
    add_child(view)
    _views.append(view)


func _cancel() -> void:
    was_cancelled = true
    done()


func _back() -> void:
    session.back()
    _rebuild()


func _declare_absent() -> void:
    _resolve(session.declare_absent())


func _resolve(outcome: AnalysisLedger.Outcome) -> void:
    match outcome:
        AnalysisLedger.Outcome.HIT:
            sfx.play(Sfx.Sound.SUCCESS)
            Bursts.burst(self, _window_rect(session.picked).get_center(), UiPalette.glow(UiPalette.OK, 2.2), 50, 320.0, 0.9, 4.0)
        AnalysisLedger.Outcome.ABSENT_OK:
            sfx.play(Sfx.Sound.PICKUP)
        AnalysisLedger.Outcome.ABSENT_WRONG, AnalysisLedger.Outcome.MISS:
            sfx.play(Sfx.Sound.FAILURE)
            shake(6.0)
    _rebuild()


func _gui_input(event: InputEvent) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
        return
    match session.step:
        AnalysisSession.Step.CHOOSE:
            for i: int in session.pending.size():
                if _rack_rect(i).has_point(click.position):
                    sfx.play(Sfx.Sound.SCAN)
                    session.choose(session.pending[i])
                    _rebuild()
                    return
        AnalysisSession.Step.COMPARE:
            for i: int in session.windows.size():
                if _window_rect(i).has_point(click.position) and not session.discarded.has(i):
                    _resolve(session.pick(i))
                    return
        AnalysisSession.Step.DONE:
            pass


func _process(delta: float) -> void:
    update_shake(delta)
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(UiPalette.BACKGROUND, 0.94))
    var mouse: Vector2 = get_local_mouse_position()
    _draw_header()
    match session.step:
        AnalysisSession.Step.CHOOSE:
            _draw_rack(mouse)
        AnalysisSession.Step.COMPARE, AnalysisSession.Step.DONE:
            _draw_windows(mouse)


func _draw_header() -> void:
    var spec: AnalyzerSpec = session.analyzer
    var planet: PlanetSpec = session.planet
    UiPalette.header(self, HEADER)
    UiPalette.text(self, Vector2(30, 12), "%s — %s" % [spec.name.to_upper(), planet.name], UiPalette.TITLE, UiPalette.glow(UiPalette.BORDER, 1.2), true)
    UiPalette.text(self, Vector2(32, 50), "Mide: %s   |   eje: %s   |   rango %d a %d" % [spec.category, spec.axis_label, int(spec.axis_min), int(spec.axis_max)], UiPalette.SMALL, UiPalette.GRAY)
    var done_count: Vector2i = expedition.ledger.coverage(planet.id, spec.id)
    UiPalette.text(self, Vector2(32, 76), "Análisis de este aparato: %d      Identificados: %d/%d" % [expedition.ledger.analyses_left(planet.id, spec.id), done_count.x, done_count.y], UiPalette.SMALL, UiPalette.SCIENCE, true)
    var aids: PackedStringArray = PackedStringArray()
    if expedition.has_alignment():
        aids.append("alineación activa: los trazos blancos marcan dónde debería caer cada pico del patrón")
    if expedition.false_discards() > 0:
        aids.append("filtro activo: dos ventanas falsas descartadas")
    if aids.is_empty():
        UiPalette.text(self, Vector2(32, 100), "sin apoyo: te toca comparar las posiciones a ojo, por el color", UiPalette.TINY, UiPalette.WARNING)
    else:
        UiPalette.text(self, Vector2(32, 100), "  |  ".join(aids), UiPalette.TINY, UiPalette.OK)


func _draw_rack(mouse: Vector2) -> void:
    UiPalette.text(self, Vector2(50, 140), "PASO 1 — elige el patrón de laboratorio que vas a buscar", UiPalette.SUBTITLE, UiPalette.WARNING, true)
    UiPalette.text(self, Vector2(50, 168), "Puede que ese patrón no esté en este planeta: descubrirlo también es el trabajo.", UiPalette.TINY, UiPalette.GRAY)
    for i: int in session.pending.size():
        var rect: Rect2 = _rack_rect(i)
        var pattern: PatternSpec = session.analyzer.pattern(session.pending[i])
        var hover: bool = rect.has_point(mouse)
        UiPalette.card(self, rect, UiPalette.PANEL_ALT if hover else UiPalette.PANEL, UiPalette.glow(UiPalette.BORDER, 1.3) if hover else UiPalette.BORDER_DIM)
        UiPalette.text(self, rect.position + Vector2(12, 8), pattern.name.left(30), UiPalette.SMALL, UiPalette.TEXT, true)
        UiPalette.text(self, rect.position + Vector2(12, 26), pattern.symbol, UiPalette.TINY, UiPalette.GRAY)


func _draw_windows(mouse: Vector2) -> void:
    var held: PatternSpec = session.analyzer.pattern(session.chosen)
    UiPalette.text(self, Vector2(50, 140), "PATRÓN EN MANO: %s  %s" % [held.name, held.symbol], UiPalette.SUBTITLE, UiPalette.OK, true)
    var comparing: bool = session.step == AnalysisSession.Step.COMPARE
    if comparing:
        UiPalette.text(self, Vector2(50, 236), "PASO 2 — las seis ventanas están medidas con el mismo aparato y se parecen a propósito. Solo una cae exactamente donde el patrón.", UiPalette.SMALL, UiPalette.WARNING)
    for i: int in session.windows.size():
        var rect: Rect2 = _window_rect(i)
        var discarded: bool = session.discarded.has(i)
        var hover: bool = comparing and rect.has_point(mouse) and not discarded
        var border: Color = UiPalette.glow(UiPalette.BORDER, 1.3) if hover else UiPalette.BORDER_DIM
        if not comparing and session.is_true_window(i):
            border = UiPalette.glow(UiPalette.OK, 1.6)
        elif not comparing and i == session.picked:
            border = UiPalette.glow(UiPalette.DANGER, 1.6)
        elif discarded:
            border = Color(0.2, 0.2, 0.2)
        UiPalette.card(self, rect, UiPalette.PANEL_ALT if hover else UiPalette.PANEL, border)
        UiPalette.text(self, rect.position + Vector2(14, 40), char(65 + i), UiPalette.SUBTITLE, Color(0.39, 0.39, 0.39) if discarded else UiPalette.TEXT, true)
        if discarded:
            UiPalette.text(self, rect.position + Vector2(4, 64), "DESCART.", UiPalette.TINY - 2, Color(0.42, 0.42, 0.42))
        if not comparing and session.is_true_window(i):
            UiPalette.text(self, rect.position + Vector2(4, 64), "COINCIDE", UiPalette.TINY - 2, UiPalette.OK, true)
    if not comparing:
        var result: Array = RESULT_TEXT[session.outcome]
        UiPalette.text_centered(self, size.x / 2.0, size.y - 118.0, String(result[0]), UiPalette.TITLE, UiPalette.glow(result[1] as Color, 1.4), true)
