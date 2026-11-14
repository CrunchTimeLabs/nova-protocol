class_name PlayerScreen
extends VBoxContainer
## La pantalla de un jugador: un título y su vista dentro de un SubViewport propio, así cada vista tiene su tamaño
## y sus coordenadas (`get_viewport_rect()` es el de su recuadro). Solo contiene: no decide reglas.


func setup(title: String, content: Node) -> void:
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    size_flags_vertical = Control.SIZE_EXPAND_FILL
    var label: Label = Label.new()
    label.text = title
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(label)
    var container: SubViewportContainer = SubViewportContainer.new()
    container.stretch = true
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    add_child(container)
    var viewport: SubViewport = SubViewport.new()
    container.add_child(viewport)
    viewport.add_child(content)
