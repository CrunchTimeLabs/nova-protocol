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
var _replica: OrbitMatch
var _has_forecast: bool = false
var _was_space_pressed: bool = false


func setup(client: MatchClient) -> void:
    _replica = client.replica as OrbitMatch
    _view.setup(_replica.body, _replica.attractors())
    add_child(_view)
    _hud.position = HUD_MARGIN
    add_child(_hud)
    _hud.text = "Esperando datos de la nave…"
    client.snapshot_applied.connect(_on_snapshot)


## Espacio (una vez por pulsación) recalcula la trayectoria. Se lee el teclado directamente: no depende del foco del recuadro.
func _process(_delta: float) -> void:
    var is_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
    if is_pressed and not _was_space_pressed:
        _sync_forecast()
    _was_space_pressed = is_pressed


func _on_snapshot(_tick: int) -> void:
    if not _has_forecast:
        _sync_forecast()    # la primera vez, para no empezar sin trayectoria
    _hud.text = "Velocidad: %.3f\nEspacio: recalcular trayectoria · Indicaciones al piloto de viva voz" % _replica.body.velocity.length()


func _sync_forecast() -> void:
    _has_forecast = true
    _view.set_forecast(_replica.body.forecast(FORECAST_STEPS, FORECAST_STEP))
