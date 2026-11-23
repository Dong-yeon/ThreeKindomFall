# 황건적 졸병 저폴리 모델 + 뼈대 + 동작(walk) — 블렌더 코드로만(D-275).
# 실행: python godot3d/tools/blender/yellow_turban.py <출력 폴더> [--render]   (pip install bpy)
#       blender -b -P godot3d/tools/blender/yellow_turban.py -- <출력 폴더> [--render]
# 결과: yellow_turban.glb(뼈대 · walk 동작 — 가까이 볼 때)
#       yellow_turban_poses.glb(walk 4프레임을 굳힌 정지 메시 pose_0~3 — 적 떼 MultiMesh용)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()

SKIN   = lp.mat("skin",   "d8a070")
YELLOW = lp.mat("yellow", "e8c020")       # 누런 두건 · 띠
TAN    = lp.mat("tan",    "a88a60")       # 삼베옷
DKTAN  = lp.mat("dktan",  "6e5a40")
BLACK  = lp.mat("black",  "1a1614")
WOOD   = lp.mat("wood",   "7a5a34")
STEEL  = lp.mat("steel",  "b8c0c8", 0.4, 0.8)

b = lp.Body()
# 앞쪽 = -Y, 발밑 z=0, 키 약 1.75(관우보다 작게 · 2.3등신). 삼각형을 아껴 적 떼에 맞춤(작은 구 · 6각 기둥).
b.bone = "leg_L"; b.box(0.12, 0.14, 0.26, (-0.11, 0, 0.13), DKTAN)
b.bone = "leg_R"; b.box(0.12, 0.14, 0.26, ( 0.11, 0, 0.13), DKTAN)

b.bone = "torso"
b.cone(0.34, 0.25, 0.22, 0.56, TAN, v=6)          # 옷 아랫단
b.cone(0.25, 0.22, 0.52, 0.96, TAN, v=6)          # 몸통
b.cone(0.265, 0.265, 0.52, 0.60, YELLOW, v=6)     # 누런 허리띠
b.box(0.36, 0.05, 0.05, (0, -0.21, 0.82), DKTAN, (0, math.radians(35), 0))  # 어깨에 멘 끈

b.bone = "arm_L"   # 왼팔은 창 자루를 앞에서 받침
b.cone(0.07, 0.085, 0.60, 0.92, TAN, x=-0.31, v=6, rot=(math.radians(-35), 0, 0))
b.ball(0.065, (-0.31, -0.13, 0.62), SKIN, 1)

b.bone = "arm_R"   # 오른팔 + 죽창(대나무 자루 + 쇠 끝)
b.cone(0.07, 0.085, 0.62, 0.92, TAN, x=0.31, v=6, rot=(math.radians(-20), 0, 0))
b.ball(0.065, (0.32, -0.08, 0.64), SKIN, 1)
# 창은 앞(-Y)으로 30° 기울여 듦: 자루 가운데 (0.33, -0.05, 0.775), 축 = (0, -sin30, cos30)
b.cone(0.025, 0.025, 0.0, 1.55, WOOD, x=0.33, y=-0.05, v=5, rot=(math.radians(30), 0, 0))
b.cone(0.05, 0.0, 1.43, 1.68, STEEL, x=0.33, y=-0.50, v=4, rot=(math.radians(30), 0, 0))  # 쇠 끝(자루 끝 + 축 방향)

b.bone = "head"
b.ball(0.35, (0, 0, 1.28), SKIN, 1, (1, 0.95, 1.05))  # 깎은 구(20면) — 거친 느낌
b.ball(0.30, (0, 0.04, 1.42), BLACK, 1, (1.05, 1.0, 0.7))  # 머리털(정수리)
b.cone(0.365, 0.365, 1.36, 1.48, YELLOW, v=8)     # 누런 두건(이마 띠)
b.box(0.06, 0.04, 0.26, (-0.06, 0.38, 1.30), YELLOW, (math.radians(-25), 0, math.radians(10)))  # 뒤로 늘어진 매듭
b.box(0.06, 0.04, 0.22, ( 0.06, 0.38, 1.31), YELLOW, (math.radians(-25), 0, math.radians(-10)))
b.box(0.06, 0.03, 0.05, (-0.12, -0.33, 1.26), BLACK)   # 눈
b.box(0.06, 0.03, 0.05, ( 0.12, -0.33, 1.26), BLACK)
b.box(0.11, 0.04, 0.035, (-0.12, -0.33, 1.33), BLACK, (0, math.radians(20), 0))   # 성난 눈썹(안쪽이 내려감)
b.box(0.11, 0.04, 0.035, ( 0.12, -0.33, 1.33), BLACK, (0, math.radians(-20), 0))

mesh = b.join("yellow_turban")
rig = lp.make_rig("yellow_turban", mesh, [
    ("root",  (0, 0, 0),         (0, 0, 0.3),        None),
    ("torso", (0, 0, 0.52),      (0, 0, 1.0),        "root"),
    ("head",  (0, 0, 1.0),       (0, 0, 1.6),        "torso"),
    ("leg_L", (-0.11, 0, 0.36),  (-0.11, 0, 0.0),    "root"),
    ("leg_R", ( 0.11, 0, 0.36),  ( 0.11, 0, 0.0),    "root"),
    ("arm_L", (-0.31, 0, 0.92),  (-0.31, -0.13, 0.62), "torso"),
    ("arm_R", ( 0.31, 0, 0.92),  ( 0.32, -0.08, 0.64), "torso"),
])

def walk(f):   # 0 ~ 12 (0.5초 주기 — 관우보다 종종걸음)
    s = math.sin(f / 12 * 2 * math.pi)
    rot = {
        "leg_L": (-40 * s, 0, 0), "leg_R": (40 * s, 0, 0),
        "arm_L": (8 * s, 0, 0),   "arm_R": (-8 * s, 0, 0),   # 창을 든 채라 팔은 조금만
        "torso": (-10, 0, 6 * s),                             # 앞으로 숙이고 달려듦
        "head":  (6, 0, -5 * s),
    }
    return rot, {"root": (0, 0.05 * abs(s), 0)}

walk_act = lp.make_action(rig, "walk", list(range(0, 13, 2)), walk)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_check(OUT, "yt_walk", rig, walk_act, [0, 3, 6, 9], target_z=0.85, scale=2.8)

poses = lp.bake_poses(rig, mesh, walk_act, [0, 3, 6, 9])
lp.export(os.path.join(OUT, "yellow_turban.glb"), [rig, mesh], animated=True)
lp.export(os.path.join(OUT, "yellow_turban_poses.glb"), poses, animated=False)
print("DONE")
