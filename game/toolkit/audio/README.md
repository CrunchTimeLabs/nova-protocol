# audio

## Propósito
Sonidos sintetizados en tiempo de carga (PCM 16 bits), sin archivos de audio.

## Escenarios
- DADO notas y una forma de onda CUANDO se pide un tono ENTONCES devuelve un `AudioStreamWAV` listo para reproducir.
- DADO un golpe o retumbo CUANDO se pide ENTONCES se genera con ruido de semilla fija (siempre suena igual).

## Qué reutilizar
- `Synth` (`tone`, `sweep`, `boom`, `rumble`, `wav`). Nuevo porque el `Sfx` de la expedición está vacío y vive en otra feature (no se puede importar); la síntesis sale de `../game-mechanics/` (`Sfx`).

## Depende de
Nada.

## Cubierto por
Lab `Recolección` (vista; no se prueba con el ejecutor).
