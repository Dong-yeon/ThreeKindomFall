# 황건적 병사 저폴리 모델 + 뼈대 + 동작(walk) — 블렌더 코드로만.
# D-275 첫 시안 → D-280: GPT 콘셉트 설정화(godot3d/art/concept/yellow_turban.webp)를 보고 다시 만듦:
#   탁한 겨자색 두건(뒤 매듭 + 늘어진 끈) · 뻗친 검은 머리 · 그을린 피부 · 성난 눈썹 · 덥수룩한 짧은 수염 ·
#   해진 갈색 옷(짙은 조끼 + 밝은 속옷) · 찢어진 반소매 · 겨자색 허리띠(앞 매듭 + 긴 끝) · 손목 감개 ·
#   통바지 + 다리 감개 · 짚신 · 끈 감은 나무 자루에 녹슨 쇠 창날, 오른손.
# 적 떼(MultiMesh)용이라 삼각형을 아낌(작은 구 · 6각 기둥).
# 실행: python godot3d/tools/blender/yellow_turban.py <출력 폴더> [--render]   (pip install bpy)
# 돌격병 무기는 D-326부터 녹슨 도끼(쌍단도 → 도끼 하나).
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
    if VARIANT == "rusher":
        b.cone(0.10, 0.10, 0.04, 0.22, lp.mat("wrap", "8a7c68"), x=x, v=8)   # 다리 감개(돌격병)

if VARIANT == "rusher":
    # 돌격병(D-324 설정화 yt_rusher.webp): 우람한 몸 · 앞이 열린 민소매 가죽 조끼 · 가슴에 엇갈린 노란 띠 · 회갈색 허리 천 · 굵은 맨팔
    VEST = lp.mat("vest", "6e4632")
    SASH = lp.mat("sash", "8a7c68")
    b.bone = "torso"
    b.cone(0.32, 0.30, 0.40, 0.60, ROBE, v=8)                             # 헐렁한 바지 윗부분
    b.cone(0.33, 0.33, 0.56, 0.66, SASH, v=10)                            # 허리 천
    b.cone(0.33, 0.31, 0.60, 1.0, SKIN, v=10)                             # 드러난 가슴 · 배(우람하게)
    for side in (-1, 1):                                                  # 앞이 열린 가죽 조끼(양쪽 판 + 등)
        b.box(0.22, 0.06, 0.42, (0.20 * side, -0.27, 0.80), VEST, (0, R(18 * side), 0))
        b.box(0.10, 0.30, 0.42, (0.30 * side, 0.0, 0.80), VEST)
    b.box(0.56, 0.06, 0.42, (0, 0.29, 0.80), VEST)
    for side in (-1, 1):                                                  # 엇갈린 노란 띠(X)
        b.box(0.06, 0.03, 0.62, (0.0, -0.33, 0.80), MUSTARD, (0, R(38 * side), 0))
    for side, bone in ((1, "arm_L"), (-1, "arm_R")):
        b.bone = bone
        x = 0.36 * side
        b.cone(0.11, 0.15, 0.56, 0.98, SKIN, x=x, v=8)                    # 굵은 맨팔(길게)
else:
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
    # 막대 활(D-327 설정화 yt_archer_bow.webp): 굽은 나뭇가지 · 노란 천 손잡이 · 새끼줄 시위 · 양 끝 매듭
    BOWW = lp.mat("bow", "6a4434")
    pts = [(0.37, 0.30), (0.46, 0.44), (0.50, 0.62), (0.50, 0.80), (0.46, 0.98), (0.37, 1.12)]
    for (x0, z0), (x1, z1) in zip(pts, pts[1:]):
        seg = math.hypot(x1 - x0, z1 - z0)
        b.box(0.045, 0.045, seg + 0.03, ((x0 + x1) / 2, -0.10, (z0 + z1) / 2), BOWW, (0, math.atan2(x1 - x0, z1 - z0), 0))
    b.cone(0.05, 0.05, 0.62, 0.80, MUSTARD, x=0.50, y=-0.10, v=6)     # 노란 천 손잡이
    b.box(0.012, 0.012, 0.82, (0.37, -0.10, 0.71), ROPE)              # 새끼줄 시위
    for z in (0.30, 1.12):
        b.ball(0.035, (0.37, -0.10, z), ROPE, 1)                      # 시위 매듭
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
elif VARIANT == "rusher":    # 돌격병: 녹슨 도끼(D-326 무기 설정화 yt_rusher_axe.webp) — 오른손에 하나
    b.bone = "arm_R"
    AX = -0.40
    RUST = lp.mat("rust", "5a3a30", 0.7, 0.3)
    EDGE = lp.mat("edge", "c8ccd0", 0.3, 0.9)
    HAND = lp.mat("haft", "5a3e2e")
    b.cone(0.04, 0.035, 0.40, 1.22, HAND, x=AX, y=-0.12, v=6)        # 나무 자루(위로 세움)
    for z in (0.50, 1.02):
        b.cone(0.05, 0.05, z, z + 0.06, ROPE, x=AX, y=-0.12, v=6)     # 감은 끈
    b.poly([(AX + 0.035, 0.46), (AX + 0.14, 0.42), (AX + 0.12, 0.34)], -0.12, 0.02, MUSTARD)   # 자루 끝 노란 천
    b.poly([(AX - 0.04, 1.02), (AX - 0.04, 1.24), (AX - 0.20, 1.20), (AX - 0.36, 1.34), (AX - 0.38, 0.96), (AX - 0.22, 1.04)], -0.12, 0.06, RUST)   # 녹슨 도끼날(바깥으로 퍼짐)
    b.poly([(AX - 0.33, 1.32), (AX - 0.40, 1.36), (AX - 0.42, 0.94), (AX - 0.35, 0.98)], -0.12, 0.065, EDGE)   # 은빛 날

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
    if VARIANT == "shield":  # 방패병(D-325 설정화 yt_shield.webp): 옷 위 가죽 비늘 갑옷(조각 판을 겹겹이)
        b.bone = "torso"
        PLATE = lp.mat("plate", "9a6440")
        DPLATE = lp.mat("dplate", "7a4c30")
        for row, z in enumerate((0.92, 0.82, 0.72, 0.62, 0.52)):
            n = 12
            r = 0.30 + 0.012 * row
            for k in range(n):
                a = 2 * math.pi * (k + 0.5 * (row % 2)) / n
                b.box(0.15, 0.03, 0.11, (math.sin(a) * r, -math.cos(a) * r, z), PLATE if (k + row) % 2 else DPLATE, (R(-6), 0, -a))
        for side in (-1, 1):
            b.box(0.10, 0.20, 0.06, (0.22 * side, 0.0, 1.00), PLATE)  # 어깨 끈 판
    if VARIANT == "shield":  # 방패병: 왼팔에 큰 둥근 방패(설정화엔 없지만 판에서 막는 적이라 그대로)
        b.bone = "arm_L"   # 나무 판 방패(D-327 설정화 yt_shield_shield.webp): 세로 판 셋 · 가로 대 둘 · 새끼줄 테 · 가운데 노란 원
        SX, SY, SZ = 0.32, -0.32, 0.78
        PLANK = lp.mat("plank", "8a6448")
        for k, dx in enumerate((-0.12, 0.0, 0.12)):
            b.box(0.115, 0.05, 1.06 if k == 1 else 0.96, (SX + dx, SY, SZ), PLANK)   # 세로 판(큰 머리 변환에서 몸통 높이가 0.75배라 길게)        # 세로 판(가운데가 길어 둥근 끝 흉내)
        for dz in (-0.32, 0.32):
            b.box(0.40, 0.03, 0.07, (SX, SY - 0.04, SZ + dz), PLANK)     # 가로 대
            for side in (-1, 1):
                b.box(0.04, 0.08, 0.10, (SX + 0.20 * side, SY - 0.02, SZ + dz), ROPE)   # 대를 묶은 줄
        for side in (-1, 1):
            b.box(0.03, 0.07, 0.96, (SX + 0.19 * side, SY, SZ), ROPE)     # 새끼줄 테(옆)
            b.box(0.30, 0.07, 0.03, (SX, SY, SZ + 0.52 * side), ROPE)     # 새끼줄 테(위아래)
        b.cone(0.12, 0.12, -0.02, 0.02, MUSTARD, x=SX, y=SY - 0.05, v=12, rot=(R(90), 0, 0)).location.z = SZ   # 가운데 노란 원

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
    if VARIANT not in ("archer", "shield"):
        b.box(0.07, 0.10, 0.20, (0.27 * side, -0.06, 1.12), HAIR)     # 구레나룻
    if VARIANT != "rusher":
        b.box(0.06, 0.12, 0.18, (0.28 * side, 0.10, 1.18), HAIR)      # 두건 밖 옆머리
b.box(0.06, 0.06, 0.07, (0, -0.30, 1.19), SKIN)                       # 코
if VARIANT == "shield":   # 방패병(D-325): 수염 없이 콧수염 · 악문 이
    b.box(0.24, 0.05, 0.04, (0, -0.295, 1.14), HAIR, (0, 0, 0))
    b.box(0.16, 0.03, 0.05, (0, -0.30, 1.08), lp.mat("teeth", "f2efe8"))
    for side in (-1, 1):
        b.box(0.07, 0.02, 0.05, (0.19 * side, -0.27, 1.17), lp.mat("blush", "e09a8a"))
elif VARIANT == "archer":   # 궁병(D-323 설정화): 수염 없는 젊은 얼굴 · 한쪽 눈 찡긋 · 씩 웃는 입 · 볼 홍조
    b.box(0.12, 0.02, 0.02, (0.03, -0.305, 1.10), lp.mat("mouth", "8a3a30"), (0, 0, R(-10)))
    for side in (-1, 1):
        b.box(0.07, 0.02, 0.05, (0.19 * side, -0.27, 1.17), lp.mat("blush", "e09a8a"))
else:
    b.ball(0.24, (0, -0.14, 1.04), HAIR, 2, (1.15, 0.6, 0.85))        # 덥수룩한 수염(턱 · 볼 아래)
    b.box(0.26, 0.06, 0.05, (0, -0.29, 1.13), HAIR, (0, 0, 0))        # 콧수염
    if VARIANT == "rusher":
        b.box(0.12, 0.03, 0.07, (0, -0.30, 1.09), lp.mat("mouth", "7a2a28"))   # 고함치는 벌린 입
    else:
        b.box(0.10, 0.02, 0.02, (0, -0.305, 1.09), lp.mat("mouth", "8a3a30"), (0, 0, 0))   # 시무룩한 입(ㅅ 흉내)
if VARIANT != "rusher":
    b.box(0.50, 0.20, 0.26, (0, 0.17, 1.12), HAIR)                    # 뒷머리(돌격병은 빡빡 깎은 머리)
b.cone(0.325, 0.32, 1.30, 1.42, MUSTARD, v=10)                        # 노란 두건: 이마 띠
if VARIANT != "shield":
    b.ball(0.31, (0, 0.03, 1.42), MUSTARD, 2, (1.0, 1.0, 0.6))        # 아래 봉긋(방패병은 삿갓 아래 노란 띠만)
if VARIANT not in ("rusher", "shield"):
    b.ball(0.23, (0, 0.07, 1.58), MUSTARD, 2, (1.0, 1.0, 0.7))        # 위 봉긋(두 겹 — 돌격병은 납작한 한 겹)
b.box(0.14, 0.10, 0.11, (0, 0.33, 1.34), MUSTARD)                     # 뒤 매듭
b.box(0.10, 0.03, 0.42, (-0.07, 0.38, 1.10), MUSTARD, (R(12), R(-8), 0))  # 늘어진 끈
b.box(0.10, 0.03, 0.36, ( 0.07, 0.38, 1.13), MUSTARD, (R(12), R(10), 0))
if CHIBI and VARIANT in ("archer", "rusher", "shield"):   # D-303: 위에서 보이는 두건 꼭대기에 종류 표시(머리가 커져 몸 · 무기가 가려짐)
    if VARIANT == "archer":    # D-323: 설정화엔 두건 표시가 없음 — 위에서는 머리 뒤로 솟은 화살 깃 · 수염 없는 얼굴로 구분
        pass
    elif VARIANT == "rusher":  # D-324: 설정화엔 표시가 없음 — 위에서는 납작한 두건 · 우람한 맨팔 · 엇갈린 노란 띠로 구분
        pass
    else:                      # 방패병(D-325): 두건 대신 넓은 챙의 뾰족한 가죽 삿갓 + 꼭대기 노란 술(위에서 원뿔로 구분)
        HAT = lp.mat("hat", "8a5a38")
        b.cone(0.42, 0.41, 1.36, 1.40, HAT, v=12)                    # 챙
        b.cone(0.34, 0.02, 1.38, 1.86, HAT, v=8)                     # 뾰족한 갓
        b.ball(0.04, (0, 0, 1.88), MUSTARD, 1)                       # 꼭대기 꼭지
        b.box(0.05, 0.03, 0.22, (0, 0.08, 1.72), MUSTARD, (R(-40), 0, 0))   # 뒤로 늘어진 노란 술

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
