class_name SaveSlot
extends RefCounted
## Guardado en un archivo JSON con número de versión (user:// también funciona en web).


static func write(path: String, version: int, payload: Dictionary) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"version": version, "payload": payload}))
    return true


## Devuelve el payload, o un Dictionary vacío si no existe, está corrupto o es de otra versión.
static func read(path: String, version: int) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary) or int(parsed.get("version", -1)) != version:
        return {}
    var payload: Variant = parsed.get("payload", {})
    return payload if payload is Dictionary else {}
