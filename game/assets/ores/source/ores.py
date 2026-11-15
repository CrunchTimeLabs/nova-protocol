# Menas de la campaña (24x24, pixel art): las 5 que se recogen en el laberinto y se funden después.
# Uso: python3 ores.py  (escribe en ../). Reutiliza el generador de minerales de la fundición.
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../foundry/source"))
import pixel_art

ORES = {
    # Bauxita (aluminio): roca terrosa rosada con pisolitas.
    "bauxite": dict(seed=31, ramp=["#4a1c14", "#8a3a26", "#c4633f", "#e8956a", "#ffc9a2"], outline="#24100b",
                    specks=[("#f3d6b0", 0.06, 0.0), ("#6e2a1c", 0.06, 0.0)], facets=False, radius=9.5, rough=0.3),
    # Ilmenita (titanio): negra-violácea con brillo metálico.
    "ilmenite": dict(seed=44, ramp=["#120f1c", "#2a2540", "#4a4466", "#7a7398", "#c5bfe6"], outline="#07060c",
                     specks=[("#e8e4ff", 0.03, 0.7)], facets=True, radius=9.0, rough=0.24),
    # Hematita (hierro): rojo sangre con lustre gris.
    "hematite": dict(seed=52, ramp=["#2a0806", "#5e1410", "#93241c", "#c4463a", "#e8b0a8"], outline="#140303",
                     specks=[("#9da3ad", 0.05, 0.0), ("#d8dde6", 0.02, 0.7)], facets=True, radius=9.5, rough=0.26),
    # Pentlandita (níquel): bronce pálido amarillento.
    "pentlandite": dict(seed=63, ramp=["#3a2e0e", "#76622a", "#b39a4c", "#ddc77c", "#fff2c0"], outline="#1c1606",
                        specks=[("#5a5a50", 0.05, 0.0)], facets=True, radius=9.0, rough=0.22),
    # Calcopirita (cobre): dorado con irisaciones azul-verdosas.
    "chalcopyrite": dict(seed=77, ramp=["#2e2408", "#6e5a14", "#b0962a", "#e0c84c", "#fff4a0"], outline="#161104",
                         specks=[("#3fb0b0", 0.07, 0.0), ("#b05ad0", 0.04, 0.0)], facets=True, radius=9.5, rough=0.28),
}

pixel_art.OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..") + "/"
pixel_art.PREFIX = "ore_"
for key, cfg in ORES.items():
    pixel_art.mineral(key, cfg)
