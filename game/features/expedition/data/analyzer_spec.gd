class_name AnalyzerSpec
extends RefCounted
## Un analizador: qué mide, sobre qué eje y con qué patrones de laboratorio.


enum Render { SPECTRUM, PEAKS, CURVE }

var id: String
var name: String
var mass: int
var category: String
var render: Render
var axis_label: String
var axis_min: float
var axis_max: float
var ticks: PackedFloat32Array
## Continuo Compton de fondo (dosímetro gamma) en vez de línea base plana.
var has_compton: bool
var description: String
## Orden del catálogo.
var pattern_ids: Array[String] = []

var _patterns: Dictionary = {}     # String -> PatternSpec


func add_pattern(pattern: PatternSpec) -> void:
    _patterns[pattern.id] = pattern
    pattern_ids.append(pattern.id)


func pattern(pattern_id: String) -> PatternSpec:
    return _patterns.get(pattern_id) as PatternSpec


func span() -> float:
    return axis_max - axis_min
