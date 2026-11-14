class_name CircuitTile
extends PipeTile
## Pieza de conducto con comportamiento eléctrico: además de forma y rotación lleva un componente
## (cable por defecto). Viaja con la pieza cuando el tablero la intercambia de celda.


var component: CircuitComponent


func _init(p_shape: PipeTile.Shape, p_rotation: int = 0, p_component: CircuitComponent = null) -> void:
    super._init(p_shape, p_rotation)
    component = p_component if p_component != null else Wire.new()


func snapshot() -> Dictionary:
    return {"component": component.snapshot()}


## Pieza con la forma y rotación dadas y el componente descrito en `saved` (lo que dio `snapshot`).
static func from_snapshot(p_shape: PipeTile.Shape, p_rotation: int, saved: Dictionary) -> CircuitTile:
    var component_data: Dictionary = saved["component"] as Dictionary
    var kind_name: String = str(component_data["kind"])
    var restored: CircuitComponent = null
    match CircuitComponent.Kind[kind_name] as CircuitComponent.Kind:
        CircuitComponent.Kind.WIRE:
            restored = Wire.new()
        CircuitComponent.Kind.RESISTOR:
            restored = Resistor.new(float(component_data["loss"]))
    return CircuitTile.new(p_shape, p_rotation, restored)
