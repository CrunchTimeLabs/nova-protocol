extends Node2D
## Laboratorio de órbitas: compone controlador, motor con combustible, fuentes de gravedad y cuerpo. El empuje es relativo al rumbo (W adelante, S atrás, D hacia la derecha del rumbo, A hacia la izquierda; en la órbita inicial, derecha = hacia dentro); Espacio sincroniza la trayectoria prevista; R reinicia; Esc vuelve al menú.
## Mundo normalizado [0, 1]: una estrella en el centro y una luna quieta; la nave arranca en órbita circular alrededor de la estrella.


const STAR_CENTER: Vector2 = Vector2(0.5, 0.5)
const STAR_GM: float = 0.01
const MOON_CENTER: Vector2 = Vector2(0.85, 0.3)
const MOON_GM: float = 0.0008
const ORBIT_RADIUS: float = 0.25
const MAX_ACCELERATION: float = 0.05
const FUEL_CAPACITY: float = 1.0
## Segundos de empuje máximo que dura el depósito completo.
const FULL_BURN_SECONDS: float = 20.0
## Ventana de la predicción: constante, para que sincronizar cueste siempre lo mismo.
const FORECAST_STEPS: int = 900
const FORECAST_STEP: float = 1.0 / 60.0
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _controller: ManualThrustController
var _fuel: ResourceMeter
var _body: DynamicBody
var _view: OrbitView
var _hud: Label
var _start_state: Dictionary


func _ready() -> void:
    _controller = ManualThrustController.new()
    _fuel = ResourceMeter.new(FUEL_CAPACITY, FUEL_CAPACITY)
    var engine: ThrustEngine = ThrustEngine.new(MAX_ACCELERATION, _fuel, FUEL_CAPACITY / FULL_BURN_SECONDS)
    var star: CentralGravity = CentralGravity.new(STAR_CENTER, STAR_GM)
    var moon: CentralGravity = CentralGravity.new(MOON_CENTER, MOON_GM)
    var sources: Array[AccelerationSource] = [star, moon]
    var circular_speed: float = sqrt(STAR_GM / ORBIT_RADIUS)
    _body = DynamicBody.new(
            HeadingThrustController.new(_controller),
            engine,
            sources,
            STAR_CENTER + Vector2(ORBIT_RADIUS, 0.0),
            Vector2(0.0, circular_speed),
            )
    _start_state = _body.snapshot()
    _view = OrbitView.new()
    var attractors: Array[CentralGravity] = [star, moon]
    _view.setup(_body, attractors)
    add_child(_view)
    _sync_forecast()
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    _hud = Label.new()
    _hud.position = HUD_MARGIN
    layer.add_child(_hud)


func _physics_process(delta: float) -> void:
    _controller.set_command(_read_command())
    _body.step(delta)
    _hud.text = "Velocidad: %.3f   combustible: %d%%\nW: adelante · S: frenar · D: hacia dentro · A: hacia fuera · Espacio: sync · R: reiniciar · Esc: menú" % [_body.velocity.length(), roundi(_fuel.ratio() * 100.0)]


func _unhandled_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_SPACE:
            _sync_forecast()
        KEY_R:
            _reset()
        KEY_ESCAPE:
            SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


## Teclas físicas: WASD sirve igual en cualquier distribución de teclado.
func _read_command() -> Vector2:
    var horizontal: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var vertical: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    return Vector2(horizontal, vertical)


func _reset() -> void:
    _body.restore(_start_state)
    _fuel.set_value(FUEL_CAPACITY)
    _view.clear_trail()
    _sync_forecast()


## Muestra a dónde irá el cuerpo desde su estado actual si no empuja más.
func _sync_forecast() -> void:
    _view.set_forecast(_body.forecast(FORECAST_STEPS, FORECAST_STEP))
