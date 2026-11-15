class_name MeteorPilotPanel
extends Node
## Lado del piloto en el nivel Meteoritos: un `DodgeField` del tamaño real de su recuadro, que maneja con las flechas.
## Sus flechas también se traducen a empuje y se envían al anfitrión como en `PilotPanel`. El vuelo (casco, resultado)
## es local de este lado y no afecta a la estación. Enter reinicia al terminar. Casco y tiempo se ofrecen al HUD con `hud_item()`.


const METEOR_DENSITY: float = 0.5
const METEOR_SECONDS: float = 45.0
const FIELD_SEED: int = 7301
const HEARTBEAT_SECONDS: float = 0.25
const HULL_BAR_WIDTH: float = 180.0
const MESSAGE_OFFSET: Vector2 = Vector2(0.0, -20.0)

var _client: MatchClient
var _input: InputSource
var _view: DodgeView = DodgeView.new()
var _field: DodgeField
var _runs: int = 0
var _heartbeat: CommandHeartbeat = CommandHeartbeat.new(HEARTBEAT_SECONDS)
var _message: Label = Label.new()
var _hud_row: HBoxContainer = HBoxContainer.new()
var _hull_bar: MeterBar = MeterBar.new()
var _time_label: Label = Label.new()
var _was_enter_pressed: bool = false


func setup(client: MatchClient, input: InputSource) -> void:
    _client = client
    _input = input
    add_child(_view)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(_message)
    _hull_bar.custom_minimum_size = Vector2(HULL_BAR_WIDTH, 0.0)
    _hud_row.add_theme_constant_override("separation", 16)
    _hud_row.add_child(_hull_bar)
    _hud_row.add_child(_time_label)


## Casco y tiempo restante, para que el nivel los ponga en su HUD.
func hud_item() -> Control:
    return _hud_row


func _physics_process(delta: float) -> void:
    var area: Vector2 = get_viewport().get_visible_rect().size
    if area.x <= 0.0 or area.y <= 0.0:
        return
    if _field == null or _field.field_size != area:
        _start_run(area)
    var is_flying: bool = _field.status == DodgeField.Status.RUNNING
    var direction: Vector2 = _input.read_direction() if is_flying else Vector2.ZERO
    _field.step(delta, direction)
    _send_thrust(direction, delta)
    _restart_on_enter(area)
    _refresh(area)


func _start_run(area: Vector2) -> void:
    _runs += 1
    _field = DodgeField.new(area, METEOR_DENSITY, METEOR_SECONDS, FIELD_SEED + _runs)
    _view.setup(_field)
    _hull_bar.setup(_field.hull)


func _send_thrust(direction: Vector2, delta: float) -> void:
    var thrust: Vector2 = OrbitMission.thrust_from_arrows(direction)
    var payload: Dictionary = {"x": thrust.x, "y": thrust.y}
    if _heartbeat.should_send(payload, delta):
        _client.send_command(OrbitCommand.Kind.SET_THRUST, payload)


func _restart_on_enter(area: Vector2) -> void:
    var is_pressed: bool = Input.is_physical_key_pressed(KEY_ENTER)
    if is_pressed and not _was_enter_pressed and _field.status != DodgeField.Status.RUNNING:
        _start_run(area)
    _was_enter_pressed = is_pressed


func _refresh(area: Vector2) -> void:
    _view.size = area
    _time_label.text = "Tiempo: %d s" % ceili(maxf(_field.duration - _field.elapsed, 0.0))
    match _field.status:
        DodgeField.Status.ARRIVED:
            _message.text = "METEORITOS ESQUIVADOS\nEnter: reintentar"
        DodgeField.Status.DESTROYED:
            _message.text = "NAVE DESTRUIDA\nEnter: reintentar"
        DodgeField.Status.RUNNING:
            _message.text = ""
    _message.position = (area - _message.size) * 0.5 + MESSAGE_OFFSET
