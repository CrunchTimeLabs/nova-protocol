class_name CollectionLevel
extends RefCounted
## Dificultad de la recolección: cambian el tamaño del laberinto y los bloqueos (cuántos pasos tapa cada
## derrumbe, cuánto duran y cuántos puede haber a la vez).
## El ritmo es igual en todos: cada 15 s de juego, 95 % de que caiga un derrumbe en un momento al azar.
## También igual: minerales y 30 % delante del cochecito.


enum Level { EASY, MEDIUM, HARD }

const NAMES: Dictionary = {Level.EASY: "FÁCIL", Level.MEDIUM: "MEDIO", Level.HARD: "DIFÍCIL"}
const SIZES: Dictionary = {Level.EASY: Vector2i(13, 11), Level.MEDIUM: Vector2i(15, 13), Level.HARD: Vector2i(18, 15)}
## El laberinto ocupa siempre el mismo espacio en pantalla: celdas más pequeñas cuanto más grande.
const CELLS: Dictionary = {Level.EASY: 46.0, Level.MEDIUM: 40.0, Level.HARD: 33.0}
## Pasos que tapa cada derrumbe.
const PASSAGES_PER_CAVE_IN: Dictionary = {Level.EASY: 2, Level.MEDIUM: 4, Level.HARD: 6}
## Cuánto dura tapado cada paso (s): se acumulan de un derrumbe al siguiente.
const CAVE_IN_DURATIONS: Dictionary = {
    Level.EASY: Vector2(8.0, 14.0),
    Level.MEDIUM: Vector2(10.0, 18.0),
    Level.HARD: Vector2(12.0, 22.0),
}
## Pasos tapados a la vez como máximo.
const CAVE_IN_MAX: Dictionary = {Level.EASY: 6, Level.MEDIUM: 12, Level.HARD: 20}
## Cada tantos segundos de juego, esta probabilidad de que caiga un derrumbe (en un momento al azar).
const CAVE_IN_WINDOW := 15.0
const CAVE_IN_CHANCE := 0.95
## Rocas grandes de adorno (lluvia en pantalla) por derrumbe.
const BIG_ROCKS: Dictionary = {Level.EASY: 3, Level.MEDIUM: 5, Level.HARD: 8}
## Probabilidad de que un derrumbe caiga justo delante del cochecito (todos los niveles).
const FRONT_CHANCE := 0.3

var level: Level
var size: Vector2i
var cell_size: float
var cave_in_window: float = CAVE_IN_WINDOW
var cave_in_chance: float = CAVE_IN_CHANCE
var cave_in_duration: Vector2
var passages_per_cave_in: int
var cave_in_max: int
var front_chance: float = FRONT_CHANCE
var big_rocks: int


func _init(p_level: Level) -> void:
    level = p_level
    size = SIZES[level]
    cell_size = CELLS[level]
    passages_per_cave_in = PASSAGES_PER_CAVE_IN[level]
    cave_in_duration = CAVE_IN_DURATIONS[level]
    cave_in_max = CAVE_IN_MAX[level]
    big_rocks = BIG_ROCKS[level]


func title() -> String:
    return String(NAMES[level])


## Un nivel a medida (la demo del tutorial usa un laberinto pequeño).
static func custom(p_size: Vector2i, p_cell_size: float) -> CollectionLevel:
    var custom_level: CollectionLevel = CollectionLevel.new(Level.EASY)
    custom_level.size = p_size
    custom_level.cell_size = p_cell_size
    return custom_level
