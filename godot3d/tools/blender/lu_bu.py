# 여포 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만 만든다.
# D-290 임시(글 설명) → D-314: 새 설정화(큰 머리, 약 2등신)를 보고 처음부터:
#   붉은 꿩깃 두 가닥(위로 솟았다 바깥 아래로 휨) / 짙은 갈색 상투 + 금관(앞이 높은 꽃 모양) / 짙은 갈색 머리 · 날카로운 눈썹 · 씩 웃는 입 /
#   붉은 목수건 / 금 비늘 갑옷(가슴 · 앞 치마판, 갈색 테) · 금 비늘 견갑 / 붉은 망토(등 전체) / 자주 붉은 소매 · 옷 · 바지 · 갈색 소맷부리 · 신.
#   설정화엔 무기가 없지만 게임용으로 방천화극(칼날 크게)을 오른손에. 보스라 개그 동작 없음. 판에선 2.0배(D-310).
# 실행: python godot3d/tools/blender/lu_bu.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN   = lp.mat("skin",   "f2cbb0")
HAIR   = lp.mat("hair",   "3a2a24")
BLACK  = lp.mat("black",  "242120")
WHITE  = lp.mat("white",  "f6f2ea")
GOLD   = lp.mat("gold",   "d8a840", 0.45, 0.5)
DGOLD  = lp.mat("dgold",  "b88a30", 0.5, 0.4)    # 비늘 결
BROWN  = lp.mat("brown",  "6e4a30")
RED    = lp.mat("red",    "b8343a")              # 망토 · 목수건 · 꿩깃
DRED   = lp.mat("dred",   "8a2a2e")              # 옷 · 바지
STEEL  = lp.mat("steel",  "c8ccd2", 0.3, 0.9)
WOOD   = lp.mat("wood",   "3a2418")

b = lp.Body()
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.15 * side
    b.box(0.18, 0.28, 0.10, (x, -0.03, 0.05), BROWN)
    b.cone(0.12, 0.13, 0.08, 0.28, DRED, x=x, v=8)

b.bone = "torso"
b.cone(0.42, 0.34, 0.18, 0.58, DRED, v=10)                            # 붉은 옷자락
b.box(0.48, 0.05, 0.34, (0, -0.37, 0.44), GOLD, (R(-12), 0, 0))       # 금 비늘 앞 치마판
b.box(0.52, 0.04, 0.38, (0, -0.355, 0.44), BROWN, (R(-12), 0, 0))     # 치마판 갈색 테
b.cone(0.36, 0.33, 0.58, 0.98, GOLD, v=10)                            # 금 비늘 가슴 갑옷
for z in (0.66, 0.76, 0.86):                                          # 비늘 결(가로 줄)
    b.cone(0.365, 0.355, z, z + 0.025, DGOLD, v=10)
b.cone(0.37, 0.37, 0.56, 0.62, BROWN, v=10)                           # 갈색 허리띠
b.cone(0.26, 0.20, 0.94, 1.04, RED, v=8)                              # 붉은 목수건
b.box(0.18, 0.03, 0.16, (0, -0.26, 0.92), RED, (0, 0, R(45)))
for side in (-1, 1):                                                  # 금 비늘 견갑
    x = 0.36 * side
    b.ball(0.18, (x, 0.0, 0.92), GOLD, 1, (1.2, 1.2, 0.7))
    b.cone(0.20, 0.20, 0.84, 0.87, DGOLD, x=x * 1.05, v=8)
b.box(0.70, 0.05, 0.86, (0, 0.36, 0.52), RED, (R(8), 0, 0))           # 붉은 망토(등 전체 · 발목까지)
for side in (-1, 1):
    b.box(0.05, 0.40, 0.70, (0.37 * side, 0.15, 0.55), RED, (R(8), 0, 0))   # 망토 옆자락

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-22 * side), 0)
    b.cone(0.14, 0.12, 0.60, 0.92, DRED, x=0.45 * side, v=8, rot=rot)
    b.cone(0.13, 0.13, 0.60, 0.66, BROWN, x=0.51 * side, v=8, rot=rot)   # 갈색 소맷부리
    b.ball(0.11, (0.59 * side, -0.02, 0.50), SKIN, 1)

# 방천화극(오른손, 칼날 크게)
b.bone = "arm_R"
PX, PY = -0.60, -0.10
b.cone(0.03, 0.03, -0.05, 2.10, WOOD, x=PX, y=PY, v=6)
b.cone(0.0, 0.05, -0.18, -0.05, GOLD, x=PX, y=PY, v=4)
for z in (0.40, 1.80):
    b.cone(0.045, 0.045, z, z + 0.05, GOLD, x=PX, y=PY, v=6)
b.cone(0.07, 0.05, 2.06, 2.18, GOLD, x=PX, y=PY, v=6)
b.box(0.05, 0.03, 0.18, (PX, PY - 0.05, 2.04), RED)
S = 1.6
b.poly([(PX - 0.05 * S, 2.18), (PX + 0.05 * S, 2.18), (PX + 0.06 * S, 2.18 + 0.33 * S), (PX, 2.18 + 0.68 * S), (PX - 0.06 * S, 2.18 + 0.33 * S)], PY, 0.04, STEEL)
moon = [(0.04, 0.00), (0.16, -0.04), (0.30, 0.04), (0.36, 0.20), (0.30, 0.36), (0.20, 0.40), (0.26, 0.24), (0.22, 0.10), (0.10, 0.08), (0.04, 0.12)]
b.poly([(PX + x * S, 2.18 + z * S) for x, z in moon], PY, 0.04, STEEL)
b.poly([(PX - x * S, 2.18 + z * S) for x, z in moon], PY, 0.04, STEEL)

b.bone = "head"
b.ball(0.33, (0, 0, 1.26), SKIN, 2, (1.0, 0.95, 1.0))
for side in (-1, 1):
    b.ball(0.075, (0.33 * side, 0.02, 1.25), SKIN, 1, (0.6, 1.0, 1.1))
    b.box(0.11, 0.03, 0.05, (0.12 * side, -0.31, 1.31), BLACK, (0, R(-10 * side), 0))   # 날카로운 눈
    b.ball(0.012, (0.10 * side, -0.335, 1.32), WHITE, 1)
    b.box(0.17, 0.05, 0.05, (0.13 * side, -0.30, 1.41), HAIR, (0, R(-22 * side), 0))    # 날카로운 눈썹
b.box(0.05, 0.05, 0.07, (0, -0.33, 1.23), SKIN)
b.box(0.12, 0.02, 0.02, (0.02, -0.33, 1.14), lp.mat("mouth", "8a4a40"), (0, R(-10), 0))   # 씩 웃는 입
b.ball(0.35, (0, 0.10, 1.42), HAIR, 2, (1.0, 0.9, 0.85))              # 짙은 갈색 머리
b.box(0.08, 0.06, 0.12, (0, -0.32, 1.53), HAIR, (0, R(45), 0))        # 이마 가운데 머리끝
b.ball(0.14, (0, 0.08, 1.74), HAIR, 1)                                # 상투
b.cone(0.16, 0.20, 1.66, 1.80, GOLD, v=10)                            # 금관 몸
for k in range(5):                                                    # 금관 꽃잎(앞이 높음)
    a = R(-60 + k * 30)
    h = 0.16 if k == 2 else 0.10
    b.box(0.08, 0.03, h, (math.sin(a) * 0.19, -math.cos(a) * 0.19, 1.82 + h * 0.5), GOLD, (0, a, 0))
# 붉은 꿩깃 두 가닥: 금관에서 위로 솟았다가 바깥 아래로 크게 휨(짧은 상자를 이어 붙임)
for side in (-1, 1):
    x, z = 0.10 * side, 1.86
    for k in range(13):
        ang = R(10 + k * k * 1.0)                                      # 바깥 위로 길게 솟았다가 아래로 점점 크게 휨
        seg = 0.11
        nx, nz = x + math.sin(ang) * seg * side, z + math.cos(ang) * seg
        b.box(0.05, 0.05, seg + 0.03, ((x + nx) / 2, 0.02, (z + nz) / 2), RED, (0, ang * side, 0))
        x, z = nx, nz

mesh = b.join("lu_bu")
rig = lp.make_rig("lu_bu", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.15, 0, 0.28),     ( 0.15, 0, 0.0),        "root"),
    ("leg_R", (-0.15, 0, 0.28),     (-0.15, 0, 0.0),        "root"),
    ("arm_L", ( 0.33, 0, 0.94),     ( 0.59, 0, 0.50),       "torso"),
    ("arm_R", (-0.33, 0, 0.94),     (-0.59, -0.08, 0.50),   "torso"),
])

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0)}, {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-32 * s, 0, 0), "leg_R": (32 * s, 0, 0), "arm_L": (-22 * s, 0, 0), "arm_R": (6 * s, 0, 0),
           "torso": (-5, 0, 5 * s), "head": (3, 0, -4 * s)}
    return rot, {"root": (0, 0.04 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "lb2", center_z=1.3, ortho=3.4)

lp.export(os.path.join(OUT, "lu_bu.glb"), [rig, mesh], animated=True)
print("DONE")
