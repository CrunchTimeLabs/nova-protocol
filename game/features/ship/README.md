# ship

## Propósito
Nave: armar el cohete arrastrando piezas de pixel art (carga útil, aviónica, tanques, tuberías, propulsión) y despegar con el cohete armado.

## Escenarios
- DADO el hangar CUANDO se abre ENTONCES el cohete está vacío con sus 5 huecos marcados y la paleta muestra las 11 piezas con títulos simples.
- DADO una pieza CUANDO se suelta cerca del cohete ENTONCES se acomoda sola en su sección (sustituye la que hubiera); soltada lejos vuelve a su tarjeta.
- DADO una pieza del cohete CUANDO se arrastra fuera ENTONCES se quita; R vacía el cohete.
- DADO las 5 secciones llenas CUANDO se pulsa DESPEGAR o ESPACIO ENTONCES cuenta atrás 3-2-1, despega el cohete armado con llama, humo y temblor, llega a órbita y vuelve al hangar conservando el cohete.
- DADO el cohete armado CUANDO llega a órbita ENTONCES `ShipWorkshop` emite `orbit_reached` (el nivel «Nave» de Start muestra entonces un botón «Continuar»).
- DADO el cohete incompleto CUANDO se intenta despegar ENTONCES no despega.
- Se pueden armar las 48 combinaciones (2×2×2×2×3); apiladas con 1 px de solape coinciden pixel a pixel con `cohetes_completos` de los assets.

## Qué reutilizar
- `RocketParts` (catálogo: secciones, piezas, títulos, imágenes, alturas, boqueras).
- `RocketBuild` (el cohete: `place`, `remove`, `part_at`, `is_complete`, `code`, `all_combinations`).
- `HangarSession` (fases ARMANDO → DESPEGANDO → EN ÓRBITA con `StateMachine`).
- Vistas: `ShipWorkshop`, `PartsPalette`, `HangarPanel`, `RocketView`, `ShipStage`, `LaunchSmoke`, `ShipSfx`.
- Viene de `HoldScreen` de `../game-mechanics` (arrastrar a la nave), sin masa ni instrumentos: solo el armado.

## Depende de
`assembly` (`SlotAssembly`), `drag_drop` (`DragSession`), `core` (`StateMachine`), `ui` (`UiDraw`), `audio` (`Synth`).

## Cubierto por
Lab `Nave`; nivel `Nave` (`app/levels/ship_build_stage.gd`); `tests/features/ship/`, `tests/toolkit/assembly/`.

## Assets
`game/assets/rocket/`: piezas x1 copiadas de "assets para cohete" y el fondo `launch_site.png` (Blender; ver `assets/rocket/source/LEEME.txt`).
