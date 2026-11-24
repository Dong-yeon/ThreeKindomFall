# 관우 얼굴 데칼(귀여움 실험): 설정화 정면(guan_yu_v2.webp)에서 눈썹 · 눈 · 입만 투명 PNG로 잘라냄.
# 실행: python godot3d/tools/face_decal.py  → godot3d/assets/textures/face_guanyu_default.png (Pillow)
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
im = Image.open(os.path.join(ROOT, "art/concept/guan_yu_v2.webp")).convert("RGB")
X0, Y0, X1, Y1 = 296, 296, 514, 452          # 눈썹 · 눈 · 입 영역(설정화 픽셀)
cr = im.crop((X0, Y0, X1, Y1))
out = Image.new("RGBA", cr.size)
SKIN = (218, 101, 95)                         # 얼굴 바탕색 — 이 색에서 멀수록 남김
for y in range(cr.height):
    for x in range(cr.width):
        r, g, b = cr.getpixel((x, y))
        a = 0.0
        if g > r + 8:                         # 두건 녹색은 버림
            a = 0.0
        elif 300 <= y + Y0 < 398:             # 눈썹 · 눈(검정 · 흰 눈빛) — 위 두건 가장자리 · 아래 콧구멍 그늘은 뺌
            d = ((r - SKIN[0]) ** 2 + (g - SKIN[1]) ** 2 + (b - SKIN[2]) ** 2) ** 0.5
            a = min(1.0, max(0.0, (d - 45) / 50))
        elif 368 <= x + X0 <= 442 and 426 <= y + Y0 <= 448 and r > 90 and r - g > 85 and g < 62:   # 입: 입 자리 안에서 짙은 붉은 선만(수염 · 코 가장자리는 버림)
            a = min(1.0, max(0.0, (205 - r) / 40))
        out.putpixel((x, y), (r, g, b, int(a * 255)))
out = out.resize((out.width * 2, out.height * 2), Image.LANCZOS)
os.makedirs(os.path.join(ROOT, "assets/textures"), exist_ok=True)
out.save(os.path.join(ROOT, "assets/textures/face_guanyu_default.png"))
print("SIZE", out.size)
