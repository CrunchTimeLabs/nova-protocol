class_name HoldScreen
extends Screen
## Nivel 1: arrastrar instrumentos del inventario a la bodega. La masa del motor manda;
## lo que no cabe se rechaza. Arrastrar fuera de la nave lo descarga.


const HEADER := 122.0
const SHIP_ZONE := Rect2(500, 150, 750, 440)
const INFO_BOX := Rect2(30, 604, 440, 100)
const SUMMARY_BOX := Rect2(500, 604, 750, 96)
const ZONE_GROUND := &"ground"
const ZONE_SHIP := &"ship"
const GROUP_NAMES: Dictionary = {
    InstrumentSpec.Group.ANALYZER: "ANALIZADOR",
    InstrumentSpec.Group.SUPPORT: "APOYO",
    InstrumentSpec.Group.SHIP: "NAVE",
}
const GROUP_COLORS: Dictionary = {
    InstrumentSpec.Group.ANALYZER: UiPalette.SCIENCE,
    InstrumentSpec.Group.SUPPORT: UiPalette.OK,
    InstrumentSpec.Group.SHIP: UiPalette.BEACON,
}

var _drag: DragSession
var _shown_mass: float = 0.0
var _time: float = 0.0


func _ready() -> void:
    _drag = DragSession.new(_can_drop)
    make_button("CERRAR ESCOTILLAS", Rect2(size.x - 330, size.y - 54, 290, 44), UiPalette.OK, done)
    _shown_mass = float(expedition.used_mass())


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key.pressed and not key.echo and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
        done()


func _process(delta: float) -> void:
    _time += delta
    update_notices(delta)
    _shown_mass = lerpf(_shown_mass, float(expedition.used_mass()), minf(1.0, delta * 10.0))
    queue_redraw()


func _available() -> Array[InstrumentSpec]:
    var items: Array[InstrumentSpec] = []
    for item: InstrumentSpec in expedition.catalog.instruments:
        if not expedition.has(item.id):
            items.append(item)
    return items


func _inventory_rect(index: int) -> Rect2:
    return Rect2(30 + (index % 2) * 226, 150 + (index / 2) * 56, 212, 50)


func _cargo_rect(index: int) -> Rect2:
    return Rect2(SHIP_ZONE.position.x + 22 + (index % 3) * 236, SHIP_ZONE.position.y + 56 + (index / 3) * 58, 224, 50)


func _gui_input(event: InputEvent) -> void:
    var button: InputEventMouseButton = event as InputEventMouseButton
    if button == null or button.button_index != MOUSE_BUTTON_LEFT:
        return
    if button.pressed:
        _start_drag(button.position)
    elif _drag.is_dragging():
        _drop(button.position)


func _start_drag(at: Vector2) -> void:
    var available: Array[InstrumentSpec] = _available()
    for i: int in available.size():
        if _inventory_rect(i).has_point(at):
            _drag.begin(available[i], ZONE_GROUND)
            sfx.play(Sfx.Sound.CLICK)
            return
    for i: int in expedition.cargo.size():
        if _cargo_rect(i).has_point(at):
            _drag.begin(expedition.catalog.instrument(expedition.cargo.ids()[i]), ZONE_SHIP)
            sfx.play(Sfx.Sound.CLICK)
            return


## Regla del soltado: del suelo a la nave solo si cabe; de la nave al suelo siempre.
func _can_drop(payload: Variant, from_zone: StringName, to_zone: StringName) -> bool:
    var item: InstrumentSpec = payload as InstrumentSpec
    if from_zone == ZONE_GROUND and to_zone == ZONE_SHIP:
        return expedition.can_load(item.id)
    return from_zone == ZONE_SHIP and to_zone == ZONE_GROUND


func _drop(at: Vector2) -> void:
    var item: InstrumentSpec = _drag.payload as InstrumentSpec
    var from_zone: StringName = _drag.from_zone
    var to_zone: StringName = ZONE_SHIP if SHIP_ZONE.has_point(at) else ZONE_GROUND
    var result: DragSession.Result = _drag.drop(to_zone)
    if result == DragSession.Result.ACCEPTED and to_zone == ZONE_SHIP:
        expedition.load_instrument(item.id)
        notify("%s embarcado (%d kg)" % [item.name, item.mass], UiPalette.OK, 1.2)
        sfx.play(Sfx.Sound.LOAD)
        Bursts.burst(self, at, UiPalette.glow(UiPalette.OK, 1.8), 18, 160.0, 0.5, 3.0)
    elif result == DragSession.Result.ACCEPTED:
        expedition.unload_instrument(item.id)
        notify("%s descargado" % item.name, UiPalette.GRAY, 1.0)
        sfx.play(Sfx.Sound.UNLOAD)
    elif from_zone == ZONE_GROUND and to_zone == ZONE_SHIP:
        notify("NO CABE: %s pesa %d kg y solo quedan %d kg" % [item.name, item.mass, expedition.free_mass()], UiPalette.DANGER, 1.8)
        sfx.play(Sfx.Sound.DENIED)
        shake(5.0)


func _hovered(mouse: Vector2) -> InstrumentSpec:
    var available: Array[InstrumentSpec] = _available()
    for i: int in available.size():
        if _inventory_rect(i).has_point(mouse):
            return available[i]
    for i: int in expedition.cargo.size():
        if _cargo_rect(i).has_point(mouse):
            return expedition.catalog.instrument(expedition.cargo.ids()[i])
    return null


func _draw() -> void:
    var mouse: Vector2 = get_local_mouse_position()
    _draw_header()
    UiPalette.text(self, Vector2(30, 126), "INVENTARIO EN TIERRA", UiPalette.SUBTITLE, UiPalette.BORDER, true)
    var available: Array[InstrumentSpec] = _available()
    for i: int in available.size():
        _draw_inventory_card(_inventory_rect(i), available[i], mouse)
    _draw_ship_zone(mouse)
    _draw_info(_hovered(mouse))
    _draw_summary()
    draw_notices(124.0, 1)
    if _drag.is_dragging():
        var dragged: InstrumentSpec = _drag.payload as InstrumentSpec
        var card: Rect2 = Rect2(mouse - Vector2(100, 22), Vector2(200, 44))
        UiPalette.card(self, card, Color(0.18, 0.18, 0.18), UiPalette.glow(UiPalette.BEACON, 1.3), 7)
        UiPalette.wrapped(self, card.position + Vector2(8, 6), "%s (%d kg)" % [dragged.name, dragged.mass], UiPalette.TINY, UiPalette.TEXT, card.size.x - 16.0)


func _draw_header() -> void:
    UiPalette.header(self, HEADER)
    UiPalette.text(self, Vector2(30, 12), "NIVEL 1 — CARGA DE LA NAVE", UiPalette.TITLE, UiPalette.glow(UiPalette.BORDER, 1.2), true)
    UiPalette.text(self, Vector2(32, 48), "Motor asignado: %s — fundido con los %d de metal que sacaste del laberinto" % [
            expedition.engine.name, expedition.amount(Catalog.Res.METAL)], UiPalette.SMALL, UiPalette.WARNING)
    UiPalette.text(self, Vector2(32, 72), "Arrastra con el ratón los instrumentos hasta la nave. Arrástralos fuera para descargarlos.   |   F11 pantalla completa", UiPalette.TINY, UiPalette.GRAY)
    var ratio: float = _shown_mass / maxf(1.0, float(expedition.max_mass()))
    var color: Color = UiPalette.OK if ratio < 0.8 else (UiPalette.WARNING if ratio < 0.999 else UiPalette.DANGER)
    UiPalette.text(self, Vector2(size.x - 420, 14), "MASA  %d / %d kg" % [expedition.used_mass(), expedition.max_mass()], UiPalette.SUBTITLE, color, true)
    UiPalette.bar(self, Rect2(size.x - 420, 44, 380, 20), ratio, color)
    UiPalette.text(self, Vector2(size.x - 420, 70), "libre: %d kg" % expedition.free_mass(), UiPalette.TINY, UiPalette.GRAY)


func _draw_inventory_card(rect: Rect2, item: InstrumentSpec, mouse: Vector2) -> void:
    var fits: bool = item.mass <= expedition.free_mass()
    var hover: bool = rect.has_point(mouse) and not _drag.is_dragging()
    var border: Color = (UiPalette.BORDER if hover else UiPalette.BORDER_DIM) if fits else Color(0.29, 0.29, 0.29)
    UiPalette.card(self, rect, UiPalette.PANEL_ALT if hover else UiPalette.PANEL, border, 7)
    var group_color: Color = GROUP_COLORS[item.group]
    draw_rect(Rect2(rect.position + Vector2(2, 6), Vector2(3, rect.size.y - 12)), UiPalette.glow(group_color, 1.2))
    UiPalette.wrapped(self, rect.position + Vector2(10, 5), item.name, UiPalette.TINY, UiPalette.TEXT if fits else Color(0.52, 0.52, 0.52), rect.size.x - 54.0)
    UiPalette.text(self, Vector2(rect.end.x - 38, rect.position.y + 6), str(item.mass), UiPalette.SMALL, UiPalette.OK if fits else UiPalette.DANGER, true)
    UiPalette.text(self, Vector2(rect.end.x - 38, rect.position.y + 24), "kg", UiPalette.TINY, UiPalette.GRAY)
    UiPalette.text(self, Vector2(rect.position.x + 10, rect.end.y - 15), String(GROUP_NAMES[item.group]), UiPalette.TINY - 1, group_color)


func _draw_ship_zone(mouse: Vector2) -> void:
    var targeted: bool = _drag.is_dragging() and _drag.from_zone == ZONE_GROUND and SHIP_ZONE.has_point(mouse)
    var glow: float = 1.0 + (0.6 + 0.4 * sin(_time * 8.0) if targeted else 0.0)
    UiPalette.panel(self, SHIP_ZONE, UiPalette.glow(UiPalette.BORDER, glow))
    _draw_ship_silhouette(SHIP_ZONE.get_center() + Vector2(0, 30))
    UiPalette.text(self, SHIP_ZONE.position + Vector2(22, 14), "BODEGA DE LA NAVE", UiPalette.SUBTITLE, UiPalette.BORDER, true)
    UiPalette.text(self, Vector2(SHIP_ZONE.end.x - 200, SHIP_ZONE.position.y + 18), "%d elementos embarcados" % expedition.cargo.size(), UiPalette.TINY, UiPalette.GRAY)
    if expedition.cargo.is_empty():
        UiPalette.text_centered(self, SHIP_ZONE.get_center().x, SHIP_ZONE.get_center().y + 150.0, "SUELTA AQUÍ LOS INSTRUMENTOS", UiPalette.SMALL, UiPalette.GRAY, true)
    for i: int in expedition.cargo.size():
        var item: InstrumentSpec = expedition.catalog.instrument(expedition.cargo.ids()[i])
        var rect: Rect2 = _cargo_rect(i)
        var hover: bool = rect.has_point(mouse) and not _drag.is_dragging()
        UiPalette.card(self, rect, Color(0.19, 0.19, 0.19) if hover else Color(0.14, 0.14, 0.14), UiPalette.OK, 7)
        UiPalette.wrapped(self, rect.position + Vector2(8, 7), item.name, UiPalette.TINY, UiPalette.TEXT, rect.size.x - 60.0)
        UiPalette.text(self, Vector2(rect.end.x - 50, rect.position.y + 30), "%d kg" % item.mass, UiPalette.TINY, UiPalette.OK, true)


## Silueta tenue de la nave detrás de la carga.
func _draw_ship_silhouette(center: Vector2) -> void:
    var hull: PackedVector2Array = PackedVector2Array([
            center + Vector2(0, -170), center + Vector2(70, -60), center + Vector2(70, 110),
            center + Vector2(-70, 110), center + Vector2(-70, -60)])
    draw_colored_polygon(hull, Color(0.21, 0.21, 0.21, 0.35))
    draw_polyline(hull + PackedVector2Array([hull[0]]), Color(UiPalette.BORDER_DIM, 0.6), 2.0)
    for side: float in [-1.0, 1.0]:
        var fin: PackedVector2Array = PackedVector2Array([
                center + Vector2(70 * side, 50), center + Vector2(130 * side, 130), center + Vector2(70 * side, 110)])
        draw_colored_polygon(fin, Color(0.19, 0.19, 0.19, 0.35))
    draw_circle(center + Vector2(0, -70), 18.0, Color(UiPalette.BORDER, 0.15))


func _draw_info(item: InstrumentSpec) -> void:
    UiPalette.panel(self, INFO_BOX)
    if item == null:
        UiPalette.wrapped(self, INFO_BOX.position + Vector2(12, 14), "Pasa el ratón sobre un instrumento para leer para qué sirve.", UiPalette.TINY, UiPalette.GRAY, INFO_BOX.size.x - 24.0)
        return
    UiPalette.text(self, INFO_BOX.position + Vector2(12, 10), item.name, UiPalette.SMALL, UiPalette.BORDER, true)
    UiPalette.wrapped(self, INFO_BOX.position + Vector2(12, 32), item.description, UiPalette.TINY, UiPalette.GRAY, INFO_BOX.size.x - 24.0)


func _draw_summary() -> void:
    UiPalette.panel(self, SUMMARY_BOX, UiPalette.WARNING)
    var y: float = SUMMARY_BOX.position.y + 8.0
    var lines: Array[String] = Briefings.ship_summary(expedition)
    for i: int in mini(4, lines.size()):
        UiPalette.text(self, Vector2(SUMMARY_BOX.position.x + 14, y), lines[i], UiPalette.TINY, UiPalette.TEXT)
        y += 16.0
    var warning: String = ""
    var color: Color = UiPalette.WARNING
    if expedition.carried_analyzers().is_empty():
        warning = "SIN NINGÚN ANALIZADOR NO PODRÁS IDENTIFICAR NADA"
        color = UiPalette.DANGER
    elif expedition.phase_seconds() < 4.0:
        warning = "Solo %.1f s de fase por tramo: muy justo para dos cañones y un frente de choque." % expedition.phase_seconds()
    elif not expedition.has("deposito"):
        warning = "Sin Depósito auxiliar la misión termina en el primer planeta."
    if warning != "":
        UiPalette.text(self, Vector2(SUMMARY_BOX.position.x + 14, SUMMARY_BOX.end.y - 22), warning, UiPalette.TINY, color, true)
