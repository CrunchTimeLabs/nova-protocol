class_name Wire
extends CircuitComponent
## Cable: deja pasar toda la potencia, sin pérdida.


func transmit(power: float) -> float:
    return power


func snapshot() -> Dictionary:
    return {"kind": CircuitComponent.Kind.keys()[CircuitComponent.Kind.WIRE]}
