class_name AnalysisLevel
extends "res://app/levels/expedition.gd"
## Nivel Análisis: la fase de exploración planetaria, sola. La nave ya está equipada (equipo fijo) y orbita la Luna:
## una tarjeta por analizador, cada una abre una sesión de análisis. Al continuar, informe y vuelta al menú.
## Reutiliza el mundo del nivel Expedición (ventana, fondo, estrellas, sonido) y sus pantallas; no tiene reglas.


## Analizadores a bordo: espectroscopio (elementos), difractómetro (minerales) y radiómetro (terreno), sin mejoras.
const EQUIPMENT: Array[String] = ["espectroscopio", "difractometro", "radiometro"]


func _ready() -> void:
	_fit_window()
	_catalog = Catalog.new()
	_expedition = Expedition.new(_catalog)
	for instrument_id: String in EQUIPMENT:
		if not _expedition.load_instrument(instrument_id):
			push_error("AnalysisLevel: no cabe %s en la bodega" % instrument_id)
	_build_world()
	_show(OrbitScreen.new(_expedition.planet()), _on_orbit_finished)


func _on_orbit_finished() -> void:
	_show(Briefings.report(_expedition, ""), _go_to_menu)


func _go_to_menu() -> void:
	SceneRoutes.go_to(get_tree(), SceneRoutes.MENU)


func _show(next: Screen, on_finished: Callable) -> void:
	next.setup(_sfx, _stars, _expedition)
	next.finished.connect(on_finished)
	_swap_screen(next)


func _swap_screen(next: Screen) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = next
	_sfx.stop_loops()
	_holder.add_child(next)
