class_name ReceiverPanel
extends Control
## Vista del receptor: un botón por popup vivo en su posición; al hacer clic pide el acierto al anfitrión.
## El contador de aciertos va arriba a la derecha. Solo lee la réplica.


const BUTTON_SIZE: Vector2 = Vector2(72, 36)
const HUD_MARGIN: float = 12.0
const HITS_WIDTH: float = 120.0

var _client: MatchClient
var _buttons: Dictionary = {}    # int (id) -> Button
var _hits: Label = Label.new()
var _time: Label = Label.new()


func setup(client: MatchClient) -> void:
    _client = client
    _time.position = Vector2(HUD_MARGIN, HUD_MARGIN)
    add_child(_time)
    _hits.custom_minimum_size = Vector2(HITS_WIDTH, 0)
    _hits.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(_hits)


func _process(_delta: float) -> void:
    var game: TapMatch = _client.replica as TapMatch
    var area: Vector2 = get_viewport_rect().size
    _hits.position = Vector2(area.x - HITS_WIDTH - HUD_MARGIN, HUD_MARGIN)
    _hits.text = "Aciertos: %d" % game.hits()
    _time.text = "Terminó" if game.is_over() else "Tiempo: %d s" % ceili(game.time_left())
    _sync_buttons(game.targets(), area)


func _sync_buttons(targets: ExpiringSet, area: Vector2) -> void:
    for id: int in _buttons.keys():
        if not targets.has(id):
            (_buttons[id] as Button).queue_free()
            _buttons.erase(id)
    for id: int in targets.ids():
        if _buttons.has(id):
            continue
        var button: Button = Button.new()
        button.text = "¡Click!"
        button.size = BUTTON_SIZE
        button.position = targets.position_of(id) * area - BUTTON_SIZE * 0.5
        button.pressed.connect(_on_pressed.bind(id, button))
        add_child(button)
        _buttons[id] = button


func _on_pressed(id: int, button: Button) -> void:
    button.disabled = true
    _client.send_command(TapCommand.Kind.HIT, {"id": id}, true)
