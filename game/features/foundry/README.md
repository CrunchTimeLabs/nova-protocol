# Foundry

## Propósito

Minijuego de fundición según el guion de `MAYBER/message.txt`. Tiene dos relojes independientes:

- **Nivel (20 s):** el reloj de arena. Al agotarse se detienen las apariciones y todos los temporizadores.
- **Mineral (6–9 s):** cada objetivo tiene el suyo, sorteado según su tipo. Arranca solo cuando el mineral es elegido y pasa al centro.

Funcionamiento de cada ronda:

- Al empezar la ronda, la tolva se completa hasta un grupo de 3 o 4 minerales. Cada mineral nuevo gasta recursos.
- Del grupo se eligen al azar 1 o 2, que pasan al centro. Los que no se eligen esperan en la tolva y entran en el grupo siguiente.
- Para recoger un objetivo se teclea su nombre.
- Si su tiempo se agota, el mineral desaparece y los recursos gastados en él se pierden. Los recursos son solo un contador visual.
- La ronda siguiente empieza cuando el centro queda vacío.

| Mineral | Frecuencia | Valor | Vida | Coste |
|---------|-----------|-------|------|-------|
| Oro     | rara (17) | 50    | 4–5 s | 4 |
| Hierro  | media (33)| 20    | 5–6 s | 2 |
| Cobre   | común (50)| 10    | 6–7 s | 1 |

## Escenarios

- DADO una sesión nueva CUANDO se crea ENTONCES el reloj vale 20 s y los tres contadores valen cero.
- DADO el centro vacío CUANDO pasa la pausa ENTONCES la tolva se completa a 3 o 4 y van 1 o 2 al centro.
- DADO minerales que esperan CUANDO llega el grupo siguiente ENTONCES siguen en él sin volver a gastar recursos.
- DADO un objetivo CUANDO se teclea su nombre exacto ENTONCES sube su contador y su valor, queda RECOLECTADO y no se puede recoger otra vez.
- DADO dos objetivos CUANDO se recoge uno ENTONCES el reloj del otro no cambia.
- DADO un objetivo CUANDO se agota su reloj ENTONCES queda PERDIDO, desaparece y sus recursos no se devuelven.
- DADO un mineral en la tolva CUANDO se teclea su nombre ENTONCES no se recoge (solo los del centro).
- DADO que la arena se agota CUANDO se hace el siguiente tick ENTONCES la sesión termina una sola vez y todo queda congelado.

## Qué reutilizar

- `FoundryRun.new(random)` crea la sesión con un `GameRandom` inyectado. Su estado público:
  - `remaining`, `counts`, `waiting`, `active`;
  - `lost`, `resources_used`, `resources_lost`;
  - `value`, `rounds`, `ended`.
- `tick(delta)` avanza la sesión, `collect(word)` intenta recoger un mineral y `count(mineral)` consulta un contador.
- Señales para la vista: `group_spawned`, `selected`, `collected`, `expired` y `run_ended`.

- DADO `blocked` en true CUANDO se intenta recoger ENTONCES se rechaza sin cambiar nada y los relojes siguen corriendo (lo usa el nivel «Fundición dúo» con la temperatura).

## Vista (`view/`)

- `FoundryScreen`: la pantalla completa. Con `handles_restart` en false, F5/ENTER emiten `restart_requested` en vez de reiniciar solos, y si `run.blocked` ignora las letras y muestra «BLOQUEADO». Tiene:
  - el fondo del horno, el reloj de arena, la tolva sobre la cinta y las tarjetas del centro (imagen, nombre, barra verde→amarilla→roja y estado);
  - el almacén con los contadores, los recursos y el resumen final;
  - animaciones de caída, vuelo al centro, vuelo al almacén, brasas y el temblor del texto si una letra es incorrecta.
- `HourglassDraw`: dibuja la arena con la misma forma del vidrio que el marco pixel art.
- `FoundryArt`: la paleta, las imágenes y el color de la barra.
- `FoundrySfx`: los sonidos, sintetizados con `Synth`.
- Los assets están en `assets/foundry/`. Sus generadores están en `assets/foundry/source/`: el fondo con Blender (`foundry_hall.py`) y los minerales y el reloj con PIL (`pixel_art.py`).

## Depende de

- `toolkit/core`: `GameRandom`.
- `toolkit/ui/view`: `UiDraw`.
- `toolkit/audio/view`: `Synth`.

## Cubierto por

- Laboratorio: `app/labs/foundry.gd` y `scenes/foundry_lab.tscn`; nivel `app/levels/foundry_duo_level.gd`.
- Pruebas: `tests/features/foundry/test_foundry_run.gd` (14 pruebas).
