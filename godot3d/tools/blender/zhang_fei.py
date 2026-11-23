# 장비 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만(D-278).
# GPT 콘셉트 설정화(godot3d/art/concept/zhang_fei.webp)를 보고 만듦:
#   관우보다 다부진 체형 · 검은 두건(뒤 매듭 + 비스듬히 늘어진 끈) · 뻗친 검은 머리 · 붉은 얼굴 · 크고 둥근 눈 ·
#   성난 눈썹 · 짧고 덥수룩한 수염 · 검은 갑옷 + 은회색 용머리 어깨 · 남색 목도리 · 남색 허리띠 + 은 짐승 버클 ·
#   뾰족한 남색 앞치마 · 은 테 검은 갑옷 치마 · 검은 통바지 · 장팔사모(뱀처럼 구불구불한 은색 창날), 오른손.
# 실행: python godot3d/tools/blender/zhang_fei.py <출력 폴더> [--render]   (pip install bpy)
# 결과: zhang_fei.glb (뼈 이름 · 동작은 guan_yu.glb와 같음 — player.gd가 그대로 씀)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

FACE   = lp.mat("face",   "c5463a")
WHITE  = lp.mat("white",  "e8e4dc")
BLACK  = lp.mat("black",  "222228")          # 갑옷 · 머리 · 수염
DKGRAY = lp.mat("dkgray", "33333a")          # 바지 · 소매
NAVY   = lp.mat("navy",   "2e3a5a")
SILVER = lp.mat("silver", "a8acb2", 0.4, 0.7)
BRIGHT = lp.mat("bright", "d4d8dc", 0.3, 0.9)  # 창날

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 2.15. 장비의 오른쪽 = -X(정면에서 화면 왼쪽).

# ── 다리: 장화 · 통바지(관우보다 넓게) ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.19 * side
    b.box(0.23, 0.30, 0.22, (x, -0.02, 0.11), BLACK)
    b.box(0.245, 0.31, 0.04, (x, -0.02, 0.22), SILVER)
    b.cone(0.13, 0.19, 0.22, 0.62, DKGRAY, x=x, v=6)

# ── 몸통 ──
b.bone = "torso"
b.cone(0.50, 0.40, 0.50, 1.0, BLACK)                                  # 갑옷 치마
b.cone(0.51, 0.50, 0.46, 0.52, SILVER)                                # 치마 은 단
for side in (-1, 1):                                                  # 앞쪽 양옆 갑옷 판(은 테)
    b.box(0.30, 0.03, 0.46, (0.27 * side, -0.40, 0.70), SILVER, (R(-10), 0, R(-18 * side)))
    b.box(0.25, 0.035, 0.41, (0.27 * side, -0.415, 0.71), BLACK, (R(-10), 0, R(-18 * side)))
# 뾰족한 남색 앞치마(가운데) · 긴 남색 뒤판
b.poly([(-0.16, 1.0), (0.16, 1.0), (0.16, 0.55), (0.0, 0.42), (-0.16, 0.55)], -0.47, 0.03, NAVY)
b.poly([(-0.24, 1.0), (0.24, 1.0), (0.26, 0.40), (0.0, 0.30), (-0.26, 0.40)], 0.46, 0.03, NAVY)
b.cone(0.40, 0.40, 0.94, 1.08, NAVY)                                  # 남색 허리띠
b.box(0.20, 0.07, 0.15, (0, -0.41, 1.01), SILVER)                     # 짐승 얼굴 버클
b.box(0.03, 0.02, 0.025, (-0.04, -0.45, 1.04), BLACK)
b.box(0.03, 0.02, 0.025, ( 0.04, -0.45, 1.04), BLACK)
b.cone(0.40, 0.44, 1.06, 1.40, BLACK)                                 # 가슴
for side in (-1, 1):                                                  # 가슴 은 구름 무늬(흉내)
    b.box(0.10, 0.02, 0.05, (0.18 * side, -0.42, 1.24), SILVER, (0, R(20 * side), 0))
    b.box(0.05, 0.02, 0.08, (0.24 * side, -0.42, 1.20), SILVER)
b.cone(0.33, 0.27, 1.34, 1.48, NAVY, v=8)                             # 남색 목도리
b.poly([(-0.18, 1.42), (0.18, 1.42), (0.0, 1.18)], -0.36, 0.03, NAVY)  # 앞으로 늘어진 목도리 끝
for side in (-1, 1):                                                  # 은회색 용머리 어깨(2단)
    x = 0.47 * side
    b.ball(0.21, (x, 0, 1.36), SILVER, 1, (1.15, 1.25, 0.85))
    b.box(0.32, 0.32, 0.07, (x * 1.05, 0, 1.21), SILVER, (0, R(-22 * side), 0))
    b.box(0.13, 0.08, 0.10, (x * 1.02, -0.25, 1.33), SILVER)
    b.box(0.035, 0.02, 0.025, (x * 1.02 - 0.03, -0.295, 1.355), BLACK)
    b.box(0.035, 0.02, 0.025, (x * 1.02 + 0.03, -0.295, 1.355), BLACK)

# ── 팔: 검은 소매 · 은 띠 · 붉은 손 ──
b.bone = "arm_L"
b.cone(0.12, 0.14, 0.98, 1.28, DKGRAY, x=0.53, rot=(0, R(10), 0))
b.cone(0.10, 0.11, 0.74, 0.98, BLACK, x=0.57, v=6, rot=(0, R(10), 0))
for z in (0.80, 0.94):
    b.cone(0.118, 0.118, z, z + 0.04, SILVER, x=0.565 + (0.94 - z) * 0.08, v=6)
b.box(0.09, 0.14, 0.16, (0.615, -0.02, 0.66), FACE, (0, R(12), 0))

b.bone = "arm_R"   # 오른팔 + 장팔사모
b.cone(0.12, 0.14, 0.98, 1.28, DKGRAY, x=-0.53, rot=(R(-12), R(-6), 0))
b.cone(0.10, 0.11, 0.74, 0.98, BLACK, x=-0.56, y=-0.06, v=6, rot=(R(-20), 0, 0))
b.cone(0.118, 0.118, 0.93, 0.97, SILVER, x=-0.56, y=-0.02, v=6)
b.cone(0.112, 0.112, 0.76, 0.80, SILVER, x=-0.56, y=-0.10, v=6)
b.ball(0.095, (-0.58, -0.12, 0.70), FACE, 1)
PX, PY = -0.59, -0.13
b.cone(0.03, 0.03, 0.12, 2.36, BLACK, x=PX, y=PY, v=6)                # 검은 자루
b.cone(0.0, 0.055, -0.08, 0.14, SILVER, x=PX, y=PY, v=4)              # 은 물미
for z in (0.14, 0.62, 1.95):
    b.cone(0.045, 0.045, z, z + 0.05, SILVER, x=PX, y=PY, v=6)
b.cone(0.06, 0.035, 2.24, 2.36, SILVER, x=PX, y=PY, v=6)              # 창날 받침(층층이)
b.cone(0.07, 0.07, 2.36, 2.40, SILVER, x=PX, y=PY, v=6)
b.cone(0.05, 0.03, 2.40, 2.46, SILVER, x=PX, y=PY, v=6)
# 뱀처럼 구불구불한 창날(끝은 몸 쪽으로 휨) + 가운데 어두운 줄
snake = [(-0.04, 2.46), (-0.11, 2.58), (-0.05, 2.70), (-0.13, 2.84), (-0.07, 2.97), (-0.14, 3.10),
         (-0.10, 3.24), (-0.05, 3.36), (0.08, 3.48), (0.02, 3.32), (0.0, 3.20), (0.05, 3.07),
         (0.0, 2.94), (0.06, 2.81), (0.01, 2.69), (0.06, 2.57), (0.04, 2.46)]
b.poly([(PX + x, z) for x, z in snake], PY, 0.035, BRIGHT)
for dy in (-0.025, 0.025):
    b.box(0.025, 0.01, 0.80, (PX - 0.03, PY + dy, 2.90), BLACK, (0, R(4), 0))

# ── 머리 ──
b.bone = "head"
b.ball(0.34, (0, 0, 1.70), FACE, 2, (1.05, 0.95, 1.02))               # 얼굴(넓적하게)
b.box(0.07, 0.08, 0.12, (-0.35, 0.02, 1.68), FACE)
b.box(0.07, 0.08, 0.12, ( 0.35, 0.02, 1.68), FACE)
# 크고 둥근 눈(흰자 + 검은 눈동자) · 성난 눈썹(안쪽이 내려감)
for side in (-1, 1):
    b.box(0.12, 0.03, 0.10, (0.13 * side, -0.31, 1.74), WHITE)
    b.box(0.065, 0.03, 0.075, (0.12 * side, -0.325, 1.735), BLACK)
    b.box(0.17, 0.05, 0.06, (0.14 * side, -0.32, 1.84), BLACK, (0, R(-22 * side), 0))
b.box(0.07, 0.07, 0.09, (0, -0.34, 1.66), FACE)                       # 코
# 짧고 덥수룩한 수염(턱 · 뺨) · 콧수염
b.ball(0.27, (0, -0.27, 1.47), BLACK, 1, (1.2, 0.6, 1.0))         # 턱 아래로 덥수룩하게(목도리 위까지)
b.box(0.08, 0.14, 0.24, (-0.29, -0.10, 1.58), BLACK)
b.box(0.08, 0.14, 0.24, ( 0.29, -0.10, 1.58), BLACK)
b.box(0.36, 0.08, 0.07, (0, -0.34, 1.60), BLACK)
# 두건 밖으로 뻗친 검은 머리(옆 · 뒤로 뾰족뾰족)
# 머리 둘레 각도 t(0 = 뒤, ±90° = 옆)마다 바깥으로 눕힌 뿔 — 두건 띠 바로 아래
for a in (-150, -128, -106, -84, -62, -40, 40, 62, 84, 106, 128, 150):
    t = R(a)
    dx, dy = math.sin(t), math.cos(t)
    for zc, ln in ((1.80, 0.22), (1.66, 0.18)):
        sp = b.cone(0.075, 0.0, 0.0, ln, BLACK, x=0.37 * dx, y=0.37 * dy + 0.04, v=4,
                    rot=(R(-70) * dy, R(70) * dx, 0))
        sp.location.z = zc
b.box(0.58, 0.26, 0.36, (0, 0.17, 1.58), BLACK)                       # 뒷머리
# 검은 두건 · 뒤 매듭 · 비스듬히 늘어진 끈
b.ball(0.345, (0, 0.02, 1.92), BLACK, 2, (1.02, 1.02, 0.72))
b.cone(0.36, 0.36, 1.84, 1.92, BLACK)
b.box(0.18, 0.12, 0.14, (0, 0.36, 1.86), BLACK)                       # 매듭
b.box(0.14, 0.03, 0.62, (-0.10, 0.42, 1.52), NAVY, (R(14), R(-12), 0))
b.box(0.14, 0.03, 0.56, ( 0.10, 0.42, 1.55), BLACK, (R(14), R(14), 0))

mesh = b.join("zhang_fei")
rig = lp.make_rig("zhang_fei", mesh, [
    ("root",  (0, 0, 0),           (0, 0, 0.3),           None),
    ("torso", (0, 0, 0.95),        (0, 0, 1.45),          "root"),
    ("head",  (0, 0, 1.45),        (0, 0, 2.1),           "torso"),
    ("leg_L", ( 0.19, 0, 0.62),    ( 0.19, 0, 0.0),       "root"),
    ("leg_R", (-0.19, 0, 0.62),    (-0.19, 0, 0.0),       "root"),
    ("arm_L", ( 0.51, 0, 1.30),    ( 0.60, 0, 0.72),      "torso"),
    ("arm_R", (-0.51, 0, 1.30),    (-0.58, -0.12, 0.72),  "torso"),
])

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t))},
            {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 관우보다 조금 거칠게(몸을 더 비틂)
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-32 * s, 0, 0), "leg_R": (32 * s, 0, 0),
           "arm_L": (-28 * s, 0, 0), "arm_R": (8 * s, 0, 0),
           "torso": (-6, 0, 7 * s), "head": (3, 0, -5 * s)}
    return rot, {"root": (0, 0.045 * abs(s), 0)}

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
    scn.render.resolution_x, scn.render.resolution_y = 360, 480
    scn.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam); scn.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.8
    for name, p in (("front", (0, -8, 1.6)), ("side", (-8, 0, 1.6)), ("back", (0, 8, 1.6)), ("quarter", (-5, -6, 2.6))):
        cam.location = p
        cam.rotation_euler = (Vector((0, 0, 1.6)) - Vector(p)).to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"zf_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

lp.export(os.path.join(OUT, "zhang_fei.glb"), [rig, mesh], animated=True)
print("DONE")
