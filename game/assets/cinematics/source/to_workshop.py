# Cinemática 2 (10 s): los lingotes llegan al taller, una prensa los convierte en piezas y las piezas se apilan
# en el cohete. Uso: blender -b -P to_workshop.py -- <carpeta_salida>
import bpy, math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cine_common import *

out = sys.argv[sys.argv.index("--") + 1]
setup(out, world=(0.01, 0.012, 0.02))
METALS = [(0.82, 0.84, 0.88), (0.6, 0.64, 0.72), (0.42, 0.42, 0.46), (0.78, 0.78, 0.7), (0.9, 0.48, 0.25)]

iron = mat("iron", (0.22, 0.23, 0.26), rough=0.4, metal=0.8)
yellow = mat("yellow", (0.95, 0.7, 0.1), rough=0.5)
dark = mat("dark", (0.05, 0.05, 0.06))
box("back", -20, 20, -1, 18, y=6, depth=1, material=mat("back", (0.07, 0.08, 0.1), rough=1.0))
for i in range(9):
    x = -16 + i * 4
    box(f"panel{i}", x, x + 3.8, 1, 12, y=5.4, depth=0.2, material=mat(f"panel{i}", (0.1, 0.11, 0.14), rough=0.8))
    box(f"strip{i}", x + 0.4, x + 3.4, 8.6, 8.8, y=5.2, depth=0.1, material=mat(f"strip{i}", (0.3, 0.7, 1.0), emit=2.0))
box("floor", -20, 20, -1, 0.5, y=0, depth=8, material=mat("floor", (0.14, 0.14, 0.16), rough=0.9))
for i in range(10):
    x = -19 + i * 4
    box(f"stripe{i}", x, x + 2, 0.5, 0.52, y=-3, depth=0.4, material=yellow)

# Cinta y prensa (izquierda).
box("belt", -14, -2, 1.4, 1.7, y=0, depth=1.6, material=dark)
box("belt_legs", -13.5, -2.5, 0.5, 1.4, y=0, depth=1.2, material=iron)
box("press_frame_l", -9.6, -9.2, 1.7, 7.5, y=0, depth=1.4, material=yellow)
box("press_frame_r", -6.8, -6.4, 1.7, 7.5, y=0, depth=1.4, material=yellow)
box("press_top", -9.8, -6.2, 7.0, 7.6, y=0, depth=1.6, material=yellow)
ram = box("press_ram", -9.1, -6.9, 4.5, 6.9, y=0, depth=1.2, material=iron)
pts = [(1, ram.location.copy())]
for hit in (14, 26, 38):
    down = (ram.location.x, ram.location.y, ram.location.z - 2.4)
    pts += [(hit - 3, ram.location.copy()), (hit, down), (hit + 4, ram.location.copy())]
key_loc(ram, pts)

# Lingotes en la cinta: pasan bajo la prensa y salen como placas curvas (piezas).
for i, color in enumerate(METALS):
    m = mat(f"metal{i}", color, emit=0.3, rough=0.35, metal=0.3)
    ingot = box(f"ingot{i}", -0.8, 0.8, 1.7, 2.3, y=0, depth=0.8, material=m)
    plate = cyl(f"plate{i}", 0, 1.85, 0.8, 0.25, y=0, material=m, rot=(0, 0, 0))
    t_in = 1 + i * 7
    t_press = 14 + (i % 3) * 12
    xs = -15 + 0.0
    key_loc(ingot, [(1, (xs - i * 2.4, 0, 1.9)), (t_press, (-8.0, 0, 1.9)), (t_press + 1, (-8.0, 0, 1.9))])
    key_scale(ingot, [(t_press - 1, (1, 1, 1)), (t_press, (0.0, 0.0, 0.0))], interp='CONSTANT')
    key_scale(plate, [(1, (0, 0, 0)), (t_press, (0, 0, 0)), (t_press + 1, (1, 1, 1))], interp='CONSTANT')
    key_loc(plate, [(t_press, (-8.0, 0, 1.85)), (t_press + 10, (-3.0, 0, 1.85)), (44, (-1.0, 0, 1.85))])

# Chispas en cada golpe.
spark = mat("spark", (1.0, 0.75, 0.3), emit=10.0)
rnd = random.Random(3)
for hit in (14, 26, 38):
    for k in range(10):
        sp = sphere(f"spark{hit}_{k}", -8.0, 2.0, 0.06, y=-0.9, material=spark, segments=6)
        end = (-8.0 + rnd.uniform(-2.5, 2.5), -0.9, 2.0 + rnd.uniform(0.2, 2.2))
        key_loc(sp, [(hit, (-8.0, -0.9, 2.0)), (hit + 6, end)])
        key_scale(sp, [(hit - 1, (0, 0, 0)), (hit, (1, 1, 1)), (hit + 6, (1, 1, 1)), (hit + 7, (0, 0, 0))], interp='CONSTANT')

# Plano 2 y 3: las piezas del cohete vuelan desde la cinta y se apilan en la plataforma (derecha).
pad = box("pad", 6.5, 11.5, 0.5, 0.9, y=0, depth=3, material=iron)
root, parts, flame = rocket("rocket", 9.0, 0.9, flame=False)
sections = parts[:5]
order = [0, 1, 2, 3, 4]
for k, idx in enumerate(order):
    piece = sections[idx]
    final = piece.location.copy()
    t0 = 46 + k * 6
    key_loc(piece, [(1, (final.x - 6.0, final.y, 7.5)), (t0, (final.x - 6.0, final.y, 7.5)), (t0 + 6, final)])
for extra in parts[5:]:
    key_scale(extra, [(1, (0, 0, 0)), (76, (0, 0, 0)), (78, (1, 1, 1))], interp='CONSTANT')

# Brazo de grúa que acompaña cada pieza.
crane = box("crane", 2.0, 2.3, 9.2, 17, y=-0.3, depth=0.3, material=yellow)
key_loc(crane, [(46, (crane.location.x - 7.0, crane.location.y, crane.location.z)), (76, (crane.location.x + 6.8, crane.location.y, crane.location.z)), (82, (crane.location.x + 14.0, crane.location.y, crane.location.z))])

# Focos que se encienden sobre el cohete terminado.
spots = []
for sx in (5.0, 13.0):
    l = light('SPOT', (sx, -6, 9), 0, (1.0, 0.9, 0.7), rot=(math.radians(60), math.radians(-20 if sx > 9 else 20), 0), size=0.5)
    l.data.spot_size = math.radians(40)
    l.data.keyframe_insert("energy", frame=80)
    l.data.energy = 4000
    l.data.keyframe_insert("energy", frame=86)
light('AREA', (0, -10, 14), 350, (0.7, 0.78, 1.0), rot=(math.radians(55), 0, 0), size=26)
light('POINT', (-8.0, -3.0, 3.0), 400, (1.0, 0.55, 0.2), size=0.5)
light('AREA', (9.0, -4.0, 1.2), 300, (1.0, 0.5, 0.2), rot=(math.radians(-70), 0, 0), size=4)
light('SUN', (0, -10, 20), 1.0, (0.8, 0.8, 0.95), rot=(math.radians(50), math.radians(25), 0))

cam = camera(x=-7.0, z=3.2, width=10.0)
key_loc(cam, [(1, (-9.0, -60, 3.3)), (42, (-6.5, -60, 3.3))], interp='LINEAR')
key_loc(cam, [(43, (8.2, -60, 3.5)), (79, (8.8, -60, 3.5))], interp='LINEAR')
key_loc(cam, [(80, (9.0, -60, 4.2)), (120, (9.0, -60, 4.6))], interp='LINEAR')
for frame, width in ((1, 10.0), (42, 10.0), (43, 9.5), (79, 9.5), (80, 9.0), (120, 12.0)):
    cam.data.ortho_scale = width
    cam.data.keyframe_insert("ortho_scale", frame=frame)
for fc in list(cam.animation_data.action.fcurves) + list(cam.data.animation_data.action.fcurves):
    for kp in fc.keyframe_points:
        if int(kp.co.x) in (42, 79) or (fc.data_path == "ortho_scale" and int(kp.co.x) in (1, 43)):
            kp.interpolation = 'CONSTANT'
render()
