# movement

## Propósito
Cuerpo que se mueve por intención (velocidad tope y respuesta), con controladores intercambiables.

## Escenarios
- DADO un controlador con dirección CUANDO avanza el tiempo ENTONCES el cuerpo alcanza la velocidad tope según el perfil (`MovementBody`).
- DADO una lista de puntos CUANDO el cuerpo los sigue ENTONCES va en orden y se detiene en el último (`WaypointController`).
- DADO una dirección inyectada CUANDO viene de teclado, mando o prueba ENTONCES el cuerpo no cambia (`ManualController`).

## Qué reutilizar
- `MovementBody`, `MovementProfile`, contrato `MovementController`, `ManualController`, `WaypointController`; vista `SquareView`.

## Depende de
Nada.

## Cubierto por
Lab `Movement`; `tests/toolkit/movement/`.
