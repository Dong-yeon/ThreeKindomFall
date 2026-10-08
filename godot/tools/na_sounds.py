# Ninja Adventure(CC0, pixel-boy · AAA) 효과음 · 음악 → godot/assets/sfx/<키>.mp3 (CC0라 커밋함)
# 지금은 웹판이 이미 골라 줄여 둔 소리(prototype/web/src/c3_na_data.js의 NA.aud, MP3 22kHz 모노)를 그대로 꺼낸다.
# 원본 팩(assets/ninja-adventure/)을 풀어 두면 원본 WAV/OGG로 바꿔 끼울 수 있음(Godot은 WAV · OGG · MP3를 바로 가져옴).
# 실행: python godot/tools/na_sounds.py
import base64, json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
SRC = os.path.join(ROOT, 'prototype', 'web', 'src', 'c3_na_data.js')
OUT = os.path.join(HERE, '..', 'assets', 'sfx')
# 전장에서 쓰는 것만(웹판 이름 그대로). 원본 파일: build_assets.py의 sounds · music
KEEP = ['shoot', 'hit', 'hurt', 'kill', 'slam', 'heal', 'alert', 'accept', 'win', 'lose', 'fight']


def main():
    s = open(SRC, encoding='utf-8').read()
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for m in re.finditer(r'"([a-zA-Z0-9_]+)":\s*"data:audio/mpeg;base64,([A-Za-z0-9+/=]+)"', s):
        k = m.group(1)
        if k not in KEEP:
            continue
        with open(os.path.join(OUT, k + '.mp3'), 'wb') as f:
            f.write(base64.b64decode(m.group(2)))
        n += 1
    with open(os.path.join(OUT, 'CREDITS.txt'), 'w', encoding='utf-8') as f:
        f.write('Ninja Adventure Asset Pack (pixel-boy, AAA) — CC0 1.0. https://pixel-boy.itch.io/ninja-adventure-asset-pack\n'
                '웹 프로토타입이 원본에서 골라 MP3로 줄인 것(prototype/web/tools/build_assets.py).\n')
    print('sounds', n, '->', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
