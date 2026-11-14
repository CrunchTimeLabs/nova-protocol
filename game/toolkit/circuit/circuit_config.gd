class_name CircuitConfig
extends RefCounted
## Qué circuito generar: el tablero de tuberías más la demanda, la pérdida de cada pieza y el margen.


## Valores de balance por defecto (plan 002: D17 margen 10 %, D19 pérdida 15 %).
const DEFAULT_DEMAND: float = 20.0
const DEFAULT_LOSS_FRACTION: float = 0.15
const DEFAULT_MARGIN: float = 0.1

var pipe: PipeBoardConfig
## Potencia que exige cada consumidor.
var demand: float
## Fracción que pierde cada pieza al atravesarla (configurable; 0 = todas conducen como cable).
var loss_fraction: float
## Holgura de las fuentes sobre el mínimo que exige la solución tallada.
var margin: float
## Si es true, además de girar, el generador intercambia además algunas piezas del tramo correcto (se deshace con `swap_tiles`).
var shuffle_tiles: bool


func _init(
        p_pipe: PipeBoardConfig,
        p_demand: float,
        p_loss_fraction: float,
        p_margin: float,
        p_shuffle_tiles: bool = true,
        ) -> void:
    pipe = p_pipe
    demand = p_demand
    loss_fraction = p_loss_fraction
    margin = p_margin
    shuffle_tiles = p_shuffle_tiles


static func from_pipe(p_pipe: PipeBoardConfig) -> CircuitConfig:
    return CircuitConfig.new(
            p_pipe,
            DEFAULT_DEMAND,
            DEFAULT_LOSS_FRACTION,
            DEFAULT_MARGIN,
            )
