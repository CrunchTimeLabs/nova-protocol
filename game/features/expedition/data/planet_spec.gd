class_name PlanetSpec
extends RefCounted
## Un destino: cómo es el viaje hasta él y qué hay realmente en él, por analizador.


## Una sustancia presente en el planeta, con la cantidad medida y una nota.
class Finding:
    var pattern_id: String
    var amount: String
    var note: String

    func _init(p_pattern_id: String, p_amount: String, p_note: String) -> void:
        pattern_id = p_pattern_id
        amount = p_amount
        note = p_note


var id: String
var name: String
var subtitle: String
var color: Color
var dark_color: Color
var travel_seconds: float
var density: float
var radiation: float
var fuel_cost: int
var summary: String

var _findings: Dictionary = {}     # analizador -> Array[Finding]


func add_finding(analyzer_id: String, finding: Finding) -> void:
    if not _findings.has(analyzer_id):
        var empty: Array[Finding] = []
        _findings[analyzer_id] = empty
    (_findings[analyzer_id] as Array).append(finding)


func findings(analyzer_id: String) -> Array[Finding]:
    var found: Array[Finding] = []
    if _findings.has(analyzer_id):
        found.assign(_findings[analyzer_id] as Array)
    return found


func present_ids(analyzer_id: String) -> Array[String]:
    var ids: Array[String] = []
    for finding: Finding in findings(analyzer_id):
        ids.append(finding.pattern_id)
    return ids


func finding(analyzer_id: String, pattern_id: String) -> Finding:
    for candidate: Finding in findings(analyzer_id):
        if candidate.pattern_id == pattern_id:
            return candidate
    return null
