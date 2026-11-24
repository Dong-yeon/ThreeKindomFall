# 황건 궁병이 쏘는 화살 한 발 — 블렌더 코드로만(D-328, 활 설정화 godot3d/art/concept/yt_archer_bow.webp의 화살):
#   나무 화살대 · 끈으로 묶은 회색 돌 촉 · 노란 깃 두 장. 게임(horde.gd)에선 MultiMesh로 날아가는 쪽(+Z)을 향함 —
#   그래서 블렌더에선 촉이 -Y(glTF 내보내면 Godot +Z).
# 실행: python godot3d/tools/blender/yt_arrow.py <출력 폴더> [--render]   (pip install bpy)
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lowpoly as lp

OUT, FLAGS = lp.args()
lp.reset_scene()
R = math.radians
SHAFT = lp.mat("shaft", "8a6448")
STONE = lp.mat("stone", "8a8682", 0.9)
ROPE  = lp.mat("rope",  "b09a6a")
FEATH = lp.mat("feath", "e0b040")

b = lp.Body()
L = 0.9
b.cone(0.022, 0.022, -L * 0.5, L * 0.5, SHAFT, v=6, rot=(R(90), 0, 0)).location = (0, 0, 0)   # 화살대(세로 원뿔을 눕혀 Y축으로, 가운데가 원점)
b.ball(0.06, (0, -L * 0.5 - 0.06, 0), STONE, 1, (0.8, 1.6, 0.55))    # 돌 촉(뾰족한 앞)
b.cone(0.03, 0.03, -0.03, 0.03, ROPE, v=6, rot=(R(90), 0, 0)).location = (0, -L * 0.5 + 0.02, 0)   # 묶은 끈
for side in (-1, 1):                                                 # 노란 깃 두 장(꼬리)
    f = b.poly([(0.0, 0.0), (0.09 * side, 0.03), (0.10 * side, 0.18), (0.0, 0.20)], 0.0, 0.012, FEATH)
    f.rotation_euler = (R(-90), 0, 0)                                # XZ 다각형 → XY(화살대 옆으로 퍼진 깃)
    f.location = (0, L * 0.5 - 0.22, 0)
mesh = b.join("yt_arrow")
print("TRIS", lp.tris(mesh))
lp.export(os.path.join(OUT, "yt_arrow.glb"), [mesh], animated=False)
print("DONE")
