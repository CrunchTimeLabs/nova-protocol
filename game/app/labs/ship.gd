extends Control
## Laboratorio de la nave: armar el cohete arrastrando las piezas y despegar. Solo compone el hangar.


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var workshop: ShipWorkshop = ShipWorkshop.new()
    workshop.exit_requested.connect(_on_exit)
    add_child(workshop)


func _on_exit() -> void:
    SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
