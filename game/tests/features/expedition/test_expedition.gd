extends BaseTest
## Capa 4 (orquestador): la cadena metal -> motor -> masa -> instrumentos -> nave, y las reglas del salto.


var _catalog: Catalog
var _expedition: Expedition


func before_each() -> void:
    _catalog = Catalog.new()
    _expedition = Expedition.new(_catalog)


func test_metal_decides_engine_and_engine_decides_cargo_capacity() -> void:
    _expedition.add_resource(Catalog.Res.METAL, 80)
    check_equal(_expedition.assign_engine().id, "rd2", "80 de metal funden el RD-2")
    check_equal(_expedition.max_mass(), 180, "el RD-2 sube 180 kg")
    check(_expedition.load_instrument("difractometro"), "cabe un instrumento ligero")
    check(not _expedition.load_instrument("difractometro"), "no se embarca dos veces")
    for item: InstrumentSpec in _catalog.instruments:
        _expedition.load_instrument(item.id)
        check(_expedition.used_mass() <= _expedition.max_mass(), "la carga nunca supera al motor (tras %s)" % item.id)
    check(_expedition.unload_instrument("difractometro"), "se puede descargar lo cargado")
    check(not _expedition.unload_instrument("difractometro"), "no se descarga lo que no está")


func test_instruments_change_ship_and_prepare_ship_fills_meters() -> void:
    _expedition.add_resource(Catalog.Res.METAL, 300)
    _expedition.assign_engine()
    var hull_before: int = _expedition.max_hull()
    for item_id: String in ["casco", "celdas", "panel", "taladro", "filtro"]:
        _expedition.load_instrument(item_id)
    check_equal(_expedition.max_hull(), hull_before + Expedition.HULL_SPARE_BONUS, "el casco suma integridad")
    check_approx(_expedition.phase_seconds(), 180.0 / 24.0, "celdas y regulador alargan la fase")
    check_equal(_expedition.analyses_per_instrument(), Expedition.BASE_ANALYSES + Expedition.DRILL_ANALYSES, "el taladro da análisis extra")
    check_equal(_expedition.false_discards(), Expedition.FILTER_DISCARDS, "el filtro descarta ventanas falsas")
    _expedition.prepare_ship()
    check_approx(_expedition.hull.current, float(_expedition.max_hull()), "la nave sale entera")
    check_approx(_expedition.phase.current, _expedition.max_phase(), "y con la fase llena")
    _expedition.damage(10.0)
    check_approx(_expedition.hull.current, float(_expedition.max_hull()) - 10.0, "el daño baja la integridad")
    _expedition.damage(1000.0)
    check(_expedition.is_destroyed(), "sin integridad la nave está destruida")


func test_jump_needs_tank_and_fuel_and_pays_it() -> void:
    var marte: PlanetSpec = _catalog.planet("marte")
    check(not _expedition.can_travel(), "sin depósito no hay salto")
    _expedition.add_resource(Catalog.Res.METAL, 300)
    _expedition.assign_engine()
    _expedition.load_instrument("deposito")
    _expedition.add_resource(Catalog.Res.FUEL, marte.fuel_cost - 1)
    check(not _expedition.can_travel(), "falta una unidad de combustible")
    check(_expedition.travel_block_reason().contains("Faltan 1"), "el motivo dice cuánto falta")
    _expedition.add_resource(Catalog.Res.FUEL, 1)
    check(_expedition.jump_to_next_planet(), "con depósito y combustible el salto se hace")
    check_equal(_expedition.amount(Catalog.Res.FUEL), 0, "el salto paga el combustible")
    check_equal(_expedition.planet().id, "marte", "ya estamos en el segundo planeta")
    check(not _expedition.can_travel(), "no hay salto desde el último planeta")
