extends BaseTest
## Integración en pantalla dividida con el protocolo real: cada rol hace solo lo suyo y ve solo lo suyo.


func _pump(session: MissionSession, steps: int) -> void:
    for _i: int in range(steps):
        session.poll()
        session.step(1.0 / 60.0)
    session.poll()


func test_roles_split_actions_and_visibility() -> void:
    var session: MissionSession = MissionSession.build(
            SessionOptions.new(),
            func() -> MatchRules: return TapMatch.new(7),
            TapMission.roles(),
            TapMission.ROLE_ORDER,
            )
    _pump(session, 3)
    var sender: MatchClient = session.clients[0]
    var receiver: MatchClient = session.clients[1]
    check_equal(sender.role, TapRole.Role.SENDER, "el primero es el emisor (izquierda)")
    check_equal(receiver.role, TapRole.Role.RECEIVER, "el segundo es el receptor (derecha)")
    var host_game: TapMatch = (session.host as MatchHost).rules() as TapMatch

    receiver.send_command(TapCommand.Kind.SPAWN, {})
    _pump(session, 3)
    check_equal(host_game.targets().count(), 0, "el receptor no puede crear popups")

    sender.send_command(TapCommand.Kind.SPAWN, {})
    _pump(session, 3)
    var seen: TapMatch = receiver.replica as TapMatch
    check_equal(seen.targets().count(), 1, "el popup del emisor llega al receptor")
    check_equal((sender.replica as TapMatch).targets().count(), 0, "el emisor no ve los popups")
    check(sender.last_tick >= 0 and (sender.replica as TapMatch).time_left() < TapMatch.MATCH_SECONDS, "el emisor ve el tiempo")

    sender.send_command(TapCommand.Kind.HIT, {"id": seen.targets().ids()[0]})
    _pump(session, 3)
    check_equal(host_game.hits(), 0, "el emisor no puede pulsar")

    receiver.send_command(TapCommand.Kind.HIT, {"id": seen.targets().ids()[0]})
    _pump(session, 3)
    check_equal(seen.hits(), 1, "el receptor ve su acierto")
    check_equal((sender.replica as TapMatch).hits(), 0, "el emisor no ve la puntuación")
    session.close()
