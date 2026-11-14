class_name Catalog
extends RefCounted
## Toda la data del programa de exploración, ya tipada. Se crea una vez en el punto de composición
## y se pasa a quien la necesite. Sin lógica de juego: solo construir y buscar.


enum Res { METAL, CRYSTAL, FUEL }

const RES_NAMES: Dictionary = {
    Res.METAL: "Metal",
    Res.CRYSTAL: "Cristal",
    Res.FUEL: "Combustible",
}

const MAZE_COLS := 21
const MAZE_ROWS := 13
const MAZE_CELL := 46.0
const MAZE_SEED := 90210
const MAZE_BATTERY := 120.0
## Vetas dentro del laberinto: [recurso, cantidad base].
const VEINS: Array = [
    [Res.METAL, 26], [Res.METAL, 22], [Res.METAL, 30], [Res.METAL, 24],
    [Res.METAL, 28], [Res.METAL, 20], [Res.CRYSTAL, 18], [Res.CRYSTAL, 22],
    [Res.CRYSTAL, 16], [Res.FUEL, 20], [Res.FUEL, 24],
]
## La chatarra de acero frente a la entrada: con ella sola ya sale un motor mínimo.
const FIRST_VEIN: Array = [Res.METAL, 34]

var engines: Array[EngineSpec] = []
var analyzers: Array[AnalyzerSpec] = []
var instruments: Array[InstrumentSpec] = []
var planets: Array[PlanetSpec] = []


func _init() -> void:
    _build_engines()
    _build_analyzers()
    _build_instruments()
    _build_planets()


## El mejor motor que se puede fundir con ese metal.
func engine_for(metal: int) -> EngineSpec:
    var chosen: EngineSpec = engines[0]
    for engine: EngineSpec in engines:
        if metal >= engine.threshold:
            chosen = engine
    return chosen


func analyzer(analyzer_id: String) -> AnalyzerSpec:
    for candidate: AnalyzerSpec in analyzers:
        if candidate.id == analyzer_id:
            return candidate
    return null


func instrument(instrument_id: String) -> InstrumentSpec:
    for candidate: InstrumentSpec in instruments:
        if candidate.id == instrument_id:
            return candidate
    return null


func planet(planet_id: String) -> PlanetSpec:
    for candidate: PlanetSpec in planets:
        if candidate.id == planet_id:
            return candidate
    return null


func _build_engines() -> void:
    for raw: Dictionary in MissionData.ENGINES:
        var engine: EngineSpec = EngineSpec.new()
        engine.id = String(raw["id"])
        engine.threshold = int(raw["threshold"])
        engine.name = String(raw["name"])
        engine.max_mass = int(raw["max_mass"])
        engine.thrust = float(raw["thrust"])
        engine.hull = int(raw["hull"])
        engine.description = String(raw["desc"])
        engines.append(engine)


func _build_analyzers() -> void:
    for raw: Dictionary in PatternData.ANALYZERS:
        var spec: AnalyzerSpec = AnalyzerSpec.new()
        spec.id = String(raw["id"])
        spec.name = String(raw["name"])
        spec.mass = int(raw["mass"])
        spec.category = String(raw["category"])
        spec.render = int(raw["render"]) as AnalyzerSpec.Render
        var axis: Array = raw["axis"]
        spec.axis_label = String(axis[0])
        spec.axis_min = float(axis[1])
        spec.axis_max = float(axis[2])
        for tick: Variant in raw["ticks"] as Array:
            spec.ticks.append(float(tick))
        spec.has_compton = bool(raw["compton"])
        spec.description = String(raw["desc"])
        for raw_pattern: Dictionary in raw["patterns"] as Array:
            spec.add_pattern(_build_pattern(raw_pattern))
        analyzers.append(spec)


func _build_pattern(raw: Dictionary) -> PatternSpec:
    var shape: PatternSpec.Shape = PatternSpec.Shape.CURVE
    if raw.has("lines"):
        shape = PatternSpec.Shape.EMISSION
    elif raw.has("bands"):
        shape = PatternSpec.Shape.ABSORPTION
    elif raw.has("peaks"):
        shape = PatternSpec.Shape.PEAKS
    var pattern: PatternSpec = PatternSpec.new(
            String(raw["id"]),
            String(raw["name"]),
            String(raw["symbol"]),
            String(raw["info"]),
            shape,
            )
    for key: String in ["lines", "curve"]:
        for pair: Array in raw.get(key, []) as Array:
            pattern.points.append(Vector2(float(pair[0]), float(pair[1])))
    for key: String in ["bands", "peaks"]:
        for triple: Array in raw.get(key, []) as Array:
            pattern.bands.append(Vector3(float(triple[0]), float(triple[1]), float(triple[2])))
    return pattern


func _build_instruments() -> void:
    for spec: AnalyzerSpec in analyzers:
        instruments.append(InstrumentSpec.new(spec.id, spec.name, spec.mass, InstrumentSpec.Group.ANALYZER, spec.description))
    for raw: Dictionary in MissionData.SUPPORT:
        instruments.append(_build_instrument(raw, InstrumentSpec.Group.SUPPORT))
    for raw: Dictionary in MissionData.SHIP:
        instruments.append(_build_instrument(raw, InstrumentSpec.Group.SHIP))


func _build_instrument(raw: Dictionary, group: InstrumentSpec.Group) -> InstrumentSpec:
    return InstrumentSpec.new(String(raw["id"]), String(raw["name"]), int(raw["mass"]), group, String(raw["desc"]))


func _build_planets() -> void:
    for raw: Dictionary in MissionData.PLANETS:
        var spec: PlanetSpec = PlanetSpec.new()
        spec.id = String(raw["id"])
        spec.name = String(raw["name"])
        spec.subtitle = String(raw["subtitle"])
        spec.color = _color(raw["color"] as Array)
        spec.dark_color = _color(raw["dark"] as Array)
        spec.travel_seconds = float(raw["travel"])
        spec.density = float(raw["density"])
        spec.radiation = float(raw["radiation"])
        spec.fuel_cost = int(raw["fuel"])
        spec.summary = String(raw["summary"])
        var findings: Dictionary = raw["findings"]
        for analyzer_id: String in findings:
            for row: Array in findings[analyzer_id] as Array:
                spec.add_finding(analyzer_id, PlanetSpec.Finding.new(String(row[0]), String(row[1]), String(row[2])))
        planets.append(spec)


func _color(rgb: Array) -> Color:
    var gray: int = int(0.299 * float(rgb[0]) + 0.587 * float(rgb[1]) + 0.114 * float(rgb[2]))
    return Color8(gray, gray, gray)
