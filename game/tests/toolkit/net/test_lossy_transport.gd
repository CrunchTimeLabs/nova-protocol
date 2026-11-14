extends BaseTest
## Capa 4 (robustez): con pérdida, duplicados y retrasos el cliente converge en la siguiente instantánea buena.


const ROLE_COUNTER: int = 0
const KIND_ADD: int = 1


## Reglas mínimas: un contador que sube con cada comando.
class CounterRules:
    extends MatchRules

    var count: float = 0.0

    func apply(_slot: int, command: Command) -> bool:
        count += float(command.payload.get("amount", 0.0))
        return true

    func step(_delta: float) -> void:
        pass

    func release_slot(_slot: int) -> void:
        pass

    func snapshot() -> Dictionary:
        return {"count": count}

    func restore(saved: Dictionary) -> void:
        count = float(saved["count"])


func test_client_converges_after_lossy_stretch() -> void:
    var hub: LocalHub = LocalHub.new()
    var lossy: LossyTransport = LossyTransport.new(hub.create_host(), GameRandom.new(7), 0.5, 0.3, 3)
    var rules: CounterRules = CounterRules.new()
    var roles: RoleTable = RoleTable.new()
    roles.allow(ROLE_COUNTER, KIND_ADD)
    roles.show_key(ROLE_COUNTER, "count")
    var order: Array[int] = [ROLE_COUNTER]
    var host: MatchHost = MatchHost.new(rules, roles, lossy, order)
    var replica: CounterRules = CounterRules.new()
    var client: MatchClient = MatchClient.new(hub.create_client(), replica)
    host.start()
    for _i: int in range(10):
        host.poll()
        client.poll()
    check(client.is_joined(), "el apretón de manos (fiable) sobrevive a la pérdida")
    var delivered: int = 0
    var last_tick: int = -1
    client.snapshot_applied.connect(func(tick: int) -> void:
        delivered += 1
        check(tick > last_tick, "los ticks aplicados solo crecen aunque lleguen duplicados o desordenados")
        last_tick = tick
    )
    for i: int in range(200):
        client.send_command(KIND_ADD, {"amount": 1.0})
        host.poll()
        client.poll()
        host.step(1.0 / 60.0)
    check(delivered < 200, "la pérdida descartó instantáneas (%d de 200)" % delivered)
    lossy.loss_probability = 0.0
    lossy.duplicate_probability = 0.0
    lossy.max_delay_polls = 0
    for _i: int in range(6):
        host.step(1.0 / 60.0)
        host.poll()
        client.poll()
    check_approx(replica.count, rules.count, "tras un tramo bueno, la réplica coincide con el anfitrión")
