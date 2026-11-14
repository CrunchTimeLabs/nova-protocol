class_name MatchClient
extends RefCounted
## Un jugador: pide entrar, envía comandos y aplica a su réplica las instantáneas que recibe.
## Nunca decide reglas: la réplica solo refleja lo que el anfitrión mandó (ya filtrado para su rol).


signal joined(slot: int, role: int)
signal rejected(reason: int)
## El anfitrión descartó un comando de este jugador.
signal command_failed(reason: int)
signal snapshot_applied(tick: int)

enum Status { CONNECTING, JOINED, REJECTED, CLOSED }

var slot: int:
    get:
        return _slot
var role: int:
    get:
        return _role
var last_tick: int:
    get:
        return _last_tick
var replica: MatchRules

var _transport: SessionTransport
var _host_peer_id: int
var _status: StateMachine = StateMachine.new()
var _slot: int = -1
var _role: int = -1
var _last_tick: int = -1


func _init(p_transport: SessionTransport, p_replica: MatchRules, p_host_peer_id: int = LocalHub.HOST_ID) -> void:
    assert(not p_transport.is_host(), "MatchClient necesita el transporte de un jugador")
    _transport = p_transport
    replica = p_replica
    _host_peer_id = p_host_peer_id
    for state_id: int in Status.values():
        _status.add_state(State.new(state_id))
    _status.allow(Status.CONNECTING, [Status.JOINED, Status.REJECTED, Status.CLOSED])
    _status.allow(Status.JOINED, [Status.CLOSED])
    _status.allow(Status.REJECTED, [Status.CLOSED])
    _status.transition_to(Status.CONNECTING)
    _transport.peer_connected.connect(_on_peer_connected)
    _transport.message_received.connect(_on_message)
    _transport.peer_disconnected.connect(_on_peer_disconnected)


func status() -> Status:
    return _status.current_id() as Status


func is_joined() -> bool:
    return _status.is_in(Status.JOINED)


func poll() -> void:
    _transport.poll()


## Envía un comando. false si todavía no se entró (o ya se salió).
func send_command(kind: int, payload: Dictionary, is_reliable: bool = false) -> bool:
    if not is_joined():
        return false
    var command: Command = Command.new(_slot, kind, payload)
    _transport.send(
            _host_peer_id,
            MatchProtocol.make(MatchProtocol.Type.COMMAND, {MatchProtocol.KEY_COMMAND: command.to_dict()}),
            is_reliable,
            )
    return true


func close() -> void:
    if _status.is_in(Status.CLOSED):
        return
    _status.transition_to(Status.CLOSED)
    _transport.close()


func _on_peer_connected(peer_id: int) -> void:
    if peer_id != _host_peer_id:
        return
    var hello: Dictionary = MatchProtocol.make(
            MatchProtocol.Type.HELLO,
            {MatchProtocol.KEY_VERSION: MatchProtocol.PROTOCOL_VERSION},
            )
    _transport.send(_host_peer_id, hello, true)


func _on_peer_disconnected(peer_id: int) -> void:
    if peer_id == _host_peer_id and not _status.is_in(Status.CLOSED):
        _status.transition_to(Status.CLOSED)


func _on_message(peer_id: int, message: Dictionary) -> void:
    if peer_id != _host_peer_id:
        return
    match MatchProtocol.type_of(message):
        MatchProtocol.Type.WELCOME:
            if _status.is_in(Status.CONNECTING):
                _slot = MatchProtocol.int_of(message, MatchProtocol.KEY_SLOT)
                _role = MatchProtocol.int_of(message, MatchProtocol.KEY_ROLE)
                _status.transition_to(Status.JOINED)
                joined.emit(_slot, _role)
        MatchProtocol.Type.REJECT:
            if _status.is_in(Status.CONNECTING):
                _status.transition_to(Status.REJECTED)
                rejected.emit(MatchProtocol.int_of(message, MatchProtocol.KEY_REASON))
        MatchProtocol.Type.SNAPSHOT:
            _apply_snapshot(message)
        MatchProtocol.Type.ERROR:
            command_failed.emit(MatchProtocol.int_of(message, MatchProtocol.KEY_REASON))


## Una instantánea con tick menor o igual al ya aplicado (retrasada o repetida) se ignora.
func _apply_snapshot(message: Dictionary) -> void:
    if not is_joined():
        return
    var tick: int = MatchProtocol.int_of(message, MatchProtocol.KEY_TICK)
    var state: Variant = message.get(MatchProtocol.KEY_STATE)
    if tick <= _last_tick or not state is Dictionary:
        return
    _last_tick = tick
    replica.restore(state as Dictionary)
    snapshot_applied.emit(tick)
