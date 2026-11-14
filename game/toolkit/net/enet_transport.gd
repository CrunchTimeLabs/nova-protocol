class_name EnetTransport
extends SessionTransport
## Transporte de red local sobre ENet. Usa un `SceneMultiplayer` propio, sin colgarlo del árbol y solo con bytes crudos:
## no hay @rpc ni nodos, y los mensajes no pueden traer objetos. El anfitrión tiene peer_id 1.


const DEFAULT_PORT: int = 47321
const MAX_CLIENTS: int = 8
const CHANNEL: int = 0

var _multiplayer: SceneMultiplayer = SceneMultiplayer.new()
var _is_host: bool


## Abre un servidor en `port`. null (y avisa) si no se pudo.
static func host(port: int = DEFAULT_PORT, max_clients: int = MAX_CLIENTS) -> EnetTransport:
    var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error: Error = peer.create_server(port, max_clients)
    if error != OK:
        push_error("EnetTransport.host: no se pudo abrir el puerto %d (%s)" % [port, error_string(error)])
        return null
    return EnetTransport.new(peer, true)


## Se conecta a un anfitrión. null (y avisa) si no se pudo iniciar; la conexión se completa en los siguientes `poll()`.
static func join(address: String, port: int = DEFAULT_PORT) -> EnetTransport:
    var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
    var error: Error = peer.create_client(address, port)
    if error != OK:
        push_error("EnetTransport.join: no se pudo conectar a %s:%d (%s)" % [address, port, error_string(error)])
        return null
    return EnetTransport.new(peer, false)


func _init(peer: ENetMultiplayerPeer, p_is_host: bool) -> void:
    _is_host = p_is_host
    # Sin árbol, SceneMultiplayer exige una ruta raíz aunque no se use ninguna ruta de nodo.
    _multiplayer.set_root_path(NodePath("/root"))
    _multiplayer.allow_object_decoding = false
    _multiplayer.multiplayer_peer = peer
    _multiplayer.peer_connected.connect(func(peer_id: int) -> void: peer_connected.emit(peer_id))
    _multiplayer.peer_disconnected.connect(func(peer_id: int) -> void: peer_disconnected.emit(peer_id))
    _multiplayer.peer_packet.connect(_on_packet)


func is_host() -> bool:
    return _is_host


func local_peer_id() -> int:
    return _multiplayer.get_unique_id()


func send(peer_id: int, message: Dictionary, is_reliable: bool) -> void:
    var mode: MultiplayerPeer.TransferMode = MultiplayerPeer.TRANSFER_MODE_RELIABLE if is_reliable else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
    _multiplayer.send_bytes(MessageCodec.encode(message), peer_id, mode, CHANNEL)


func poll() -> void:
    _multiplayer.poll()


func close() -> void:
    _multiplayer.multiplayer_peer = null


func _on_packet(peer_id: int, packet: PackedByteArray) -> void:
    message_received.emit(peer_id, MessageCodec.decode(packet))
