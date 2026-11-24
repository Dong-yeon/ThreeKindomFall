# 황건 잡병 넷(병사 · 궁병 · 돌격병 · 방패병) — 캐릭터 모델 공통 규칙(docs/art/character-model-rules.md, D-345)대로.
# 정예 셋(장보 · 장량 · 장각)은 그대로 yellow_turban.py. 이 스크립트가 잡병 glb를 같은 이름으로 덮어씀:
#   yellow_turban(_poses).glb · yt_archer(_poses).glb · yt_rusher(_poses).glb · yt_shield(_poses).glb
# 좌표는 관우(--cute)와 같은 틀(얼굴 공 r 0.34 · 가운데 z 1.27 · 눈 줄 1.29)로 만든 뒤
#   cute.reshape(머리 1.2배 · 어깨에 묻힘 · 몸통 폭 1.25배) → 전체 GRUNT_K배(장수보다 작게).
# 설정화: art/concept/yellow_turban_v2 · yt_archer · yt_rusher · yt_shield(.webp), 무기 yellow_turban_spear · yt_archer_bow ·
#   yt_rusher_axe · yt_shield_shield. 얼굴 데칼 · 베옷 텍스처는 tools/face_decal_yt.py가 만듦.
# 실행: python godot3d/tools/blender/yt_grunt.py <출력 폴더> --kind=soldier|archer|rusher|shield [--render] [--subd=1]
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
KIND = next((f.split("=", 1)[1] for f in FLAGS if f.startswith("--kind=")), "soldier")
SUBD = int(next((f.split("=", 1)[1] for f in FLAGS if f.startswith("--subd=")), "1"))   # 규칙 6: 잡몹 1단계
NAME = {"soldier": "yellow_turban", "archer": "yt_archer", "rusher": "yt_rusher", "shield": "yt_shield"}[KIND]
GRUNT_K = 0.8          # 관우 틀(키 약 2.03) → 잡병 키 약 1.63(예전 잡병 1.64와 같게)
lp.reset_scene()
import bpy
import cute
R = math.radians
TEX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "textures")
DEC = json.load(open(os.path.join(TEX, "face_yt_%s.json" % KIND)))

# ── 색(설정화에서 뽑음 — 문서 색상표와 같게) ──
SKIN    = lp.mat("face",    "e4b294")      # 피부(이름 face — 머리 비율 재는 기준)
HAIR    = lp.mat("hair",    "2e2a28")
BEARD   = lp.mat("beard",   "3e3834")
MUSTARD = lp.mat("mustard", "e2b45f")      # 노란 두건 · 천
ROBE_T  = cute.tex_mat("robe", os.path.join(TEX, "yt_robe.png"))   # 누더기 베옷(덧댄 자국은 텍스처로만)
DKROBE  = lp.mat("dkrobe",  "6a5a4e")      # 여민 깃 · 그늘
ROPE    = lp.mat("rope",    "9a8366")      # 노끈 띠 · 짚신
SANDAL  = lp.mat("sandal",  "b39572")
NOSE_BL = lp.mat("nose",    "e0aa8c")

b = lp.Body()
RUSHER = KIND == "rusher"

# ── 다리: 짚신 · 통바지(돌격병은 정강이 천) ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.14 * side
    b.box(0.18, 0.27, 0.05, (x, -0.03, 0.025), SANDAL)                 # 짚신 바닥
    b.box(0.15, 0.04, 0.04, (x, -0.09, 0.06), ROPE)                    # 짚신 끈
    if RUSHER:
        b.cone(0.135, 0.13, 0.05, 0.22, lp.mat("shin", "776758"), x=x, v=10)          # 정강이 천
        b.cone(0.17, 0.18, 0.20, 0.34, lp.mat("pants", "615246"), x=x, v=10)          # 짧고 통 넓은 바지
    else:
        b.cone(0.12, 0.14, 0.05, 0.30, ROBE_T, x=x, v=10)              # 통바지(텍스처 덧댐)

# ── 몸통 ──
b.bone = "torso"
if RUSHER:   # 돌격병: 옆으로 넓고 둥근 몸 · 앞이 열린 민소매 가죽 조끼 · 가슴 X자 노란 천 · 허리 천
    VEST = lp.mat("vest", "775a4e")
    b.ball(0.36, (0, 0.0, 0.36), lp.mat("pants", "615246"), 2, (1.15, 1.0, 0.55))   # 바지 윗부분(둥글게)
    w = b.cone(0.42, 0.42, 0.40, 0.50, lp.mat("waist", "7d6e5f"), v=12)   # 허리 천
    w["soft_caps"] = True
    b.ball(0.40, (0, 0.0, 0.70), VEST, 2, (1.22, 1.0, 0.95))          # 둥근 몸(조끼)
    b.ball(0.24, (0, -0.25, 0.72), SKIN, 1, (0.75, 0.55, 1.1))         # 조끼 사이로 드러난 가슴
    for side in (-1, 1):
        b.box(0.075, 0.04, 0.66, (0.0, -0.36, 0.73), MUSTARD, (R(-6), R(36 * side), 0))   # 가슴 X자 노란 천
else:
    b.cone(0.38, 0.33, 0.18, 0.56, ROBE_T, v=10)                      # 베옷 아랫자락(살짝 퍼짐)
    for k in range(8):                                                # 해진 자락 끝(삐죽)
        a = R(k * 45 + 10)
        o = b.poly([(-0.06, 0.0), (0.06, 0.0), (0.0, -0.07)], 0.0, 0.02, ROBE_T)
        o.location = (math.sin(a) * 0.375, -math.cos(a) * 0.375, 0.19)
        o.rotation_euler = (0, 0, -a)
    b.cone(0.33, 0.30, 0.56, 0.98, ROBE_T, v=10)                      # 윗몸
    b.box(0.07, 0.025, 0.42, (-0.07, -0.30, 0.80), DKROBE, (R(-6), R(-28), 0))   # 여민 깃(겹친 앞섶)
    b.box(0.07, 0.025, 0.30, (0.08, -0.31, 0.86), DKROBE, (R(-6), R(28), 0))
    b.cone(0.345, 0.345, 0.55, 0.60, ROPE, v=10)                      # 노끈 허리띠
    b.ball(0.05, (0.02, -0.35, 0.575), ROPE, 1)                       # 매듭
    b.box(0.035, 0.035, 0.22, (-0.01, -0.36, 0.46), ROPE, (0, R(8), 0))   # 늘어진 끈
    b.box(0.035, 0.035, 0.18, (0.06, -0.36, 0.48), ROPE, (0, R(-10), 0))

# ── 팔 ──
for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-22 * side), 0)
    if RUSHER:   # 짧고 굵은 원통형 맨팔
        c = b.cone(0.17, 0.16, 0.56, 0.94, SKIN, x=0.46 * side, v=12, rot=rot)
        c["soft_caps"] = True
        b.ball(0.15, (0.60 * side, -0.02, 0.50), SKIN, 1)              # 큰 주먹
    else:
        c = b.cone(0.15, 0.125, 0.76, 0.97, ROBE_T, x=0.44 * side, v=12, rot=rot)   # 해진 반소매
        c["soft_caps"] = True
        b.cone(0.095, 0.10, 0.58, 0.78, SKIN, x=0.52 * side, v=10, rot=rot)        # 맨팔
        b.ball(0.12, (0.59 * side, -0.02, 0.50), SKIN, 1)              # 주먹

# ── 머리 ──
b.bone = "head"
EYE_Z = 1.29
face_ball = b.ball(0.34, (0, 0, 1.27), SKIN, 2, (1.0, 0.95, 0.98))
for side in (-1, 1):
    b.ball(0.075, (0.335 * side, 0.02, 1.27), SKIN, 1, (0.6, 1.0, 1.1))   # 귀
b.box(0.06, 0.05, 0.07, (0, -0.335, 1.21), NOSE_BL)                    # 코
BAND_LO = EYE_Z + DEC["brow_top_from_eye"] + 0.005                     # 두건 아래 가장자리 = 눈썹 바로 위(규칙 3)
MOUTH_Z = EYE_Z - DEC["mouth_from_eye"]
if KIND in ("soldier", "rusher"):   # 덥수룩한 턱수염: 구레나룻(두건 아래)부터 턱까지 한 덩어리(규칙 4) + 작은 콧수염
    cute.beard_shell(b, BEARD, top_c=MOUTH_Z - 0.035, top_s=BAND_LO, bot_c=0.90, bot_s=1.06, thick=0.09, bulge=0.0,
                     chest_r=(0.29, 0.27), grid=(13, 6))
    for side in (-1, 1):
        b.box(0.11, 0.04, 0.035, (0.06 * side, -0.335, MOUTH_Z + 0.04), BEARD, (0, R(14 * side), 0))
else:               # 궁병 · 방패병: 수염 없이 두건 아래 귀 앞 옆머리로 얼굴 윤곽과 이음(규칙 3)
    for side in (-1, 1):
        b.box(0.06, 0.10, 0.20, (0.295 * side, -0.08, BAND_LO - 0.08), HAIR, (0, R(-10 * side), R(-12 * side)))
    if KIND == "shield":   # 방패병: 콧수염(가는 팔자)
        for side in (-1, 1):
            b.box(0.12, 0.035, 0.03, (0.065 * side, -0.335, MOUTH_Z + 0.05), HAIR, (0, R(14 * side), R(-16 * side)))
if not RUSHER:   # 뒷머리(뒤통수를 덮는 공 — 앞은 얼굴 공 안에 묻혀 안 보임) · 귀 뒤 옆머리(짧게, 두건 아래)
    b.ball(0.335, (0, 0.07, 1.25), HAIR, 2, (1.0, 1.0, 1.0))
    for side in (-1, 1):
        b.box(0.06, 0.10, 0.14, (0.31 * side, 0.06, BAND_LO - 0.07), HAIR)
cute.face_decal(b, os.path.join(TEX, "face_yt_%s.png" % KIND), face_ball, DEC["w"], DEC["h"],
                EYE_Z + DEC["eye_from_top"], DEC["cx"], grid=(14, 10), subd=0)

# ── 머리 장식 ──
if KIND == "shield":   # 원뿔형 가죽 투구(챙이 이마를 살짝 파고듦) · 꼭대기 노란 술 · 뒤 노란 끈
    HELM = lp.mat("helmet", "9d765e")
    brim = b.cone(0.40, 0.40, BAND_LO - 0.02, BAND_LO + 0.03, HELM, v=16)   # 챙(머리 폭 + 5% 이내 — 원뿔 투구 챙만 조금 넓음)
    b.cone(0.355, 0.03, BAND_LO + 0.02, BAND_LO + 0.52, HELM, v=10)    # 뾰족한 원뿔
    b.ball(0.045, (0, 0, BAND_LO + 0.55), MUSTARD, 1)                  # 꼭지
    for k, (dx, ry) in enumerate(((-0.03, -8), (0.03, 8))):
        b.box(0.05, 0.035, 0.24, (dx, 0.07, BAND_LO + 0.42), MUSTARD, (R(-38), R(ry), 0))   # 늘어진 노란 술
    b.box(0.14, 0.08, 0.08, (0, 0.33, BAND_LO - 0.03), MUSTARD)        # 뒤 매듭
    for side in (-1, 1):
        b.box(0.06, 0.03, 0.26, (0.04 * side, 0.37, BAND_LO - 0.20), MUSTARD, (R(8), R(10 * side), 0))
else:   # 노란 두건: 머리 전체를 감쌈(띠 위 테 = 둥근 천 — 한 덩어리) · 뒤 매듭 + 끈 둘
    TOPH = 0.10 if RUSHER else 0.145        # 돌격병은 납작한 한 겹(민머리에 동여맨 두건)
    band = b.cone(0.315, 0.355, BAND_LO, BAND_LO + TOPH, MUSTARD, v=10)
    band["soft_top"] = True
    b.ball(0.355, (0, 0.0, BAND_LO + TOPH), MUSTARD, 2, (1.0, 1.0, 0.45 if RUSHER else 0.62))
    if not RUSHER:
        b.ball(0.24, (0, 0.08, BAND_LO + TOPH + 0.13), MUSTARD, 2, (1.0, 1.0, 0.70))   # 위 봉긋(두 겹, 설정화처럼 낮게)
    b.box(0.15, 0.10, 0.10, (0, 0.34, BAND_LO + 0.06), MUSTARD)        # 뒤 매듭
    for side in (-1, 1):
        b.box(0.08, 0.03, 0.34, (0.05 * side, 0.39, BAND_LO - 0.13), MUSTARD, (R(10), R(12 * side), 0))   # 뒤로 늘어진 끈 둘

# ── 무기 · 종류별 덧붙임 ──
if KIND == "soldier":   # 죽창(설정화 yellow_turban_spear — 대나무는 녹색 쪽으로): 마디 · 비스듬히 깎은 끝 · 노끈 + 노란 천
    b.bone = "arm_R"
    PX, PY = -0.60, -0.10
    BAMBOO, BNODE, BTIP = lp.mat("bamboo", "9fae63"), lp.mat("bnode", "84944d"), lp.mat("btip", "b8c07e")
    TOP = 2.25
    b.cone(0.045, 0.045, -0.05, TOP, BAMBOO, x=PX, y=PY, v=8)        # 대나무 자루
    for k in range(1, int(TOP / 0.40)):
        b.cone(0.053, 0.053, k * 0.40, k * 0.40 + 0.035, BNODE, x=PX, y=PY, v=8)   # 마디
    tip = b.poly([(-0.045, 0.0), (0.045, 0.0), (0.045, 0.10), (-0.045, 0.36)], 0.0, 0.08, BTIP)   # 비스듬히 깎은 끝
    tip.location = (PX, PY + 0.04, TOP)
    b.cone(0.058, 0.058, TOP - 0.26, TOP - 0.19, ROPE, x=PX, y=PY, v=8)   # 노끈
    cl = b.poly([(0.0, 0.0), (0.24, -0.02), (0.26, -0.24), (0.14, -0.28), (0.0, -0.26)], 0.0, 0.025, MUSTARD)   # 노란 천(바깥쪽)
    cl.location = (PX - 0.03, PY - 0.03, TOP - 0.21)
    cl.rotation_euler = (0, 0, R(180))

elif KIND == "archer":   # 궁병: 왼 팔뚝 노란 천 · 등에 화살통(화살 깃) + 가슴 멜빵 · 왼손에 막대 활(설정화 yt_archer_bow)
    b.bone = "arm_L"
    b.cone(0.112, 0.112, 0.62, 0.71, MUSTARD, x=0.52, v=10, rot=(0, R(-22), 0))   # 팔뚝 노란 천
    BOWW = lp.mat("bow", "6a4434")
    pts = [(0.60, 0.02), (0.69, 0.20), (0.73, 0.40), (0.73, 0.60), (0.69, 0.80), (0.60, 0.98)]
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        seg = math.hypot(x1 - x0, z1 - z0)
        b.box(0.05, 0.05, seg + 0.03, ((x0 + x1) / 2, -0.06, (z0 + z1) / 2), BOWW, (0, math.atan2(x1 - x0, z1 - z0), 0))
    b.cone(0.055, 0.055, 0.42, 0.58, MUSTARD, x=0.73, y=-0.06, v=8)   # 노란 천 손잡이
    b.box(0.012, 0.012, 0.96, (0.60, -0.06, 0.50), ROPE)             # 시위
    b.bone = "torso"
    QUIV = lp.mat("quiver", "7c6052")
    q = b.cone(0.10, 0.11, -0.30, 0.30, QUIV, v=10, rot=(0, R(35), 0))   # 등에 비스듬히 멘 화살통
    q.location = (0.10, 0.36, 0.82)
    for k, dx in enumerate((-0.05, 0.0, 0.05)):   # 화살(어깨 위로 솟은 흰 깃)
        sh = b.cone(0.014, 0.014, 0.0, 0.34, lp.mat("shaft", "6a4a36"), v=4, rot=(0, R(35), 0))
        sh.location = (-0.07 + dx, 0.36 + dx * 0.5, 1.04)
        b.box(0.08, 0.02, 0.12, (-0.17 + dx, 0.36 + dx * 0.5, 1.22), lp.mat("fletch", "ece6d8"), (0, R(35), 0))
    b.box(0.06, 0.025, 0.80, (0.0, -0.33, 0.78), lp.mat("strap", "735f54"), (R(-6), R(-40), 0))   # 가슴 멜빵
elif KIND == "rusher":   # 돌격병: 나무꾼 도끼(설정화 yt_rusher_axe) — 나무 자루 · 감은 끈 · 녹슨 날 · 은빛 날 · 자루 끝 노란 천
    b.bone = "arm_R"
    AX, AY = -0.62, -0.10
    RUST, EDGE, HAFT = lp.mat("rust", "5a3a30", 0.7, 0.3), lp.mat("edge", "c8ccd0", 0.3, 0.9), lp.mat("haft", "5a3e2e")
    b.cone(0.045, 0.04, 0.30, 1.30, HAFT, x=AX, y=AY, v=8)              # 자루(위로 세움)
    for z in (0.42, 1.06):
        b.cone(0.056, 0.056, z, z + 0.07, ROPE, x=AX, y=AY, v=8)         # 감은 끈
    cl = b.poly([(0.0, 0.0), (0.14, -0.04), (0.12, -0.16), (0.0, -0.12)], 0.0, 0.02, MUSTARD)   # 자루 끝 노란 천
    cl.location = (AX + 0.03, AY - 0.02, 0.40)
    head = b.poly([(0.04, 1.08), (0.04, 1.32), (-0.20, 1.28), (-0.38, 1.44), (-0.40, 1.00), (-0.22, 1.10)], 0.0, 0.07, RUST)   # 녹슨 도끼날
    head.location = (AX, AY, 0)
    edge = b.poly([(-0.34, 1.42), (-0.42, 1.46), (-0.44, 0.98), (-0.37, 1.02)], 0.0, 0.075, EDGE)   # 은빛 날
    edge.location = (AX, AY, 0)
elif KIND == "shield":   # 방패병: 가로로 겹친 가죽 비늘 갑옷 · 왼팔에 나무 판 방패(앞면 절반 크기의 노란 원)
    b.bone = "torso"
    ARM, ARMD = lp.mat("armor", "8c6751"), lp.mat("armord", "74543f")
    for row, z in enumerate((0.88, 0.77, 0.66, 0.55, 0.44)):            # 위 줄이 아래 줄 위로 겹침(가로 줄)
        n = 12
        r = 0.33 + 0.008 * row
        for k in range(n):
            a = 2 * math.pi * (k + 0.5 * (row % 2)) / n
            pl = b.box(0.19, 0.022, 0.135, (math.sin(a) * r, -math.cos(a) * r, z), ARM if (k + row) % 2 else ARMD, (R(-10), 0, -a))
            pl["crease"] = 0.75   # 각진 가죽 조각(서브디비전에 자갈처럼 둥글어지지 않게)
    b.cone(0.40, 0.40, 0.57, 0.62, ROPE, v=10)                          # 갑옷 위 노끈 띠
    b.bone = "arm_L"
    PLANK, SX, SY, SZ = lp.mat("plank", "8a6448"), 0.56, -0.40, 0.62
    W = 0.46
    for k, dx in enumerate((-0.15, 0.0, 0.15)):
        pk = b.box(0.158, 0.05, 0.86 if k == 1 else 0.80, (SX + dx, SY, SZ), PLANK)   # 세로 판 셋(가운데가 길어 둥근 끝 흉내)
        pk["crease"] = 0.7
    for dz in (-0.27, 0.27):
        b.box(W + 0.02, 0.035, 0.07, (SX, SY - 0.04, SZ + dz), PLANK)["crease"] = 0.7    # 가로 대
    for side in (-1, 1):
        b.box(0.035, 0.07, 0.80, (SX + (W / 2 + 0.01) * side, SY, SZ), ROPE)   # 새끼줄 테(옆)
        b.box(W, 0.07, 0.035, (SX, SY, SZ + 0.43 * side), ROPE)                 # (위아래)
    disc = b.cone(W / 4, W / 4, -0.02, 0.02, MUSTARD, v=16, rot=(R(90), 0, 0))   # 노란 원(지름 = 방패 폭의 절반)
    disc.location = (SX, SY - 0.05, SZ)

mesh = None
cute.smooth_all(b, SUBD)
mesh = b.join(NAME)
bpy.ops.object.shade_smooth()
chin, top, ratio, ARM_OUT = cute.reshape(mesh)
HEAD_DOWN = 0.12
cute.scale_mesh(mesh, GRUNT_K)
print("HEAD ratio %.2f (chin %.2f top %.2f) — x%.2f 뒤 키 %.2f" % (ratio, chin, top, GRUNT_K, top * GRUNT_K))

K = GRUNT_K
AO = ARM_OUT
BONES = [
    ("root",  (0, 0, 0),                    (0, 0, 0.3 * K),                 None),
    ("torso", (0, 0, 0.50 * K),             (0, 0, (1.00 - HEAD_DOWN) * K),  "root"),
    ("head",  (0, 0, (1.00 - HEAD_DOWN) * K), (0, 0, (1.60 - HEAD_DOWN) * K), "torso"),
    ("leg_L", ( 0.14 * K, 0, 0.28 * K),     ( 0.14 * K, 0, 0.0),             "root"),
    ("leg_R", (-0.14 * K, 0, 0.28 * K),     (-0.14 * K, 0, 0.0),             "root"),
    ("arm_L", ( (0.32 + AO) * K, 0, 0.94 * K), ( (0.58 + AO) * K, 0, 0.52 * K), "torso"),
    ("arm_R", (-(0.32 + AO) * K, 0, 0.94 * K), (-(0.58 + AO) * K, -0.08 * K, 0.52 * K), "torso"),
]
rig = lp.make_rig(NAME, mesh, BONES)


def walk(f):   # 0 ~ 12 (0.5초 주기 — 앞으로 숙이고 종종걸음, 무기 든 팔은 조금만) — yellow_turban.py와 같음
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
    lp.render_views(OUT, "yt_" + KIND, center_z=0.95, ortho=2.4)
poses = lp.bake_poses(rig, mesh, walk_act, [0, 3, 6, 9])
lp.export(os.path.join(OUT, NAME + ".glb"), [rig, mesh], animated=True)
lp.export(os.path.join(OUT, NAME + "_poses.glb"), poses, animated=False)
print("DONE")
