class_name MeteorMission
extends OrbitMissionLab
## Gana la estación al cruzar el radio de meta alrededor de la luna; se pierde si el casco o el combustible llegan a cero o la nave sale del mapa. Sin tiempo límite.
## Nivel Meteoritos en pantalla dividida: la misión Órbita (estación a la izquierda) y, a la derecha, el piloto esquiva
## meteoritos en un campo propio. Arriba, un `SplitHud` con lo común: velocidad (izquierda), modo (centro) y casco y tiempo
## (derecha). Pantalla dividida por defecto; `-- --lan` para red local.


## Ritmo de la órbita respecto al normal: menor que 1 hace que la nave recorra la trayectoria más despacio.
const ORBIT_TIME_SCALE: float = 0.3

const OUTCOME_TEXTS: Dictionary = {
    OrbitMatch.Outcome.WON: "¡LLEGASTE A LA LUNA! Enter: reintentar",
    OrbitMatch.Outcome.LOST: "PERDIDOS. Enter: reintentar",
}

var _hud: SplitHud = SplitHud.new()
var _speed: Label = Label.new()
var _outcome: Label = Label.new()
var _was_enter_pressed: bool = false


func _ready() -> void:
    super()
    if _session == null:
        return
    _status.visible = false
    _screen.offset_top = SplitHud.HEIGHT
    var layer: CanvasLayer = CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    layer.add_child(_hud)
    var mode: Label = Label.new()
    mode.text = _mode_text()
    _hud.add_center(mode)
    _hud.add_center(_outcome)


func _build_session(session_options: SessionOptions) -> MissionSession:
    return MissionSession.build(
            session_options,
            func() -> MatchRules: return OrbitMatch.new(ORBIT_TIME_SCALE),
            OrbitMission.roles(),
            OrbitMission.ROLE_ORDER,
            )


func _panel_for(client: MatchClient) -> Node:
    if client.role != OrbitRole.Role.PILOT:
        _hud.add_left(_speed)
        client.snapshot_applied.connect(_on_station_snapshot.bind(client))
        var station: StationPanel = super._panel_for(client) as StationPanel
        station.enable_phase_key()
        station.enable_goal()
        return station
    var pilot: MeteorPilotPanel = MeteorPilotPanel.new()
    # Con un solo teclado (pantalla dividida) el piloto usa las flechas.
    var scheme: InputSource.Scheme = InputSource.Scheme.ARROWS if options.mode == SessionOptions.Mode.SPLIT_SCREEN else InputSource.Scheme.BOTH
    pilot.setup(client, InputSource.new(scheme))
    _hud.add_right(pilot.hud_item())
    return pilot


func _title_for(role: int) -> String:
    if role == OrbitRole.Role.PILOT:
        return "Piloto — esquiva los meteoritos"
    return super._title_for(role)


func _on_station_snapshot(_tick: int, client: MatchClient) -> void:
    _speed.text = "Velocidad: %.3f" % (client.replica as OrbitMatch).body.velocity.length()


## Con resultado (victoria o derrota), Enter recarga el nivel en este lado; el otro lado hace lo mismo con su Enter.
func _process(_delta: float) -> void:
    if _session == null:
        return
    var outcome: OrbitMatch.Outcome = _current_outcome()
    _outcome.text = OUTCOME_TEXTS.get(outcome, "")
    var is_pressed: bool = Input.is_physical_key_pressed(KEY_ENTER)
    if is_pressed and not _was_enter_pressed and outcome != OrbitMatch.Outcome.PLAYING:
        SceneRoutes.go_to(get_tree(), SceneRoutes.METEOR_MISSION)
    _was_enter_pressed = is_pressed


func _current_outcome() -> OrbitMatch.Outcome:
    for client: MatchClient in _session.clients:
        var replica: OrbitMatch = client.replica as OrbitMatch
        if replica.outcome != OrbitMatch.Outcome.PLAYING:
            return replica.outcome
    return OrbitMatch.Outcome.PLAYING
