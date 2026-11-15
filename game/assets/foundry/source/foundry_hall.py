# Interior de la fundición (fondo del lab Fundición). Cámara ortográfica: 1 unidad = 10 px a 256x160.
# Coordenadas: x_px = (X + 12.8) * 10 ; y_px = (16 - Z) * 10. Se dibuja x4 (1024x640) con filtro nearest.
# Zonas que deja libres la interfaz: tolva (cinta) en Z ~11.8, objetivos en el centro (Z 5..10), suelo abajo.
import bpy, math, random, sys
random.seed(11)
out = sys.argv[sys.argv.index("--") + 1]

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 512
scene.cycles.use_denoising = False
scene.render.resolution_x = 512
scene.render.resolution_y = 320
# Se renderiza a 512x320 y se reduce a 256x160 (menos ruido sin denoiser).
scene.render.resolution_percentage = 100
scene.render.filepath = out
scene.view_settings.view_transform = 'Standard'
scene.world = bpy.data.worlds.new("w")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.01, 0.008, 0.012, 1)
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


def bricks(name, c1, c2, mortar, scale, row=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = 0.95
    tex = nt.nodes.new("ShaderNodeTexBrick")
    tex.inputs["Color1"].default_value = (*c1, 1)
    tex.inputs["Color2"].default_value = (*c2, 1)
    tex.inputs["Mortar"].default_value = (*mortar, 1)
    tex.inputs["Scale"].default_value = scale
    tex.inputs["Mortar Size"].default_value = 0.035
    tex.inputs["Row Height"].default_value = row
    # Las paredes están en el plano XZ: el ladrillo usa (X, Z) como (u, v).
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    comb = nt.nodes.new("ShaderNodeCombineXYZ")
    nt.links.new(tc.outputs["Object"], sep.inputs[0])
    nt.links.new(sep.outputs["X"], comb.inputs["X"])
    nt.links.new(sep.outputs["Z"], comb.inputs["Y"])
    nt.links.new(sep.outputs["Y"], comb.inputs["Z"])
    nt.links.new(comb.outputs[0], tex.inputs["Vector"])
    nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    return m


def box(name, x0, x1, z0, z1, y=0.0, depth=1.0, material=None):
    bpy.ops.mesh.primitive_cube_add(location=((x0 + x1) / 2, y, (z0 + z1) / 2))
    o = bpy.context.object
    o.name = name
    o.scale = ((x1 - x0) / 2, depth / 2, (z1 - z0) / 2)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material:
        o.data.materials.append(material)
    return o


def cyl(name, x, z, r, depth, y=0.0, material=None, rot=(math.pi / 2, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=(x, y, z), rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    if material:
        o.data.materials.append(material)
    return o


# Pared del fondo: ladrillo oscuro.
wall = bricks("wall", (0.20, 0.08, 0.055), (0.15, 0.06, 0.045), (0.035, 0.025, 0.025), 0.9)
box("wall", -14, 14, 0, 17, y=3, depth=1, material=wall)

# Horno arriba al centro: cuerpo de piedra, arco y boca incandescente.
stone = bricks("stone", (0.32, 0.29, 0.27), (0.26, 0.24, 0.23), (0.08, 0.07, 0.07), 1.6, row=0.45)
iron = mat("iron", (0.16, 0.16, 0.18), rough=0.45, metal=0.85)
rust = mat("rust", (0.35, 0.16, 0.08), rough=0.7, metal=0.4)
fire = mat("fire", (1.0, 0.36, 0.06), emit=2.0)
fire_core = mat("fire_core", (1.0, 0.62, 0.2), emit=3.0)
box("furnace", -5.2, 5.2, 12.6, 17, y=1.6, depth=2, material=stone)
cyl("mouth_arch", 0, 13.9, 2.7, 0.5, y=0.55, material=stone)
cyl("mouth", 0, 13.9, 2.25, 0.3, y=0.35, material=fire)
box("mouth_low", -2.25, 2.25, 12.6, 13.9, y=0.35, depth=0.3, material=fire)
cyl("mouth_core", 0, 13.3, 1.2, 0.2, y=0.15, material=fire_core)
for i in range(9):
    gx = -2.0 + i * 0.5
    box(f"grate{i}", gx - 0.07, gx + 0.07, 12.6, 16.0, y=0.0, depth=0.12, material=iron)
box("grate_bar", -2.4, 2.4, 13.4, 13.55, y=-0.05, depth=0.12, material=iron)
box("lintel", -5.4, 5.4, 15.6, 16.2, y=0.4, depth=0.6, material=iron)
for x in (-4.6, 4.6):
    box(f"rivet{x}", x - 0.15, x + 0.15, 15.75, 16.05, y=0.05, depth=0.2, material=rust)

# Cinta transportadora (la tolva de la interfaz) bajo el horno.
belt = mat("belt", (0.13, 0.12, 0.12), rough=0.9)
box("belt", -7.2, 7.2, 11.55, 11.95, y=0, depth=1.2, material=belt)
box("belt_frame", -7.4, 7.4, 11.1, 11.55, y=-0.1, depth=1.2, material=iron)
x = -7.0
while x <= 7.01:
    cyl(f"roller{x}", x, 11.32, 0.18, 0.4, y=-0.75, material=rust, verts=12)
    x += 1.0
for x in (-7.0, 7.0):
    box(f"leg{x}", x - 0.15, x + 0.15, 9.6, 11.1, y=0, depth=0.3, material=iron)

# Pilares de piedra que enmarcan el centro.
pillar = bricks("pillar", (0.30, 0.27, 0.25), (0.24, 0.22, 0.21), (0.07, 0.06, 0.06), 1.8, row=0.4)
for x0 in (-8.6, 7.2):
    box(f"pillar{x0}", x0, x0 + 1.4, 0, 16, y=0.8, depth=1.2, material=pillar)
    box(f"cap{x0}", x0 - 0.2, x0 + 1.6, 10.6, 11.0, y=0.4, depth=1.4, material=iron)

# Faroles en los pilares.
lamp = mat("lamp", (1.0, 0.7, 0.3), emit=6.0)
for x in (-7.9, 7.9):
    box(f"lamp_box{x}", x - 0.35, x + 0.35, 8.0, 8.9, y=-0.2, depth=0.5, material=iron)
    box(f"lamp{x}", x - 0.22, x + 0.22, 8.15, 8.75, y=-0.5, depth=0.2, material=lamp)
    bpy.ops.object.light_add(type='POINT', location=(x, -1.5, 8.4))
    l = bpy.context.object
    l.data.energy = 120
    l.data.color = (1.0, 0.65, 0.3)
    l.data.shadow_soft_size = 0.4

# Cadenas colgando con ganchos.
chain = mat("chain", (0.3, 0.3, 0.32), rough=0.4, metal=0.9)
for x, bottom in ((-5.6, 6.0), (5.8, 7.2)):
    z = 11.0
    while z > bottom:
        bpy.ops.mesh.primitive_torus_add(location=(x, 0.9, z), major_radius=0.16, minor_radius=0.05,
                                         rotation=(0, 0, math.pi / 2 if int(z * 3) % 2 else 0))
        bpy.context.object.data.materials.append(chain)
        z -= 0.26
    bpy.ops.mesh.primitive_torus_add(location=(x + 0.15, 0.9, bottom - 0.25), major_radius=0.3, minor_radius=0.08,
                                     rotation=(math.pi / 2, 0, 0))
    bpy.context.object.data.materials.append(chain)

# Suelo de piedra y canal de metal fundido.
floor = bricks("floor", (0.17, 0.15, 0.14), (0.13, 0.12, 0.11), (0.05, 0.045, 0.04), 1.3)
box("floor", -14, 14, -1, 2.6, y=0, depth=6, material=floor)
molten = mat("molten", (1.0, 0.3, 0.05), emit=1.5)
molten_hot = mat("molten_hot", (1.0, 0.55, 0.18), emit=2.4)
box("channel_edge", -14, 14, 1.7, 2.05, y=-3.05, depth=0.2, material=iron)
box("channel", -14, 14, 1.25, 1.7, y=-3.05, depth=0.2, material=molten)
for i in range(18):
    x = random.uniform(-12.5, 12.5)
    w = random.uniform(0.3, 0.9)
    box(f"hot{i}", x, x + w, 1.4, 1.55, y=-3.2, depth=0.1, material=molten_hot)

# Crisoles a los lados del centro, con metal brillando.
for x in (-10.6, 10.6):
    cyl(f"crucible{x}", x, 3.5, 1.15, 1.6, y=-1, material=iron, rot=(0, 0, 0))
    cyl(f"crucible_glow{x}", x, 4.31, 0.95, 0.04, y=-1, material=molten, rot=(0, 0, 0))
    box(f"crucible_band{x}", x - 1.2, x + 1.2, 3.2, 3.45, y=-1.7, depth=0.1, material=rust)

# Moldes (lingoteras) en el suelo, abajo del centro.
for i, x in enumerate((-4.4, -1.5, 1.4, 4.3)):
    box(f"mold{i}", x - 1.0, x + 1.0, 2.6, 3.05, y=-1.2, depth=1.2, material=iron)
    box(f"ingot{i}", x - 0.75, x + 0.75, 2.95, 3.12, y=-1.6, depth=0.6,
        material=molten if i % 2 == 0 else rust)

# Luz del horno (cálida, desde arriba), relleno frío tenue y brillo del canal.
bpy.ops.object.light_add(type='AREA', location=(0, -3.5, 13.2))
f = bpy.context.object
f.data.energy = 1400
f.data.size = 5
f.data.color = (1.0, 0.5, 0.18)
f.rotation_euler = (math.radians(-60), 0, 0)
bpy.ops.object.light_add(type='AREA', location=(0, -6, 1.6))
g = bpy.context.object
g.data.energy = 700
g.data.size = 26
g.data.color = (1.0, 0.45, 0.15)
g.rotation_euler = (math.radians(-100), 0, 0)
bpy.ops.object.light_add(type='SUN', location=(0, -10, 20))
s = bpy.context.object
s.data.energy = 0.25
s.data.color = (0.5, 0.55, 1.0)
s.rotation_euler = (math.radians(50), math.radians(25), 0)

bpy.ops.object.camera_add(location=(0, -60, 8), rotation=(math.pi / 2, 0, 0))
cam = bpy.context.object
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 25.6
scene.camera = cam
bpy.ops.render.render(write_still=True)
