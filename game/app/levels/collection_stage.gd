class_name CollectionStage
extends Control
## Etapa «Recolección» de «Start», a dos jugadores en el mismo laberinto: elegir dificultad y conducir los dos
## cochecitos (J1 WASD por la izquierda, J2 IJKL por la derecha). Al terminar, Enter guarda las menas en
## `CampaignState` y pasa al siguiente nivel. R genera otro laberinto, Esc vuelve a la dificultad y, desde
## ahí, al menú. Solo compone; las reglas viven en la feature `collection_duo`.


const FIRST_SEED := 1

var _seed_value: int = FIRST_SEED
var _level: CollectionLevel.Level = CollectionLevel.Level.EASY
var _run: DuoRun
var _current: Control


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _show_level_select()


func _show_level_select() -> void:
    var select: DuoLevelSelect = DuoLevelSelect.new(_level)
    select.chosen.connect(_on_level_chosen)
    select.exit_requested.connect(_on_exit)
    _swap(select)


func _start() -> void:
    _run = DuoRun.new(DuoLevel.new(_level), _seed_value)
    var screen: DuoScreen = DuoScreen.new(_run)
    screen.restart_requested.connect(_on_restart)
    screen.exit_requested.connect(_show_level_select)
    screen.continue_requested.connect(_on_continue)
    _swap(screen)


func _swap(next: Control) -> void:
    if _current != null:
        remove_child(_current)
        _current.queue_free()
    _current = next
    add_child(_current)


func _on_level_chosen(level: CollectionLevel.Level) -> void:
    _level = level
    _seed_value += 1
    _start()


func _on_restart() -> void:
    _seed_value += 1
    _start()


## Las menas de los dos pasan a la campaña (la fundición las usa).
func _on_continue() -> void:
    CampaignState.ores = {}
    for ore: Ores.Ore in Ores.all():
        CampaignState.add_ore(ore, _run.ore_total(ore))
    SceneRoutes.go_to(get_tree(), Campaign.next_after(SceneRoutes.COLLECTION_STAGE))


func _on_exit() -> void:
    SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
