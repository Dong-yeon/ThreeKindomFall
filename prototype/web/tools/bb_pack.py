# B.B.Bits Three Kingdoms 캐릭터 → 게임용 아틀라스(src/c3b_bb_data.js, 커밋 금지)
# 입력: assets/three-kingdom/ 의 구매 파일 그대로(압축 파일은 풀지 않아도 됨)
#   - [Resource]A005-Hero Characters for Three Kingdoms.zip  (Hero Characters part 5: 시트 2장)
#   - NPC Characters-1.png                                      (NPC Characters part 1, 무료)
# 원본 576x768 = 192x256 픽셀아트를 3배 확대한 것. 한 칸 16x32, 캐릭터 8명(4x2) x 3프레임 x 4방향(아래·왼·오·위)
# 출력: 캐릭터마다 64x128 (열 = 아래·위·왼·오, 행 = 걷기 프레임 [1,0,1,2])
# 라이선스: 게임에 포함해 배포만 가능. 원본/변환 파일을 따로 공유·커밋하지 말 것.
import json, base64, io, os, sys, zipfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
ASSET = os.path.join(ROOT, 'assets', 'three-kingdom')
OUT = os.path.join(HERE, '..', 'src', 'c3b_bb_data.js')
HERO_ZIP = os.path.join(ASSET, '[Resource]A005-Hero Characters for Three Kingdoms.zip')
NPC1 = os.path.join(ASSET, 'NPC Characters-1.png')

def from_zip(zp, name):
    with zipfile.ZipFile(zp) as z:
        n = next(x for x in z.namelist() if x.endswith(name))
        return Image.open(io.BytesIO(z.read(n)))

for p in (HERO_ZIP, NPC1):
    if not os.path.exists(p):
        sys.exit('없음: ' + p)
src = {'h1': from_zip(HERO_ZIP, 'Hero Characters-1.png'), 'h2': from_zip(HERO_ZIP, 'Hero Characters-2.png'), 'n1': Image.open(NPC1)}
sheets = {k: v.convert('RGBA').resize((192, 256), Image.NEAREST) for k, v in src.items()}

def hx(h): return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))

# key: (sheet, char 0~7 = A~H, recolor map)
CAST = {
    'bb_gy':    ('h1', 4, {}),                                   # 관우(녹포·초록 투구)
    'bb_gyI':   ('h1', 5, {}),                                   # 관우(철갑·은 투구)
    'bb_gyG':   ('h1', 4, {'#0e3e12': '#5a3a08', '#38741a': '#dd8c00', '#dd8c00': '#fbc800', '#fbc800': '#fff0a0'}),  # 관우(금룡포)
    'bb_lb':    ('h1', 2, {}),                                   # 유비
    'bb_zf':    ('h1', 7, {}),                                   # 장비
    'bb_zj':    ('h1', 3, {}),                                   # 장각(황색 도포)
    'bb_mil':   ('h1', 0, {'#43573f': '#2c5a30', '#92a381': '#5a9a4a'}),                                   # 아군 의용병(초록 옷)
    'bb_ytb':   ('h1', 0, {'#492917': '#8a6a10', '#97530f': '#e8c040', '#43573f': '#6a5230', '#92a381': '#b89868'}),  # 황건병(노란 삿갓)
    'bb_ytarch':('n1', 3, {'#492917': '#8a6a10', '#97530f': '#e8c040', '#0b0f30': '#2a1a08', '#131b54': '#5a3a18'}), # 황건 궁수
    'bb_ytbig': ('n1', 7, {'#353234': '#c89a30', '#eae6da': '#f0d878', '#cdbfb3': '#c8a850'}),                     # 황건 역사(노란 두건)
    'bb_cyz':   ('h2', 6, {'#aa2c1e': '#b88a10', '#f66d1e': '#f0c830', '#480e55': '#4a3010', '#652bbc': '#8a6a20'}),  # 정원지(황건 장수)
    'bb_n1':    ('n1', 0, {}), 'bb_n2': ('n1', 4, {}), 'bb_n3': ('n1', 6, {}), 'bb_n4': ('n1', 1, {}),               # 마을 사람
}
SRC_ROW = {'down': 0, 'left': 1, 'right': 2, 'up': 3}
DIRS = ['down', 'up', 'left', 'right']
FRAMES = [1, 0, 1, 2]

def cell(sh, ch, d, f):
    x0 = (ch % 4) * 48 + FRAMES[f] * 16; y0 = (ch // 4) * 128 + SRC_ROW[d] * 32
    return sheets[sh].crop((x0, y0, x0 + 16, y0 + 32))

def recolor(im, mp):
    if not mp: return im
    M = {hx(a): hx(b) for a, b in mp.items()}; px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] and p[:3] in M: px[x, y] = M[p[:3]] + (p[3],)
    return im

PER = 8; keys = list(CAST); W = PER * 64; H = ((len(keys) + PER - 1) // PER) * 128
atlas = Image.new('RGBA', (W, H), (0, 0, 0, 0)); meta = {}
for n, k in enumerate(keys):
    sh, ch, mp = CAST[k]; ox, oy = (n % PER) * 64, (n // PER) * 128
    for c, d in enumerate(DIRS):
        for r in range(4): atlas.paste(recolor(cell(sh, ch, d, r).copy(), mp), (ox + c * 16, oy + r * 32))
    meta[k] = {'x': ox, 'y': oy}
buf = io.BytesIO(); atlas.save(buf, 'PNG', optimize=True)
js = '  // ═════════ B.B.Bits Three Kingdoms 캐릭터(구매 에셋 — 게임 안에서만 사용, 파일 단독 배포 금지) ═════════\n'
js += '  const BB = ' + json.dumps({'img': 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode(), 'meta': meta}) + ';\n'
with open(OUT, 'w', encoding='utf-8') as f:
    f.write(js)
print('bb atlas', atlas.size, 'KB', len(buf.getvalue()) // 1024, 'keys', len(keys), '->', os.path.normpath(OUT))
