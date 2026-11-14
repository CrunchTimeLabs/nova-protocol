class_name PipeBoardConfig
extends RefCounted
## Qué tablero generar: tamaño, semilla y puntos de conexión. Más fuentes o destinos = más rutas.


var width: int
var height: int
var seed_value: int
var sources: Array[PipeTerminal]
var targets: Array[PipeTerminal]


func _init(
        p_width: int,
        p_height: int,
        p_seed_value: int,
        p_sources: Array[PipeTerminal],
        p_targets: Array[PipeTerminal],
        ) -> void:
    width = p_width
    height = p_height
    seed_value = p_seed_value
    sources = p_sources
    targets = p_targets


## Una sola ruta: fuente en la esquina superior izquierda, destino en la inferior derecha.
static func single_route(p_width: int, p_height: int, p_seed_value: int) -> PipeBoardConfig:
    var sources: Array[PipeTerminal] = [PipeTerminal.new(Vector2i(0, 0), PipeTile.Side.WEST)]
    var targets: Array[PipeTerminal] = [
        PipeTerminal.new(Vector2i(p_width - 1, p_height - 1), PipeTile.Side.EAST),
    ]
    return PipeBoardConfig.new(p_width, p_height, p_seed_value, sources, targets)


## Una fuente y dos destinos (esquinas derechas): las rutas pueden compartir tramo con un TEE.
static func two_targets(p_width: int, p_height: int, p_seed_value: int) -> PipeBoardConfig:
    var config: PipeBoardConfig = single_route(p_width, p_height, p_seed_value)
    config.targets.append(PipeTerminal.new(Vector2i(p_width - 1, 0), PipeTile.Side.EAST))
    return config


## Una fuente y tres destinos: los dos de la esquina derecha y uno en el centro del tablero.
static func center_target(p_width: int, p_height: int, p_seed_value: int) -> PipeBoardConfig:
    var config: PipeBoardConfig = two_targets(p_width, p_height, p_seed_value)
    config.targets.append(PipeTerminal.new(Vector2i(p_width / 2, p_height / 2), PipeTile.Side.EAST))
    return config


## Dos fuentes (esquinas izquierdas) y cuatro destinos: los dos de la esquina derecha y dos dentro del tablero.
static func two_sources_inner_targets(p_width: int, p_height: int, p_seed_value: int) -> PipeBoardConfig:
    var config: PipeBoardConfig = two_targets(p_width, p_height, p_seed_value)
    config.sources.append(PipeTerminal.new(Vector2i(0, p_height - 1), PipeTile.Side.WEST))
    config.targets.append(PipeTerminal.new(Vector2i(p_width / 2, p_height / 4), PipeTile.Side.EAST))
    config.targets.append(PipeTerminal.new(Vector2i(p_width / 2, p_height * 3 / 4), PipeTile.Side.WEST))
    return config
