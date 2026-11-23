# 관우 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만 만든다.
# D-274 첫 시안 → D-277: GPT 콘셉트 설정화(godot3d/art/concept/guan_yu.webp)를 보고 다시 만듦
#   (약 3등신 · 녹색 두건과 뒤로 늘어진 천 · 금 용머리 어깨 갑옷 · 금 테 앞치마형 전포 · 검은 통바지와 장화 ·
#    언월도는 오른손 — 어두운 칼날 + 은색 날 + 등의 홈).
# 실행: python godot3d/tools/blender/guan_yu.py <출력 폴더> [--render]   (pip install bpy)
#       blender -b -P godot3d/tools/blender/guan_yu.py -- <출력 폴더> [--render]
# 결과: guan_yu.glb (--render면 정면 · 옆 · 뒤 · 3/4 확인용 PNG)
#   --chibi(D-301 시험): 큰 머리 비율(lowpoly.Chibi) + 개그 동작(swing 휘두르기 · stagger 휘청 · flop 엉덩방아 → 일어나기) → guan_yu_chibi.glb
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

FACE   = lp.mat("face",   "c5463a")          # 붉은 얼굴 · 손
GREEN  = lp.mat("green",  "3f7a52")
DKGRN  = lp.mat("dkgreen", "2c5a3c")
GOLD   = lp.mat("gold",   "c9a24e", 0.45, 0.5)
BLACK  = lp.mat("black",  "26211e")
DKGRAY = lp.mat("dkgray", "34302c")          # 바지 · 팔토시
BELT   = lp.mat("belt",   "4a362a")
STEEL  = lp.mat("steel",  "4a5058", 0.4, 0.7)  # 칼날 몸
SILVER = lp.mat("silver", "d8dce0", 0.3, 0.9)  # 칼날 날

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 2.2(두건 끝). 관우의 오른쪽 = -X(정면에서 보면 화면 왼쪽).

# ── 다리: 장화 · 통바지 ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.17 * side
    b.box(0.20, 0.28, 0.22, (x, -0.02, 0.11), BLACK)                # 장화
    b.box(0.215, 0.29, 0.04, (x, -0.02, 0.22), GOLD)                # 장화 금 테
    b.cone(0.12, 0.16, 0.22, 0.62, DKGRAY, x=x, v=6)                # 통바지

# ── 몸통: 전포 · 앞치마 · 허리띠 · 가슴 ──
b.bone = "torso"
b.cone(0.47, 0.37, 0.48, 1.0, GREEN)                                # 전포 치마(옆 · 뒤)
b.cone(0.48, 0.47, 0.44, 0.50, GOLD)                                # 치마 금 단
# 앞치마(앞 · 뒤): 금 테(뒤에 조금 크게) + 녹색 판, 치마 기울기에 맞춰 10° 눕힘
b.box(0.42, 0.025, 0.74, (0, -0.425, 0.64), GOLD, (R(-10), 0, 0))
b.box(0.36, 0.03, 0.68, (0, -0.44, 0.65), GREEN, (R(-10), 0, 0))
b.box(0.12, 0.01, 0.10, (-0.12, -0.46, 0.52), DKGRN, (R(-10), 0, 0))  # 구름 무늬(흉내)
b.box(0.12, 0.01, 0.10, ( 0.12, -0.46, 0.52), DKGRN, (R(-10), 0, 0))
b.box(0.50, 0.025, 0.78, (0, 0.425, 0.66), GOLD, (R(10), 0, 0))
b.box(0.44, 0.03, 0.72, (0, 0.44, 0.67), GREEN, (R(10), 0, 0))
b.cone(0.385, 0.385, 0.95, 1.08, BELT)                               # 허리띠
b.box(0.20, 0.06, 0.13, (0, -0.39, 1.015), GOLD)                     # 용 버클
b.box(0.08, 0.04, 0.08, (0, -0.42, 1.015), BELT, (0, R(45), 0))
b.cone(0.37, 0.41, 1.06, 1.40, GREEN)                                # 가슴(어깨로 갈수록 넓게)
b.cone(0.30, 0.20, 1.38, 1.46, DKGRN, v=8)                           # 깃
# 어깨 갑옷(금 용머리, 2단) — 덩어리 + 아래 판 + 앞으로 튀어나온 얼굴
for side in (-1, 1):
    x = 0.44 * side
    b.ball(0.20, (x, 0, 1.36), GOLD, 1, (1.15, 1.25, 0.85))
    b.box(0.30, 0.30, 0.07, (x * 1.05, 0, 1.22), GOLD, (0, R(-22 * side), 0))
    b.box(0.12, 0.08, 0.10, (x * 1.02, -0.24, 1.33), GOLD)          # 용 얼굴
    b.box(0.03, 0.02, 0.02, (x * 1.02 - 0.03, -0.285, 1.355), BLACK)  # 눈
    b.box(0.03, 0.02, 0.02, (x * 1.02 + 0.03, -0.285, 1.355), BLACK)

# ── 팔: 녹색 반소매 · 검은 팔토시 · 금 테 · 붉은 손 ──
b.bone = "arm_L"   # 왼팔(+X): 손을 펴고 살짝 벌림
b.cone(0.11, 0.13, 0.98, 1.28, GREEN, x=0.50, rot=(0, R(10), 0))
b.cone(0.095, 0.105, 0.74, 0.98, DKGRAY, x=0.54, v=6, rot=(0, R(10), 0))
b.cone(0.112, 0.112, 0.94, 0.98, GOLD, x=0.535, v=6)
b.cone(0.105, 0.105, 0.74, 0.78, GOLD, x=0.57, v=6)
b.box(0.08, 0.13, 0.15, (0.585, -0.02, 0.66), FACE, (0, R(12), 0))  # 편 손

b.bone = "arm_R"   # 오른팔(-X) + 청룡언월도
b.cone(0.11, 0.13, 0.98, 1.28, GREEN, x=-0.50, rot=(R(-12), R(-6), 0))
b.cone(0.095, 0.105, 0.74, 0.98, DKGRAY, x=-0.53, y=-0.06, v=6, rot=(R(-20), 0, 0))
b.cone(0.112, 0.112, 0.94, 0.98, GOLD, x=-0.53, y=-0.02, v=6)
b.cone(0.105, 0.105, 0.74, 0.78, GOLD, x=-0.53, y=-0.10, v=6)
b.ball(0.09, (-0.55, -0.12, 0.70), FACE, 1)                          # 자루를 쥔 주먹
PX, PY = -0.56, -0.13
b.cone(0.03, 0.03, 0.10, 2.30, BLACK, x=PX, y=PY, v=6)               # 검은 자루
b.cone(0.0, 0.05, -0.06, 0.12, GOLD, x=PX, y=PY, v=4)                # 금 물미(뾰족)
b.cone(0.05, 0.05, 0.12, 0.17, GOLD, x=PX, y=PY, v=6)
for z in (0.62, 1.95):                                              # 자루 금 고리
    b.cone(0.042, 0.042, z, z + 0.05, GOLD, x=PX, y=PY, v=6)
b.cone(0.045, 0.06, 2.20, 2.30, GOLD, x=PX, y=PY, v=6)               # 칼날 받침(용머리 흉내)
b.box(0.13, 0.13, 0.12, (PX, PY, 2.34), GOLD)
# 칼날: 바깥(-X)은 은색 날, 안쪽은 어두운 몸 + 등의 홈, 끝은 몸 쪽으로 휨
edge = [(-0.06, 2.38), (-0.17, 2.56), (-0.25, 2.82), (-0.25, 3.06), (-0.17, 3.26), (0.02, 3.38),
        (-0.06, 3.24), (-0.15, 3.06), (-0.15, 2.82), (-0.09, 2.58), (-0.02, 2.40)]
body = [(-0.02, 2.40), (-0.09, 2.58), (-0.15, 2.82), (-0.15, 3.06), (-0.06, 3.24), (0.02, 3.38),
        (-0.01, 3.20), (0.01, 3.04), (0.07, 2.97), (0.01, 2.90), (0.03, 2.64), (0.06, 2.44), (0.05, 2.38)]
b.poly([(PX + x, z) for x, z in edge], PY, 0.035, SILVER)
b.poly([(PX + x, z) for x, z in body], PY, 0.035, STEEL)
for dy in (-0.03, 0.03):                                            # 칼날의 금 용 무늬(흉내)
    b.box(0.05, 0.01, 0.30, (PX - 0.06, PY + dy, 2.80), GOLD, (0, R(8), 0))
    b.box(0.07, 0.01, 0.05, (PX - 0.04, PY + dy, 2.98), GOLD)

# ── 머리 ──
b.bone = "head"
b.ball(0.33, (0, 0, 1.70), FACE, 2, (1.0, 0.95, 1.08))               # 얼굴
b.box(0.06, 0.08, 0.12, (-0.33, 0.02, 1.68), FACE)                    # 귀
b.box(0.06, 0.08, 0.12, ( 0.33, 0.02, 1.68), FACE)
b.box(0.56, 0.26, 0.42, (0, 0.17, 1.55), BLACK)                       # 뒤로 내린 긴 머리
b.box(0.07, 0.10, 0.30, (-0.30, -0.06, 1.62), BLACK)                  # 귀밑머리
b.box(0.07, 0.10, 0.30, ( 0.30, -0.06, 1.62), BLACK)
b.box(0.15, 0.04, 0.05, (-0.13, -0.31, 1.80), BLACK, (0, R(-18), 0))  # 굵은 눈썹(바깥이 올라감)
b.box(0.15, 0.04, 0.05, ( 0.13, -0.31, 1.80), BLACK, (0, R(18), 0))
b.box(0.09, 0.03, 0.055, (-0.12, -0.315, 1.73), BLACK)                # 눈
b.box(0.09, 0.03, 0.055, ( 0.12, -0.315, 1.73), BLACK)
b.box(0.06, 0.06, 0.09, (0, -0.33, 1.66), FACE)                       # 코
beard = b.cone(0.05, 0.27, 0.98, 1.60, BLACK, y=-0.40, v=6, rot=(R(-14), 0, 0))  # 허리띠까지 오는 넓은 수염(가슴 앞으로)
beard.scale = (1.0, 0.45, 1.0)
b.box(0.34, 0.07, 0.06, (0, -0.33, 1.60), BLACK)                      # 콧수염
b.box(0.05, 0.05, 0.14, (-0.17, -0.31, 1.53), BLACK)
b.box(0.05, 0.05, 0.14, ( 0.17, -0.31, 1.53), BLACK)
# 녹색 두건(높고 둥글게) + 금 띠 + 이마 금 마름모 + 뒤로 늘어진 천
b.cone(0.355, 0.33, 1.84, 2.06, GREEN)
b.ball(0.33, (0, 0.02, 2.06), GREEN, 2, (1.0, 1.0, 0.9))
b.cone(0.36, 0.36, 1.83, 1.89, GOLD)
b.box(0.12, 0.04, 0.12, (0, -0.355, 1.92), GOLD, (0, R(45), 0))
b.box(0.44, 0.04, 0.30, (0, 0.33, 1.80), DKGRN)                       # 뒤판
b.box(0.18, 0.03, 0.80, (-0.09, 0.37, 1.30), GREEN, (R(8), 0, 0))     # 허리까지 늘어진 천
b.box(0.18, 0.03, 0.76, ( 0.09, 0.37, 1.32), DKGRN, (R(8), 0, 0))

mesh = b.join("guan_yu")
# --weapon=자루배,칼날배(D-306 무기 크기 비교, 기본 1.1,1.6)
WPN = next((f.split("=", 1)[1] for f in FLAGS if f.startswith("--weapon=")), "1.1,1.6").split(",")   # D-306: C안(자루 1.1 · 칼날 1.6)으로 굳힘
CH = lp.Chibi(weapon=float(WPN[0]), blade=float(WPN[1]), blade_from=2.20, blade_pivot=(PX, PY)) if "--chibi" in FLAGS else None
if CH:
    CH.apply_mesh(mesh)
BONES = [
    ("root",  (0, 0, 0),           (0, 0, 0.3),           None),
    ("torso", (0, 0, 0.95),        (0, 0, 1.45),          "root"),
    ("head",  (0, 0, 1.45),        (0, 0, 2.1),           "torso"),
    ("leg_L", ( 0.17, 0, 0.62),    ( 0.17, 0, 0.0),       "root"),
    ("leg_R", (-0.17, 0, 0.62),    (-0.17, 0, 0.0),       "root"),
    ("arm_L", ( 0.48, 0, 1.30),    ( 0.56, 0, 0.72),      "torso"),
    ("arm_R", (-0.48, 0, 1.30),    (-0.55, -0.12, 0.72),  "torso"),
]
rig = lp.make_rig("guan_yu", mesh, CH.bones(BONES) if CH else BONES)

def idle(f):   # 0 ~ 24 (1초): 숨쉬듯 위아래
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t))},
            {"torso": (0, 0.015 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 0 ~ 16 (0.67초 한 걸음 주기)
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-30 * s, 0, 0), "leg_R": (30 * s, 0, 0),
           "arm_L": (-24 * s, 0, 0), "arm_R": (8 * s, 0, 0),     # 언월도 든 팔은 조금만
           "torso": (-5, 0, 5 * s), "head": (3, 0, -4 * s)}
    return rot, {"root": (0, 0.04 * abs(s), 0)}

idle_act = lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
walk_act = lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)

if CH:
    def ease(a, b, k):
        k = max(0.0, min(1.0, k))
        k = k * k * (3 - 2 * k)
        return a + (b - a) * k

    def swing(f):   # 0 ~ 14 (0.58초): 까치발로 언월도를 머리 위로 → 무게에 끌려 몸이 한 바퀴 빙글 → 휘청 멈춤(D-304 — 우스꽝스럽게)
        if f <= 4:      # 들어 올림: 몸을 뒤로 젖히고 까치발
            k = ease(0, 1, f / 4)
            return ({"arm_R": (-150 * k, 0, 20 * k), "arm_L": (-60 * k, 0, 30 * k), "torso": (-18 * k, 0, 0), "head": (-10 * k, 0, 0),
                     "leg_L": (0, 0, -8 * k), "leg_R": (0, 0, 8 * k)}, {"root": (0, 0.08 * k, 0)})
        if f <= 10:     # 휩쓸기: 팔은 옆으로 뻗고 윗몸이 한 바퀴(몸통 뼈를 세로축으로 360° — D-305: 다리는 걷기 그대로 두려고 뿌리 뼈 대신)
            k = (f - 4) / 6
            return ({"arm_R": (-90, 0, -10), "arm_L": (-40, 0, 70), "torso": (12 * k, -360 * ease(0, 1, k), 0), "head": (0, 0, 20 * math.sin(k * math.pi)),
                     "leg_L": (-20, 0, -25), "leg_R": (20, 0, 25)}, {"root": (0, 0.04 * math.sin(k * math.pi), 0)})
        k = (f - 10) / 4   # 멈춤: 무게에 앞으로 고꾸라질 듯 휘청
        w = math.sin(k * math.pi)
        return ({"arm_R": (ease(-90, 0, k), 0, -10), "arm_L": (ease(-40, 0, k), 0, ease(70, 0, k)), "torso": (25 * w, 0, 10 * w),
                 "head": (15 * w, 0, -10 * w), "leg_L": (-30 * w, 0, 0)}, {})

    def stagger(f):   # 0 ~ 18 (0.75초 — D-305: 공격 간격 0.8초보다 짧게): 어지러워 비틀 — 머리가 원을 그리고 언월도를 질질 끌며 깡충
        k = f / 18
        a = k * 4 * math.pi
        w = math.sin(k * math.pi)
        return ({"head": (12 * math.sin(a) * w, 0, 18 * math.cos(a) * w), "torso": (8 * math.cos(a) * w, 0, 14 * math.sin(a) * w),
                 "arm_R": (40 * w, 0, -20 * w), "arm_L": (-50 * w, 0, 60 * w),
                 "leg_L": (-35 * max(0.0, math.sin(a)) * w, 0, 0), "leg_R": (-35 * max(0.0, -math.sin(a)) * w, 0, 0)},
                {"root": (0.18 * math.sin(a * 0.5) * w, 0.07 * abs(math.sin(a)), 0)})

    def flop(f):   # 0 ~ 36 (1.5초): 뒤로 털썩 주저앉음 → 어리둥절 고개 갸웃 → 벌떡
        if f <= 6:
            sit = ease(0, 1, f / 6)
        elif f <= 26:
            sit = 1.0
        else:
            sit = ease(1, 0, (f - 26) / 10)
        wob = math.sin(f / 36 * 8 * math.pi) * (1.0 if 6 < f <= 26 else 0.0)
        return ({"torso": (-45 * sit, 0, 8 * wob), "head": (20 * sit, 0, 25 * wob),
                 "leg_L": (-95 * sit, 0, -20 * sit), "leg_R": (-95 * sit, 0, 20 * sit),
                 "arm_L": (-40 * sit, 0, 70 * sit), "arm_R": (-30 * sit, 0, -70 * sit)},
                {"root": (0, -0.42 * sit, 0.10 * sit)})

    lp.make_action(rig, "swing", list(range(0, 15, 1)), swing)
    lp.make_action(rig, "stagger", list(range(0, 19, 1)), stagger)
    lp.make_action(rig, "flop", list(range(0, 37, 1)), flop)
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
        scn.render.filepath = os.path.join(OUT, f"gy_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

lp.export(os.path.join(OUT, "guan_yu_chibi.glb" if CH else "guan_yu.glb"), [rig, mesh], animated=True)
print("DONE")
