# 유비 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만(D-279).
# GPT 콘셉트 설정화(godot3d/art/concept/liu_bei.webp)를 보고 만듦:
#   살색 얼굴 · 크고 긴 귓불 · 짙은 갈색 상투 + 금관 + 가로 비녀 · 귀 옆 머리 가닥 · 콧수염 + 뾰족한 턱수염 ·
#   노란 비단 전포 · 넓은 소매(크림 끝단 · 붉은 안감) · 크림 교차 깃 · 납작한 금 구름 어깨 · 갈색 허리띠 + 금 버클 +
#   붉은 술 · 양 허리에 칼집에 든 쌍고검 · 금 테 앞판 + 구름 무늬 · 뒤의 긴 노란 망토판 · 갈색 바지 · 금 테 장화.
#   손에는 아무것도 안 듦(칼은 허리에).
# 실행: python godot3d/tools/blender/liu_bei.py <출력 폴더> [--render]   (pip install bpy)
# 결과: liu_bei.glb (뼈 이름 · 동작은 guan_yu.glb와 같음)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN   = lp.mat("skin",   "f0c4a0")
WHITE  = lp.mat("white",  "f4efe6")
HAIR   = lp.mat("hair",   "3a2a24")
YELLOW = lp.mat("yellow", "e2b838")
LIGHT  = lp.mat("light",  "f0d488")          # 구름 무늬
GOLD   = lp.mat("gold",   "c9a24e", 0.45, 0.5)
CREAM  = lp.mat("cream",  "efe0c0")
REDIN  = lp.mat("redin",  "8a2a2a")          # 소매 안감 · 술 · 칼 손잡이
BROWN  = lp.mat("brown",  "4a3428")          # 허리띠 · 속옷 · 바지
DKBRN  = lp.mat("dkbrown", "2e2420")         # 장화 · 칼집

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 2.3(관 끝). 유비의 오른쪽 = -X.

# ── 다리 ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.16 * side
    b.box(0.20, 0.28, 0.22, (x, -0.02, 0.11), DKBRN)
    b.box(0.215, 0.29, 0.04, (x, -0.02, 0.22), GOLD)
    b.cone(0.12, 0.15, 0.22, 0.60, BROWN, x=x, v=6)

# ── 몸통: 긴 노란 전포 ──
b.bone = "torso"
b.cone(0.48, 0.37, 0.40, 1.02, YELLOW)                               # 전포 치마
b.cone(0.49, 0.48, 0.36, 0.42, GOLD)                                 # 금 단
b.box(0.42, 0.025, 0.74, (0, -0.425, 0.62), GOLD, (R(-10), 0, 0))     # 앞판: 금 테
b.box(0.36, 0.03, 0.68, (0, -0.44, 0.63), YELLOW, (R(-10), 0, 0))
b.box(0.18, 0.012, 0.08, (0, -0.462, 0.52), LIGHT, (R(-10), 0, 0))    # 구름 무늬(흉내)
b.box(0.08, 0.012, 0.06, (-0.07, -0.465, 0.46), LIGHT, (R(-10), 0, 0))
# 뒤의 긴 노란 망토판(어깨 → 무릎 아래) + 금 테 + 구름 무늬
b.poly([(-0.34, 1.42), (0.34, 1.42), (0.30, 0.42), (0.0, 0.32), (-0.30, 0.42)], 0.47, 0.025, GOLD)
b.poly([(-0.30, 1.40), (0.30, 1.40), (0.26, 0.46), (0.0, 0.37), (-0.26, 0.46)], 0.495, 0.025, YELLOW)
b.box(0.22, 0.012, 0.09, (0, 0.53, 0.66), LIGHT)
b.box(0.10, 0.012, 0.07, (0.08, 0.53, 0.58), LIGHT)
b.cone(0.385, 0.385, 0.96, 1.08, BROWN)                               # 허리띠
b.box(0.20, 0.06, 0.13, (0, -0.39, 1.02), GOLD)                       # 금 짐승 버클
for side in (-1, 1):                                                  # 금 끈 + 붉은 술
    b.box(0.14, 0.03, 0.03, (0.12 * side, -0.40, 0.95), GOLD, (0, R(30 * side), 0))
    b.cone(0.045, 0.02, 0.70, 0.88, REDIN, x=0.17 * side, y=-0.42, v=5)
    b.cone(0.03, 0.03, 0.88, 0.92, GOLD, x=0.17 * side, y=-0.42, v=5)
b.cone(0.37, 0.41, 1.06, 1.40, YELLOW)                                # 가슴
# 크림 교차 깃(V) + 갈색 속옷
b.box(0.06, 0.03, 0.40, (-0.08, -0.395, 1.25), CREAM, (0, R(-22), 0))
b.box(0.06, 0.03, 0.40, ( 0.08, -0.395, 1.25), CREAM, (0, R(22), 0))
b.poly([(-0.10, 1.42), (0.10, 1.42), (0.0, 1.14)], -0.39, 0.02, BROWN)
b.cone(0.28, 0.24, 1.38, 1.46, CREAM, v=8)                            # 목깃
for side in (-1, 1):                                                  # 납작한 금 구름 어깨 장식
    x = 0.42 * side
    b.box(0.30, 0.32, 0.08, (x, 0, 1.38), GOLD, (0, R(-20 * side), 0))
    b.box(0.10, 0.02, 0.06, (x, -0.165, 1.38), LIGHT, (0, R(-20 * side), 0))
# 쌍고검: 양 허리에 칼집째(붉은 바둑판 손잡이 · 금 코등이 · 금 장식)
for side in (-1, 1):
    x = 0.47 * side   # 전포 밖으로 보이게
    tilt = (R(-8), R(10 * side), 0)
    b.box(0.07, 0.09, 0.78, (x, -0.16, 0.66), DKBRN, tilt)            # 칼집
    for z in (0.40, 0.86):
        b.box(0.085, 0.105, 0.05, (x - 0.04 * side * (0.66 - z), -0.16 - 0.06 * (0.66 - z), z), GOLD, tilt)
    b.box(0.09, 0.11, 0.05, (x + 0.05 * side, -0.12, 1.07), GOLD, tilt)  # 코등이
    b.box(0.06, 0.08, 0.20, (x + 0.065 * side, -0.10, 1.20), REDIN, tilt)  # 손잡이
    b.box(0.07, 0.09, 0.04, (x + 0.08 * side, -0.09, 1.31), GOLD, tilt)

# ── 팔: 넓은 소매(크림 끝단 · 붉은 안감), A자세로 벌림 ──
for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-28 * side), 0)   # 아래(손) 쪽이 바깥으로
    b.cone(0.24, 0.12, 0.86, 1.32, YELLOW, x=0.56 * side, v=8, rot=rot)    # 넓어지는 소매
    b.cone(0.255, 0.25, 0.84, 0.92, CREAM, x=0.67 * side, v=8, rot=rot)    # 소매 끝단
    b.cone(0.20, 0.20, 0.83, 0.86, REDIN, x=0.68 * side, v=8, rot=rot)     # 안감
    b.box(0.09, 0.13, 0.15, (0.74 * side, -0.02, 0.76), SKIN, rot)          # 손

# ── 머리 ──
b.bone = "head"
b.ball(0.33, (0, 0, 1.72), SKIN, 2, (1.0, 0.95, 1.05))
for side in (-1, 1):
    b.box(0.07, 0.09, 0.26, (0.335 * side, 0.02, 1.62), SKIN)         # 크고 긴 귓불
    b.box(0.05, 0.06, 0.40, (0.27 * side, -0.10, 1.58), HAIR)         # 귀 옆 머리 가닥
    b.box(0.12, 0.03, 0.10, (0.12 * side, -0.31, 1.74), WHITE)        # 눈(흰자 + 갈색 눈동자)
    b.box(0.07, 0.03, 0.08, (0.11 * side, -0.325, 1.735), HAIR)
    b.box(0.15, 0.04, 0.05, (0.13 * side, -0.31, 1.84), HAIR, (0, R(8 * side), 0))   # 굵은 눈썹
    b.box(0.13, 0.03, 0.03, (0.07 * side, -0.335, 1.60), HAIR, (0, R(-15 * side), 0))  # 가는 콧수염
b.box(0.06, 0.06, 0.08, (0, -0.34, 1.67), SKIN)                       # 코
b.cone(0.0, 0.08, 1.40, 1.56, HAIR, y=-0.30, v=5)                     # 뾰족한 턱수염
# 짙은 갈색 머리(위 · 뒤를 덮음) + 상투 + 금관 + 가로 비녀
b.ball(0.35, (0, 0.13, 1.86), HAIR, 2, (1.02, 1.0, 0.95))   # 이마가 드러나게 뒤 · 위로
b.box(0.60, 0.20, 0.30, (0, 0.20, 1.62), HAIR)
b.ball(0.14, (0, 0.06, 2.16), HAIR, 1)                                 # 상투
b.box(0.24, 0.20, 0.10, (0, 0.04, 2.22), GOLD)                         # 관 받침
b.box(0.16, 0.15, 0.22, (0, 0.04, 2.36), HAIR)                         # 관(검은 몸)
b.box(0.22, 0.18, 0.04, (0, 0.04, 2.48), GOLD)                         # 관 윗테
b.box(0.08, 0.02, 0.08, (0, -0.07, 2.33), GOLD, (0, R(45), 0))         # 관 앞 마름모
b.box(0.60, 0.03, 0.03, (0, 0.04, 2.27), GOLD)                       # 가로 비녀
for side in (-1, 1):
    b.cone(0.035, 0.0, 0.0, 0.07, GOLD, x=0.335 * side, y=0.04, v=4, rot=(0, R(90 * side), 0)).location.z = 2.27

mesh = b.join("liu_bei")
rig = lp.make_rig("liu_bei", mesh, [
    ("root",  (0, 0, 0),         (0, 0, 0.3),        None),
    ("torso", (0, 0, 0.95),      (0, 0, 1.45),       "root"),
    ("head",  (0, 0, 1.45),      (0, 0, 2.1),        "torso"),
    ("leg_L", ( 0.16, 0, 0.60),  ( 0.16, 0, 0.0),    "root"),
    ("leg_R", (-0.16, 0, 0.60),  (-0.16, 0, 0.0),    "root"),
    ("arm_L", ( 0.42, 0, 1.32),  ( 0.74, 0, 0.78),   "torso"),
    ("arm_R", (-0.42, 0, 1.32),  (-0.74, 0, 0.78),   "torso"),
])

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t)), "arm_R": (0, 0, 3 * math.sin(t))},
            {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 손에 든 게 없어 두 팔을 고르게 흔듦, 몸은 덜 비틂(차분하게)
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-28 * s, 0, 0), "leg_R": (28 * s, 0, 0),
           "arm_L": (-20 * s, 0, 0), "arm_R": (20 * s, 0, 0),
           "torso": (-3, 0, 3 * s), "head": (2, 0, -3 * s)}
    return rot, {"root": (0, 0.035 * abs(s), 0)}

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
    for name, p in (("front", (0, -8, 1.4)), ("side", (-8, 0, 1.4)), ("back", (0, 8, 1.4)), ("quarter", (-5, -6, 2.4))):
        cam.location = p
        cam.rotation_euler = (Vector((0, 0, 1.4)) - Vector(p)).to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"lb_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

lp.export(os.path.join(OUT, "liu_bei.glb"), [rig, mesh], animated=True)
print("DONE")
