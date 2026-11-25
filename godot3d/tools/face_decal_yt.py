# 황건 잡병 넷 얼굴 데칼(D-345, docs/art/character-model-rules.md 1번): 설정화 정면에서 눈썹 · 눈(하이라이트 포함) · 입을 잘라
# 투명 PNG로 — 눈은 1.5배(관우와 같게), 볼터치는 설정화 자리에 부드러운 타원으로 그려 넣음.
# 실행: python godot3d/tools/face_decal_yt.py  → godot3d/assets/textures/face_yt_<종류>.png (Pillow)
#       장면 배치용 수치(픽셀 → 모델 단위)는 같은 이름의 .json으로(모델 스크립트 yt_grunt.py가 읽음).
import json, os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
EYE_K = 1.5          # 눈 배율(관우 D-337과 같게)
EYE_GAP = 0.26       # 두 눈 사이(모델 단위, 관우와 같게) — 설정화 픽셀 → 모델 단위 환산의 기준
BLUSH = (232, 150, 132)

# 종류마다: 설정화 · 얼굴 바탕색 · 판(데칼 범위) · 눈썹 띠 · 눈 가운데 · 눈 반경 · 입 상자와 입 규칙 · 볼터치 자리
TYPES = {
    "soldier": dict(src="yellow_turban_v2", skin=(228, 178, 148), board=(290, 285, 516, 452),
                    brow=(296, 300, 512, 344), eyes=[(340, 357), (459, 357)], eye_r=(19, 24),
                    mouth=(362, 424, 440, 446), mouth_rule="red", blush=[(305, 404), (494, 404)]),
    "archer": dict(src="yt_archer", skin=(230, 180, 150), board=(290, 285, 516, 440),
                   brow=(296, 300, 512, 344), eyes=[(340, 357), (459, 357)], eye_r=(22, 24),
                   mouth=(358, 410, 442, 434), mouth_rule="red", blush=[(305, 400), (494, 400)]),
    "rusher": dict(src="yt_rusher", skin=(225, 170, 145), board=(300, 222, 506, 384),
                   brow=(318, 234, 496, 277), eyes=[(360, 289), (455, 289)], eye_r=(17, 20),
                   mouth=(364, 342, 450, 380), mouth_rule="open", blush=[(325, 330), (490, 330)]),
    "shield": dict(src="yt_shield", skin=(232, 178, 151), board=(290, 285, 516, 462),
                   brow=(296, 306, 512, 344), eyes=[(340, 357), (459, 357)], eye_r=(19, 24),
                   mouth=(362, 426, 442, 458), mouth_rule="teeth", blush=[(305, 404), (494, 404)]),
}


def keyed(im, box, skin, rule):
    cr = im.crop(box)
    out = Image.new("RGBA", cr.size)
    sl = sum(skin) / 3
    for y in range(cr.height):
        for x in range(cr.width):
            r, g, b = cr.getpixel((x, y))
            lum = (r + g + b) / 3
            a = 0.0
            if rule == "feat":                         # 눈썹 · 눈 · 하이라이트: 바탕색에서 먼 것
                d = ((r - skin[0]) ** 2 + (g - skin[1]) ** 2 + (b - skin[2]) ** 2) ** 0.5
                a = min(1.0, max(0.0, (d - 45) / 50))
                if g > r + 8 or (r - b > 45 and 95 < lum < 200):   # 두건 · 띠 · 가죽 투구 챙 같은 다른 색은 버림
                    a = 0.0
            elif rule == "red":                        # 다문 입: 짙은 붉은 선(수염 검정은 버림)
                if r > 90 and r - g > 55 and g < 120:
                    a = min(1.0, max(0.0, (210 - r) / 40))
            elif rule == "open":                       # 벌린 입: 짙은 붉은 속(수염 검정 · 피부는 버림)
                if r > 70 and r - g > 45 and lum < sl - 40:
                    a = 1.0
            elif rule == "teeth":                      # 악문 이: 흰 이 + 이 사이 틈
                if lum > 205 and abs(r - b) < 30:
                    a = 1.0
                elif lum < 150 and abs(r - g) < 40 and r < 170:
                    a = 0.6
            out.putpixel((x, y), (r, g, b, int(a * 255)))
    return out


def make(name, t):
    im = Image.open(os.path.join(ROOT, "art/concept", t["src"] + ".webp")).convert("RGB")
    X0, Y0, X1, Y1 = t["board"]
    board = Image.new("RGBA", (X1 - X0, Y1 - Y0))
    # 볼터치: 부드러운 타원(설정화 볼 자리)
    bl = Image.new("RGBA", board.size)
    d = ImageDraw.Draw(bl)
    for cx, cy in t["blush"]:
        d.ellipse((cx - X0 - 22, cy - Y0 - 13, cx - X0 + 22, cy - Y0 + 13), fill=BLUSH + (150,))
    board.alpha_composite(bl.filter(ImageFilter.GaussianBlur(5)))
    # 눈썹(눈 자리는 지우고 붙임)
    ex, ey = t["eye_r"]
    def in_eye(x, y):
        return any(((x - cx) / ex) ** 2 + ((y - cy) / ey) ** 2 <= 1.0 for cx, cy in t["eyes"])
    bx0, by0, bx1, by1 = t["brow"]
    brow = keyed(im, t["brow"], t["skin"], "feat")
    for y in range(brow.height):
        for x in range(brow.width):
            if in_eye(x + bx0, y + by0):
                brow.putpixel((x, y), (0, 0, 0, 0))
    board.alpha_composite(brow, (bx0 - X0, by0 - Y0))
    # 눈: 하나씩 1.5배
    for cx, cy in t["eyes"]:
        eye = keyed(im, (cx - ex, cy - ey, cx + ex, cy + ey), t["skin"], "feat")
        for y in range(eye.height):
            for x in range(eye.width):
                if not in_eye(x + cx - ex, y + cy - ey):
                    eye.putpixel((x, y), (0, 0, 0, 0))
        big = eye.resize((int(eye.width * EYE_K), int(eye.height * EYE_K)), Image.LANCZOS)
        board.alpha_composite(big, (cx - big.width // 2 - X0, cy + 3 - big.height // 2 - Y0))
    # 입
    mx0, my0, mx1, my1 = t["mouth"]
    board.alpha_composite(keyed(im, t["mouth"], t["skin"], t["mouth_rule"]), (mx0 - X0, my0 - Y0))
    board = board.resize((board.width * 2, board.height * 2), Image.LANCZOS)
    path = os.path.join(ROOT, "assets/textures", "face_yt_%s.png" % name)
    board.save(path)
    # 배치 수치: 설정화 픽셀 → 모델 단위(두 눈 사이 = EYE_GAP)
    s = EYE_GAP / (t["eyes"][1][0] - t["eyes"][0][0])
    ecx = (t["eyes"][0][0] + t["eyes"][1][0]) / 2
    ecy = t["eyes"][0][1] + 3
    info = {"w": (X1 - X0) * s, "h": (Y1 - Y0) * s,
            "eye_from_top": (ecy - Y0) * s, "cx": ((X0 + X1) / 2 - ecx) * s,
            "brow_top_from_eye": (ecy - t["brow"][1]) * s, "mouth_from_eye": ((my0 + my1) / 2 - ecy) * s}
    with open(path.replace(".png", ".json"), "w") as f:
        json.dump(info, f, indent=1)
    print(name, board.size, {k: round(v, 3) for k, v in info.items()})


if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "assets/textures"), exist_ok=True)
    for n, t in TYPES.items():
        make(n, t)


def robe_texture():
    """누더기 베옷 덧댄 자국(규칙: 덧댄 자국은 텍스처로만, D-345) — 바탕 베옷 색 + 짙은 네모 조각 · 밝은 바늘땀."""
    import random
    rnd = random.Random(7)
    W = 512
    im = Image.new("RGB", (W, W), (130, 112, 98))
    d = ImageDraw.Draw(im)
    for _ in range(4000):   # 거친 베 결
        x, y = rnd.randrange(W), rnd.randrange(W)
        c = rnd.randint(-10, 10)
        d.point((x, y), fill=(130 + c, 112 + c, 98 + c))
    for k in range(7):      # 덧댄 조각
        cx, cy = rnd.randint(40, W - 40), rnd.randint(40, W - 40)
        w, h = rnd.randint(36, 60), rnd.randint(30, 52)
        patch = Image.new("RGBA", (w + 16, h + 16), (0, 0, 0, 0))
        pd = ImageDraw.Draw(patch)
        pd.rectangle((8, 8, 8 + w, 8 + h), fill=(94, 78, 66, 255))
        for sx in range(10, w + 6, 7):   # 바늘땀(위아래)
            pd.line((sx, 4, sx + 3, 12), fill=(170, 150, 128, 255), width=2)
            pd.line((sx, h + 4, sx + 3, h + 12), fill=(170, 150, 128, 255), width=2)
        patch = patch.rotate(rnd.uniform(-25, 25), expand=True, resample=Image.BICUBIC)
        im.paste(patch, (cx - patch.width // 2, cy - patch.height // 2), patch)
    path = os.path.join(ROOT, "assets/textures", "yt_robe.png")
    im.save(path)
    print("ROBE", path)


if __name__ == "__main__":
    robe_texture()
