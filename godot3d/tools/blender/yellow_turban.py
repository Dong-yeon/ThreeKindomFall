# 황건적 병사 저폴리 모델 + 뼈대 + 동작(walk) — 블렌더 코드로만.
# D-275 첫 시안 → D-280: GPT 콘셉트 설정화(godot3d/art/concept/yellow_turban.webp)를 보고 다시 만듦:
#   탁한 겨자색 두건(뒤 매듭 + 늘어진 끈) · 뻗친 검은 머리 · 그을린 피부 · 성난 눈썹 · 덥수룩한 짧은 수염 ·
#   해진 갈색 옷(짙은 조끼 + 밝은 속옷) · 찢어진 반소매 · 겨자색 허리띠(앞 매듭 + 긴 끝) · 손목 감개 ·
#   통바지 + 다리 감개 · 짚신 · 끈 감은 나무 자루에 녹슨 쇠 창날, 오른손.
# 적 떼(MultiMesh)용이라 삼각형을 아낌(작은 구 · 6각 기둥).
# 실행: python godot3d/tools/blender/yellow_turban.py <출력 폴더> [--render]   (pip install bpy)
# 결과: yellow_turban.glb(뼈대 · walk) + yellow_turban_poses.glb(walk 4프레임 정지 메시 pose_0~3)
#       --variant=militia면 militia.glb · militia_poses.glb(녹색 두건 의용군)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
# --variant=militia: 같은 몸에 녹색 두건 · 띠 → 유비의 의용군(D-285, militia.glb · militia_poses.glb)
# --variant=archer|rusher|shield: 황건 궁병 · 돌격병 · 방패병(D-288 — 같은 몸에 무기 · 색만 바꿈)
VARIANT = ""
for f in FLAGS:
    if f.startswith("--variant="):
        VARIANT = f.split("=", 1)[1]
MILITIA = VARIANT == "militia"
# --variant=zhangbao|zhangliang|daoshi: 진영 정예(D-289 — 갑옷 · 망토 · 고유 무기, 게임에선 1.4배)
ELITE = VARIANT in ["zhangbao", "zhangliang", "daoshi"]
NAME = {"militia": "militia", "archer": "yt_archer", "rusher": "yt_rusher", "shield": "yt_shield",
        "zhangbao": "elite_zhangbao", "zhangliang": "elite_zhangliang", "daoshi": "elite_daoshi"}.get(VARIANT, "yellow_turban")
lp.reset_scene()
R = math.radians

SKIN    = lp.mat("skin",    "c98e68")       # 그을린 피부
HAIR    = lp.mat("hair",    "2a221e")       # 머리 · 수염 · 눈
MUSTARD = lp.mat("mustard", "4f8a3e" if MILITIA else "9a7e3e")       # 탁한 겨자색 두건 · 띠 — 유비의 밝은 노랑(e2b838)과 구분되게 채도 · 밝기를 낮춤(D-280)
DKBRN   = lp.mat("dkbrown", {"archer": "3e4632", "shield": "34302c"}.get(VARIANT, "4e3a2e"))  # 조끼 · 바지 · 감개(궁병 녹갈 · 방패병 짙게)
LTBRN   = lp.mat("ltbrown", "8a6e58")       # 속옷 · 소매
WOOD    = lp.mat("wood",    "5a3e2c")       # 창 자루 · 짚신 끈은 띠 색
IRON    = lp.mat("iron",    "6e5e56", 0.6, 0.4)  # 녹슨 쇠
RED     = lp.mat("red",     "8a2a22")       # 돌격병 붉은 띠
BRONZE  = lp.mat("bronze",  "8a6a3a", 0.5, 0.5)  # 정예 갑옷
CAPE    = lp.mat("cape",    {"zhangbao": "a8342a", "zhangliang": "c9a03a", "daoshi": "e8d8a8"}.get(VARIANT, "c9a03a"))

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 1.75(장수보다 작게). 오른쪽 = -X.

for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.13 * side
    b.box(0.15, 0.24, 0.04, (x, -0.03, 0.02), MUSTARD)               # 짚신
    b.box(0.12, 0.14, 0.22, (x, 0, 0.15), DKBRN)                      # 다리 감개
    b.cone(0.10, 0.14, 0.24, 0.52, DKBRN, x=x, v=6)                   # 통바지

b.bone = "torso"
b.cone(0.33, 0.26, 0.40, 0.70, LTBRN, v=6)                           # 해진 속옷 아랫단
b.box(0.12, 0.05, 0.10, (-0.14, -0.29, 0.43), DKBRN, (0, 0, R(20)))  # 해진 자국(흉내)
b.box(0.10, 0.05, 0.08, ( 0.17, -0.27, 0.45), DKBRN, (0, 0, R(-25)))
b.cone(0.28, 0.27, 0.64, 1.0, DKBRN, v=6)                            # 짙은 조끼
b.box(0.06, 0.03, 0.30, (-0.07, -0.275, 0.86), LTBRN, (0, R(-24), 0))  # 여민 깃(V)
b.box(0.06, 0.03, 0.30, ( 0.07, -0.275, 0.86), LTBRN, (0, R(24), 0))
b.cone(0.295, 0.295, 0.62, 0.72, MUSTARD, v=6)                       # 겨자색 허리띠
b.box(0.10, 0.07, 0.09, (0.10, -0.29, 0.67), MUSTARD)                 # 앞 매듭
b.box(0.06, 0.02, 0.34, (0.08, -0.31, 0.48), MUSTARD, (0, R(6), 0))  # 늘어진 끝
b.box(0.06, 0.02, 0.28, (0.15, -0.30, 0.51), MUSTARD, (0, R(-10), 0))

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    x = 0.32 * side
    b.cone(0.10, 0.11, 0.80, 0.98, LTBRN, x=x, v=6)                   # 찢어진 반소매
    b.cone(0.065, 0.075, 0.62, 0.82, SKIN, x=x + 0.01 * side, v=6)    # 맨팔
    b.cone(0.08, 0.08, 0.60, 0.68, DKBRN, x=x + 0.015 * side, v=6)    # 손목 감개
b.bone = "arm_L"
b.ball(0.065, (0.34, -0.02, 0.55), SKIN, 1)
b.bone = "arm_R"
b.ball(0.07, (-0.34, -0.11, 0.57), SKIN, 1)
if VARIANT == "archer":      # 궁병: 왼손에 활 · 등에 화살통
    b.bone = "arm_L"
    bow = [(0.36, 0.30), (0.46, 0.45), (0.50, 0.70), (0.46, 0.95), (0.36, 1.10), (0.39, 1.10), (0.49, 0.95),
           (0.53, 0.70), (0.49, 0.45), (0.39, 0.30)]
    b.poly(bow, -0.10, 0.04, WOOD)
    b.box(0.01, 0.01, 0.80, (0.37, -0.10, 0.70), LTBRN)               # 활시위
    b.bone = "torso"
    b.cone(0.07, 0.07, 0.70, 1.15, WOOD, x=-0.12, y=0.25, v=6, rot=(R(12), R(-15), 0))   # 화살통
    for dx in (-0.03, 0.03):
        b.box(0.03, 0.03, 0.10, (-0.16 + dx, 0.28, 1.22), MUSTARD)    # 화살 깃
elif VARIANT == "zhangbao":   # 장보: 큰 칼(대도)
    b.bone = "arm_R"
    b.cone(0.03, 0.03, 0.30, 1.00, WOOD, x=-0.36, y=-0.12, v=5)
    b.poly([(-0.40, 1.00), (-0.24, 1.05), (-0.20, 1.55), (-0.30, 1.75), (-0.40, 1.60)], -0.12, 0.04, IRON)
elif VARIANT == "zhangliang": # 장량: 긴 극(창 + 초승달 날)
    b.bone = "arm_R"
    b.cone(0.03, 0.03, 0.0, 2.30, WOOD, x=-0.36, y=-0.12, v=5)
    b.poly([(-0.36, 2.28), (-0.30, 2.45), (-0.36, 2.75), (-0.42, 2.45)], -0.12, 0.03, IRON)
    b.poly([(-0.36, 2.15), (-0.18, 2.20), (-0.12, 2.38), (-0.20, 2.30), (-0.36, 2.28)], -0.12, 0.03, IRON)
elif VARIANT == "daoshi":     # 황건 도사: 지팡이 + 누런 부적
    b.bone = "arm_R"
    b.cone(0.03, 0.025, 0.0, 1.90, WOOD, x=-0.36, y=-0.12, v=5)
    b.ball(0.10, (-0.36, -0.12, 1.95), MUSTARD, 1)
    b.box(0.10, 0.01, 0.22, (-0.36, -0.20, 1.75), MUSTARD)
elif VARIANT == "rusher":    # 돌격병: 쌍단도 · 붉은 띠
    for side, bone in ((1, "arm_L"), (-1, "arm_R")):
        b.bone = bone
        b.box(0.05, 0.04, 0.12, (0.35 * side, -0.14, 0.55), WOOD)     # 자루
        b.box(0.07, 0.025, 0.48, (0.36 * side, -0.24, 0.62), IRON, (R(-60), 0, 0))   # 앞으로 내민 칼날
    b.bone = "torso"
    b.cone(0.30, 0.30, 0.74, 0.80, RED, v=6)                          # 붉은 띠
else:                        # 졸병 · 방패병 · 의용군: 창
    PX, PY = -0.36, -0.12
    top = 1.60 if VARIANT == "shield" else 1.95                       # 방패병은 짧은 창
    b.cone(0.025, 0.025, 0.0, top, WOOD, x=PX, y=PY, v=5)                # 나무 자루
    for z in (0.08, top - 0.17):
        b.cone(0.035, 0.035, z, z + 0.08, MUSTARD, x=PX, y=PY, v=5)       # 감은 끈
    b.poly([(PX, top - 0.01), (PX + 0.07, top + 0.13), (PX, top + 0.41), (PX - 0.07, top + 0.13)], PY, 0.03, IRON)  # 녹슨 창날(잎 모양)
    if VARIANT == "shield":  # 방패병: 왼팔에 큰 둥근 방패
        b.bone = "arm_L"
        b.cone(0.34, 0.34, -0.03, 0.03, DKBRN, x=0.30, y=-0.30, v=10, rot=(R(90), 0, 0)).location.z = 0.80
        b.cone(0.10, 0.06, -0.06, 0.06, MUSTARD, x=0.30, y=-0.34, v=8, rot=(R(90), 0, 0)).location.z = 0.80   # 방패 가운데 징

if ELITE:
    b.bone = "torso"
    if VARIANT == "daoshi":
        b.cone(0.36, 0.28, 0.08, 0.66, CAPE, v=8)                     # 긴 도포
    else:
        b.box(0.44, 0.06, 0.34, (0, -0.28, 0.84), BRONZE)             # 가슴 갑옷
        for side in (-1, 1):
            b.box(0.18, 0.24, 0.08, (0.32 * side, 0, 0.98), BRONZE, (0, R(-20 * side), 0))   # 어깨 갑옷
    b.box(0.46, 0.04, 0.80, (0, 0.27, 0.58), CAPE, (R(8), 0, 0))       # 망토

b.bone = "head"
b.ball(0.31, (0, 0, 1.22), SKIN, 2, (1.0, 0.95, 1.02))
b.box(0.06, 0.07, 0.11, (-0.31, 0.02, 1.20), SKIN)                    # 귀
b.box(0.06, 0.07, 0.11, ( 0.31, 0.02, 1.20), SKIN)
for side in (-1, 1):
    b.box(0.07, 0.03, 0.07, (0.11 * side, -0.29, 1.25), HAIR)         # 눈
    b.box(0.15, 0.04, 0.05, (0.12 * side, -0.29, 1.34), HAIR, (0, R(-22 * side), 0))  # 성난 눈썹
    for zc in (1.30, 1.18):                                           # 두건 밖으로 뻗친 머리
        sp = b.cone(0.06, 0.0, 0.0, 0.16, HAIR, x=0.32 * side, y=0.06, v=4, rot=(0, R(70 * side), 0))
        sp.location.z = zc
b.box(0.06, 0.06, 0.07, (0, -0.31, 1.19), SKIN)                       # 코
b.ball(0.22, (0, -0.20, 1.04), HAIR, 1, (1.15, 0.6, 0.85))            # 덥수룩한 짧은 수염
b.box(0.07, 0.12, 0.20, (-0.26, -0.09, 1.10), HAIR)
b.box(0.07, 0.12, 0.20, ( 0.26, -0.09, 1.10), HAIR)
b.box(0.30, 0.07, 0.06, (0, -0.30, 1.12), HAIR)                       # 콧수염
b.box(0.50, 0.20, 0.26, (0, 0.17, 1.12), HAIR)                        # 뒷머리
b.ball(0.32, (0, 0.02, 1.38), MUSTARD, 1, (1.03, 1.03, 0.62))         # 겨자색 두건
b.cone(0.325, 0.325, 1.32, 1.40, MUSTARD, v=8)
b.box(0.14, 0.10, 0.11, (0, 0.33, 1.34), MUSTARD)                     # 뒤 매듭
b.box(0.10, 0.03, 0.42, (-0.07, 0.38, 1.10), MUSTARD, (R(12), R(-8), 0))  # 늘어진 끈
b.box(0.10, 0.03, 0.36, ( 0.07, 0.38, 1.13), MUSTARD, (R(12), R(10), 0))

mesh = b.join("yellow_turban")
rig = lp.make_rig("yellow_turban", mesh, [
    ("root",  (0, 0, 0),           (0, 0, 0.3),           None),
    ("torso", (0, 0, 0.62),        (0, 0, 1.0),           "root"),
    ("head",  (0, 0, 1.0),         (0, 0, 1.55),          "torso"),
    ("leg_L", ( 0.13, 0, 0.50),    ( 0.13, 0, 0.0),       "root"),
    ("leg_R", (-0.13, 0, 0.50),    (-0.13, 0, 0.0),       "root"),
    ("arm_L", ( 0.30, 0, 0.96),    ( 0.34, 0, 0.56),      "torso"),
    ("arm_R", (-0.30, 0, 0.96),    (-0.34, -0.11, 0.57),  "torso"),
])

def walk(f):   # 0 ~ 12 (0.5초 주기 — 앞으로 숙이고 종종걸음, 창 든 팔은 조금만)
    s = math.sin(f / 12 * 2 * math.pi)
    rot = {
        "leg_L": (-38 * s, 0, 0), "leg_R": (38 * s, 0, 0),
        "arm_L": (-22 * s, 0, 0), "arm_R": (6 * s, 0, 0),
        "torso": (-9, 0, 6 * s),
        "head":  (5, 0, -5 * s),
    }
    return rot, {"root": (0, 0.045 * abs(s), 0)}

walk_act = lp.make_action(rig, "walk", list(range(0, 13, 2)), walk)
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
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 3.0
    for name, p in (("front", (0, -8, 1.15)), ("side", (-8, 0, 1.15)), ("back", (0, 8, 1.15))):
        cam.location = p
        cam.rotation_euler = (Vector((0, 0, 1.15)) - Vector(p)).to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(OUT, f"yt_{name}.png")
        bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(sun); bpy.data.objects.remove(cam)

poses = lp.bake_poses(rig, mesh, walk_act, [0, 3, 6, 9])
lp.export(os.path.join(OUT, NAME + ".glb"), [rig, mesh], animated=True)
lp.export(os.path.join(OUT, NAME + "_poses.glb"), poses, animated=False)
print("DONE")
