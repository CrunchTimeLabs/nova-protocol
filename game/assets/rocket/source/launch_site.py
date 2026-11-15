# Plataforma de lanzamiento nocturna (fondo del hangar). Cámara ortográfica: 1 unidad = 10 px a 256x160.
# Coordenadas: x_px = (X + 12.8) * 10 ; y_px = (16 - Z) * 10.
import bpy, math, random, sys
random.seed(7)
out = sys.argv[sys.argv.index("--") + 1]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 96
scene.cycles.use_denoising = False
scene.cycles.samples = 256
scene.render.resolution_x = 256
scene.render.resolution_y = 160
scene.render.resolution_percentage = 100
scene.render.filepath = out
scene.view_settings.view_transform = 'Standard'
scene.world = bpy.data.worlds.new("w")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.004, 0.006, 0.02, 1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = 1.0

def mat(name, color, emit=0.0, rough=0.8, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*color, 1)
        b.inputs["Emission Strength"].default_value = emit
    return m

def box(name, x0, x1, z0, z1, y=0.0, depth=1.0, material=None):
    bpy.ops.mesh.primitive_cube_add(location=((x0 + x1) / 2, y, (z0 + z1) / 2))
    o = bpy.context.object
    o.name = name
    o.scale = ((x1 - x0) / 2, depth / 2, (z1 - z0) / 2)
    if material:
        o.data.materials.append(material)
    return o

# Cielo: degradado vertical en un plano emisor lejano.
sky = bpy.data.materials.new("sky")
sky.use_nodes = True
nt = sky.node_tree
for n in list(nt.nodes):
    nt.nodes.remove(n)
outn = nt.nodes.new("ShaderNodeOutputMaterial")
em = nt.nodes.new("ShaderNodeEmission")
ramp = nt.nodes.new("ShaderNodeValToRGB")
sep = nt.nodes.new("ShaderNodeSeparateXYZ")
tc = nt.nodes.new("ShaderNodeTexCoord")
nt.links.new(tc.outputs["Generated"], sep.inputs[0])
nt.links.new(sep.outputs["Y"], ramp.inputs[0])
# La cámara ve del 0.33 (horizonte) al 0.67 (arriba) del plano.
ramp.color_ramp.elements[0].position = 0.34
ramp.color_ramp.elements[0].color = (0.30, 0.10, 0.28, 1)
ramp.color_ramp.elements[1].position = 0.66
ramp.color_ramp.elements[1].color = (0.004, 0.006, 0.025, 1)
mid = ramp.color_ramp.elements.new(0.42)
mid.color = (0.07, 0.04, 0.16, 1)
nt.links.new(ramp.outputs[0], em.inputs[0])
em.inputs[1].default_value = 1.0
nt.links.new(em.outputs[0], outn.inputs[0])
bpy.ops.mesh.primitive_plane_add(size=1, location=(0, 60, 8), rotation=(math.pi / 2, 0, 0))
p = bpy.context.object
p.scale = (40, 24, 1)
p.data.materials.append(sky)

# Estrellas y luna.
star = mat("star", (1.0, 0.95, 0.85), emit=6.0)
star_blue = mat("star_blue", (0.6, 0.75, 1.0), emit=5.0)
for i in range(75):
    x = random.uniform(-13, 13)
    z = random.uniform(5.0, 16)
    r = random.choice([0.035, 0.035, 0.045, 0.06, 0.08])
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(x, 50, z), segments=6, ring_count=4)
    bpy.context.object.data.materials.append(star_blue if random.random() < 0.3 else star)
moon = mat("moon", (0.95, 0.9, 0.75), emit=3.0)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.9, location=(-3.3, 45, 13.6))
bpy.context.object.data.materials.append(moon)
halo = mat("halo", (0.22, 0.2, 0.36), emit=0.5)
bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.1, location=(-3.3, 46, 13.6), rotation=(math.pi / 2, 0, 0))
bpy.context.object.data.materials.append(halo)

# Montañas lejanas (dos capas).
def ridge(name, y, base, peaks, color):
    verts = [(-14, y, 0)]
    xs = [-14 + i * 28 / (len(peaks) - 1) for i in range(len(peaks))]
    for x, h in zip(xs, peaks):
        verts.append((x, y, base + h))
    verts.append((14, y, 0))
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], [list(range(len(verts)))])
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat(name, color, emit=0.25))
ridge("far", 30, 1.0, [1.5, 3.2, 2.1, 4.4, 2.6, 3.8, 1.7, 3.0, 2.2, 4.0, 1.4], (0.13, 0.08, 0.25))
ridge("near", 20, 0.8, [0.6, 1.4, 2.4, 1.2, 0.8, 1.9, 1.1, 2.6, 1.3, 0.9, 1.6], (0.05, 0.04, 0.12))

# Suelo, plataforma y foso de llamas.
ground = mat("ground", (0.16, 0.15, 0.2), rough=0.95)
concrete = mat("concrete", (0.5, 0.5, 0.55), rough=0.9)
dark = mat("dark", (0.04, 0.04, 0.05))
stripe = mat("stripe", (0.95, 0.65, 0.1), emit=0.4)
box("ground", -14, 14, -0.5, 1.0, y=2, depth=8, material=ground)
box("pad", -2.6, 3.0, 1.0, 1.55, y=0, depth=4, material=concrete)
box("pad_step", -3.4, 3.8, 0.6, 1.05, y=0.5, depth=4, material=concrete)
box("trench", -0.9, 1.3, 0.62, 1.0, y=-1.4, depth=0.6, material=dark)
for i in range(7):
    x0 = -2.6 + i * 0.8
    box(f"stripe{i}", x0, x0 + 0.4, 1.5, 1.58, y=-1.6, depth=0.3, material=stripe)

# Torre de servicio (celosía) a la derecha del cohete.
steel = mat("steel", (0.75, 0.16, 0.1), rough=0.6, metal=0.2)
grey = mat("grey", (0.35, 0.37, 0.42), rough=0.6, metal=0.6)
tx0, tx1 = 3.4, 4.6
box("tower_l", tx0, tx0 + 0.18, 1.55, 13.4, material=steel)
box("tower_r", tx1 - 0.18, tx1, 1.55, 13.4, material=steel)
z = 1.55
while z < 13.2:
    box(f"rung{z}", tx0, tx1, z, z + 0.12, material=steel)
    bpy.ops.mesh.primitive_cube_add(location=((tx0 + tx1) / 2, 0, z + 0.6))
    o = bpy.context.object
    o.scale = (0.06, 0.5, 0.75)
    o.rotation_euler = (0, math.atan2(tx1 - tx0, 1.2), 0)
    o.data.materials.append(steel)
    z += 1.2
box("tower_cap", tx0 - 0.2, tx1 + 0.2, 13.4, 13.7, material=grey)
red = mat("red", (1.0, 0.08, 0.05), emit=12.0)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.16, location=((tx0 + tx1) / 2, -0.6, 13.95))
bpy.context.object.data.materials.append(red)
for zz in (4.2, 7.6, 10.8):
    box(f"arm{zz}", 2.35, tx0, zz, zz + 0.22, material=grey)
    box(f"arm_end{zz}", 2.25, 2.4, zz - 0.25, zz + 0.4, material=grey)

# Postes de luz con focos que iluminan la plataforma.
lamp = mat("lamp", (1.0, 0.92, 0.7), emit=20.0)
for x, d in ((-4.6, 1), (5.4, -1)):
    box(f"pole{x}", x - 0.08, x + 0.08, 1.0, 6.6, y=-0.5, depth=0.16, material=grey)
    box(f"lamp{x}", x - 0.35, x + 0.35, 6.6, 6.85, y=-0.5, depth=0.2, material=lamp)
    bpy.ops.object.light_add(type='SPOT', location=(x, -4, 6.6))
    l = bpy.context.object
    l.data.energy = 1400
    l.data.color = (1.0, 0.88, 0.65)
    l.data.spot_size = math.radians(70)
    l.data.spot_blend = 0.6
    l.rotation_euler = (math.radians(15), math.radians(-35 * d), 0)
bpy.ops.object.light_add(type='SUN', location=(0, -10, 20))
sun = bpy.context.object
sun.data.energy = 1.2
sun.data.color = (0.55, 0.6, 1.0)
sun.rotation_euler = (math.radians(55), math.radians(-20), 0)

# Brillo cálido bajo la plataforma (iluminación de servicio).
bpy.ops.object.light_add(type='AREA', location=(0.2, -3, 0.4))
glow = bpy.context.object
glow.data.energy = 250
glow.data.size = 6
glow.data.color = (1.0, 0.6, 0.3)
glow.rotation_euler = (math.radians(-80), 0, 0)

# Cámara ortográfica.
bpy.ops.object.camera_add(location=(0, -60, 8), rotation=(math.pi / 2, 0, 0))
cam = bpy.context.object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 25.6
scene.camera = cam
bpy.ops.render.render(write_still=True)
