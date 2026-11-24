# 관우 저폴리 모델 + 뼈대 + 동작 — 블렌더 코드로만 만든다.
# D-274 첫 시안 → D-277 설정화(guan_yu.webp, 약 3등신) → D-311: 새 설정화(godot3d/art/concept/guan_yu_v2.webp)를 보고 처음부터 큰 머리(약 2등신)로:
#   두 겹 봉긋한 녹색 두건 + 앞 금 장식 + 뒤 매듭 · 늘어진 두 끈 · 허리까지 내려오는 녹색 뒷천 / 붉은 얼굴 · 굵은 눈썹 · 까만 눈 /
#   배까지 오는 넓은 검은 수염 · 구레나룻 · 양옆 긴 머리 / 오른쪽 어깨에만 금 견갑 / 녹색 전포 + 가슴을 가로지르는 띠 /
#   갈색 허리띠 + 금 육각 버클 · 장식 / 앞에 늘어진 녹색 띠 · 녹색 바지 · 갈색 신 · 붉은 주먹.
#   설정화엔 무기가 없지만 게임용으로 청룡언월도(D-306 C안 크기)를 오른손에.
# 동작: idle · walk + 개그 동작(lowpoly.gag_actions "sweep": swing · stagger · flop).
# 실행: python godot3d/tools/blender/guan_yu.py <출력 폴더> [--render]   (pip install bpy)
# 결과: guan_yu.glb (--render면 정면 · 옆 · 뒤 gy_*.png — 설정화와 맞대 보기용)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

FACE   = lp.mat("face",   "d4594c")          # 붉은 얼굴 · 주먹
BLUSH  = lp.mat("blush",  "e8737a")
GREEN  = lp.mat("green",  "4f9a5e")          # 전포 · 두건
DKGRN  = lp.mat("dkgreen", "3d7d4a")         # 바지 · 띠 · 뒷천 그늘
GOLD   = lp.mat("gold",   "d6b04a", 0.45, 0.5)
BLACK  = lp.mat("black",  "26221f")          # 수염 · 머리 · 눈썹
BROWN  = lp.mat("brown",  "5c3f2c")          # 허리띠 · 신
STEEL  = lp.mat("steel",  "4a5058", 0.4, 0.7)
SILVER = lp.mat("silver", "d8dce0", 0.3, 0.9)

b = lp.Body()
# 앞쪽 = -Y, 발밑 z = 0, 키 약 2.0(두건 끝). 관우의 오른쪽 = -X.

# ── 다리: 갈색 신 · 녹색 바지(짧게) ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.14 * side
    b.box(0.18, 0.27, 0.10, (x, -0.03, 0.05), BROWN)
    b.cone(0.11, 0.13, 0.08, 0.28, DKGRN, x=x, v=8)

# ── 몸통: 녹색 전포 · 허리띠 · 띠 · 견갑 · 뒷천 ──
b.bone = "torso"
b.cone(0.43, 0.33, 0.18, 0.56, GREEN, v=10)                          # 전포 자락(아래로 퍼짐)
b.box(0.30, 0.02, 0.34, (-0.10, -0.40, 0.36), DKGRN, (R(-14), 0, 0))  # 앞자락 겹침(그늘)
b.cone(0.33, 0.30, 0.56, 0.98, GREEN, v=10)                          # 윗몸
b.cone(0.345, 0.345, 0.53, 0.60, BROWN, v=10)                        # 갈색 허리띠
b.box(0.15, 0.05, 0.09, (0, -0.335, 0.565), GOLD)                     # 금 육각 버클
for x in (-0.18, 0.18):
    b.box(0.05, 0.04, 0.05, (x, -0.29, 0.565), GOLD, (0, 0, R(45)))  # 띠 장식
b.box(0.07, 0.02, 0.36, (0.08, -0.36, 0.36), DKGRN, (R(-12), 0, R(4)))  # 앞에 늘어진 녹색 띠
b.box(0.08, 0.02, 0.62, (0.0, -0.30, 0.78), DKGRN, (R(-8), R(40), 0))   # 가슴을 가로지르는 띠
b.box(0.26, 0.30, 0.08, (-0.33, 0.0, 0.92), GOLD, (0, R(-28), 0))    # 오른쪽 어깨 금 견갑
b.box(0.18, 0.22, 0.04, (-0.37, 0.0, 0.95), GOLD, (0, R(-28), 0))
b.box(0.62, 0.05, 0.92, (0, 0.36, 1.00), GREEN, (R(5), 0, 0))         # 두건에서 내려온 뒷천(두건 아래 ~ 허리, 뒷머리를 덮음)
b.poly([(-0.31, 0.56), (0.31, 0.56), (0.0, 0.40)], 0.38, 0.05, GREEN)  # 뒷천 끝(뾰족)

# ── 팔: 녹색 소매 · 붉은 주먹(살짝 벌림) ──
for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-22 * side), 0)
    b.cone(0.16, 0.13, 0.60, 0.97, GREEN, x=0.44 * side, v=8, rot=rot)   # 굵은 소매
    b.cone(0.14, 0.14, 0.60, 0.66, DKGRN, x=0.51 * side, v=8, rot=rot)
    b.ball(0.125, (0.59 * side, -0.02, 0.50), FACE, 1)                # 큰 주먹

# 청룡언월도(오른손)
b.bone = "arm_R"
PX, PY = -0.60, -0.10
b.cone(0.028, 0.028, -0.05, 1.95, BLACK, x=PX, y=PY, v=6)            # 자루
b.cone(0.0, 0.045, -0.15, -0.05, GOLD, x=PX, y=PY, v=4)
for z in (0.45, 1.70):
    b.cone(0.04, 0.04, z, z + 0.05, GOLD, x=PX, y=PY, v=6)
b.cone(0.045, 0.06, 1.90, 2.00, GOLD, x=PX, y=PY, v=6)
b.box(0.12, 0.12, 0.10, (PX, PY, 2.04), GOLD)
BZ, BS = 2.08, 1.6                                                   # 칼날: 예전 모양 × 1.6
edge = [(-0.06, 2.38), (-0.17, 2.56), (-0.25, 2.82), (-0.25, 3.06), (-0.17, 3.26), (0.02, 3.38),
        (-0.06, 3.24), (-0.15, 3.06), (-0.15, 2.82), (-0.09, 2.58), (-0.02, 2.40)]
body = [(-0.02, 2.40), (-0.09, 2.58), (-0.15, 2.82), (-0.15, 3.06), (-0.06, 3.24), (0.02, 3.38),
        (-0.01, 3.20), (0.01, 3.04), (0.07, 2.97), (0.01, 2.90), (0.03, 2.64), (0.06, 2.44), (0.05, 2.38)]
tr = lambda pts: [(PX + x * BS, BZ + (z - 2.38) * BS) for x, z in pts]
b.poly(tr(edge), PY, 0.04, SILVER)
b.poly(tr(body), PY, 0.04, STEEL)

# ── 머리 ──
b.bone = "head"
b.ball(0.34, (0, 0, 1.27), FACE, 2, (1.0, 0.95, 0.98))               # 얼굴
for side in (-1, 1):
    b.ball(0.08, (0.34 * side, 0.02, 1.27), FACE, 1, (0.6, 1.0, 1.1))  # 귀
    b.ball(0.05, (0.12 * side, -0.30, 1.32), BLACK, 1)                # 까만 눈
    b.ball(0.015, (0.11 * side, -0.345, 1.34), lp.mat("white", "f8f8f4"), 1)   # 눈 빛
    b.box(0.17, 0.06, 0.06, (0.13 * side, -0.30, 1.42), BLACK, (0, R(-20 * side), 0))  # 굵은 성난 눈썹(안쪽이 내려감)
    b.box(0.07, 0.02, 0.04, (0.21 * side, -0.28, 1.22), BLUSH)        # 볼 홍조
    b.box(0.06, 0.10, 0.40, (0.31 * side, 0.06, 1.10), BLACK)         # 양옆 긴 머리(귀 뒤)
    b.box(0.07, 0.10, 0.20, (0.28 * side, -0.14, 1.15), BLACK)        # 구레나룻
b.box(0.06, 0.05, 0.07, (0, -0.335, 1.24), FACE)                      # 코
beard = b.cone(0.05, 0.36, 0.56, 1.16, BLACK, y=-0.25, v=10, rot=(R(-8), 0, 0))   # 배까지 오는 넓은 수염(아래가 뾰족)
beard.scale = (1.0, 0.6, 1.0)
for side in (-1, 1):
    b.box(0.10, 0.14, 0.18, (0.25 * side, -0.18, 1.06), BLACK)        # 턱선 수염(구레나룻과 이어짐)
b.box(0.30, 0.06, 0.05, (0, -0.33, 1.17), BLACK)                      # 콧수염
b.box(0.56, 0.16, 0.26, (0, 0.16, 1.14), BLACK)                       # 뒷머리(두건 뒷천에 가려짐)
# 두건: 이마 띠 → 아래 봉긋 → 위 봉긋(두 겹) · 앞 금 장식 · 뒤 매듭 + 두 끈
b.cone(0.36, 0.355, 1.42, 1.56, GREEN, v=12)
b.ball(0.34, (0, 0.02, 1.58), GREEN, 2, (1.0, 1.0, 0.65))
b.ball(0.27, (0, 0.06, 1.76), GREEN, 2, (1.0, 1.0, 0.75))
b.box(0.11, 0.04, 0.08, (0, -0.355, 1.50), GOLD, (0, R(45), 0))
b.box(0.16, 0.10, 0.10, (0, 0.36, 1.48), DKGRN)                      # 뒤 매듭
for side in (-1, 1):
    b.box(0.07, 0.03, 0.30, (0.05 * side, 0.40, 1.30), DKGRN, (R(8), R(12 * side), 0))

mesh = b.join("guan_yu")
rig = lp.make_rig("guan_yu", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.14, 0, 0.28),     ( 0.14, 0, 0.0),        "root"),
    ("leg_R", (-0.14, 0, 0.28),     (-0.14, 0, 0.0),        "root"),
    ("arm_L", ( 0.32, 0, 0.94),     ( 0.58, 0, 0.52),       "torso"),
    ("arm_R", (-0.32, 0, 0.94),     (-0.58, -0.08, 0.52),   "torso"),
])

def idle(f):   # 0 ~ 24 (1초): 숨쉬듯 위아래
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t))},
            {"torso": (0, 0.012 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 0 ~ 16 (0.67초 한 걸음 주기) — 다리가 짧아 종종걸음
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-35 * s, 0, 0), "leg_R": (35 * s, 0, 0),
           "arm_L": (-22 * s, 0, 0), "arm_R": (8 * s, 0, 0),
           "torso": (-4, 0, 5 * s), "head": (2, 0, -4 * s)}
    return rot, {"root": (0, 0.035 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
lp.gag_actions(rig, "sweep")   # 개그 동작(D-304~307)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "gy", center_z=1.0, ortho=2.5)

lp.export(os.path.join(OUT, "guan_yu.glb"), [rig, mesh], animated=True)
print("DONE")
