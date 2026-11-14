class_name MissionLobby
extends Control
## Sala de espera de las misiones multijugador: se elige misión y modo (pantalla dividida por defecto) y, para unirse
## por LAN, la IP a mano. Al iniciar crea el laboratorio de la misión en su lugar. Esc vuelve al menú.


enum Mission { ORBIT, CIRCUIT }
enum Mode { SPLIT_SCREEN, LAN_HOST, LAN_JOIN }
## El orden de las opciones del selector de modo: la primera es el valor por defecto.
const MODE_LABELS: Array[String] = ["Pantalla dividida (misma computadora)", "LAN: ser anfitrión", "LAN: unirse"]
const BACKGROUND: Color = Color(0.0, 0.0, 0.0)

var _mission: OptionButton = OptionButton.new()
var _mode: OptionButton = OptionButton.new()
var _address: LineEdit = LineEdit.new()


func _ready() -> void:
    var background: ColorRect = ColorRect.new()
    background.color = BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var center: CenterContainer = CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    column.custom_minimum_size = Vector2(360, 0)
    center.add_child(column)
    var title: Label = Label.new()
    title.text = "Misiones multijugador"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    column.add_child(title)
    _mission.add_item("Órbita: piloto + estación")
    _mission.add_item("Circuito: rotador + intercambiador")
    column.add_child(_mission)
    for label: String in MODE_LABELS:
        _mode.add_item(label)
    column.add_child(_mode)
    _address.placeholder_text = "IP del anfitrión (solo para unirse)"
    _address.text = SessionOptions.LOOPBACK
    _address.visible = false
    column.add_child(_address)
    _mode.item_selected.connect(_on_mode_selected)
    var start: Button = Button.new()
    start.text = "Iniciar"
    start.custom_minimum_size = Vector2(0, 44)
    start.pressed.connect(_on_start)
    column.add_child(start)


func _input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
        SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


## La IP solo importa al unirse por LAN; en pantalla dividida (misma computadora) no hay nada que elegir.
func _on_mode_selected(index: int) -> void:
    _address.visible = index == Mode.LAN_JOIN


func _on_start() -> void:
    var options: SessionOptions = SessionOptions.new()
    match _mode.selected:
        Mode.LAN_HOST:
            options.mode = SessionOptions.Mode.LAN
        Mode.LAN_JOIN:
            options.mode = SessionOptions.Mode.LAN
            options.is_host = false
            options.address = _address.text.strip_edges()
    var lab: MissionLab
    match _mission.selected:
        Mission.CIRCUIT:
            lab = CircuitMissionLab.new()
        _:
            lab = OrbitMissionLab.new()
    lab.options = options
    # El laboratorio pasa a ser la escena actual: así Esc (cambiar de escena) libera el laboratorio y no solo la sala.
    var tree: SceneTree = get_tree()
    tree.root.add_child(lab)
    tree.current_scene = lab
    queue_free()
