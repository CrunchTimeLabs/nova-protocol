class_name Briefings
extends RefCounted
## Las pantallas de información de la campaña: qué dicen y qué dibujan debajo del texto.
## Solo leen la expedición; las reglas siguen en el dominio.


static func intro() -> InfoScreen:
    var lines: Array[String] = [
        "Empiezas sin nada. Un cochecito, un laberinto y una batería que se agota.",
        "Con el metal que saques se funde tu motor. El motor decide cuánta masa puedes subir. La masa decide qué instrumentos llevas. Los instrumentos deciden qué puedes sobrevivir y qué puedes medir.",
        "Arriba te espera el espectroscopio: comparar el patrón de laboratorio que llevas en la mano con la lectura real del planeta es la única forma de saber de qué está hecho.",
        "F11 en cualquier momento para pantalla completa.",
    ]
    return InfoScreen.new().configure(
            "PROGRAMA DE EXPLORACIÓN",
            "Objetivo: averiguar qué hay en cada planeta",
            lines,
            "JUGAR",
            UiPalette.OK,
            )


static func maze_brief() -> InfoScreen:
    var lines: Array[String] = [
        "Justo delante de la entrada hay una chatarra de acero: con eso solo ya se puede fundir un cohete mínimo y salir al espacio, aunque será una nave que da problemas.",
        "Dentro del laberinto hay más vetas. En cada una puedes recoger tal cual pulsando E, o arriesgarte con la extracción de precisión pulsando ESPACIO: una broca oscila a toda velocidad y la paras con otro ESPACIO. Cuanto más al centro, hasta el triple de material.",
        "Tienes %d segundos de batería. La extracción de precisión consume 4 segundos cada vez: no te da tiempo a hacerla en todas." % int(Catalog.MAZE_BATTERY),
        "Cuando quieras despegar, lleva el cochecito a la rampa verde de la derecha.",
    ]
    return InfoScreen.new().configure(
            "NIVEL 0 — RECOLECCIÓN EN LA TIERRA",
            "Laberinto de la cantera",
            lines,
            "BAJAR A LA CANTERA",
            UiPalette.WARNING,
            )


static func foundry(expedition: Expedition, maze_end: MazeRun.End) -> InfoScreen:
    var subtitle: String = "Se agotó la batería del cochecito" if maze_end == MazeRun.End.BATTERY else "Saliste por la rampa con tiempo de sobra"
    var lines: Array[String] = [
        "Esto es lo que entró en la fundición y este es el motor que salió. Ahora te dan una nave básica para el despegue: lo que decidas cargar en ella es lo único que tendrás ahí arriba.",
    ]
    var engine: EngineSpec = expedition.engine
    var drawer: Callable = func(canvas: Control, box: Rect2, top: float) -> void:
        var y: float = top + 10.0
        for res: int in [Catalog.Res.METAL, Catalog.Res.CRYSTAL, Catalog.Res.FUEL]:
            canvas.draw_circle(Vector2(box.position.x + 56, y + 10), 7.0, UiPalette.glow(UiPalette.resource_color(res), 1.4))
            UiPalette.text(canvas, Vector2(box.position.x + 74, y), str(expedition.amount(res)), UiPalette.SUBTITLE, UiPalette.TEXT, true)
            UiPalette.text(canvas, Vector2(box.position.x + 140, y + 3), String(Catalog.RES_NAMES[res]), UiPalette.SMALL, UiPalette.GRAY)
            y += 30.0
        y += 10.0
        UiPalette.text(canvas, Vector2(box.position.x + 50, y), engine.name, UiPalette.TITLE, UiPalette.glow(UiPalette.WARNING, 1.3), true)
        UiPalette.text(canvas, Vector2(box.position.x + 50, y + 36), "Carga útil: %d kg" % engine.max_mass, UiPalette.SUBTITLE, UiPalette.OK, true)
        UiPalette.wrapped(canvas, Vector2(box.position.x + 50, y + 66), engine.description, UiPalette.BODY, UiPalette.GRAY, box.size.x - 100.0)
    return InfoScreen.new().configure(
            "FUNDICIÓN COMPLETADA",
            subtitle,
            lines,
            "PASAR A LA BODEGA",
            UiPalette.WARNING,
            ).with_extra(drawer).with_sound(Sfx.Sound.SUCCESS)


static func ship_summary(expedition: Expedition) -> Array[String]:
    var summary: Array[String] = [
        "Motor            : %s (%d kg de carga útil)" % [expedition.engine.name, expedition.max_mass()],
        "Masa embarcada   : %d / %d kg" % [expedition.used_mass(), expedition.max_mass()],
        "Integridad       : %d" % expedition.max_hull(),
        "Carga de fase    : %d (-%d/s) = %.1f s de intangibilidad por tramo, sin recarga" % [
                int(expedition.max_phase()), int(expedition.phase_drain()), expedition.phase_seconds()],
        "Velocidad        : %.1f base, %.1f en fase" % [expedition.speed() / 60.0, expedition.speed() * Expedition.PHASE_BOOST / 60.0],
    ]
    var carried: Array[AnalyzerSpec] = expedition.carried_analyzers()
    if carried.is_empty():
        summary.append("SIN NINGÚN ANALIZADOR NO PUEDES CUMPLIR EL OBJETIVO DE LA MISIÓN")
    else:
        var names: PackedStringArray = PackedStringArray()
        for spec: AnalyzerSpec in carried:
            names.append(spec.category)
        summary.append("Analizadores (%d): %s" % [carried.size(), ", ".join(names)])
        summary.append("Análisis por instrumento y planeta: %d" % expedition.analyses_per_instrument())
    if expedition.radiation_mitigation() > 0.0:
        summary.append("Blindaje antirradiación activo (-50 % de daño)")
    if expedition.magnet_radius() > 0.0:
        summary.append("Colector electrostático: %d px" % int(expedition.magnet_radius()))
    if expedition.pickup_factor() > 1:
        summary.append("Bodega de muestras: recolección x2")
    return summary


static func ship_ready(expedition: Expedition) -> InfoScreen:
    var lines: Array[String] = ["Masa final: %d de %d kg." % [expedition.used_mass(), expedition.max_mass()]]
    var summary: Array[String] = ship_summary(expedition)
    var drawer: Callable = func(canvas: Control, box: Rect2, top: float) -> void:
        var y: float = top + 8.0
        for line: String in summary:
            UiPalette.text(canvas, Vector2(box.position.x + 50, y), line, UiPalette.BODY, UiPalette.TEXT)
            y += 23.0
    return InfoScreen.new().configure(
            "NAVE LISTA",
            "Escotillas cerradas, ya no se puede cambiar nada",
            lines,
            "DESPEGAR",
            UiPalette.OK,
            ).with_extra(drawer)


static func practice_brief(expedition: Expedition) -> InfoScreen:
    var lines: Array[String] = [
        "FLECHAS o WASD para moverte en las dos direcciones.",
        "ESPACIO o SHIFT MANTENIDO activa la FASE. Mientras la mantengas eres intangible: los escombros, los cañones, los frentes de choque y la radiación te atraviesan sin hacerte nada. Además empujas un 80 % más rápido.",
        "LA BARRA NO SE RECARGA. Tienes %.1f segundos de fase para todo el tramo y lo que gastes no vuelve. Esa es la decisión del nivel: en qué medio segundo la usas." % expedition.phase_seconds(),
        "La carga se repone entera al empezar cada tramo nuevo, no durante.",
        "Aquí no hay daño ni gasto real: prueba los mandos tranquilo.",
    ]
    return InfoScreen.new().configure(
            "FUERA DE LA ATMÓSFERA",
            "Tramo de práctica",
            lines,
            "PROBAR LOS MANDOS",
            UiPalette.BORDER,
            )


static func leg_brief(expedition: Expedition, leg: int) -> InfoScreen:
    var planet: PlanetSpec = expedition.planet()
    var lines: Array[String] = [
        "Duración estimada del tramo: %d s. Densidad de escombros x%.2f, radiación solar x%.2f." % [int(planet.travel_seconds), planet.density, planet.radiation],
        "CAÑONES DE LARGO ALCANCE: una franja roja marca la línea de tiro durante 1.7 s y después dispara. Salir de la franja a velocidad normal casi nunca da tiempo: o esquivas con antelación o entras en fase justo en el medio segundo del disparo.",
        "FRENTES DE CHOQUE: anillos que se expanden desde un punto y avanzan más rápido que tu velocidad de crucero.",
        "RADIACIÓN SOLAR: bandas que entran por cualquiera de los cuatro bordes y barren la pantalla. Hacen daño mientras estés dentro.",
        "Llevas %.1f segundos de fase para los %d segundos que dura el tramo, y no se recargan. Gastarlos en un meteorito suelto es regalar el segundo que te hará falta cuando cargue el cañón." % [expedition.phase_seconds(), int(planet.travel_seconds)],
        "Recoge los orbes de color: son los recursos que te harán falta para el salto al siguiente planeta.",
    ]
    return InfoScreen.new().configure(
            "TRAMO %d — RUMBO A %s" % [leg, planet.name],
            "A partir de aquí el daño es real",
            lines,
            "ADELANTE",
            UiPalette.DANGER,
            ).with_planet(planet)


static func destroyed(expedition: Expedition, leg: int) -> InfoScreen:
    var lines: Array[String] = [
        "La integridad llegó a cero antes de alcanzar el destino.",
        "Daño por meteoritos: %d.  Por cañones: %d.  Por radiación: %d." % [expedition.damage_rocks, expedition.damage_laser, int(expedition.damage_radiation)],
        "Más casco, más celdas de fase o un blindaje habrían cambiado el resultado, pero cada uno de ellos pesa y la masa salía del metal del laberinto.",
    ]
    return InfoScreen.new().configure(
            "NAVE DESTRUIDA",
            "Tramo %d" % leg,
            lines,
            "VER INFORME",
            UiPalette.DANGER,
            ).with_sound(Sfx.Sound.FAILURE)


static func arrival(expedition: Expedition) -> InfoScreen:
    var planet: PlanetSpec = expedition.planet()
    var lines: Array[String] = [
        "Integridad al llegar: %d de %d." % [int(maxf(0.0, expedition.hull.current)), expedition.max_hull()],
        "Llevas %d analizador(es) y cada uno trae %d análisis para este planeta: %d medidas en total." % [
                expedition.carried_analyzers().size(), expedition.analyses_per_instrument(), expedition.ledger.total_analyses_left(planet.id)],
        "Cada instrumento abre su propio minijuego. Eliges un patrón de laboratorio y el aparato te devuelve seis ventanas de medida hechas con el mismo detector: se parecen a propósito y solo una cae exactamente donde el patrón.",
        "Puede que ninguna coincida, porque ese patrón quizá no esté aquí. Declarar correctamente una ausencia también vale ciencia.",
    ]
    return InfoScreen.new().configure(
            "INSERCIÓN ORBITAL EN %s" % planet.name,
            "Nivel 3 — análisis",
            lines,
            "DESPLEGAR INSTRUMENTOS",
            planet.color.lightened(0.2),
            ).with_planet(planet).with_sound(Sfx.Sound.SUCCESS)


static func no_jump(expedition: Expedition) -> InfoScreen:
    var lines: Array[String] = [
        expedition.travel_block_reason(),
        "CONSECUENCIA: el combustible se recoge en los orbes naranjas durante el vuelo y el depósito se embarca en la bodega. Las dos decisiones se tomaron hace mucho rato.",
    ]
    return InfoScreen.new().configure(
            "FIN DE LA MISIÓN",
            "No hay salto hacia %s" % expedition.next_planet().name,
            lines,
            "VER INFORME",
            UiPalette.WARNING,
            )


static func jump_brief(expedition: Expedition) -> InfoScreen:
    var next: PlanetSpec = expedition.next_planet()
    var lines: Array[String] = [
        "Tienes %d de combustible y el salto cuesta %d." % [expedition.amount(Catalog.Res.FUEL), next.fuel_cost],
        next.summary,
        "El tramo es más largo, los escombros más densos y la radiación más intensa. Vuelve a recoger orbes por el camino: los azules son cristal, los grises metal y los naranjas combustible.",
    ]
    return InfoScreen.new().configure(
            "SALTO A %s" % next.name,
            "Nivel 4 — segundo tramo",
            lines,
            "ENCENDER MOTORES",
            next.color.lightened(0.2),
            ).with_planet(next)


static func grade_label(grade: AnalysisLedger.Grade) -> String:
    match grade:
        AnalysisLedger.Grade.A_PLUS:
            return "A+ — Composición caracterizada"
        AnalysisLedger.Grade.A:
            return "A — Misión científica exitosa"
        AnalysisLedger.Grade.B:
            return "B — Resultados sólidos"
        AnalysisLedger.Grade.C:
            return "C — Reconocimiento preliminar"
        AnalysisLedger.Grade.D:
            return "D — Datos anecdóticos"
        AnalysisLedger.Grade.F:
            return "F — No sabemos qué hay allí"
    return ""


static func grade_color(grade: AnalysisLedger.Grade) -> Color:
    match grade:
        AnalysisLedger.Grade.A_PLUS, AnalysisLedger.Grade.A, AnalysisLedger.Grade.B:
            return UiPalette.OK
        AnalysisLedger.Grade.C, AnalysisLedger.Grade.D:
            return UiPalette.WARNING
        AnalysisLedger.Grade.F:
            return UiPalette.DANGER
    return UiPalette.TEXT


static func report(expedition: Expedition, loss_reason: String) -> InfoScreen:
    var grade: AnalysisLedger.Grade = expedition.ledger.grade()
    var color: Color = grade_color(grade)
    var lines: Array[String] = []
    if loss_reason != "":
        lines.append(loss_reason)
    lines.append("Objetivo de la campaña: saber qué hay en cada planeta. Esto es lo que quedó demostrado con medidas propias, instrumento por instrumento.")
    var catalog: Catalog = expedition.catalog
    var drawer: Callable = func(canvas: Control, box: Rect2, top: float) -> void:
        var y: float = top + 4.0
        for planet: PlanetSpec in catalog.planets:
            var total: Vector2i = expedition.ledger.coverage(planet.id)
            UiPalette.text(canvas, Vector2(box.position.x + 46, y), "%s  —  %d/%d hallazgos" % [planet.name, total.x, total.y], UiPalette.SUBTITLE, planet.color.lightened(0.25), true)
            y += 24.0
            for spec: AnalyzerSpec in expedition.carried_analyzers():
                var ids: Array[String] = expedition.ledger.discovered(planet.id, spec.id)
                var part: Vector2i = expedition.ledger.coverage(planet.id, spec.id)
                var names: PackedStringArray = PackedStringArray()
                for pattern_id: String in ids:
                    names.append(spec.pattern(pattern_id).name)
                var found: String = ", ".join(names) if not ids.is_empty() else "sin datos"
                var line: String = "   %-11s %d/%d  %s" % [spec.category, part.x, part.y, found]
                UiPalette.text(canvas, Vector2(box.position.x + 46, y), line.left(80), UiPalette.TINY, UiPalette.TEXT if not ids.is_empty() else UiPalette.GRAY)
                y += 17.0
            if expedition.carried_analyzers().is_empty():
                UiPalette.text(canvas, Vector2(box.position.x + 46, y), "   sin analizadores embarcados", UiPalette.TINY, UiPalette.GRAY)
                y += 17.0
            y += 8.0
        var stats: Array = [
            ["Ciencia total", "%d pts" % expedition.ledger.science],
            ["Analizadores embarcados", "%d de %d" % [expedition.carried_analyzers().size(), catalog.analyzers.size()]],
            ["Extracciones perfectas", "%d de %d" % [expedition.perfect_veins, expedition.veins_taken]],
            ["Orbes recogidos en vuelo", str(expedition.orbs_taken)],
            ["Análisis fallidos", str(expedition.ledger.failures)],
            ["Daño por radiación", str(int(expedition.damage_radiation))],
            ["Daño por cañones", str(expedition.damage_laser)],
        ]
        var stats_y: float = top + 4.0
        for row: Array in stats:
            UiPalette.text(canvas, Vector2(box.position.x + 690, stats_y), String(row[0]), UiPalette.TINY, UiPalette.GRAY)
            UiPalette.text(canvas, Vector2(box.position.x + 880, stats_y), String(row[1]), UiPalette.TINY, UiPalette.TEXT, true)
            stats_y += 20.0
        UiPalette.wrapped(canvas, Vector2(box.position.x + 690, stats_y + 18.0), grade_label(grade), UiPalette.TITLE - 4, UiPalette.glow(color, 1.3), 290.0)
    return InfoScreen.new().configure(
            "INFORME DE LA EXPEDICIÓN",
            "Balance científico final",
            lines,
            "NUEVA EXPEDICIÓN",
            color,
            ).with_extra(drawer, UiPalette.SCREEN.y - 170.0).with_sound(Sfx.Sound.SUCCESS if grade <= AnalysisLedger.Grade.C else Sfx.Sound.FAILURE)
