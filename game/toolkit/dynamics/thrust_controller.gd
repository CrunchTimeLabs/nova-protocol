@abstract
class_name ThrustController
extends RefCounted
## Contrato de quien decide hacia dónde empujar (teclado, IA, replay…). No sabe nada de física ni de combustible.
## Devuelve la dirección del empuje con magnitud de 0 (motor apagado) a 1 (empuje máximo); el motor limita lo que pase de 1.


@abstract func thrust_command(position: Vector2, velocity: Vector2, delta: float) -> Vector2
