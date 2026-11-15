# campaign

Lo que comparten los niveles de «Start».

- `Ores`: las 5 menas de la campaña y su elemento puro. Para cada una guarda el punto de fusión, el color, el peso y la imagen.
- `CampaignState`: el estado que pasa de un nivel al siguiente. Es estático y `reset()` lo vacía al pulsar Start. Guarda:
  - las menas recogidas;
  - las piezas desbloqueadas;
  - el cohete que despegó.
- `Cinematics` y `view/CinematicPlayer`: las cinemáticas de 10 s, hechas con Blender en `assets/cinematics/source`, con sus subtítulos y etiquetas.
- `view/StartBackdrop`: el fondo animado del menú, donde el cohete esquiva asteroides.
