# 관우 저폴리 모델 + 뼈대 + 동작(idle · walk) — Blender(bpy) 코드로만 만든다(참고 그림 없음, D-274).
# 실행(Blender 5.x 또는 pip bpy):
#   blender -b -P godot3d/tools/blender/guan_yu.py -- <출력 폴더> [--render]
#   python godot3d/tools/blender/guan_yu.py <출력 폴더> [--render]   (pip install bpy)
# 결과: <출력 폴더>/guan_yu.glb (--render면 확인용 PNG도)
import bpy, bmesh, math, sys, os
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
RENDER = "--render" in args
args = [a for a in args if not a.startswith("--")]
OUT = args[0] if args else "."
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scn = bpy.context.scene
scn.render.fps = 24

MATS = {}
def mat(name, hexs, rough=0.8, metal=0.0):
    if name in MATS: return MATS[name]
    rgb = tuple((int(hexs[i:i+2], 16) / 255) ** 2.2 for i in (0, 2, 4))  # sRGB → linear
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    MATS[name] = m
    return m

SKIN  = mat("skin",  "a8362a")        # 붉은 얼굴
BLACK = mat("black", "1a1614")
GREEN = mat("green", "2f6b45")        # 녹색 전포
DKGRN = mat("dkgreen", "1f4a30")
GOLD  = mat("gold",  "c89a40", 0.5, 0.6)
BROWN = mat("brown", "6a3a24")
STEEL = mat("steel", "c8d0d8", 0.35, 0.9)
RED   = mat("red",   "b8202a")

parts = []          # (object, bone)
BONE = "torso"      # 지금 만드는 조각이 붙을 뼈
def done(o, m, rot=None):
    o.data.materials.append(m)
    if rot: o.rotation_euler = rot
    parts.append((o, BONE))
    return o

def cone(r1, r2, z0, z1, m, x=0, y=0, v=8, rot=None):
    bpy.ops.mesh.primitive_cone_add(vertices=v, radius1=r1, radius2=r2, depth=z1 - z0,
                                    location=(x, y, (z0 + z1) / 2))
    return done(bpy.context.object, m, rot)

def box(sx, sy, sz, loc, m, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object; o.scale = (sx, sy, sz)
    return done(o, m, rot)

def ball(r, loc, m, sub=2, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc)
    o = bpy.context.object; o.scale = scale
    return done(o, m)

# ── 몸 조각 ── 앞쪽 = -Y. 발밑 z=0, 키 약 2.0(2.5등신)
BONE = "leg_L"; box(0.13, 0.16, 0.24, (-0.13, 0, 0.12), BLACK)
BONE = "leg_R"; box(0.13, 0.16, 0.24, ( 0.13, 0, 0.12), BLACK)

BONE = "torso"
cone(0.46, 0.31, 0.16, 0.64, GREEN)                       # 전포 아랫단
cone(0.31, 0.27, 0.60, 1.12, GREEN)                       # 몸통
cone(0.335, 0.335, 0.58, 0.68, GOLD)                      # 허리띠
box(0.10, 0.04, 0.10, (0, -0.335, 0.63), GOLD)            # 띠 장식
box(0.36, 0.06, 0.34, (0, -0.25, 0.90), BROWN)            # 가슴 갑옷
box(0.20, 0.26, 0.12, (-0.36, 0, 1.06), GOLD, (0, math.radians(-18), 0))   # 어깨 갑옷
box(0.20, 0.26, 0.12, ( 0.36, 0, 1.06), GOLD, (0, math.radians(18), 0))
box(0.50, 0.04, 0.78, (0, 0.26, 0.70), DKGRN, (math.radians(8), 0, 0))     # 망토

BONE = "arm_L"
cone(0.085, 0.10, 0.62, 1.02, GREEN, x=-0.40, rot=(0, math.radians(-8), 0))
ball(0.08, (-0.43, 0, 0.58), SKIN, 1)

BONE = "arm_R"      # 오른팔 + 청룡언월도
cone(0.085, 0.10, 0.70, 1.02, GREEN, x=0.40, y=-0.06, rot=(math.radians(-20), math.radians(8), 0))
ball(0.08, (0.44, -0.13, 0.68), SKIN, 1)
PX, PY = 0.46, -0.14
cone(0.028, 0.028, -0.05, 2.25, BROWN, x=PX, y=PY, v=6)   # 자루
cone(0.05, 0.03, -0.12, -0.02, GOLD, x=PX, y=PY, v=6)     # 물미
bm = bmesh.new()
pts = [(0.00, 2.20), (0.10, 2.30), (0.22, 2.55), (0.26, 2.80), (0.20, 3.02),
       (0.06, 3.12), (0.10, 2.92), (0.10, 2.70), (0.04, 2.50), (-0.04, 2.40), (-0.04, 2.22)]
vs = [bm.verts.new((PX + x, PY, z)) for x, z in pts]
bm.faces.new(vs)
me = bpy.data.meshes.new("blade"); bm.to_mesh(me); bm.free()
blade = bpy.data.objects.new("blade", me); scn.collection.objects.link(blade)
blade.modifiers.new("solid", "SOLIDIFY").thickness = 0.04
done(blade, STEEL)
cone(0.05, 0.05, 2.17, 2.25, GOLD, x=PX, y=PY, v=6)       # 칼날 받침
cone(0.07, 0.01, 1.98, 2.17, RED, x=PX - 0.06, y=PY, v=5) # 술

BONE = "head"
ball(0.42, (0, 0, 1.48), SKIN, 2, (1, 0.95, 1))
cone(0.40, 0.30, 1.66, 1.92, GREEN)                       # 두건(녹건)
box(0.16, 0.14, 0.12, (0, 0.02, 1.96), GREEN)
box(0.05, 0.03, 0.30, (-0.10, 0.36, 1.62), DKGRN, (math.radians(-20), 0, 0))  # 두건 끈
box(0.05, 0.03, 0.30, ( 0.10, 0.36, 1.62), DKGRN, (math.radians(-20), 0, 0))
box(0.09, 0.03, 0.035, (-0.14, -0.40, 1.52), BLACK, (0, math.radians(-12), 0))  # 눈
box(0.09, 0.03, 0.035, ( 0.14, -0.40, 1.52), BLACK, (0, math.radians(12), 0))
box(0.15, 0.04, 0.045, (-0.15, -0.395, 1.61), BLACK, (0, math.radians(-22), 0)) # 눈썹(바깥이 올라감)
box(0.15, 0.04, 0.045, ( 0.15, -0.395, 1.61), BLACK, (0, math.radians(22), 0))
cone(0.03, 0.17, 0.82, 1.38, BLACK, y=-0.36, v=6, rot=(math.radians(10), 0, 0))  # 긴 수염
box(0.20, 0.06, 0.04, (0, -0.42, 1.36), BLACK)            # 콧수염

# ── 조각마다 자기 뼈 이름의 정점 그룹(가중치 1) → 한 덩어리로 ──
for o, bone in parts:
    bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)
    g = o.vertex_groups.new(name=bone)
    g.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
bpy.ops.object.select_all(action="DESELECT")
for o, _ in parts: o.select_set(True)
bpy.context.view_layer.objects.active = parts[0][0]
bpy.ops.object.join()
hero = bpy.context.object; hero.name = "guan_yu_mesh"
bpy.ops.object.shade_flat()
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
tris = sum(len(p.vertices) - 2 for p in hero.data.polygons)

# ── 뼈대 ──
arm_data = bpy.data.armatures.new("guan_yu_rig")
rig = bpy.data.objects.new("guan_yu", arm_data)
scn.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_data.edit_bones
def bone(name, head, tail, parent=None):
    b = eb.new(name); b.head = head; b.tail = tail; b.roll = 0
    if parent: b.parent = eb[parent]
    return b
bone("root",  (0, 0, 0),        (0, 0, 0.3))
bone("torso", (0, 0, 0.62),     (0, 0, 1.15), "root")
bone("head",  (0, 0, 1.15),     (0, 0, 1.9),  "torso")
bone("leg_L", (-0.13, 0, 0.34), (-0.13, 0, 0.0), "root")
bone("leg_R", ( 0.13, 0, 0.34), ( 0.13, 0, 0.0), "root")
bone("arm_L", (-0.40, 0, 1.04), (-0.43, 0, 0.58), "torso")
bone("arm_R", ( 0.40, -0.06, 1.04), (0.44, -0.13, 0.68), "torso")
bpy.ops.object.mode_set(mode="OBJECT")
hero.parent = rig
hero.modifiers.new("rig", "ARMATURE").object = rig

# ── 동작 ── 뼈 로컬 축: 아래로 향한 뼈(다리 · 팔)도 roll 0이면 로컬 X ≈ 월드 X → X축 회전 = 앞뒤로 흔들기
ad = rig.animation_data_create()
pb = rig.pose.bones
for p in pb: p.rotation_mode = "XYZ"

def key(frame, rot=None, loc=None):
    for name, (rx, ry, rz) in (rot or {}).items():
        pb[name].rotation_euler = (math.radians(rx), math.radians(ry), math.radians(rz))
        pb[name].keyframe_insert("rotation_euler", frame=frame)
    for name, xyz in (loc or {}).items():
        pb[name].location = xyz
        pb[name].keyframe_insert("location", frame=frame)

def reset():
    for p in pb:
        p.rotation_euler = (0, 0, 0); p.location = (0, 0, 0)

def make_action(name, frames, fn):
    reset()
    act = bpy.data.actions.new(name)
    ad.action = act
    for f in frames: fn(f)
    tr = ad.nla_tracks.new(); tr.name = name
    st = tr.strips.new(name, int(frames[0]), act)
    ad.action = None
    reset()
    return act

ALL = ["root", "torso", "head", "leg_L", "leg_R", "arm_L", "arm_R"]

def idle(f):   # 0 ~ 24 (1초): 숨쉬듯 위아래
    t = f / 24 * 2 * math.pi
    rot = {b: (0, 0, 0) for b in ALL}
    rot["head"] = (2 * math.sin(t), 0, 0)
    rot["arm_L"] = (0, 0, -3 * math.sin(t))
    key(f, rot, {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 0 ~ 16 (0.67초 한 걸음 주기)
    t = f / 16 * 2 * math.pi
    s = math.sin(t)
    rot = {b: (0, 0, 0) for b in ALL}
    rot["leg_L"] = (-35 * s, 0, 0)
    rot["leg_R"] = ( 35 * s, 0, 0)
    rot["arm_L"] = ( 28 * s, 0, 0)
    rot["arm_R"] = (-10 * s, 0, 0)
    rot["torso"] = (-6, 0, 5 * s)          # 살짝 앞으로 숙이고 비틀기
    rot["head"]  = ( 4, 0, -4 * s)
    bob = 0.045 * abs(math.sin(t))         # 한 주기에 두 번 튀어오름
    key(f, rot, {"root": (0, bob, 0)})     # root 로컬 Y = 위(뼈가 +Z를 향함)

make_action("idle", list(range(0, 25, 2)), idle)
make_action("walk", list(range(0, 17, 2)), walk)

print("TRIS", tris)

# ── 확인용 렌더(선택) ──
if RENDER:
    bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
    bpy.context.object.data.materials.append(mat("ground", "8a9a6a"))
    bpy.ops.object.light_add(type="SUN", location=(3, -4, 6))
    sun = bpy.context.object; sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    w = bpy.data.worlds.new("w"); scn.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.62, 0.72, 1)
    scn.render.engine = "CYCLES"; scn.cycles.device = "CPU"; scn.cycles.samples = 16
    scn.render.resolution_x = scn.render.resolution_y = 360
    scn.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam); scn.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.8
    cam.location = (5.5, -6, 2.6)
    cam.rotation_euler = (Vector((0, 0, 1.25)) - cam.location).to_track_quat("-Z", "Y").to_euler()
    walk_act = bpy.data.actions["walk"]
    for tr in ad.nla_tracks: tr.mute = True
    ad.action = walk_act
    for f in (0, 4, 8, 12):
        scn.frame_set(f)
        scn.render.filepath = os.path.join(OUT, f"walk_{f:02d}.png")
        bpy.ops.render.render(write_still=True)
    ad.action = None
    for tr in ad.nla_tracks: tr.mute = False

# ── 내보내기: 뼈대 + 몸만, NLA 트랙 하나 = 동작 하나 ──
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True); hero.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "guan_yu.glb"), export_format="GLB",
                          use_selection=True, export_animation_mode="NLA_TRACKS",
                          export_apply=False)
print("DONE", os.path.join(OUT, "guan_yu.glb"))
