class_name MeteorMission
extends OrbitMissionLab
## Nivel Meteoritos en pantalla dividida: la misión Órbita (estación a la izquierda) y, a la derecha, el piloto esquiva
## meteoritos en un campo propio. Arriba, un `SplitHud` con lo común: velocidad (izquierda), modo (centro) y casco y tiempo
## (derecha). Pantalla dividida por defecto; `-- --lan` para red local.


var _hud: SplitHud = SplitHud.new()
var _speed: Label = Label.new()


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


func _panel_for(client: MatchClient) -> Node:
    if client.role != OrbitRole.Role.PILOT:
        _hud.add_left(_speed)
        client.snapshot_applied.connect(_on_station_snapshot.bind(client))
        return super._panel_for(client)
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
