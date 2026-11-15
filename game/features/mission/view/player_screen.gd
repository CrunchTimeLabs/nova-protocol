class_name PlayerScreen
extends VBoxContainer
## La pantalla de un jugador: un título y su vista dentro de un SubViewport propio, así cada vista tiene su tamaño
## y sus coordenadas (`get_viewport_rect()` es el de su recuadro). Solo contiene: no decide reglas.


## `base_size` distinto de cero: la vista está maquetada para ese tamaño y se escala para caber en el recuadro
## conservando la proporción. Cero: la vista usa el tamaño real del recuadro.
func setup(title: String, content: Node, base_size: Vector2 = Vector2.ZERO) -> void:
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
    var viewport: SubViewport = SubViewport.new()
    if base_size == Vector2.ZERO:
        add_child(container)
    else:
        var fit: AspectRatioContainer = AspectRatioContainer.new()
        fit.ratio = base_size.x / base_size.y
        fit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        fit.size_flags_vertical = Control.SIZE_EXPAND_FILL
        add_child(fit)
        fit.add_child(container)
        viewport.size_2d_override = Vector2i(base_size)
        viewport.size_2d_override_stretch = true
    container.add_child(viewport)
    viewport.add_child(content)
