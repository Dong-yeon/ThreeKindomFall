# 관우 얼굴 데칼(귀여움 실험 D-336 · 2차 D-337): 설정화 정면(guan_yu_v2.webp)에서 눈썹 · 눈 · 입만 투명 PNG로 잘라냄.
# 2차: 눈을 1.5배(눈마다 가운데를 축으로) · 눈썹은 조금 위로(눈이 커진 자리) — 조각마다 따로 잘라 새 판에 붙임.
# 실행: python godot3d/tools/face_decal.py  → godot3d/assets/textures/face_guanyu_default.png (Pillow)
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
im = Image.open(os.path.join(ROOT, "art/concept/guan_yu_v2.webp")).convert("RGB")
SKIN = (218, 101, 95)                          # 얼굴 바탕색 — 이 색에서 멀수록 남김
X0, Y0, X1, Y1 = 296, 280, 514, 452            # 결과 판(설정화 픽셀 좌표, 1차보다 위로 16px 넓힘)
EYE_K = 1.5                                    # 눈 크기 배율
EYES = [(341, 364), (461, 364)]                # 눈 가운데(설정화)
EYE_R = (19, 25)                               # 눈 하나 잘라낼 반폭 · 반높이
BROW_UP = 10                                   # 눈썹을 위로(px)
EYE_DOWN = 4                                   # 커진 눈을 아래로(px)


def keyed(box, mode):
    """box 영역을 잘라 알파를 매김. mode: feat(눈썹 · 눈 — 바탕색에서 먼 것) | mouth(짙은 붉은 선)."""
    cr = im.crop(box)
    out = Image.new("RGBA", cr.size)
    for y in range(cr.height):
        for x in range(cr.width):
            r, g, b = cr.getpixel((x, y))
            a = 0.0
            if g > r + 8:                          # 두건 녹색은 버림
                a = 0.0
            elif mode == "feat":
                d = ((r - SKIN[0]) ** 2 + (g - SKIN[1]) ** 2 + (b - SKIN[2]) ** 2) ** 0.5
                a = min(1.0, max(0.0, (d - 45) / 50))
            elif r > 90 and r - g > 85 and g < 62:   # 입: 수염(검정)은 버리고 짙은 붉은 선만
                a = min(1.0, max(0.0, (205 - r) / 40))
            out.putpixel((x, y), (r, g, b, int(a * 255)))
    return out


def in_eye(x, y):
    return any(((x - cx) / EYE_R[0]) ** 2 + ((y - cy) / EYE_R[1]) ** 2 <= 1.0 for cx, cy in EYES)


board = Image.new("RGBA", (X1 - X0, Y1 - Y0))
# 눈썹: 위 두건 가장자리(300 위)는 빼고 눈 자리를 지운 뒤 위로 올려 붙임
brow = keyed((X0, 300, X1, 352), "feat")
for y in range(brow.height):
    for x in range(brow.width):
        if in_eye(x + X0, y + 300):
            brow.putpixel((x, y), (0, 0, 0, 0))
board.alpha_composite(brow, (0, 300 - BROW_UP - Y0))
# 눈: 하나씩 잘라 1.5배 → 가운데 맞춰 붙임
for cx, cy in EYES:
    eye = keyed((cx - EYE_R[0], cy - EYE_R[1], cx + EYE_R[0], cy + EYE_R[1]), "feat")
    for y in range(eye.height):
        for x in range(eye.width):
            if not in_eye(x + cx - EYE_R[0], y + cy - EYE_R[1]):
                eye.putpixel((x, y), (0, 0, 0, 0))
    big = eye.resize((int(eye.width * EYE_K), int(eye.height * EYE_K)), Image.LANCZOS)
    board.alpha_composite(big, (cx - big.width // 2 - X0, cy + EYE_DOWN - big.height // 2 - Y0))
# 입: 입 자리만
board.alpha_composite(keyed((368, 426, 443, 449), "mouth"), (368 - X0, 426 - Y0))

board = board.resize((board.width * 2, board.height * 2), Image.LANCZOS)
os.makedirs(os.path.join(ROOT, "assets/textures"), exist_ok=True)
board.save(os.path.join(ROOT, "assets/textures/face_guanyu_default.png"))
print("SIZE", board.size)
