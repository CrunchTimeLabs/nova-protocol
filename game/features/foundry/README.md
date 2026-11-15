# Foundry

## Propósito

Minijuego de fundición: los minerales aparecen cada 1,6–3,2 s, con un máximo de 3 activos, y cada uno vive un tiempo aleatorio entre 4 y 7 s. El jugador teclea su nombre para recogerlos antes de que se enfríen. La sesión dura 20 segundos y termina cuando el temporizador llega a cero.

## Escenarios

- DADO una sesión nueva CUANDO se crea ENTONCES el temporizador vale 20 s y los tres contadores valen cero.
- DADO que avanza el tiempo CUANDO se cumple el intervalo sorteado ENTONCES aparece un mineral aleatorio sin descontar tiempo extra.
- DADO un mineral activo CUANDO el jugador envía su nombre exacto ENTONCES su contador sube una unidad y el mineral desaparece.
- DADO un mineral activo CUANDO se agota su vida sorteada (entre 4 y 7 s) ENTONCES se descarta, cuenta como perdido y no suma al contador.
- DADO dos minerales del mismo tipo CUANDO se envía ese nombre ENTONCES se recoge solo el que tiene menos vida.
- DADO que el temporizador llega a cero CUANDO se hace el siguiente tick ENTONCES la sesión termina una sola vez y no procesa más.

## Qué reutilizar

- `FoundryRun.new(random)`: crea la sesión con un `GameRandom` inyectado; su estado público es `remaining`, `counts`, `active`, `lost` y `ended`.
- `FoundryRun.tick(delta)`: avanza el temporizador, las vidas y las apariciones; el dueño lo llama desde su bucle.
- `FoundryRun.collect(word)`: intenta recoger un mineral por nombre, sin distinguir mayúsculas; devuelve si recogió.
- `FoundryRun.count(mineral)`: consulta el contador de un mineral.
- Señales `spawned`, `collected`, `expired` y `run_ended`: para que una vista reaccione sin leer el estado cada fotograma.

`FoundryRun` es una clase nueva porque `Countdown` mide pasos fijos y `ResourceMeter` un valor acotado, pero ninguno modela apariciones con vida ni recogida por texto.

## Depende de

- `toolkit/core`: `GameRandom` para las apariciones y vidas reproducibles.
- `toolkit/ui/view`: `UiDraw` para el dibujo del laboratorio (solo la vista).

## Cubierto por

- Laboratorio: `app/labs/foundry.gd` y `scenes/foundry_lab.tscn`.
- Pruebas: `tests/features/foundry/test_foundry_run.gd` (10 pruebas).
- Nivel: no hay; el laboratorio compone la mecánica aislada.
