extends BaseTest
## Capa 2: una orden de estado se envía al cambiar y como latido; entre medias, no.


func test_sends_on_change_and_on_heartbeat_only() -> void:
    var heartbeat: CommandHeartbeat = CommandHeartbeat.new(1.0)
    var steady: Dictionary = {"x": 0.0, "y": 1.0}
    check(heartbeat.should_send(steady, 0.1), "la primera vez siempre")
    check(not heartbeat.should_send(steady, 0.1), "sin cambios no repite")
    check(heartbeat.should_send({"x": 1.0, "y": 0.0}, 0.1), "un cambio se envía de inmediato")
    var sent: int = 0
    for _i: int in range(25):
        if heartbeat.should_send({"x": 1.0, "y": 0.0}, 0.1):
            sent += 1
    check_equal(sent, 2, "en 2,5 s sin cambios, un latido por segundo")
