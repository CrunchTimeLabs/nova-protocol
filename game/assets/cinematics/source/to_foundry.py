# Cinemática 1 (10 s): las menas viajan en vagoneta desde la mina hasta el horno y salen como lingotes puros.
# Uso: blender -b -P to_foundry.py -- <carpeta_salida>
import bpy, math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cine_common import *

out = sys.argv[sys.argv.index("--") + 1]
setup(out, world=(0.012, 0.008, 0.01))

ORES = [  # color de la mena, color del metal puro
    ((0.85, 0.42, 0.3), (0.82, 0.84, 0.88)),   # bauxita -> aluminio
    ((0.32, 0.28, 0.5), (0.6, 0.64, 0.72)),    # ilmenita -> titanio
    ((0.7, 0.16, 0.12), (0.42, 0.42, 0.46)),   # hematita -> hierro
    ((0.8, 0.7, 0.4), (0.78, 0.78, 0.7)),      # pentlandita -> níquel
    ((0.75, 0.62, 0.2), (0.9, 0.48, 0.25)),    # calcopirita -> cobre
]

rockm = mat("rock", (0.16, 0.12, 0.1), rough=1.0)
dark = mat("dark", (0.05, 0.04, 0.04))
iron = mat("iron", (0.2, 0.2, 0.22), rough=0.4, metal=0.8)
rust = mat("rust", (0.4, 0.18, 0.08), rough=0.7, metal=0.3)
wood = mat("wood", (0.3, 0.17, 0.08), rough=0.9)
brick = mat("brick", (0.32, 0.12, 0.08), rough=0.95)
fire = mat("fire", (1.0, 0.4, 0.08), emit=1.6)
molten = mat("molten", (1.0, 0.45, 0.1), emit=3.0)

# Fondo: pared de la mina a la izquierda, nave de la fundición a la derecha.
box("back", -14, 14, -1, 17, y=6, depth=1, material=mat("back", (0.08, 0.06, 0.06), rough=1.0))
box("cave_wall", -14, -4.5, -1, 17, y=4, depth=1, material=rockm)
for i in range(14):
    rnd = random.Random(i)
    rock(f"cave_rock{i}", rnd.uniform(-13, -5), rnd.uniform(0, 16), rnd.uniform(0.6, 1.4), rockm, i, y=3)
cyl("tunnel", -9, 3.2, 2.6, 1, y=3.4, material=dark, verts=32)
for x in (-11.5, -6.5):
    box(f"beam{x}", x - 0.2, x + 0.2, 0.5, 6.0, y=2.5, depth=0.4, material=wood)
box("lintel", -11.8, -6.2, 5.6, 6.1, y=2.5, depth=0.4, material=wood)

# Suelo y rieles.
box("floor", -14, 14, -1, 0.5, y=0, depth=8, material=mat("floor", (0.12, 0.1, 0.09), rough=1.0))
box("rail", -14, 6, 0.5, 0.62, y=-0.5, depth=0.15, material=iron)
for i in range(28):
    x = -13.5 + i * 0.7
    box(f"tie{i}", x, x + 0.3, 0.45, 0.55, y=-0.5, depth=1.2, material=wood)

# Horno grande (derecha) con boca, chimenea y caño de colada.
box("furnace", 4.5, 11.5, 0.5, 9.5, y=1.5, depth=3, material=brick)
cyl("mouth", 6.0, 8.0, 1.0, 0.4, y=0.0, material=fire)
for i in range(5):
    gx = 5.3 + i * 0.35
    box(f"grate{i}", gx - 0.05, gx + 0.05, 7.0, 9.0, y=-0.3, depth=0.1, material=iron)
box("chimney", 9.0, 10.5, 9.5, 17, y=1.5, depth=1.5, material=brick)
box("spout", 3.0, 4.6, 3.6, 4.1, y=0.0, depth=0.6, material=iron)
fire_light = light('POINT', (6.0, -2.0, 7.5), 300, (1.0, 0.5, 0.2), size=1.0)
fire_light.data.keyframe_insert("energy", frame=1)
fire_light.data.energy = 900
fire_light.data.keyframe_insert("energy", frame=58)
fire_light.data.energy = 500
fire_light.data.keyframe_insert("energy", frame=120)
key_emit(fire, [(1, 1.6), (50, 1.6), (58, 5.0), (75, 2.4)])

# Rampa elevadora que sube del suelo a la boca del horno.
ramp = box("ramp", -1.0, 5.0, 0.0, 0.3, y=-0.2, depth=1.6, material=iron)
ramp.rotation_euler = (0, -math.atan2(7.0, 6.0) * 0.6, 0)

# Vagoneta con las 5 menas: entra desde el túnel y se detiene al pie de la rampa.
cart = box("cart", -1.4, 1.4, 0.75, 2.0, y=-0.5, depth=1.6, material=rust)
wheels = []
for wx in (-0.8, 0.8):
    w = cyl(f"wheel{wx}", wx, 0.75, 0.35, 0.3, y=-1.4, material=iron, verts=12)
    wheels.append(w)
ores = []
for i, (ore_color, metal_color) in enumerate(ORES):
    m = mat(f"ore{i}", ore_color, emit=0.4, rough=0.5, metal=0.3)
    o = rock(f"ore{i}", -1.0 + i * 0.5, 2.25 + (i % 2) * 0.25, 0.42, m, 100 + i, y=-0.6)
    ores.append(o)
group = [cart] + wheels + ores
start_dx, stop_dx = -9.5, 0.0
# Posiciones de reposo (antes de animar: luego Blender evalúa la animación y `location` cambia).
rest = {obj.name: obj.location.copy() for obj in group}
for obj in group:
    base = rest[obj.name]
    key_loc(obj, [(1, (base.x + start_dx, base.y, base.z)), (36, (base.x + stop_dx, base.y, base.z))])
for w in wheels:
    key_rot(w, [(1, (math.pi / 2, 0, 0)), (36, (math.pi / 2, -14.0, 0))])

# Las menas saltan una a una al horno (arco hasta la boca).
for i, o in enumerate(ores):
    f0 = 38 + i * 4
    base = rest[o.name]
    mid = (3.5, base.y, 9.5)
    end = (6.0, 0.4, 8.0)
    key_loc(o, [(f0, (base.x + stop_dx, base.y, base.z)), (f0 + 5, mid), (f0 + 9, end)])
    key_scale(o, [(f0 + 8, (1, 1, 1)), (f0 + 10, (0.01, 0.01, 0.01))])

# Colada: un cazo lleno de metal fundido pasa sobre cinco lingoteras y vierte en cada una; cada lingote se
# enfría hasta el color de su metal puro (Al, Ti, Fe, Ni, Cu).
MOLD_X = [0.6, 2.6, 4.6, 6.6, 8.6]
ladle = cyl("ladle", MOLD_X[0], 4.2, 0.7, 1.0, y=-2.6, material=iron, rot=(0, 0, 0), verts=16)
ladle_top = cyl("ladle_top", MOLD_X[0], 4.72, 0.6, 0.05, y=-2.6, material=molten, rot=(0, 0, 0), verts=16)
arm = box("ladle_arm", MOLD_X[0] - 0.08, MOLD_X[0] + 0.08, 4.9, 9.0, y=-2.6, depth=0.16, material=iron)
stream = box("stream", MOLD_X[0] - 0.14, MOLD_X[0] + 0.14, 1.2, 3.6, y=-2.6, depth=0.28, material=molten)
for obj in (ladle, ladle_top, arm, stream):
    # Fuera de cuadro hasta el último plano.
    points = [(1, (30.0, obj.location.y, obj.location.z)), (63, (30.0, obj.location.y, obj.location.z))]
    for i, x in enumerate(MOLD_X):
        t0 = 66 + i * 10
        points += [(t0, (x, obj.location.y, obj.location.z)), (t0 + 6, (x, obj.location.y, obj.location.z))]
    points.insert(2, (64, (MOLD_X[0] - 0.01, obj.location.y, obj.location.z)))
    key_loc(obj, points)
    for fc in obj.animation_data.action.fcurves:
        for kp in fc.keyframe_points:
            if int(kp.co.x) == 63:
                kp.interpolation = 'CONSTANT'
pours = [(1, (1, 1, 0.0))]
for i in range(5):
    t0 = 66 + i * 10
    pours += [(t0, (1, 1, 0.0)), (t0 + 1, (1, 1, 1)), (t0 + 6, (1, 1, 1)), (t0 + 7, (1, 1, 0.0))]
key_scale(stream, pours, interp='CONSTANT')
for i, (ore_color, metal_color) in enumerate(ORES):
    x = MOLD_X[i]
    box(f"mold{i}", x - 0.85, x + 0.85, 0.5, 1.0, y=-2.6, depth=1.0, material=iron)
    hot = mat(f"ingot_hot{i}", (1.0, 0.42, 0.1), emit=2.2)
    cool = mat(f"ingot{i}", metal_color, emit=0.35, rough=0.35, metal=0.2)
    ingot = box(f"ingot{i}", x - 0.7, x + 0.7, 0.9, 1.15, y=-2.7, depth=0.8, material=cool)
    glow = box(f"ingot_glow{i}", x - 0.7, x + 0.7, 0.9, 1.17, y=-2.75, depth=0.8, material=hot)
    t0 = 67 + i * 10
    key_scale(ingot, [(1, (1, 1, 0.0)), (t0, (1, 1, 0.0)), (t0 + 5, (1, 1, 1))])
    key_scale(glow, [(1, (1, 1, 0.0)), (t0, (1, 1, 0.0)), (t0 + 5, (1, 1, 1)), (t0 + 16, (1, 1, 1)), (t0 + 26, (1, 1, 0.0))])

# La vagoneta vacía vuelve a la mina antes del último plano.
for obj in [cart] + wheels:
    base = rest[obj.name]
    key_loc(obj, [(36, (base.x + stop_dx, base.y, base.z)), (60, (base.x + stop_dx, base.y, base.z)), (63, (base.x - 12.0, base.y, base.z))])

# Luces: cálida del horno, fría de la mina y relleno.
light('AREA', (-9, -6, 4), 150, (0.5, 0.6, 1.0), rot=(math.radians(80), 0, 0), size=6)
light('AREA', (0, -10, 12), 500, (1.0, 0.75, 0.55), rot=(math.radians(60), 0, 0), size=20)
light('SUN', (0, -10, 20), 0.6, (0.7, 0.7, 0.9), rot=(math.radians(55), math.radians(20), 0))

# Cámara: empieza mirando la mina y se desplaza hacia el horno y las lingoteras.
# Tres planos con corte: la vagoneta sale de la mina, las menas entran al horno, la colada llena los moldes.
cam = camera(x=-4.0, z=3.5, width=13.0)
key_loc(cam, [(1, (-5.5, -60, 3.6)), (38, (-2.5, -60, 3.6))], interp='LINEAR')
key_loc(cam, [(39, (3.2, -60, 5.0)), (63, (3.6, -60, 5.2))], interp='LINEAR')
key_loc(cam, [(64, (4.6, -60, 2.6)), (120, (4.6, -60, 2.4))], interp='LINEAR')
for frame, width in ((1, 13.0), (63, 13.0), (64, 10.5)):
    cam.data.ortho_scale = width
    cam.data.keyframe_insert("ortho_scale", frame=frame)
for fc in cam.data.animation_data.action.fcurves:
    for kp in fc.keyframe_points:
        kp.interpolation = 'CONSTANT'
for fc in cam.animation_data.action.fcurves:
    for kp in fc.keyframe_points:
        if int(kp.co.x) in (38, 63):
            kp.interpolation = 'CONSTANT'
render()
