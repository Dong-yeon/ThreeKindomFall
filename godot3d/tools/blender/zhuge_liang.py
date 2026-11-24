# 제갈량 저폴리 모델 + 뼈대 + 동작 — 블렌더 코드로만 만든다.
# D-295 임시(글 설명, 윤건) → D-311: 설정화(godot3d/art/concept/zhuge_liang.webp)를 보고 처음부터 큰 머리(약 2등신)로:
#   세로 골이 진 높은 검은 관 + 아래 띠 / 양옆으로 늘어진 긴 검은 머리 / 가는 눈 · 팔자 콧수염 · 뾰족한 턱수염 · 볼 홍조 /
#   흰 학창의(하늘색 깃 · 앞섶 · 자락 테 · 소맷부리) · 검은 허리띠 + 초록 옥 장식 + 검은 술 · 흰 바지 · 검은 신.
#   학우선은 설정화에선 가슴에 꽂혀 있지만 무기라 오른손에 듦 — 모양은 무기 설정화(D-316)대로.
# 동작: idle · walk + 개그 동작(lowpoly.end_actions: down · cheer, D-313).
# 실행: python godot3d/tools/blender/zhuge_liang.py <출력 폴더> [--render]   (pip install bpy)
# 결과: zhuge_liang.glb (--render면 정면 · 옆 · 뒤 zl_*.png)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN  = lp.mat("skin",  "f2cdb4")
BLUSH = lp.mat("blush", "f0a0a0")
WHITE = lp.mat("white", "eeeeec")          # 학창의
PANTS = lp.mat("pants", "dcdcda")
TRIM  = lp.mat("trim",  "9cc6e8")          # 하늘색 테
BLACK = lp.mat("black", "242424")          # 관 · 머리 · 띠 · 신
JADE  = lp.mat("jade",  "5e9a7c", 0.4)
FEATH = lp.mat("feath", "fafaf8")
WOOD  = lp.mat("wood",  "6a4a30")

b = lp.Body()
# 앞쪽 = -Y, 발밑 z = 0, 키 약 2.1(관 끝). 오른쪽 = -X.
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.14 * side
    b.box(0.17, 0.27, 0.09, (x, -0.03, 0.045), BLACK)                 # 검은 신
    b.cone(0.11, 0.12, 0.08, 0.24, PANTS, x=x, v=8)                   # 흰 바지

b.bone = "torso"
b.cone(0.44, 0.33, 0.16, 0.62, WHITE, v=10)                           # 학창의 자락
b.cone(0.445, 0.43, 0.14, 0.20, TRIM, v=10)                           # 자락 하늘색 테
b.box(0.06, 0.02, 0.46, (0.12, -0.41, 0.40), TRIM, (R(-14), 0, 0))    # 앞섶 테(세로)
b.cone(0.33, 0.29, 0.62, 0.98, WHITE, v=10)                           # 윗몸
b.box(0.07, 0.02, 0.44, (-0.06, -0.31, 0.80), TRIM, (0, R(-30), R(-38)))   # 깃(대각선, 하늘색)
b.box(0.07, 0.02, 0.24, ( 0.10, -0.30, 0.90), TRIM, (0, R(30), R(38)))
b.cone(0.30, 0.26, 0.95, 1.01, TRIM, v=10)                            # 목깃
b.cone(0.34, 0.34, 0.60, 0.68, BLACK, v=10)                           # 검은 허리띠
b.box(0.16, 0.04, 0.14, (0.02, -0.355, 0.62), JADE)                   # 옥 장식
b.box(0.05, 0.03, 0.10, (0.02, -0.36, 0.50), JADE)
b.cone(0.03, 0.015, 0.36, 0.46, BLACK, x=0.02, y=-0.36, v=5)          # 검은 술
b.box(0.04, 0.02, 0.26, (-0.16, -0.34, 0.50), BLACK, (0, 0, R(-25)))  # 늘어진 끈
b.box(0.30, 0.05, 0.40, (0, 0.32, 0.40), WHITE)                       # 뒤 자락

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-24 * side), 0)
    b.cone(0.17, 0.14, 0.60, 0.97, WHITE, x=0.44 * side, v=8, rot=rot)   # 넓은 소매
    b.cone(0.175, 0.17, 0.58, 0.65, TRIM, x=0.52 * side, v=8, rot=rot)   # 하늘색 소맷부리
    b.ball(0.11, (0.58 * side, -0.02, 0.50), SKIN, 1)                 # 주먹
# 학우선(오른손) — 무기 설정화(D-316, art/concept/zhuge_liang_fan.webp): 두 겹으로 겹친 둥근 흰 깃털(끝 하늘색) ·
#   갈색 자루 · 갈색 테 안 초록 옥 · 금 고리 · 금 띠 · 하늘색 술
b.bone = "arm_R"
FX, FY = -0.60, -0.10
FWHITE = lp.mat("fwhite", "f6f6f4")
FBLUE  = lp.mat("fblue",  "bcd6ee")
FBROWN = lp.mat("fbrown", "6e5040")
FGOLD  = lp.mat("fgold",  "e2b860", 0.5, 0.4)
b.cone(0.03, 0.04, 0.30, 0.80, FBROWN, x=FX, y=FY, v=8)              # 갈색 자루
b.cone(0.045, 0.045, 0.40, 0.44, FGOLD, x=FX, y=FY, v=8)             # 금 띠
b.cone(0.04, 0.0, 0.16, 0.30, FBLUE, x=FX, y=FY, v=6)                # 하늘색 술
b.box(0.03, 0.03, 0.06, (FX, FY - 0.04, 0.70), FGOLD)                # 금 고리
b.ball(0.10, (FX, FY - 0.01, 0.84), FBROWN, 1, (1.0, 0.45, 1.1))     # 옥 테
b.ball(0.075, (FX, FY - 0.04, 0.84), JADE, 1, (1.0, 0.45, 1.15))     # 초록 옥
for layer, (n, ln, spread, dy, base) in enumerate(((7, 0.62, 48, 0.03, 0.86), (5, 0.44, 40, -0.02, 0.86))):
    for k in range(n):   # 깃털: 굵고 둥근 납작 타원(위로 모임, 뒷줄이 길고 앞줄이 짧게 겹침) + 끝 하늘색
        a = math.radians(-spread + 2 * spread * k / (n - 1))
        cx, cz = FX + math.sin(a) * ln * 0.5, base + math.cos(a) * ln * 0.5
        f = b.ball(0.5, (cx, FY + dy, cz), FWHITE, 2, (0.22, 0.06, ln))
        f.rotation_euler = (0, a, 0)
        t = b.ball(0.5, (FX + math.sin(a) * ln * 0.88, FY + dy - 0.012, base + math.cos(a) * ln * 0.88), FBLUE, 2, (0.15, 0.04, ln * 0.22))
        t.rotation_euler = (0, a, 0)

b.bone = "head"
b.ball(0.33, (0, 0, 1.26), SKIN, 2, (1.0, 0.95, 1.0))                # 얼굴
for side in (-1, 1):
    b.ball(0.075, (0.33 * side, 0.02, 1.25), SKIN, 1, (0.6, 1.0, 1.1))  # 귀
    b.box(0.11, 0.03, 0.025, (0.12 * side, -0.31, 1.30), BLACK)       # 가는 눈
    b.box(0.12, 0.03, 0.025, (0.12 * side, -0.30, 1.38), BLACK, (0, R(-8 * side), 0))   # 가는 눈썹
    b.box(0.08, 0.02, 0.05, (0.20 * side, -0.27, 1.20), BLUSH)        # 볼 홍조
    b.box(0.11, 0.03, 0.03, (0.07 * side, -0.33, 1.17), BLACK, (0, R(25 * side), 0))   # 팔자 콧수염
    b.box(0.06, 0.12, 0.62, (0.31 * side, 0.02, 1.02), BLACK)         # 양옆 긴 머리
b.box(0.05, 0.05, 0.07, (0, -0.33, 1.23), SKIN)                       # 코
b.cone(0.0, 0.06, 0.90, 1.10, BLACK, y=-0.29, v=6)                    # 뾰족한 턱수염
b.box(0.66, 0.26, 0.56, (0, 0.20, 1.16), BLACK)                       # 뒷머리(관 아래 ~ 목, 뒤통수를 다 덮음)
b.cone(0.345, 0.34, 1.40, 1.54, BLACK, v=12)                          # 관 아래 띠
b.cone(0.45, 0.49, 1.52, 2.00, BLACK, v=4, rot=(0, 0, R(45)))         # 높은 관(얼굴만큼 넓고 위로 살짝 넓어지는 네모)
b.box(0.68, 0.68, 0.04, (0, 0.0, 2.00), BLACK)                        # 관 윗면
for k in range(5):   # 세로 골(앞 · 뒤)
    x = -0.24 + k * 0.12
    b.box(0.04, 0.03, 0.46, (x, -0.335, 1.76), lp.mat("ridge", "3a3a3a"))
    b.box(0.04, 0.03, 0.46, (x, 0.335, 1.76), lp.mat("ridge", "3a3a3a"))

mesh = b.join("zhuge_liang")
rig = lp.make_rig("zhuge_liang", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.14, 0, 0.24),     ( 0.14, 0, 0.0),        "root"),
    ("leg_R", (-0.14, 0, 0.24),     (-0.14, 0, 0.0),        "root"),
    ("arm_L", ( 0.32, 0, 0.94),     ( 0.58, 0, 0.50),       "torso"),
    ("arm_R", (-0.32, 0, 0.94),     (-0.58, -0.08, 0.50),   "torso"),
])

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_R": (-4 * math.sin(t), 0, 0)},
            {"torso": (0, 0.012 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 부채 든 팔은 덜 흔듦(차분하게)
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-30 * s, 0, 0), "leg_R": (30 * s, 0, 0), "arm_L": (-16 * s, 0, 0), "arm_R": (6 * s, 0, 0),
           "torso": (-3, 0, 3 * s), "head": (2, 0, -2 * s)}
    return rot, {"root": (0, 0.03 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
lp.end_actions(rig)   # 개그 동작: 쓰러질 때 down · 승리할 때 cheer(D-313)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "zl", center_z=1.05, ortho=2.6)

lp.export(os.path.join(OUT, "zhuge_liang.glb"), [rig, mesh], animated=True)
print("DONE")
