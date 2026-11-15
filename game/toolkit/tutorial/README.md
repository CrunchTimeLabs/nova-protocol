# tutorial

## Propósito
Lección en pasos que se cumplen haciendo: cada paso tiene título, texto, etiqueta de demostración y un objetivo.

## Escenarios
- DADO un paso CUANDO se informa su objetivo ENTONCES pasa al siguiente (`report`); el objetivo de otro paso no cuenta.
- DADO el último paso cumplido CUANDO se consulta ENTONCES `is_done` y no hay paso actual.
- DADO una lección CUANDO se salta un paso o entera ENTONCES avanza o termina (`next`, `skip`).

## Qué reutilizar
- `TutorialSteps` (`current`, `report`, `next`, `skip`, `is_done`, señal `step_completed`). Nuevo: no había nada de tutoriales en el toolkit.

## Depende de
Nada.

## Cubierto por
Lab `Recolección`; `tests/toolkit/tutorial/`.
