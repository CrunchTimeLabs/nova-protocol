# Convierte el render de una cinemática (raw_0001.png … a 512x320) en los cuadros del juego: 256x160 (pixel art,
# se dibuja x4 con filtro nearest), reducidos con caja y cuantizados a 96 colores.
# Uso: python3 build_frames.py <carpeta_render> <nombre>   → ../<nombre>/f001.png …
import sys, os, glob
from PIL import Image

src, name = sys.argv[1], sys.argv[2]
dst = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", name)
os.makedirs(dst, exist_ok=True)
for path in sorted(glob.glob(os.path.join(src, "raw_*.png"))):
    index = int(os.path.basename(path)[4:8])
    im = Image.open(path).convert("RGB").resize((256, 160), Image.BOX)
    im = im.quantize(colors=96, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    im.save(os.path.join(dst, "f%03d.png" % index), optimize=True)
print("cuadros:", len(os.listdir(dst)))
