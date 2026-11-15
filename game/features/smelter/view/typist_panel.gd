class_name TypistPanel
extends Control
## Mitad izquierda (J1): reloj de arena, tolva con las menas en espera, objetivos en el centro (mena, su nombre
## y la barra de su tiempo) y lo tecleado. Si la temperatura bloquea, los objetivos se ven con candado.
## Solo dibuja; el nivel le pasa lo tecleado.


const CARD := Vector2(196, 224)
const CARD_TOP := 168.0
const CARD_GAP := 22.0
const BELT_Y := 146.0
const HOURGLASS_AT := Vector2(16, 58)
const HOURGLASS_SCALE := 2.5

var run: SmelterRun
var typed: String = ""
var wrong: float = 0.0
var _time: float = 0.0
var _born: Dictionary = {}
var _cards: Array[Dictionary] = []


func setup(p_run: SmelterRun) -> void:
    run = p_run
    run.group_spawned.connect(_on_group)
    run.selected.connect(_on_selected)
    run.smelted.connect(_on_done)
    run.expired.connect(_on_done)


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    size = SmelterStyle.HALF
    clip_contents = true


func _process(delta: float) -> void:
    _time += delta
    wrong = maxf(0.0, wrong - delta)
    for index: int in range(_cards.size() - 1, -1, -1):
        var done: float = float(_cards[index]["done"])
        if done >= 0.0 and _time - done > 0.6:
            _cards.remove_at(index)
    queue_redraw()


func _on_group(added: Array[SmelterRun.Spawn]) -> void:
    for i: int in added.size():
        _born[added[i]] = _time + float(i) * 0.08


func _on_selected(spawn: SmelterRun.Spawn) -> void:
    _cards.append({"spawn": spawn, "since": _time, "done": -1.0})


func _on_done(spawn: SmelterRun.Spawn) -> void:
    for card: Dictionary in _cards:
        if card["spawn"] == spawn:
            card["done"] = _time


func _draw() -> void:
    SmelterStyle.backdrop(self, 260.0, _time)
    SmelterStyle.top_bar(self, 1, "FUNDICIÓN · ESCRIBE EL METAL", "A–Z · Retroceso")
    _draw_hourglass()
    _draw_hopper()
    _draw_cards()
    _draw_buffer()


func _draw_hourglass() -> void:
    var ratio: float = run.remaining / SmelterRun.TIME_LIMIT
    HourglassDraw.draw(self, HOURGLASS_AT, HOURGLASS_SCALE, ratio, _time, run.is_started and not run.is_finished)
    var warning: bool = run.remaining <= 5.0 and run.is_started and not run.is_finished
    UiDraw.text_centered(self, HOURGLASS_AT.x + 35.0, HOURGLASS_AT.y + 124.0, "%d s" % ceili(run.remaining), 18,
            FoundryArt.DANGER if warning else FoundryArt.TEXT, true)
    UiDraw.text_centered(self, HOURGLASS_AT.x + 35.0, HOURGLASS_AT.y + 150.0, "Quedan", 11, FoundryArt.MUTED)
    UiDraw.text_centered(self, HOURGLASS_AT.x + 35.0, HOURGLASS_AT.y + 164.0, "%d menas" % (run.total_pool() + run.waiting.size()), 11, FoundryArt.MUTED)


func _draw_hopper() -> void:
    draw_rect(Rect2(100, BELT_Y, 400, 6), Color(0.12, 0.11, 0.11))
    for x: int in range(104, 500, 18):
        draw_rect(Rect2(float(x) + fmod(_time * 30.0, 18.0), BELT_Y + 1, 6, 2), Color(0.3, 0.27, 0.25))
    UiDraw.text(self, Vector2(104, BELT_Y + 10), "TOLVA", 10, FoundryArt.MUTED, true)
    var count: int = run.waiting.size()
    for index: int in count:
        var spawn: SmelterRun.Spawn = run.waiting[index]
        var age: float = _time - float(_born.get(spawn, -10.0))
        if age < 0.0:
            continue
        var target: Vector2 = Vector2(300 + (float(index) - float(count - 1) / 2.0) * 64.0, BELT_Y - 24.0)
        var drop: float = clampf(age / 0.35, 0.0, 1.0)
        var at: Vector2 = Vector2(target.x, lerpf(60.0, target.y, drop * drop))
        SmelterStyle.ore(self, spawn.ore, at, 2.0)


func _card_rect(index: int, count: int) -> Rect2:
    var total: float = CARD.x * float(count) + CARD_GAP * float(count - 1)
    return Rect2(Vector2(298.0 - total / 2.0 + float(index) * (CARD.x + CARD_GAP), CARD_TOP), CARD)


func _draw_cards() -> void:
    if _cards.is_empty():
        if run.is_started and not run.is_finished:
            UiDraw.text_centered(self, 298, CARD_TOP + 90, "Llegan menas" + ".".repeat(1 + int(_time * 3.0) % 3), 16, FoundryArt.MUTED, true)
        return
    for index: int in _cards.size():
        _draw_card(_cards[index], _card_rect(index, _cards.size()))


func _draw_card(card: Dictionary, rect: Rect2) -> void:
    var spawn: SmelterRun.Spawn = card["spawn"]
    var enter: float = clampf((_time - float(card["since"])) / 0.35, 0.0, 1.0)
    var done: float = float(card["done"])
    var fade: float = 1.0 if done < 0.0 else 1.0 - clampf((_time - done) / 0.6, 0.0, 1.0)
    var alpha: float = enter * fade
    var color: Color = Ores.color(spawn.ore)
    var edge: Color = color
    if spawn.status == SmelterRun.Status.SMELTED:
        edge = FoundryArt.GOOD
    elif spawn.status == SmelterRun.Status.LOST:
        edge = FoundryArt.DANGER
    rect.position.y += (1.0 - enter) * -40.0
    UiDraw.panel(self, rect, Color(0.06, 0.035, 0.03, 0.9 * alpha), Color(edge, 0.9 * alpha))
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5)), Color(edge, alpha))
    var center: Vector2 = rect.position + Vector2(rect.size.x / 2.0, 62.0 + sin(_time * 3.0 + rect.position.x) * 2.0)
    if spawn.status == SmelterRun.Status.TARGET:
        draw_circle(center, 42.0, Color(1.0, 0.45, 0.12, 0.12 * alpha))
    var tint: Color = Color(1, 1, 1, alpha) if spawn.status != SmelterRun.Status.LOST else Color(0.35, 0.3, 0.3, alpha)
    if spawn.status == SmelterRun.Status.SMELTED:
        draw_rect(Rect2(center - Vector2(30, 10), Vector2(60, 20)), Color(color.lightened(0.3), alpha))
    else:
        SmelterStyle.ore(self, spawn.ore, center, 3.5, tint)
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 112, Ores.ore_name(spawn.ore).to_upper(), 20, Color(color, alpha), true)
    var answer: String = Ores.element(spawn.ore).to_upper()
    var shown: String = ""
    var plain_typed: String = SmelterRun.plain(typed)
    var matched: int = plain_typed.length() if SmelterRun.answer(spawn.ore).begins_with(plain_typed) else 0
    for i: int in answer.length():
        shown += answer[i] if i < matched else "_"
    if spawn.status == SmelterRun.Status.SMELTED:
        shown = answer
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 140, "→ " + shown, 16, Color(FoundryArt.TEXT, alpha), true)
    var bar: Rect2 = Rect2(rect.position + Vector2(16, 172), Vector2(rect.size.x - 32, 12))
    var ratio: float = spawn.ratio()
    UiDraw.bar(self, bar, ratio, Color(FoundryArt.timer_color(ratio), alpha), Color(0.1, 0.06, 0.05, alpha), Color(0.4, 0.3, 0.25, alpha))
    var status: String = "%.1f s" % spawn.remaining
    var status_color: Color = FoundryArt.timer_color(ratio)
    match spawn.status:
        SmelterRun.Status.SMELTED:
            status = "¡FUNDIDO!"
            status_color = FoundryArt.GOOD
        SmelterRun.Status.LOST:
            status = "SE ENFRIÓ"
            status_color = FoundryArt.DANGER
    UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 192, status, 14, Color(status_color, alpha), true)
    if run.blocked and spawn.status == SmelterRun.Status.TARGET:
        var pulse: float = 0.5 + 0.5 * sin(_time * 8.0)
        draw_rect(rect, Color(0.5, 0.05, 0.03, 0.45 + 0.15 * pulse))
        _lock(rect.get_center() - Vector2(0, 20))
        UiDraw.text_centered(self, rect.get_center().x, rect.get_center().y + 4, "TEMPERATURA", 14, FoundryArt.TEXT, true)


func _lock(at: Vector2) -> void:
    draw_rect(Rect2(at - Vector2(14, 4), Vector2(28, 22)), FoundryArt.DANGER)
    draw_arc(at - Vector2(0, 4), 9.0, PI, TAU, 12, FoundryArt.DANGER, 4.0)
    draw_rect(Rect2(at + Vector2(-2, 4), Vector2(4, 8)), Color(0.2, 0.02, 0.02))


func _draw_buffer() -> void:
    var shake: float = sin(wrong * 60.0) * 8.0 * (wrong / 0.35)
    var rect: Rect2 = Rect2(Vector2(118 + shake, 420), Vector2(360, 56))
    UiDraw.panel(self, rect, Color(0.05, 0.03, 0.025, 0.92), FoundryArt.DANGER if wrong > 0.0 else Color(SmelterStyle.J1, 0.7))
    if typed.is_empty():
        UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 17, "ESCRIBE EL METAL PURO", 18, FoundryArt.MUTED, true)
    else:
        var caret: String = "_" if int(_time * 2.5) % 2 == 0 else " "
        UiDraw.text_centered(self, rect.get_center().x, rect.position.y + 10, typed.to_upper() + caret, 28, FoundryArt.TEXT, true)
    UiDraw.text_centered(self, rect.get_center().x, rect.end.y + 10, "Mena → metal puro: Bauxita→Aluminio · Ilmenita→Titanio · …", 11, FoundryArt.MUTED)
