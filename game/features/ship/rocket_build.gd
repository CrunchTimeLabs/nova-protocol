class_name RocketBuild
extends RefCounted
## El cohete que se arma: una ranura por sección. Cada pieza va a su sección (si había otra, la sustituye).


signal changed(section: RocketParts.Section)

var _assembly: SlotAssembly


func _init() -> void:
    var categories: Array[int] = []
    for section: RocketParts.Section in RocketParts.sections():
        categories.append(section)
    _assembly = SlotAssembly.new(categories)
    _assembly.changed.connect(_on_changed)


## Coloca la pieza en su sección. Devuelve la que sustituyó (-1 si el hueco estaba vacío).
func place(part: RocketParts.Part) -> int:
    var section: RocketParts.Section = RocketParts.section_of(part)
    var slot: int = _assembly.slot_for(section)
    var previous: int = _assembly.item_at(slot)
    _assembly.place(slot, part, section)
    return previous


## Quita la pieza de `section`. Devuelve la que había (-1 si estaba vacía).
func remove(section: RocketParts.Section) -> int:
    return _assembly.remove(_assembly.slot_for(section))


## Pieza en `section` o -1.
func part_at(section: RocketParts.Section) -> int:
    return _assembly.item_at(_assembly.slot_for(section))


func is_complete() -> bool:
    return _assembly.is_complete()


func clear() -> void:
    _assembly.clear()


## Código de la combinación como en `cohetes_completos` (C1_A1_T1_P1_M1); vacío si falta alguna pieza.
func code() -> String:
    if not is_complete():
        return ""
    var codes: PackedStringArray = PackedStringArray()
    for section: RocketParts.Section in RocketParts.sections():
        codes.append(String(RocketParts.CODES[part_at(section)]))
    return "_".join(codes)


## Aspecto del cohete armado de 0 a 100 (100 = la mejor pieza en cada sección); las secciones vacías no suman.
func stat(which: RocketParts.Stat) -> int:
    var total: int = 0
    for section: RocketParts.Section in RocketParts.sections():
        var part: int = part_at(section)
        if part != -1:
            total += RocketParts.stat_of(part as RocketParts.Part, which)
    return roundi(100.0 * float(total) / float(RocketParts.stat_max(which)))


## Todas las combinaciones posibles: una pieza por sección.
static func all_combinations() -> Array[Array]:
    var combos: Array[Array] = [[]]
    for section: RocketParts.Section in RocketParts.sections():
        var grown: Array[Array] = []
        for combo: Array in combos:
            for part: RocketParts.Part in RocketParts.parts_of(section):
                var next: Array = combo.duplicate()
                next.append(part)
                grown.append(next)
        combos = grown
    return combos


func snapshot() -> Dictionary:
    return _assembly.snapshot()


func restore(data: Dictionary) -> void:
    _assembly.restore(data)


func _on_changed(slot: int) -> void:
    changed.emit(_assembly.category_of(slot) as RocketParts.Section)
