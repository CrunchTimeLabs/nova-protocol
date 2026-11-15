class_name FoundryDuoLevel
extends Node
## Nivel «Fundición dúo» en pantalla dividida: a la izquierda la fundición (letras), a la derecha la temperatura
## (flechas arriba y abajo; Shift las acelera como ayuda). La temperatura fuera de rango bloquea la fundición; ambos comparten el reloj de la fundición.
## F5 (o ENTER al terminar) reinicia ambos lados; Esc vuelve al menú.
## Compone los componentes de cada lab (no los labs) y le da a la temperatura el arte de la fundición. Sin reglas: viven en FoundryDuo.


const SEED: int = 2026
## Tamaño para el que está maquetada cada pantalla (se escala conservando la proporción); ajustable por lado.
const FOUNDRY_SIZE: Vector2 = Vector2(1024, 640)
const TEMPERATURE_SIZE: Vector2 = Vector2(1024, 640)
const FOUNDRY_TITLE: String = "Fundición — teclea los minerales"
## Reloj de la temperatura (solo presentación): amplía las zonas de los puntos de fusión. Valor (°C) → posición en el arco.
const DIAL_STOP_VALUES: Array[float] = [0.0, 800.0, 1000.0, 1100.0, 1500.0, 1600.0, 1800.0]
const DIAL_STOP_FRACTIONS: Array[float] = [0.0, 0.15, 0.25, 0.6, 0.75, 0.95, 1.0]
const DIAL_MARKS: Array[float] = [0.0, 800.0, 1000.0, 1050.0, 1100.0, 1500.0, 1550.0, 1600.0, 1800.0]
const TEMPERATURE_TITLE: String = "Temperatura — flechas (Shift: más rápido)"

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
    var is_boosted: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    _duo.step(delta, raise - lower, is_boosted)


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
    panel.dial_map = ScaleMap.new(DIAL_STOP_VALUES, DIAL_STOP_FRACTIONS)
    panel.dial_marks = DIAL_MARKS
    panel.shows_progress = false
    panel.waiting_text = "Esperando un mineral…"
    panel.title_text = "TEMPERATURA"
    panel.hint_text = "Flecha arriba: subir · Flecha abajo: bajar · Shift: más rápido · F5 / ENTER: reiniciar · Esc: menú"
    panel.out_of_range_text = "Fundición bloqueada"
