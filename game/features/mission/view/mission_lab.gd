class_name MissionLab
extends Node
## Base de los laboratorios de misión multijugador: arma la sesión según SessionOptions (pantalla dividida por defecto,
## `--lan` para red local), crea la pantalla de cada jugador local cuando recibe su rol y bombea la red cada paso fijo.
## Esc vuelve al menú. Solo compone: las reglas viven en `game/mission/` y el toolkit.


## Si es null se leen de la línea de comandos (`godot ... -- --lan`).
var options: SessionOptions

var _session: MissionSession
var _screen: SplitScreen = SplitScreen.new()
var _status: Label = Label.new()


func _ready() -> void:
    if options == null:
        options = SessionOptions.from_args(OS.get_cmdline_user_args())
    _session = _build_session(options)
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)
    layer.add_child(_screen)
    if _session == null:
        _status.text = "No se pudo abrir la red. Esc: menú"
        layer.add_child(_status)
        return
    _status.text = _mode_text()
    _status.position = Vector2(12, 4)
    layer.add_child(_status)
    for client: MatchClient in _session.clients:
        client.joined.connect(_on_joined.bind(client))
        client.rejected.connect(func(reason: int) -> void: _status.text = "Entrada rechazada (motivo %d)" % reason)


func _physics_process(delta: float) -> void:
    if _session == null:
        return
    _session.poll()
    _session.step(delta)


func _input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
        SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _exit_tree() -> void:
    if _session != null:
        _session.close()


## Las subclases arman la sesión de su misión.
func _build_session(_options: SessionOptions) -> MissionSession:
    return null


## Las subclases devuelven el título y el contenido de la pantalla de un rol, o null si no hay vista.
func _panel_for(_client: MatchClient) -> Node:
    return null


func _title_for(_role: int) -> String:
    return ""


## Las subclases cuya vista está maquetada para un tamaño fijo lo devuelven para que se escale al recuadro; cero: tamaño real.
func _base_size_for(_role: int) -> Vector2:
    return Vector2.ZERO


func _mode_text() -> String:
    if options.mode == SessionOptions.Mode.SPLIT_SCREEN:
        return "Pantalla dividida · Esc: menú"
    if options.is_host:
        return "LAN: anfitrión en el puerto %d · Esc: menú" % options.port
    return "LAN: unido a %s:%d · Esc: menú" % [options.address, options.port]


func _on_joined(_slot: int, role: int, client: MatchClient) -> void:
    var panel: Node = _panel_for(client)
    if panel != null:
        _screen.add_player(_title_for(role), panel, _base_size_for(role))
