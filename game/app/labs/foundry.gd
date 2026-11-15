extends Control
## Laboratorio de Fundición: compone un FoundryRun y dibuja su estado.
## La vista solo forma la palabra tecleada y delega en collect(); las reglas viven en FoundryRun.
## F5 reinicia y Esc vuelve al menú.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const PANEL_BG := Color(0.06, 0.075, 0.11)
const PANEL_BORDER := Color(0.18, 0.21, 0.28)
const TEXT := Color(0.86, 0.9, 0.96)
const MUTED := Color(0.52, 0.58, 0.68)
const TIME_COLOR := Color(0.35, 0.8, 1.0)
const WARNING_TIME := 5.0
const DANGER := Color(1.0, 0.35, 0.3)
const OK := Color(0.3, 0.95, 0.55)
const BAR_BACK := Color(0.08, 0.1, 0.14)
const BAR_FRAME := Color(0.22, 0.26, 0.34)
const MINERAL_COLORS: Dictionary = {
    FoundryRun.Mineral.IRON: Color(0.72, 0.78, 0.88),
    FoundryRun.Mineral.COPPER: Color(0.95, 0.5, 0.25),
    FoundryRun.Mineral.GOLD: Color(1.0, 0.82, 0.2),
}
const MINERAL_GLYPHS: Dictionary = {
    FoundryRun.Mineral.IRON: "Fe",
    FoundryRun.Mineral.COPPER: "Cu",
    FoundryRun.Mineral.GOLD: "Au",
}
const TITLE_SIZE := 34
const BODY_SIZE := 15
const CARD_NAME_SIZE := 26
const BUFFER_SIZE := 32
const HINT_SIZE := 13
const MARGIN := 36.0
const COUNTER_HEIGHT := 58.0
const CARD_WIDTH := 220.0
const CARD_HEIGHT := 150.0
const CARD_GAP := 28.0
const BAR_HEIGHT := 10.0
const MAX_TYPED_LENGTH := 10

var _run: FoundryRun
var _typed: String = ""


func _ready() -> void:
    _restart()
    resized.connect(queue_redraw)


func _process(delta: float) -> void:
    _run.tick(delta)
    queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
        KEY_F5:
            _restart()
        KEY_ENTER, KEY_KP_ENTER:
            if _run.is_ended():
                _restart()
        KEY_BACKSPACE:
            if not _typed.is_empty():
                _typed = _typed.left(_typed.length() - 1)
                queue_redraw()
        _:
            _type(key.keycode)


func _restart() -> void:
    _run = FoundryRun.new(GameRandom.new())
    _typed = ""
    queue_redraw()


## La vista acumula letras y envía la palabra completa; el dominio decide si recoge.
func _type(keycode: Key) -> void:
    if _run.is_ended() or keycode < KEY_A or keycode > KEY_Z:
        return
    _typed += char(keycode).to_lower()
    if _run.collect(_typed):
        _typed = ""
        return
    _trim_typed()


## Si lo tecleado ya no puede ser el comienzo de ningún mineral activo, se borra.
func _trim_typed() -> void:
    if _typed.length() > MAX_TYPED_LENGTH:
        _typed = ""
        return
    for spawn: FoundryRun.Spawn in _run.active:
        var mineral_name: String = String(FoundryRun.NAMES[spawn.mineral]).to_lower()
        if mineral_name.begins_with(_typed):
            return
    _typed = ""


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND, true)
    _draw_header()
    _draw_counters()
    _draw_active()
    _draw_buffer()
    if _run.is_ended():
        _draw_finished()


func _draw_header() -> void:
    UiDraw.text(self, Vector2(MARGIN, MARGIN - 8.0), "FUNDICIÓN", TITLE_SIZE, TEXT, true)
    UiDraw.text(
            self,
            Vector2(MARGIN, MARGIN + 38.0),
            "Escribe el nombre del mineral antes de que se enfríe",
            BODY_SIZE,
            MUTED,
            )
    var time_color: Color = DANGER if _run.remaining <= WARNING_TIME else TIME_COLOR
    var time_width: float = minf(300.0, size.x * 0.32)
    var time_x: float = size.x - MARGIN - time_width
    UiDraw.text(self, Vector2(time_x, MARGIN), "TIEMPO", BODY_SIZE, time_color, true)
    UiDraw.text(
            self,
            Vector2(time_x, MARGIN - 2.0),
            "%.1f s" % _run.remaining,
            24,
            time_color,
            true,
            HORIZONTAL_ALIGNMENT_RIGHT,
            time_width,
            )


func _draw_counters() -> void:
    var minerals: Array = [
        FoundryRun.Mineral.IRON,
        FoundryRun.Mineral.COPPER,
        FoundryRun.Mineral.GOLD,
    ]
    var available: float = size.x - MARGIN * 2.0
    var gap: float = 12.0
    var width: float = (available - gap * 2.0) / 3.0
    var top: float = MARGIN + 78.0
    for index: int in minerals.size():
        var mineral: FoundryRun.Mineral = minerals[index]
        var color: Color = MINERAL_COLORS[mineral]
        var rect: Rect2 = Rect2(
                Vector2(MARGIN + float(index) * (width + gap), top),
                Vector2(width, COUNTER_HEIGHT),
                )
        UiDraw.card(self, rect, PANEL_BG, PANEL_BORDER)
        draw_rect(Rect2(rect.position, Vector2(20.0, rect.size.y)), color)
        UiDraw.text(
                self,
                rect.position + Vector2(16.0, 10.0),
                String(MINERAL_GLYPHS[mineral]),
                20,
                color,
                true,
                )
        UiDraw.text(
                self,
                rect.position + Vector2(52.0, 10.0),
                String(FoundryRun.NAMES[mineral]).to_upper(),
                BODY_SIZE,
                MUTED,
                )
        UiDraw.text(
                self,
                Vector2(rect.end.x - 64.0, rect.position.y + 12.0),
                str(_run.count(mineral)),
                26,
                color,
                true,
                HORIZONTAL_ALIGNMENT_RIGHT,
                48.0,
                )


func _draw_active() -> void:
    var count: int = _run.active.size()
    var top: float = size.y * 0.37
    if count == 0:
        UiDraw.text_centered(self, size.x * 0.5, top + 40.0, "ESPERANDO MINERALES...", BODY_SIZE, MUTED)
        return
    var total_width: float = CARD_WIDTH * float(count) + CARD_GAP * float(count - 1)
    var start_x: float = (size.x - total_width) * 0.5
    for index: int in count:
        var spawn: FoundryRun.Spawn = _run.active[index]
        var rect: Rect2 = Rect2(
                Vector2(start_x + float(index) * (CARD_WIDTH + CARD_GAP), top),
                Vector2(CARD_WIDTH, CARD_HEIGHT),
                )
        _draw_mineral_card(rect, spawn)


func _draw_mineral_card(rect: Rect2, spawn: FoundryRun.Spawn) -> void:
    var color: Color = MINERAL_COLORS[spawn.mineral]
    UiDraw.card(self, rect, PANEL_BG, color.darkened(0.25))
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), color)
    UiDraw.text(
            self,
            rect.position + Vector2(16.0, 14.0),
            String(MINERAL_GLYPHS[spawn.mineral]),
            20,
            color,
            true,
            )
    UiDraw.text_centered(
            self,
            rect.get_center().x,
            rect.position.y + 24.0,
            String(FoundryRun.NAMES[spawn.mineral]).to_upper(),
            CARD_NAME_SIZE,
            TEXT,
            true,
            )
    UiDraw.text_centered(
            self,
            rect.get_center().x,
            rect.position.y + 62.0,
            "TECLEA SU NOMBRE",
            HINT_SIZE,
            MUTED,
            )
    var ratio: float = clampf(spawn.remaining / spawn.lifetime, 0.0, 1.0)
    var bar_rect: Rect2 = Rect2(
            Vector2(rect.position.x + 20.0, rect.end.y - 32.0),
            Vector2(rect.size.x - 40.0, BAR_HEIGHT),
            )
    UiDraw.bar(self, bar_rect, ratio, color, BAR_BACK, BAR_FRAME)
    UiDraw.text_centered(
            self,
            rect.get_center().x,
            rect.end.y - 58.0,
            "%.1f s" % maxf(spawn.remaining, 0.0),
            BODY_SIZE,
            color,
            true,
            )


func _draw_buffer() -> void:
    var top: float = size.y - 154.0
    var width: float = minf(620.0, size.x - MARGIN * 2.0)
    var rect: Rect2 = Rect2(Vector2((size.x - width) * 0.5, top), Vector2(width, 62.0))
    UiDraw.card(self, rect, Color(0.05, 0.06, 0.09), PANEL_BORDER)
    if _typed.is_empty():
        UiDraw.text_centered(
                self,
                size.x * 0.5,
                top + 18.0,
                "TECLEA EL NOMBRE",
                BUFFER_SIZE - 8,
                MUTED,
                true,
                )
    else:
        UiDraw.text_centered(
                self,
                size.x * 0.5,
                top + 12.0,
                _typed.to_upper(),
                BUFFER_SIZE,
                TEXT,
                true,
                )
    UiDraw.text(
            self,
            Vector2(MARGIN, size.y - 58.0),
            "PERDIDOS: %d" % _run.lost,
            BODY_SIZE,
            DANGER if _run.lost > 0 else MUTED,
            true,
            )
    UiDraw.text(
            self,
            Vector2(MARGIN, size.y - 34.0),
            "F5: reiniciar · Retroceso: borrar · Esc: menú",
            HINT_SIZE,
            MUTED,
            )


func _draw_finished() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.68), true)
    var width: float = minf(520.0, size.x - MARGIN * 2.0)
    var height: float = 270.0
    var rect: Rect2 = Rect2(
            Vector2((size.x - width) * 0.5, (size.y - height) * 0.5),
            Vector2(width, height),
            )
    UiDraw.card(self, rect, PANEL_BG, TIME_COLOR)
    UiDraw.text_centered(self, size.x * 0.5, rect.position.y + 28.0, "TIEMPO AGOTADO", 28, TEXT, true)
    UiDraw.text_centered(
            self,
            size.x * 0.5,
            rect.position.y + 74.0,
            "Se acabaron los %d segundos." % int(FoundryRun.TIME_LIMIT),
            BODY_SIZE,
            MUTED,
            )
    var minerals: Array = [
        FoundryRun.Mineral.IRON,
        FoundryRun.Mineral.COPPER,
        FoundryRun.Mineral.GOLD,
    ]
    var column_width: float = rect.size.x / 3.0
    for index: int in minerals.size():
        var mineral: FoundryRun.Mineral = minerals[index]
        var center_x: float = rect.position.x + column_width * (float(index) + 0.5)
        UiDraw.text_centered(self, center_x, rect.position.y + 112.0, str(_run.count(mineral)), 32, MINERAL_COLORS[mineral], true)
        UiDraw.text_centered(
                self,
                center_x,
                rect.position.y + 152.0,
                String(FoundryRun.NAMES[mineral]).to_upper(),
                HINT_SIZE,
                MUTED,
                )
    UiDraw.text_centered(
            self,
            size.x * 0.5,
            rect.position.y + 186.0,
            "Minerales perdidos: %d" % _run.lost,
            BODY_SIZE,
            DANGER if _run.lost > 0 else MUTED,
            )
    UiDraw.text_centered(
            self,
            size.x * 0.5,
            rect.position.y + 220.0,
            "ENTER: nueva sesión · Esc: menú",
            BODY_SIZE,
            OK,
            true,
            )
