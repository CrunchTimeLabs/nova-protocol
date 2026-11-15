# thermal

## Propósito
Una magnitud (temperatura) que se mueve sola de forma inestable y que el jugador corrige, más su reloj analógico.

## Escenarios
- DADO una aguja CUANDO pasa cada intervalo ENTONCES elige al azar subir o bajar y deriva sin salir de la escala (`UnstableGauge`).
- DADO un impulso del jugador CUANDO se aplica `push` ENTONCES la aguja sube o baja esa cantidad, acotada a la escala.
- DADO una escala, un rango objetivo y una lectura CUANDO se dibuja ENTONCES se ve el arco con marcas, el rango resaltado y la aguja (`DialView`).

- DADO una escala por tramos CUANDO se pide la posición de un valor ENTONCES se interpola entre sus puntos, ampliando unas zonas y comprimiendo otras (`ScaleMap`, solo presentación).

## Qué reutilizar
- `UnstableGauge` (valor con deriva aleatoria con semilla; `drift_speed` y `change_interval` ajustables) y la vista `DialView` (colores con `set_colors`; escala por tramos con `set_map` y marcas con `set_marks`). `UnstableGauge` acepta otro máximo de escala y dos ajustes opcionales de sensación: `wander_response` (deriva suave) y `push_damping` (la deriva se atenúa mientras el jugador empuja). `ScaleMap`: valor → posición en el arco, sin tocar el valor.
- No usa `Countdown`/`TimedCycle` para la deriva: la dirección cambia a un intervalo propio y no recorre una secuencia de pasos.

## Depende de
`toolkit/core` (`GameRandom`).

## Cubierto por
Lab «Fundición temperatura» (`features/foundry_temperature`); `tests/toolkit/thermal/`.
