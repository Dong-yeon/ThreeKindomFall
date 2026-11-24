# 청룡(관우 절기 청룡강림 · 오의 청룡파천의 용) — 블렌더 코드로만(D-335, 설정화 godot3d/art/concept/qinglong_head.webp · qinglong_side.webp · qinglong_skill.webp).
# 뼈대 없이 조각 다섯을 따로 내보냄 — 게임(scripts/martial/dragon_body.gd)이 머리가 지나온 길을 따라 마디를 늘어놓음:
#   head 머리(위턱 · 눈 · 눈썹 · 귀 · 금 뿔 · 금 갈기 · 금 수염) / jaw 아래턱(포효 때 벌림 — 원점이 턱 뒤 경첩)
#   seg 몸 마디 하나(청록 몸통 · 연한 배 판 · 금 등지느러미 — 길이 0.6 · 반지름 0.5, 게임에서 크기를 줄여 가며 씀)
#   tail 꼬리 끝(가늘어지는 몸 + 금 불꽃 털) / leg 앞다리 하나(앞다리 둘만 — 게임에서 좌우로 뒤집어 붙임)
# 방향: 블렌더 +Y가 앞(glTF → Godot −Z, look_at 기준), +Z가 위. 크기는 머리 폭 약 1.1 기준(게임에서 배율).
# 실행: python godot3d/tools/blender/qinglong.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians
TEAL  = lp.mat("teal",  "4c9a80", 0.75)   # 몸(설정화의 옥빛 청록)
BELLY = lp.mat("belly", "e6edd0", 0.8)    # 배 판(연한 미색)
GOLD  = lp.mat("gold",  "e6c27a", 0.6)    # 뿔 · 갈기 · 수염 · 지느러미(바랜 금)
BROW  = lp.mat("brow",  "6e6a60", 0.9)    # 눈썹(짙은 회갈)
EYEW  = lp.mat("eyew",  "f4f0e6", 0.5)
IRIS  = lp.mat("iris",  "9a7a2e", 0.4)    # 호박색 눈
PUPIL = lp.mat("pupil", "2a2418", 0.4)
MOUTH = lp.mat("mouth", "8a3a3a", 0.8)    # 입 안(포효 때 보임)
TEETH = lp.mat("teeth", "f4f0e6", 0.5)


def curve_tube(b, pts, r0, r1, m, v=6):
    """점들을 잇는 가는 관(수염 · 뿔 가지) — 마디마다 원뿔 하나."""
    from mathutils import Vector
    n = len(pts) - 1
    for i in range(n):
        a, c = Vector(pts[i]), Vector(pts[i + 1])
        d = c - a
        ra = r0 + (r1 - r0) * i / n
        rc = r0 + (r1 - r0) * (i + 1) / n
        o = b.cone(ra, rc, 0, d.length, m, v=v)
        o.location = a
        o.rotation_mode = "QUATERNION"
        o.rotation_quaternion = d.to_track_quat("Z", "Y")
        # 원뿔은 z0~z1 가운데가 원점이라 반 길이만큼 앞으로
        o.location = a + d * 0.5


# ── 머리 ──
h = lp.Body()
h.ball(0.5, (0, 0, 0), TEAL, 2, (1.0, 1.0, 0.92))                   # 둥근 머리통
h.ball(0.32, (0, 0.5, -0.12), TEAL, 2, (1.05, 1.15, 0.72))          # 위턱(주둥이)
h.ball(0.2, (0, 0.78, -0.06), TEAL, 2, (1.25, 0.8, 0.8))            # 코끝(둥근 코)
for sx in (-1, 1):
    h.ball(0.04, (sx * 0.1, 0.92, -0.02), PUPIL, 1)                  # 콧구멍
    # 눈: 흰자 · 호박 눈동자 · 동공 · 빛점(크게, 앞을 봄 — 설정화처럼 얼굴 앞쪽)
    h.ball(0.19, (sx * 0.2, 0.36, 0.13), EYEW, 2, (0.85, 0.5, 1.0))
    h.ball(0.135, (sx * 0.2, 0.43, 0.13), IRIS, 2, (0.9, 0.45, 0.95))
    h.ball(0.07, (sx * 0.2, 0.48, 0.13), PUPIL, 1, (1.0, 0.45, 1.0))
    h.ball(0.03, (sx * 0.17, 0.5, 0.19), EYEW, 1)
    # 굵은 눈썹(안쪽이 낮은 성난 눈썹)
    h.box(0.26, 0.09, 0.09, (sx * 0.21, 0.36, 0.34), BROW, rot=(0, sx * R(-16), 0))
    # 귀(청록 뾰족 — 옆 뒤로)
    e = h.cone(0.13, 0.0, 0, 0.3, TEAL, v=6)
    e.location = (sx * 0.4, 0.06, 0.34)
    e.rotation_euler = (R(-20), sx * R(40), 0)
    # 금 뿔(굵은 사슴뿔 — 줄기 + 앞으로 난 가지 하나, 위 뒤로)
    curve_tube(h, [(sx * 0.2, -0.08, 0.36), (sx * 0.23, -0.12, 0.7), (sx * 0.25, -0.2, 1.0), (sx * 0.24, -0.34, 1.2)], 0.085, 0.055, GOLD, v=8)
    curve_tube(h, [(sx * 0.24, -0.16, 0.84), (sx * 0.28, -0.02, 0.96), (sx * 0.29, 0.06, 1.04)], 0.055, 0.04, GOLD, v=8)
    # 금 수염(코 옆에서 옆으로 늘어졌다 위로 휨)
    curve_tube(h, [(sx * 0.2, 0.82, -0.12), (sx * 0.45, 0.78, -0.2), (sx * 0.7, 0.62, -0.3), (sx * 0.85, 0.45, -0.18), (sx * 0.9, 0.35, 0.02)], 0.025, 0.015, GOLD)
# 금 갈기: 정수리 · 귀 뒤 · 뺨 뒤에서 뒤로 흩날리는 뾰족한 털 뭉치(목 쪽으로 이어짐)
for sx in (-1, 1):
    for k, (y, z, ang) in enumerate([(-0.3, 0.42, 30), (-0.4, 0.22, 10), (-0.42, 0.0, -10), (-0.36, -0.2, -30)]):
        o = h.cone(0.14, 0.0, 0, 0.4, GOLD, v=5)
        o.location = (sx * (0.3 + 0.04 * k), y, z)
        o.rotation_euler = (R(-90 - ang * 0.6), sx * R(35), 0)   # 뒤로 · 바깥으로
for k, (z, ang) in enumerate([(0.5, 40), (0.3, 15), (0.08, -5)]):   # 등 가운데 줄
    o = h.cone(0.16, 0.0, 0, 0.55, GOLD, v=5)
    o.location = (0, -0.38, z)
    o.rotation_euler = (R(-90 - ang), 0, 0)
h.ball(0.24, (0, -0.06, 0.46), GOLD, 1, (0.85, 1.1, 0.7))          # 이마 위 볏(정면에서 뿔 사이)
for sx in (-1, 0, 1):
    o = h.cone(0.13, 0.0, 0, 0.38, GOLD, v=5)
    o.location = (sx * 0.12, -0.2, 0.52)
    o.rotation_euler = (R(-35), sx * R(25), 0)
head = h.join("head")

# ── 아래턱(원점 = 턱 뒤 경첩: 게임에서 x축으로 돌려 입을 벌림) ──
j = lp.Body()
j.ball(0.26, (0, 0.34, -0.06), TEAL, 2, (1.0, 1.25, 0.45))          # 아래턱
j.ball(0.2, (0, 0.34, 0.0), MOUTH, 1, (0.85, 1.1, 0.25))            # 입 안
for sx in (-1, 1):
    j.cone(0.035, 0.0, 0, 0.08, TEETH, x=sx * 0.14, y=0.55, v=4).location = (sx * 0.14, 0.55, 0.06)   # 송곳니
jaw = j.join("jaw")

# ── 몸 마디 하나(가운데 원점, 길이 0.6 · 반지름 0.5) ──
s = lp.Body()
s.ball(0.5, (0, 0, 0), TEAL, 2, (1.0, 0.75, 0.92))                  # 몸통 토막(앞뒤로 조금 납작 — 이어 붙이면 겹침)
s.ball(0.4, (0, 0, -0.28), BELLY, 1, (0.78, 0.62, 0.42))            # 배 판(아래)
for sx in (-1, 1):
    s.ball(0.16, (sx * 0.36, 0.04, 0.2), TEAL, 1, (0.6, 0.9, 0.5))  # 옆 비늘 볼록
f = s.cone(0.14, 0.0, 0, 0.36, GOLD, v=4)                            # 금 등지느러미(위로 뾰족, 뒤로 기움)
f.location = (0, -0.06, 0.6)
f.rotation_euler = (R(-28), 0, 0)
seg = s.join("seg")

# ── 꼬리 끝 ──
t = lp.Body()
o = t.cone(0.32, 0.12, 0, 0.9, TEAL, v=8)                            # 가늘어지는 몸(+Y 쪽이 몸통에 붙음)
o.rotation_euler = (R(90), 0, 0)
o.location = (0, -0.1, 0)
t.ball(0.22, (0, -0.1, -0.12), BELLY, 1, (0.6, 1.6, 0.4))
for k in range(5):                                                   # 금 불꽃 털(뒤 끝에서 퍼짐)
    a = R(-60 + k * 30)
    c = t.cone(0.13, 0.0, 0, 0.55, GOLD, v=5)
    c.location = (math.sin(a) * 0.12, -0.75, math.cos(a) * 0.12 + 0.05)
    c.rotation_euler = (R(-70) - math.cos(a) * R(25), 0, -math.sin(a) * R(40))
t.ball(0.17, (0, -0.62, 0.02), GOLD, 1, (1.0, 1.2, 1.0))
tail = t.join("tail")

# ── 앞다리 하나(원점 = 어깨, 오른쪽(+X) 다리 — 왼쪽은 게임에서 뒤집음) ──
l = lp.Body()
l.ball(0.17, (0.08, 0.02, -0.08), TEAL, 1, (1.0, 1.0, 1.2))         # 어깨
l.cone(0.12, 0.1, 0, 0.32, TEAL, v=6).location = (0.14, 0.08, -0.3)  # 위팔(아래로)
l.ball(0.13, (0.15, 0.14, -0.5), TEAL, 1, (1.0, 1.3, 0.8))          # 발
for k in range(3):                                                   # 발가락 셋
    l.ball(0.05, (0.15 + (k - 1) * 0.07, 0.28, -0.53), TEAL, 1)
leg = l.join("leg")

print("TRIS head=%d jaw=%d seg=%d tail=%d leg=%d" % tuple(lp.tris(o) for o in (head, jaw, seg, tail, leg)))
lp.export(os.path.join(OUT, "qinglong.glb"), [head, jaw, seg, tail, leg], animated=False)

if "--render" in FLAGS:   # 설정화와 맞대 보기: 머리 + 아래턱 정면(용이 +Y를 보므로 'back' 카메라) · 옆
    for o in (seg, tail, leg):
        o.hide_render = True
    jaw.location = (0, 0, -0.18)
    lp.render_views(OUT, "qinglong_head", center_z=0.2, ortho=2.6, views=("back", "side", "quarter"))
    jaw.location = (0, 0, 0)
print("DONE")
