class_name RocketParts
extends RefCounted
## Catálogo de piezas del cohete: sección, título simple, imagen y alto en píxeles (pixel art x1, 48 px de ancho).
## Se apilan de arriba abajo en el orden de `Section`, solapando `OVERLAP` píxeles.


enum Section { PAYLOAD, AVIONICS, TANKS, PIPES, PROPULSION }
enum Part { C1, C2, A1, A2, T1, T2, P1, P2, M1, M2, M3 }

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
}
const TITLES: Dictionary = {
    Part.C1: "Satélite", Part.C2: "Cápsula",
    Part.A1: "Computadora", Part.A2: "Antena",
    Part.T1: "Tanques con ventanas", Part.T2: "Tanques con domos",
    Part.P1: "Válvulas", Part.P2: "Esfera",
    Part.M1: "Motor simple", Part.M2: "Motor triple", Part.M3: "Motor engranaje",
}
## Código como en los nombres de `cohetes_completos` (cohete_C1_A1_T1_P1_M1.png).
const CODES: Dictionary = {
    Part.C1: "C1", Part.C2: "C2", Part.A1: "A1", Part.A2: "A2", Part.T1: "T1", Part.T2: "T2",
    Part.P1: "P1", Part.P2: "P2", Part.M1: "M1", Part.M2: "M2", Part.M3: "M3",
}
const SECTION_HEIGHTS: Dictionary = {
    Section.PAYLOAD: 44,
    Section.AVIONICS: 14,
    Section.TANKS: 48,
    Section.PIPES: 16,
    Section.PROPULSION: 40,
}
## Última fila con píxeles de cada motor (x1): ahí empieza la llama.
const NOZZLE_BOTTOM: Dictionary = {Part.M1: 38, Part.M2: 33, Part.M3: 36}
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
