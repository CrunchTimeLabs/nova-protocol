extends BaseTest
## Capa 2 (regla): cada resultado de análisis suma ciencia o falla, gasta un análisis y mueve la nota.


var _expedition: Expedition
var _ledger: AnalysisLedger


func before_each() -> void:
    _expedition = Expedition.new(Catalog.new())
    _expedition.add_resource(Catalog.Res.METAL, 300)
    _expedition.assign_engine()
    _expedition.load_instrument("radiometro")
    _ledger = _expedition.ledger


func test_outcomes_score_spend_quota_and_log() -> void:
    check_equal(_ledger.grade(), AnalysisLedger.Grade.F, "sin hallazgos, F")
    _ledger.record_analysis("luna", "radiometro", "regolito_fino", AnalysisLedger.Outcome.HIT)
    _ledger.record_analysis("luna", "radiometro", "lava_reciente", AnalysisLedger.Outcome.ABSENT_OK)
    _ledger.record_analysis("luna", "radiometro", "costra_sal", AnalysisLedger.Outcome.MISS)
    check_equal(_ledger.science, AnalysisLedger.HIT_SCIENCE + AnalysisLedger.ABSENT_SCIENCE, "acierto y negativo suman ciencia")
    check_equal(_ledger.failures, 1, "el fallo se cuenta")
    check_equal(_ledger.analyses_left("luna", "radiometro"), Expedition.BASE_ANALYSES - 3, "cada análisis gasta uno")
    check_equal(_ledger.coverage("luna"), Vector2i(1, 3), "1 de 3 en la Luna")
    check_equal(_expedition.log_lines.size(), 1, "solo el acierto queda en el diario")
    check_equal(_ledger.grade(), AnalysisLedger.Grade.D, "algo es D")


func test_grade_follows_thresholds_over_what_the_carried_analyzers_can_measure() -> void:
    check_equal(_ledger.total_possible(), 8, "el radiómetro mide 8 cosas entre los dos planetas")
    for row: Array in [["luna", "regolito_fino"], ["luna", "mare_basaltico"], ["luna", "sombra_permanente"], ["marte", "duna_arena"], ["marte", "roca_expuesta"]]:
        _ledger.record_analysis(String(row[0]), "radiometro", String(row[1]), AnalysisLedger.Outcome.HIT)
    check_equal(_ledger.grade(), AnalysisLedger.Grade.A, "5 de 8 es A")
    _ledger.reset()
    check_equal(_ledger.total_discovered(), 0, "reset vacía el libro")
