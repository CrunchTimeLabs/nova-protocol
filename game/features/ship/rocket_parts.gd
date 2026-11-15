class_name RocketParts
extends RefCounted
## Catálogo de piezas del cohete: sección, título simple, imagen y alto en píxeles (pixel art x1, 48 px de ancho).
## Se apilan de arriba abajo en el orden de `Section`, solapando `OVERLAP` píxeles.


enum Section { PAYLOAD, AVIONICS, TANKS, PIPES, PROPULSION }
## Las 11 primeras son los assets originales; C3, A3, T3, P3 y M4 son las variantes avanzadas (desbloqueables).
enum Part { C1, C2, A1, A2, T1, T2, P1, P2, M1, M2, M3, C3, A3, T3, P3, M4 }

const SECTION_TITLES: Dictionary = {
    Section.PAYLOAD: "Carga útil",
    Section.AVIONICS: "Aviónica",
    Section.TANKS: "Tanques",
    Section.PIPES: "Tuberías",
    Section.PROPULSION: "Propulsión",
}
const SECTION_OF: Dictionary = {
    Part.C1: Section.PAYLOAD, Part.C2: Section.PAYLOAD,
    Part.A1: Section.AVIONICS, Part.A2: Section.AVIONICS,
    Part.T1: Section.TANKS, Part.T2: Section.TANKS,
    Part.P1: Section.PIPES, Part.P2: Section.PIPES,
    Part.M1: Section.PROPULSION, Part.M2: Section.PROPULSION, Part.M3: Section.PROPULSION,
    Part.C3: Section.PAYLOAD, Part.A3: Section.AVIONICS, Part.T3: Section.TANKS, Part.P3: Section.PIPES,
    Part.M4: Section.PROPULSION,
}
const TITLES: Dictionary = {
    Part.C1: "Satélite", Part.C2: "Cápsula",
    Part.A1: "Computadora", Part.A2: "Antena",
    Part.T1: "Tanques con ventanas", Part.T2: "Tanques con domos",
    Part.P1: "Válvulas", Part.P2: "Esfera",
    Part.M1: "Motor simple", Part.M2: "Motor triple", Part.M3: "Motor engranaje",
    Part.C3: "Telescopio", Part.A3: "Radar", Part.T3: "Tanques criogénicos", Part.P3: "Tubos de cobre",
    Part.M4: "Motor aerospike",
}
## Código como en los nombres de `cohetes_completos` (cohete_C1_A1_T1_P1_M1.png).
const CODES: Dictionary = {
    Part.C1: "C1", Part.C2: "C2", Part.A1: "A1", Part.A2: "A2", Part.T1: "T1", Part.T2: "T2",
    Part.P1: "P1", Part.P2: "P2", Part.M1: "M1", Part.M2: "M2", Part.M3: "M3",
    Part.C3: "C3", Part.A3: "A3", Part.T3: "T3", Part.P3: "P3", Part.M4: "M4",
}
## Piezas con las que se cuenta sin desbloquear nada: las más simples (y débiles).
const BASE_PARTS: Array[Part] = [Part.C1, Part.A1, Part.T1, Part.P1, Part.M1]
## Orden en que la fundición desbloquea las demás (de la más sencilla a la mejor).
const UNLOCK_ORDER: Array[Part] = [
    Part.M2, Part.T2, Part.C2, Part.P2, Part.A2, Part.M3, Part.T3, Part.P3, Part.A3, Part.C3, Part.M4,
]

## Los 4 aspectos del cohete; cada pieza suma a cada uno.
enum Stat { DURABILITY, THRUST, FUEL, STABILITY }
const STAT_TITLES: Dictionary = {
    Stat.DURABILITY: "Durabilidad",
    Stat.THRUST: "Empuje",
    Stat.FUEL: "Combustible",
    Stat.STABILITY: "Estabilidad",
}
## Aporte de cada pieza a [durabilidad, empuje, combustible, estabilidad]. Las base aportan poco a propósito.
const STATS: Dictionary = {
    Part.C1: [4, 0, 2, 4], Part.C2: [14, 0, 4, 10], Part.C3: [10, 2, 6, 18],
    Part.A1: [2, 0, 1, 4], Part.A2: [5, 0, 3, 14], Part.A3: [6, 2, 4, 22],
    Part.T1: [5, 1, 8, 2], Part.T2: [14, 2, 24, 6], Part.T3: [18, 4, 34, 8],
    Part.P1: [2, 2, 2, 1], Part.P2: [6, 8, 8, 4], Part.P3: [8, 12, 10, 6],
    Part.M1: [3, 8, 0, 2], Part.M2: [6, 26, 0, 8], Part.M3: [8, 34, 0, 6], Part.M4: [10, 44, 4, 12],
}
const SECTION_HEIGHTS: Dictionary = {
    Section.PAYLOAD: 44,
    Section.AVIONICS: 14,
    Section.TANKS: 48,
    Section.PIPES: 16,
    Section.PROPULSION: 40,
}
## Última fila con píxeles de cada motor (x1): ahí empieza la llama.
const NOZZLE_BOTTOM: Dictionary = {Part.M1: 38, Part.M2: 33, Part.M3: 36, Part.M4: 37}
const WIDTH := 48
const OVERLAP := 1
const TEXTURE_DIR := "res://assets/rocket/"
const FLAME_FRAMES: Array[String] = ["flame1.png", "flame2.png", "flame3.png"]


static func sections() -> Array[Section]:
    return [Section.PAYLOAD, Section.AVIONICS, Section.TANKS, Section.PIPES, Section.PROPULSION]


static func parts_of(section: Section) -> Array[Part]:
    var found: Array[Part] = []
    for part: int in SECTION_OF.keys():
        if SECTION_OF[part] == section:
            found.append(part as Part)
    return found


static func section_of(part: Part) -> Section:
    return SECTION_OF[part] as Section


static func texture_path(part: Part) -> String:
    return TEXTURE_DIR + String(CODES[part]).to_lower() + ".png"


## Fila (en píxeles x1) donde empieza cada sección del cohete apilado.
static func section_top(section: Section) -> int:
    var top: int = 0
    for other: Section in sections():
        if other == section:
            return top
        top += int(SECTION_HEIGHTS[other]) - OVERLAP
    return top


## Alto total del cohete apilado (x1).
static func total_height() -> int:
    var last: Section = Section.PROPULSION
    return section_top(last) + int(SECTION_HEIGHTS[last])


static func stats() -> Array[Stat]:
    return [Stat.DURABILITY, Stat.THRUST, Stat.FUEL, Stat.STABILITY]


## Aporte de `part` al aspecto `stat`.
static func stat_of(part: Part, stat: Stat) -> int:
    return int((STATS[part] as Array)[stat])


## El máximo que puede llegar a tener un aspecto (la mejor pieza de cada sección).
static func stat_max(stat: Stat) -> int:
    var total: int = 0
    for section: Section in sections():
        var best: int = 0
        for part: Part in parts_of(section):
            best = maxi(best, stat_of(part, stat))
        total += best
    return total


static func is_base(part: Part) -> bool:
    return BASE_PARTS.has(part)
