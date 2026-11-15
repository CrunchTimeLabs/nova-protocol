class_name DuoLevel
extends RefCounted
## Dificultad de la recolección a dos: laberintos mucho más grandes (todo a la vista, celdas más pequeñas),
## más derrumbes y un mínimo de menas mayor. Usa los mismos niveles que la recolección de uno.


## Columnas x filas por dificultad.
const SIZES: Dictionary = {
    CollectionLevel.Level.EASY: Vector2i(23, 13),
    CollectionLevel.Level.MEDIUM: Vector2i(27, 15),
    CollectionLevel.Level.HARD: Vector2i(33, 17),
}
## Menas que hay que juntar entre los dos para que se abra la rampa.
const MINIMUMS: Dictionary = {
    CollectionLevel.Level.EASY: 12,
    CollectionLevel.Level.MEDIUM: 16,
    CollectionLevel.Level.HARD: 20,
}
const PASSAGES_PER_CAVE_IN: Dictionary = {
    CollectionLevel.Level.EASY: 3,
    CollectionLevel.Level.MEDIUM: 5,
    CollectionLevel.Level.HARD: 8,
}
const CAVE_IN_MAX: Dictionary = {
    CollectionLevel.Level.EASY: 10,
    CollectionLevel.Level.MEDIUM: 16,
    CollectionLevel.Level.HARD: 26,
}
## Espacio de pantalla para el laberinto (debajo del marcador, dejando sitio a las entradas y la rampa).
const BOARD := Rect2(70, 76, 884, 510)
const MAX_CELL := 42.0

var level: CollectionLevel.Level
var size: Vector2i
var cell_size: float
var minimum: int
var passages_per_cave_in: int
var cave_in_max: int
var cave_in_duration: Vector2
var cave_in_window: float = CollectionLevel.CAVE_IN_WINDOW
var cave_in_chance: float = CollectionLevel.CAVE_IN_CHANCE
var front_chance: float = CollectionLevel.FRONT_CHANCE
var big_rocks: int


func _init(p_level: CollectionLevel.Level) -> void:
    level = p_level
    size = SIZES[level]
    cell_size = floorf(minf(MAX_CELL, minf(BOARD.size.x / float(size.x), BOARD.size.y / float(size.y))))
    minimum = MINIMUMS[level]
    passages_per_cave_in = PASSAGES_PER_CAVE_IN[level]
    cave_in_max = CAVE_IN_MAX[level]
    cave_in_duration = CollectionLevel.CAVE_IN_DURATIONS[level]
    big_rocks = CollectionLevel.BIG_ROCKS[level]


func title() -> String:
    return String(CollectionLevel.NAMES[level])


## Esquina del laberinto: centrado en el espacio de pantalla.
func origin() -> Vector2:
    var board_size: Vector2 = Vector2(size) * cell_size
    return BOARD.position + (BOARD.size - board_size) / 2.0
