# collection

## Propósito
Recolección: el cochecito recorre un laberinto dinámico recogiendo minerales para la fundición. Un tutorial acompaña al lado sin pausar y cada paso se cumple haciendo lo que enseña.

## Escenarios
- DADO el lab CUANDO se entra ENTONCES se elige dificultad sobre la vista previa del laberinto: Fácil 13×11 (cada derrumbe tapa 2 pasos de 8–14 s, máx. 6 a la vez), Medio 15×13 (4 pasos, 10–18 s, máx. 12), Difícil 18×15 (6 pasos, 12–22 s, máx. 20); se acumulan de un derrumbe al siguiente. Lo demás es igual en todos.
- DADO la partida CUANDO pasa cada bloque de 15 s ENTONCES hay un 95 % (igual en todos los niveles) de que caiga un derrumbe en un momento al azar del bloque (`ChanceWindow`).
- DADO cualquier nivel CUANDO cae un derrumbe ENTONCES con un 30 % cae justo delante del cochecito (nunca encima ni cortando la salida) y llueven rocas grandes de adorno por la pantalla (3/5/8) con temblor; no tocan el juego.
- DADO el lab CUANDO empieza ENTONCES se juega ya y la tarjeta del tutorial entra por el lado: conducir → recoger un mineral → recoger un cristal → la salida (ENTER salta un paso).
- DADO un paso CUANDO el jugador hace lo que pide ENTONCES se felicita y pasa al siguiente.
- DADO la partida CUANDO pasa el tiempo ENTONCES aparecen minerales de 5 tipos (Metal 10, Cobre 15, Cristal 25, Oro 40, Amatista 60; los valiosos son raros) a 2–12 pasos, con la vida justa del camino más corto (margen de x2.2 el metal a x1.15 la amatista, +1.5 s); su barra se vacía y parpadean al final.
- DADO el cochecito descentrado frente a un pasillo abierto CUANDO empuja hacia él ENTONCES se centra solo y entra (asistencia de esquina).
- DADO un mineral CUANDO el cochecito pasa por encima ENTONCES se recoge solo y suma al almacén.
- DADO un derrumbe CUANDO cae ENTONCES las rocas tapan sus pasos el tiempo del nivel, nunca encima del cochecito ni cortando su salida; el primero abre su lección, que se cierra al despejarse.
- DADO el cochecito CUANDO entra en la rampa ENTONCES termina con el total. R: otro laberinto del mismo nivel (solo salen las lecciones no vistas). Esc: volver a la dificultad. Si el anfitrión activa `can_continue` (nivel «Recolección» de Start), el cuadro final añade «Enter: continuar» y Enter emite `continue_requested`.

## Qué reutilizar
- `CollectionLevel` (datos de cada dificultad).
- `CollectionRun` (entidad: cochecito, minerales, derrumbes, almacén; señales `collected`, `mineral_lost`, `cave_in_started`, `finished`).
- `CollectionSession` (orquestador: fases, tutorial por objetivos, lección del derrumbe).
- `CollectionDemo` (demostraciones con piloto automático para el tutorial).
- Vistas: `LevelSelect`, `CollectionScreen`, `TutorialCard`, `RockRain`, `CollectionDraw`, `RocksDraw`, `CollectionFx`, `CollectionSfx`.
- No reutiliza `MazeRun` de la expedición: es otra feature (no se importa) y depende de `Expedition`/`Catalog`.

## Depende de
`maze` (`Maze`, `MazeCaveIns`), `spawn` (`TimedSpawns`), `inventory` (`Tally`), `tutorial` (`TutorialSteps`), `time` (`ChanceWindow`), `core` (`StateMachine`, `GameRandom`), `ui` (`UiDraw`), `audio` (`Synth`).

## Cubierto por
Lab `Recolección`; nivel `Recolección` (`app/levels/collection_stage.gd`, primera etapa de Start); `tests/features/collection/`.
