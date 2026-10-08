# B.B.Bits Three Kingdoms 캐릭터 → Godot용 시트(godot/assets/bb/<키>.png, 커밋 금지 — .gitignore에 있음)
# 입력: assets/three-kingdom/ 의 구매 파일 그대로(압축 파일은 풀지 않아도 됨)
#   - [Resource]A005-Hero Characters for Three Kingdoms.zip  (Hero Characters part 5: 시트 2장)
#   - NPC Characters-1.png                                      (NPC Characters part 1)
# 원본 576x768 = 192x256 픽셀아트를 3배 확대한 것 → 1배로 줄여 씀. 캐릭터 8명(4x2) x 3프레임 x 4방향
# 출력: 캐릭터마다 48x128 = 16x32 칸, 가로 3프레임 x 세로 4방향(아래·왼·오·위). 원본 배치 그대로, 색만 바꿈
# 실행: python godot/tools/bb_export.py  → 그다음 Godot 에디터를 열거나 --headless --import로 가져오기
# 라이선스: 게임에 포함해 배포만 가능. 원본/변환 파일을 따로 공유·커밋하지 말 것.
import io, os, sys, zipfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
ASSET = os.path.join(ROOT, 'assets', 'three-kingdom')
OUT = os.path.join(HERE, '..', 'assets', 'bb')
HERO_ZIP = os.path.join(ASSET, '[Resource]A005-Hero Characters for Three Kingdoms.zip')
NPC1 = os.path.join(ASSET, 'NPC Characters-1.png')


def from_zip(zp, name):
    with zipfile.ZipFile(zp) as z:
        n = next(x for x in z.namelist() if x.endswith(name))
        return Image.open(io.BytesIO(z.read(n)))


def hx(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))


# 키: (시트, 캐릭터 0~7, 색 바꾸기). 웹판 bb_pack.py와 같은 색 + 황건 돌격병(D-170: 말 탄 기병 대신)
CAST = {
    'gy':      ('h1', 4, {}),                                   # 관우(녹포·초록 투구)
    'gy_iron': ('h1', 5, {}),                                   # 관우(철갑·은 투구)
    'gy_gold': ('h1', 4, {'#0e3e12': '#5a3a08', '#38741a': '#dd8c00', '#dd8c00': '#fbc800', '#fbc800': '#fff0a0'}),  # 관우(금룡포)
    'lb':      ('h1', 2, {}),                                   # 유비
    'zf':      ('h1', 7, {}),                                   # 장비
    'zj':      ('h1', 3, {}),                                   # 장각(황색 도포)
    'mil':     ('h1', 0, {'#43573f': '#2c5a30', '#92a381': '#5a9a4a'}),                                   # 아군 의용병(초록 옷)
    'ytb':     ('h1', 0, {'#492917': '#8a6a10', '#97530f': '#e8c040', '#43573f': '#6a5230', '#92a381': '#b89868'}),  # 황건병(노란 삿갓)
    'ytarch':  ('n1', 3, {'#492917': '#8a6a10', '#97530f': '#e8c040', '#0b0f30': '#2a1a08', '#131b54': '#5a3a18'}),  # 황건 궁수
    'ytdash':  ('n1', 1, {'#492917': '#8a6a10', '#97530f': '#e8c040', '#1d1b1c': '#5a1a10', '#353234': '#9a3020'}),  # 황건 돌격병(붉은 옷)
    'ytbig':   ('n1', 7, {'#353234': '#c89a30', '#eae6da': '#f0d878', '#cdbfb3': '#c8a850'}),                     # 황건 역사(노란 두건)
    'cyz':     ('h2', 6, {'#aa2c1e': '#b88a10', '#f66d1e': '#f0c830', '#480e55': '#4a3010', '#652bbc': '#8a6a20'}),  # 정원지(황건 장수)
}


def recolor(im, mp):
    if not mp:
        return im
    M = {hx(a): hx(b) for a, b in mp.items()}
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] and p[:3] in M:
                px[x, y] = M[p[:3]] + (p[3],)
    return im


def main():
    for p in (HERO_ZIP, NPC1):
        if not os.path.exists(p):
            sys.exit('없음: ' + p)
    src = {'h1': from_zip(HERO_ZIP, 'Hero Characters-1.png'), 'h2': from_zip(HERO_ZIP, 'Hero Characters-2.png'), 'n1': Image.open(NPC1)}
    sheets = {k: v.convert('RGBA').resize((192, 256), Image.NEAREST) for k, v in src.items()}
    os.makedirs(OUT, exist_ok=True)
    for key, (sh, ch, mp) in CAST.items():
        x0, y0 = (ch % 4) * 48, (ch // 4) * 128
        im = recolor(sheets[sh].crop((x0, y0, x0 + 48, y0 + 128)).copy(), mp)
        im.save(os.path.join(OUT, key + '.png'), optimize=True)
    print('bb sheets', len(CAST), '->', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
