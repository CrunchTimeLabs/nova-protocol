extends Control
## Menú inicial: Start, Labs (selección de personaje) y Exit.


signal player_selected(player_id: String)

const BACKGROUND := Color(0.02, 0.03, 0.07)
const MENU_WIDTH := 360.0
const SEPARATION := 12
const PLAYERS: Array[String] = ["jim", "jen", "may", "vla"]

var selected_player: String = ""

var _title: Label
var _column: VBoxContainer
var _buttons: VBoxContainer


func _ready() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

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

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", SEPARATION)
	_column.add_child(_buttons)

	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _title.text != "NOVA PROTOCOL":
		_show_main()


func _show_main() -> void:
	_show_menu("NOVA PROTOCOL")
	_add_button("Start", _on_start)
	_add_button("Labs", _show_labs)
	if not OS.has_feature("web"):          # en navegador no hay a dónde "salir"
		_add_button("Exit", _on_exit)


func _show_labs() -> void:
	_show_menu("LABS")
	for player_id: String in PLAYERS:
		_add_button(player_id, _on_player.bind(player_id))
	_add_button("Back", _show_main)


func _show_menu(title_text: String) -> void:
	_title.text = title_text
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


func _on_player(player_id: String) -> void:
	selected_player = player_id
	player_selected.emit(player_id)


func _on_start() -> void:
	pass    # sin juego todavía: enlazar con SceneRoutes cuando exista


func _on_exit() -> void:
	get_tree().quit()
