class_name CircuitComponent
extends RefCounted
## Contrato de lo que lleva una pieza del circuito: transforma la potencia que la atraviesa.
## Las subclases sobrescriben `transmit` y `snapshot`; la base no conduce nada.


enum Kind { WIRE, RESISTOR }


## Potencia que sale de la pieza cuando entra `power`.
func transmit(power: float) -> float:
    push_error("CircuitComponent.transmit: la subclase debe implementarlo")
    return 0.0


## Datos primitivos para guardar: siempre lleva "kind" con el nombre del enum.
func snapshot() -> Dictionary:
    push_error("CircuitComponent.snapshot: la subclase debe implementarlo")
    return {}
