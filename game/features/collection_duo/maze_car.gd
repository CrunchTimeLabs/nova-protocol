class_name MazeCar
extends RefCounted
## Un cochecito del laberinto a dos: posición, hacia dónde va y lo que lleva recogido.


## Jugador 1 (izquierda, WASD) y jugador 2 (derecha, IJKL).
var player: int
var position: Vector2
## Dirección de marcha (Maze.N/E/S/W): hacia dónde está su "delante".
var heading_dir: int
var tally: Tally = Tally.new()
## Ya entró al laberinto alguna vez.
var has_entered: bool = false
## Está sobre la rampa de salida.
var is_on_exit: bool = false


func _init(p_player: int, p_position: Vector2, p_heading: int) -> void:
    player = p_player
    position = p_position
    heading_dir = p_heading


func units() -> int:
    var total: int = 0
    for ore: Ores.Ore in Ores.all():
        total += tally.count(ore)
    return total
