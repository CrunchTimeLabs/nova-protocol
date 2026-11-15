class_name Ores
extends RefCounted
## Las 5 menas de la campaña y el elemento puro que sale de cada una en la fundición: lo más usado en las
## aleaciones de cohetes. Se recogen en el laberinto (nombre de la mena) y se funden (nombre del elemento).


enum Ore { BAUXITE, ILMENITE, HEMATITE, PENTLANDITE, CHALCOPYRITE }

const ORE_NAMES: Dictionary = {
    Ore.BAUXITE: "Bauxita",
    Ore.ILMENITE: "Ilmenita",
    Ore.HEMATITE: "Hematita",
    Ore.PENTLANDITE: "Pentlandita",
    Ore.CHALCOPYRITE: "Calcopirita",
}
const ELEMENTS: Dictionary = {
    Ore.BAUXITE: "Aluminio",
    Ore.ILMENITE: "Titanio",
    Ore.HEMATITE: "Hierro",
    Ore.PENTLANDITE: "Níquel",
    Ore.CHALCOPYRITE: "Cobre",
}
const SYMBOLS: Dictionary = {
    Ore.BAUXITE: "Al",
    Ore.ILMENITE: "Ti",
    Ore.HEMATITE: "Fe",
    Ore.PENTLANDITE: "Ni",
    Ore.CHALCOPYRITE: "Cu",
}
## Punto de fusión del elemento puro (°C).
const MELTING_POINTS: Dictionary = {
    Ore.BAUXITE: 660.0,
    Ore.ILMENITE: 1668.0,
    Ore.HEMATITE: 1538.0,
    Ore.PENTLANDITE: 1455.0,
    Ore.CHALCOPYRITE: 1085.0,
}
const COLORS: Dictionary = {
    Ore.BAUXITE: Color(0.93, 0.55, 0.4),
    Ore.ILMENITE: Color(0.6, 0.56, 0.85),
    Ore.HEMATITE: Color(0.9, 0.3, 0.26),
    Ore.PENTLANDITE: Color(0.9, 0.8, 0.5),
    Ore.CHALCOPYRITE: Color(0.35, 0.85, 0.78),
}
## Peso al aparecer (de cada 100): la hematita es la más común y la ilmenita la más rara.
const WEIGHTS: Dictionary = {
    Ore.HEMATITE: 32,
    Ore.BAUXITE: 26,
    Ore.CHALCOPYRITE: 18,
    Ore.PENTLANDITE: 13,
    Ore.ILMENITE: 11,
}
## Margen de tiempo en el laberinto sobre el camino más corto: lo raro aprieta más.
const SLACK: Dictionary = {
    Ore.HEMATITE: 2.2,
    Ore.BAUXITE: 1.9,
    Ore.CHALCOPYRITE: 1.6,
    Ore.PENTLANDITE: 1.4,
    Ore.ILMENITE: 1.25,
}
const TEXTURE_DIR := "res://assets/ores/"
const TEXTURE_FILES: Dictionary = {
    Ore.BAUXITE: "ore_bauxite.png",
    Ore.ILMENITE: "ore_ilmenite.png",
    Ore.HEMATITE: "ore_hematite.png",
    Ore.PENTLANDITE: "ore_pentlandite.png",
    Ore.CHALCOPYRITE: "ore_chalcopyrite.png",
}

static var _textures: Dictionary = {}


static func all() -> Array[Ore]:
    return [Ore.BAUXITE, Ore.ILMENITE, Ore.HEMATITE, Ore.PENTLANDITE, Ore.CHALCOPYRITE]


static func ore_name(ore: Ore) -> String:
    return String(ORE_NAMES[ore])


static func element(ore: Ore) -> String:
    return String(ELEMENTS[ore])


static func color(ore: Ore) -> Color:
    return COLORS[ore]


static func texture(ore: Ore) -> Texture2D:
    if not _textures.has(ore):
        _textures[ore] = load(TEXTURE_DIR + String(TEXTURE_FILES[ore])) as Texture2D
    return _textures[ore]


## Mena al azar según los pesos (con el azar que se pasa).
static func pick(random: GameRandom) -> Ore:
    var total: int = 0
    for ore: int in WEIGHTS.keys():
        total += int(WEIGHTS[ore])
    var roll: int = random.range_int(1, total)
    for ore: int in WEIGHTS.keys():
        roll -= int(WEIGHTS[ore])
        if roll <= 0:
            return ore as Ore
    return Ore.HEMATITE
