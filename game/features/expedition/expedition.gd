class_name Expedition
extends RefCounted
## Estado de la expedición y motor de consecuencias. La cadena completa es:
##   metal del laberinto -> motor -> masa disponible -> instrumentos embarcados
##   instrumentos -> qué se puede sobrevivir en vuelo y qué se puede analizar en órbita.
## Nada está fijado a mano: todo lo derivado se calcula de lo recogido y lo cargado.
## Lo que se analiza en cada planeta vive en `ledger`; la bodega es un `CargoHold` del toolkit.


const HULL_SPARE_BONUS := 35
const BASE_PHASE := 120.0
const EXTRA_CELLS_PHASE := 60.0
const PHASE_DRAIN := 34.0
const REGULATED_PHASE_DRAIN := 24.0
## Velocidad en píxeles por segundo: 3.6 px por fotograma a 60 FPS, más 3.2 por punto de empuje extra.
const BASE_SPEED := 216.0
const SPEED_PER_THRUST := 192.0
const PHASE_BOOST := 1.8
const SHIELD_MITIGATION := 0.5
const MAGNET_RADIUS := 75.0
const HOLD_PICKUP_FACTOR := 2
const BASE_ANALYSES := 4
const DRILL_ANALYSES := 3
const FILTER_DISCARDS := 2
const LOG_LIMIT := 60

var catalog: Catalog
var resources: Dictionary = {}     # Catalog.Res -> int
var engine: EngineSpec
var cargo: CargoHold = CargoHold.new()
var ledger: AnalysisLedger
## Integridad y carga de fase de la nave: se rellenan en prepare_ship().
var hull: ResourceMeter = ResourceMeter.new(1.0, 0.0)
var phase: ResourceMeter = ResourceMeter.new(1.0, 0.0)

var planet_index: int = 0
var perfect_veins: int = 0
var veins_taken: int = 0
var orbs_taken: int = 0
var damage_radiation: float = 0.0
var damage_rocks: int = 0
var damage_laser: int = 0
var log_lines: Array[String] = []


func _init(p_catalog: Catalog) -> void:
    catalog = p_catalog
    ledger = AnalysisLedger.new(catalog, carried_analyzers, analyses_per_instrument)
    ledger.finding_logged.connect(add_log)
    reset()


func reset() -> void:
    resources = {Catalog.Res.METAL: 0, Catalog.Res.CRYSTAL: 0, Catalog.Res.FUEL: 0}
    engine = catalog.engines[0]
    cargo.clear()
    cargo.set_capacity(engine.max_mass)
    hull = ResourceMeter.new(1.0, 0.0)
    phase = ResourceMeter.new(1.0, 0.0)
    planet_index = 0
    perfect_veins = 0
    veins_taken = 0
    orbs_taken = 0
    damage_radiation = 0.0
    damage_rocks = 0
    damage_laser = 0
    log_lines.clear()
    ledger.reset()


# ------------------------------------------------------------------ laberinto

func amount(res: Catalog.Res) -> int:
    return int(resources[res])


func add_resource(res: Catalog.Res, quantity: int) -> void:
    resources[res] = amount(res) + quantity


func assign_engine() -> EngineSpec:
    engine = catalog.engine_for(amount(Catalog.Res.METAL))
    cargo.set_capacity(engine.max_mass)
    return engine


# ------------------------------------------------------------------ bodega

func max_mass() -> int:
    return cargo.capacity


func used_mass() -> int:
    return cargo.used()


func free_mass() -> int:
    return cargo.free_capacity()


func has(instrument_id: String) -> bool:
    return cargo.has(instrument_id)


func can_load(instrument_id: String) -> bool:
    var item: InstrumentSpec = catalog.instrument(instrument_id)
    return item != null and cargo.can_add(instrument_id, item.mass)


func load_instrument(instrument_id: String) -> bool:
    return can_load(instrument_id) and cargo.add(instrument_id, catalog.instrument(instrument_id).mass)


func unload_instrument(instrument_id: String) -> bool:
    return cargo.remove(instrument_id)


# ------------------------------------------------------------------ nave en vuelo

func max_hull() -> int:
    return engine.hull + (HULL_SPARE_BONUS if has("casco") else 0)


## Carga de fase: se rellena al empezar cada tramo y nada más.
func max_phase() -> float:
    return BASE_PHASE + (EXTRA_CELLS_PHASE if has("celdas") else 0.0)


func phase_drain() -> float:
    return REGULATED_PHASE_DRAIN if has("panel") else PHASE_DRAIN


## Segundos totales de intangibilidad por tramo.
func phase_seconds() -> float:
    return max_phase() / phase_drain()


func speed() -> float:
    return BASE_SPEED + SPEED_PER_THRUST * (engine.thrust - 1.0)


func radiation_mitigation() -> float:
    return SHIELD_MITIGATION if has("blindaje") else 0.0


func magnet_radius() -> float:
    return MAGNET_RADIUS if has("iman") else 0.0


func pickup_factor() -> int:
    return HOLD_PICKUP_FACTOR if has("bodega") else 1


func prepare_ship() -> void:
    hull = ResourceMeter.new(float(max_hull()), float(max_hull()))
    phase = ResourceMeter.new(max_phase(), max_phase())


func damage(quantity: float) -> void:
    hull.add(-quantity)


func is_destroyed() -> bool:
    return hull.current <= 0.0


# ------------------------------------------------------------------ analizadores

## Los analizadores embarcados, en el orden del catálogo.
func carried_analyzers() -> Array[AnalyzerSpec]:
    var carried: Array[AnalyzerSpec] = []
    for spec: AnalyzerSpec in catalog.analyzers:
        if has(spec.id):
            carried.append(spec)
    return carried


## Cada analizador trae sus propios análisis por planeta, no un bote común.
func analyses_per_instrument() -> int:
    return BASE_ANALYSES + (DRILL_ANALYSES if has("taladro") else 0)


func false_discards() -> int:
    return FILTER_DISCARDS if has("filtro") else 0


## La computadora numera el eje y marca dónde deberían caer los picos del patrón.
func has_alignment() -> bool:
    return has("computadora")


func has_full_report() -> bool:
    return has("antena")


# ------------------------------------------------------------------ viaje

func planet() -> PlanetSpec:
    return catalog.planets[planet_index]


func next_planet() -> PlanetSpec:
    if planet_index + 1 < catalog.planets.size():
        return catalog.planets[planet_index + 1]
    return null


## Motivo por el que no se puede saltar al siguiente planeta; cadena vacía si se puede.
func travel_block_reason() -> String:
    var next: PlanetSpec = next_planet()
    if next == null:
        return "No hay más destinos en esta campaña."
    if not has("deposito"):
        return "Sin Depósito auxiliar a bordo no hay delta-v para otro tramo."
    var fuel: int = amount(Catalog.Res.FUEL)
    if fuel < next.fuel_cost:
        return "Faltan %d de combustible para el salto (necesitas %d)." % [next.fuel_cost - fuel, next.fuel_cost]
    return ""


func can_travel() -> bool:
    return travel_block_reason() == ""


## Paga el combustible, avanza al siguiente planeta y repone la nave. Solo si can_travel().
func jump_to_next_planet() -> bool:
    if not can_travel():
        push_error("Expedition: salto ilegal (%s)" % travel_block_reason())
        return false
    add_resource(Catalog.Res.FUEL, -next_planet().fuel_cost)
    planet_index += 1
    prepare_ship()
    return true


func add_log(text: String) -> void:
    log_lines.append(text)
    if log_lines.size() > LOG_LIMIT:
        log_lines.pop_front()
