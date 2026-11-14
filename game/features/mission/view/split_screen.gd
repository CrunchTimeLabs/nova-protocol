class_name SplitScreen
extends HBoxContainer
## Reparte la ventana entre las pantallas de los jugadores, una al lado de la otra.


const SEPARATION: int = 8


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    add_theme_constant_override("separation", SEPARATION)


func add_player(title: String, content: Node) -> void:
    var screen: PlayerScreen = PlayerScreen.new()
    add_child(screen)
    screen.setup(title, content)
