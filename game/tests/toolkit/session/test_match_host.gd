extends BaseTest
## Capa 4: anfitrión y cliente con el protocolo real sobre LocalTransport: roles, filtrado, rechazos y flujo.

const ROLE_WATCHER: int = 0
const ROLE_DRIVER: int = 1
const KIND_PUSH: int = 7
const KIND_FORBIDDEN: int = 8


## Reglas de prueba: un contador que solo el conductor empuja; el observador ve "count", el conductor no.
class CounterRules:
    extends MatchRules

    var count: float = 0.0
    var secret: int = 0
    var released: Array[int] = []

    func apply(_slot: int, command: Command) -> bool:
        var amount: Variant = command.payload.get("amount")
        if not (amount is int or amount is float):
            return false
        count += float(amount)
        return true

    func step(_delta: float) -> void:
        pass

    func release_slot(slot: int) -> void:
        released.append(slot)

    func snapshot() -> Dictionary:
        return {"count": count, "secret": secret}

    func restore(saved: Dictionary) -> void:
        if saved.has("count"):
            count = float(saved["count"])
        if saved.has("secret"):
            secret = int(saved["secret"])


var _hub: LocalHub
var _rules: CounterRules
var _host: MatchHost
var _watcher: MatchClient
var _watcher_view: CounterRules
var _driver: MatchClient
var _driver_view: CounterRules
var _rejections: Array[int] = []
## Transportes y clientes extra de una prueba, para que `_pump` también los atienda.
var _extra_transports: Array[SessionTransport] = []
var _extra_clients: Array[MatchClient] = []


func before_each() -> void:
    _hub = LocalHub.new()
    _rules = CounterRules.new()
    _rules.secret = 42
    var roles: RoleTable = RoleTable.new()
    roles.show_key(ROLE_WATCHER, "count")
    roles.allow(ROLE_DRIVER, KIND_PUSH)
    roles.show_key(ROLE_DRIVER, "secret")
    var order: Array[int] = [ROLE_WATCHER, ROLE_DRIVER]
    _host = MatchHost.new(_rules, roles, _hub.create_host(), order)
    _rejections = []
    _extra_transports = []
    _extra_clients = []
    _host.command_rejected.connect(func(_slot: int, reason: int) -> void: _rejections.append(reason))
    _watcher_view = CounterRules.new()
    _watcher = MatchClient.new(_hub.create_client(), _watcher_view)
    _driver_view = CounterRules.new()
    _driver = MatchClient.new(_hub.create_client(), _driver_view)
    _host.start()
    _pump()


func test_roles_are_assigned_in_order_and_views_are_filtered() -> void:
    check(_watcher.is_joined() and _driver.is_joined(), "ambos entraron")
    check_equal(_watcher.role, ROLE_WATCHER, "el primero observa")
    check_equal(_driver.role, ROLE_DRIVER, "el segundo conduce")
    _driver.send_command(KIND_PUSH, {"amount": 3.0})
    _pump()
    _host.step(1.0 / 60.0)
    _pump()
    check_approx(_watcher_view.count, 3.0, "el observador ve el cambio del conductor")
    check_equal(_driver_view.count, 0.0, "el conductor no recibe lo del observador")
    check_equal(_watcher_view.secret, 0, "el observador no recibe lo del conductor")
    check_equal(_driver_view.secret, 42, "el conductor ve lo suyo")


func test_commands_outside_the_role_or_invalid_are_rejected() -> void:
    _watcher.send_command(KIND_PUSH, {"amount": 5.0})
    _driver.send_command(KIND_FORBIDDEN, {"amount": 5.0})
    _driver.send_command(KIND_PUSH, {"amount": "mucho"})
    _pump()
    check_equal(_rules.count, 0.0, "el estado no cambió")
    var expected: Array[int] = [
        MatchProtocol.Reason.FORBIDDEN,
        MatchProtocol.Reason.FORBIDDEN,
        MatchProtocol.Reason.REFUSED,
    ]
    check_equal(_rejections, expected, "cada rechazo es visible con su motivo")


func test_malformed_and_flooding_commands_are_limited() -> void:
    _hub_raw_command(_driver, {"slot": "x"})
    for _i: int in range(MatchHost.MAX_COMMANDS_PER_STEP + 3):
        _driver.send_command(KIND_PUSH, {"amount": 1.0})
    _pump()
    check_equal(_rules.count, float(MatchHost.MAX_COMMANDS_PER_STEP), "solo se aplican las permitidas por paso")
    check(_rejections.has(MatchProtocol.Reason.INVALID_COMMAND), "el comando mal formado se rechaza")
    check(_rejections.has(MatchProtocol.Reason.RATE_LIMITED), "el exceso se limita")


func test_old_snapshots_are_ignored() -> void:
    _host.step(1.0 / 60.0)
    _pump()
    var applied: int = _watcher.last_tick
    _rules.count = 99.0
    _watcher._apply_snapshot(MatchProtocol.make(MatchProtocol.Type.SNAPSHOT, {MatchProtocol.KEY_TICK: applied, MatchProtocol.KEY_STATE: {"count": 1234.0}}))
    check(not is_equal_approx(_watcher_view.count, 1234.0), "un tick repetido o menor no se aplica")


func test_illegal_flow_is_refused() -> void:
    check(not _host.start(), "no se puede iniciar dos veces")
    _host.close()
    check(not _host.step(0.1), "cerrada, la partida no avanza")


func test_version_and_capacity_are_enforced_and_leaving_frees_the_role() -> void:
    var late: MatchClient = _extra_client()
    _pump()
    check_equal(late.status(), MatchClient.Status.REJECTED, "con la sala llena, el tercero es rechazado")
    check(_rejections.has(MatchProtocol.Reason.SESSION_FULL), "motivo: sala llena")
    _driver.send_command(KIND_PUSH, {"amount": 1.0})
    _pump()
    _driver.close()
    _pump()
    check_equal(_rules.released.size(), 1, "al irse, el anfitrión libera sus órdenes")
    var replacement: MatchClient = _extra_client()
    _pump()
    check(replacement.is_joined(), "el rol liberado se puede ocupar")
    check_equal(replacement.role, ROLE_DRIVER, "con el mismo rol que quedó libre")


func test_other_protocol_version_is_rejected() -> void:
    var transport: LocalTransport = _hub.create_client()
    _extra_transports.append(transport)
    var seen: Array[Dictionary] = []
    transport.message_received.connect(func(_peer: int, message: Dictionary) -> void: seen.append(message))
    transport.send(LocalHub.HOST_ID, MatchProtocol.make(MatchProtocol.Type.HELLO, {MatchProtocol.KEY_VERSION: 999}), true)
    _pump()
    check_equal(seen.size(), 1, "el anfitrión responde")
    check_equal(MatchProtocol.type_of(seen[0]), MatchProtocol.Type.REJECT, "con un rechazo")
    check_equal(MatchProtocol.int_of(seen[0], MatchProtocol.KEY_REASON), MatchProtocol.Reason.VERSION_MISMATCH, "por versión")


func _pump() -> void:
    for _i: int in range(3):
        _host.poll()
        _watcher.poll()
        _driver.poll()
        for client: MatchClient in _extra_clients:
            client.poll()
        for transport: SessionTransport in _extra_transports:
            transport.poll()


func _extra_client() -> MatchClient:
    var client: MatchClient = MatchClient.new(_hub.create_client(), CounterRules.new())
    _extra_clients.append(client)
    return client


func _hub_raw_command(client: MatchClient, command: Dictionary) -> void:
    client._transport.send(LocalHub.HOST_ID, MatchProtocol.make(MatchProtocol.Type.COMMAND, {MatchProtocol.KEY_COMMAND: command}), false)
