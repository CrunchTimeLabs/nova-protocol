# core

## Propósito
Primitivas que casi todo usa: azar con semilla, máquina de estados, medidor de recurso, bitácora y guardado.

## Escenarios
- DADO una semilla CUANDO se repite la secuencia ENTONCES el azar da los mismos valores (`GameRandom`).
- DADO un medidor con máximo CUANDO se suma o resta más de lo permitido ENTONCES se acota a 0..máximo y avisa al vaciarse o llenarse (`ResourceMeter`).
- DADO una tabla de transiciones CUANDO se pide una transición ilegal ENTONCES es un error visible (`StateMachine`).
- DADO un `Dictionary` primitivo CUANDO se guarda y se carga ENTONCES se conserva con número de versión (`SaveSlot`).

## Qué reutilizar
- `GameRandom`, `ResourceMeter`, `StateMachine` + `State`, `MessageLog`, `SaveSlot`; vista `MeterBar`.

## Depende de
Nada.

## Cubierto por
Lab `Resource meter`; `tests/toolkit/core/`.
