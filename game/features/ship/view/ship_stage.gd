class_name ShipStage
extends RefCounted
## Escena del hangar según la fase: el cohete en la plataforma (con sus huecos), despegando con llama,
## y los textos grandes (cuenta atrás, despegue, órbita) y la barra de título.


const TITLE := Color(0.98, 0.78, 0.3)
const TEXT := Color(0.88, 0.9, 1.0)
const HINT := Color(0.65, 0.7, 0.85)
const FLASH := Color(1.0, 0.95, 0.75)
const FADE_IN := 0.6
const ASCENT_DISTANCE := 820.0
const LIFTOFF_TEXT_TIME := 1.2
## La cuenta atrás va a la izquierda del cohete (los paneles ya se han ido).
const COUNTDOWN_X := 250.0


static func draw_rocket(
        canvas: CanvasItem,
        session: HangarSession,
        hover: int,
        flash: Dictionary,
        time: float,
        ascent: float,
        ) -> void:
    var base: Vector2 = ShipWorkshop.ROCKET_BASE
    var scale: float = ShipWorkshop.ROCKET_SCALE
    match session.phase():
        HangarSession.Phase.BUILDING:
            var alpha: float = clampf(session.phase_time / FADE_IN, 0.0, 1.0)
            if alpha < 1.0 and session.build.is_complete():
                base.y += (1.0 - alpha) * 40.0
            RocketView.draw(canvas, session.build, base, scale, true, hover, time)
            for section: int in flash.keys():
                var left: float = float(flash[section])
                if left > 0.0:
                    var rect: Rect2 = RocketView.section_rect(section as RocketParts.Section, base, scale)
                    canvas.draw_rect(rect, Color(FLASH, 0.6 * left / ShipWorkshop.FLASH_TIME))
        HangarSession.Phase.LAUNCHING:
            var lifted: Vector2 = base - Vector2(0.0, ascent * ascent * ASCENT_DISTANCE)
            var left: float = session.countdown()
            if left < 0.6:
                var strength: float = 0.2 if left > 0.0 else 0.6 + 0.4 * minf(1.0, ascent * 4.0)
                var engine: RocketParts.Part = session.build.part_at(RocketParts.Section.PROPULSION) as RocketParts.Part
                RocketView.draw_flame(canvas, lifted, scale, time, strength, engine)
            RocketView.draw(canvas, session.build, lifted, scale, false, -1, time)
        HangarSession.Phase.IN_ORBIT:
            pass


static func draw_hud(canvas: CanvasItem, session: HangarSession, panels: float, time: float, _mouse: Vector2) -> void:
    var size: Vector2 = (canvas as Control).size
    canvas.draw_rect(Rect2(0, 0, size.x, ShipWorkshop.TOP_BAR), Color(0.02, 0.02, 0.06, 0.55 + 0.3 * panels))
    canvas.draw_line(Vector2(0, ShipWorkshop.TOP_BAR), Vector2(size.x, ShipWorkshop.TOP_BAR), Color(TITLE, 0.35), 1.0)
    UiDraw.text(canvas, Vector2(20, 10), "NAVE", 24, TITLE, true)
    UiDraw.text(canvas, Vector2(110, 18), "Arrastra las piezas al cohete", 14, Color(TEXT, panels))
    UiDraw.text(canvas, Vector2(size.x - 250, 20), "R: vaciar    Esc: menú", 12, Color(HINT, panels))
    match session.phase():
        HangarSession.Phase.LAUNCHING:
            var left: float = session.countdown()
            if left > 0.0:
                var number: String = str(ceili(left))
                var beat: float = fmod(left, 1.0)
                var font_size: int = 96 + int(40.0 * beat)
                var spot: Vector2 = Vector2(COUNTDOWN_X, size.y / 2.0)
                canvas.draw_circle(spot, 86.0, Color(0.02, 0.02, 0.06, 0.6))
                canvas.draw_arc(spot, 86.0, -PI / 2.0, -PI / 2.0 + TAU * beat, 48, Color(TITLE, 0.9), 4.0)
                UiDraw.text_centered(canvas, spot.x, spot.y - float(font_size) * 0.62, number, font_size, TITLE, true)
                UiDraw.text_centered(canvas, spot.x, spot.y + 92.0, "CUENTA ATRÁS", 14, TEXT, true)
            elif session.phase_time - HangarSession.COUNTDOWN_TIME < LIFTOFF_TEXT_TIME:
                _big(canvas, size, "¡DESPEGUE!", 48, TITLE)
        HangarSession.Phase.IN_ORBIT:
            var alpha: float = minf(1.0, session.phase_time * 2.0)
            _big(canvas, size, "¡EN ÓRBITA!", 48, Color(TITLE, alpha))
            UiDraw.text_centered(canvas, size.x / 2.0, size.y / 2.0 + 30.0, "Tu cohete llegó al espacio", 16, Color(TEXT, alpha))
        HangarSession.Phase.BUILDING:
            pass


static func _big(canvas: CanvasItem, size: Vector2, text: String, font_size: int, color: Color) -> void:
    var y: float = size.y / 2.0 - float(font_size) * 0.9
    canvas.draw_rect(Rect2(0, y - 18.0, size.x, float(font_size) + 70.0), Color(0.02, 0.02, 0.06, 0.5 * color.a))
    UiDraw.text_centered(canvas, size.x / 2.0 + 3.0, y + 3.0, text, font_size, Color(0, 0, 0, color.a * 0.6), true)
    UiDraw.text_centered(canvas, size.x / 2.0, y, text, font_size, color, true)
