# 유비 저폴리 모델 + 뼈대 + 동작 — 블렌더 코드로만 만든다.
# D-279 설정화(liu_bei.webp, 약 3등신) → D-314: 새 설정화(큰 머리, 약 2등신)를 보고 처음부터:
#   검은 머리 + 상투 위 작은 금관(앞으로 살짝 기운 네모) / 큰 귀 · 긴 귓불 / 웃는 얼굴 · 콧수염 + 턱수염 + 턱선 수염 /
#   노란 용포(가슴에 금 용 무늬 흉내) · 자주색 교차 깃 · 소맷부리 · 앞 자락 / 자주색 허리띠 + 금 장식 셋 /
#   양 허리에 칼집째 쌍고검(자주색 칼집 · 금 장식, 비스듬히) / 자주색 바지 · 검은 신.
# 동작: idle · walk + 개그 동작(lowpoly.end_actions: 쓰러질 때 down · 승리할 때 cheer, D-313).
# 실행: python godot3d/tools/blender/liu_bei.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN   = lp.mat("skin",   "f2cbb0")
BLUSH  = lp.mat("blush",  "f0a0a0")
YELLOW = lp.mat("yellow", "e8b23c")          # 용포
MAROON = lp.mat("maroon", "8a2a3a")          # 깃 · 띠 · 칼집 · 바지
GOLD   = lp.mat("gold",   "d6b04a", 0.45, 0.5)
DGOLD  = lp.mat("dgold",  "c49a3a", 0.5, 0.4)   # 용 무늬
BLACK  = lp.mat("black",  "242120")
WHITE  = lp.mat("white",  "f8f6f2")

b = lp.Body()
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.14 * side
    b.box(0.17, 0.27, 0.09, (x, -0.03, 0.045), BLACK)
    b.cone(0.11, 0.12, 0.08, 0.24, MAROON, x=x, v=8)

b.bone = "torso"
b.cone(0.44, 0.33, 0.16, 0.62, YELLOW, v=10)                          # 용포 자락
b.box(0.06, 0.02, 0.46, (-0.10, -0.41, 0.40), MAROON, (R(-14), 0, 0))  # 앞섶 자주 테
b.cone(0.33, 0.29, 0.62, 0.98, YELLOW, v=10)                          # 윗몸
b.box(0.07, 0.02, 0.46, (-0.06, -0.31, 0.80), MAROON, (0, R(-30), R(-38)))   # 교차 깃
b.box(0.07, 0.02, 0.24, ( 0.10, -0.30, 0.90), MAROON, (0, R(30), R(38)))
b.cone(0.30, 0.26, 0.95, 1.01, MAROON, v=10)                          # 목깃
b.box(0.18, 0.02, 0.14, (0.12, -0.30, 0.82), DGOLD, (0, R(10), 0))    # 가슴 금 용 무늬(흉내)
b.box(0.08, 0.02, 0.06, (0.18, -0.30, 0.90), DGOLD, (0, R(10), R(30)))
b.cone(0.345, 0.345, 0.60, 0.67, MAROON, v=10)                        # 자주색 허리띠
for x in (-0.14, 0.0, 0.14):
    b.ball(0.04, (x, -0.33, 0.635), GOLD, 1, (1.0, 0.5, 1.0))         # 금 장식 셋
for side in (-1, 1):   # 양 허리 쌍고검(칼집째, 비스듬히 — 뒤로 갈수록 내려감)
    x = 0.36 * side
    tilt = (R(55), 0, R(-8 * side))   # 손잡이가 앞 위, 칼집 끝이 뒤 아래(설정화 옆모습)
    b.box(0.06, 0.07, 0.70, (x, 0.02, 0.48), MAROON, tilt)            # 칼집
    b.box(0.08, 0.09, 0.05, (x, -0.27, 0.68), GOLD, tilt)             # 코등이
    b.box(0.05, 0.06, 0.16, (x, -0.35, 0.74), MAROON, tilt)           # 손잡이
    b.box(0.07, 0.08, 0.06, (x, 0.30, 0.28), GOLD, tilt)              # 칼집 끝 금

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-24 * side), 0)
    b.cone(0.16, 0.13, 0.60, 0.97, YELLOW, x=0.44 * side, v=8, rot=rot)
    b.cone(0.165, 0.16, 0.58, 0.65, MAROON, x=0.52 * side, v=8, rot=rot)   # 자주 소맷부리
    b.ball(0.11, (0.58 * side, -0.02, 0.50), SKIN, 1)

b.bone = "head"
b.ball(0.33, (0, 0, 1.26), SKIN, 2, (1.0, 0.95, 1.0))
for side in (-1, 1):
    b.ball(0.09, (0.34 * side, 0.02, 1.20), SKIN, 1, (0.55, 1.0, 1.6))   # 크고 긴 귀(긴 귓불)
    b.ball(0.045, (0.12 * side, -0.30, 1.31), BLACK, 1)               # 까만 눈
    b.ball(0.012, (0.11 * side, -0.345, 1.33), WHITE, 1)
    b.box(0.13, 0.04, 0.04, (0.12 * side, -0.30, 1.40), BLACK, (0, R(-6 * side), 0))   # 눈썹
    b.box(0.08, 0.02, 0.05, (0.20 * side, -0.27, 1.20), BLUSH)
    b.box(0.06, 0.10, 0.22, (0.27 * side, -0.14, 1.12), BLACK)        # 턱선 수염
b.box(0.05, 0.05, 0.07, (0, -0.33, 1.23), SKIN)
b.box(0.22, 0.04, 0.04, (0, -0.32, 1.165), BLACK)                     # 콧수염
b.box(0.10, 0.02, 0.025, (0, -0.33, 1.13), lp.mat("lip", "d07070"))   # 웃는 입
b.cone(0.03, 0.12, 0.92, 1.10, BLACK, y=-0.27, v=6)                   # 턱수염
b.ball(0.35, (0, 0.12, 1.42), BLACK, 2, (1.0, 0.88, 0.85))            # 머리(뒤 · 위 — 옆에서 얼굴을 가리지 않게 뒤로)
b.box(0.06, 0.06, 0.10, (0, -0.33, 1.52), BLACK, (0, R(45), 0))       # 이마 가운데 머리끝
b.ball(0.12, (0, 0.04, 1.68), BLACK, 1)                               # 상투
b.box(0.22, 0.16, 0.12, (0, 0.02, 1.80), GOLD, (R(-12), 0, 0))        # 작은 금관(앞으로 기움)
b.box(0.30, 0.20, 0.03, (0, 0.03, 1.74), GOLD)                        # 관 받침

mesh = b.join("liu_bei")
rig = lp.make_rig("liu_bei", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.14, 0, 0.24),     ( 0.14, 0, 0.0),        "root"),
    ("leg_R", (-0.14, 0, 0.24),     (-0.14, 0, 0.0),        "root"),
    ("arm_L", ( 0.32, 0, 0.94),     ( 0.58, 0, 0.50),       "torso"),
    ("arm_R", (-0.32, 0, 0.94),     (-0.58, 0, 0.50),       "torso"),
])

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t)), "arm_R": (0, 0, 3 * math.sin(t))},
            {"torso": (0, 0.012 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 손에 든 게 없어 두 팔을 고르게 흔듦
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-32 * s, 0, 0), "leg_R": (32 * s, 0, 0), "arm_L": (-22 * s, 0, 0), "arm_R": (22 * s, 0, 0),
           "torso": (-3, 0, 4 * s), "head": (2, 0, -3 * s)}
    return rot, {"root": (0, 0.035 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
lp.end_actions(rig)   # 개그 동작: 쓰러질 때 down · 승리할 때 cheer(D-313)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "lb", center_z=1.0, ortho=2.5)

lp.export(os.path.join(OUT, "liu_bei.glb"), [rig, mesh], animated=True)
print("DONE")
