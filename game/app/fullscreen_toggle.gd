extends Node
## Alterna pantalla completa con Alt+Enter o F11 (F11 solo llega al juego en escritorio: en web lo
## captura el navegador). Escucha en `_input` para ganar a los controles con foco. Servicio de ventana sin reglas de juego: se registra como autoload.


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var is_alt_enter: bool = key.alt_pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]
	if not is_alt_enter and key.keycode != KEY_F11:
		return
	get_viewport().set_input_as_handled()
	var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
			)
