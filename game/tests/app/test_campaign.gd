extends BaseTest
## La secuencia de «Start»: Recolección → Fundición dúo → Nave → Meteoritos → Análisis → menú.


func test_each_level_leads_to_the_next_and_the_last_to_the_menu() -> void:
    var expected: Array[String] = [
        SceneRoutes.COLLECTION_STAGE,
        SceneRoutes.FOUNDRY_DUO_LEVEL,
        SceneRoutes.SHIP_BUILD_STAGE,
        SceneRoutes.METEOR_MISSION,
        SceneRoutes.ANALYSIS_LEVEL,
    ]
    check_equal(Campaign.first(), expected[0], "empieza en Recolección")
    check_equal(Campaign.SEQUENCE, expected, "el orden es el pedido")
    for index: int in range(expected.size() - 1):
        check_equal(Campaign.next_after(expected[index]), expected[index + 1], "cada nivel lleva al siguiente")
    check_equal(Campaign.next_after(SceneRoutes.ANALYSIS_LEVEL), SceneRoutes.MENU, "tras Análisis, menú")
    check_equal(Campaign.next_after("res://otra.tscn"), SceneRoutes.MENU, "una ruta ajena vuelve al menú")
