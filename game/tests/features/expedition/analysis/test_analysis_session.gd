extends BaseTest
## Capa 3 (minijuego): la ventana buena da acierto, declarar ausente se juzga contra lo real y todo es reproducible.


var _catalog: Catalog
var _expedition: Expedition
var _luna: PlanetSpec
var _spectrometer: AnalyzerSpec


func before_each() -> void:
    _catalog = Catalog.new()
    _expedition = Expedition.new(_catalog)
    _expedition.add_resource(Catalog.Res.METAL, 300)
    _expedition.assign_engine()
    _expedition.load_instrument("espectroscopio")
    _luna = _catalog.planet("luna")
    _spectrometer = _catalog.analyzer("espectroscopio")


func _new_session() -> AnalysisSession:
    return AnalysisSession.new(_expedition, _luna, _spectrometer)


func _true_index(session: AnalysisSession) -> int:
    for i: int in session.windows.size():
        if session.is_true_window(i):
            return i
    return -1


func _signature(session: AnalysisSession) -> Array:
    var rows: Array = []
    for window: PatternSpec in session.windows:
        rows.append([window.id, window.is_decoy, window.points, window.bands])
    return rows


func test_picking_the_true_window_is_a_hit_and_leaves_the_rack() -> void:
    var session: AnalysisSession = _new_session()
    check_equal(session.pending.size(), _luna.findings("espectroscopio").size() + AnalysisSession.ABSENT_IN_RACK, "el rack mezcla presentes y ausentes")
    session.choose("Fe")
    check_equal(session.windows.size(), AnalysisSession.WINDOW_COUNT, "seis ventanas")
    check_equal(session.pick(_true_index(session)), AnalysisLedger.Outcome.HIT, "elegir la buena es acierto")
    check(_expedition.ledger.discovered("luna", "espectroscopio").has("Fe"), "queda descubierto")
    check(not _new_session().pending.has("Fe"), "lo descubierto sale del rack")


func test_declaring_absent_is_judged_against_what_is_really_there() -> void:
    var session: AnalysisSession = _new_session()
    var absent_id: String = ""
    for pattern_id: String in session.pending:
        if not session.present.has(pattern_id):
            absent_id = pattern_id
    session.choose(absent_id)
    check_equal(_true_index(session), -1, "un ausente no tiene ventana buena")
    check_equal(session.declare_absent(), AnalysisLedger.Outcome.ABSENT_OK, "declararlo ausente es correcto")
    var wrong: AnalysisSession = _new_session()
    wrong.choose("O")
    check_equal(wrong.declare_absent(), AnalysisLedger.Outcome.ABSENT_WRONG, "el oxígeno sí estaba")


func test_filter_never_discards_the_true_window_and_back_costs_nothing() -> void:
    _expedition.load_instrument("filtro")
    var session: AnalysisSession = _new_session()
    session.choose("Ca")
    check_equal(session.discarded.size(), Expedition.FILTER_DISCARDS, "descarta las ventanas que da el filtro")
    check(not session.discarded.has(_true_index(session)), "nunca la buena")
    session.back()
    check_equal(session.step, AnalysisSession.Step.CHOOSE, "volver al rack")
    check_equal(_expedition.ledger.analyses_left("luna", "espectroscopio"), Expedition.BASE_ANALYSES, "sin gasto")


func test_same_expedition_state_gives_the_same_windows() -> void:
    var first: AnalysisSession = _new_session()
    var second: AnalysisSession = _new_session()
    first.choose("Fe")
    second.choose("Fe")
    check_equal(_signature(first), _signature(second), "misma semilla, mismas ventanas y señuelos")
