# circuit

## Propósito
Capa eléctrica sobre el tablero de tuberías: reparte potencia y las piezas la transforman.

## Escenarios
- DADO fuentes con vatios CUANDO la potencia atraviesa una resistencia ENTONCES pierde su fracción (`Resistor`).
- DADO un circuito generado CUANDO se crea ENTONCES hay solución con margen sobre la demanda (`CircuitGenerator`).
- DADO un `PowerGrid` CUANDO se resuelve ENTONCES cada destino indica si recibe lo que demanda.

## Qué reutilizar
- `PowerGrid`, `CircuitGenerator`, `CircuitConfig`, `CircuitTile`, contrato `CircuitComponent`, `Wire`, `Resistor`; vista `CircuitView`.

## Depende de
`toolkit/puzzle`.

## Cubierto por
Lab `Circuit`; `tests/toolkit/circuit/`.
