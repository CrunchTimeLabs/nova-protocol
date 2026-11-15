class_name ExpeditionLevel
extends Node
## Nivel Expedición: punto de composición. Crea la data, la expedición y el orquestador, y muestra la pantalla de
## cada paso al instante. Sin fondo, sonido ni transiciones. No tiene reglas. Esc vuelve al menú.


var _catalog: Catalog
var _expedition: Expedition
var _flow: MissionFlow
var _sfx: Sfx
var _stars: Starfield
var _holder: Control
var _screen: Screen
var _saved_scale_size: Vector2i
var _saved_scale_mode: Window.ContentScaleMode


func _ready() -> void:
    _fit_window()
    _catalog = Catalog.new()
    _expedition = Expedition.new(_catalog)
    _flow = MissionFlow.new(_expedition)
    _build_world()
    _flow.step_changed.connect(_on_step_changed)
    _flow.start()


## Devuelve la ventana a como estaba para que el menú y los laboratorios no hereden esta configuración.
func _exit_tree() -> void:
    var window: Window = get_window()
    window.content_scale_size = _saved_scale_size
    window.content_scale_mode = _saved_scale_mode


## Las pantallas están maquetadas para UiPalette.SCREEN: se ajusta la ventana al entrar y se restaura al salir.
func _fit_window() -> void:
    var window: Window = get_window()
    _saved_scale_size = window.content_scale_size
    _saved_scale_mode = window.content_scale_mode
    window.content_scale_size = Vector2i(UiPalette.SCREEN)
    window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS


func _build_world() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    add_child(canvas)
    var root: Control = Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.theme = UiPalette.make_theme()
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)

    var background: ColorRect = ColorRect.new()
    background.color = UiPalette.BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(background)

    _stars = Starfield.new()
    add_child(_stars)

    _holder = Control.new()
    _holder.set_anchors_preset(Control.PRESET_FULL_RECT)
    _holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(_holder)

    _sfx = Sfx.new()
    add_child(_sfx)


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    if key.keycode == KEY_ESCAPE:
        SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _on_step_changed(step: MissionFlow.Step) -> void:
    var next: Screen = _screen_for(step)
    next.setup(_sfx, _stars, _expedition)
    _swap(next)


func _screen_for(step: MissionFlow.Step) -> Screen:
    var leg: int = _flow.leg
    match step:
        MissionFlow.Step.INTRO:
            return Briefings.intro()
        MissionFlow.Step.MAZE_BRIEF:
            return Briefings.maze_brief()
        MissionFlow.Step.MAZE:
            var maze: MazeScreen = MazeScreen.new()
            maze.ended.connect(_flow.finish_maze)
            return maze
        MissionFlow.Step.FOUNDRY:
            return Briefings.foundry(_expedition, _flow.maze_end)
        MissionFlow.Step.HOLD:
            return HoldScreen.new()
        MissionFlow.Step.SHIP_READY:
            return Briefings.ship_ready(_expedition)
        MissionFlow.Step.LAUNCH:
            return LaunchScreen.new()
        MissionFlow.Step.PRACTICE_BRIEF:
            return Briefings.practice_brief(_expedition)
        MissionFlow.Step.PRACTICE:
            return FlightScreen.new(Flight.new(_expedition, _expedition.planet(), 0, true))
        MissionFlow.Step.LEG_BRIEF:
            return Briefings.leg_brief(_expedition, leg)
        MissionFlow.Step.LEG:
            var flight: FlightScreen = FlightScreen.new(Flight.new(_expedition, _expedition.planet(), leg, false))
            flight.leg_over.connect(_flow.finish_leg)
            return flight
        MissionFlow.Step.DESTROYED:
            return Briefings.destroyed(_expedition, leg)
        MissionFlow.Step.ARRIVAL:
            return Briefings.arrival(_expedition)
        MissionFlow.Step.ORBIT:
            return OrbitScreen.new(_expedition.planet())
        MissionFlow.Step.NO_JUMP:
            return Briefings.no_jump(_expedition)
        MissionFlow.Step.JUMP_BRIEF:
            return Briefings.jump_brief(_expedition)
        MissionFlow.Step.REPORT:
            return Briefings.report(_expedition, _flow.loss_reason)
    push_error("Expedición: paso sin pantalla %d" % step)
    return Briefings.intro()


## Las pantallas que avisan con su propio resultado (laberinto, tramo) no llaman a advance().
func _uses_own_result(screen: Screen) -> bool:
    return screen is MazeScreen or (screen is FlightScreen and not (screen as FlightScreen).flight.is_practice)


func _swap(next: Screen) -> void:
    if _screen != null:
        _screen.queue_free()
    _screen = next
    _sfx.stop_loops()
    if not _uses_own_result(next):
        next.finished.connect(_flow.advance)
    _holder.add_child(next)
