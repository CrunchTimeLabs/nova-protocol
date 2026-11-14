class_name HeadingThrustController
extends ThrustController
## Orden de empuje relativa al rumbo: "adelante" es hacia donde va el cuerpo, así las teclas significan lo mismo
## en cualquier punto de la trayectoria. Envuelve a otro controlador (teclado, mando…) cuya orden se lee así:
##   -y = adelante (acelera a lo largo de la velocidad)    +y = atrás (frena la velocidad tangencial)
##   +x = a la derecha del rumbo                           -x = a la izquierda del rumbo
## "Derecha" e "izquierda" son del cuerpo mirando adelante, con y hacia abajo en pantalla. Es empuje extra: se suma
## a las fuentes (gravedad, etc.) y no las sustituye. Casi quieto, el rumbo no está definido y la orden se queda como llega.


## Por debajo de esta velocidad no hay rumbo fiable.
const MIN_SPEED_FOR_HEADING: float = 0.0001

var _inner: ThrustController


func _init(p_inner: ThrustController) -> void:
    assert(p_inner != null, "HeadingThrustController necesita un controlador interior")
    _inner = p_inner


func thrust_command(position: Vector2, velocity: Vector2, delta: float) -> Vector2:
    var command: Vector2 = _inner.thrust_command(position, velocity, delta)
    if velocity.length() < MIN_SPEED_FOR_HEADING:
        return command
    var forward: Vector2 = velocity.normalized()
    var right: Vector2 = Vector2(-forward.y, forward.x)
    return forward * -command.y + right * command.x
