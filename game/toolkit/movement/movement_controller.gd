@abstract
class_name MovementController
extends RefCounted
## Contrato de quien decide hacia dónde ir (teclado, IA, replay…). No sabe nada de física.
## Devuelve la dirección deseada con magnitud de 0 (quieto) a 1 (velocidad máxima); el cuerpo limita lo que pase de 1.


@abstract func desired_direction(position: Vector2, delta: float) -> Vector2
