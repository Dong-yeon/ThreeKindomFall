# 관우 저폴리 모델 + 뼈대 + 동작 — 블렌더 코드로만 만든다.
# D-274 첫 시안 → D-277 설정화(guan_yu.webp, 약 3등신) → D-311: 새 설정화(godot3d/art/concept/guan_yu_v2.webp)를 보고 처음부터 큰 머리(약 2등신)로:
#   두 겹 봉긋한 녹색 두건 + 앞 금 장식 + 뒤 매듭 · 늘어진 두 끈 · 허리까지 내려오는 녹색 뒷천 / 붉은 얼굴 · 굵은 눈썹 · 까만 눈 /
#   배까지 오는 넓은 검은 수염 · 구레나룻 · 양옆 긴 머리 / 오른쪽 어깨에만 금 견갑 / 녹색 전포 + 가슴을 가로지르는 띠 /
#   갈색 허리띠 + 금 육각 버클 · 장식 / 앞에 늘어진 녹색 띠 · 녹색 바지 · 갈색 신 · 붉은 주먹.
#   청룡언월도는 무기 설정화(D-315)대로 오른손에.
# 동작: idle · walk + 개그 동작(lowpoly.end_actions: 쓰러질 때 down · 승리할 때 cheer, D-313).
# 실행: python godot3d/tools/blender/guan_yu.py <출력 폴더> [--render]   (pip install bpy)
# 결과: guan_yu.glb (--render면 정면 · 옆 · 뒤 gy_*.png — 설정화와 맞대 보기용)
# --cute(귀여움 실험, 결과 guan_yu_cute.glb — 게임은 아직 guan_yu.glb): 점 눈 · 눈썹 대신 설정화에서 잘라낸 얼굴 데칼
#   (assets/textures/face_guanyu_default.png, tools/face_decal.py)을 얼굴 곡면에 Shrinkwrap으로 붙이고,
#   모든 조각 shade_smooth + Subdivision Surface(2) · 머리 무리(머리 뼈 조각 = 얼굴 · 두건 · 수염 · 데칼) 1.4배.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
CUTE = "--cute" in FLAGS
lp.reset_scene()
R = math.radians

FACE   = lp.mat("face",   "d4594c")          # 붉은 얼굴 · 주먹
BLUSH  = lp.mat("blush",  "e8737a")
GREEN  = lp.mat("green",  "4f9a5e")          # 전포 · 두건
DKGRN  = lp.mat("dkgreen", "3d7d4a")         # 바지 · 띠 · 뒷천 그늘
GOLD   = lp.mat("gold",   "d6b04a", 0.45, 0.5)
BLACK  = lp.mat("black",  "26221f")          # 수염 · 머리 · 눈썹
BROWN  = lp.mat("brown",  "5c3f2c")          # 허리띠 · 신
STEEL  = lp.mat("steel",  "4a5058", 0.4, 0.7)
SILVER = lp.mat("silver", "d8dce0", 0.3, 0.9)

b = lp.Body()
# 앞쪽 = -Y, 발밑 z = 0, 키 약 2.0(두건 끝). 관우의 오른쪽 = -X.

# ── 다리: 갈색 신 · 녹색 바지(짧게) ──
for side, bone in ((-1, "leg_R"), (1, "leg_L")):
    b.bone = bone
    x = 0.14 * side
    b.box(0.18, 0.27, 0.10, (x, -0.03, 0.05), BROWN)
    b.cone(0.11, 0.13, 0.08, 0.28, DKGRN, x=x, v=8)

# ── 몸통: 녹색 전포 · 허리띠 · 띠 · 견갑 · 뒷천 ──
b.bone = "torso"
b.cone(0.43, 0.33, 0.18, 0.56, GREEN, v=10)                          # 전포 자락(아래로 퍼짐)
b.box(0.30, 0.02, 0.34, (-0.10, -0.40, 0.36), DKGRN, (R(-14), 0, 0))  # 앞자락 겹침(그늘)
b.cone(0.33, 0.30, 0.56, 0.98, GREEN, v=10)                          # 윗몸
b.cone(0.345, 0.345, 0.53, 0.60, BROWN, v=10)                        # 갈색 허리띠
b.box(0.15, 0.05, 0.09, (0, -0.335, 0.565), GOLD)                     # 금 육각 버클
for x in (-0.18, 0.18):
    b.box(0.05, 0.04, 0.05, (x, -0.29, 0.565), GOLD, (0, 0, R(45)))  # 띠 장식
b.box(0.07, 0.02, 0.36, (0.08, -0.36, 0.36), DKGRN, (R(-12), 0, R(4)))  # 앞에 늘어진 녹색 띠
b.box(0.08, 0.02, 0.62, (0.0, -0.30, 0.78), DKGRN, (R(-8), R(40), 0))   # 가슴을 가로지르는 띠
b.box(0.26, 0.30, 0.08, (-0.33, 0.0, 0.92), GOLD, (0, R(-28), 0))    # 오른쪽 어깨 금 견갑
b.box(0.18, 0.22, 0.04, (-0.37, 0.0, 0.95), GOLD, (0, R(-28), 0))
b.box(0.62, 0.05, 0.92, (0, 0.36, 1.00), GREEN, (R(5), 0, 0))         # 두건에서 내려온 뒷천(두건 아래 ~ 허리, 뒷머리를 덮음)
b.poly([(-0.31, 0.56), (0.31, 0.56), (0.0, 0.40)], 0.38, 0.05, GREEN)  # 뒷천 끝(뾰족)

# ── 팔: 녹색 소매 · 붉은 주먹(살짝 벌림) ──
for side, bone in ((1, "arm_L"), (-1, "arm_R")):
    b.bone = bone
    rot = (0, R(-22 * side), 0)
    b.cone(0.16, 0.13, 0.60, 0.97, GREEN, x=0.44 * side, v=8, rot=rot)   # 굵은 소매
    b.cone(0.14, 0.14, 0.60, 0.66, DKGRN, x=0.51 * side, v=8, rot=rot)
    b.ball(0.125, (0.59 * side, -0.02, 0.50), FACE, 1)                # 큰 주먹

# 청룡언월도(오른손) — 무기 설정화(D-315): 녹색 자루 · 금 물미(둥근 끝) · 금 용머리 코등이 · 넓은 은 칼날(끝이 휘고 등에 홈) · 금 용 무늬
b.bone = "arm_R"
PX, PY = -0.60, -0.10
WGRN = lp.mat("wgreen", "4f8a68")
WGOLD = lp.mat("wgold", "e2c070", 0.5, 0.4)
b.cone(0.045, 0.045, 0.05, 1.42, WGRN, x=PX, y=PY, v=8)              # 녹색 자루(굵게)
b.cone(0.06, 0.06, 0.02, 0.08, WGOLD, x=PX, y=PY, v=8)               # 물미 띠
b.ball(0.075, (PX, PY, -0.04), WGOLD, 1, (1.0, 1.0, 1.4))            # 금 물미(둥근 끝)
b.box(0.16, 0.15, 0.20, (PX, PY, 1.52), WGOLD)                       # 금 용머리 코등이
b.box(0.12, 0.10, 0.08, (PX - 0.13, PY, 1.50), WGOLD)                # 용 주둥이(바깥으로)
b.box(0.04, 0.03, 0.06, (PX - 0.02, PY - 0.08, 1.58), lp.mat("weye", "8a6a30"))   # 용 눈
blade = [(-0.08, 1.62), (-0.20, 1.86), (-0.25, 2.14), (-0.22, 2.42), (-0.10, 2.62), (0.12, 2.72),
         (0.06, 2.56), (0.10, 2.44), (0.03, 2.34), (0.08, 2.20), (0.09, 1.62)]   # 앞(바깥 -X)이 볼록, 끝이 몸 쪽으로 휨, 등에 홈
b.poly([(PX + x, z) for x, z in blade], PY, 0.05, SILVER)
for dy in (-0.03, 0.03):   # 금 용 무늬(흉내 — 몸통 S자 + 머리)
    b.box(0.03, 0.01, 0.42, (PX - 0.08, PY + dy, 1.96), WGOLD, (0, R(12), 0))
    b.box(0.03, 0.01, 0.20, (PX - 0.04, PY + dy, 2.22), WGOLD, (0, R(-20), 0))
    b.box(0.08, 0.01, 0.07, (PX - 0.02, PY + dy, 2.34), WGOLD)

# ── 머리 ──
b.bone = "head"
face_ball = b.ball(0.34, (0, 0, 1.27), FACE, 2, (1.0, 0.95, 0.98))   # 얼굴
for side in (-1, 1):
    b.ball(0.08, (0.34 * side, 0.02, 1.27), FACE, 1, (0.6, 1.0, 1.1))  # 귀
    if not CUTE:   # --cute는 얼굴 데칼이 눈 · 눈썹 · 입을 맡음
        b.ball(0.05, (0.12 * side, -0.30, 1.32), BLACK, 1)                # 까만 눈
        b.ball(0.015, (0.11 * side, -0.345, 1.34), lp.mat("white", "f8f8f4"), 1)   # 눈 빛
        b.box(0.17, 0.06, 0.06, (0.13 * side, -0.30, 1.42), BLACK, (0, R(-20 * side), 0))  # 굵은 성난 눈썹(안쪽이 내려감)
    b.box(0.07, 0.02, 0.04, (0.21 * side, -0.28, 1.22), BLUSH)        # 볼 홍조
    b.box(0.06, 0.10, 0.40, (0.31 * side, 0.06, 1.10), BLACK)         # 양옆 긴 머리(귀 뒤)
    b.box(0.07, 0.10, 0.20, (0.28 * side, -0.14, 1.15), BLACK)        # 구레나룻
b.box(0.06, 0.05, 0.07, (0, -0.335, 1.24), FACE)                      # 코
if CUTE:   # 2차(D-337): 수염은 입 아래 ~ 가슴(길이 2/3) · 끝 둥글게 · 짙은 갈색빛 검정 / 콧수염은 따로 작게 둘(입 위)
    BEARD = lp.mat("beard", "2b211e")
    beard = b.cone(0.10, 0.30, 0.72, 1.10, BEARD, y=-0.25, v=10, rot=(R(-8), 0, 0))
    beard.scale = (1.0, 0.6, 1.0)
    b.ball(0.12, (0, -0.255, 0.74), BEARD, 2, (1.0, 0.6, 0.8))           # 둥근 수염 끝
    for side in (-1, 1):
        b.box(0.10, 0.14, 0.18, (0.25 * side, -0.18, 1.06), BEARD)    # 턱선 수염(구레나룻과 이어짐)
        b.box(0.11, 0.04, 0.035, (0.06 * side, -0.335, 1.178), BEARD, (0, R(14 * side), 0))   # 작은 콧수염(바깥으로 처짐)
else:
    beard = b.cone(0.05, 0.36, 0.56, 1.16, BLACK, y=-0.25, v=10, rot=(R(-8), 0, 0))   # 배까지 오는 넓은 수염(아래가 뾰족)
    beard.scale = (1.0, 0.6, 1.0)
    for side in (-1, 1):
        b.box(0.10, 0.14, 0.18, (0.25 * side, -0.18, 1.06), BLACK)        # 턱선 수염(구레나룻과 이어짐)
    b.box(0.30, 0.06, 0.05, (0, -0.33, 1.17), BLACK)                      # 콧수염
b.box(0.56, 0.16, 0.26, (0, 0.16, 1.14), BLACK)                       # 뒷머리(두건 뒷천에 가려짐)
# 두건: 이마 띠 → 아래 봉긋 → 위 봉긋(두 겹) · 앞 금 장식 · 뒤 매듭 + 두 끈
TU = 0.06 if CUTE else 0.0   # 2차(D-337): 두건 아래 가장자리를 눈썹 위로 올려 얼굴을 넓게
b.cone(0.36, 0.355, 1.42 + TU, 1.56 + TU, GREEN, v=12)
b.ball(0.34, (0, 0.02, 1.58 + TU), GREEN, 2, (1.0, 1.0, 0.65))
b.ball(0.27, (0, 0.06, 1.76 + TU), GREEN, 2, (1.0, 1.0, 0.75))
b.box(0.11, 0.04, 0.08, (0, -0.355, 1.50 + TU), GOLD, (0, R(45), 0))
b.box(0.16, 0.10, 0.10, (0, 0.36, 1.48 + TU), DKGRN)                      # 뒤 매듭
for side in (-1, 1):
    b.box(0.07, 0.03, 0.30, (0.05 * side, 0.40, 1.30 + TU), DKGRN, (R(8), R(12 * side), 0))

if CUTE:
    import bpy
    # 모든 조각: 매끈하게(Subdivision Surface 2단계) — 합칠 때 적용됨
    # 받침 모서리 없는 저폴리 조각은 그냥 나누면 녹아내림(자루가 실처럼 · 몸통 조각 사이가 벌어짐) → 크리스로 부피를 지킴.
    # 2차(D-337): 1차의 '모든 모서리 0.6'은 몸이 각져 보여서 조각 종류마다 — 원기둥은 옆 모서리 0(둥근 관) · 위아래 테 CAP,
    #   상자는 BOX(둥근 베개), 칼날 같은 판(두께 준 다각형)은 PLATE, 공은 0.
    CAP, BOX, PLATE = 0.8, 0.25, 0.6
    for o, _ in b.parts:
        me = o.data
        if o.name.startswith("Cone"):
            vals = [0.0 if abs(me.vertices[e.vertices[0]].co.z - me.vertices[e.vertices[1]].co.z) > 1e-5 else CAP for e in me.edges]
        elif o.name.startswith("Cube"):
            vals = [BOX] * len(me.edges)
        elif o.name.startswith("poly"):
            vals = [PLATE] * len(me.edges)
        else:
            vals = [0.0] * len(me.edges)
        at = me.attributes.get("crease_edge") or me.attributes.new("crease_edge", "FLOAT", "EDGE")
        at.data.foreach_set("value", vals)
        for md in o.modifiers:
            if md.type == "SOLIDIFY":
                md.edge_crease_inner = md.edge_crease_outer = md.edge_crease_rim = PLATE
        md = o.modifiers.new("subd", "SUBSURF")
        md.levels = md.render_levels = 2
    # 얼굴 데칼: 머리 앞 격자 평면(설정화 픽셀 0.00213m — 두 눈 사이 0.26) → 얼굴 공(매끈하게 한 뒤) 곡면에 Shrinkwrap(앞뒤로 투영)
    PNG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "textures", "face_guanyu_default.png")
    DW, DH, DTOP = 0.464, 0.366, 1.477   # 데칼 폭 · 높이 · 위끝(2차: 눈 줄 z ≈ 1.29 · 눈썹 1.36 ~ 1.46 — 올린 두건 띠 1.48 아래 · 입 z ≈ 1.14)
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=24, y_subdivisions=18, size=1, calc_uvs=True,
                                    location=(0, -0.60, DTOP - DH / 2), rotation=(R(90), 0, 0))
    decal = bpy.context.object
    decal.scale = (DW, DH, 1)
    md = decal.modifiers.new("subd", "SUBSURF")
    md.levels = md.render_levels = 2
    sw = decal.modifiers.new("wrap", "SHRINKWRAP")
    sw.target = face_ball
    sw.wrap_method = "PROJECT"
    sw.use_project_z = True                       # 평면 로컬 Z = 정면(-Y)
    sw.use_negative_direction = sw.use_positive_direction = True
    sw.offset = 0.006
    dm = bpy.data.materials.new("face_decal")
    dm.use_nodes = True
    nt = dm.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.abspath(PNG))
    bsdf = nt.nodes["Principled BSDF"]
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.8
    for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):   # 알파 블렌드(블렌더 판마다 이름이 다름)
        if hasattr(dm, attr):
            try:
                setattr(dm, attr, val)
            except Exception:
                pass
    decal.data.materials.append(dm)
    b.parts.append((decal, "head"))

mesh = b.join("guan_yu")
if CUTE:
    import bpy
    bpy.ops.object.shade_smooth()
    names = {g.index: g.name for g in mesh.vertex_groups}
    hv = [v for v in mesh.data.vertices if v.groups and names[v.groups[0].group] == "head"]
    fi = [i for i, m in enumerate(mesh.data.materials) if m and m.name == "face"][0]
    hset = {v.index for v in hv}
    face_idx = {i for p in mesh.data.polygons if p.material_index == fi for i in p.vertices
                if i in hset and abs(mesh.data.vertices[i].co.x) < 0.08}
    def ratio():   # 머리 높이(턱 = 얼굴 공 아래 끝 ~ 머리 무리 위끝) / 전체 키(발밑 ~ 머리 위끝)
        top = max(v.co.z for v in hv)
        chin = min(mesh.data.vertices[i].co.z for i in face_idx)   # 얼굴 공 아래 끝(가운데)
        return top, chin, (top - chin) / top
    top0, chin0, r0 = ratio()
    HEAD_K = 1.4
    for v in hv:   # 머리 무리를 턱 아래(목 자리)를 축으로 1.4배 — 얼굴이 몸 위에 그대로 앉게
        x, y, z = v.co
        v.co = (x * HEAD_K, y * HEAD_K, chin0 + (z - chin0) * HEAD_K)
    top1, chin1, r1 = ratio()
    print("HEAD ratio before %.2f (chin %.2f top %.2f) -> after %.2f (top %.2f)" % (r0, chin0, top0, r1, top1))
rig = lp.make_rig("guan_yu", mesh, [
    ("root",  (0, 0, 0),            (0, 0, 0.3),            None),
    ("torso", (0, 0, 0.50),         (0, 0, 1.00),           "root"),
    ("head",  (0, 0, 1.00),         (0, 0, 1.60),           "torso"),
    ("leg_L", ( 0.14, 0, 0.28),     ( 0.14, 0, 0.0),        "root"),
    ("leg_R", (-0.14, 0, 0.28),     (-0.14, 0, 0.0),        "root"),
    ("arm_L", ( 0.32, 0, 0.94),     ( 0.58, 0, 0.52),       "torso"),
    ("arm_R", (-0.32, 0, 0.94),     (-0.58, -0.08, 0.52),   "torso"),
])

def idle(f):   # 0 ~ 24 (1초): 숨쉬듯 위아래
    t = f / 24 * 2 * math.pi
    return ({"head": (2 * math.sin(t), 0, 0), "arm_L": (0, 0, -3 * math.sin(t))},
            {"torso": (0, 0.012 * (1 - math.cos(t)) * 0.5, 0)})

def walk(f):   # 0 ~ 16 (0.67초 한 걸음 주기) — 다리가 짧아 종종걸음
    s = math.sin(f / 16 * 2 * math.pi)
    rot = {"leg_L": (-35 * s, 0, 0), "leg_R": (35 * s, 0, 0),
           "arm_L": (-22 * s, 0, 0), "arm_R": (8 * s, 0, 0),
           "torso": (-4, 0, 5 * s), "head": (2, 0, -4 * s)}
    return rot, {"root": (0, 0.035 * abs(s), 0)}

lp.make_action(rig, "idle", list(range(0, 25, 2)), idle)
lp.make_action(rig, "walk", list(range(0, 17, 2)), walk)
lp.end_actions(rig)   # 개그 동작: 쓰러질 때 down · 승리할 때 cheer(D-313)
print("TRIS", lp.tris(mesh))

if "--render" in FLAGS:
    lp.render_views(OUT, "gy_cute" if CUTE else "gy", center_z=1.15 if CUTE else 1.0, ortho=3.0 if CUTE else 2.5)

lp.export(os.path.join(OUT, "guan_yu_cute.glb" if CUTE else "guan_yu.glb"), [rig, mesh], animated=True)
print("DONE")
