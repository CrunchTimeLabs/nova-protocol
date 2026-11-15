class_name CollectionStage
extends Control
## Etapa «Recolección» de «Start»: el mismo juego del lab (elegir dificultad, cochecito en el laberinto con su tutorial),
## pero al llegar a la salida Enter pasa al siguiente nivel. R genera otro laberinto, Esc vuelve a la dificultad y, desde ahí, al menú.
## Solo compone; las reglas viven en la feature `collection`.


const FIRST_SEED := 1

var _seed_value: int = FIRST_SEED
var _level: CollectionLevel.Level = CollectionLevel.Level.EASY
var _session: CollectionSession
var _current: Control
var _has_seen_intro: bool = false
var _has_seen_cave_in: bool = false


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _show_level_select()


func _show_level_select() -> void:
    if _session != null:
        _has_seen_cave_in = _session.has_seen_cave_in()
    var select: LevelSelect = LevelSelect.new(_level)
    select.chosen.connect(_on_level_chosen)
    select.exit_requested.connect(_on_exit)
    _swap(select)


func _start() -> void:
    var level: CollectionLevel = CollectionLevel.new(_level)
    var run: CollectionRun = CollectionRun.new(CollectionScreen.board_origin(level), level, _seed_value)
    _session = CollectionSession.new(run, not _has_seen_intro, not _has_seen_cave_in)
    _has_seen_intro = true
    var screen: CollectionScreen = CollectionScreen.new(_session)
    screen.can_continue = true
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
    _has_seen_cave_in = _session.has_seen_cave_in()
    _seed_value += 1
    _start()


func _on_continue() -> void:
    SceneRoutes.go_to(get_tree(), Campaign.next_after(SceneRoutes.COLLECTION_STAGE))


func _on_exit() -> void:
    SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)
