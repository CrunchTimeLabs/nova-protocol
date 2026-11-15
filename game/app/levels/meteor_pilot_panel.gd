class_name MeteorPilotPanel
extends Node
## Lado del piloto en el nivel Meteoritos: un `DodgeField` del tamaño real de su recuadro, que maneja con las flechas.
## Sus flechas también se traducen a empuje y se envían al anfitrión como en `PilotPanel`. El vuelo (casco, resultado)
## es local de este lado; si se destruye, avisa al anfitrión (`REPORT_CRASH`). El nivel (`MeteorMission`) recarga con Enter al haber resultado. La estación (tecla F) decide cuándo entra la nave en fase. Aviso de viento solar, fase, casco y tiempo se ofrecen al HUD con `hud_item()`.


## Densidad como el primer planeta del original; sin tiempo límite (0): se gana desde la estación.
const METEOR_DENSITY: float = 1.0
const NO_TIME_LIMIT: float = 0.0
## Viento solar (ondas expansivas); como el original, 0.5.
const SOLAR_WIND: float = 0.5
const FIELD_SEED: int = 7301
const HEARTBEAT_SECONDS: float = 0.25
const HULL_BAR_WIDTH: float = 180.0
const PHASE_BAR_WIDTH: float = 120.0
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
var _phase_bar: MeterBar = MeterBar.new()
var _phase_label: Label = Label.new()
var _time_label: Label = Label.new()
var _wind_label: Label = Label.new()
var _wind_lamp: StatusLamp = StatusLamp.new()
var _backdrop: ShaderBackdrop = ShaderBackdrop.new()
var _has_reported_crash: bool = false
## Mientras dura la presentación del nivel la nave no vuela.
var paused: bool = false
var _rocket: Array[RocketParts.Part] = RocketSprite.parts_from(CampaignState.rocket)
var _build: RocketBuild = RocketBuild.new()


func setup(client: MatchClient, input: InputSource) -> void:
    _client = client
    _input = input
    for part: RocketParts.Part in _rocket:
        _build.place(part)
    _view.ship_painter = _paint_ship
    _view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(_backdrop)
    add_child(_view)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(_message)
    _hull_bar.custom_minimum_size = Vector2(HULL_BAR_WIDTH, 0.0)
    _hud_row.add_theme_constant_override("separation", 16)
    _wind_label.text = "Viento solar"
    _hud_row.add_child(_wind_label)
    _hud_row.add_child(_wind_lamp)
    _phase_label.text = "Fase (F)"
    _phase_bar.custom_minimum_size = Vector2(PHASE_BAR_WIDTH, 0.0)
    _hud_row.add_child(_phase_label)
    _hud_row.add_child(_phase_bar)
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
    var replica: OrbitMatch = _client.replica as OrbitMatch
    var is_flying: bool = not paused and _field.status == DodgeField.Status.RUNNING and replica.outcome == OrbitMatch.Outcome.PLAYING
    var direction: Vector2 = _input.read_direction() if is_flying else Vector2.ZERO
    if is_flying:
        _field.step(delta, direction, replica.phase_held)
    _send_thrust(direction, delta)
    _report_crash()
    _refresh(area)


func _start_run(area: Vector2) -> void:
    _runs += 1
    _field = DodgeField.new(
            area,
            METEOR_DENSITY,
            NO_TIME_LIMIT,
            FIELD_SEED + _runs,
            SOLAR_WIND,
            )
    _apply_rocket_stats()
    _view.setup(_field)
    _hull_bar.setup(_field.hull)
    _phase_bar.setup(_field.phase)


## Los 4 aspectos del cohete armado cambian el vuelo; las piezas base dejan una nave frágil y lenta.
## Durabilidad → casco · Empuje → velocidad · Combustible → carga de fase · Estabilidad → menos viento solar.
func _apply_rocket_stats() -> void:
    var durability: float = float(_build.stat(RocketParts.Stat.DURABILITY))
    var thrust: float = float(_build.stat(RocketParts.Stat.THRUST))
    var fuel: float = float(_build.stat(RocketParts.Stat.FUEL))
    var stability: float = float(_build.stat(RocketParts.Stat.STABILITY))
    var hull_max: float = 35.0 + durability * 1.15
    _field.hull = ResourceMeter.new(hull_max, hull_max)
    _field.speed_scale = 0.72 + thrust * 0.0055
    var phase_max: float = 40.0 + fuel * 1.4
    _field.phase = ResourceMeter.new(phase_max, phase_max)
    _field.wind = SOLAR_WIND * (1.35 - stability * 0.009)


func _paint_ship(canvas: CanvasItem, center: Vector2, in_phase: bool, time: float) -> void:
    var moving: float = 0.6 if _input == null else 0.3 + 0.7 * _input.read_direction().length()
    RocketSprite.draw_sideways(canvas, _rocket, center, 0.4, time, moving, in_phase)


func _send_thrust(direction: Vector2, delta: float) -> void:
    var thrust: Vector2 = OrbitMission.thrust_from_arrows(direction)
    var payload: Dictionary = {"x": thrust.x, "y": thrust.y}
    if _heartbeat.should_send(payload, delta):
        _client.send_command(OrbitCommand.Kind.SET_THRUST, payload)


## Al quedarse sin casco avisa al anfitrión una vez; él decide la derrota de la partida.
func _report_crash() -> void:
    if _field.status != DodgeField.Status.DESTROYED or _has_reported_crash:
        return
    _has_reported_crash = _client.send_command(OrbitCommand.Kind.REPORT_CRASH, {}, true)


func _refresh(area: Vector2) -> void:
    _view.size = area
    _backdrop.size = area
    _wind_lamp.set_ok(not _field.wave_warning)
    _time_label.text = "Tiempo: %d s" % int(_field.elapsed)
    _message.text = _result_text()
    _message.position = (area - _message.size) * 0.5 + MESSAGE_OFFSET


func _result_text() -> String:
    var replica: OrbitMatch = _client.replica as OrbitMatch
    if replica.outcome == OrbitMatch.Outcome.WON:
        return "LA ESTACIÓN LLEGÓ A LA LUNA\nEnter: reintentar"
    if _field.status == DodgeField.Status.DESTROYED:
        return "NAVE DESTRUIDA\nEnter: reintentar"
    if replica.outcome == OrbitMatch.Outcome.LOST:
        return "NAVE PERDIDA EN EL ESPACIO\nEnter: reintentar"
    return ""
