class_name InfoScreen
extends Screen
## Pantalla fija entre niveles: título, texto y un botón. `extra` dibuja contenido propio debajo del
## texto: recibe (pantalla, caja, y donde acabó el texto). Opcionalmente, un planeta de fondo.


const BOX_MARGIN_X := 140.0
const BOX_TOP := 90.0
const DEFAULT_BOX_HEIGHT := 500.0
const BUTTON_SIZE := Vector2(300, 56)

var title: String = ""
var subtitle: String = ""
var lines: Array[String] = []
var button_text: String = "CONTINUAR"
var color: Color = UiPalette.BORDER
var extra: Callable = Callable()
var box_height: float = DEFAULT_BOX_HEIGHT
var backdrop: PlanetSpec = null
var sound: int = -1


func configure(p_title: String, p_subtitle: String, p_lines: Array[String], p_button: String, p_color: Color) -> InfoScreen:
    title = p_title
    subtitle = p_subtitle
    lines = p_lines
    button_text = p_button
    color = p_color
    return self


func with_extra(drawer: Callable, height: float = DEFAULT_BOX_HEIGHT) -> InfoScreen:
    extra = drawer
    box_height = height
    return self


func with_planet(planet: PlanetSpec) -> InfoScreen:
    backdrop = planet
    return self


## Sonido al aparecer (un `Sfx.Sound`).
func with_sound(sound_id: int) -> InfoScreen:
    sound = sound_id
    return self


func _ready() -> void:
    if backdrop != null:
        var planet: PlanetView = PlanetView.new(backdrop.color, backdrop.dark_color, backdrop.id.hash())
        planet.place(Vector2(size.x - 60.0, size.y - 40.0), 300.0)
        planet.modulate = Color(1.0, 1.0, 1.0, 0.55)
        add_child(planet)
    var button_rect: Rect2 = Rect2(Vector2(size.x / 2.0 - BUTTON_SIZE.x / 2.0, size.y - 104.0), BUTTON_SIZE)
    make_button(button_text, button_rect, color, done)
    if sound >= 0 and sfx != null:
        sfx.play(sound as Sfx.Sound)


func _unhandled_key_input(event: InputEvent) -> void:
    if is_continue_key(event):
        get_viewport().set_input_as_handled()
        if sfx != null:
            sfx.play(Sfx.Sound.CLICK)
        done()


func _draw() -> void:
    var box: Rect2 = Rect2(BOX_MARGIN_X, BOX_TOP, size.x - 2.0 * BOX_MARGIN_X, box_height)
    UiPalette.panel(self, box, color)
    draw_line(box.position + Vector2(20, 0), Vector2(box.end.x - 20, box.position.y), UiPalette.glow(color, 1.8), 3.0)
    var title_size: int = UiPalette.HUGE
    while title_size > UiPalette.SUBTITLE and UiPalette.font(true).get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x > box.size.x - 60.0:
        title_size -= 2
    UiPalette.text_centered(self, box.get_center().x, box.position.y + 30.0, title, title_size, UiPalette.glow(color, 1.25), true)
    if subtitle != "":
        UiPalette.text_centered(self, box.get_center().x, box.position.y + 84.0, subtitle, UiPalette.SUBTITLE, UiPalette.GRAY, true)
    draw_line(Vector2(box.position.x + 50, box.position.y + 116), Vector2(box.end.x - 50, box.position.y + 116), UiPalette.BORDER_DIM, 1.0)
    var y: float = box.position.y + 136.0
    for line: String in lines:
        y = UiPalette.wrapped(self, Vector2(box.position.x + 50, y), line, UiPalette.BODY, UiPalette.TEXT, box.size.x - 100.0) + 7.0
    if extra.is_valid():
        extra.call(self, box, y)
