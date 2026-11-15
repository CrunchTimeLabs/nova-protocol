class_name SenderPanel
extends Control
## Vista del emisor: con Espacio pide un popup al anfitrión. Solo ve el tiempo restante.


var _client: MatchClient
var _was_pressed: bool = false
var _label: Label = Label.new()


func setup(client: MatchClient) -> void:
    _client = client
    _label.position = Vector2(12, 12)
    add_child(_label)


## Sondeo con detección de flanco: en pantalla dividida el teclado no llega a cada recuadro por eventos.
func _physics_process(_delta: float) -> void:
    var is_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
    if is_pressed and not _was_pressed:
        _client.send_command(TapCommand.Kind.SPAWN, {}, true)
    _was_pressed = is_pressed
    var game: TapMatch = _client.replica as TapMatch
    if game.is_over():
        _label.text = "Tiempo terminado"
    else:
        _label.text = "ESPACIO: enviar un popup\nTiempo: %d s" % ceili(game.time_left())
