class_name WaypointController
extends MovementController
## IA sencilla: va hacia una lista de puntos en orden y se detiene al llegar al último.
## Una lista vacía es un controlador ya terminado (quieto).


signal waypoint_reached(index: int)

const DEFAULT_ARRIVAL_RADIUS: float = 8.0

var arrival_radius: float

var _points: Array[Vector2] = []
var _index: int = 0


func _init(p_points: Array[Vector2], p_arrival_radius: float = DEFAULT_ARRIVAL_RADIUS) -> void:
    _points = p_points.duplicate()
    arrival_radius = maxf(p_arrival_radius, 0.0)


func is_finished() -> bool:
    return _index >= _points.size()


## Con varios puntos dentro del radio los consume todos en la misma llamada, en orden.
func desired_direction(position: Vector2, _delta: float) -> Vector2:
    while not is_finished() and position.distance_to(_points[_index]) <= arrival_radius:
        var reached: int = _index
        _index += 1
        waypoint_reached.emit(reached)
    if is_finished():
        return Vector2.ZERO
    return position.direction_to(_points[_index])
