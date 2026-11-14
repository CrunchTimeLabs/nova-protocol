extends BaseTest
## Capa 1: la red solo trae diccionarios de primitivos; basura y objetos serializados no se decodifican.


## JSON no distingue enteros de reales: los números vuelven como float y el receptor los convierte.
func test_round_trip_keeps_primitives() -> void:
    var message: Dictionary = {"t": 3.0, "name": "a", "nested": {"v": [1.0, 2.5]}}
    check_equal(MessageCodec.decode(MessageCodec.encode(message)), message, "ida y vuelta")


func test_garbage_and_objects_decode_to_empty() -> void:
    check(MessageCodec.decode(PackedByteArray([1, 2, 3, 255])).is_empty(), "bytes arbitrarios")
    check(MessageCodec.decode("[1, 2]".to_utf8_buffer()).is_empty(), "un JSON que no es objeto")
    var node: RefCounted = RefCounted.new()
    check(MessageCodec.decode(var_to_bytes_with_objects(node)).is_empty(), "un objeto serializado por Godot")
