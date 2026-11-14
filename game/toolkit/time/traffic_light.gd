class_name TrafficLight
extends RefCounted
## Semáforo de tres luces: rojo -> amarillo -> verde -> rojo, 3 s por luz.
## El tiempo se inyecta desde fuera con tick(delta); no usa Timer, nodos ni get_tree().


signal light_changed(previous: TrafficLight.Light, current: TrafficLight.Light)

enum Light { RED, YELLOW, GREEN }

const DURATION_SECONDS: float = 3.0

const _ORDER: Array[TrafficLight.Light] = [
    Light.RED,
    Light.YELLOW,
    Light.GREEN,
]
const _DURATIONS: Array[float] = [
    DURATION_SECONDS,
    DURATION_SECONDS,
    DURATION_SECONDS,
]

var _cycle: TimedCycle


func _init() -> void:
    _cycle = TimedCycle.new(_DURATIONS)
    _cycle.stepped.connect(_on_stepped)


func current() -> TrafficLight.Light:
    return _ORDER[_cycle.index]


func elapsed() -> float:
    return _cycle.elapsed()


func tick(delta: float) -> void:
    _cycle.tick(delta)


## Vuelve a rojo y borra el tiempo acumulado. Avisa si la luz cambió.
func reset() -> void:
    var previous: TrafficLight.Light = current()
    _cycle.reset()
    var present: TrafficLight.Light = current()
    if present != previous:
        light_changed.emit(previous, present)


func _on_stepped(previous_index: int, current_index: int) -> void:
    light_changed.emit(_ORDER[previous_index], _ORDER[current_index])
