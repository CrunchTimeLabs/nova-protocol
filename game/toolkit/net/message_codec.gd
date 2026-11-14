class_name MessageCodec
extends RefCounted
## Convierte un mensaje (Dictionary de primitivos) en bytes y de vuelta. Usa JSON: nunca decodifica objetos,
## así un mensaje de la red no puede traer código ni instancias.


static func encode(message: Dictionary) -> PackedByteArray:
    return JSON.stringify(message).to_utf8_buffer()


## El mensaje, o un diccionario vacío si los bytes no son un objeto JSON válido.
static func decode(bytes: PackedByteArray) -> Dictionary:
    var json: JSON = JSON.new()
    if json.parse(bytes.get_string_from_utf8()) != OK:
        return {}
    if json.data is Dictionary:
        return json.data as Dictionary
    return {}
