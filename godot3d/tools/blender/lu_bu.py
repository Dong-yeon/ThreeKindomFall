# 여포 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만(D-290).
# 설정화 없이 글 설명으로: 꿩깃 두 가닥이 달린 금관 · 붉은 얼굴 아닌 흰 얼굴 · 검은 갑옷에 붉은 테 · 붉은 전포 · 붉은 망토 ·
# 방천화극(긴 자루 + 가운데 창날 + 양쪽 초승달 날), 오른손. GPT 설정화를 받으면 맞춰 고침.
# 실행: python godot3d/tools/blender/lu_bu.py <출력 폴더> [--render]   (pip install bpy)
# 결과: lu_bu.glb (뼈 이름 · 동작은 장수들과 같음 — foe.gd가 walk를 씀)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN   = lp.mat("skin",   "e8c4a4")
BLACK  = lp.mat("black",  "1c1a1e")          # 머리 · 눈 · 갑옷
ARMOR  = lp.mat("armor",  "2a2830", 0.45, 0.5)
RED    = lp.mat("red",    "b0242a")          # 전포 · 망토 · 테
GOLD   = lp.mat("gold",   "d0a848", 0.4, 0.6)
FEATHER = lp.mat("feather", "c8662a")        # 꿩깃(주황 갈색)
STEEL  = lp.mat("steel",  "c8ccd2", 0.3, 0.9)
WOOD   = lp.mat("wood",   "3a2418")

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 2.3(꿩깃 빼고). 오른쪽 = -X.
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.18 * side
    b.box(0.22, 0.30, 0.24, (x, -0.02, 0.12), BLACK)
    b.box(0.235, 0.31, 0.05, (x, -0.02, 0.24), GOLD)
    b.cone(0.13, 0.17, 0.24, 0.64, ARMOR, x=x, v=6)

b.bone = "torso"
b.cone(0.50, 0.38, 0.46, 1.02, RED)                                  # 붉은 전포
b.cone(0.51, 0.50, 0.42, 0.48, GOLD)
for side in (-1, 1):                                                 # 갑옷 치마 판
    b.box(0.30, 0.04, 0.50, (0.25 * side, -0.41, 0.72), ARMOR, (R(-10), 0, R(-15 * side)))
    b.box(0.32, 0.03, 0.04, (0.25 * side, -0.43, 0.48), RED, (R(-10), 0, R(-15 * side)))
b.cone(0.40, 0.40, 0.96, 1.10, GOLD)                                 # 금 허리띠
b.box(0.22, 0.06, 0.15, (0, -0.41, 1.03), BLACK)                     # 짐승 버클
b.cone(0.40, 0.45, 1.08, 1.44, ARMOR)                                # 검은 가슴 갑옷
b.box(0.40, 0.04, 0.05, (0, -0.42, 1.30), RED)                       # 가슴 붉은 테
b.box(0.05, 0.04, 0.30, (0, -0.43, 1.25), GOLD)
for side in (-1, 1):                                                 # 어깨 갑옷(크게, 붉은 테)
    x = 0.48 * side
    b.ball(0.22, (x, 0, 1.40), ARMOR, 1, (1.2, 1.25, 0.85))
    b.box(0.34, 0.32, 0.06, (x * 1.06, 0, 1.25), RED, (0, R(-24 * side), 0))
    b.box(0.10, 0.10, 0.18, (x * 1.05, 0, 1.58), GOLD)               # 어깨 뿔
b.box(0.62, 0.05, 1.15, (0, 0.50, 0.80), RED, (R(10), 0, 0))         # 붉은 망토(전포 바깥)

b.bone = "arm_L"
b.cone(0.12, 0.14, 1.00, 1.32, ARMOR, x=0.54, rot=(0, R(10), 0))
b.cone(0.10, 0.11, 0.76, 1.00, BLACK, x=0.58, v=6, rot=(0, R(10), 0))
b.cone(0.118, 0.118, 0.76, 0.82, GOLD, x=0.60, v=6)
b.box(0.09, 0.14, 0.16, (0.63, -0.02, 0.68), SKIN, (0, R(12), 0))

b.bone = "arm_R"   # 오른팔 + 방천화극
b.cone(0.12, 0.14, 1.00, 1.32, ARMOR, x=-0.54, rot=(R(-12), R(-6), 0))
b.cone(0.10, 0.11, 0.76, 1.00, BLACK, x=-0.57, y=-0.06, v=6, rot=(R(-20), 0, 0))
b.cone(0.118, 0.118, 0.78, 0.84, GOLD, x=-0.57, y=-0.10, v=6)
b.ball(0.095, (-0.59, -0.12, 0.72), SKIN, 1)
PX, PY = -0.60, -0.13
b.cone(0.032, 0.032, 0.05, 2.55, WOOD, x=PX, y=PY, v=6)              # 긴 자루
b.cone(0.0, 0.05, -0.08, 0.10, GOLD, x=PX, y=PY, v=4)
for z in (0.60, 2.10):
    b.cone(0.045, 0.045, z, z + 0.05, GOLD, x=PX, y=PY, v=6)
b.cone(0.07, 0.05, 2.50, 2.62, GOLD, x=PX, y=PY, v=6)                # 날 받침
b.box(0.05, 0.03, 0.18, (PX, PY - 0.05, 2.48), RED)                  # 붉은 술
b.poly([(PX - 0.05, 2.62), (PX + 0.05, 2.62), (PX + 0.06, 2.95), (PX, 3.30), (PX - 0.06, 2.95)], PY, 0.035, STEEL)  # 가운데 창날
moon = [(0.04, 2.62), (0.16, 2.58), (0.30, 2.66), (0.36, 2.82), (0.30, 2.98), (0.20, 3.02), (0.26, 2.86), (0.22, 2.72), (0.10, 2.70), (0.04, 2.74)]
b.poly([(PX + x, z) for x, z in moon], PY, 0.035, STEEL)             # 양쪽 초승달 날
b.poly([(PX - x, z) for x, z in moon], PY, 0.035, STEEL)

b.bone = "head"
b.ball(0.33, (0, 0, 1.74), SKIN, 2, (1.0, 0.95, 1.05))
b.box(0.06, 0.08, 0.12, (-0.33, 0.02, 1.72), SKIN)
b.box(0.06, 0.08, 0.12, ( 0.33, 0.02, 1.72), SKIN)
for side in (-1, 1):
    b.box(0.12, 0.03, 0.06, (0.12 * side, -0.31, 1.77), WHITE := lp.mat("white", "f2eee6"))
    b.box(0.06, 0.03, 0.06, (0.11 * side, -0.325, 1.77), BLACK)
    b.box(0.16, 0.04, 0.045, (0.13 * side, -0.31, 1.86), BLACK, (0, R(-24 * side), 0))   # 날카로운 눈썹
b.box(0.06, 0.06, 0.08, (0, -0.335, 1.70), SKIN)
b.box(0.12, 0.03, 0.02, (0, -0.33, 1.60), BLACK)                     # 다문 입
b.box(0.60, 0.24, 0.36, (0, 0.18, 1.66), BLACK)                       # 뒷머리
b.ball(0.35, (0, 0.04, 1.86), BLACK, 2, (1.02, 1.0, 0.72))            # 머리
b.cone(0.36, 0.33, 1.86, 1.98, GOLD)                                  # 금관 띠
b.box(0.30, 0.20, 0.22, (0, 0.0, 2.08), GOLD)                         # 금관
b.box(0.10, 0.04, 0.12, (0, -0.12, 2.06), RED, (0, R(45), 0))         # 관 앞 붉은 구슬
# 꿩깃 두 가닥(뒤로 휘며 높이 솟음): 짧은 상자를 이어 붙임
for side in (-1, 1):
    x, y, z = 0.10 * side, 0.02, 2.18
    for k in range(7):
        ang = R(10 + k * 12)
        seg = 0.22
        nx, ny, nz = x + 0.03 * side, y + math.sin(ang) * seg, z + math.cos(ang) * seg
        b.box(0.05, 0.05, seg + 0.02, ((x + nx) / 2, (y + ny) / 2, (z + nz) / 2), FEATHER, (-ang, 0, 0))   # 뒤(+Y)로 휨
        x, y, z = nx, ny, nz

mesh = b.join("lu_bu")
CH = lp.Chibi(leg_top=0.64, neck=1.46, weapon=1.0, blade=1.6, blade_from=2.50, blade_pivot=(PX, PY)) if "--classic" not in FLAGS else None   # D-309: 큰 머리 비율 기본 · 방천화극 칼날 ×1.6(보스라 개그 동작 없음)
if CH:
    CH.apply_mesh(mesh)
BONES = [
    ("root",  (0, 0, 0),           (0, 0, 0.3),           None),
    ("torso", (0, 0, 0.96),        (0, 0, 1.46),          "root"),
    ("head",  (0, 0, 1.46),        (0, 0, 2.1),           "torso"),
    ("leg_L", ( 0.18, 0, 0.64),    ( 0.18, 0, 0.0),       "root"),
    ("leg_R", (-0.18, 0, 0.64),    (-0.18, 0, 0.0),       "root"),
    ("arm_L", ( 0.52, 0, 1.32),    ( 0.62, 0, 0.72),      "torso"),
    ("arm_R", (-0.52, 0, 1.32),    (-0.59, -0.12, 0.72),  "torso"),
]
rig = lp.make_rig("lu_bu", mesh, CH.bones(BONES) if CH else BONES)

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0)}, {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-30 * s, 0, 0), "leg_R": (30 * s, 0, 0), "arm_L": (-22 * s, 0, 0), "arm_R": (6 * s, 0, 0),
           "torso": (-6, 0, 5 * s), "head": (3, 0, -4 * s)}
    return rot, {"root": (0, 0.04 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    import bpy
    from mathutils import Vector
    scn = bpy.context.scene
    bpy.ops.object.light_add(type="SUN", location=(0, -4, 6))
    sun = bpy.context.object
    sun.data.energy = 3.0
    sun.rotation_euler = (R(40), 0, R(15))
    w = bpy.data.worlds.new("w"); scn.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scn.render.engine = "CYCLES"; scn.cycles.device = "CPU"; scn.cycles.samples = 16
    scn.render.resolution_x, scn.render.resolution_y = 360, 520
    scn.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam); scn.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 4.4
    for name, p in (("front", (0, -8, 1.8)), ("side", (-8, 0, 1.8)), ("back", (0, 8, 1.8))):
        cam.location = p
        cam.rotation_euler = (Vector((0, 0, 1.8)) - Vector(p)).to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"lb_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

lp.export(os.path.join(OUT, "lu_bu.glb"), [rig, mesh], animated=True)
print("DONE")
