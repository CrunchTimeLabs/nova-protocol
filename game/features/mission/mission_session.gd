class_name MissionSession
extends RefCounted
## Arma la partida de una misión según SessionOptions: el anfitrión (si esta máquina lo es) y los clientes locales.
## Pantalla dividida: un anfitrión y un cliente por rol sobre un LocalHub. LAN: un anfitrión y su propio jugador por
## loopback, o solo un cliente que se une a otra máquina. Sin nodos: la vista lee `clients` y llama a `poll()` / `step()`.


## null si esta máquina solo se une a otra.
var host: MatchHost
var clients: Array[MatchClient] = []


## `rules_factory` devuelve unas reglas nuevas (`MatchRules`) cada vez: una para el anfitrión y una réplica por cliente.
## null (y avisa) si no se pudo abrir la red.
static func build(
        options: SessionOptions,
        rules_factory: Callable,
        roles: RoleTable,
        role_order: Array[int],
        ) -> MissionSession:
    var session: MissionSession = MissionSession.new()
    if options.mode == SessionOptions.Mode.SPLIT_SCREEN:
        var hub: LocalHub = LocalHub.new()
        session.host = MatchHost.new(rules_factory.call() as MatchRules, roles, hub.create_host(), role_order)
        for _role: int in role_order:
            session.clients.append(MatchClient.new(hub.create_client(), rules_factory.call() as MatchRules))
    elif options.is_host:
        var server: EnetTransport = EnetTransport.host(options.port, role_order.size())
        var own: EnetTransport = EnetTransport.join(options.address, options.port)
        if server == null or own == null:
            return null
        session.host = MatchHost.new(rules_factory.call() as MatchRules, roles, server, role_order)
        session.clients.append(MatchClient.new(own, rules_factory.call() as MatchRules))
    else:
        var remote: EnetTransport = EnetTransport.join(options.address, options.port)
        if remote == null:
            return null
        session.clients.append(MatchClient.new(remote, rules_factory.call() as MatchRules))
    if session.host != null:
        session.host.start()
    return session


func poll() -> void:
    if host != null:
        host.poll()
    for client: MatchClient in clients:
        client.poll()


## Un paso fijo del anfitrión; sin efecto si esta máquina solo es jugador.
func step(delta: float) -> void:
    if host != null:
        host.step(delta)


func close() -> void:
    for client: MatchClient in clients:
        client.close()
    if host != null:
        host.close()
