class_name FlightScreen
extends Screen
## Tramo espacial (o práctica). Simula un `Flight` a 60 Hz y dibuja planeta, peligros, nave y HUD en
## capas: planeta, llama, mundo, efectos y HUD. Avisa con `leg_over(llegó)`; la práctica, con `finished`.


signal leg_over(arrived: bool)

const HUD_HEIGHT := 84.0
const CRUISE_STARS := Vector2(90, 0)
const PHASE_STARS := Vector2(156, 0)
const DESTROYED_PAUSE := 1.6
const ARRIVED_PAUSE := 0.4
const SIDE_NAMES: Dictionary = {
    FlightHazards.Side.TOP: "ARRIBA",
    FlightHazards.Side.BOTTOM: "ABAJO",
    FlightHazards.Side.LEFT: "LA IZQUIERDA",
    FlightHazards.Side.RIGHT: "LA DERECHA",
}

var flight: Flight
var _status: Flight.Status = Flight.Status.RUNNING
var _end_timer: float = 0.0
var _time: float = 0.0
var _hurt_flash: float = 0.0
var _fired: Dictionary = {}       # Laser -> true, para que el disparo suene una vez
var _planet: PlanetView
var _world: Control
var _fx: Node2D
var _hud: Control
var _flame: CPUParticles2D
var _phase_trail: CPUParticles2D


func _init(p_flight: Flight) -> void:
    super._init()
    flight = p_flight


func _ready() -> void:
    if not flight.is_practice:
        _planet = PlanetView.new(flight.planet.color, flight.planet.dark_color, flight.planet.id.hash())
        add_child(_planet)
    _flame = Bursts.stream(UiPalette.glow(Color(0.71, 0.71, 0.71), 2.0), Vector2.LEFT, 60, 260.0, 0.28, 5.0, 14.0)
    add_child(_flame)
    _phase_trail = Bursts.stream(UiPalette.glow(Color(0.78, 0.78, 0.78, 0.8), 1.8), Vector2.LEFT, 80, 200.0, 0.55, 9.0, 8.0)
    _phase_trail.emitting = false
    add_child(_phase_trail)
    _world = _layer(_draw_world)
    _fx = Node2D.new()
    add_child(_fx)
    _hud = _layer(_draw_hud)
    sfx.set_loop(Sfx.Loop.ENGINE, true, -14.0)


func _layer(drawer: Callable) -> Control:
    var layer: Control = Control.new()
    layer.size = size
    layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.draw.connect(drawer)
    add_child(layer)
    return layer


func _physics_process(delta: float) -> void:
    if _status != Flight.Status.RUNNING:
        _end_timer -= delta
        if _end_timer <= 0.0:
            _finish()
        return
    var hull_before: float = expedition.hull.current
    var wants_phase: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)
    _status = flight.step(delta, move_input(), wants_phase)
    if expedition.hull.current < hull_before - 0.001:
        _hurt_flash = minf(1.0, _hurt_flash + 0.25)
    for event: Flight.Event in flight.events:
        _react(event)
    _check_laser_fire()
    match _status:
        Flight.Status.DESTROYED:
            _end_timer = DESTROYED_PAUSE
            sfx.play(Sfx.Sound.EXPLOSION)
            Bursts.burst(_fx, flight.ship, UiPalette.glow(Color(0.68, 0.68, 0.68), 2.4), 90, 420.0, 1.4, 7.0)
            Bursts.burst(_fx, flight.ship, Color(0.88, 0.88, 0.88), 40, 260.0, 1.8, 4.0)
            shake(18.0)
            _flame.emitting = false
        Flight.Status.ARRIVED:
            _end_timer = ARRIVED_PAUSE
            sfx.play(Sfx.Sound.SUCCESS)
        Flight.Status.RUNNING:
            pass


func _finish() -> void:
    if is_done():
        return
    sfx.stop_loops()
    if flight.is_practice:
        done()
    else:
        leg_over.emit(_status == Flight.Status.ARRIVED)
        done()


func _react(event: Flight.Event) -> void:
    match event.kind:
        Flight.EventKind.ROCK_HIT:
            notify("IMPACTO  -%d" % event.quantity, UiPalette.DANGER)
            sfx.play(Sfx.Sound.HIT)
            Bursts.burst(_fx, event.position, Color(0.58, 0.58, 0.58), 26, 240.0, 0.7, 4.0)
            Bursts.burst(_fx, flight.ship, UiPalette.glow(Color(0.74, 0.74, 0.74), 2.0), 14, 160.0, 0.4, 3.0)
            shake(9.0)
        Flight.EventKind.WAVE_HIT:
            notify("FRENTE DE CHOQUE  -%d" % event.quantity, UiPalette.BEACON)
            sfx.play(Sfx.Sound.HIT, 0.8)
            shake(7.0)
        Flight.EventKind.LASER_HIT:
            notify("ALCANZADO POR EL CAÑÓN  -%d" % event.quantity, UiPalette.DANGER)
            sfx.play(Sfx.Sound.EXPLOSION, 1.2)
            Bursts.burst(_fx, flight.ship, UiPalette.glow(Color(0.61, 0.61, 0.61), 2.2), 40, 300.0, 0.7, 4.0)
            shake(14.0)
        Flight.EventKind.PICKUP:
            var color: Color = UiPalette.resource_color(event.res)
            notify("+%d %s" % [event.quantity, String(Catalog.RES_NAMES[event.res]).to_lower()], color, 0.75)
            sfx.play(Sfx.Sound.PICKUP, randf_range(0.95, 1.1))
            Bursts.burst(_fx, event.position, UiPalette.glow(color, 2.2), 20, 180.0, 0.5, 3.0)
        Flight.EventKind.LASER_WARNING:
            notify("CAÑÓN DE LARGO ALCANCE APUNTANDO", UiPalette.DANGER, 1.35)
            sfx.play(Sfx.Sound.LASER_CHARGE)
        Flight.EventKind.WAVE_WARNING:
            notify("FRENTE DE CHOQUE — MANTÉN LA FASE", UiPalette.BEACON, 1.5)
            sfx.play(Sfx.Sound.WAVE)
        Flight.EventKind.FRONT_WARNING:
            notify("RADIACIÓN SOLAR POR %s" % String(SIDE_NAMES[event.side]), UiPalette.WARNING, 1.5)
            sfx.play(Sfx.Sound.ALARM, 1.3, -6.0)
        Flight.EventKind.PHASE_EMPTY:
            notify("CARGA DE FASE AGOTADA", UiPalette.DANGER, 1.8)
            sfx.play(Sfx.Sound.ALARM)


func _check_laser_fire() -> void:
    for laser: FlightHazards.Laser in flight.lasers:
        if laser.is_firing() and not _fired.has(laser):
            _fired[laser] = true
            sfx.play(Sfx.Sound.LASER_FIRE)
            shake(4.0)
    for laser: Variant in _fired.keys():
        if not flight.lasers.has(laser):
            _fired.erase(laser)


func _process(delta: float) -> void:
    _time += delta
    update_notices(delta)
    update_shake(delta)
    _hurt_flash = maxf(0.0, _hurt_flash - delta * 2.0)
    var alive: bool = _status != Flight.Status.DESTROYED
    stars.velocity = PHASE_STARS if flight.in_phase else CRUISE_STARS
    sfx.set_loop(Sfx.Loop.PHASE, flight.in_phase and alive, -4.0)
    var rear: Vector2 = flight.ship + Vector2(-23, 0)
    _flame.position = rear
    _phase_trail.position = rear
    _flame.emitting = alive and not flight.in_phase
    _phase_trail.emitting = alive and flight.in_phase
    if _planet != null:
        _planet.place(Vector2(size.x - 122, 228), 14.0 + 86.0 * flight.progress())
    _world.queue_redraw()
    _hud.queue_redraw()


func _draw_world() -> void:
    var canvas: Control = _world
    for front: FlightHazards.Front in flight.fronts:
        _draw_front(canvas, front)
    for wave: FlightHazards.Wave in flight.waves:
        for ring: Vector2 in [Vector2(0, 5), Vector2(18, 3), Vector2(36, 2)]:
            var radius: float = wave.radius - ring.x
            if radius > 4.0:
                var alpha: float = maxf(0.0, (190.0 - ring.x * 4.0 - wave.radius * 0.08) / 255.0)
                canvas.draw_arc(wave.center, radius, 0.0, TAU, 96, Color(0.8, 0.8, 0.8, alpha), ring.y, true)
    for orb: FlightHazards.Orb in flight.orbs:
        var color: Color = UiPalette.resource_color(orb.res)
        var radius: float = 9.0 + 2.2 * sin(_time * 5.0 + fmod(orb.position.y, 6.28))
        canvas.draw_circle(orb.position, radius, UiPalette.glow(color, 1.5))
        canvas.draw_circle(orb.position, radius * 0.4, UiPalette.glow(Color.WHITE, 1.6))
    for rock: FlightHazards.Rock in flight.rocks:
        var points: PackedVector2Array = Transform2D(rock.spin, rock.position) * rock.outline
        canvas.draw_colored_polygon(points, Color(0.34, 0.34, 0.34))
        var lit: PackedVector2Array = Transform2D(rock.spin, rock.position + Vector2(-2, -2)) * (Transform2D().scaled(Vector2(0.6, 0.6)) * rock.outline)
        canvas.draw_colored_polygon(lit, Color(0.41, 0.41, 0.41))
        canvas.draw_polyline(points + PackedVector2Array([points[0]]), Color(0.52, 0.52, 0.52), 2.0)
    for laser: FlightHazards.Laser in flight.lasers:
        _draw_laser(canvas, laser)
    _draw_ship(canvas)
    if _hurt_flash > 0.0:
        canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.18 * _hurt_flash))


func _draw_front(canvas: Control, front: FlightHazards.Front) -> void:
    var rect: Rect2 = front.rect(Flight.FIELD)
    canvas.draw_rect(rect, Color(0.85, 0.85, 0.85, 0.27))
    canvas.draw_rect(rect, UiPalette.glow(Color(0.93, 0.93, 0.93), 1.3), false, 2.0)
    var step: float = 26.0
    var shift: float = _time * 240.0
    if front.is_horizontal():
        for column: int in range(0, int(size.x), int(step)):
            var x: float = float(column)
            var y: float = rect.get_center().y + 7.0 * sin((x + shift) * 0.05)
            canvas.draw_line(Vector2(x, y), Vector2(x + step / 2.0, y), UiPalette.glow(Color(0.96, 0.96, 0.96), 1.4), 2.0)
    else:
        for row: int in range(0, int(size.y), int(step)):
            var y: float = float(row)
            var x: float = rect.get_center().x + 7.0 * sin((y + shift) * 0.05)
            canvas.draw_line(Vector2(x, y), Vector2(x, y + step / 2.0), UiPalette.glow(Color(0.96, 0.96, 0.96), 1.4), 2.0)


func _draw_laser(canvas: Control, laser: FlightHazards.Laser) -> void:
    var rect: Rect2 = laser.rect(Flight.FIELD)
    if not laser.is_firing():
        var progress: float = laser.charge_ratio()
        var blink: float = 0.5 + 0.5 * sin(_time * (10.0 + progress * 30.0))
        canvas.draw_rect(rect, Color(0.5, 0.5, 0.5, (30.0 + 50.0 * progress) / 255.0 + 0.08 * blink))
        var a: Vector2 = Vector2(0, laser.line) if laser.horizontal else Vector2(laser.line, 0)
        var b: Vector2 = Vector2(size.x, laser.line) if laser.horizontal else Vector2(laser.line, size.y)
        canvas.draw_line(a, b, UiPalette.glow(Color(0.63, 0.63, 0.63), 1.0 + progress), 2.0)
    else:
        canvas.draw_rect(rect, UiPalette.glow(Color(0.95, 0.95, 0.95, 0.85), 1.8))
        canvas.draw_rect(rect.grow(7.0), UiPalette.glow(Color(0.54, 0.54, 0.54), 1.8), false, 5.0)


func _draw_ship(canvas: Control) -> void:
    if _status == Flight.Status.DESTROYED:
        return
    var at: Vector2 = flight.ship
    if flight.invulnerable > 0.0 and not flight.in_phase and int(_time * 15.0) % 2 == 0:
        return
    var body: PackedVector2Array = PackedVector2Array([
            at + Vector2(27, 0), at + Vector2(-6, -14), at + Vector2(-23, -11), at + Vector2(-23, 11), at + Vector2(-6, 14)])
    if flight.in_phase:
        canvas.draw_circle(at - Vector2(60, 0), 26.0, Color(0.68, 0.68, 0.68, 0.12))
        for k: int in [1, 2, 3]:
            canvas.draw_arc(at, 26.0 + float(k) * 9.0, 0.0, TAU, 48, Color(0.8, 0.8, 0.8, (70.0 - float(k) * 16.0) / 255.0), 2.0, true)
        canvas.draw_colored_polygon(body, Color(0.83, 0.83, 0.83, 0.43))
        canvas.draw_polyline(body + PackedVector2Array([body[0]]), UiPalette.glow(Color(0.88, 0.88, 0.88), 1.6), 2.0)
    else:
        canvas.draw_colored_polygon(body, Color(0.92, 0.92, 0.92))
        canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(27, 0), at + Vector2(-6, 14), at + Vector2(-23, 11), at + Vector2(-23, 3)]), Color(0.77, 0.77, 0.77))
        canvas.draw_polyline(body + PackedVector2Array([body[0]]), Color(0.38, 0.38, 0.38), 2.0)
    canvas.draw_circle(at + Vector2(7, 0), 5.0, UiPalette.glow(UiPalette.BORDER, 1.5))


func _draw_hud() -> void:
    var canvas: Control = _hud
    UiPalette.header(canvas, HUD_HEIGHT)
    var title: String = "PRÁCTICA DE PILOTAJE" if flight.is_practice else "TRAMO %d — RUMBO A %s" % [flight.leg, flight.planet.name]
    UiPalette.text(canvas, Vector2(24, 8), title, UiPalette.SUBTITLE, UiPalette.glow(UiPalette.BORDER, 1.2), true)
    UiPalette.text(canvas, Vector2(24, 32), "FLECHAS mover  |  ESPACIO/SHIFT = FASE", UiPalette.SMALL, UiPalette.GRAY)
    var speed: float = expedition.speed() / 60.0
    UiPalette.text(canvas, Vector2(24, 54), "velocidad %.1f / %.1f en fase" % [speed, speed * Expedition.PHASE_BOOST], UiPalette.TINY, UiPalette.GRAY)
    UiPalette.hull_bar(canvas, Rect2(430, 26, 220, 18), expedition.hull.current, float(expedition.max_hull()))

    var seconds: float = flight.phase_seconds_left()
    var phase_color: Color = UiPalette.BEACON
    var phase_label: String = "CARGA DE FASE"
    if flight.in_phase:
        phase_color = UiPalette.glow(Color(0.84, 0.84, 0.84), 1.5)
        phase_label = "EN FASE — INTANGIBLE"
    elif expedition.phase.current <= 0.0:
        phase_color = UiPalette.DANGER
        phase_label = "CARGA DE FASE AGOTADA"
    elif seconds < 1.2:
        phase_color = UiPalette.WARNING
    UiPalette.text(canvas, Vector2(740, 9), phase_label, UiPalette.TINY, phase_color, true)
    UiPalette.bar(canvas, Rect2(740, 26, 200, 18), expedition.phase.current / expedition.max_phase(), phase_color)
    UiPalette.text(canvas, Vector2(740, 50), "%.1f s restantes  (no se recarga)" % seconds, UiPalette.TINY, UiPalette.TEXT)

    var trip_color: Color = flight.planet.color.lightened(0.2)
    UiPalette.text(canvas, Vector2(1030, 9), "TRAYECTO", UiPalette.TINY, UiPalette.GRAY, true)
    UiPalette.bar(canvas, Rect2(1030, 26, 210, 18), flight.progress(), trip_color)
    UiPalette.text(canvas, Vector2(1030, 50), "%d%%" % int(flight.progress() * 100.0), UiPalette.TINY, UiPalette.TEXT)
    if not flight.is_practice:
        UiPalette.resources_row(canvas, Vector2(430, 50), flight.collected, 70.0, "+")
    _draw_notices_on(canvas, size.y - 120.0)
    if flight.is_practice and flight.elapsed < 8.0:
        UiPalette.text_centered(canvas, size.x / 2.0, size.y - 60.0, "Mantén ESPACIO: la fase dura lo que dure la barra.", UiPalette.SUBTITLE, UiPalette.WARNING, true)


## Los avisos van en la capa del HUD para quedar encima del mundo.
func _draw_notices_on(canvas: Control, bottom: float) -> void:
    var y: float = bottom
    for notice: Array in _notices:
        var color: Color = notice[1]
        color.a = clampf(float(notice[2]) * 3.0, 0.0, 1.0)
        UiPalette.text_centered(canvas, size.x / 2.0, y, String(notice[0]), UiPalette.SUBTITLE, color, true)
        y -= NOTICE_SPACING
