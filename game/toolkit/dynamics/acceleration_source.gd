@abstract
class_name AccelerationSource
extends RefCounted
## Contrato de lo que empuja a un cuerpo sin ser su controlador (gravedad, viento, arrastre…).
## Devuelve una aceleración en unidades/s²; no cambia el cuerpo, solo responde a su estado.


@abstract func acceleration_at(position: Vector2, velocity: Vector2) -> Vector2
