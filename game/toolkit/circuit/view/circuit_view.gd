class_name CircuitView
extends PipeBoardView
## Dibuja un PowerGrid sobre el tablero de tuberías: el color de cada destino dice si está
## encendido o apagado y sobre él se lee la potencia recibida y la exigida. Solo lee la rejilla.


const FONT_SIZE: int = 14
const TEXT_OFFSET: Vector2 = Vector2(-22.0, -20.0)
const COLOR_SATISFIED: Color = Color(0.4, 1.0, 0.5)
const COLOR_BLACKOUT: Color = Color(0.9, 0.3, 0.3)
const COLOR_TEXT: Color = Color(0.9, 0.95, 1.0)

var _grid: PowerGrid


func setup_grid(grid: PowerGrid) -> void:
    _grid = grid
    _grid.changed.connect(queue_redraw)
    setup(grid.board)


func _draw() -> void:
    super._draw()
    if _grid == null:
        return
    for i: int in _grid.board.sources.size():
        var source_tip: Vector2 = _terminal_tip(_grid.board.sources[i])
        var supply: String = "%dW" % roundi(_grid.supply_of(i))
        draw_string(ThemeDB.fallback_font, source_tip + TEXT_OFFSET, supply, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, COLOR_TEXT)
    for i: int in _grid.board.targets.size():
        var terminal: PipeTerminal = _grid.board.targets[i]
        var tip: Vector2 = _terminal_tip(terminal)
        var color: Color = COLOR_SATISFIED if _grid.is_satisfied(i) else COLOR_BLACKOUT
        draw_circle(tip, TERMINAL_RADIUS, color)
        var text: String = "%d/%d" % [roundi(_grid.delivered_to(i)), roundi(_grid.demand_of(i))]
        draw_string(ThemeDB.fallback_font, tip + TEXT_OFFSET, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, COLOR_TEXT)
    for y: int in _grid.board.height:
        for x: int in _grid.board.width:
            var cell: Vector2i = Vector2i(x, y)
            if _grid.power_at(cell) > 0.0:
                var label: String = str(roundi(_grid.power_at(cell)))
                draw_string(ThemeDB.fallback_font, _center_of(cell) + Vector2(NODE_RADIUS, -NODE_RADIUS), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, COLOR_TEXT)

