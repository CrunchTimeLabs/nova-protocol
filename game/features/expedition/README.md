# expedition

## Propósito
Nivel de campaña "Expedición": laberinto → fundición → bodega → despegue → vuelo → órbita y análisis. Diseño completo en `GAMELOOP_EXPEDICION.md`.

## Escenarios
- DADO un metal recogido CUANDO termina el laberinto ENTONCES se asigna el mejor motor que alcanza (`Expedition.assign_engine`).
- DADO una bodega con masa máxima CUANDO se carga un instrumento que no cabe ENTONCES se rechaza.
- DADO un tramo de vuelo CUANDO el casco llega a 0 ENTONCES se pierde y va al informe; si no, llega y se orbita (`MissionFlow`).
- DADO un planeta CUANDO se analiza ENTONCES se gasta un análisis y se gana ciencia según el resultado (`AnalysisSession`).

## Qué reutilizar
- `MissionFlow` (flujo), `Expedition` (estado), `Catalog` (datos), `MazeRun`, `Flight`, `AnalysisSession`, `AnalysisLedger`; vistas en cada `view/`.

## Depende de
`toolkit/core`, `maze`, `inventory`, `precision`, `drag_drop`, `ui`, `fx`.

## Cubierto por
Nivel `app/levels/expedition.gd` ("Start"); `tests/features/expedition/`.
