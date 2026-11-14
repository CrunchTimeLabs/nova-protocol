class_name MatchHost
extends RefCounted
## Anfitrión autoritativo: recibe comandos, los valida contra el rol del emisor, los aplica a las reglas
## y difunde a cada jugador la instantánea filtrada para su rol. Los jugadores nunca cambian el estado por su cuenta.


signal player_joined(slot: int, role: int)
signal player_left(slot: int)
## Todo comando o ingreso descartado queda visible aquí (y el emisor recibe un ERROR).
signal command_rejected(slot: int, reason: int)

enum Phase { LOBBY, RUNNING, CLOSED }

## Un jugador que manda más órdenes que esto entre dos pasos es limitado.
const MAX_COMMANDS_PER_STEP: int = 8

var phase: Phase:
    get:
        return _phase
## Pasos fijos ejecutados desde `start()`.
var tick: int:
    get:
        return _tick

var _rules: MatchRules
var _roles: RoleTable
var _transport: SessionTransport
var _role_order: Array[int]
var _free_roles: Array[int] = []
var _slot_of_peer: Dictionary = {}     # int -> int
var _peer_of_slot: Dictionary = {}     # int -> int
var _role_of_slot: Dictionary = {}     # int -> int
var _commands_this_step: Dictionary = {}    # int -> int
var _next_slot: int = 0
var _phase: Phase = Phase.LOBBY
var _tick: int = 0


## `role_order` fija cuántos jugadores caben y qué rol recibe cada uno al entrar, en ese orden.
func _init(
        p_rules: MatchRules,
        p_roles: RoleTable,
        p_transport: SessionTransport,
        p_role_order: Array[int],
        ) -> void:
    assert(p_transport.is_host(), "MatchHost necesita el transporte del anfitrión")
    _rules = p_rules
    _roles = p_roles
    _transport = p_transport
    _role_order = p_role_order.duplicate()
    _free_roles = p_role_order.duplicate()
    _transport.message_received.connect(_on_message)
    _transport.peer_disconnected.connect(_on_peer_disconnected)


## Las reglas de la partida (para que el punto de composición o una prueba las lea).
func rules() -> MatchRules:
    return _rules


func player_count() -> int:
    return _slot_of_peer.size()


func role_of_slot(slot: int) -> int:
    return int(_role_of_slot.get(slot, -1))


## LOBBY -> RUNNING. false (y avisa) desde cualquier otro estado.
func start() -> bool:
    if _phase != Phase.LOBBY:
        push_error("MatchHost.start: transición ilegal desde %s" % Phase.keys()[_phase])
        return false
    _phase = Phase.RUNNING
    return true


## LOBBY o RUNNING -> CLOSED.
func close() -> void:
    if _phase == Phase.CLOSED:
        return
    _phase = Phase.CLOSED
    _transport.close()


func poll() -> void:
    _transport.poll()


## Un paso fijo: avanza las reglas y difunde a cada jugador su vista. false si la partida no está en marcha.
func step(delta: float) -> bool:
    if _phase != Phase.RUNNING:
        push_error("MatchHost.step: la partida no está en marcha (%s)" % Phase.keys()[_phase])
        return false
    _rules.step(delta)
    _tick += 1
    _commands_this_step.clear()
    for peer: Variant in _slot_of_peer.keys():
        _send_snapshot(int(peer))
    return true


func _on_message(peer_id: int, message: Dictionary) -> void:
    match MatchProtocol.type_of(message):
        MatchProtocol.Type.HELLO:
            _on_hello(peer_id, message)
        MatchProtocol.Type.COMMAND:
            _on_command(peer_id, message)
        _:
            _reject(peer_id, -1, MatchProtocol.Reason.INVALID_COMMAND)


func _on_hello(peer_id: int, message: Dictionary) -> void:
    if _slot_of_peer.has(peer_id) or _phase == Phase.CLOSED:
        return
    if MatchProtocol.int_of(message, MatchProtocol.KEY_VERSION) != MatchProtocol.PROTOCOL_VERSION:
        _send_reject(peer_id, MatchProtocol.Reason.VERSION_MISMATCH)
        return
    if _free_roles.is_empty():
        _send_reject(peer_id, MatchProtocol.Reason.SESSION_FULL)
        return
    var role: int = _free_roles.pop_front()
    var slot: int = _next_slot
    _next_slot += 1
    _slot_of_peer[peer_id] = slot
    _peer_of_slot[slot] = peer_id
    _role_of_slot[slot] = role
    var welcome: Dictionary = MatchProtocol.make(
            MatchProtocol.Type.WELCOME,
            {MatchProtocol.KEY_SLOT: slot, MatchProtocol.KEY_ROLE: role},
            )
    _transport.send(peer_id, welcome, true)
    _send_snapshot(peer_id)
    player_joined.emit(slot, role)


func _on_command(peer_id: int, message: Dictionary) -> void:
    if not _slot_of_peer.has(peer_id):
        _send_reject(peer_id, MatchProtocol.Reason.NOT_JOINED)
        return
    var slot: int = int(_slot_of_peer[peer_id])
    if _phase != Phase.RUNNING:
        _reject(peer_id, slot, MatchProtocol.Reason.NOT_RUNNING)
        return
    var raw: Variant = message.get(MatchProtocol.KEY_COMMAND)
    var command: Command = Command.from_dict(raw as Dictionary) if raw is Dictionary else null
    if command == null:
        _reject(peer_id, slot, MatchProtocol.Reason.INVALID_COMMAND)
        return
    command.slot = slot    # el slot lo pone el anfitrión: lo que diga el mensaje no cuenta
    if not _roles.can_send(role_of_slot(slot), command.kind):
        _reject(peer_id, slot, MatchProtocol.Reason.FORBIDDEN)
        return
    var count: int = int(_commands_this_step.get(slot, 0)) + 1
    _commands_this_step[slot] = count
    if count > MAX_COMMANDS_PER_STEP:
        _reject(peer_id, slot, MatchProtocol.Reason.RATE_LIMITED)
        return
    if not _rules.apply(slot, command):
        _reject(peer_id, slot, MatchProtocol.Reason.REFUSED)


func _on_peer_disconnected(peer_id: int) -> void:
    if not _slot_of_peer.has(peer_id):
        return
    var slot: int = int(_slot_of_peer[peer_id])
    var role: int = role_of_slot(slot)
    _slot_of_peer.erase(peer_id)
    _peer_of_slot.erase(slot)
    _role_of_slot.erase(slot)
    _commands_this_step.erase(slot)
    _free_roles.append(role)
    _free_roles.sort_custom(func(a: int, b: int) -> bool: return _role_order.find(a) < _role_order.find(b))
    _rules.release_slot(slot)
    player_left.emit(slot)


func _send_snapshot(peer_id: int) -> void:
    var role: int = role_of_slot(int(_slot_of_peer[peer_id]))
    var snapshot: Dictionary = MatchProtocol.make(
            MatchProtocol.Type.SNAPSHOT,
            {
                MatchProtocol.KEY_TICK: _tick,
                MatchProtocol.KEY_STATE: _roles.filter(role, _rules.snapshot()),
            },
            )
    _transport.send(peer_id, snapshot, false)


func _reject(peer_id: int, slot: int, reason: int) -> void:
    command_rejected.emit(slot, reason)
    _transport.send(peer_id, MatchProtocol.make(MatchProtocol.Type.ERROR, {MatchProtocol.KEY_REASON: reason}), true)


func _send_reject(peer_id: int, reason: int) -> void:
    command_rejected.emit(-1, reason)
    _transport.send(peer_id, MatchProtocol.make(MatchProtocol.Type.REJECT, {MatchProtocol.KEY_REASON: reason}), true)
