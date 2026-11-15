class_name FoundryDuoLevel
extends Node
## Nivel «Fundición dúo» en pantalla dividida: a la izquierda la fundición (letras), a la derecha la temperatura
## (flechas arriba y abajo). La temperatura fuera de rango bloquea la fundición; ambos comparten el reloj de la fundición.
## F5 (o ENTER al terminar) reinicia ambos lados; Esc vuelve al menú.
## Compone los componentes de cada lab (no los labs) y le da a la temperatura el arte de la fundición. Sin reglas: viven en FoundryDuo.


const SEED: int = 2026
## Tamaño para el que está maquetada cada pantalla (se escala conservando la proporción); ajustable por lado.
const FOUNDRY_SIZE: Vector2 = Vector2(1024, 640)
const TEMPERATURE_SIZE: Vector2 = Vector2(1024, 640)
const FOUNDRY_TITLE: String = "Fundición — teclea los minerales"
const TEMPERATURE_TITLE: String = "Temperatura — flechas arriba y abajo"

var _layer: CanvasLayer = CanvasLayer.new()
var _split: SplitScreen
var _duo: FoundryDuo
var _runs: int = 0


func _ready() -> void:
    add_child(_layer)
    _start()


func _physics_process(delta: float) -> void:
    var raise: float = float(Input.is_physical_key_pressed(KEY_UP))
    var lower: float = float(Input.is_physical_key_pressed(KEY_DOWN))
    _duo.step(delta, raise - lower)


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
        KEY_F5:
            _start()
        KEY_ENTER, KEY_KP_ENTER:
            if _duo.is_over():
                _start()


## Arma de cero los dos lados y los enlaza (mismo azar en cada reinicio de la misma partida).
func _start() -> void:
    _runs += 1
    if _split != null:
        _split.queue_free()
    _split = SplitScreen.new()
    _layer.add_child(_split)
    _duo = FoundryDuo.new(SEED + _runs)

    var foundry: FoundryScreen = FoundryScreen.new()
    foundry.handles_restart = false
    _split.add_player(FOUNDRY_TITLE, foundry, FOUNDRY_SIZE)
    foundry.restart(GameRandom.new(SEED + _runs))
    _duo.bind(foundry.run())

    var temperature: TemperaturePanel = TemperaturePanel.new()
    _style_like_foundry(temperature)
    _split.add_player(TEMPERATURE_TITLE, temperature, TEMPERATURE_SIZE)
    temperature.setup(_duo.temperature)


## La temperatura usa el fondo, la paleta y el tipo de letra de la fundición para verse como el mismo juego.
func _style_like_foundry(panel: TemperaturePanel) -> void:
    panel.background = FoundryArt.texture(FoundryArt.BACKGROUND)
    panel.panel_fill = FoundryArt.GLASS
    panel.panel_edge = FoundryArt.EDGE
    panel.title_color = FoundryArt.TITLE
    panel.text_color = FoundryArt.TEXT
    panel.muted_color = FoundryArt.MUTED
    panel.dial_arc_color = FoundryArt.MUTED
    panel.dial_target_color = Color(FoundryArt.TITLE, 0.6)
    panel.dial_needle_color = FoundryArt.TEXT
    panel.title_text = "TEMPERATURA"
    panel.hint_text = "Flecha arriba: subir · Flecha abajo: bajar · F5 / ENTER: reiniciar · Esc: menú"
    panel.out_of_range_text = "Fundición bloqueada"
