class_name StationPanel
extends Node2D
## Vista de la estación: la órbita de la nave y su trayectoria prevista, que calcula en su máquina (D1).
## La trayectoria no es automática: Espacio la recalcula desde el estado actual (como en el laboratorio de órbitas).
## Solo lee la réplica que el cliente mantiene al día.


const FORECAST_STEPS: int = 900
const FORECAST_STEP: float = 1.0 / 60.0
const HUD_MARGIN: Vector2 = Vector2(12, 8)

var _view: OrbitView = OrbitView.new()
var _hud: Label = Label.new()
var _client: MatchClient
var _replica: OrbitMatch
var _has_phase_key: bool = false
var _has_goal: bool = false
var _was_f_pressed: bool = false
var _has_forecast: bool = false
var _was_space_pressed: bool = false


func setup(client: MatchClient) -> void:
    _client = client
    _replica = client.replica as OrbitMatch
    _view.setup(_replica.body, _replica.attractors())
    add_child(_view)
    _hud.position = HUD_MARGIN
    add_child(_hud)
    _hud.text = "Esperando datos de la nave…"
    client.snapshot_applied.connect(_on_snapshot)


## Activa F: mantenerla hace que la nave del piloto haga el salto de fase. Solo lo pide el nivel que lo usa.
func enable_phase_key() -> void:
    _has_phase_key = true


## Muestra la meta (círculo alrededor de la luna) y la distancia a ella. Solo lo pide el nivel que la usa.
func enable_goal() -> void:
    _has_goal = true
    _view.set_goal(OrbitMatch.MOON_CENTER, OrbitMatch.MOON_GOAL_RADIUS)


## Espacio (una vez por pulsación) recalcula la trayectoria. Se lee el teclado directamente: no depende del foco del recuadro.
func _process(_delta: float) -> void:
    var is_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
    if is_pressed and not _was_space_pressed:
        _sync_forecast()
    _was_space_pressed = is_pressed
    if _has_phase_key:
        _send_phase_key()


## Envía el estado de F solo cuando cambia.
func _send_phase_key() -> void:
    var is_held: bool = Input.is_physical_key_pressed(KEY_F)
    if is_held == _was_f_pressed:
        return
    if _client.send_command(OrbitCommand.Kind.PHASE_HOLD, {"on": is_held}, true):
        _was_f_pressed = is_held


func _on_snapshot(_tick: int) -> void:
    if not _has_forecast:
        _sync_forecast()    # la primera vez, para no empezar sin trayectoria
    var hint: String = "Espacio: recalcular trayectoria · Indicaciones al piloto de viva voz"
    if _has_phase_key:
        hint += "\nF (mantener): salto de fase de la nave"
    if _has_goal:
        hint += "\nDistancia a la luna: %.3f (meta: menos de %.2f)" % [_replica.distance_to_moon(), OrbitMatch.MOON_GOAL_RADIUS]
    _hud.text = "Velocidad: %.3f\n%s" % [_replica.body.velocity.length(), hint]


func _sync_forecast() -> void:
    _has_forecast = true
    _view.set_forecast(_replica.body.forecast(FORECAST_STEPS, FORECAST_STEP))
