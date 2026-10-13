# 정원지 대군 조정 확인용: run_bot_test.py를 seed 여러 개로 돌려 대군 지표를 모은다.
# 실행: python godot/tools/army_sweep.py --seeds 1-10 --out godot/out/sweep_new [--proj <godot 폴더>] [--par 5]
#   seed마다 원본 출력(seedN.txt)을 남기고, 끝에 표: 판 결과 · 길이 · 대군과 처음 만난 곳(본진까지 px) · 대군전 길이 · 부장 · 정원지 처치 시간.
# 이미 있는 seedN.txt는 다시 돌리지 않음(--redo로 다시).
import argparse, os, re, subprocess, sys, statistics
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))


def tsec(s):
    m, ss = s.split(':')
    return int(m) * 60 + int(ss)


def run(seed, out, proj, redo):
    path = os.path.join(out, 'seed%d.txt' % seed)
    if os.path.exists(path) and not redo:
        return
    cmd = [sys.executable, '-X', 'utf8', os.path.join(proj, 'tools', 'run_bot_test.py'), '--seed', str(seed)]
    r = subprocess.run(cmd, capture_output=True)
    open(path, 'wb').write(r.stdout)


def parse(text):
    rows = {}
    mode = None
    for line in text.splitlines():
        m = re.match(r'^(일반|무적)\s+(\S+(?:\([^)]*\))?)\s+(\d+:\d\d)', line)
        if m:
            rows.setdefault(m.group(1), {})['status'] = m.group(2)
            rows[m.group(1)]['len'] = tsec(m.group(3))
        m = re.match(r'^\[(일반|무적)\] 판 길이', line)
        if m:
            mode = m.group(1)
        if mode and line.startswith('  사건: '):
            ev = []
            for part in line[len('  사건: '):].split(' | ')[0].split(' · '):
                mm = re.match(r'(\d+:\d\d) (.+?)\(\+\d+:\d\d\)$', part.strip())
                if mm:
                    ev.append((tsec(mm.group(1)), mm.group(2)))
            rows[mode]['ev'] = ev
        if mode and line.startswith('  대군: '):
            rows[mode]['army'] = line[len('  대군: '):]
        if mode and line.startswith('  울타리: '):
            rows[mode]['arena'] = line[len('  울타리: '):]
        if mode and line.startswith('  회복: '):
            rows[mode]['heals'] = line[len('  회복: '):]
        if mode and line.startswith('  받은 피해: ') and ' · 마지막 ' in line:
            rows[mode]['last'] = line.rsplit(' · 마지막 ', 1)[1].strip()
        if mode and line.startswith('  받은 피해: '):
            hurt = {}
            for part in line[len('  받은 피해: '):].split(' · ')[1:]:
                mm = re.match(r'(.+) (\d+)\(\d+%\)$', part.strip())
                if mm:
                    hurt[mm.group(1)] = int(mm.group(2))
            rows[mode]['hurt'] = hurt
    return rows


def metrics(r):
    ev = r.get('ev', [])
    met = [(t, n) for t, n in ev if '과 만남' in n or '와 만남' in n]
    first_d = None
    am = re.findall(r'만남\(본진까지 (\d+)px\)', r.get('army', ''))
    if am:
        first_d = int(am[0])
    start = next((t for t, n in ev if n == '정원지 대군 출진'), None)
    end = next((t for t, n in ev if n == '정원지 격파'), None)
    kills = []
    spawn = {}
    for t, n in ev:
        m = re.match(r'(.+?)(?:과|와) 만남', n)
        if m:
            spawn[m.group(1)] = t
        m = re.match(r'(.+?) 격파$', n)
        if m and m.group(1) in spawn:
            kills.append((m.group(1), t - spawn[m.group(1)]))
    cyz_on = next((t for t, n in ev if n == '정원지 등장'), None)
    if end is not None and cyz_on is not None:
        kills.append(('정원지', end - cyz_on))
    # 곁에서 싸운 시간(봇이 [army]에 적음)이 있으면 그것을 처치 시간으로 씀(만남 → 격파는 지나가다 스친 시간까지 들어감)
    army = r.get('army', '')
    eng = re.findall(r'(\S+) \d+:\d\d 만남\(본진까지 \d+px\) → \d+:\d\d 격파\(본진까지 (\d+)px · 곁에서 싸운 (\d+)s\)', army)
    kill_d = [int(d) for _, d, _ in eng]
    if eng:
        kills = [(n, int(e)) for n, _, e in eng]
        mz = re.search(r'정원지 격파\(곁에서 싸운 (\d+)s\)', army)
        if mz:
            kills.append(('정원지', int(mz.group(1))))
    first_met = met[0][0] if met else None
    return {'kill_d': kill_d if eng else [], 'first_d': first_d, 'war': (end - first_met) if (end is not None and first_met is not None) else None,
            'start': start, 'kills': kills}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--seeds', default='1-10')
    ap.add_argument('--out', required=True)
    ap.add_argument('--proj', default=os.path.abspath(os.path.join(HERE, '..')))
    ap.add_argument('--par', type=int, default=5)
    ap.add_argument('--redo', action='store_true')
    a = ap.parse_args()
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    lo, _, hi = a.seeds.partition('-')
    seeds = list(range(int(lo), int(hi or lo) + 1))
    os.makedirs(a.out, exist_ok=True)
    with ThreadPoolExecutor(a.par) as ex:
        list(ex.map(lambda s: run(s, a.out, a.proj, a.redo), seeds))
    agg = {}
    print('seed 모드  결과              길이   출진   첫 만남(본진까지)  대군전   처치 시간(곁에서 싸운 시간, 없으면 만남→격파)  부장 격파 자리(본진까지)')
    for s in seeds:
        rows = parse(open(os.path.join(a.out, 'seed%d.txt' % s), encoding='utf-8', errors='replace').read())
        for mode in ('일반', '무적'):
            r = rows.get(mode)
            if not r:
                print('%-4d %s  (없음)' % (s, mode))
                continue
            m = metrics(r)
            g = agg.setdefault(mode, {'len': [], 'd': [], 'kd': [], 'war': [], 'kill': [], 'dead': [], 'clear': 0})
            g['kd'] += m['kill_d']
            for dur, dist in re.findall(r'\S+ \d+:\d\d\((\d+)s · 본진까지 (\d+)px\)', r.get('arena', '')):
                g.setdefault('ar', []).append(int(dur))
                g.setdefault('ard', []).append(int(dist))
            for k, v in re.findall(r'(물체|부장|처치|마을|카드) (\d+)', r.get('heals', '')):
                g.setdefault('heal', {})[k] = g.setdefault('heal', {}).get(k, 0) + int(v)
            if r['status'] != '클리어':
                g.setdefault('why', []).append('%d %s(마지막 피해 %s)' % (s, r['status'], r.get('last', '-')))
            hs = g.setdefault('hurt', {})
            for k, v in r.get('hurt', {}).items():
                hs[k] = hs.get(k, 0) + v
            g['len'].append(r['len'])
            if r['status'] == '클리어':
                g['clear'] += 1
            else:
                g['dead'].append('%d %s' % (s, r['status']))
            if m['first_d'] is not None:
                g['d'].append(m['first_d'])
            if m['war'] is not None:
                g['war'].append(m['war'])
            g['kill'] += [k for _, k in m['kills']]
            print('%-4d %s  %-16s %-6s %-6s %-18s %-8s %s' % (s, mode, r['status'], '%d:%02d' % divmod(r['len'], 60),
                  '%d:%02d' % divmod(m['start'], 60) if m['start'] is not None else '-',
                  '%dpx' % m['first_d'] if m['first_d'] is not None else '-',
                  '%ds' % m['war'] if m['war'] is not None else '-', ' · '.join('%s %ds' % k for k in m['kills']) or '-') + '   ' + (' · '.join('%dpx' % d for d in m['kill_d']) or '-'))
    print()
    for mode, g in agg.items():
        def st(v):
            return '%d~%d (중앙 %d)' % (min(v), max(v), statistics.median(v)) if v else '-'
        print('[%s] 클리어 %d/%d · 판 길이 %s초 · 첫 만남 본진까지 %spx · 대군전 %s초 · 장수 처치 %s초(30초 넘음 %d/%d) · 실패: %s' % (
            mode, g['clear'], len(g['len']), st(g['len']), st(g['d']), st(g['war']), st(g['kill']),
            sum(1 for k in g['kill'] if k > 30), len(g['kill']), ', '.join(g['dead']) or '없음'))
        if g['d']:
            bins = {}
            for d in g['d']:
                bins[d // 300 * 300] = bins.get(d // 300 * 300, 0) + 1
            print('    첫 만남 분포(300px 칸): ' + ' · '.join('%d~%d: %d' % (k, k + 299, v) for k, v in sorted(bins.items())))
        if g.get('ar'):
            print('    울타리 %d번 · 걸린 시간 %s초(20~40초 %d/%d) · 중심 본진까지 %spx' % (len(g['ar']), st(g['ar']), sum(1 for v in g['ar'] if 20 <= v <= 40), len(g['ar']), st(g['ard'])))
        if g.get('heal'):
            print('    회복(10판 합): ' + ' · '.join('%s %d' % kv for kv in sorted(g['heal'].items(), key=lambda kv: -kv[1])))
        if g.get('why'):
            print('    실패 원인: ' + ' / '.join(g['why']))
        if g.get('hurt'):
            tot = sum(g['hurt'].values())
            ranged = sum(v for k, v in g['hurt'].items() if '화살' in k)
            dash = sum(v for k, v in g['hurt'].items() if '돌진' in k)
            print('    받은 피해(10판 합 %d): 원거리 %d%% · 돌진 %d%% | ' % (tot, round(ranged * 100 / max(tot, 1)), round(dash * 100 / max(tot, 1)))
                  + ' · '.join('%s %d%%' % (k, round(v * 100 / max(tot, 1))) for k, v in sorted(g['hurt'].items(), key=lambda kv: -kv[1])))
        if g['kd']:
            bins = {}
            for d in g['kd']:
                bins[d // 300 * 300] = bins.get(d // 300 * 300, 0) + 1
            print('    부장 격파 자리 분포(300px 칸): ' + ' · '.join('%d~%d: %d' % (k, k + 299, v) for k, v in sorted(bins.items())))


if __name__ == '__main__':
    main()
