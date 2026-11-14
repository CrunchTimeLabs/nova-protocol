class_name Screen
extends Control
## Base de todas las pantallas: ocupa la ventana, recibe sus dependencias por `setup`, avisa al
## terminar una sola vez, y trae botones con estilo, avisos flotantes y temblor de pantalla.


signal finished

const NOTICE_SPACING := 26.0

var sfx: Sfx
var stars: Starfield
var expedition: Expedition

var _is_done: bool = false
var _notices: Array[Array] = []     # [texto, color, segundos restantes]


func setup(p_sfx: Sfx, p_stars: Starfield, p_expedition: Expedition) -> Screen:
    sfx = p_sfx
    stars = p_stars
    expedition = p_expedition
    return self


func _init() -> void:
    size = UiPalette.SCREEN
    mouse_filter = Control.MOUSE_FILTER_STOP


## Termina la pantalla (solo cuenta la primera vez).
func done() -> void:
    if _is_done:
        return
    _is_done = true
    finished.emit()


func is_done() -> bool:
    return _is_done


func make_button(label: String, rect: Rect2, color: Color, handler: Callable) -> Button:
    var button: Button = Button.new()
    button.text = label
    button.position = rect.position
    button.size = rect.size
    button.focus_mode = Control.FOCUS_NONE
    UiPalette.style_button(button, color)
    var font_size: int = UiPalette.SUBTITLE
    while font_size > UiPalette.TINY and UiPalette.font(true).get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > rect.size.x - 28.0:
        font_size -= 1
    button.add_theme_font_size_override("font_size", font_size)
    button.pressed.connect(func() -> void:
        if sfx != null:
            sfx.play(Sfx.Sound.CLICK)
        handler.call()
    )
    add_child(button)
    return button


func notify(message: String, color: Color, seconds: float = 1.2) -> void:
    _notices.push_front([message, color, seconds])


func update_notices(delta: float) -> void:
    for notice: Array in _notices:
        notice[2] = float(notice[2]) - delta
    _notices = _notices.filter(func(notice: Array) -> bool: return float(notice[2]) > 0.0)


## Avisos apilados hacia arriba desde `bottom`, centrados, desvaneciéndose al final.
func draw_notices(bottom: float, limit: int = 8) -> void:
    var y: float = bottom
    for notice: Array in _notices.slice(0, limit):
        var color: Color = notice[1]
        color.a = clampf(float(notice[2]) * 3.0, 0.0, 1.0)
        UiPalette.text_centered(self, size.x / 2.0, y, String(notice[0]), UiPalette.SUBTITLE, color, true)
        y -= NOTICE_SPACING


## Sacude la pantalla unos instantes (golpes, despegue).
func shake(_strength: float) -> void:
    pass


func update_shake(_delta: float) -> void:
    pass


static func is_continue_key(event: InputEvent) -> bool:
    var key: InputEventKey = event as InputEventKey
    return key != null and key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER or key.keycode == KEY_SPACE)


## Dirección pedida con flechas o WASD.
static func move_input() -> Vector2:
    var x: float = float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
    var y: float = float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
    return Vector2(x, y)
