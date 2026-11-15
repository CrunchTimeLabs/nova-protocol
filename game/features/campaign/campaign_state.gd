class_name CampaignState
extends RefCounted
## Lo que la campaña («Start») lleva de un nivel al siguiente. Estático: vive mientras el juego está abierto
## (cambiar de escena no lo borra) y `reset()` lo deja como al pulsar Start.
## - Recolección → Fundición: menas recogidas por tipo.
## - Fundición → Nave: piezas desbloqueadas además de las base.
## - Nave → Meteoritos: piezas del cohete armado (y sus aspectos).


## Menas recogidas por tipo (Ores.Ore -> unidades).
static var ores: Dictionary = {}
## Piezas de cohete ganadas en la fundición (RocketParts.Part), en orden de desbloqueo.
static var unlocked_parts: Array[int] = []
## Pieza por sección del cohete que despegó (RocketParts.Section -> RocketParts.Part); vacío si no hubo.
static var rocket: Dictionary = {}


static func reset() -> void:
    ores = {}
    unlocked_parts = []
    rocket = {}


static func add_ore(ore: Ores.Ore, amount: int = 1) -> void:
    ores[ore] = int(ores.get(ore, 0)) + amount


static func ore_count(ore: Ores.Ore) -> int:
    return int(ores.get(ore, 0))


static func total_ores() -> int:
    var total: int = 0
    for amount: int in ores.values():
        total += amount
    return total
