extends BaseTest
## Capa 4 (orquestador): armar → despegar (solo completo) → órbita → armar, sin tocar el cohete en vuelo.


func _complete(session: HangarSession) -> void:
    for part: RocketParts.Part in [RocketParts.Part.C1, RocketParts.Part.A2, RocketParts.Part.T1, RocketParts.Part.P2, RocketParts.Part.M3]:
        session.place(part)


func test_cannot_launch_incomplete() -> void:
    var session: HangarSession = HangarSession.new()
    session.place(RocketParts.Part.C1)
    check(not session.launch(), "incompleto no despega")
    check_equal(session.phase(), HangarSession.Phase.BUILDING, "sigue armando")


func test_full_launch_cycle_keeps_the_rocket() -> void:
    var session: HangarSession = HangarSession.new()
    _complete(session)
    check(session.launch(), "despega")
    check(not session.launch(), "no despega dos veces")
    check(not session.place(RocketParts.Part.C2), "no se toca en vuelo")
    check(not session.remove(RocketParts.Section.PAYLOAD), "ni se quita")
    session.tick(HangarSession.COUNTDOWN_TIME / 2.0)
    check_approx(session.ascent(), 0.0, "en cuenta atrás no sube")
    session.tick(HangarSession.LAUNCH_TIME)
    check_equal(session.phase(), HangarSession.Phase.IN_ORBIT, "en órbita")
    session.tick(HangarSession.ORBIT_TIME + 0.1)
    check_equal(session.phase(), HangarSession.Phase.BUILDING, "vuelve al hangar")
    check_equal(session.build.code(), "C1_A2_T1_P2_M3", "el cohete se conserva")
