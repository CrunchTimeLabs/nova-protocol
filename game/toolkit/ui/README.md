# ui

## Propósito
Utilidades de dibujo genéricas (texto, paneles, tarjetas, barras, colores de espectro en gris) y un HUD básico de pantalla dividida.

## Escenarios
- DADO un `CanvasItem` CUANDO se llama a `UiDraw.panel`, `card` o `bar` ENTONCES dibuja formas planas sin sombras ni bordes redondeados.
- DADO un nivel con dos pantallas CUANDO se añaden controles a `SplitHud` ENTONCES se ordenan en zonas izquierda, centro y derecha sin conocer el juego.

## Qué reutilizar
- `UiDraw`.
- `SplitHud`: franja con `add_left/add_center/add_right`. Se crea aparte porque `UiDraw` solo dibuja y `MeterBar` es una sola barra: nadie ordenaba zonas por lado.

## Depende de
Nada.

## Cubierto por
`features/expedition`; `SplitHud` en `app/levels/meteor_mission.gd`.
