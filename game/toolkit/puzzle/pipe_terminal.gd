class_name PipeTerminal
extends RefCounted
## Punto de conexión del tablero: una celda y el lado por el que entra (fuente) o sale (destino) la energía.


var cell: Vector2i
var side: PipeTile.Side


func _init(p_cell: Vector2i, p_side: PipeTile.Side) -> void:
    cell = p_cell
    side = p_side


func snapshot() -> Dictionary:
    return {"x": cell.x, "y": cell.y, "side": PipeTile.Side.keys()[side]}


static func from_snapshot(saved: Dictionary) -> PipeTerminal:
    var side_name: String = str(saved["side"])
    return PipeTerminal.new(
            Vector2i(int(saved["x"]), int(saved["y"])),
            PipeTile.Side[side_name] as PipeTile.Side,
            )
