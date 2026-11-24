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
# D-307부터 큰 머리 비율(lowpoly.Chibi — 다리 끝 0.50 · 목 1.0) + 두건 꼭대기 종류 표시가 기본. --classic이면 예전 비율.
CHIBI = "--classic" not in FLAGS
lp.reset_scene()
R = math.radians

SKIN    = lp.mat("skin",    "c98e68")       # 그을린 피부
HAIR    = lp.mat("hair",    "2a221e")       # 머리 · 수염 · 눈
MUSTARD = lp.mat("mustard", "4f8a3e" if MILITIA else "c49a42")       # 두건 · 띠 — D-321 새 설정화(yellow_turban_v2.webp)의 노란 두건(D-280의 탁한 겨자색보다 밝게, 판 조명에서 형광처럼 뜨지 않게 채도는 낮춤)
ROBE    = lp.mat("robe",    "7a6450")       # 해진 갈색 옷 · 바지(D-321)
PATCH   = lp.mat("patch",   "584636")       # 기운 자국
ROPE    = lp.mat("rope",    "b09a6a")       # 새끼줄 허리띠 · 짚신
DKBRN   = lp.mat("dkbrown", {"archer": "3e4632", "shield": "34302c"}.get(VARIANT, "4e3a2e"))  # 조끼 · 바지 · 감개(궁병 녹갈 · 방패병 짙게)
LTBRN   = lp.mat("ltbrown", "8a6e58")       # 속옷 · 소매
WOOD    = lp.mat("wood",    "5a3e2c")       # 창 자루 · 짚신 끈은 띠 색
IRON    = lp.mat("iron",    "6e5e56", 0.6, 0.4)  # 녹슨 쇠
RED     = lp.mat("red",     "8a2a22")       # 돌격병 붉은 띠
BRONZE  = lp.mat("bronze",  "8a6a3a", 0.5, 0.5)  # 정예 갑옷
CAPE    = lp.mat("cape",    {"zhangbao": "a8342a", "zhangliang": "c9a03a", "daoshi": "e8d8a8"}.get(VARIANT, "c9a03a"))

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 1.75(장수보다 작게). 오른쪽 = -X.

for side, bone in ((-1, "leg_R"), (1, "leg_L")):   # D-321: 짚신 · 기운 갈색 바지
    b.bone = bone
    x = 0.13 * side
    b.box(0.16, 0.26, 0.035, (x, -0.03, 0.018), ROPE)                 # 짚신 바닥
    b.box(0.14, 0.03, 0.03, (x, -0.10, 0.05), ROPE)                   # 짚신 끈
    b.cone(0.11, 0.15, 0.04, 0.52, ROBE, x=x, v=6)                    # 통바지
    b.box(0.08, 0.02, 0.07, (x + 0.03 * side, -0.13, 0.20), PATCH)    # 기운 자국

b.bone = "torso"
b.cone(0.34, 0.27, 0.38, 0.70, ROBE, v=8)                             # 해진 옷 자락(무릎 위)
for k in range(6):                                                    # 해진 자락 끝(삐죽)
    a = R(k * 60 + 15)
    b.box(0.10, 0.04, 0.08, (math.sin(a) * 0.33, -math.cos(a) * 0.33, 0.37), ROBE, (0, 0, -a))
b.cone(0.28, 0.27, 0.64, 1.0, ROBE, v=8)                              # 윗몸
b.box(0.06, 0.03, 0.34, (-0.06, -0.275, 0.84), PATCH, (0, R(-24), R(-20)))   # 여민 깃(겹친 앞섶)
b.box(0.06, 0.03, 0.22, ( 0.08, -0.275, 0.90), PATCH, (0, R(24), R(20)))
for (px, pz, rz) in ((-0.17, 0.86, 15), (0.15, 0.48, -10), (0.20, 0.80, 30)):   # 기운 자국
    b.box(0.09, 0.02, 0.08, (px, -0.285 if pz > 0.6 else -0.31, pz), PATCH, (0, 0, R(rz)))
b.box(0.10, 0.02, 0.09, (-0.10, 0.28, 0.80), PATCH)                   # 등 기운 자국
b.cone(0.29, 0.29, 0.64, 0.69, ROPE, v=10)                            # 새끼줄 허리띠
b.ball(0.05, (0.02, -0.29, 0.665), ROPE, 1)                           # 매듭
b.box(0.03, 0.03, 0.22, (-0.01, -0.30, 0.54), ROPE, (0, R(8), 0))     # 늘어진 줄 끝
b.box(0.03, 0.03, 0.18, ( 0.05, -0.30, 0.56), ROPE, (0, R(-10), 0))

for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    x = 0.32 * side
    b.cone(0.11, 0.12, 0.78, 0.98, ROBE, x=x, v=6)                    # 해진 반소매
    b.box(0.06, 0.04, 0.05, (x * 1.05, -0.06, 0.78), ROBE, (0, 0, R(30 * side)))   # 해진 소매 끝
    b.cone(0.07, 0.08, 0.62, 0.82, SKIN, x=x + 0.01 * side, v=6)      # 맨팔
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
    QUIV = lp.mat("quiver", "6e4a36")
    b.cone(0.10, 0.11, 0.55, 1.00, QUIV, x=-0.16, y=0.32, v=8, rot=(0, R(-45), 0))   # 등에 비스듬히 멘 화살통(D-323 궁병 설정화) — 오른 어깨 바깥으로
    for k, dx in enumerate((-0.05, 0.0, 0.05)):   # 화살: 큰 머리에 안 가리게 어깨 바깥 위로 길게
        b.cone(0.015, 0.015, 0.0, 0.40, WOOD, x=-0.42 + dx, y=0.32 + dx, v=4, rot=(0, R(-45), 0)).location.z = 1.02
        b.box(0.08, 0.02, 0.12, (-0.58 + dx, 0.32 + dx, 1.18), lp.mat("fletch", "e8e2d4"), (0, R(-45), 0))   # 흰 깃
    b.box(0.05, 0.02, 0.78, (0.0, -0.285, 0.82), QUIV, (0, R(42), 0))  # 가슴을 가로지르는 멜빵(오른 어깨 → 왼 허리)
    b.box(0.05, 0.02, 0.60, (0.02, 0.29, 0.86), QUIV, (0, R(-42), 0))  # 등 멜빵
    b.bone = "arm_L"
    b.cone(0.085, 0.085, 0.66, 0.74, MUSTARD, x=0.33, v=8)            # 노란 손목 감개
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
    # 대나무 죽창(D-322, 무기 설정화 yellow_turban_spear.webp): 마디 있는 대나무 자루 · 비스듬히 깎은 끝 · 새끼줄로 묶은 노란 천
    PX, PY = -0.36, -0.12
    BAMBOO = lp.mat("bamboo", "c8b878")
    BNODE = lp.mat("bnode", "a89a5a")
    top = 1.60 if VARIANT == "shield" else 1.95                       # 방패병은 짧은 창
    b.cone(0.035, 0.035, 0.0, top, BAMBOO, x=PX, y=PY, v=6)           # 대나무 자루(굵게)
    for k in range(1, int(top / 0.34) + 1):
        b.cone(0.043, 0.043, k * 0.34, k * 0.34 + 0.03, BNODE, x=PX, y=PY, v=6)   # 마디
    b.poly([(PX - 0.035, top), (PX + 0.035, top), (PX + 0.035, top + 0.12), (PX - 0.035, top + 0.42)], PY, 0.07, BAMBOO)   # 비스듬히 깎은 끝
    b.cone(0.045, 0.045, top - 0.20, top - 0.14, ROPE, x=PX, y=PY, v=6)   # 새끼줄
    b.poly([(PX - 0.03, top - 0.16), (PX - 0.24, top - 0.18), (PX - 0.26, top - 0.40), (PX - 0.15, top - 0.44), (PX - 0.03, top - 0.42)], PY - 0.02, 0.025, MUSTARD)   # 노란 천(바깥쪽 — 몸에 안 가리게)
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

b.bone = "head"   # D-321: 시무룩한 얼굴 · 덥수룩한 수염 · 노란 두 겹 두건
b.ball(0.31, (0, 0, 1.22), SKIN, 2, (1.0, 0.95, 1.02))
for side in (-1, 1):
    b.ball(0.06, (0.31 * side, 0.02, 1.21), SKIN, 1, (0.6, 1.0, 1.1))   # 귀
    if VARIANT == "archer" and side == 1:
        b.box(0.08, 0.02, 0.02, (0.11, -0.29, 1.25), HAIR, (0, 0, R(-15)))   # 찡긋 감은 눈(궁병)
    else:
        b.ball(0.035, (0.11 * side, -0.28, 1.25), HAIR, 1)            # 까만 눈
    b.box(0.15, 0.05, 0.05, (0.12 * side, -0.28, 1.34), HAIR, (0, R(-24 * side), 0))  # 성난 굵은 눈썹
    if VARIANT != "archer":
        b.box(0.07, 0.10, 0.20, (0.27 * side, -0.06, 1.12), HAIR)     # 구레나룻
    b.box(0.06, 0.12, 0.18, (0.28 * side, 0.10, 1.18), HAIR)          # 두건 밖 옆머리
b.box(0.06, 0.06, 0.07, (0, -0.30, 1.19), SKIN)                       # 코
if VARIANT == "archer":   # 궁병(D-323 설정화): 수염 없는 젊은 얼굴 · 한쪽 눈 찡긋 · 씩 웃는 입 · 볼 홍조
    b.box(0.12, 0.02, 0.02, (0.03, -0.305, 1.10), lp.mat("mouth", "8a3a30"), (0, 0, R(-10)))
    for side in (-1, 1):
        b.box(0.07, 0.02, 0.05, (0.19 * side, -0.27, 1.17), lp.mat("blush", "e09a8a"))
else:
    b.ball(0.24, (0, -0.14, 1.04), HAIR, 2, (1.15, 0.6, 0.85))        # 덥수룩한 수염(턱 · 볼 아래)
    b.box(0.26, 0.06, 0.05, (0, -0.29, 1.13), HAIR, (0, 0, 0))        # 콧수염
    b.box(0.10, 0.02, 0.02, (0, -0.305, 1.09), lp.mat("mouth", "8a3a30"), (0, 0, 0))   # 시무룩한 입(ㅅ 흉내)
b.box(0.50, 0.20, 0.26, (0, 0.17, 1.12), HAIR)                        # 뒷머리
b.cone(0.325, 0.32, 1.30, 1.42, MUSTARD, v=10)                        # 노란 두건: 이마 띠
b.ball(0.31, (0, 0.03, 1.42), MUSTARD, 2, (1.0, 1.0, 0.6))            # 아래 봉긋
b.ball(0.23, (0, 0.07, 1.58), MUSTARD, 2, (1.0, 1.0, 0.7))            # 위 봉긋(두 겹)
b.box(0.14, 0.10, 0.11, (0, 0.33, 1.34), MUSTARD)                     # 뒤 매듭
b.box(0.10, 0.03, 0.42, (-0.07, 0.38, 1.10), MUSTARD, (R(12), R(-8), 0))  # 늘어진 끈
b.box(0.10, 0.03, 0.36, ( 0.07, 0.38, 1.13), MUSTARD, (R(12), R(10), 0))
if CHIBI and VARIANT in ("archer", "rusher", "shield"):   # D-303: 위에서 보이는 두건 꼭대기에 종류 표시(머리가 커져 몸 · 무기가 가려짐)
    if VARIANT == "archer":    # D-323: 설정화엔 두건 표시가 없음 — 위에서는 머리 뒤로 솟은 화살 깃 · 수염 없는 얼굴로 구분
        pass
    elif VARIANT == "rusher":  # 붉은 머리띠 + 꼭대기 붉은 술
        b.cone(0.33, 0.33, 1.34, 1.42, RED, v=8)
        b.cone(0.07, 0.0, 1.55, 1.72, RED, v=5)
    else:                      # 방패병: 녹슨 쇠 투구 테 + 정수리 쇠판
        b.cone(0.34, 0.34, 1.30, 1.42, IRON, v=8)
        b.box(0.30, 0.30, 0.06, (0, 0.02, 1.58), IRON)

mesh = b.join("yellow_turban")
CH = lp.Chibi(leg_top=0.50, neck=1.0, weapon=1.2 if ELITE else 0.9) if CHIBI else None   # 정예 무기는 크게(D-307)
if CH:
    CH.apply_mesh(mesh)
BONES = [
    ("root",  (0, 0, 0),           (0, 0, 0.3),           None),
    ("torso", (0, 0, 0.62),        (0, 0, 1.0),           "root"),
    ("head",  (0, 0, 1.0),         (0, 0, 1.55),          "torso"),
    ("leg_L", ( 0.13, 0, 0.50),    ( 0.13, 0, 0.0),       "root"),
    ("leg_R", (-0.13, 0, 0.50),    (-0.13, 0, 0.0),       "root"),
    ("arm_L", ( 0.30, 0, 0.96),    ( 0.34, 0, 0.56),      "torso"),
    ("arm_R", (-0.30, 0, 0.96),    (-0.34, -0.11, 0.57),  "torso"),
]
rig = lp.make_rig("yellow_turban", mesh, CH.bones(BONES) if CH else BONES)

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
