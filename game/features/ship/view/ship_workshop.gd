class_name ShipWorkshop
extends Control
## Hangar: fondo de la plataforma de lanzamiento, paleta de piezas, el cohete en la plataforma y el panel.
## Arrastrar con el ratón (DragSession): soltar cerca del cohete coloca la pieza en su sección; sacar una
## pieza del cohete la quita. ESPACIO o el botón despegan; R vacía; Esc sale. Solo lee la sesión.


signal exit_requested
## El cohete armado llegó a órbita (un nivel puede encadenar la siguiente etapa).
signal orbit_reached

const BACKGROUND := "res://assets/rocket/launch_site.png"
const BACKGROUND_SCALE := 4.0
const ROCKET_BASE := Vector2(520, 578)
const ROCKET_SCALE := 3.0
## Margen alrededor del cohete donde soltar ya cuenta como "en el cohete".
const SNAP_MARGIN := 80.0
const ZONE_PALETTE := &"palette"
const ZONE_ROCKET := &"rocket"
const ZONE_OUTSIDE := &"outside"
const TOP_BAR := 56.0
const TOWER_LIGHT := Vector2(674, 82)
const FLASH_TIME := 0.4
const RETURN_TIME := 0.25
const SHAKE := 6.0
const PANEL_FADE := 2.5

var _session: HangarSession = HangarSession.new()
var _drag: DragSession
var _sfx: ShipSfx
var _smoke: LaunchSmoke = LaunchSmoke.new()
var _time: float = 0.0
var _mouse: Vector2 = Vector2.ZERO
var _drag_part: int = -1
var _flash: Dictionary = {}          # Section -> segundos
## Pieza rechazada que vuelve a su tarjeta: [parte, desde, segundos].
var _returning: Array = []
var _last_beep: int = -1
var _panels: float = 1.0


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    mouse_filter = Control.MOUSE_FILTER_STOP
    _drag = DragSession.new(_accepts)
    _drag.dropped.connect(_on_dropped)
    _sfx = ShipSfx.new()
    add_child(_sfx)
    _session.phase_changed.connect(_on_phase_changed)


## Regla del arrastre: al cohete siempre (va a su sección); fuera solo si salía del cohete (se quita).
func _accepts(_payload: Variant, from_zone: StringName, to_zone: StringName) -> bool:
    return to_zone == ZONE_ROCKET or from_zone == ZONE_ROCKET


func _process(delta: float) -> void:
    _time += delta
    _session.tick(delta)
    _smoke.update(delta)
    for section: int in _flash.keys():
        _flash[section] = maxf(0.0, float(_flash[section]) - delta)
    if not _returning.is_empty():
        _returning[2] = float(_returning[2]) + delta
        if float(_returning[2]) >= RETURN_TIME:
            _returning.clear()
    var is_building: bool = _session.phase() == HangarSession.Phase.BUILDING
    _panels = clampf(_panels + (delta if is_building else -delta) * PANEL_FADE, 0.0, 1.0)
    _update_launch()
    queue_redraw()


func _gui_input(event: InputEvent) -> void:
    var motion: InputEventMouseMotion = event as InputEventMouseMotion
    if motion != null:
        _mouse = motion.position
        return
    var click: InputEventMouseButton = event as InputEventMouseButton
    if click == null or click.button_index != MOUSE_BUTTON_LEFT:
        return
    _mouse = click.position
    if click.pressed:
        _press(click.position)
    elif _drag.is_dragging():
        _drag.drop(ZONE_ROCKET if _snap_area().has_point(click.position) else ZONE_OUTSIDE)


func _unhandled_key_input(event: InputEvent) -> void:
    var key: InputEventKey = event as InputEventKey
    if key == null or not key.pressed or key.echo:
        return
    match key.keycode:
        KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
            _launch()
        KEY_R:
            if _session.can_edit() and not _drag.is_dragging():
                _session.clear()
                _sfx.play(ShipSfx.Sound.REMOVE)
        KEY_ESCAPE:
            exit_requested.emit()


func _press(point: Vector2) -> void:
    if not _session.can_edit() or _drag.is_dragging():
        return
    if _session.build.is_complete() and HangarPanel.BUTTON.has_point(point):
        _launch()
        return
    var part: int = PartsPalette.part_at(point)
    if part != -1:
        _start_drag(part, ZONE_PALETTE)
        return
    for section: RocketParts.Section in RocketParts.sections():
        var placed: int = _session.build.part_at(section)
        if placed != -1 and RocketView.section_rect(section, ROCKET_BASE, ROCKET_SCALE).has_point(point):
            _session.remove(section)
            _start_drag(placed, ZONE_ROCKET)
            return


func _start_drag(part: int, zone: StringName) -> void:
    _drag_part = part
    _drag.begin(part, zone)
    _sfx.play(ShipSfx.Sound.PICK)


func _on_dropped(result: DragSession.Result, payload: Variant, from_zone: StringName, to_zone: StringName) -> void:
    var part: RocketParts.Part = int(payload) as RocketParts.Part
    _drag_part = -1
    match result:
        DragSession.Result.ACCEPTED:
            if to_zone == ZONE_ROCKET:
                _session.place(part)
                var section: RocketParts.Section = RocketParts.section_of(part)
                _flash[section] = FLASH_TIME
                var rect: Rect2 = RocketView.section_rect(section, ROCKET_BASE, ROCKET_SCALE)
                _smoke.sparks(rect.get_center(), PartsPalette.ACCENT)
                _sfx.play(ShipSfx.Sound.SNAP)
                if _session.build.is_complete():
                    _sfx.play(ShipSfx.Sound.READY, -4.0)
            else:
                _sfx.play(ShipSfx.Sound.REMOVE)
        DragSession.Result.REJECTED:
            _returning = [part, _mouse, 0.0]
            _sfx.play(ShipSfx.Sound.DENIED, -6.0)
        DragSession.Result.CANCELLED, DragSession.Result.NOT_DRAGGING:
            if from_zone == ZONE_ROCKET:
                _session.place(part)


func _launch() -> void:
    if _session.launch():
        _last_beep = -1
    elif _session.phase() == HangarSession.Phase.BUILDING:
        _sfx.play(ShipSfx.Sound.DENIED, -6.0)


## Pitidos de la cuenta atrás, encendido, humo y rugido mientras sube.
func _update_launch() -> void:
    if _session.phase() != HangarSession.Phase.LAUNCHING:
        _sfx.set_engine(0.0)
        return
    var left: float = _session.countdown()
    if left > 0.0:
        var second: int = ceili(left)
        if second != _last_beep:
            _last_beep = second
            _sfx.play(ShipSfx.Sound.BEEP)
        if left < 0.6:
            _smoke.billow(ROCKET_BASE, 2, 0.5)
        return
    if _last_beep != 0:
        _last_beep = 0
        _sfx.play(ShipSfx.Sound.IGNITION)
    var ascent: float = _session.ascent()
    _sfx.set_engine(1.0 - ascent * 0.8)
    if ascent < 0.5:
        _smoke.billow(ROCKET_BASE, 6, 1.0 - ascent)


func _on_phase_changed(phase: HangarSession.Phase) -> void:
    match phase:
        HangarSession.Phase.IN_ORBIT:
            _sfx.play(ShipSfx.Sound.ORBIT)
            orbit_reached.emit()
        HangarSession.Phase.BUILDING, HangarSession.Phase.LAUNCHING:
            pass


func _snap_area() -> Rect2:
    return RocketView.bounds(ROCKET_BASE, ROCKET_SCALE).grow(SNAP_MARGIN)


func _draw() -> void:
    var shake: Vector2 = Vector2.ZERO
    var ascent: float = _session.ascent()
    if _session.phase() == HangarSession.Phase.LAUNCHING and _session.countdown() <= 0.0:
        shake = Vector2(sin(_time * 70.0), cos(_time * 53.0)) * SHAKE * (1.0 - ascent)
    draw_set_transform(shake, 0.0, Vector2.ONE)
    var background: Texture2D = RocketView.texture(BACKGROUND)
    draw_texture_rect(background, Rect2(Vector2.ZERO, background.get_size() * BACKGROUND_SCALE), false)
    var blink: float = 0.5 + 0.5 * sin(_time * 3.0)
    draw_circle(TOWER_LIGHT, 6.0 + 4.0 * blink, Color(1.0, 0.2, 0.15, 0.25 * blink))
    _smoke.draw(self)
    ShipStage.draw_rocket(self, _session, _hover_section(), _flash, _time, ascent)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    ShipStage.draw_hud(self, _session, _panels, _time, _mouse)
    if _panels > 0.01:
        draw_set_transform(Vector2((1.0 - _panels) * -40.0, 0.0), 0.0, Vector2.ONE)
        PartsPalette.draw(self, _session.build, PartsPalette.part_at(_mouse) if _drag_part == -1 else -1, _drag_part)
        draw_set_transform(Vector2((1.0 - _panels) * 40.0, 0.0), 0.0, Vector2.ONE)
        HangarPanel.draw(self, _session.build, _time, HangarPanel.BUTTON.has_point(_mouse))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_dragged()


## La pieza que se arrastra (a su tamaño final) o la que vuelve a su tarjeta.
func _draw_dragged() -> void:
    var part: int = _drag_part
    var where: Vector2 = _mouse
    var alpha: float = 0.9
    if part == -1 and not _returning.is_empty():
        part = int(_returning[0])
        var t: float = float(_returning[2]) / RETURN_TIME
        where = (_returning[1] as Vector2).lerp((PartsPalette.card_rects()[part] as Rect2).get_center(), t)
        alpha = 0.9 * (1.0 - t)
    if part == -1:
        return
    var texture: Texture2D = RocketView.part_texture(part as RocketParts.Part)
    var size: Vector2 = Vector2(texture.get_width(), texture.get_height()) * ROCKET_SCALE
    draw_texture_rect(texture, Rect2(where - size / 2.0, size), false, Color(1, 1, 1, alpha))


## Sección que se resalta: la de la pieza arrastrada si está cerca del cohete.
func _hover_section() -> int:
    if _drag_part == -1 or not _snap_area().has_point(_mouse):
        return -1
    return RocketParts.section_of(_drag_part as RocketParts.Part)
