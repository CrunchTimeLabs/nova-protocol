class_name LocalHub
extends RefCounted
## Punto de encuentro en memoria de los transportes locales: reparte mensajes entre ellos como lo haría la red.
## Pantalla dividida, un jugador y pruebas usan el mismo camino de código que la red (los mensajes se codifican).


enum Event { CONNECTED, DISCONNECTED, MESSAGE }

const HOST_ID: int = 1

var _inboxes: Dictionary = {}    # int (peer) -> Array[Dictionary] de eventos
var _next_id: int = HOST_ID + 1


func create_host() -> LocalTransport:
    assert(not _inboxes.has(HOST_ID), "LocalHub ya tiene anfitrión")
    _inboxes[HOST_ID] = []
    return LocalTransport.new(self, HOST_ID)


## Un cliente nuevo; ambos extremos se enteran de la conexión en su siguiente `poll()`.
func create_client() -> LocalTransport:
    assert(_inboxes.has(HOST_ID), "LocalHub necesita anfitrión antes que clientes")
    var id: int = _next_id
    _next_id += 1
    _inboxes[id] = []
    push(HOST_ID, Event.CONNECTED, id)
    push(id, Event.CONNECTED, HOST_ID)
    return LocalTransport.new(self, id)


func push(to_peer: int, event: Event, from_peer: int, bytes: PackedByteArray = PackedByteArray()) -> void:
    if _inboxes.has(to_peer):
        (_inboxes[to_peer] as Array).append({"event": event, "peer": from_peer, "bytes": bytes})


func take(peer_id: int) -> Array:
    var events: Array = _inboxes.get(peer_id, []) as Array
    _inboxes[peer_id] = []
    return events


## A quiénes llega un envío a `peer_id` 0: el anfitrión habla con todos; un cliente, solo con el anfitrión.
func everyone_but(sender: int) -> Array[int]:
    var targets: Array[int] = []
    if sender == HOST_ID:
        for peer: Variant in _inboxes.keys():
            if int(peer) != HOST_ID:
                targets.append(int(peer))
    elif _inboxes.has(HOST_ID):
        targets.append(HOST_ID)
    return targets


## Un extremo se va: el anfitrión se entera de cada cliente que se va; los clientes, de la caída del anfitrión.
func leave(peer_id: int) -> void:
    if not _inboxes.has(peer_id):
        return
    _inboxes.erase(peer_id)
    if peer_id == HOST_ID:
        for peer: Variant in _inboxes.keys():
            push(int(peer), Event.DISCONNECTED, HOST_ID)
    else:
        push(HOST_ID, Event.DISCONNECTED, peer_id)
