# 제갈량 저폴리 모델 + 뼈대 + 동작(idle · walk) — 블렌더 코드로만(D-295, 임시).
# 설정화 없이 글 설명으로: 윤건(검푸른 두건, 뒤로 끈 두 가닥) · 흰 학창의(넓은 소매 · 검은 테) · 푸른 회색 속옷 ·
# 검은 허리띠 + 옥 장식 · 짧은 콧수염 · 가는 턱수염 · 오른손에 흰 학우선(깃털 부채). 설정화를 받으면 맞춰 고침.
# 실행: python godot3d/tools/blender/zhuge_liang.py <출력 폴더> [--render]   (pip install bpy)
# 결과: zhuge_liang.glb (뼈 이름 · 동작은 다른 장수들과 같음)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians

SKIN  = lp.mat("skin",  "f0c8a8")
WHITE = lp.mat("white", "eeeae0")          # 학창의
EYEW  = lp.mat("eyew",  "f6f2ea")
BLACK = lp.mat("black", "1e1e24")          # 테 · 머리 · 눈
HAT   = lp.mat("hat",   "2a3448")          # 윤건
INNER = lp.mat("inner", "6a7a9a")          # 속옷
JADE  = lp.mat("jade",  "6ab89a", 0.4)
FEATH = lp.mat("feath", "f8f8f4")          # 학우선 깃털
WOOD  = lp.mat("wood",  "6a4a30")

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 2.2. 오른쪽 = -X.
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.15 * side
    b.box(0.18, 0.27, 0.18, (x, -0.02, 0.09), BLACK)                   # 검은 신
    b.cone(0.11, 0.13, 0.18, 0.56, INNER, x=x, v=6)

b.bone = "torso"
b.cone(0.50, 0.36, 0.30, 1.00, WHITE)                                 # 긴 학창의 자락(발목까지)
b.cone(0.51, 0.50, 0.26, 0.34, BLACK)                                 # 검은 단
b.box(0.06, 0.03, 0.70, (-0.05, -0.43, 0.65), BLACK, (R(-10), 0, R(-4)))   # 앞섶 검은 테
b.cone(0.37, 0.37, 0.94, 1.04, BLACK)                                 # 허리띠
b.box(0.10, 0.05, 0.10, (0, -0.38, 0.99), JADE)                       # 옥 장식
b.cone(0.03, 0.02, 0.62, 0.92, JADE, x=0.10, y=-0.40, v=5)            # 늘어진 옥 술
b.cone(0.36, 0.40, 1.02, 1.40, WHITE)                                 # 가슴
b.box(0.06, 0.03, 0.40, (-0.08, -0.385, 1.24), BLACK, (0, R(-22), 0))   # 교차 깃(검은 테)
b.box(0.06, 0.03, 0.40, ( 0.08, -0.385, 1.24), BLACK, (0, R(22), 0))
b.poly([(-0.10, 1.42), (0.10, 1.42), (0.0, 1.16)], -0.38, 0.02, INNER)
b.cone(0.27, 0.23, 1.38, 1.46, BLACK, v=8)                            # 목깃
b.poly([(-0.32, 1.40), (0.32, 1.40), (0.36, 0.34), (-0.36, 0.34)], 0.44, 0.025, WHITE)   # 뒤 자락

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-24 * side), 0)
    b.cone(0.26, 0.12, 0.84, 1.32, WHITE, x=0.55 * side, v=8, rot=rot)     # 넓은 소매
    b.cone(0.27, 0.265, 0.80, 0.88, BLACK, x=0.66 * side, v=8, rot=rot)    # 검은 소매 끝
    b.box(0.09, 0.13, 0.14, (0.70 * side, -0.02, 0.74), SKIN, rot)          # 손
# 학우선(오른손, 손잡이 + 부채꼴 깃털 판)
b.bone = "arm_R"
FX, FY = -0.72, -0.10
b.cone(0.025, 0.025, 0.66, 0.96, WOOD, x=FX, y=FY, v=6)
b.cone(0.04, 0.04, 0.95, 1.00, JADE, x=FX, y=FY, v=6)
FS = 1.0 if "--classic" in FLAGS else 1.6   # D-308: 큰 머리 그림체에선 부채를 크게
fan = [(FX, 0.98)]
for k in range(9):
    a = R(-50 + k * 12.5)
    fan.append((FX + math.sin(a) * 0.42 * FS, 0.98 + math.cos(a) * 0.48 * FS))
b.poly(fan, FY, 0.02, FEATH)
b.poly([(FX, 0.98), (FX - 0.05 * FS, 0.98 + 0.32 * FS), (FX + 0.05 * FS, 0.98 + 0.32 * FS)], FY - 0.015, 0.01, BLACK)   # 가운데 깃대

b.bone = "head"
b.ball(0.31, (0, 0, 1.70), SKIN, 2, (0.96, 0.95, 1.08))
for side in (-1, 1):
    b.box(0.06, 0.08, 0.13, (0.31 * side, 0.02, 1.68), SKIN)
    b.box(0.11, 0.03, 0.06, (0.11 * side, -0.29, 1.73), EYEW)
    b.box(0.06, 0.03, 0.06, (0.10 * side, -0.305, 1.73), BLACK)
    b.box(0.13, 0.03, 0.03, (0.12 * side, -0.29, 1.81), BLACK, (0, R(-6 * side), 0))     # 가는 눈썹
    b.box(0.11, 0.03, 0.025, (0.06 * side, -0.315, 1.59), BLACK, (0, R(-18 * side), 0))  # 짧은 콧수염
b.box(0.05, 0.05, 0.07, (0, -0.32, 1.66), SKIN)
b.cone(0.0, 0.05, 1.36, 1.54, BLACK, y=-0.28, v=5)                    # 가는 턱수염
b.ball(0.33, (0, 0.10, 1.84), BLACK, 2, (1.0, 1.0, 0.9))              # 머리
b.box(0.56, 0.18, 0.26, (0, 0.18, 1.62), BLACK)
# 윤건: 머리를 덮는 두건 + 위로 솟은 네모 + 뒤로 늘어진 끈 두 가닥
b.cone(0.35, 0.33, 1.84, 2.00, HAT)
b.box(0.40, 0.34, 0.24, (0, 0.04, 2.10), HAT)
b.box(0.30, 0.26, 0.04, (0, 0.04, 2.23), HAT)
for side in (-1, 1):
    b.box(0.06, 0.02, 0.50, (0.08 * side, 0.36, 1.82), HAT, (R(12), 0, R(6 * side)))

mesh = b.join("zhuge_liang")
CH = lp.Chibi(leg_top=0.56, neck=1.45) if "--classic" not in FLAGS else None   # D-308: 큰 머리 비율이 기본(--classic이면 예전)
if CH:
    CH.apply_mesh(mesh)
BONES = [
    ("root",  (0, 0, 0),         (0, 0, 0.3),        None),
    ("torso", (0, 0, 0.95),      (0, 0, 1.45),       "root"),
    ("head",  (0, 0, 1.45),      (0, 0, 2.1),        "torso"),
    ("leg_L", ( 0.15, 0, 0.56),  ( 0.15, 0, 0.0),    "root"),
    ("leg_R", (-0.15, 0, 0.56),  (-0.15, 0, 0.0),    "root"),
    ("arm_L", ( 0.40, 0, 1.32),  ( 0.70, 0, 0.76),   "torso"),
    ("arm_R", (-0.40, 0, 1.32),  (-0.72, -0.10, 0.76), "torso"),
]
rig = lp.make_rig("zhuge_liang", mesh, CH.bones(BONES) if CH else BONES)

def idle(f):
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_R": (-4 * math.sin(t), 0, 0)},
            {"torso": (0, 0.012 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 부채 든 팔은 덜 흔듦(차분하게)
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-24 * s, 0, 0), "leg_R": (24 * s, 0, 0), "arm_L": (-16 * s, 0, 0), "arm_R": (6 * s, 0, 0),
           "torso": (-3, 0, 3 * s), "head": (2, 0, -2 * s)}
    return rot, {"root": (0, 0.03 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
if CH:
    lp.gag_actions(rig, "fan")   # 개그 동작(D-308)
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
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.8, 0.85, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scn.render.engine = "CYCLES"; scn.cycles.device = "CPU"; scn.cycles.samples = 16
    scn.render.resolution_x, scn.render.resolution_y = 360, 480
    scn.view_settings.view_transform = "Standard"
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam); scn.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.8
    for name, p in (("front", (0, -8, 1.3)), ("side", (-8, 0, 1.3)), ("quarter", (-5, -6, 2.4))):
        cam.location = p
        cam.rotation_euler = (Vector((0, 0, 1.3)) - Vector(p)).to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"zl_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

lp.export(os.path.join(OUT, "zhuge_liang.glb"), [rig, mesh], animated=True)
print("DONE")
