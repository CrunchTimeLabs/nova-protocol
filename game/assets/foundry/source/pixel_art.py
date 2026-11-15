# Pixel art de la fundición: minerales (24x24) y marco del reloj de arena (28x48).
# Uso: python3 pixel_art.py  (escribe en ../). La arena la dibuja el juego con la misma forma del vidrio
# (HourglassDraw.half_width), así que si cambias GLASS_* aquí cámbialo también allí.
import math, random
from PIL import Image

OUT = "../"
PREFIX = "mineral_"
SIZE = 24


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


MINERALS = {
    "gold": dict(seed=3, ramp=["#4a2c05", "#9a620c", "#d99a18", "#f8cf3e", "#fff3a8"], outline="#2a1803",
                 specks=[("#fffbe0", 0.05, 0.75)], facets=True, radius=9.0, rough=0.22),
    "copper": dict(seed=8, ramp=["#3d170b", "#7c3317", "#b85a29", "#e38a4e", "#ffc596"], outline="#200b05",
                   specks=[("#3fae8c", 0.07, 0.0), ("#7fe0bb", 0.025, 0.0)], facets=False, radius=9.5, rough=0.3),
    "iron": dict(seed=21, ramp=["#1e2026", "#3c3f47", "#5f636d", "#8b919d", "#c7ced9"], outline="#0d0e11",
                 specks=[("#9a4a22", 0.06, 0.0), ("#e6edf7", 0.03, 0.7)], facets=True, radius=9.5, rough=0.26),
}


def mineral(name, cfg):
    rnd = random.Random(cfg["seed"])
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    cx, cy = SIZE / 2 - 0.5, SIZE / 2 + 0.5
    # Contorno irregular: radio con unas pocas ondas.
    waves = [(rnd.uniform(0, math.tau), rnd.randint(2, 5), rnd.uniform(0.4, 1.0)) for _ in range(4)]

    def radius(a):
        r = cfg["radius"]
        for phase, k, amp in waves:
            r += amp * cfg["rough"] * 4 * math.sin(k * a + phase)
        return r

    inside = [[False] * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            dx, dy = x - cx, (y - cy) * 1.12
            d = math.hypot(dx, dy)
            if d < radius(math.atan2(dy, dx)):
                inside[y][x] = True
    # Facetas: planos que dan cortes de luz (oro e hierro).
    planes = [(rnd.uniform(0, math.tau), rnd.uniform(-0.5, 0.5)) for _ in range(5)]
    light = (-0.7, -0.8, 0.35)
    ramp = [hexc(c) for c in cfg["ramp"]]
    for y in range(SIZE):
        for x in range(SIZE):
            if not inside[y][x]:
                continue
            dx, dy = (x - cx) / 10.0, (y - cy) / 10.0
            nz = math.sqrt(max(0.05, 1 - dx * dx - dy * dy))
            nx, ny = dx, dy
            if cfg["facets"]:
                a = math.atan2(dy, dx)
                sector = int((a + math.pi) / math.tau * len(planes)) % len(planes)
                ang, tilt = planes[sector]
                nx += 0.35 * math.cos(ang) + tilt * 0.2
                ny += 0.35 * math.sin(ang)
            n = math.sqrt(nx * nx + ny * ny + nz * nz)
            shade = (nx * light[0] + ny * light[1] + nz * light[2]) / n
            shade = shade * 0.75 + 0.22 + rnd.uniform(-0.05, 0.05)
            level = min(len(ramp) - 1, max(0, int(shade * len(ramp))))
            px[x, y] = ramp[level]
    # Motas (pátina, óxido, brillos): solo dentro y con la luz pedida (0 = cualquiera).
    for color, density, min_light in cfg["specks"]:
        for y in range(SIZE):
            for x in range(SIZE):
                if inside[y][x] and rnd.random() < density:
                    if min_light == 0.0 or px[x, y][:3] in [r[:3] for r in ramp[3:]]:
                        px[x, y] = hexc(color)
    # Brillo principal arriba a la izquierda.
    hx, hy = int(cx - 3), int(cy - 4)
    for x, y in ((hx, hy), (hx + 1, hy), (hx, hy + 1)):
        if inside[y][x]:
            px[x, y] = hexc("#ffffff")
    # Contorno oscuro de 1 px y sombra de contacto.
    out = img.copy()
    o = out.load()
    oc = hexc(cfg["outline"])
    for y in range(SIZE):
        for x in range(SIZE):
            if inside[y][x]:
                continue
            for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + ddx, y + ddy
                if 0 <= xx < SIZE and 0 <= yy < SIZE and inside[yy][xx]:
                    o[x, y] = oc
                    break
    out.save(OUT + f"{PREFIX}{name}.png")


# Reloj de arena: tapas de madera, postes y vidrio. Interior del vidrio entre GLASS_TOP y GLASS_BOTTOM.
W, H = 28, 48
GLASS_TOP, GLASS_BOTTOM, NECK = 6, 41, 23.5
MAX_HALF, NECK_HALF = 9.0, 1.0


def half_width(y):
    t = abs(y + 0.5 - NECK) / (NECK - GLASS_TOP)
    t = min(1.0, t)
    return NECK_HALF + (MAX_HALF - NECK_HALF) * math.sin(t * math.pi / 2) ** 0.8


def hourglass():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    wood = [hexc(c) for c in ("#2b1408", "#5a2e12", "#8a4a1e", "#b8702f", "#e0a060")]
    brass = [hexc(c) for c in ("#3a2a08", "#8a6418", "#d4a83a", "#ffe08a")]
    cx = W / 2 - 0.5
    # Vidrio: borde claro y relleno muy tenue.
    for y in range(GLASS_TOP, GLASS_BOTTOM + 1):
        hw = half_width(y)
        for x in range(W):
            d = abs(x - cx)
            if d <= hw + 0.5:
                px[x, y] = (170, 210, 255, 34)
            if hw - 0.5 < d <= hw + 1.5:
                px[x, y] = (190, 225, 255, 150)
    for y in range(GLASS_TOP + 2, NECK.__int__() - 3):
        x = int(cx - half_width(y) + 2.5)
        px[x, y] = (255, 255, 255, 170)
    # Tapas.
    for y0 in (0, H - 6):
        for y in range(y0, y0 + 6):
            for x in range(1, W - 1):
                level = 3 if y == y0 else 1 if y == y0 + 5 else 2
                if x in (1, W - 2):
                    level = 0
                px[x, y] = wood[level]
        for x in range(2, W - 2, 3):
            px[x, y0 + 2] = wood[4] if y0 == 0 else wood[3]
        for x in range(3, W - 3):
            px[x, y0 + (6 if y0 == 0 else -1)] = brass[1]
    # Postes laterales.
    for y in range(6, H - 6):
        for x, lv in ((2, 1), (3, 3), (4, 2), (W - 5, 1), (W - 4, 2), (W - 3, 0)):
            px[x, y] = wood[lv]
    for y in (14, 33):
        for x in (2, 3, 4, W - 5, W - 4, W - 3):
            px[x, y] = brass[2] if x in (3, W - 4) else brass[1]
    img.save(OUT + "hourglass.png")


if __name__ == "__main__":
    for key, cfg in MINERALS.items():
        mineral(key, cfg)
    hourglass()
