class_name OrbitScreen
extends Screen
## Nivel 3: en órbita. Una tarjeta por analizador embarcado; cada una abre un `AnalysisScreen` encima
## y, al acabar, la pantalla de resultado. CONTINUAR MISIÓN termina la órbita.


const HEADER := 118.0
const PLANET_CENTER := Vector2(330, 372)
const PLANET_RADIUS := 178.0
const LOG_BOX := Rect2(30, 570, 620, 160)

var planet: PlanetSpec
var _planet_view: PlanetView
var _overlay: Screen
var _continue: Button
var _time: float = 0.0


func _init(p_planet: PlanetSpec) -> void:
    super._init()
    planet = p_planet


func _ready() -> void:
    stars.velocity = Vector2(6, 0)
    _planet_view = PlanetView.new(planet.color, planet.dark_color, planet.id.hash())
    _planet_view.place(PLANET_CENTER, PLANET_RADIUS)
    add_child(_planet_view)
    _continue = make_button("CONTINUAR MISIÓN", Rect2(size.x - 330, size.y - 66, 290, 48), UiPalette.OK, done)


func _card_rect(index: int) -> Rect2:
    return Rect2(690, 142 + index * 80, 560, 70)


func _process(delta: float) -> void:
    _time += delta
    update_notices(delta)
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if _overlay == null and key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
        done()


func _gui_input(event: InputEvent) -> void:
    var click: InputEventMouseButton = event as InputEventMouseButton
    if _overlay != null or click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
        return
    var carried: Array[AnalyzerSpec] = expedition.carried_analyzers()
    for i: int in carried.size():
        if _card_rect(i).has_point(click.position) and expedition.ledger.analyses_left(planet.id, carried[i].id) > 0:
            _open_analysis(carried[i])
            return


func _open_analysis(spec: AnalyzerSpec) -> void:
    var session: AnalysisSession = AnalysisSession.new(expedition, planet, spec)
    if not session.has_patterns():
        notify("Ya no quedan patrones por resolver con este aparato", UiPalette.WARNING, 1.6)
        sfx.play(Sfx.Sound.DENIED)
        return
    sfx.play(Sfx.Sound.SCAN)
    var screen: AnalysisScreen = AnalysisScreen.new(session)
    screen.finished.connect(_on_analysis_finished.bind(screen))
    _push(screen)


func _on_analysis_finished(screen: AnalysisScreen) -> void:
    _pop()
    if screen.was_cancelled:
        return
    var result: InfoScreen = _result_screen(screen.session)
    result.finished.connect(_pop)
    _push(result)
    if screen.session.outcome == AnalysisLedger.Outcome.HIT:
        var view: PatternView = PatternView.new(screen.session.analyzer.pattern(screen.session.chosen), screen.session.analyzer, true)
        view.position = Vector2(InfoScreen.BOX_MARGIN_X + 50.0, 492.0)
        view.size = Vector2(size.x - 2.0 * InfoScreen.BOX_MARGIN_X - 100.0, 62.0)
        result.add_child(view)


func _push(screen: Screen) -> void:
    _overlay = screen
    screen.setup(sfx, stars, expedition)
    add_child(screen)
    _planet_view.visible = false
    _continue.visible = false


func _pop() -> void:
    if _overlay != null:
        _overlay.queue_free()
        _overlay = null
    _planet_view.visible = true
    _continue.visible = true


func _result_screen(session: AnalysisSession) -> InfoScreen:
    var spec: AnalyzerSpec = session.analyzer
    var pattern: PatternSpec = spec.pattern(session.chosen)
    match session.outcome:
        AnalysisLedger.Outcome.HIT:
            var finding: PlanetSpec.Finding = planet.finding(spec.id, pattern.id)
            var lines: Array[String] = [
                "%s — medida en %s: %s." % [spec.category, planet.name.to_lower(), finding.amount],
                finding.note,
                pattern.info if expedition.has_full_report() else "Sin Antena de alta ganancia solo baja el resumen: el informe científico completo se queda en el buffer.",
            ]
            return InfoScreen.new().configure(pattern.name, "%s — %s" % [spec.name, planet.name], lines, "ANOTAR EN LA BITÁCORA", UiPalette.SCIENCE).with_extra(
                    func(canvas: Control, box: Rect2, _top: float) -> void:
                        UiPalette.text(canvas, Vector2(box.position.x + 50, 560), "patrón de referencia sobre el eje de %s" % spec.axis_label, UiPalette.TINY, UiPalette.GRAY)
            )
        AnalysisLedger.Outcome.ABSENT_OK:
            var lines: Array[String] = [
                "Un negativo bien medido también es ciencia: acabas de acotar la composición del planeta descartando un candidato.",
                "+%d puntos de ciencia." % AnalysisLedger.ABSENT_SCIENCE,
            ]
            return InfoScreen.new().configure("RESULTADO NEGATIVO CONFIRMADO", "%s no aparece en %s" % [pattern.name, planet.name], lines, "CONTINUAR", UiPalette.BEACON)
        AnalysisLedger.Outcome.ABSENT_WRONG:
            var lines: Array[String] = [
                "Declaraste ausente algo que sí aparece en las ventanas. El análisis se pierde y sigue sin identificar.",
                "Repasa pico por pico: los señuelos están corridos muy poco, y a veces solo uno de ellos está fuera de sitio.",
            ]
            return InfoScreen.new().configure("DECLARACIÓN ERRÓNEA", "%s SÍ estaba en la muestra" % pattern.name, lines, "CONTINUAR", UiPalette.DANGER)
        AnalysisLedger.Outcome.MISS:
            var lines: Array[String] = [
                "La correlación no cuadra: el análisis se pierde.",
                "Las seis ventanas están hechas a propósito para parecerse. No cuentes cuántos picos hay, mira DÓNDE cae cada uno: un pico corrido cambia de color antes que de forma.",
                "La Computadora de alineación marca con trazos blancos la posición exacta del patrón sobre cada ventana.",
            ]
            return InfoScreen.new().configure("VENTANA EQUIVOCADA", spec.name, lines, "CONTINUAR", UiPalette.DANGER)
    return InfoScreen.new()


func _draw() -> void:
    if _overlay != null:
        draw_rect(Rect2(Vector2.ZERO, size), Color(UiPalette.BACKGROUND, 0.75))
        return
    var mouse: Vector2 = get_local_mouse_position()
    _draw_orbiter()
    UiPalette.header(self, HEADER)
    var title_color: Color = UiPalette.glow(planet.color.lightened(0.25), 1.2)
    UiPalette.text(self, Vector2(30, 12), "ÓRBITA DE %s" % planet.name, UiPalette.TITLE, title_color, true)
    UiPalette.text(self, Vector2(32, 48), planet.subtitle, UiPalette.SMALL, UiPalette.GRAY)
    UiPalette.text(self, Vector2(32, 72), planet.summary.left(120), UiPalette.TINY, UiPalette.GRAY)
    UiPalette.text(self, Vector2(32, 92), "Cada instrumento abre su propio análisis. F11 pantalla completa.", UiPalette.TINY, UiPalette.GRAY)
    var total: Vector2i = expedition.ledger.coverage(planet.id)
    UiPalette.text(self, Vector2(size.x - 360, 16), "IDENTIFICADOS %d/%d" % [total.x, total.y], UiPalette.SUBTITLE, UiPalette.SCIENCE, true)
    UiPalette.bar(self, Rect2(size.x - 360, 42, 320, 16), float(total.x) / float(maxi(1, total.y)), UiPalette.glow(UiPalette.SCIENCE, 1.2))
    UiPalette.text(self, Vector2(size.x - 360, 66), "ciencia acumulada: %d pts" % expedition.ledger.science, UiPalette.TINY, UiPalette.GRAY)
    _draw_cards(mouse)
    _draw_log()
    UiPalette.resources_row(self, Vector2(690, 592), expedition.resources, 140.0)
    UiPalette.hull_bar(self, Rect2(690, 650, 240, 16), expedition.hull.current, float(expedition.max_hull()))
    draw_notices(size.y - 130.0)


## La propia nave dando vueltas al planeta, por delante y por detrás.
func _draw_orbiter() -> void:
    var angle: float = _time * 0.6
    var spot: Vector2 = PLANET_CENTER + Vector2(cos(angle) * (PLANET_RADIUS + 40.0), sin(angle) * (PLANET_RADIUS + 40.0) * 0.28)
    draw_arc(PLANET_CENTER, PLANET_RADIUS + 40.0, 0.0, TAU, 96, Color(UiPalette.BORDER, 0.08), 1.0)
    if sin(angle) > 0.0:
        draw_circle(spot, 4.0, UiPalette.glow(UiPalette.BEACON, 2.0))
        draw_circle(spot, 9.0, Color(UiPalette.BEACON, 0.18))


func _draw_cards(mouse: Vector2) -> void:
    var carried: Array[AnalyzerSpec] = expedition.carried_analyzers()
    if carried.is_empty():
        var box: Rect2 = Rect2(690, 142, 560, 180)
        UiPalette.panel(self, box, UiPalette.DANGER)
        UiPalette.wrapped(self, box.position + Vector2(18, 20), "No embarcaste ningún analizador. Desde órbita no puedes medir nada: la misión científica está perdida antes de empezar.", UiPalette.SMALL, UiPalette.DANGER, box.size.x - 36.0)
    for i: int in carried.size():
        var spec: AnalyzerSpec = carried[i]
        var rect: Rect2 = _card_rect(i)
        var left: int = expedition.ledger.analyses_left(planet.id, spec.id)
        var part: Vector2i = expedition.ledger.coverage(planet.id, spec.id)
        var hover: bool = _overlay == null and rect.has_point(mouse) and left > 0
        var tone: Color = UiPalette.instrument_color(spec.id)
        var background: Color = UiPalette.PANEL
        var border: Color = Color(tone, 0.55)
        var color: Color = tone.lightened(0.35)
        if left == 0:
            background = Color(0.09, 0.09, 0.09)
            border = Color(0.3, 0.3, 0.3)
            color = Color(0.51, 0.51, 0.51)
        elif hover:
            background = UiPalette.PANEL_ALT
            border = UiPalette.glow(tone, 1.4)
        UiPalette.card(self, rect, background, border)
        if left > 0:
            draw_rect(Rect2(rect.position, Vector2(6, rect.size.y)), tone)
        UiPalette.text(self, rect.position + Vector2(14, 8), spec.name, UiPalette.SUBTITLE, color, true)
        UiPalette.text(self, rect.position + Vector2(14, 32), "mide %s  —  %s" % [spec.category.to_upper(), spec.axis_label], UiPalette.TINY, UiPalette.GRAY)
        UiPalette.text(self, rect.position + Vector2(14, 50), "identificados %d/%d" % [part.x, part.y], UiPalette.TINY, UiPalette.OK if part.x > 0 else UiPalette.GRAY)
        UiPalette.text(self, Vector2(rect.end.x - 130, rect.position.y + 12), "%d análisis" % left if left > 0 else "agotado", UiPalette.SMALL, tone if left > 0 else UiPalette.DANGER, true)
        UiPalette.bar(self, Rect2(rect.end.x - 132, rect.position.y + 40, 118, 12), float(part.x) / float(maxi(1, part.y)), tone)


func _draw_log() -> void:
    UiPalette.panel(self, LOG_BOX, UiPalette.SCIENCE)
    UiPalette.text(self, LOG_BOX.position + Vector2(14, 10), "BITÁCORA DE %s" % planet.name, UiPalette.SUBTITLE, UiPalette.SCIENCE, true)
    draw_line(LOG_BOX.position + Vector2(14, 36), Vector2(LOG_BOX.end.x - 14, LOG_BOX.position.y + 36), UiPalette.BORDER_DIM, 1.0)
    var y: float = LOG_BOX.position.y + 44.0
    var anything: bool = false
    for spec: AnalyzerSpec in expedition.carried_analyzers():
        var ids: Array[String] = expedition.ledger.discovered(planet.id, spec.id)
        if ids.is_empty():
            continue
        anything = true
        var names: PackedStringArray = PackedStringArray()
        for pattern_id: String in ids:
            names.append(spec.pattern(pattern_id).name)
        UiPalette.text(self, Vector2(LOG_BOX.position.x + 14, y), spec.category + ":", UiPalette.TINY, UiPalette.BORDER, true)
        y = UiPalette.wrapped(self, Vector2(LOG_BOX.position.x + 104, y), ", ".join(names), UiPalette.TINY, UiPalette.TEXT, LOG_BOX.size.x - 120.0) + 4.0
        if y > LOG_BOX.end.y - 26.0:
            break
    if not anything:
        UiPalette.wrapped(self, LOG_BOX.position + Vector2(14, 46), "Todavía no sabes nada de este planeta. Pulsa un instrumento de la derecha.", UiPalette.TINY, UiPalette.GRAY, LOG_BOX.size.x - 28.0)
