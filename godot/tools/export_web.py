# 웹 빌드(godot/build/web)를 만든다. 사람 플레이 기록(D-221)이 어느 커밋으로 한 판인지 알 수 있게
# 내보내기 전에 지금 커밋 해시를 godot/build_info.txt에 적는다(커밋 안 함 — .gitignore, 내보내기 프리셋의 include_filter로 빌드에 들어감).
# 실행: py -3 godot/tools/export_web.py [--godot <경로>]   (그 뒤 serve_web.py로 LAN HTTPS 서빙, 폰에서 https://<PC IP>:8060/?playtest=1)
# Godot 실행 파일: --godot > 환경 변수 GODOT > C:/Tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe
import argparse, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, '..'))
DEFAULT_GODOT = r'C:\Tools\Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'


def git(*args):
    return subprocess.run(['git', '-C', PROJ] + list(args), capture_output=True, text=True).stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--godot', default=os.environ.get('GODOT', DEFAULT_GODOT))
    a = ap.parse_args()
    h = git('rev-parse', '--short', 'HEAD') or 'unknown'
    if git('status', '--porcelain', '--untracked-files=no'):
        h += '-dirty'
    open(os.path.join(PROJ, 'build_info.txt'), 'w', encoding='utf-8').write(h + '\n')
    os.makedirs(os.path.join(PROJ, 'build', 'web'), exist_ok=True)
    r = subprocess.run([a.godot, '--path', PROJ, '--headless', '--export-release', 'Web', 'build/web/index.html'])
    print('커밋 %s · 내보내기 %s' % (h, '완료' if r.returncode == 0 else '실패(%d)' % r.returncode))
    sys.exit(r.returncode)


if __name__ == '__main__':
    main()
