# thermal

## Propósito
Una magnitud (temperatura) que se mueve sola de forma inestable y que el jugador corrige, más su reloj analógico.

## Escenarios
- DADO una aguja CUANDO pasa cada intervalo ENTONCES elige al azar subir o bajar y deriva sin salir de la escala (`UnstableGauge`).
- DADO un impulso del jugador CUANDO se aplica `push` ENTONCES la aguja sube o baja esa cantidad, acotada a la escala.
- DADO una escala, un rango objetivo y una lectura CUANDO se dibuja ENTONCES se ve el arco con marcas, el rango resaltado y la aguja (`DialView`).

## Qué reutilizar
- `UnstableGauge` (valor con deriva aleatoria con semilla; `drift_speed` y `change_interval` ajustables) y la vista `DialView` (colores configurables con `set_colors`).
- No usa `Countdown`/`TimedCycle` para la deriva: la dirección cambia a un intervalo propio y no recorre una secuencia de pasos.

## Depende de
`toolkit/core` (`GameRandom`).

## Cubierto por
Lab «Fundición temperatura» (`features/foundry_temperature`); `tests/toolkit/thermal/`.
