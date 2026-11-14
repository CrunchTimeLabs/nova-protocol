extends BaseTest
## Capa 1 (datos): un hallazgo que apunta a un patrón inexistente rompe el análisis; los motores siguen la tabla de metal.


var _catalog: Catalog


func before_each() -> void:
    _catalog = Catalog.new()


func test_every_finding_points_to_an_existing_pattern_and_leaves_decoys() -> void:
    for planet: PlanetSpec in _catalog.planets:
        for spec: AnalyzerSpec in _catalog.analyzers:
            var present: int = planet.findings(spec.id).size()
            check(present > 0, "%s/%s tiene algo que encontrar" % [planet.id, spec.id])
            check(spec.pattern_ids.size() > present, "%s/%s deja patrones ausentes para el rack" % [planet.id, spec.id])
            for finding: PlanetSpec.Finding in planet.findings(spec.id):
                check(spec.pattern(finding.pattern_id) != null, "%s/%s: el patrón %s existe" % [planet.id, spec.id, finding.pattern_id])


func test_engine_follows_metal_thresholds() -> void:
    var table: Array = [[0, "rd1"], [69, "rd1"], [70, "rd2"], [149, "rd2"], [150, "rd3"], [240, "rd4"], [999, "rd4"]]
    for row: Array in table:
        check_equal(_catalog.engine_for(int(row[0])).id, String(row[1]), "motor para %d de metal" % int(row[0]))
