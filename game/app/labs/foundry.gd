extends Control
## Laboratorio de Fundición: compone la pantalla de la fundición (FoundryScreen). Las reglas viven en
## FoundryRun; F5 reinicia, ENTER repite al terminar y Esc vuelve al menú.


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var screen: FoundryScreen = FoundryScreen.new()
    screen.exit_requested.connect(_on_exit)
    add_child(screen)


func _on_exit() -> void:
    SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
