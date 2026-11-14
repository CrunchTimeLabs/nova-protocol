class_name PatternSpec
extends RefCounted
## Un patrón de laboratorio: la firma que un analizador espera ver para una sustancia.
## Los señuelos son copias con los picos corridos (`is_decoy`).


enum Shape { EMISSION, ABSORPTION, PEAKS, CURVE }

var id: String
var name: String
var symbol: String
var info: String
var shape: Shape
## EMISSION: (longitud de onda, intensidad).  CURVE: (hora, valor 0-1).
var points: Array[Vector2] = []
## ABSORPTION: (centro, ancho, profundidad).  PEAKS: (posición, altura, ancho).
var bands: Array[Vector3] = []
var is_decoy: bool = false


func _init(p_id: String, p_name: String, p_symbol: String, p_info: String, p_shape: Shape) -> void:
    id = p_id
    name = p_name
    symbol = p_symbol
    info = p_info
    shape = p_shape


## Posiciones características sobre el eje (vacío para las curvas, que no tienen picos).
func positions() -> PackedFloat32Array:
    var found: PackedFloat32Array = PackedFloat32Array()
    match shape:
        Shape.EMISSION:
            for line: Vector2 in points:
                found.append(line.x)
        Shape.ABSORPTION, Shape.PEAKS:
            for band: Vector3 in bands:
                found.append(band.x)
        Shape.CURVE:
            pass
    return found


func copy_as_decoy() -> PatternSpec:
    var decoy: PatternSpec = PatternSpec.new(id, name, symbol, info, shape)
    decoy.points = points.duplicate()
    decoy.bands = bands.duplicate()
    decoy.is_decoy = true
    return decoy
