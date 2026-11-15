# Cinemática 4 (10 s): el cohete llega al planeta, entra en órbita y despliega tres haces de colores (los
# instrumentos) que barren la superficie. Uso: blender -b -P arrival.py -- <carpeta_salida>
import bpy, math, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cine_common import *

out = sys.argv[sys.argv.index("--") + 1]
setup(out, world=(0.004, 0.004, 0.012))
star = mat("star", (1.0, 0.95, 0.9), emit=8.0)
rnd = random.Random(9)
for i in range(140):
    sphere(f"star{i}", rnd.uniform(-30, 30), rnd.uniform(-12, 26), rnd.choice([0.04, 0.05, 0.07]), y=60, material=star, segments=6)

# Planeta con bandas de color (luna gris-azulada con cráteres) y atmósfera.
surface = mat("surface", (0.55, 0.5, 0.62), rough=0.95)
planet = sphere("planet", 0, -27.5, 26.0, y=20, material=surface, segments=96)
# Superficie con manchas (ruido): mares oscuros y tierras claras.
nt = surface.node_tree
noise = nt.nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 0.6
noise.inputs["Detail"].default_value = 6.0
ramp = nt.nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.42
ramp.color_ramp.elements[0].color = (0.3, 0.27, 0.4, 1)
ramp.color_ramp.elements[1].position = 0.58
ramp.color_ramp.elements[1].color = (0.62, 0.56, 0.7, 1)
nt.links.new(noise.outputs["Fac"], ramp.inputs[0])
nt.links.new(ramp.outputs[0], nt.nodes["Principled BSDF"].inputs["Base Color"])
atm = mat("atm", (0.45, 0.7, 1.0), emit=0.9)
sphere("atm", 0, -27.5, 26.7, y=45, material=atm, segments=96)

# Cohete: llega desde arriba a la izquierda (grande y cerca) y queda orbitando sobre el horizonte.
root, parts, flame = rocket("ship", 0, 0, y=0.0)
key_loc(root, [(1, (-16.0, 0, 12.0)), (40, (-3.0, 0, 3.4)), (60, (0.0, 0, 2.8)), (120, (4.0, 0, 2.9))])
key_rot(root, [(1, (0, math.radians(120), 0)), (40, (0, math.radians(100), 0)), (60, (0, math.radians(90), 0)), (120, (0, math.radians(84), 0))])
key_scale(flame, [(1, (1, 1, 1)), (40, (1, 1, 1)), (46, (0.3, 0.3, 0.3)), (120, (0.3, 0.3, 0.3))])

# Haces de los instrumentos: conos translúcidos hacia la superficie que se encienden uno tras otro y barren.
BEAMS = [((0.75, 0.45, 1.0), 64), ((0.35, 1.0, 0.55), 74), ((1.0, 0.65, 0.25), 84)]
for i, (color, t0) in enumerate(BEAMS):
    m = mat(f"beam{i}", color, emit=0.7, alpha=0.22)
    m.shadow_method = 'NONE'
    beam = cone(f"beam{i}", 0, 0, 1.4, 0.05, 4.5, y=-0.5 - i * 0.1, material=m)
    key_scale(beam, [(1, (0, 0, 0)), (t0, (0, 0, 0)), (t0 + 3, (1, 1, 1)), (120, (1, 1, 1))], interp='LINEAR')
    sweep = []
    for k in range(t0, 121, 6):
        base_x = 0.0 + (k - 60) * 4.0 / 60.0 + 1.2
        sweep.append((k, (base_x + 2.6 * math.sin((k - t0) * 0.12 + i * 2.0), -0.5 - i * 0.1, 0.3)))
    sweep.insert(0, (t0 - 1, sweep[0][1]))
    key_loc(beam, sweep, interp='LINEAR')
    # Anillos que aparecen en el suelo donde mide cada haz.
    ping_m = mat(f"ping{i}", color, emit=1.2)
    for p in range(3):
        bpy.ops.mesh.primitive_torus_add(location=(0, -0.4, -1.95), major_radius=0.5, minor_radius=0.05, rotation=(math.pi / 2, 0, 0))
        ring = bpy.context.object
        ring.data.materials.append(ping_m)
        f0 = t0 + 6 + p * 10
        x = sweep[min(len(sweep) - 1, 1 + p * 2)][1][0]
        ring.location = (x, -0.4 - i * 0.1, -1.6)
        key_scale(ring, [(1, (0, 0, 0)), (f0, (0.2, 0.2, 0.2)), (f0 + 10, (2.4, 2.4, 2.4)), (f0 + 11, (0, 0, 0))], interp='LINEAR')

light('SUN', (0, -10, 20), 3.0, (1.0, 0.95, 0.88), rot=(math.radians(55), math.radians(-40), 0))
light('AREA', (0, -10, 6), 6, (0.4, 0.6, 1.0), rot=(math.radians(80), 0, 0), size=30)

cam = camera(x=0.0, z=6.0, width=34.0)
key_loc(cam, [(1, (-6.0, -60, 4.5)), (40, (-1.0, -60, 2.2)), (60, (1.5, -60, 1.0)), (120, (3.5, -60, 0.9))])
for frame, width in ((1, 30.0), (40, 18.0), (60, 12.0), (120, 11.0)):
    cam.data.ortho_scale = width
    cam.data.keyframe_insert("ortho_scale", frame=frame)
render()
