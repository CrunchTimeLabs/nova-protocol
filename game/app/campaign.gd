class_name Campaign
extends RefCounted
## Secuencia de niveles del botón «Start»: cada nivel sabe cuál sigue al terminar. Sin estado: solo el orden.


## Niveles en orden de juego (rutas de `SceneRoutes`).
## Entre niveles van las cinemáticas (10 s, se pueden saltar).
const SEQUENCE: Array[String] = [
    SceneRoutes.COLLECTION_STAGE,
    SceneRoutes.CINE_TO_FOUNDRY,
    SceneRoutes.FOUNDRY_DUO_LEVEL,
    SceneRoutes.CINE_TO_WORKSHOP,
    SceneRoutes.SHIP_BUILD_STAGE,
    SceneRoutes.CINE_SPACE_HAZARDS,
    SceneRoutes.METEOR_MISSION,
    SceneRoutes.CINE_ARRIVAL,
    SceneRoutes.ANALYSIS_LEVEL,
]


static func first() -> String:
    return SEQUENCE[0]


## Ruta a la que se va al terminar `route`; tras el último nivel (o con una ruta ajena) vuelve al menú.
static func next_after(route: String) -> String:
    var index: int = SEQUENCE.find(route)
    if index < 0 or index + 1 >= SEQUENCE.size():
        return SceneRoutes.MENU
    return SEQUENCE[index + 1]
