# 저폴리 인물 공통 도구(D-275): 기본 도형 조각 → 뼈마다 정점 그룹 → 뼈대 · 동작 → glb.
# 블렌더 코드로만 만들고 참고 그림은 쓰지 않는다(D-274). guan_yu.py는 이 파일 전에 만들어 따로 둠.
import bpy, bmesh, math, os, sys


def args():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    flags = {x for x in a if x.startswith("--")}
    pos = [x for x in a if not x.startswith("--")]
    out = pos[0] if pos else "."
    os.makedirs(out, exist_ok=True)
    return out, flags


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = 24


_MATS = {}
def mat(name, hexs, rough=0.8, metal=0.0):
    if name in _MATS:
        return _MATS[name]
    rgb = tuple((int(hexs[i:i + 2], 16) / 255) ** 2.2 for i in (0, 2, 4))  # sRGB → linear
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    _MATS[name] = m
    return m


class Body:
    """조각을 만들 때 지금 뼈(self.bone)를 기억해 두었다가 합칠 때 정점 그룹으로 넣는다."""

    def __init__(self):
        self.parts = []
        self.bone = "torso"

    def _done(self, o, m, rot=None):
        o.data.materials.append(m)
        if rot:
            o.rotation_euler = rot
        self.parts.append((o, self.bone))
        return o

    def cone(self, r1, r2, z0, z1, m, x=0, y=0, v=8, rot=None):
        bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=z1 - z0,
                                        location=(x, y, (z0 + z1) / 2))
        return self._done(bpy.context.object, m, rot)

    def box(self, sx, sy, sz, loc, m, rot=None):
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
        o = bpy.context.object
        o.scale = (sx, sy, sz)
        return self._done(o, m, rot)

    def ball(self, r, loc, m, sub=2, scale=(1, 1, 1)):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc)
        o = bpy.context.object
        o.scale = scale
        return self._done(o, m)

    def poly(self, pts_xz, y, thick, m):
        """XZ 평면 다각형을 두께 thick로(칼날 등)."""
        bm = bmesh.new()
        bm.faces.new([bm.verts.new((x, y, z)) for x, z in pts_xz])
        me = bpy.data.meshes.new("poly")
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new("poly", me)
        bpy.context.scene.collection.objects.link(o)
        o.modifiers.new("solid", "SOLIDIFY").thickness = thick
        return self._done(o, m)

    def join(self, name):
        for o, bone in self.parts:
            bpy.context.view_layer.objects.active = o
            for md in list(o.modifiers):
                bpy.ops.object.modifier_apply(modifier=md.name)
            g = o.vertex_groups.new(name=bone)
            g.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
        bpy.ops.object.select_all(action="DESELECT")
        for o, _ in self.parts:
            o.select_set(True)
        bpy.context.view_layer.objects.active = self.parts[0][0]
        bpy.ops.object.join()
        mesh = bpy.context.object
        mesh.name = name + "_mesh"
        bpy.ops.object.shade_flat()
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        return mesh


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def make_rig(name, mesh, bones):
    """bones: [(이름, head, tail, parent)] — roll 0. 아래로 향한 뼈도 로컬 X ≈ 월드 X."""
    data = bpy.data.armatures.new(name + "_rig")
    rig = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    eb = data.edit_bones
    for n, h, t, p in bones:
        b = eb.new(n)
        b.head, b.tail, b.roll = h, t, 0
        if p:
            b.parent = eb[p]
    bpy.ops.object.mode_set(mode="OBJECT")
    mesh.parent = rig
    mesh.modifiers.new("rig", "ARMATURE").object = rig
    rig.animation_data_create()
    for p in rig.pose.bones:
        p.rotation_mode = "XYZ"
    return rig


def _reset_pose(rig):
    for p in rig.pose.bones:
        p.rotation_euler = (0, 0, 0)
        p.location = (0, 0, 0)


def make_action(rig, name, frames, pose_fn):
    """pose_fn(f) → (rot{뼈: (x°,y°,z°)}, loc{뼈: (x,y,z)}). NLA 트랙 하나 = glb 동작 하나."""
    pb, ad = rig.pose.bones, rig.animation_data
    _reset_pose(rig)
    act = bpy.data.actions.new(name)
    ad.action = act
    for f in frames:
        rot, loc = pose_fn(f)
        for b in pb:
            rx, ry, rz = rot.get(b.name, (0, 0, 0))
            b.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
            b.keyframe_insert("rotation_euler", frame=f)
            b.location = loc.get(b.name, (0, 0, 0))
            b.keyframe_insert("location", frame=f)
    tr = ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, int(frames[0]), act)
    ad.action = None
    _reset_pose(rig)
    return act


def bake_poses(rig, mesh, action, frames, prefix="pose"):
    """동작의 몇 프레임을 뼈 없는 정지 메시로 굳힌다 — 적 떼(MultiMesh)는 뼈를 못 쓰므로 프레임을 바꿔 끼움."""
    scn = bpy.context.scene
    ad = rig.animation_data
    for tr in ad.nla_tracks:
        tr.mute = True
    ad.action = action
    out = []
    for i, f in enumerate(frames):
        scn.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(mesh.evaluated_get(dg), preserve_all_data_layers=True, depsgraph=dg)
        o = bpy.data.objects.new(f"{prefix}_{i}", me)
        scn.collection.objects.link(o)
        out.append(o)
    ad.action = None
    for tr in ad.nla_tracks:
        tr.mute = False
    scn.frame_set(0)
    return out


def export(path, objs, animated):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    kw = dict(filepath=path, export_format="GLB", use_selection=True)
    if animated:
        kw.update(export_animation_mode="NLA_TRACKS", export_apply=False)
    else:
        kw.update(export_animations=False, export_skins=False)
    bpy.ops.export_scene.gltf(**kw)


def render_check(out_dir, name, rig, action, frames, target_z=1.0, scale=3.2):
    """확인용 렌더(3/4 시점, 프레임 몇 장)."""
    from mathutils import Vector
    scn = bpy.context.scene
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    ground = bpy.context.object
    ground.data.materials.append(mat("ground", "8a9a6a"))
    bpy.ops.object.light_add(type="SUN", location=(3, -4, 6))
    sun = bpy.context.object
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    w = bpy.data.worlds.new("w")
    scn.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.62, 0.72, 1)
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 16
    scn.render.resolution_x = scn.render.resolution_y = 320
    scn.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam)
    scn.camera = cam
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    cam.location = (5.5, -6, target_z + 1.4)
    cam.rotation_euler = (Vector((0, 0, target_z)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    ad = rig.animation_data
    for tr in ad.nla_tracks:
        tr.mute = True
    ad.action = action
    paths = []
    for f in frames:
        scn.frame_set(f)
        p = os.path.join(out_dir, f"{name}_{f:02d}.png")
        scn.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    ad.action = None
    for tr in ad.nla_tracks:
        tr.mute = False
    bpy.data.objects.remove(ground)
    bpy.data.objects.remove(sun)
    bpy.data.objects.remove(cam)
    return paths
