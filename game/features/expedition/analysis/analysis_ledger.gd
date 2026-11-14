class_name AnalysisLedger
extends RefCounted
## Libro de análisis de la expedición: qué se identificó o descartó en cada planeta con cada analizador,
## cuántos análisis se gastaron, la ciencia ganada y la nota final. Qué analizadores van a bordo y cuántos
## análisis trae cada uno lo dicen quienes lo crean (`carried`, `quota`); el libro no conoce la nave.


signal finding_logged(text: String)

enum Outcome { HIT, ABSENT_OK, ABSENT_WRONG, MISS }
enum Grade { A_PLUS, A, B, C, D, F }

const HIT_SCIENCE := 100
const ABSENT_SCIENCE := 45
## Fracción mínima de hallazgos para cada nota, de mejor a peor (D = algo, F = nada).
const GRADE_THRESHOLDS: Array = [[0.85, Grade.A_PLUS], [0.6, Grade.A], [0.4, Grade.B], [0.2, Grade.C]]

var science: int = 0
var failures: int = 0

var _catalog: Catalog
var _carried: Callable      # () -> Array[AnalyzerSpec]
var _quota: Callable        # () -> int, análisis por instrumento y planeta
# planeta -> analizador -> Array[String] / int
var _discovered: Dictionary = {}
var _absent: Dictionary = {}
var _spent: Dictionary = {}


func _init(p_catalog: Catalog, carried: Callable, quota: Callable) -> void:
    _catalog = p_catalog
    _carried = carried
    _quota = quota
    reset()


func reset() -> void:
    science = 0
    failures = 0
    _discovered.clear()
    _absent.clear()
    _spent.clear()
    for planet: PlanetSpec in _catalog.planets:
        _discovered[planet.id] = {}
        _absent[planet.id] = {}
        _spent[planet.id] = {}
        for spec: AnalyzerSpec in _catalog.analyzers:
            var found: Array[String] = []
            var ruled_out_ids: Array[String] = []
            (_discovered[planet.id] as Dictionary)[spec.id] = found
            (_absent[planet.id] as Dictionary)[spec.id] = ruled_out_ids
            (_spent[planet.id] as Dictionary)[spec.id] = 0


func analyses_spent(planet_id: String, analyzer_id: String) -> int:
    return int((_spent[planet_id] as Dictionary)[analyzer_id])


func analyses_left(planet_id: String, analyzer_id: String) -> int:
    return maxi(0, int(_quota.call()) - analyses_spent(planet_id, analyzer_id))


func total_analyses_left(planet_id: String) -> int:
    var total: int = 0
    for spec: AnalyzerSpec in _carried_analyzers():
        total += analyses_left(planet_id, spec.id)
    return total


func discovered(planet_id: String, analyzer_id: String) -> Array[String]:
    return (_discovered[planet_id] as Dictionary)[analyzer_id]


func ruled_out(planet_id: String, analyzer_id: String) -> Array[String]:
    return (_absent[planet_id] as Dictionary)[analyzer_id]


## Aplica el resultado de un análisis: siempre gasta uno de ese instrumento.
func record_analysis(planet_id: String, analyzer_id: String, pattern_id: String, outcome: Outcome) -> void:
    var spent: Dictionary = _spent[planet_id]
    spent[analyzer_id] = int(spent[analyzer_id]) + 1
    var spec: AnalyzerSpec = _catalog.analyzer(analyzer_id)
    match outcome:
        Outcome.HIT:
            discovered(planet_id, analyzer_id).append(pattern_id)
            science += HIT_SCIENCE
            finding_logged.emit("%s: %s — %s." % [_catalog.planet(planet_id).name, spec.category, spec.pattern(pattern_id).name])
        Outcome.ABSENT_OK:
            ruled_out(planet_id, analyzer_id).append(pattern_id)
            science += ABSENT_SCIENCE
        Outcome.ABSENT_WRONG, Outcome.MISS:
            failures += 1


## (identificados, posibles) en un planeta, con un analizador o con todos los embarcados.
func coverage(planet_id: String, analyzer_id: String = "") -> Vector2i:
    var planet: PlanetSpec = _catalog.planet(planet_id)
    if analyzer_id != "":
        return Vector2i(discovered(planet_id, analyzer_id).size(), planet.findings(analyzer_id).size())
    var result: Vector2i = Vector2i.ZERO
    for spec: AnalyzerSpec in _carried_analyzers():
        result += Vector2i(discovered(planet_id, spec.id).size(), planet.findings(spec.id).size())
    return result


func total_discovered() -> int:
    var total: int = 0
    for planet: PlanetSpec in _catalog.planets:
        for spec: AnalyzerSpec in _catalog.analyzers:
            total += discovered(planet.id, spec.id).size()
    return total


## Solo cuenta lo que los analizadores embarcados podrían medir.
func total_possible() -> int:
    var total: int = 0
    for planet: PlanetSpec in _catalog.planets:
        total += coverage(planet.id).y
    return maxi(1, total)


func grade() -> Grade:
    var found: int = total_discovered()
    var fraction: float = float(found) / float(total_possible())
    for row: Array in GRADE_THRESHOLDS:
        if fraction >= float(row[0]):
            return int(row[1]) as Grade
    return Grade.D if found > 0 else Grade.F


func _carried_analyzers() -> Array[AnalyzerSpec]:
    var carried: Array[AnalyzerSpec] = []
    carried.assign(_carried.call() as Array)
    return carried
