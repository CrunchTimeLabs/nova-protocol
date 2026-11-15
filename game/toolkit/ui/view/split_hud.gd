class_name SplitHud
extends Control
## HUD básico de pantalla dividida: una franja con tres zonas (izquierda, centro, derecha) para poner encima de los recuadros.
## No conoce ningún juego ni lee dominio: cada nivel le añade `Control` que se actualizan solos.


const HEIGHT: float = 44.0
const MARGIN: int = 12
const SEPARATION: int = 16
const BACKGROUND: Color = Color(0.0, 0.0, 0.0)

var _left: HBoxContainer = _make_zone(BoxContainer.ALIGNMENT_BEGIN)
var _center: HBoxContainer = _make_zone(BoxContainer.ALIGNMENT_CENTER)
var _right: HBoxContainer = _make_zone(BoxContainer.ALIGNMENT_END)


func _init() -> void:
    set_anchors_preset(Control.PRESET_TOP_WIDE)
    offset_bottom = HEIGHT
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var background: ColorRect = ColorRect.new()
    background.color = BACKGROUND
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    var margin: MarginContainer = MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for side: String in ["margin_left", "margin_right"]:
        margin.add_theme_constant_override(side, MARGIN)
    add_child(margin)
    var row: HBoxContainer = HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    margin.add_child(row)
    for zone: HBoxContainer in [_left, _center, _right]:
        row.add_child(zone)


func add_left(item: Control) -> void:
    _left.add_child(item)


func add_center(item: Control) -> void:
    _center.add_child(item)


func add_right(item: Control) -> void:
    _right.add_child(item)


func _make_zone(zone_alignment: BoxContainer.AlignmentMode) -> HBoxContainer:
    var zone: HBoxContainer = HBoxContainer.new()
    zone.alignment = zone_alignment
    zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    zone.add_theme_constant_override("separation", SEPARATION)
    zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return zone
