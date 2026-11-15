class_name PatternView
extends Control
## Dibuja un patrón sobre el eje de su analizador: líneas de emisión, bandas de absorción, picos o
## curvas. Solo se redibuja cuando cambia algo, así que puede haber muchas en pantalla.
## `variant` > 0 añade el pequeño ruido de una medida real (las ventanas no son copias exactas).


const RULER_HEIGHT := 14.0

var pattern: PatternSpec
var analyzer: AnalyzerSpec
var show_ruler: bool = false
## Posiciones del patrón de referencia: trazos blancos para comparar la alineación.
var marks: PackedFloat32Array = PackedFloat32Array()
var variant: int = 0
var dimmed: bool = false:
    set(value):
        dimmed = value
        queue_redraw()


func _init(p_pattern: PatternSpec, p_analyzer: AnalyzerSpec, p_show_ruler: bool, p_variant: int = 0) -> void:
    pattern = p_pattern
    analyzer = p_analyzer
    show_ruler = p_show_ruler
    variant = p_variant
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    clip_contents = true


func _draw() -> void:
    var w: int = int(size.x)
    var usable: float = size.y - (RULER_HEIGHT if show_ruler else 0.0)
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 8802 + variant * 31 + pattern.id.length()
    match analyzer.render:
        AnalyzerSpec.Render.SPECTRUM:
            if pattern.shape == PatternSpec.Shape.ABSORPTION:
                _draw_absorption(w, usable)
            else:
                _draw_emission(w, usable, rng)
        AnalyzerSpec.Render.PEAKS, AnalyzerSpec.Render.CURVE:
            _draw_signal(w, usable, rng)
    _draw_marks(usable)
    if show_ruler:
        _draw_ruler(usable)
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.33, 0.33, 0.33), false, 1.0)
    if dimmed:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.03, 0.03, 0.82))


func _x_of(value: float) -> float:
    return (value - analyzer.axis_min) / analyzer.span() * size.x


func _nm_at(column: int, w: int) -> float:
    return analyzer.axis_min + analyzer.span() * float(column) / float(w)


func _draw_absorption(w: int, usable: float) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    var colors: PackedColorArray = PackedColorArray()
    for i: int in w:
        var nm: float = _nm_at(i, w)
        points.append(Vector2(i, 0))
        points.append(Vector2(i, usable))
        colors.append(UiPalette.wavelength_color(nm, 0.30 + 0.70 * PatternSampler.transmittance(pattern, nm)))
    draw_multiline_colors(points, colors, 1.0)


func _draw_emission(w: int, usable: float, rng: RandomNumberGenerator) -> void:
    draw_rect(Rect2(0, 0, w, usable), Color(0.03, 0.03, 0.03))
    var points: PackedVector2Array = PackedVector2Array()
    var colors: PackedColorArray = PackedColorArray()
    for i: int in range(0, w, 2):
        points.append(Vector2(i, 0))
        points.append(Vector2(i, usable))
        colors.append(UiPalette.wavelength_color(_nm_at(i, w), 0.07))
    draw_multiline_colors(points, colors, 2.0)
    for line: Vector2 in pattern.points:
        if line.x < analyzer.axis_min or line.x > analyzer.axis_max:
            continue
        var x: float = _x_of(line.x)
        var noise: float = 1.0 if variant == 0 else rng.randf_range(0.84, 1.0)
        var brightness: float = clampf(line.y * noise, 0.55, 1.0)
        var color: Color = UiPalette.wavelength_color(line.x, brightness)
        var halo: Color = Color(color.r, color.g, color.b, 0.35)
        draw_line(Vector2(x - 4, 0), Vector2(x - 4, usable), halo, 2.0)
        draw_line(Vector2(x + 4, 0), Vector2(x + 4, usable), halo, 2.0)
        draw_line(Vector2(x, 0), Vector2(x, usable), UiPalette.glow(color, 1.0 + brightness * 0.8), 5.0)


func _draw_signal(w: int, usable: float, rng: RandomNumberGenerator) -> void:
    draw_rect(Rect2(0, 0, w, usable), Color(0.04, 0.04, 0.04))
    var values: PackedFloat32Array = PatternSampler.sample(pattern, analyzer, w)
    if variant != 0:
        for i: int in values.size():
            values[i] = minf(1.0, values[i] * rng.randf_range(0.95, 1.05))
    var points: PackedVector2Array = PackedVector2Array()
    var colors: PackedColorArray = PackedColorArray()
    var outline: PackedVector2Array = PackedVector2Array()
    for i: int in w:
        var height: float = values[i] * (usable - 4.0)
        if height > 0.0:
            points.append(Vector2(i, usable - 1.0))
            points.append(Vector2(i, usable - 1.0 - height))
            colors.append(UiPalette.axis_color(float(i) / float(w), 0.22 + 0.78 * values[i]))
        if i % 2 == 0:
            outline.append(Vector2(i, usable - 2.0 - values[i] * (usable - 4.0)))
    if not points.is_empty():
        draw_multiline_colors(points, colors, 1.0)
    if outline.size() > 1:
        draw_polyline(outline, Color(1.0, 1.0, 1.0), 2.2, true)


func _draw_marks(usable: float) -> void:
    for value: float in marks:
        if value < analyzer.axis_min or value > analyzer.axis_max:
            continue
        var x: float = _x_of(value)
        draw_line(Vector2(x, usable - 12.0), Vector2(x, usable - 1.0), Color.WHITE, 2.0)
        draw_line(Vector2(x, 0), Vector2(x, 8), Color(0.8, 0.85, 0.95), 2.0)


func _draw_ruler(usable: float) -> void:
    draw_rect(Rect2(0, usable, size.x, size.y - usable), Color(0.05, 0.05, 0.05))
    var font: Font = UiPalette.font()
    for tick: float in analyzer.ticks:
        var x: float = _x_of(tick)
        draw_line(Vector2(x, usable), Vector2(x, usable + 4.0), Color(0.51, 0.51, 0.51), 1.0)
        var label: String = str(int(tick))
        var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, UiPalette.TINY - 1).x
        var left: float = clampf(x - width / 2.0, 0.0, size.x - width)
        draw_string(font, Vector2(left, usable + 3.0 + font.get_ascent(UiPalette.TINY - 1)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, UiPalette.TINY - 1, Color(0.63, 0.63, 0.63))
