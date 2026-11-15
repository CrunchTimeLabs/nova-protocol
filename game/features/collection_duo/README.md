# collection_duo

Recolección a dos en el mismo laberinto, sin pantalla dividida. J1 juega con WASD y entra por la izquierda; J2 juega con IJKL y entra por la derecha.

- Las menas son las 5 de `Ores`. Aparecen junto a uno de los dos jugadores, por turnos, con el tiempo justo para llegar.
- Los derrumbes nunca caen junto a ningún jugador ni dejan a nadie sin camino. Para eso se añadieron `MazeCaveIns.also_protected` y `goal`.
- La rampa de abajo se abre cuando entre los dos juntan el mínimo de la dificultad. La partida termina cuando los dos están sobre la rampa.
- El resumen final muestra quién recogió más.
- Mientras dura el tutorial grande del centro (`is_warming_up`) no aparece nada. El tutorial se cierra cuando los dos han entrado.

Archivos:

- Reglas: `DuoRun`, `DuoLevel` y `MazeCar`.
- Vista: `view/`.
- Nivel: `app/levels/collection_stage.gd`.
- Pruebas: `tests/features/collection_duo/`.
