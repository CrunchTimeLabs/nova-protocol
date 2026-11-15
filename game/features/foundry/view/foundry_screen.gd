class_name FoundryScreen
extends Control
## Pantalla de la fundición: fondo del horno, reloj de arena (tiempo total), tolva con los minerales en espera,
## objetivos en el centro con su barra (tiempo de vida), almacén con los contadores y recursos.
## La vista forma la palabra tecleada y llama a `FoundryRun.collect`; las animaciones son solo de la vista.
## F5 reinicia, ENTER reinicia al terminar y Esc emite `exit_requested`.


signal exit_requested

const SCALE := 4.0
const TOP_BAR := 56.0
## La cinta del fondo (tolva): los minerales en espera se apoyan aquí.
const BELT_Y := 160.0
const BELT_CENTER := 512.0
const BELT_SLOT := 74.0
const HOPPER_SCALE := 2.0
const FURNACE_MOUTH := Vector2(512, 84)
const CARD_SIZE := Vector2(214, 246)
const CARD_TOP := 206.0
const CARD_GAP := 40.0
const CARD_SCALE := 4.0
const BUFFER := Rect2(312, 486, 400, 60)
const LEFT_PANEL := Rect2(16, 68, 196, 336)
const RESOURCE_PANEL := Rect2(16, 414, 196, 214)
const RIGHT_PANEL := Rect2(812, 68, 196, 560)
const STORE_ROW := 128.0
const HOURGLASS_AT := Vector2(58, 106)
const MOVE_TIME := 0.45
const GHOST_TIME := 0.6
const DROP_TIME := 0.4
const FLY_TIME := 0.55
const WRONG_TIME := 0.35
const WARNING_TIME := 5.0
const MAX_TYPED := 10
const EMBERS := 40

var _run: FoundryRun
var _sfx: FoundrySfx
var _time: float = 0.0
var _typed: String = ""
var _wrong: float = 0.0
## Posición actual de cada mineral en la tolva y cuándo cayó a ella.
var _hopper_pos: Dictionary = {}
var _born: Dictionary = {}
## Tarjetas del centro: {spawn, since, done, pos}. `done` < 0 mientras sigue activo.
var _cards: Array[Dictionary] = []
## Minerales recogidos volando al almacén: {mineral, from, since}.
var _flyers: Array[Dictionary] = []
var _pulse: Dictionary = {}
var _lost_flash: float = 0.0
var _embers: Array[Dictionary] = []
var _ended_at: float = -1.0
var _last_tick: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _sfx = FoundrySfx.new()
    add_child(_sfx)
    _rng.randomize()
    for i: int in EMBERS:
        _embers.append(_new_ember(true))
    restart(GameRandom.new())


## Empieza una sesión nueva con el azar dado (las pruebas de captura pasan una semilla).
func restart(random: GameRandom) -> void:
    _run = FoundryRun.new(random)
    _run.group_spawned.connect(_on_group_spawned)
    _run.selected.connect(_on_selected)
    _run.collected.connect(_on_collected)
    _run.expired.connect(_on_expired)
    _run.run_ended.connect(_on_run_ended)
    _typed = ""
    _hopper_pos.clear()
    _born.clear()
    _cards.clear()
    _flyers.clear()
    _pulse.clear()
    _ended_at = -1.0
    _last_tick = -1
    _sfx.set_furnace(true)


func run() -> FoundryRun:
    return _run


func _process(delta: float) -> void:
    _time += delta
    _run.tick(delta)
    _wrong = maxf(0.0, _wrong - delta)
    _lost_flash = maxf(0.0, _lost_flash - delta)
    for mineral: int in _pulse.keys():
        _pulse[mineral] = maxf(0.0, float(_pulse[mineral]) - delta)
    _update_hopper(delta)
    _update_cards(delta)
    _update_flyers()
    _update_embers(delta)
    _update_ticks()
    queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_ESCAPE:
            exit_requested.emit()
        KEY_F5:
            restart(GameRandom.new())
        KEY_ENTER, KEY_KP_ENTER:
            if _run.is_ended():
                restart(GameRandom.new())
        KEY_BACKSPACE:
            if not _typed.is_empty():
                _typed = _typed.left(_typed.length() - 1)
        _:
            _type(key.keycode)


## Acumula letras; si la palabra es un objetivo lo recoge, y si ya no puede serlo se borra con aviso.
func _type(keycode: Key) -> void:
    if _run.is_ended() or keycode < KEY_A or keycode > KEY_Z:
        return
    _typed += char(keycode).to_lower()
    _sfx.play(FoundrySfx.Sound.KEY, -4.0, _rng.randf_range(0.9, 1.1))
    if _run.collect(_typed):
        _typed = ""
        return
    if _typed.length() <= MAX_TYPED:
        for spawn: FoundryRun.Spawn in _run.active:
            if _name(spawn.mineral).to_lower().begins_with(_typed):
                return
    _typed = ""
    _wrong = WRONG_TIME
    _sfx.play(FoundrySfx.Sound.WRONG, -4.0)


func _name(mineral: FoundryRun.Mineral) -> String:
    return String(FoundryRun.NAMES[mineral])


# --- Reacciones a la sesión -------------------------------------------------------------------------------

func _on_group_spawned(added: Array[FoundryRun.Spawn]) -> void:
    for i: int in added.size():
        var spawn: FoundryRun.Spawn = added[i]
        _born[spawn] = _time + float(i) * 0.08
        _hopper_pos[spawn] = FURNACE_MOUTH
    if not added.is_empty():
        _sfx.play(FoundrySfx.Sound.DROP)


func _on_selected(spawn: FoundryRun.Spawn) -> void:
    var from: Vector2 = _hopper_pos.get(spawn, FURNACE_MOUTH)
    _hopper_pos.erase(spawn)
    _born.erase(spawn)
    _cards.append({"spawn": spawn, "since": _time, "done": -1.0, "from": from, "pos": Vector2.ZERO, "placed": false})
    _sfx.play(FoundrySfx.Sound.SELECT, -4.0)


func _on_collected(spawn: FoundryRun.Spawn) -> void:
    var card: Dictionary = _card_of(spawn)
    if not card.is_empty():
        card["done"] = _time
        _flyers.append({"mineral": spawn.mineral, "from": _card_image_center(card), "since": _time})
    _sfx.play(FoundrySfx.Sound.GOLD if spawn.mineral == FoundryRun.Mineral.GOLD else FoundrySfx.Sound.COLLECT)


func _on_expired(spawn: FoundryRun.Spawn) -> void:
    var card: Dictionary = _card_of(spawn)
    if not card.is_empty():
        card["done"] = _time
    _lost_flash = 0.8
    _sfx.play(FoundrySfx.Sound.LOST, -2.0)


func _on_run_ended(_result: FoundryRun.End) -> void:
    _ended_at = _time
    _typed = ""
    _sfx.set_furnace(false)
    _sfx.play(FoundrySfx.Sound.END)


func _card_of(spawn: FoundryRun.Spawn) -> Dictionary:
    for card: Dictionary in _cards:
        if card["spawn"] == spawn:
            return card
    return {}


# --- Animación ------------------------------------------------------------------------------------------

func _hopper_target(index: int, count: int) -> Vector2:
    return Vector2(BELT_CENTER + (float(index) - float(count - 1) / 2.0) * BELT_SLOT, BELT_Y - 12.0 * HOPPER_SCALE)


func _update_hopper(delta: float) -> void:
    var count: int = _run.waiting.size()
    for index: int in count:
        var spawn: FoundryRun.Spawn = _run.waiting[index]
        var target: Vector2 = _hopper_target(index, count)
        var age: float = _time - float(_born.get(spawn, -10.0))
        if age < DROP_TIME:
            # Sale del horno y cae a la cinta con un pequeño rebote.
            var t: float = clampf(age / DROP_TIME, 0.0, 1.0)
            var x: float = lerpf(FURNACE_MOUTH.x, target.x, t)
            var y: float = lerpf(FURNACE_MOUTH.y, target.y, t * t) - sin(t * PI) * 26.0
            _hopper_pos[spawn] = Vector2(x, y)
        else:
            var current: Vector2 = _hopper_pos.get(spawn, target)
            _hopper_pos[spawn] = current.lerp(target, 1.0 - exp(-delta * 10.0))


func _card_slot(index: int, count: int) -> Vector2:
    var total: float = CARD_SIZE.x * float(count) + CARD_GAP * float(count - 1)
    return Vector2(BELT_CENTER - total / 2.0 + float(index) * (CARD_SIZE.x + CARD_GAP), CARD_TOP)


func _update_cards(delta: float) -> void:
    for index: int in range(_cards.size() - 1, -1, -1):
        var done: float = float(_cards[index]["done"])
        if done >= 0.0 and _time - done > GHOST_TIME:
            _cards.remove_at(index)
    for index: int in _cards.size():
        var card: Dictionary = _cards[index]
        var slot: Vector2 = _card_slot(index, _cards.size())
        if not bool(card["placed"]):
            card["pos"] = slot
            card["placed"] = true
        else:
            card["pos"] = (card["pos"] as Vector2).lerp(slot, 1.0 - exp(-delta * 12.0))


func _card_image_center(card: Dictionary) -> Vector2:
    return (card["pos"] as Vector2) + Vector2(CARD_SIZE.x / 2.0, 70.0)


func _store_icon(mineral: FoundryRun.Mineral) -> Vector2:
    var row: int = FoundryArt.ORDER.find(mineral)
    return RIGHT_PANEL.position + Vector2(40, 74.0 + float(row) * STORE_ROW)


func _update_flyers() -> void:
    for index: int in range(_flyers.size() - 1, -1, -1):
        var flyer: Dictionary = _flyers[index]
        if _time - float(flyer["since"]) >= FLY_TIME:
            _pulse[int(flyer["mineral"])] = 0.5
            _flyers.remove_at(index)


func _new_ember(anywhere: bool) -> Dictionary:
    var y: float = _rng.randf_range(200.0, 600.0) if anywhere else _rng.randf_range(570.0, 600.0)
    return {
        "pos": Vector2(_rng.randf_range(0.0, 1024.0), y),
        "speed": _rng.randf_range(18.0, 46.0),
        "phase": _rng.randf_range(0.0, TAU),
        "life": _rng.randf_range(0.5, 1.0),
    }


func _update_embers(delta: float) -> void:
    for index: int in _embers.size():
        var ember: Dictionary = _embers[index]
        var pos: Vector2 = ember["pos"]
        pos.y -= float(ember["speed"]) * delta
        pos.x += sin(_time * 1.7 + float(ember["phase"])) * 12.0 * delta
        ember["pos"] = pos
        ember["life"] = float(ember["life"]) - delta * 0.18
        if float(ember["life"]) <= 0.0 or pos.y < TOP_BAR:
            _embers[index] = _new_ember(false)


func _update_ticks() -> void:
    if _run.is_ended() or _run.remaining > WARNING_TIME:
        return
    var second: int = ceili(_run.remaining)
    if second != _last_tick:
        _last_tick = second
        _sfx.play(FoundrySfx.Sound.TICK, -2.0, 1.0 + 0.05 * float(WARNING_TIME - second))


# --- Dibujo ---------------------------------------------------------------------------------------------

func _draw() -> void:
    var background: Texture2D = FoundryArt.texture(FoundryArt.BACKGROUND)
    draw_texture_rect(background, Rect2(Vector2.ZERO, background.get_size() * SCALE), false)
    var flicker: float = 0.5 + 0.25 * sin(_time * 7.0) + 0.25 * sin(_time * 13.3)
    draw_circle(FURNACE_MOUTH, 64.0 + 8.0 * flicker, Color(1.0, 0.5, 0.15, 0.06 + 0.06 * flicker))
    _draw_embers()
    _draw_top_bar()
    _draw_hopper()
    _draw_cards()
    _draw_buffer()
    _draw_hourglass_panel()
    _draw_resources()
    _draw_store()
    _draw_flyers()
    if _run.is_ended():
        _draw_summary()


func _draw_embers() -> void:
    for ember: Dictionary in _embers:
        var pos: Vector2 = ember["pos"]
        var alpha: float = clampf(float(ember["life"]), 0.0, 1.0)
        var snapped_pos: Vector2 = (pos / SCALE).floor() * SCALE
        draw_rect(Rect2(snapped_pos, Vector2(SCALE, SCALE)), Color(1.0, 0.6 + 0.3 * alpha, 0.2, 0.7 * alpha))


func _draw_top_bar() -> void:
    draw_rect(Rect2(0, 0, size.x, TOP_BAR), Color(0.04, 0.02, 0.02, 0.82))
    draw_line(Vector2(0, TOP_BAR), Vector2(size.x, TOP_BAR), Color(FoundryArt.TITLE, 0.45), 1.0)
    UiDraw.text(self, Vector2(20, 10), "FUNDICIÓN", 24, FoundryArt.TITLE, true)
    UiDraw.text(self, Vector2(180, 18), "Teclea el nombre del mineral antes de que se enfríe", 14, FoundryArt.TEXT)
    UiDraw.text(self, Vector2(size.x - 330, 20), "Retroceso: borrar  F5: reiniciar  Esc: menú", 12, FoundryArt.MUTED)


func _draw_hopper() -> void:
    UiDraw.text(self, Vector2(226, BELT_Y + 10.0), "TOLVA · EN ESPERA", 11, Color(FoundryArt.TEXT, 0.75), true)
    var count: int = _run.waiting.size()
    for index: int in count:
        var spawn: FoundryRun.Spawn = _run.waiting[index]
        var pos: Vector2 = _hopper_pos.get(spawn, _hopper_target(index, count))
        if _time < float(_born.get(spawn, -10.0)):
            continue
        FoundryArt.draw_mineral(self, spawn.mineral, pos, HOPPER_SCALE)
        UiDraw.text_centered(self, pos.x, pos.y + 30.0, _name(spawn.mineral).to_upper(), 10, Color(FoundryArt.TEXT, 0.7), true)


func _draw_cards() -> void:
    if _cards.is_empty() and not _run.is_ended():
        var dots: String = ".".repeat(1 + int(_time * 3.0) % 3)
        UiDraw.text_centered(self, BELT_CENTER, CARD_TOP + 100.0, "Llegan minerales" + dots, 16, FoundryArt.MUTED, true)
        return
    for card: Dictionary in _cards:
        _draw_card(card)


func _draw_card(card: Dictionary) -> void:
    var spawn: FoundryRun.Spawn = card["spawn"]
    var enter: float = clampf((_time - float(card["since"])) / MOVE_TIME, 0.0, 1.0)
    var eased: float = 1.0 - pow(1.0 - enter, 3.0)
    var done: float = float(card["done"])
    var fade: float = 1.0 if done < 0.0 else 1.0 - clampf((_time - done) / GHOST_TIME, 0.0, 1.0)
    var rect: Rect2 = Rect2(card["pos"], CARD_SIZE)
    var tint: Color = FoundryArt.color(spawn.mineral)
    var edge: Color = tint
    match spawn.status:
        FoundryRun.Status.COLLECTED:
            edge = FoundryArt.GOOD
        FoundryRun.Status.LOST:
            edge = FoundryArt.DANGER
    var alpha: float = eased * fade
    var bob: float = sin(_time * 3.0 + rect.position.x) * 3.0 if spawn.status == FoundryRun.Status.TARGET else 0.0
    UiDraw.panel(self, rect, Color(0.06, 0.035, 0.03, 0.88 * alpha), Color(edge, 0.9 * alpha))
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), Color(edge, alpha))
    # Halo de calor detrás del mineral.
    var image_center: Vector2 = rect.position + Vector2(rect.size.x / 2.0, 70.0 + bob)
    if spawn.status == FoundryRun.Status.TARGET:
        draw_circle(image_center, 46.0, Color(1.0, 0.45, 0.12, 0.12 * alpha))
    # El mineral vuela desde la tolva hasta su tarjeta.
    var from: Vector2 = card["from"]
    var mineral_at: Vector2 = from.lerp(image_center, eased)
    var mineral_scale: float = lerpf(HOPPER_SCALE, CARD_SCALE, eased)
    var mineral_tint: Color = Color(1, 1, 1, fade)
    if spawn.status == FoundryRun.Status.LOST:
        var t: float = 1.0 - fade
        mineral_tint = Color(0.35, 0.3, 0.3, fade)
        mineral_at.y += t * 30.0
    if spawn.status != FoundryRun.Status.COLLECTED:
        FoundryArt.draw_mineral(self, spawn.mineral, mineral_at, mineral_scale, mineral_tint)
    var name_top: float = rect.position.y + 122.0
    _draw_name(rect.get_center().x, name_top, spawn.mineral, alpha)
    var info: String = "%s · %d" % [String(FoundryArt.RARITY[spawn.mineral]), int(FoundryRun.VALUES[spawn.mineral])]
    UiDraw.text_centered(self, rect.get_center().x, name_top + 32.0, info, 11, Color(FoundryArt.MUTED, alpha))
    var bar: Rect2 = Rect2(rect.position + Vector2(18, 176), Vector2(rect.size.x - 36.0, 14))
    var ratio: float = spawn.ratio()
    var bar_color: Color = FoundryArt.timer_color(ratio)
    if spawn.status == FoundryRun.Status.TARGET and ratio < 0.25 and int(_time * 8.0) % 2 == 0:
        bar_color = bar_color.lightened(0.4)
    UiDraw.bar(self, bar, ratio, Color(bar_color, alpha), Color(0.1, 0.06, 0.05, alpha), Color(0.4, 0.3, 0.25, alpha))
    var status: String = "%.1f s" % spawn.remaining
    var status_color: Color = bar_color
    match spawn.status:
        FoundryRun.Status.COLLECTED:
            status = "RECOLECTADO"
            status_color = FoundryArt.GOOD
        FoundryRun.Status.LOST:
            status = "PERDIDO  -%d recursos" % int(FoundryRun.COSTS[spawn.mineral])
            status_color = FoundryArt.DANGER
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 204.0, status, 14 if spawn.status == FoundryRun.Status.TARGET else 13, Color(status_color, alpha), true)


## Nombre del mineral con las letras ya tecleadas resaltadas.
func _draw_name(center_x: float, top: float, mineral: FoundryRun.Mineral, alpha: float) -> void:
    var label: String = _name(mineral).to_upper()
    var font_size: int = 26
    var font: Font = UiDraw.font(true)
    var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var matched: int = 0
    if not _typed.is_empty() and label.to_lower().begins_with(_typed):
        matched = _typed.length()
    var x: float = center_x - width / 2.0
    var baseline: float = top + font.get_ascent(font_size)
    for i: int in label.length():
        var letter: String = label[i]
        var color: Color = FoundryArt.TITLE if i < matched else FoundryArt.TEXT
        draw_string(font, Vector2(x, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(color, alpha))
        x += font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _draw_buffer() -> void:
    var shake: float = sin(_wrong * 60.0) * 8.0 * (_wrong / WRONG_TIME)
    var rect: Rect2 = Rect2(BUFFER.position + Vector2(shake, 0.0), BUFFER.size)
    var edge: Color = FoundryArt.DANGER if _wrong > 0.0 else FoundryArt.EDGE
    UiDraw.panel(self, rect, Color(0.05, 0.03, 0.025, 0.9), edge)
    if _typed.is_empty():
        var hint: String = "TECLEA EL NOMBRE" if not _run.active.is_empty() else "ESPERA AL MINERAL"
        UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 18.0, hint, 18, FoundryArt.MUTED, true)
        return
    var caret: String = "_" if int(_time * 2.5) % 2 == 0 else " "
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 12.0, _typed.to_upper() + caret, 28, FoundryArt.TEXT, true)


func _draw_hourglass_panel() -> void:
    FoundryArt.panel(self, LEFT_PANEL)
    UiDraw.text_centered(self, LEFT_PANEL.get_center().x, LEFT_PANEL.position.y + 12.0, "TIEMPO DEL NIVEL", 13, FoundryArt.TITLE, true)
    var ratio: float = _run.remaining / FoundryRun.TIME_LIMIT
    HourglassDraw.draw(self, HOURGLASS_AT, SCALE, ratio, _time, not _run.is_ended())
    var warning: bool = _run.remaining <= WARNING_TIME and not _run.is_ended()
    var color: Color = FoundryArt.TEXT
    var font_size: int = 26
    if warning:
        var beat: float = fmod(_run.remaining, 1.0)
        color = FoundryArt.DANGER
        font_size = 26 + int(6.0 * beat)
    UiDraw.text_centered(self, LEFT_PANEL.get_center().x, LEFT_PANEL.end.y - 40.0, "%.1f s" % _run.remaining, font_size, color, true)


func _draw_resources() -> void:
    FoundryArt.panel(self, RESOURCE_PANEL)
    var x: float = RESOURCE_PANEL.position.x + 14.0
    var y: float = RESOURCE_PANEL.position.y + 12.0
    UiDraw.text(self, Vector2(x, y), "RECURSOS", 13, FoundryArt.TITLE, true)
    _resource_line(y + 30.0, "Total", str(_run.resources), FoundryArt.TEXT)
    var lost_color: Color = FoundryArt.DANGER if _run.lost > 0 else FoundryArt.MUTED
    if _lost_flash > 0.0:
        lost_color = lost_color.lightened(0.5 * _lost_flash)
    _resource_line(y + 56.0, "Perdidos", str(_run.lost), lost_color)
    UiDraw.wrapped(
            self,
            Vector2(x, y + 92.0),
            "Cada mineral nuevo gasta recursos. Si se enfría sin recogerlo, no se devuelven.",
            11,
            FoundryArt.MUTED,
            RESOURCE_PANEL.size.x - 28.0,
            )


func _resource_line(y: float, label: String, value: String, color: Color) -> void:
    var x: float = RESOURCE_PANEL.position.x + 14.0
    UiDraw.text(self, Vector2(x, y), label, 12, FoundryArt.MUTED)
    UiDraw.text(self, Vector2(x, y - 3.0), value, 18, color, true, HORIZONTAL_ALIGNMENT_RIGHT, RESOURCE_PANEL.size.x - 28.0)


func _draw_store() -> void:
    FoundryArt.panel(self, RIGHT_PANEL)
    UiDraw.text_centered(self, RIGHT_PANEL.get_center().x, RIGHT_PANEL.position.y + 12.0, "ALMACÉN", 13, FoundryArt.TITLE, true)
    for row: int in FoundryArt.ORDER.size():
        var mineral: FoundryRun.Mineral = FoundryArt.ORDER[row]
        var top: float = RIGHT_PANEL.position.y + 36.0 + float(row) * STORE_ROW
        var row_rect: Rect2 = Rect2(RIGHT_PANEL.position.x + 10.0, top, RIGHT_PANEL.size.x - 20.0, STORE_ROW - 10.0)
        var pulse: float = float(_pulse.get(mineral, 0.0)) / 0.5
        draw_rect(row_rect, Color(FoundryArt.color(mineral), 0.06 + 0.2 * pulse))
        draw_rect(Rect2(row_rect.position, Vector2(4.0, row_rect.size.y)), FoundryArt.color(mineral))
        FoundryArt.draw_mineral(self, mineral, _store_icon(mineral), 2.0 + 0.4 * pulse)
        UiDraw.text(self, row_rect.position + Vector2(64, 10), _name(mineral).to_upper(), 15, FoundryArt.color(mineral), true)
        UiDraw.text(self, row_rect.position + Vector2(64, 30), String(FoundryArt.RARITY[mineral]), 11, FoundryArt.MUTED)
        UiDraw.text(self, row_rect.position + Vector2(64, 44), "%d c/u" % int(FoundryRun.VALUES[mineral]), 11, FoundryArt.MUTED)
        UiDraw.text(
                self,
                row_rect.position + Vector2(0, 66),
                "x %d" % _run.count(mineral),
                28 + int(6.0 * pulse),
                FoundryArt.TEXT,
                true,
                HORIZONTAL_ALIGNMENT_RIGHT,
                row_rect.size.x - 12.0,
                )
    var total_top: float = RIGHT_PANEL.end.y - 90.0
    draw_line(Vector2(RIGHT_PANEL.position.x + 14, total_top), Vector2(RIGHT_PANEL.end.x - 14, total_top), Color(FoundryArt.EDGE, 0.5), 1.0)
    UiDraw.text_centered(self, RIGHT_PANEL.get_center().x, total_top + 12.0, "VALOR TOTAL", 12, FoundryArt.MUTED, true)
    UiDraw.text_centered(self, RIGHT_PANEL.get_center().x, total_top + 32.0, str(_run.value), 32, FoundryArt.TITLE, true)


func _draw_flyers() -> void:
    for flyer: Dictionary in _flyers:
        var t: float = clampf((_time - float(flyer["since"])) / FLY_TIME, 0.0, 1.0)
        var mineral: FoundryRun.Mineral = int(flyer["mineral"]) as FoundryRun.Mineral
        var from: Vector2 = flyer["from"]
        var to: Vector2 = _store_icon(mineral)
        var eased: float = t * t * (3.0 - 2.0 * t)
        var at: Vector2 = from.lerp(to, eased) - Vector2(0.0, sin(t * PI) * 90.0)
        FoundryArt.draw_mineral(self, mineral, at, lerpf(CARD_SCALE, 2.0, eased))
        for i: int in 3:
            var trail: float = clampf(eased - 0.06 * float(i + 1), 0.0, 1.0)
            var spot: Vector2 = from.lerp(to, trail) - Vector2(0.0, sin(trail * PI) * 90.0)
            draw_rect(Rect2(spot - Vector2(3, 3), Vector2(6, 6)), Color(FoundryArt.color(mineral), 0.5 - 0.15 * float(i)))


func _draw_summary() -> void:
    var t: float = clampf((_time - _ended_at) / 0.5, 0.0, 1.0)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.01, 0.72 * t))
    var rect: Rect2 = Rect2(Vector2(262, 120 + 20.0 * (1.0 - t)), Vector2(500, 400))
    UiDraw.panel(self, rect, Color(0.08, 0.045, 0.035, 0.97 * t), Color(FoundryArt.TITLE, t))
    var cx: float = rect.get_center().x
    UiDraw.text_centered(self, cx, rect.position.y + 22.0, "¡SE ACABÓ LA ARENA!", 28, Color(FoundryArt.TITLE, t), true)
    UiDraw.text_centered(self, cx, rect.position.y + 62.0, "Fin de los %d segundos" % int(FoundryRun.TIME_LIMIT), 14, Color(FoundryArt.MUTED, t))
    var column: float = rect.size.x / 3.0
    for index: int in FoundryArt.ORDER.size():
        var mineral: FoundryRun.Mineral = FoundryArt.ORDER[index]
        var x: float = rect.position.x + column * (float(index) + 0.5)
        FoundryArt.draw_mineral(self, mineral, Vector2(x, rect.position.y + 130.0), 3.0, Color(1, 1, 1, t))
        UiDraw.text_centered(self, x, rect.position.y + 172.0, str(_run.count(mineral)), 32, Color(FoundryArt.color(mineral), t), true)
        UiDraw.text_centered(self, x, rect.position.y + 212.0, _name(mineral).to_upper(), 12, Color(FoundryArt.MUTED, t), true)
    UiDraw.text_centered(self, cx, rect.position.y + 250.0, "Valor total: %d" % _run.value, 20, Color(FoundryArt.TITLE, t), true)
    var lost_color: Color = FoundryArt.DANGER if _run.resources_lost > 0 else FoundryArt.MUTED
    UiDraw.text_centered(
            self,
            cx,
            rect.position.y + 286.0,
            "Recursos gastados %d · perdidos %d (%d minerales)" % [_run.resources_used, _run.resources_lost, _run.lost],
            13,
            Color(lost_color, t),
            )
    UiDraw.text_centered(self, cx, rect.end.y - 50.0, "ENTER: otra vez     Esc: menú", 15, Color(FoundryArt.GOOD, t), true)
