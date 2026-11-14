class_name Resistor
extends CircuitComponent
## Resistencia: pierde una fracción de la potencia que la atraviesa (0 = cable, 1 = corta todo).


var loss_fraction: float


func _init(p_loss_fraction: float) -> void:
    assert(p_loss_fraction >= 0.0 and p_loss_fraction <= 1.0, "Resistor: la pérdida es una fracción entre 0 y 1")
    loss_fraction = p_loss_fraction


func transmit(power: float) -> float:
    return power * (1.0 - loss_fraction)


func snapshot() -> Dictionary:
    return {"kind": CircuitComponent.Kind.keys()[CircuitComponent.Kind.RESISTOR], "loss": loss_fraction}
