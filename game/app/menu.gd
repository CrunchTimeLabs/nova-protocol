extends Control
## Menú inicial: Start (secuencia de niveles), Old (flujo anterior), Levels (una lista de niveles), Labs (una lista de features) y Exit.


const BACKGROUND := Color(0.02, 0.03, 0.07)
const MENU_WIDTH := 360.0
const SEPARATION := 12
const LAB_COLUMNS := 3
const BACK_MARGIN := Vector2(16, 16)
## Niveles jugables: [título, ruta de la escena].
const LEVELS: Array = [
	["Recolección", SceneRoutes.COLLECTION_STAGE],
	["Fundición dúo", SceneRoutes.FOUNDRY_DUO_LEVEL],
	["Nave", SceneRoutes.SHIP_BUILD_STAGE],
	["Meteoritos", SceneRoutes.METEOR_MISSION],
	["Análisis", SceneRoutes.ANALYSIS_LEVEL],
]
## Labs de las features: [título, ruta de la escena].
const LABS: Array = [
	["Movement", SceneRoutes.MOVEMENT_LAB],
	["Circuit", SceneRoutes.CIRCUIT_LAB],
	["Resource meter", SceneRoutes.RESOURCE_METER_LAB],
	["Cargo hold", SceneRoutes.CARGO_HOLD_LAB],
	["Drag drop", SceneRoutes.DRAG_DROP_LAB],
	["Fundición", SceneRoutes.FOUNDRY_LAB],
	["Fundición temperatura", SceneRoutes.FUNDICION_TEMPERATURA],
	["Maze", SceneRoutes.MAZE_LAB],
	["Recolección", SceneRoutes.COLLECTION_LAB],
	["Nave", SceneRoutes.SHIP_LAB],
	["Countdown", SceneRoutes.COUNTDOWN_LAB],
	["Precision", SceneRoutes.PRECISION_LAB],
	["Wiring", SceneRoutes.WIRING_LAB],
	["Traffic light", SceneRoutes.TRAFFIC_LIGHT_LAB],
	["Orbit", SceneRoutes.ORBIT_LAB],
	["Split screen", SceneRoutes.MISSION_LOBBY],
]

var _title: Label
var _column: VBoxContainer
var _buttons: GridContainer
var _back: Button


func _ready() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	add_child(StartBackdrop.new())

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", SEPARATION)
	_column.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	center.add_child(_column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 32)
	_column.add_child(_title)

	_buttons = GridContainer.new()
	_buttons.add_theme_constant_override("h_separation", SEPARATION)
	_buttons.add_theme_constant_override("v_separation", SEPARATION)
	_column.add_child(_buttons)

	_back = Button.new()
	_back.text = "Back"
	_back.position = BACK_MARGIN
	_back.pressed.connect(_show_main)
	add_child(_back)

	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _title.text != "NOVA PROTOCOL":
		_show_main()


func _show_main() -> void:
	_show_menu("NOVA PROTOCOL", 1)
	_add_button("Start", _on_start)
	#_add_button("Old", _on_old)
	#_add_button("Levels", _show_levels)
	#_add_button("Labs", _show_labs)
	if not OS.has_feature("web"):          # en navegador no hay a dónde "salir"
		_add_button("Exit", _on_exit)


func _show_levels() -> void:
	_show_menu("LEVELS", 1)
	for entry: Array in LEVELS:
		_add_button(str(entry[0]), SceneRoutes.go_to.bind(get_tree(), str(entry[1])))


func _show_labs() -> void:
	_show_menu("LABS", LAB_COLUMNS)
	for entry: Array in LABS:
		_add_button(str(entry[0]), SceneRoutes.go_to.bind(get_tree(), str(entry[1])))


func _show_menu(title_text: String, columns: int) -> void:
	_title.text = title_text
	_buttons.columns = columns
	_back.visible = title_text != "NOVA PROTOCOL"
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()


func _add_button(text: String, handler: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(handler)
	_buttons.add_child(button)


func _on_start() -> void:
	CampaignState.reset()
	SceneRoutes.go_to(get_tree(), Campaign.first())


func _on_old() -> void:
	SceneRoutes.go_to(get_tree(), SceneRoutes.EXPEDITION_LEVEL)


func _on_exit() -> void:
	get_tree().quit()
