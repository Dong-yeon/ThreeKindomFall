# 팔진도 돌기둥(D-338, 설정화 godot3d/art/concept/bagua_parts.webp 왼쪽): 둥근 돌 셋을 쌓은 기둥 · 넓은 받침 · 두 덩이 머리돌 · 꼭대기 흰 깃털.
# 팔괘 문양(빛)은 게임(scripts/martial/ult_bagua.gd)이 기둥마다 자기 괘를 앞면(블렌더 −Y → Godot +Z)에 붙임 — 여기선 돌만.
# 높이 1.5(게임에서 배율). 실행: python godot3d/tools/blender/bagua_pillar.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians
STONE  = lp.mat("stone",  "9a9ca2", 0.95)
STONE2 = lp.mat("stone2", "8c8e95", 0.95)
FWHITE = lp.mat("fwhite", "f4f4f2", 0.7)
CORD   = lp.mat("cord",   "8a6a40", 0.8)

b = lp.Body()

def rbox(sx, sy, sz, loc, m, bev=0.06):
    o = b.box(sx, sy, sz, loc, m)
    md = o.modifiers.new("bev", "BEVEL")
    md.width = bev / max(sx, sy, sz)   # 크기 1 상자에 비율로 들어가므로 나눔
    md.segments = 2
    return o

rbox(0.95, 0.85, 0.22, (0, 0, 0.11), STONE2, 0.08)              # 넓은 받침
rbox(0.72, 0.62, 0.40, (0, 0, 0.42), STONE, 0.07)               # 아래 돌
rbox(0.66, 0.58, 0.36, (0, 0, 0.80), STONE2, 0.07)              # 가운데 돌
rbox(0.62, 0.55, 0.30, (0, 0, 1.13), STONE, 0.07)               # 위 돌
for sx in (-1, 1):
    rbox(0.32, 0.56, 0.18, (sx * 0.16, 0, 1.36), STONE2, 0.06)  # 머리돌 두 덩이
b.cone(0.09, 0.07, 1.44, 1.56, STONE, v=8)                      # 꼭대기 꼭지
b.cone(0.075, 0.075, 1.55, 1.59, CORD, v=8)                     # 묶은 끈
for k in range(3):                                               # 흰 깃털(위로 · 살짝 휨)
    f = b.ball(0.5, (0.02 * (k - 1), 0, 1.78), FWHITE, 2, (0.14, 0.05, 0.36))
    f.rotation_euler = (0, R(-12 + 12 * k), 0)
mesh = b.join("bagua_pillar")
print("TRIS", lp.tris(mesh))
lp.export(os.path.join(OUT, "bagua_pillar.glb"), [mesh], animated=False)
if "--render" in FLAGS:
    lp.render_views(OUT, "pillar", center_z=0.9, ortho=2.4, views=("front", "side"))
print("DONE")
