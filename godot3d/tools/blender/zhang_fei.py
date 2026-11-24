# 장비 저폴리 모델 + 뼈대 + 동작 — 블렌더 코드로만 만든다.
# D-278 설정화(zhang_fei.webp, 약 3등신) → D-314: 새 설정화(큰 머리, 약 2등신)를 보고 처음부터:
#   두 겹 봉긋한 검은 두건 + 뒤 매듭 · 두 끈 + 등까지 내려오는 검은 뒷천 / 그을린 얼굴 · 성난 눈썹 · 부릅뜬 둥근 눈 · 크게 웃는 입 /
#   사방으로 뻗친 검은 수염 · 콧수염 / 붉은 목수건 / 호랑이 얼굴 청동 견갑(양쪽) / 갈색 가죽 갑옷 조끼(판) /
#   남색 소매 · 옷 · 바지 / 붉은 허리띠 + 구리 육각 버클 · 늘어진 붉은 띠 / 갈색 신.
#   장팔사모는 무기 설정화(D-317)대로 오른손에.
# 동작: idle · walk + 개그 동작(lowpoly.end_actions: down · cheer, D-313).
# 실행: python godot3d/tools/blender/zhang_fei.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN   = lp.mat("skin",   "b87a52")          # 그을린 얼굴 · 주먹
BLACK  = lp.mat("black",  "26221f")
WHITE  = lp.mat("white",  "f6f2ea")
NAVY   = lp.mat("navy",   "34406e")          # 남색 옷
LEATH  = lp.mat("leath",  "6e4a36")          # 가죽 갑옷
DLEATH = lp.mat("dleath", "553828")
RED    = lp.mat("red",    "a8343a")
BRONZE = lp.mat("bronze", "c08458", 0.45, 0.5)
MOUTH  = lp.mat("mouth",  "7a2a2a")
STEEL  = lp.mat("steel",  "c8ccd2", 0.3, 0.9)

b = lp.Body()
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.15 * side
    b.box(0.18, 0.28, 0.10, (x, -0.03, 0.05), DLEATH)                 # 갈색 신
    b.cone(0.12, 0.13, 0.08, 0.28, NAVY, x=x, v=8)                    # 남색 바지

b.bone = "torso"
b.cone(0.44, 0.34, 0.18, 0.58, NAVY, v=10)                            # 남색 옷자락
b.cone(0.40, 0.36, 0.30, 0.60, LEATH, v=8)                            # 가죽 갑옷 치마(판)
b.box(0.30, 0.03, 0.30, (0, -0.39, 0.44), DLEATH, (R(-12), 0, 0))     # 앞 판 테
b.cone(0.36, 0.33, 0.58, 0.98, LEATH, v=8)                            # 가죽 조끼
b.box(0.02, 0.03, 0.34, (0, -0.35, 0.80), DLEATH)                     # 조끼 가운데 선
for z in (0.72, 0.88):
    b.box(0.60, 0.03, 0.02, (0, -0.33, z), DLEATH)                    # 조끼 판 이음
b.cone(0.37, 0.37, 0.55, 0.62, RED, v=10)                             # 붉은 허리띠
b.box(0.16, 0.05, 0.10, (0, -0.37, 0.585), BRONZE)                    # 구리 육각 버클
b.box(0.07, 0.02, 0.32, (0.10, -0.38, 0.40), RED, (R(-10), 0, R(4)))  # 늘어진 붉은 띠
b.cone(0.26, 0.20, 0.94, 1.04, RED, v=8)                              # 붉은 목수건
b.box(0.18, 0.03, 0.16, (0, -0.26, 0.92), RED, (0, 0, R(45)))         # 목수건 매듭(앞 세모)
for side in (-1, 1):                                                  # 호랑이 얼굴 청동 견갑
    x = 0.36 * side
    b.box(0.30, 0.32, 0.10, (x, 0.0, 0.93), BRONZE, (0, R(-24 * side), 0))
    b.ball(0.07, (x * 1.05, -0.12, 0.96), lp.mat("dbronze", "9a6440", 0.5, 0.5), 1, (1.0, 0.6, 1.0))   # 호랑이 얼굴(흉내)
b.box(0.62, 0.05, 0.70, (0, 0.35, 0.95), BLACK, (R(5), 0, 0))         # 두건 뒷천(등까지)

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-22 * side), 0)
    b.cone(0.15, 0.13, 0.60, 0.95, NAVY, x=0.45 * side, v=8, rot=rot)
    b.ball(0.125, (0.59 * side, -0.02, 0.50), SKIN, 1)                # 큰 주먹

# 장팔사모(오른손) — 무기 설정화(D-317, art/concept/zhang_fei_spear.webp): 갈색 자루 · 구리 고리 둘 · 둥근 구리 물미 ·
#   붉은 술(가닥) · 구리 목 고리 둘 · 굵고 매끈한 물결 칼날(옆에서 보면 얇음)
b.bone = "arm_R"
PX, PY = -0.60, -0.10
SBROWN = lp.mat("sbrown", "5a4038")
COPPER = lp.mat("copper", "d08a68", 0.45, 0.5)
b.cone(0.035, 0.035, -0.05, 1.66, SBROWN, x=PX, y=PY, v=8)           # 갈색 자루
for z in (0.55, 1.15):
    b.cone(0.05, 0.05, z, z + 0.06, COPPER, x=PX, y=PY, v=8)          # 구리 고리
b.cone(0.05, 0.05, -0.08, -0.03, COPPER, x=PX, y=PY, v=8)
b.ball(0.05, (PX, PY, -0.11), COPPER, 1, (1.0, 1.0, 1.2))            # 둥근 구리 물미
b.cone(0.05, 0.10, 1.50, 1.70, RED, x=PX, y=PY, v=10)                # 붉은 술(아래로 퍼짐)
for k in range(6):
    a = R(k * 60)
    b.box(0.03, 0.03, 0.20, (PX + math.cos(a) * 0.08, PY + math.sin(a) * 0.08, 1.58), RED)   # 술 가닥
b.cone(0.06, 0.06, 1.70, 1.76, COPPER, x=PX, y=PY, v=10)             # 구리 목 고리 둘
b.cone(0.08, 0.08, 1.78, 1.83, COPPER, x=PX, y=PY, v=10)
x0, z0 = PX, 1.83                                                    # 물결 칼날: 짧은 상자를 이어 S자로(끝이 가늘어짐)
for k in range(12):
    t0, t1 = k / 12, (k + 1) / 12
    xa, xb = PX + 0.10 * math.sin(t0 * 2.6 * math.pi), PX + 0.10 * math.sin(t1 * 2.6 * math.pi)
    za, zb = 1.83 + t0 * 1.0, 1.83 + t1 * 1.0
    w = 0.13 * (1.0 - 0.55 * t0)
    seg = math.hypot(xb - xa, zb - za)
    b.box(w, 0.06, seg + 0.07, ((xa + xb) / 2, PY, (za + zb) / 2), STEEL, (0, math.atan2(xb - xa, zb - za), 0))   # 이음새 틈이 안 보이게 겹침

b.bone = "head"
b.ball(0.34, (0, 0, 1.27), SKIN, 2, (1.02, 0.95, 0.98))               # 얼굴
for side in (-1, 1):
    b.ball(0.08, (0.35 * side, 0.02, 1.26), SKIN, 1, (0.6, 1.0, 1.1))
    b.ball(0.065, (0.12 * side, -0.29, 1.32), WHITE, 1, (1.0, 0.5, 1.0))   # 부릅뜬 흰자
    b.ball(0.035, (0.12 * side, -0.325, 1.32), BLACK, 1)              # 눈동자
    b.box(0.18, 0.06, 0.07, (0.13 * side, -0.30, 1.43), BLACK, (0, R(-24 * side), 0))   # 성난 굵은 눈썹
    b.box(0.13, 0.04, 0.04, (0.07 * side, -0.33, 1.18), BLACK, (0, R(-20 * side), 0))   # 콧수염(끝이 올라감)
b.box(0.07, 0.06, 0.08, (0, -0.34, 1.25), SKIN)
b.box(0.22, 0.04, 0.09, (0, -0.31, 1.10), MOUTH)                      # 크게 벌린 입
b.box(0.18, 0.045, 0.03, (0, -0.315, 1.135), WHITE)                   # 윗니
# 사방으로 뻗친 수염: 턱 둘레에 뾰족한 원뿔을 부채꼴로
for k in range(11):
    a = R(-100 + k * 20)
    r0 = 0.30
    cx, cz = math.sin(a) * r0, 1.05 + math.cos(a) * 0.20 - 0.10
    b.cone(0.07, 0.0, 0.0, 0.26, BLACK, x=cx, y=-0.14 - 0.06 * math.cos(a), v=5, rot=(R(-20), a + math.pi, 0)).location.z = cz
b.ball(0.26, (0, -0.10, 1.00), BLACK, 1, (1.15, 0.75, 0.75))          # 수염 덩어리(턱 밑)
b.box(0.60, 0.20, 0.30, (0, 0.18, 1.14), BLACK)                       # 뒷머리
# 검은 두건: 이마 띠 → 아래 봉긋 → 위 봉긋 · 뒤 매듭 + 두 끈
b.cone(0.37, 0.36, 1.42, 1.56, BLACK, v=12)
b.ball(0.35, (0, 0.02, 1.58), BLACK, 2, (1.0, 1.0, 0.65))
b.ball(0.27, (0, 0.06, 1.76), BLACK, 2, (1.0, 1.0, 0.75))
b.box(0.16, 0.10, 0.10, (0, 0.37, 1.48), lp.mat("dk", "1a1816"))
for side in (-1, 1):
    b.box(0.07, 0.03, 0.30, (0.05 * side, 0.41, 1.30), lp.mat("dk", "1a1816"), (R(8), R(12 * side), 0))

mesh = b.join("zhang_fei")
rig = lp.make_rig("zhang_fei", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.15, 0, 0.28),     ( 0.15, 0, 0.0),        "root"),
    ("leg_R", (-0.15, 0, 0.28),     (-0.15, 0, 0.0),        "root"),
    ("arm_L", ( 0.33, 0, 0.94),     ( 0.59, 0, 0.50),       "torso"),
    ("arm_R", (-0.33, 0, 0.94),     (-0.59, -0.08, 0.50),   "torso"),
])

def idle(f):   # 씩씩거리듯 어깨가 들썩
    t = f / 24 * 2 * math.pi
    return ({"head": (3 * math.sin(t), 0, 0), "arm_L": (0, 0, -4 * math.sin(t))},
            {"torso": (0, 0.018 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 성큼성큼 · 어깨를 흔들며
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-36 * s, 0, 0), "leg_R": (36 * s, 0, 0), "arm_L": (-26 * s, 0, 0), "arm_R": (8 * s, 0, 0),
           "torso": (-5, 0, 7 * s), "head": (3, 0, -5 * s)}
    return rot, {"root": (0, 0.04 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
lp.end_actions(rig)   # 개그 동작: 쓰러질 때 down · 승리할 때 cheer(D-313)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "zf", center_z=1.0, ortho=2.5)

lp.export(os.path.join(OUT, "zhang_fei.glb"), [rig, mesh], animated=True)
print("DONE")
