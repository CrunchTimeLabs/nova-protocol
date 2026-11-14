# dynamics

## Propósito
Física por aceleraciones: cuerpo con empuje de un motor y fuentes externas (gravedad, viento).

## Escenarios
- DADO un cuerpo con motor y combustible CUANDO el controlador ordena empuje ENTONCES gasta combustible y, al acabarse, empuja menos (`ThrustEngine`).
- DADO una gravedad central CUANDO el cuerpo está cerca ENTONCES lo atrae hacia el punto (`CentralGravity`).
- DADO un controlador relativo al rumbo CUANDO se pulsa "adelante" ENTONCES empuja hacia donde va el cuerpo (`HeadingThrustController`).

## Qué reutilizar
- `DynamicBody`, `ThrustEngine`, contratos `ThrustController` y `AccelerationSource`, `CentralGravity`, `UniformAcceleration`, `ManualThrustController`, `HeadingThrustController`; vista `OrbitView`.

## Depende de
Nada.

## Cubierto por
Lab `Orbit`; `tests/toolkit/dynamics/`.
