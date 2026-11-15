class_name Cinematics
extends RefCounted
## Las cinemáticas de la campaña (10 s, renderizadas con Blender en `assets/cinematics/`): de dónde salen sus
## cuadros y qué subtítulos y etiquetas llevan. Muy visuales: solo el texto esencial.
## Subtítulo: [desde_s, hasta_s, texto]. Etiqueta: [desde_s, hasta_s, texto, posición (0..1 de la imagen), color].


enum Id { TO_FOUNDRY, TO_WORKSHOP, SPACE_HAZARDS, ARRIVAL }

const FPS := 12.0
const DATA: Dictionary = {
    Id.TO_FOUNDRY: {
        "dir": "res://assets/cinematics/to_foundry/",
        "frames": 120,
        "subtitles": [
            [0.2, 3.1, "Las menas salen de la mina"],
            [3.3, 5.3, "…y entran al horno"],
            [5.5, 9.8, "El calor deja el metal puro"],
        ],
        "labels": [
            [7.6, 10.0, "Al", Vector2(0.12, 0.8), Color(0.85, 0.88, 0.95)],
            [7.9, 10.0, "Ti", Vector2(0.31, 0.8), Color(0.7, 0.72, 0.85)],
            [8.2, 10.0, "Fe", Vector2(0.5, 0.8), Color(0.9, 0.5, 0.45)],
            [8.6, 10.0, "Ni", Vector2(0.69, 0.8), Color(0.92, 0.88, 0.62)],
            [9.0, 10.0, "Cu", Vector2(0.88, 0.8), Color(1.0, 0.6, 0.35)],
        ],
    },
    Id.TO_WORKSHOP: {
        "dir": "res://assets/cinematics/to_workshop/",
        "frames": 120,
        "subtitles": [
            [0.2, 3.3, "El metal fundido llega al taller"],
            [3.5, 6.6, "Se prensa en piezas"],
            [6.8, 9.8, "Piezas para tu cohete"],
        ],
        "labels": [],
    },
    Id.SPACE_HAZARDS: {
        "dir": "res://assets/cinematics/space_hazards/",
        "frames": 120,
        "subtitles": [
            [0.2, 3.0, "El espacio no está vacío"],
            [3.2, 6.0, "Meteoritos"],
            [6.2, 9.8, "Lo más peligroso: los desvíos de trayectoria"],
        ],
        "labels": [],
    },
    Id.ARRIVAL: {
        "dir": "res://assets/cinematics/arrival/",
        "frames": 120,
        "subtitles": [
            [0.2, 3.4, "¡Llegaron al planeta!"],
            [3.6, 9.8, "Ahora, sus instrumentos lo exploran"],
        ],
        "labels": [],
    },
}


static func frame_path(id: Id, index: int) -> String:
    return String(DATA[id]["dir"]) + "f%03d.png" % (index + 1)


static func frame_count(id: Id) -> int:
    return int(DATA[id]["frames"])


static func duration(id: Id) -> float:
    return float(frame_count(id)) / FPS


static func subtitle_at(id: Id, seconds: float) -> Array:
    for entry: Array in DATA[id]["subtitles"]:
        if seconds >= float(entry[0]) and seconds < float(entry[1]):
            return entry
    return []
