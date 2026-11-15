class_name TemperatureTargets
extends RefCounted
## Generador simple de objetivos: cada TARGET_INTERVAL elige al azar un rango de TARGET_RANGES y lo anuncia con un mensaje.
## El tiempo se avanza desde fuera con tick(delta). Todo el azar usa la semilla.


signal target_announced(low: float, high: float, message: String)

const TARGET_INTERVAL: float = 12.0
## Rangos de temperatura (°C): x = mínimo, y = máximo.
const TARGET_RANGES: Array[Vector2] = [Vector2(150.0, 200.0), Vector2(300.0, 350.0), Vector2(400.0, 450.0)]

var _random: GameRandom
var _elapsed: float = 0.0


func _init(seed_value: int = -1) -> void:
    _random = GameRandom.new(seed_value)


## Anuncia un objetivo ahora y reinicia la espera.
func announce_now() -> void:
    _elapsed = 0.0
    var range_now: Vector2 = _random.pick(TARGET_RANGES) as Vector2
    var message: String = "Lleva la temperatura a %d–%d °C" % [int(range_now.x), int(range_now.y)]
    target_announced.emit(range_now.x, range_now.y, message)


## Acumula tiempo y anuncia un objetivo nuevo cada TARGET_INTERVAL. Un delta no positivo se ignora.
func tick(delta: float) -> void:
    if delta <= 0.0:
        return
    _elapsed += delta
    if _elapsed >= TARGET_INTERVAL:
        announce_now()
