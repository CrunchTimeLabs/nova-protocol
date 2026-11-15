# Cinemática 3 (10 s): el cohete viaja por el espacio; lluvia de meteoritos que esquiva; luego la trayectoria
# planeada (puntos cian, recta) y la real que se curva hacia un planeta (puntos rojos) hasta que corrige con el
# propulsor. Uso: blender -b -P space_hazards.py -- <carpeta_salida>
import bpy, math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cine_common import *

out = sys.argv[sys.argv.index("--") + 1]
setup(out, world=(0.004, 0.004, 0.012))
star = mat("star", (1.0, 0.95, 0.9), emit=8.0)
star_b = mat("star_b", (0.6, 0.75, 1.0), emit=6.0)
rnd = random.Random(5)
for i in range(160):
    sphere(f"star{i}", rnd.uniform(-40, 60), rnd.uniform(-14, 26), rnd.choice([0.04, 0.05, 0.07]), y=40,
           material=star_b if rnd.random() < 0.3 else star, segments=6)

# Cohete de lado (la nariz hacia +X).
root, parts, flame = rocket("ship", 0, 0, y=0.0)
root.rotation_euler = (0, math.radians(90), 0)
key_scale(flame, [(1, (1, 1, 1)), (120, (1, 1, 1))])

# Trayectoria del cohete: recto, esquiva (sube y baja) y al final se curva hacia el planeta y corrige.
path = [(1, (-6.0, 0.0, 6.0)), (40, (8.0, 0.0, 6.0)), (52, (14.0, 0.0, 8.0)), (64, (20.0, 0.0, 4.5)),
        (76, (26.0, 0.0, 6.0)), (98, (34.0, 0.0, 3.0)), (110, (38.0, 0.0, 3.4)), (120, (42.0, 0.0, 5.0))]
key_loc(root, path)
key_rot(root, [(1, (0, math.radians(90), 0)), (46, (0, math.radians(90), 0)), (52, (0, math.radians(60), 0)),
               (58, (0, math.radians(125), 0)), (70, (0, math.radians(75), 0)), (78, (0, math.radians(90), 0)),
               (96, (0, math.radians(120), 0)), (110, (0, math.radians(70), 0)), (120, (0, math.radians(85), 0))])

# Meteoritos (plano 2): cruzan en diagonal.
rockm = mat("meteor", (0.5, 0.36, 0.26), emit=0.0, rough=0.9)
glow = mat("meteor_glow", (1.0, 0.5, 0.2), emit=2.5)
for i in range(14):
    r = rnd.uniform(0.5, 1.3)
    m = rock(f"meteor{i}", 0, 0, r, rockm, 200 + i, y=-1.0 - rnd.uniform(0, 2))
    t0 = 34 + i * 3
    start = (14.0 + rnd.uniform(-4, 12), m.location.y, 16.0)
    end = (start[0] - 14.0, m.location.y, -6.0)
    objs = [(m, 0.0)]
    # Estela: tres chispas que siguen al meteorito por detrás (arriba a la derecha).
    for k in range(3):
        ember = sphere(f"ember{i}_{k}", 0, 0, r * (0.35 - 0.08 * k), y=m.location.y + 0.3, material=glow, segments=6)
        objs.append((ember, (k + 1) * 0.55 * r))
    for obj, back in objs:
        key_loc(obj, [(t0, (start[0] + back, obj.location.y, start[2] + back)), (t0 + 22, (end[0] + back, obj.location.y, end[2] + back))], interp='LINEAR')
    key_rot(m, [(t0, (0, 0, 0)), (t0 + 22, (rnd.uniform(-6, 6), rnd.uniform(-6, 6), 0))], interp='LINEAR')

# Planeta que tira de la nave (plano 3) y las dos trayectorias.
planet = mat("planet", (0.35, 0.5, 0.9), rough=0.8)
sphere("planet", 33.0, -6.0, 6.5, y=6.0, material=planet, segments=48)
atm = mat("atm", (0.4, 0.7, 1.0), emit=1.2, alpha=0.25)
sphere("atm", 33.0, -6.0, 7.1, y=6.5, material=mat("atm2", (0.3, 0.55, 1.0), emit=0.8), segments=48)
plan = mat("plan", (0.3, 0.9, 1.0), emit=4.0)
real = mat("real", (1.0, 0.3, 0.25), emit=5.0)
for k in range(14):
    x = 26.0 + k * 1.1
    d = sphere(f"plan{k}", x, 6.0, 0.12, y=-0.5, material=plan, segments=8)
    key_scale(d, [(1, (0, 0, 0)), (78 + k // 3, (0, 0, 0)), (79 + k // 3, (1, 1, 1))], interp='CONSTANT')
for k in range(10):
    t = k / 9.0
    x = 26.0 + t * 9.0
    z = 6.0 - 3.2 * t * t
    d = sphere(f"real{k}", x, z, 0.14, y=-0.6, material=real, segments=8)
    key_scale(d, [(1, (0, 0, 0)), (82 + k * 2, (0, 0, 0)), (83 + k * 2, (1, 1, 1))], interp='CONSTANT')
# Aviso rojo pulsante alrededor de la nave mientras se desvía.
warn = mat("warn", (1.0, 0.2, 0.15), emit=3.0, alpha=0.35)
ring = bpy.ops.mesh.primitive_torus_add(location=(0, 0, 0), major_radius=1.8, minor_radius=0.07, rotation=(math.pi / 2, 0, 0))
ring = bpy.context.object
ring.data.materials.append(warn)
ring.parent = None
pts = []
for f in range(1, 121, 3):
    loc = None
    pts.append(f)
for f in range(1, 121):
    pass
ring_points = []
for frame, loc in path:
    ring_points.append((frame, (loc[0] + 2.4, -0.8, loc[2])))
key_loc(ring, ring_points)
pulse = [(1, (0, 0, 0)), (84, (0, 0, 0))]
for k in range(6):
    f = 85 + k * 4
    pulse += [(f, (1.0, 1.0, 1.0)), (f + 2, (1.3, 1.3, 1.3))]
pulse += [(108, (0, 0, 0))]
key_scale(ring, pulse, interp='LINEAR')

light('SUN', (0, -10, 20), 2.5, (1.0, 0.95, 0.9), rot=(math.radians(60), math.radians(-30), 0))
light('AREA', (20, -12, 2), 120, (0.4, 0.6, 1.0), rot=(math.radians(90), 0, 0), size=30)

cam = camera(x=0.0, z=6.0, width=16.0)
key_loc(cam, [(1, (-2.0, -60, 6.0)), (40, (8.0, -60, 6.0)), (76, (23.0, -60, 5.6)), (98, (31.0, -60, 4.4)), (120, (37.0, -60, 4.6))], interp='LINEAR')
render()
