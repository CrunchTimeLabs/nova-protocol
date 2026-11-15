class_name HalfTutorial
extends Control
## Tutorial de una mitad, encima de su pantalla. Cada jugador cumple el suyo por su cuenta:
## - TYPIST: tabla mena → metal y una práctica: escribir ALUMINIO (la bauxita).
## - HEAT: llevar la aguja a la zona verde (660 °C, aluminio) y mantenerla HOLD segundos (el reloj se ve debajo).
## Al cumplirse dice «¡LISTO!» y espera al compañero; el nivel lo quita cuando los dos terminan.


enum Mode { TYPIST, HEAT }

const HOLD := 1.5
const PRACTICE_WORD := "aluminio"

var mode: Mode
var is_done: bool = false
var typed: String = ""
var _held: float = 0.0
var _time: float = 0.0
var _done_at: float = -1.0
var _temperature: TemperatureState


func _init(p_mode: Mode, temperature: TemperatureState = null) -> void:
    mode = p_mode
    _temperature = temperature


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    size = SmelterStyle.HALF


## Letra del tutorial de quien teclea. Devuelve si se cumplió con ella.
func type_letter(letter: String) -> bool:
    if is_done or mode != Mode.TYPIST:
        return false
    typed += letter
    if not PRACTICE_WORD.begins_with(typed):
        typed = ""
        return false
    if typed == PRACTICE_WORD:
        _complete()
        return true
    return false


func backspace() -> void:
    typed = typed.left(maxi(0, typed.length() - 1))


func _process(delta: float) -> void:
    _time += delta
    if mode == Mode.HEAT and not is_done and _temperature != null:
        _held = _held + delta if _temperature.is_in_range() else 0.0
        if _held >= HOLD:
            _complete()
    queue_redraw()


func _complete() -> void:
    is_done = true
    _done_at = _time


func _draw() -> void:
    var color: Color = SmelterStyle.J1 if mode == Mode.TYPIST else SmelterStyle.J2
    if is_done:
        var box: Rect2 = Rect2(56, 200, 400, 140)
        UiDraw.panel(self, box, Color(0.03, 0.09, 0.05, 0.92), FoundryArt.GOOD)
        UiDraw.text_centered(self, box.get_center().x, box.position.y + 26, "✔ ¡LISTO!", 34, FoundryArt.GOOD, true)
        UiDraw.text_centered(self, box.get_center().x, box.position.y + 84, "Esperando al compañero" + ".".repeat(1 + int(_time * 3.0) % 3), 15, FoundryArt.TEXT, true)
        return
    if mode == Mode.TYPIST:
        _draw_typist(color)
    else:
        _draw_heat(color)


func _draw_typist(color: Color) -> void:
    draw_rect(Rect2(Vector2(0, SmelterStyle.TOP), size - Vector2(0, SmelterStyle.TOP)), Color(0.02, 0.01, 0.01, 0.82))
    var box: Rect2 = Rect2(24, 58, 464, 470)
    UiDraw.panel(self, box, Color(0.06, 0.035, 0.03, 0.96), color)
    UiDraw.text(self, box.position + Vector2(16, 10), "TUTORIAL · JUGADOR 1", 12, FoundryArt.MUTED, true)
    UiDraw.text_centered(self, box.get_center().x, box.position.y + 32, "ESCRIBE EL METAL PURO", 24, color, true)
    UiDraw.text_centered(self, box.get_center().x, box.position.y + 66, "Llega una mena: escribe el metal que se saca de ella", 13, FoundryArt.TEXT)
    var y: float = box.position.y + 96
    for ore: Ores.Ore in Ores.all():
        var highlight: bool = ore == SmelterDuo.PRACTICE_ORE
        if highlight:
            draw_rect(Rect2(box.position.x + 20, y - 6, box.size.x - 40, 40), Color(color, 0.12 + 0.06 * sin(_time * 4.0)))
        SmelterStyle.ore(self, ore, Vector2(box.position.x + 54, y + 13), 1.3)
        UiDraw.text(self, Vector2(box.position.x + 80, y + 4), Ores.ore_name(ore), 16, Ores.color(ore), true)
        UiDraw.text(self, Vector2(box.position.x + 214, y + 4), "→", 16, FoundryArt.MUTED, true)
        UiDraw.text(self, Vector2(box.position.x + 246, y + 4), "%s (%s)" % [Ores.element(ore).to_upper(), Ores.SYMBOLS[ore]], 16, FoundryArt.TEXT, true)
        y += 42.0
    # Práctica: letras que van llenando la palabra.
    var practice: Rect2 = Rect2(box.position.x + 40, box.end.y - 128, box.size.x - 80, 104)
    UiDraw.panel(self, practice, Color(0.04, 0.025, 0.02, 0.95), Color(color, 0.6))
    SmelterStyle.ore(self, SmelterDuo.PRACTICE_ORE, practice.position + Vector2(44, 46), 2.5)
    UiDraw.text(self, practice.position + Vector2(90, 12), "Practica: la bauxita da…", 13, FoundryArt.MUTED, true)
    var letters: String = ""
    for i: int in PRACTICE_WORD.length():
        letters += PRACTICE_WORD[i].to_upper() + " " if i < typed.length() else "_ "
    UiDraw.text(self, practice.position + Vector2(90, 38), letters, 26, FoundryArt.TEXT, true)
    UiDraw.text(self, practice.position + Vector2(90, 76), "Escribe ALUMINIO con el teclado", 12, color, true)


func _draw_heat(color: Color) -> void:
    # Se deja ver el reloj (la práctica es real): cartel arriba y abajo.
    var top: Rect2 = Rect2(16, 50, 480, 86)
    UiDraw.panel(self, top, Color(0.03, 0.04, 0.07, 0.94), color)
    UiDraw.text(self, top.position + Vector2(12, 8), "TUTORIAL · JUGADOR 2", 11, FoundryArt.MUTED, true)
    UiDraw.text_centered(self, top.get_center().x, top.position.y + 24, "LLEVA LA AGUJA A LA ZONA VERDE", 20, color, true)
    UiDraw.text_centered(self, top.get_center().x, top.position.y + 56, "↑ sube · ↓ baja · mantén para ir más rápido", 13, FoundryArt.TEXT)
    var bottom: Rect2 = Rect2(16, 476, 480, 62)
    UiDraw.panel(self, bottom, Color(0.03, 0.04, 0.07, 0.94), color)
    UiDraw.text(self, bottom.position + Vector2(14, 8), "Mantén %.1f s dentro:" % HOLD, 13, FoundryArt.TEXT, true)
    UiDraw.bar(self, Rect2(bottom.position + Vector2(14, 32), Vector2(bottom.size.x - 28, 14)), _held / HOLD, FoundryArt.GOOD, Color(0.1, 0.1, 0.12), Color(0.4, 0.4, 0.45))
    UiDraw.text(self, bottom.position + Vector2(bottom.size.x - 190, 8), "Fuera de rango, J1 no funde", 11, FoundryArt.MUTED)
