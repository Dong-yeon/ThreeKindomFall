# USB로 연결된 Android 기기의 Chrome 탭 콘솔(console.log)을 PC에서 읽는다 — 웹 빌드의 봇 성능 측정([perf])을 기기에서 재려고.
# adb로 Chrome 디버깅 소켓을 PC 포트로 잇고(adb forward), DevTools 프로토콜(웹소켓)로 탭에 붙어 콘솔 메시지를 출력한다.
# 실행: py -3 godot/tools/web_console.py --url perf.html [--match "\[perf\]|\[result\]"] [--timeout 600]
#   CPU 프로파일: --profile 15 --after 40 → 40초 뒤 15초 동안 표본을 모아 함수별 자기 시간 위 40개(함수 이름은 디버그 웹 빌드에서 보임)
#   기기 Chrome에서 그 주소가 열려 있어야 함(adb reverse로 PC 서버를 localhost로 보이게 하면 HTTPS가 필요 없음).
import argparse, base64, json, os, re, socket, struct, subprocess, sys, time, urllib.request

PORT = 9333


def ws_connect(url):
    m = re.match(r'ws://([^/:]+):(\d+)(/.*)', url)
    host, port, path = m.group(1), int(m.group(2)), m.group(3)
    s = socket.create_connection((host, port))
    key = base64.b64encode(os.urandom(16)).decode()
    s.sendall(('GET %s HTTP/1.1\r\nHost: %s:%d\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n'
               'Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n' % (path, host, port, key)).encode())
    buf = b''
    while b'\r\n\r\n' not in buf:
        buf += s.recv(4096)
    return s, buf.split(b'\r\n\r\n', 1)[1]


def ws_send(s, text):
    data = text.encode()
    mask = os.urandom(4)
    head = bytes([0x81])
    n = len(data)
    if n < 126:
        head += bytes([0x80 | n])
    elif n < 65536:
        head += bytes([0x80 | 126]) + struct.pack('>H', n)
    else:
        head += bytes([0x80 | 127]) + struct.pack('>Q', n)
    s.sendall(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))


class Reader:
    def __init__(self, s, rest):
        self.s, self.buf = s, rest

    def _need(self, n):
        while len(self.buf) < n:
            chunk = self.s.recv(65536)
            if not chunk:
                raise EOFError
            self.buf += chunk
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def frame(self):
        b0, b1 = self._need(2)
        n = b1 & 0x7f
        if n == 126:
            n = struct.unpack('>H', self._need(2))[0]
        elif n == 127:
            n = struct.unpack('>Q', self._need(8))[0]
        return b0 & 0x0f, self._need(n)


def call(s, rd, mid, method, params=None):
    ws_send(s, json.dumps({'id': mid, 'method': method, 'params': params or {}}))
    while True:
        op, data = rd.frame()
        if op != 1:
            continue
        msg = json.loads(data)
        if msg.get('id') == mid:
            return msg.get('result', {})


def profile(s, rd, a):
    time.sleep(a.after)
    call(s, rd, 10, 'Profiler.enable')
    call(s, rd, 11, 'Profiler.setSamplingInterval', {'interval': 500})
    call(s, rd, 12, 'Profiler.start')
    time.sleep(a.profile)
    prof = call(s, rd, 13, 'Profiler.stop')['profile']
    total = sum(prof.get('timeDeltas', [])) / 1000.0
    self_ms = {}
    for n in prof['nodes']:
        cf = n['callFrame']
        name = cf.get('functionName') or '(%s)' % os.path.basename(cf.get('url', '')) or '(?)'
        self_ms[name] = self_ms.get(name, 0) + n.get('hitCount', 0)
    hits = sum(self_ms.values()) or 1
    print('프로파일 %.1f초 · 표본 %d' % (total / 1000.0, hits))
    top = sorted(self_ms.items(), key=lambda kv: -kv[1])[:40]
    for name, h in top:
        print('%5.1f%%  %s' % (h * 100.0 / hits, name[:110]))
    # 위 5개 함수를 부른 쪽(위로 3단계)
    byid = {n['id']: n for n in prof['nodes']}
    parent = {}
    for n in prof['nodes']:
        for c in n.get('children', []):
            parent[c] = n['id']
    def nm(n):
        cf = n['callFrame']
        return cf.get('functionName') or '(%s)' % os.path.basename(cf.get('url', ''))
    for name, _ in top[:5]:
        chains = {}
        for n in prof['nodes']:
            if nm(n) != name or not n.get('hitCount'):
                continue
            ch, cur = [], n['id']
            for _ in range(4):
                cur = parent.get(cur)
                if cur is None:
                    break
                ch.append(nm(byid[cur]))
            key = ' < '.join(ch)
            chains[key] = chains.get(key, 0) + n['hitCount']
        print('-- %s 를 부른 쪽:' % name)
        for k, h in sorted(chains.items(), key=lambda kv: -kv[1])[:4]:
            print('   %5.1f%%  %s' % (h * 100.0 / hits, k[:160]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--url', default='perf.html', help='붙을 탭 주소에 들어 있는 글')
    ap.add_argument('--match', default=r'\[perf\]|\[result\]|\[bot\]|ERROR')
    ap.add_argument('--timeout', type=float, default=600)
    ap.add_argument('--until', default=r'\[result\]', help='이 글이 나오면 끝냄')
    ap.add_argument('--profile', type=float, default=0, help='CPU 프로파일 초(0 = 안 함)')
    ap.add_argument('--after', type=float, default=30, help='프로파일 시작까지 기다릴 초')
    a = ap.parse_args()
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    subprocess.run(['adb', 'forward', 'tcp:%d' % PORT, 'localabstract:chrome_devtools_remote'], check=True, capture_output=True)
    tabs = json.load(urllib.request.urlopen('http://127.0.0.1:%d/json' % PORT))
    tab = next((t for t in tabs if a.url in t.get('url', '') and t.get('webSocketDebuggerUrl')), None)
    if tab is None:
        sys.exit('탭을 못 찾음(%s): %s' % (a.url, [t.get('url') for t in tabs]))
    s, rest = ws_connect(tab['webSocketDebuggerUrl'])
    ws_send(s, json.dumps({'id': 1, 'method': 'Runtime.enable'}))
    rd = Reader(s, rest)
    if a.profile > 0:
        profile(s, rd, a)
        subprocess.run(['adb', 'forward', '--remove', 'tcp:%d' % PORT], capture_output=True)
        return
    pat, until = re.compile(a.match), re.compile(a.until)
    t0 = time.time()
    s.settimeout(5)
    while time.time() - t0 < a.timeout:
        try:
            op, data = rd.frame()
        except socket.timeout:
            continue
        except EOFError:
            break
        if op != 1:
            continue
        msg = json.loads(data)
        if msg.get('method') != 'Runtime.consoleAPICalled':
            continue
        text = ' '.join(str(x.get('value', x.get('description', ''))) for x in msg['params']['args'])
        for line in text.splitlines():
            if pat.search(line):
                print(line, flush=True)
        if until.search(text):
            break
    subprocess.run(['adb', 'forward', '--remove', 'tcp:%d' % PORT], capture_output=True)


if __name__ == '__main__':
    main()
