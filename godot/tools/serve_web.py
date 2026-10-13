# 웹 빌드(godot/build/web)를 같은 Wi-Fi의 폰에서 열 수 있게 HTTPS로 서빙한다.
# Godot 웹은 보안 연결(HTTPS 또는 localhost)이 아니면 실행되지 않아서(Secure Context), IP로 열려면 HTTPS가 필요하다.
# 실행: py -3 godot/tools/serve_web.py [--port 8060]
#   처음엔 이 PC의 LAN IP를 넣은 자체 서명 인증서를 godot/build/cert/에 만든다(openssl, 커밋 안 함 — build/는 .gitignore).
#   폰 Safari에서 https://<PC IP>:<port> → '연결이 비공개가 아님' 경고 → 세부사항 보기 → '이 웹 사이트 방문'.
#   PC IP가 바뀌면 --new-cert로 다시 만든다. 외부에 올리지 않는다(LAN 테스트 전용).
import argparse, http.server, os, socket, ssl, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.abspath(os.path.join(HERE, '..', 'build', 'web'))
CERT_DIR = os.path.abspath(os.path.join(HERE, '..', 'build', 'cert'))


def lan_ip():
    # 바깥으로 나가는 경로의 내 주소(실제로 보내지는 않음)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('192.168.0.1', 9))
        return s.getsockname()[0]
    finally:
        s.close()


def make_cert(ip, crt, key):
    os.makedirs(CERT_DIR, exist_ok=True)
    subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '365',
                    '-keyout', key, '-out', crt, '-subj', '/CN=ThreeKingdomFall LAN test',
                    '-addext', 'subjectAltName=IP:%s,IP:127.0.0.1,DNS:localhost' % ip], check=True, capture_output=True)


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, '.wasm': 'application/wasm', '.pck': 'application/octet-stream'}

    def end_headers(self):
        # 빌드를 다시 하면 곧바로 새 파일을 받게
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', type=int, default=8060)
    ap.add_argument('--new-cert', action='store_true')
    a = ap.parse_args()
    if not os.path.exists(os.path.join(WEB, 'index.html')):
        sys.exit('웹 빌드가 없음: ' + WEB + ' (Godot에서 Web 프리셋으로 내보내기)')
    ip = lan_ip()
    crt, key = os.path.join(CERT_DIR, 'lan.crt'), os.path.join(CERT_DIR, 'lan.key')
    if a.new_cert or not os.path.exists(crt):
        make_cert(ip, crt, key)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(crt, key)
    os.chdir(WEB)
    srv = http.server.ThreadingHTTPServer(('0.0.0.0', a.port), Handler)
    srv.socket = ctx.wrap_socket(srv.socket, server_side=True)
    print('폰 Safari에서: https://%s:%d   (PC: https://localhost:%d)' % (ip, a.port, a.port), flush=True)
    srv.serve_forever()


if __name__ == '__main__':
    main()
