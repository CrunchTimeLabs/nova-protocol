class_name CinematicStage
extends Control
## Etapa de cinemática de «Start»: reproduce una cinemática y, al terminar (o saltarla), pasa al nivel que
## sigue a `route` en la campaña. Cada escena de cinemática pone su `cinematic` y su propia `route`.


@export var cinematic: Cinematics.Id = Cinematics.Id.TO_FOUNDRY
@export var route: String = ""


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var player: CinematicPlayer = CinematicPlayer.new(cinematic)
    player.finished.connect(_on_finished)
    add_child(player)


func _on_finished() -> void:
    SceneRoutes.go_to(get_tree(), Campaign.next_after(route))
