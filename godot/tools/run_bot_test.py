# 1장 자동 전투 테스트: Godot을 창 없이(headless) 띄워 봇(scripts/bot.gd)이 1장을 끝까지 진행하게 하고 결과를 표로 보여 준다.
# 판마다 클리어 여부 · 시간 · 처치 · 공적 레벨 · 채운 책략 칸 · 진화 수 · 오류, 그리고 칸 · 진화 · 고른 기록(레벨업 카드)을 출력.
# 탁현 마을(D-215): 습격 · 장수 도착 · 끝(구함 · 불탐) 시각과 동료(장비)의 처치 · 등무에게 준 피해 · 물러난 때.
# 실행: python godot/tools/run_bot_test.py [--seed 1] [--modes normal,god] [--max-time 900] [--late-village 초] [--godot <Godot 실행 파일>]
#   normal = 봇이 실제로 싸움(손맛·난이도 확인) / god = 장수 무적(진영 → 관문 → 정원지 → 장각까지 목표 흐름이 이어지는지)
# 판정: 오류가 하나라도 있거나 god가 클리어하지 못하면 실패(종료 코드 1). normal의 클리어 여부는 난이도 문제라 실패로 치지 않음.
# Godot 실행 파일: --godot > 환경 변수 GODOT > C:/Tools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe
# B.B.Bits 그림(assets/bb/)이 없어도 돈다(인물은 동그라미로 그려짐).
import argparse, os, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, '..'))
DEFAULT_GODOT = r'C:\Tools\Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
MODE_NAME = {'normal': '일반', 'god': '무적'}
STATUS_NAME = {'clear': '클리어', 'lose_hero': '실패(장수 쓰러짐)', 'lose_home': '실패(본진 함락)', 'lose_liubei': '실패(유비 쓰러짐)', 'lose_army': '실패(대군이 본진에 닿음)', 'timeout': '시간 초과'}
# 엔진이 끝날 때 내는 소리(오류 아님)
NOISE = ('Unreferenced static string', 'leaked at exit', 'PagedAllocator', 'ObjectDB instances leaked')


def fmt_t(s):
    s = int(float(s))
    return '%d:%02d' % (s // 60, s % 60)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--godot', default=os.environ.get('GODOT', DEFAULT_GODOT))
    ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--modes', default='normal,god')
    ap.add_argument('--max-time', type=float, default=900)
    ap.add_argument('--late-village', type=float, default=0, help='시험용(D-215): 마을 습격 뒤 이 초 동안 봇이 마을로 가지 않음(동료 혼자 버티는지)')
    ap.add_argument('--timeout', type=float, default=900, help='한 판에 기다릴 실제 시간(초)')
    a = ap.parse_args()
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    if not os.path.exists(a.godot):
        sys.exit('Godot 실행 파일이 없음: ' + a.godot + ' (--godot 또는 환경 변수 GODOT)')
    # 처음 받은 저장소면 가져오기(.godot/)부터
    if not os.path.isdir(os.path.join(PROJ, '.godot')):
        print('처음 실행: 에셋 가져오기 중…')
        subprocess.run([a.godot, '--path', PROJ, '--headless', '--import'], capture_output=True, timeout=600)
    modes = [m for m in a.modes.split(',') if m]
    procs = {}
    t0 = time.time()
    for m in modes:
        cmd = [a.godot, '--path', PROJ, '--headless', '--fixed-fps', '60', '--', '--bot', '--seed=%d' % a.seed, '--max-time=%g' % a.max_time]
        if m == 'god':
            cmd.append('--god')
        if a.late_village > 0:
            cmd.append('--late-village=%g' % a.late_village)
        procs[m] = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    rows, failed = [], False
    for m, p in procs.items():
        try:
            out, _ = p.communicate(timeout=a.timeout)
        except subprocess.TimeoutExpired:
            p.kill()
            out, _ = p.communicate()
        text = out.decode('utf-8', 'replace')
        res = None
        extra = {'slots': '-', 'evos': '-', 'picks': '-', 'phases': '-', 'events': '-', 'timeline': '-', 'evo_t': '-', 'army': '-', 'village': '-', 'hurt': '-', 'arena': '-', 'heals': '-', 'allies': '-', 'move': '-', 'small': '-', 'lb_hurt': '-', 'trade': '-'}
        logged, printed = [], []  # 봇의 Logger가 모은 것(파일:줄 포함) / 엔진 출력에서 찾은 것(봇이 붙기 전 오류도 잡힘)
        for line in text.splitlines():
            if line.startswith('[result]'):
                res = dict(kv.split('=', 1) for kv in line[len('[result]'):].split())
            elif line.startswith(('[slots]', '[evos]', '[picks]', '[phases]', '[events]', '[timeline]', '[evo_t]', '[army]', '[village]', '[hurt]', '[arena]', '[heals]', '[allies]', '[move]', '[small]', '[lb_hurt]', '[trade]')):
                tag, _, rest = line.partition(' ')
                extra[tag.strip('[]')] = rest.strip()
            elif line.startswith('[error]'):
                logged.append(line[len('[error]'):].strip())
            elif ('SCRIPT ERROR' in line or line.startswith('ERROR:')) and not any(n in line for n in NOISE):
                printed.append(line.strip())
        logged, printed = list(dict.fromkeys(logged)), list(dict.fromkeys(printed))
        # 같은 오류가 두 곳에 다 찍히므로 많은 쪽 수를 쓰고, 자세한 쪽(Logger)을 보여 줌
        errs = logged if len(logged) >= len(printed) else printed
        n_err = max(len(logged), len(printed), int(res['errors']) if res else 0)
        if res is None:
            res = {'status': 'crash', 'time': '0', 'kills': '-', 'max_combo': '-', 'cap': '-', 'hero_hp': '-', 'home': '-'}
            errs.append('결과 줄이 없음(멈춤 또는 강제 종료) — 마지막 출력: ' + ' / '.join(text.strip().splitlines()[-3:]))
            n_err += 1
        rows.append((m, res, n_err, errs, extra))
        if n_err or (m == 'god' and res['status'] != 'clear'):
            failed = True
    # 표
    print()
    print('1장 탁현 싸움 — 자동 전투 (seed %d, 판 시간 상한 %s, 실제 %.0f초)' % (a.seed, fmt_t(a.max_time), time.time() - t0))
    head = ['모드', '결과', '걸린 시간', '처치', '공적 Lv', '진화', '이동(px)', '멈춤%', '둘레 적', '분당 피격', '최저 체력', '구슬%', '점령', '오류']
    body = []
    for m, r, n_err, _, _ in rows:
        body.append([MODE_NAME.get(m, m), STATUS_NAME.get(r['status'], r['status']), fmt_t(r['time']), r['kills'], r.get('level', '-'),
                     r.get('evos', '-'), r.get('dist', '-'), r.get('still', '-'), r.get('near', '-'), r.get('hits_pm', '-'), r.get('min_hp', '-'), r.get('orbs', '-'), '%s/3' % r['cap'], str(n_err)])
    w = [max(len(x) for x in col) for col in zip(head, *body)]
    for row in [head] + body:
        print('  '.join(c.ljust(w[i]) for i, c in enumerate(row)))
    for m, r, n_err, errs, ex in rows:
        print()
        print('[%s] 판 길이 %s (%s)' % (MODE_NAME.get(m, m), fmt_t(r['time']), STATUS_NAME.get(r['status'], r['status'])))
        print('  탁현 마을: %s' % ex['village'])
        print('  받은 피해: %s' % ex['hurt'])
        print('  울타리: %s' % ex['arena'])
        print('  적장 거래: %s' % ex['trade'])
        print('  회복: %s' % ex['heals'])
        print('  작은 사건: %s' % ex['small'])
        print('  유비 피해 · 무리: %s' % ex['lb_hurt'])
        print('  대군: %s' % ex['army'])
        print('  사건: %s' % ex['events'])
        print('  시각별 Lv: %s' % ex['timeline'])
        print('  진화 시각: %s' % ex['evo_t'])
        print('  구간: %s' % ex['phases'])
        print('  칸: %s' % ex['slots'])
        print('  이동: %s' % ex['move'])
        print('  아군(30초마다): %s' % ex['allies'])
        print('  진화: %s' % ex['evos'])
        print('  고른 기록(%s번): %s' % (r.get('picks', '-'), ex['picks']))
        if errs:
            print('\n[%s] 오류 %d건' % (MODE_NAME.get(m, m), n_err))
            for e in errs[:20]:
                print('  - ' + e)
    print('\n판정: ' + ('실패' if failed else '통과') + ' (오류 0 · 무적 모드 클리어가 기준)')
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
