# USB로 연결된 Android 기기의 Chrome 탭 콘솔(console.log)을 PC에서 읽는다 — 웹 빌드의 봇 성능 측정([perf])을 기기에서 재려고.
# adb로 Chrome 디버깅 소켓을 PC 포트로 잇고(adb forward), DevTools 프로토콜(웹소켓)로 탭에 붙어 콘솔 메시지를 출력한다.
# 실행: py -3 godot/tools/web_console.py --url perf.html [--match "\[perf\]|\[result\]"] [--timeout 600]
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--url', default='perf.html', help='붙을 탭 주소에 들어 있는 글')
    ap.add_argument('--match', default=r'\[perf\]|\[result\]|\[bot\]|ERROR')
    ap.add_argument('--timeout', type=float, default=600)
    ap.add_argument('--until', default=r'\[result\]', help='이 글이 나오면 끝냄')
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
