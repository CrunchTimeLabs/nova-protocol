extends BaseTest
## El equipo fijo del nivel Análisis existe en el catálogo, cabe en la bodega del motor básico y deja todos sus analizadores a bordo.


func test_fixed_equipment_fits_and_is_carried() -> void:
    var expedition: Expedition = Expedition.new(Catalog.new())
    for instrument_id: String in AnalysisLevel.EQUIPMENT:
        check(expedition.load_instrument(instrument_id), "%s existe y cabe" % instrument_id)
    check_equal(expedition.carried_analyzers().size(), AnalysisLevel.EQUIPMENT.size(), "todos quedan a bordo como analizadores")
    check(expedition.used_mass() <= expedition.max_mass(), "no pasa la masa máxima del motor")
