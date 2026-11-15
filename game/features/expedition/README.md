# expedition

## Propósito
Nivel de campaña "Expedición": laberinto → fundición → bodega → despegue → vuelo → órbita y análisis. Diseño completo en `GAMELOOP_EXPEDICION.md`.

## Escenarios
- DADO un metal recogido CUANDO termina el laberinto ENTONCES se asigna el mejor motor que alcanza (`Expedition.assign_engine`).
- DADO una bodega con masa máxima CUANDO se carga un instrumento que no cabe ENTONCES se rechaza.
- DADO un tramo de vuelo CUANDO el casco llega a 0 ENTONCES se pierde y va al informe; si no, llega y se orbita (`MissionFlow`).
- DADO el modo meteoritos (`Flight.meteor_field`) CUANDO se vuela ENTONCES caen solo rocas, con la densidad pedida, y siguen haciendo daño.
- DADO un planeta CUANDO se analiza ENTONCES se gasta un análisis y se gana ciencia según el resultado (`AnalysisSession`).
- DADO el nivel Análisis (`AnalysisLevel`) CUANDO arranca ENTONCES la nave lleva un equipo fijo (tres analizadores, sin mejoras) y orbita la Luna; al continuar, informe y vuelta al menú.

## Qué reutilizar
- `MissionFlow` (flujo), `Expedition` (estado), `Catalog` (datos), `MazeRun`, `Flight`, `AnalysisSession`, `AnalysisLedger`; vistas en cada `view/`.

## Depende de
`toolkit/core`, `maze`, `inventory`, `precision`, `drag_drop`, `ui`, `fx`.

## Cubierto por
Niveles `app/levels/expedition.gd` ("Start") y `app/levels/analysis.gd` ("Análisis"); `tests/features/expedition/`.
