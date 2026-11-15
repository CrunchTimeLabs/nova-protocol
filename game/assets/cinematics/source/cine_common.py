# Utilidades comunes de las cinemáticas (Blender 4, EEVEE). Cámara ortográfica de lado: 1 unidad = 20 px a
# 512x320 (se reduce a 256x160 y se dibuja x4). x_px = (X + 12.8) * 20 ; y_px = (8 - Z) * 20 con la cámara en Z=8... 
# (ver `camera`). FPS 12, 120 cuadros = 10 s.
import bpy, math, random

FPS = 12
FRAMES = 120


def setup(out_dir, world=(0.01, 0.01, 0.02)):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = bpy.context.scene
    s.render.engine = 'BLENDER_EEVEE'
    s.eevee.taa_render_samples = 32
    s.eevee.use_bloom = True
    s.eevee.bloom_intensity = 0.08
    s.eevee.bloom_threshold = 0.9
    s.eevee.use_soft_shadows = True
    s.render.resolution_x = 512
    s.render.resolution_y = 320
    s.render.fps = FPS
    s.frame_start = 1
    s.frame_end = FRAMES
    s.render.filepath = out_dir + "/raw_"
    s.render.image_settings.file_format = 'PNG'
    s.view_settings.view_transform = 'Standard'
    s.world = bpy.data.worlds.new("w")
    s.world.use_nodes = True
    s.world.node_tree.nodes["Background"].inputs[0].default_value = (*world, 1)
    return s


def mat(name, color, emit=0.0, rough=0.7, metal=0.0, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit > 0:
        b.inputs["Emission Color"].default_value = (*color, 1)
        b.inputs["Emission Strength"].default_value = emit
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = 'BLEND'
    return m


def key_emit(m, frame_values):
    b = m.node_tree.nodes["Principled BSDF"]
    for frame, value in frame_values:
        b.inputs["Emission Strength"].default_value = value
        b.inputs["Emission Strength"].keyframe_insert("default_value", frame=frame)


def box(name, x0, x1, z0, z1, y=0.0, depth=1.0, material=None):
    bpy.ops.mesh.primitive_cube_add(location=((x0 + x1) / 2, y, (z0 + z1) / 2))
    o = bpy.context.object
    o.name = name
    o.scale = ((x1 - x0) / 2, depth / 2, (z1 - z0) / 2)
    if material:
        o.data.materials.append(material)
    return o


def sphere(name, x, z, r, y=0.0, material=None, segments=16):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=(x, y, z), segments=segments, ring_count=max(4, segments // 2))
    o = bpy.context.object
    o.name = name
    if material:
        o.data.materials.append(material)
    return o


def rock(name, x, z, r, material, seed, y=0.0):
    rnd = random.Random(seed)
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, location=(x, y, z), subdivisions=1)
    o = bpy.context.object
    o.name = name
    for v in o.data.vertices:
        v.co *= rnd.uniform(0.75, 1.15)
    o.data.materials.append(material)
    return o


def cyl(name, x, z, r, depth, y=0.0, material=None, rot=(math.pi / 2, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=(x, y, z), rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    if material:
        o.data.materials.append(material)
    return o


def key_loc(obj, frame_points, interp='BEZIER'):
    for frame, loc in frame_points:
        obj.location = loc
        obj.keyframe_insert("location", frame=frame)
    _interp(obj, interp, "location")


def key_rot(obj, frame_points, interp='BEZIER'):
    for frame, rot in frame_points:
        obj.rotation_euler = rot
        obj.keyframe_insert("rotation_euler", frame=frame)
    _interp(obj, interp, "rotation_euler")


def key_scale(obj, frame_points, interp='BEZIER'):
    # Los valores multiplican la escala que ya tiene el objeto (las cajas guardan su tamaño en la escala).
    base = obj.scale.copy()
    for frame, sc in frame_points:
        obj.scale = (base.x * sc[0], base.y * sc[1], base.z * sc[2])
        obj.keyframe_insert("scale", frame=frame)
    obj.scale = base
    _interp(obj, interp, "scale")


def _interp(obj, interp, path):
    # Solo el canal animado en esta llamada (no pisa la interpolación de los demás).
    if obj.animation_data and obj.animation_data.action:
        for fc in obj.animation_data.action.fcurves:
            if fc.data_path != path:
                continue
            for kp in fc.keyframe_points:
                kp.interpolation = interp


def light(kind, loc, energy, color, rot=(0, 0, 0), size=1.0):
    bpy.ops.object.light_add(type=kind, location=loc, rotation=rot)
    l = bpy.context.object
    l.data.energy = energy
    l.data.color = color
    if kind in ('AREA',):
        l.data.size = size
    if kind in ('POINT', 'SPOT'):
        l.data.shadow_soft_size = size
    return l


def camera(x=0.0, z=8.0, width=25.6, y=-60):
    bpy.ops.object.camera_add(location=(x, y, z), rotation=(math.pi / 2, 0, 0))
    cam = bpy.context.object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = width
    cam.data.clip_end = 400
    bpy.context.scene.camera = cam
    return cam


def stars(count, seed, y=60, area=(-16, 16, -2, 18), material=None):
    rnd = random.Random(seed)
    for i in range(count):
        sphere(f"star{i}", rnd.uniform(area[0], area[1]), rnd.uniform(area[2], area[3]), rnd.choice([0.03, 0.04, 0.06]),
               y=y, material=material, segments=6)


def render():
    bpy.ops.render.render(animation=True)


def cone(name, x, z, r1, r2, depth, y=0.0, material=None, rot=(0, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=depth, location=(x, y, z), rotation=rot, vertices=verts)
    o = bpy.context.object
    o.name = name
    if material:
        o.data.materials.append(material)
    return o


def parent_to(parent, children):
    for child in children:
        child.parent = parent
        child.matrix_parent_inverse = parent.matrix_world.inverted()


def empty(name, loc):
    bpy.ops.object.empty_add(location=loc)
    e = bpy.context.object
    e.name = name
    return e


ROCKET_SECTIONS = [  # (nombre, alto, radio abajo, radio arriba, color)
    ("engine", 1.0, 0.55, 0.38, (0.35, 0.36, 0.4)),
    ("pipes", 0.4, 0.6, 0.6, (0.22, 0.24, 0.3)),
    ("tanks", 2.0, 0.6, 0.6, (0.92, 0.92, 0.95)),
    ("avionics", 0.45, 0.6, 0.6, (0.95, 0.5, 0.15)),
    ("payload", 1.3, 0.6, 0.05, (0.92, 0.92, 0.95)),
]


def rocket(name, x, z, y=0.0, flame=True):
    """Cohete de 5 secciones (motor abajo, carga útil arriba) vertical, base en z. Devuelve (padre, piezas, llama)."""
    root = empty(name, (x, y, z))
    parts = []
    top = z
    for section, height, r1, r2, color in ROCKET_SECTIONS:
        m = mat(f"{name}_{section}", color, rough=0.45, metal=0.2)
        if section == "engine":
            o = cone(f"{name}_{section}", x, top + height / 2, r1, r2, height, y=y, material=m)
        elif section == "payload":
            o = cone(f"{name}_{section}", x, top + height / 2, r1, r2, height, y=y, material=m)
        else:
            o = cyl(f"{name}_{section}", x, top + height / 2, r1, height, y=y, material=m, rot=(0, 0, 0))
        parts.append(o)
        top += height
    fin_m = mat(f"{name}_fin", (0.85, 0.25, 0.15), rough=0.5)
    for side in (-1, 1):
        f = box(f"{name}_fin{side}", x + side * 0.55, x + side * 1.0, z + 0.9, z + 1.9, y=y, depth=0.12, material=fin_m)
        parts.append(f)
    window = mat(f"{name}_window", (0.4, 0.8, 1.0), emit=1.5)
    parts.append(sphere(f"{name}_window", x, z + 2.4, 0.18, y=y - 0.55, material=window, segments=10))
    fl = None
    if flame:
        fm = mat(f"{name}_flame", (1.0, 0.55, 0.15), emit=6.0)
        fl = cone(f"{name}_flame", x, z - 0.7, 0.35, 0.02, 1.4, y=y, material=fm, rot=(math.pi, 0, 0))
        parts.append(fl)
    parent_to(root, parts)
    return root, parts, fl
