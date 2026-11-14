class_name AnalysisSession
extends RefCounted
## Un análisis con un instrumento: elegir un patrón de laboratorio del rack y buscar su pareja entre
## seis ventanas de medida (la buena si está, otra sustancia real y señuelos). También se puede
## declarar que no está. Siempre gasta un análisis de ese instrumento al resolverse.


enum Step { CHOOSE, COMPARE, DONE }

const WINDOW_COUNT := 6
## Patrones ausentes que se mezclan en el rack con los presentes.
const ABSENT_IN_RACK := 3
const SEED := 8802

var analyzer: AnalyzerSpec
var planet: PlanetSpec
var step: Step = Step.CHOOSE
var pending: Array[String] = []
var present: Array[String] = []
var chosen: String = ""
var windows: Array[PatternSpec] = []
var discarded: Array[int] = []
var picked: int = -1
var outcome: AnalysisLedger.Outcome = AnalysisLedger.Outcome.MISS

var _expedition: Expedition
var _rng: GameRandom


func _init(expedition: Expedition, p_planet: PlanetSpec, p_analyzer: AnalyzerSpec) -> void:
    _expedition = expedition
    planet = p_planet
    analyzer = p_analyzer
    var spent: int = expedition.ledger.analyses_spent(planet.id, analyzer.id)
    _rng = GameRandom.new(SEED + _letter_sum(analyzer.id) * 71 + planet.id.length() * 701 + spent * 37)
    present = planet.present_ids(analyzer.id)
    _build_rack()


func has_patterns() -> bool:
    return not pending.is_empty()


func _build_rack() -> void:
    var absent: Array[String] = []
    for pattern_id: String in analyzer.pattern_ids:
        if not present.has(pattern_id):
            absent.append(pattern_id)
    _rng.shuffle(absent)
    var done: Array[String] = []
    done.append_array(_expedition.ledger.discovered(planet.id, analyzer.id))
    done.append_array(_expedition.ledger.ruled_out(planet.id, analyzer.id))
    var rack: Array[String] = present.duplicate()
    rack.append_array(absent.slice(0, ABSENT_IN_RACK))
    for pattern_id: String in rack:
        if not done.has(pattern_id):
            pending.append(pattern_id)
    pending.sort_custom(func(a: String, b: String) -> bool: return analyzer.pattern(a).name < analyzer.pattern(b).name)


## Paso 1: elegir el patrón que se va a buscar. Construye las seis ventanas.
func choose(pattern_id: String) -> void:
    if step != Step.CHOOSE or not pending.has(pattern_id):
        push_error("AnalysisSession: no se puede elegir %s ahora" % pattern_id)
        return
    chosen = pattern_id
    windows = _build_windows(pattern_id)
    discarded.clear()
    var fakes: Array[int] = []
    for i: int in windows.size():
        if not is_true_window(i):
            fakes.append(i)
    _rng.shuffle(fakes)
    discarded.assign(fakes.slice(0, _expedition.false_discards()))
    step = Step.COMPARE


## Vuelve al rack sin gastar el análisis.
func back() -> void:
    if step == Step.COMPARE:
        step = Step.CHOOSE
        chosen = ""


func is_true_window(index: int) -> bool:
    var window: PatternSpec = windows[index]
    return not window.is_decoy and window.id == chosen


## Paso 2: elegir una ventana. Devuelve el resultado y lo apunta en la expedición.
func pick(index: int) -> AnalysisLedger.Outcome:
    if step != Step.COMPARE or discarded.has(index) or index < 0 or index >= windows.size():
        push_error("AnalysisSession: ventana %d no elegible" % index)
        return outcome
    picked = index
    return _finish(AnalysisLedger.Outcome.HIT if is_true_window(index) else AnalysisLedger.Outcome.MISS)


## Paso 2 alternativo: ninguna coincide.
func declare_absent() -> AnalysisLedger.Outcome:
    if step != Step.COMPARE:
        push_error("AnalysisSession: no hay patrón elegido")
        return outcome
    return _finish(AnalysisLedger.Outcome.ABSENT_WRONG if present.has(chosen) else AnalysisLedger.Outcome.ABSENT_OK)


func _finish(result: AnalysisLedger.Outcome) -> AnalysisLedger.Outcome:
    outcome = result
    step = Step.DONE
    _expedition.ledger.record_analysis(planet.id, analyzer.id, chosen, outcome)
    return outcome


## La buena (si está), una sustancia real distinta y señuelos hasta seis, barajadas.
func _build_windows(pattern_id: String) -> Array[PatternSpec]:
    var pattern: PatternSpec = analyzer.pattern(pattern_id)
    var built: Array[PatternSpec] = []
    if present.has(pattern_id):
        built.append(pattern)
    var others: Array[String] = []
    for other: String in present:
        if other != pattern_id:
            others.append(other)
    _rng.shuffle(others)
    if not others.is_empty():
        built.append(analyzer.pattern(others[0]))
    while built.size() < WINDOW_COUNT:
        built.append(DecoyFactory.decoy(pattern, analyzer, _rng.range_int(0, 999999)))
    _rng.shuffle(built)
    return built


static func _letter_sum(text: String) -> int:
    var total: int = 0
    for i: int in text.length():
        total += text.unicode_at(i)
    return total
