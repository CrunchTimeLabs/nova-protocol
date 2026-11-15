class_name Campaign
extends RefCounted
## Secuencia de niveles del botón «Start»: cada nivel sabe cuál sigue al terminar. Sin estado: solo el orden.


## Niveles en orden de juego (rutas de `SceneRoutes`).
const SEQUENCE: Array[String] = [
    SceneRoutes.COLLECTION_STAGE,
    SceneRoutes.FOUNDRY_DUO_LEVEL,
    SceneRoutes.SHIP_BUILD_STAGE,
    SceneRoutes.METEOR_MISSION,
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
