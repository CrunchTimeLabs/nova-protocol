# fx

## Propósito
Efectos visuales. Los stubs sin estética se conservan por compatibilidad; los shaders de nebulosa y planeta solo los usa el nivel Meteoritos.

## Escenarios
- DADO una pantalla que pide estrellas, partículas o un planeta CUANDO usa estas clases ENTONCES no se dibuja nada decorativo (planeta = círculo plano).
- DADO un recuadro CUANDO se monta `ShaderBackdrop` ENTONCES se dibuja una nebulosa y un planeta lejano con los shaders, sin lógica.

## Qué reutilizar
- `Starfield`, `Bursts`, `PlanetView` (solo por compatibilidad con `features/expedition`); `ShaderBackdrop` (`view/`, shaders `nebula` y `planet` traídos de `game-mechanics`).

## Depende de
Nada.

## Cubierto por
`features/expedition`; nivel `app/levels/meteor_mission.gd` (`ShaderBackdrop`).
