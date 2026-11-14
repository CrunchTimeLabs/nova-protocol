class_name CircuitMatch
extends MatchRules
## Reglas de la misión del circuito: girar e intercambiar piezas de una PowerGrid. Cada orden la valida el tablero.
## Sin nodos: la vista lee `grid`.


## Giros por orden: más no tiene sentido (4 giros es una vuelta).
const MAX_STEPS: int = 3
const KEY_GRID: String = "grid"

var grid: PowerGrid


func _init(p_grid: PowerGrid) -> void:
    grid = p_grid


## ROTATE_TILE {"x", "y", "steps"} o SWAP_TILES {"ax", "ay", "bx", "by"}. false si no es válido o el tablero lo rechaza.
func apply(_slot: int, command: Command) -> bool:
    match command.kind:
        CircuitCommand.Kind.ROTATE_TILE:
            var cell: Variant = _cell(command.payload, "x", "y")
            var steps: Variant = _number(command.payload.get("steps"))
            if cell == null or steps == null:
                return false
            return grid.board.rotate_tile(cell as Vector2i, clampi(int(steps), -MAX_STEPS, MAX_STEPS))
        CircuitCommand.Kind.SWAP_TILES:
            var first: Variant = _cell(command.payload, "ax", "ay")
            var second: Variant = _cell(command.payload, "bx", "by")
            if first == null or second == null:
                return false
            return grid.board.swap_tiles(first as Vector2i, second as Vector2i)
    return false


func step(_delta: float) -> void:
    pass


func release_slot(_slot: int) -> void:
    pass


func snapshot() -> Dictionary:
    return {KEY_GRID: grid.snapshot()}


func restore(saved: Dictionary) -> void:
    if saved.has(KEY_GRID):
        grid.restore(saved[KEY_GRID] as Dictionary)


## Un número finito del mensaje, o null.
func _number(raw: Variant) -> Variant:
    if (raw is int or raw is float) and is_finite(float(raw)):
        return float(raw)
    return null


func _cell(payload: Dictionary, x_key: String, y_key: String) -> Variant:
    var x: Variant = _number(payload.get(x_key))
    var y: Variant = _number(payload.get(y_key))
    if x == null or y == null:
        return null
    return Vector2i(int(x), int(y))
