# 웹 프로토타입 빌드: src/의 조각들을 순서대로 이어 dist/index.html 한 파일로 만든다.
# 실행: python prototype/web/build.py  (repo 어디서 실행해도 됨)
# - src/c3b_bb_data.js(B.B.Bits 캐릭터)가 없으면 tools/bb_pack.py로 assets/three-kingdom/에서 만든다.
#   에셋이 없으면 이 조각을 빼고 빌드한다(그때는 Ninja Adventure 그림으로 대신 나옴).
# - dist/index.html에는 구매 에셋이 들어가므로 커밋하지 않는다(.gitignore).
import os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'src')
DIST = os.path.join(HERE, 'dist')
PARTS = ['b_core.js', 'c_tiles.js', 'd_town.js', 'c3_na_data.js', 'c3b_bb_data.js', 'c3_ninja.js', 'e_arena.js', 'f_ai.js', 'g_ui.js',
         'i_story.js', 'j_rope.js', 'k_army.js', 'm_musou.js', 'n_field.js', 'p_world.js', 'h_boot.js']

bb = os.path.join(SRC, 'c3b_bb_data.js')
if not os.path.exists(bb):
    r = subprocess.run([sys.executable, os.path.join(HERE, 'tools', 'bb_pack.py')])
    if r.returncode != 0 or not os.path.exists(bb):
        print('경고: B.B.Bits 캐릭터 데이터를 만들지 못해 빼고 빌드합니다(assets/three-kingdom/ 확인).')

def read(p):
    with open(os.path.join(SRC, p), encoding='utf-8') as f:
        return f.read()

parts = [p for p in PARTS if os.path.exists(os.path.join(SRC, p))]
html = read('a.html') + '<script>\n' + ''.join(read(p) for p in parts) + '</script>\n'
os.makedirs(DIST, exist_ok=True)
out = os.path.join(DIST, 'index.html')
with open(out, 'w', encoding='utf-8') as f:
    f.write(html)
print(out, len(html), 'bytes', '' if 'c3b_bb_data.js' in parts else '(B.B.Bits 없음)')
