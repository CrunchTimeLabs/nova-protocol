class_name ShipBuildStage
extends Control
## Etapa «Nave» de «Start»: el hangar del lab (armar el cohete y despegar). Al llegar a órbita aparece un botón
## «Continuar» que pasa al siguiente nivel; Esc vuelve al menú. Solo compone; las reglas viven en la feature `ship`.


const CONTINUE_TEXT := "Continuar"
const CONTINUE_SIZE := Vector2(200, 52)
const CONTINUE_MARGIN := 24.0

var _continue: Button


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var workshop: ShipWorkshop = ShipWorkshop.new()
    workshop.exit_requested.connect(_on_exit)
    workshop.orbit_reached.connect(_on_orbit_reached)
    add_child(workshop)

    _continue = Button.new()
    _continue.text = CONTINUE_TEXT
    _continue.size = CONTINUE_SIZE
    _continue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, int(CONTINUE_MARGIN))
    _continue.visible = false
    _continue.pressed.connect(_on_continue)
    add_child(_continue)


func _on_orbit_reached() -> void:
    _continue.visible = true


func _on_continue() -> void:
    SceneRoutes.go_to(get_tree(), Campaign.next_after(SceneRoutes.SHIP_BUILD_STAGE))


func _on_exit() -> void:
    SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
