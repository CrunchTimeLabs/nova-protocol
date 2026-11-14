# drag_drop

## Propósito
Arrastrar y soltar sin pantalla, con regla de aceptación inyectada.

## Escenarios
- DADO un arrastre CUANDO se suelta en una zona que la regla acepta ENTONCES resultado ACCEPTED.
- DADO un arrastre CUANDO la regla lo rechaza ENTONCES REJECTED y el arrastre termina.
- DADO un arrastre CUANDO se cancela ENTONCES CANCELLED.

## Qué reutilizar
- `DragSession` (`begin`, `drop`, `cancel`, señal `dropped`).

## Depende de
Nada.

## Cubierto por
Lab `Drag drop`; `tests/toolkit/drag_drop/`.
