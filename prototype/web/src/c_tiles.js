  // ═════════ 도트 타일 — 임시(코드로 그림). Kenney 타일로 바꿀 때는 TILE[...]·SPR 만 갈아 끼우면 됨 ═════════
  const TS = 16;
  function mk(w, h, fn) { const c = document.createElement('canvas'); c.width = w; c.height = h; const g = c.getContext('2d'); g.imageSmoothingEnabled = false; fn(g); return c; }
  const R = (g, x, y, w, h, col) => { g.fillStyle = col; g.fillRect(x, y, w, h); };
  // 고정 난수(타일 무늬가 매번 같게)
  function seeded(s) { return () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; }; }
  function grassBase(g, s) { const r = seeded(s); R(g, 0, 0, 16, 16, '#5f9a4a'); for (let i = 0; i < 14; i++) R(g, Math.floor(r() * 16), Math.floor(r() * 16), 1, 1, r() < 0.5 ? '#6faa55' : '#518a3e'); for (let i = 0; i < 3; i++) { const x = Math.floor(r() * 14), y = Math.floor(r() * 13) + 2; R(g, x, y, 1, 2, '#78b45c'); R(g, x + 1, y - 1, 1, 2, '#78b45c'); } }
  const TILE = {};
  TILE.grass = [0, 1, 2, 3].map((s) => mk(16, 16, (g) => grassBase(g, 11 + s * 7)));
  TILE.path = [0, 1].map((s) => mk(16, 16, (g) => { const r = seeded(91 + s * 13); R(g, 0, 0, 16, 16, '#d8c08a'); for (let i = 0; i < 12; i++) R(g, Math.floor(r() * 16), Math.floor(r() * 16), 1, 1, r() < 0.6 ? '#c8ac74' : '#e6d29e'); }));
  TILE.tree = mk(16, 16, (g) => { grassBase(g, 5); R(g, 6, 11, 4, 5, '#6a4a2a'); R(g, 7, 11, 1, 5, '#7e5a34'); R(g, 2, 2, 12, 10, '#2f6a34'); R(g, 1, 4, 14, 6, '#2f6a34'); R(g, 3, 1, 10, 1, '#2f6a34'); R(g, 4, 3, 5, 3, '#4a8a44'); R(g, 3, 5, 3, 2, '#4a8a44'); R(g, 10, 7, 3, 2, '#25562a'); R(g, 4, 10, 8, 1, '#25562a'); });
  TILE.water = [0, 1].map((f) => mk(16, 16, (g) => { R(g, 0, 0, 16, 16, '#4a7ab8'); for (let y = 2 + f * 2; y < 16; y += 5) { R(g, (y * 3 + f * 4) % 10, y, 5, 1, '#7aa4d8'); } R(g, (5 + f * 6) % 14, 9, 2, 1, '#cfe2f4'); }));
  TILE.flower = mk(16, 16, (g) => { grassBase(g, 41); for (const [x, y, c] of [[3, 4, '#e86a6a'], [10, 3, '#f2d24a'], [6, 10, '#f4f0e8'], [12, 11, '#e86a6a'], [2, 12, '#f2d24a']]) { R(g, x, y, 2, 2, c); R(g, x, y + 2, 1, 1, '#3e7a34'); } });
  // 책 덤불: 떠도는 이야기가 숨어 있는 곳(포켓몬의 풀숲 자리) — 키 큰 풀 사이로 낡은 책등이 보임
  TILE.bush = [0, 1].map((f) => mk(16, 16, (g) => { R(g, 0, 0, 16, 16, '#3f7a3a'); const r = seeded(7 + f); for (let x = 0; x < 16; x += 3) { const h = 5 + Math.floor(r() * 4); R(g, x, 16 - h - 4, 2, h, '#2e6a2e'); R(g, x + 1, 16 - h - 5 + f, 1, 2, '#56964a'); } R(g, 3, 9, 2, 6, '#b8432f'); R(g, 5, 10, 2, 5, '#e8dcb0'); R(g, 10, 8, 2, 7, '#4a6a9a'); R(g, 12, 10, 2, 5, '#c8a050'); R(g, 0, 15, 16, 1, '#2a5a2a'); }));
  TILE.fence = mk(16, 16, (g) => { grassBase(g, 23); R(g, 0, 6, 16, 2, '#8a6a3a'); R(g, 0, 11, 16, 2, '#8a6a3a'); R(g, 2, 4, 2, 11, '#6a4a2a'); R(g, 12, 4, 2, 11, '#6a4a2a'); });
  TILE.sign = mk(16, 16, (g) => { R(g, 0, 0, 16, 16, '#d8c08a'); R(g, 7, 9, 2, 6, '#6a4a2a'); R(g, 2, 3, 12, 7, '#8a6a3a'); R(g, 3, 4, 10, 5, '#b89a5a'); R(g, 4, 5, 8, 1, '#6a4a2a'); R(g, 4, 7, 6, 1, '#6a4a2a'); });
  // 건물 — 지붕·벽·창·문. 문 칸은 지도에서 'door'
  function building(w, h, roof, label, doors) {
    return mk(w * 16, h * 16, (g) => {
      const W = w * 16, H = h * 16, rh = Math.floor(H * 0.45);
      R(g, 0, rh, W, H - rh, '#e8dcc0'); R(g, 0, H - 3, W, 3, '#b8a888'); for (let x = 0; x < W; x += 8) R(g, x, rh, 1, H - rh, '#d8ccb0');
      R(g, -2, 0, W + 4, rh, roof); for (let y = 2; y < rh; y += 4) R(g, 0, y, W, 1, 'rgba(0,0,0,0.18)'); R(g, 0, rh - 2, W, 2, 'rgba(0,0,0,0.35)'); R(g, 0, 0, W, 2, 'rgba(255,255,255,0.18)');
      for (let x = 8; x < W - 12; x += 24) { if (doors.some((d) => x + 8 > d * 16 - 4 && x < d * 16 + 20)) continue; R(g, x, rh + 6, 10, 9, '#4a6a8a'); R(g, x, rh + 6, 10, 1, '#2a3a4a'); R(g, x + 4, rh + 6, 1, 9, '#e8dcc0'); R(g, x + 1, rh + 7, 3, 3, '#8ab0d0'); }
      for (const d of doors) { R(g, d * 16 + 2, H - 14, 12, 14, '#5a3a22'); R(g, d * 16 + 2, H - 14, 12, 2, '#3a2412'); R(g, d * 16 + 10, H - 8, 2, 2, '#e2b85a'); }
      if (label) { g.font = '700 9px sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; const tw = g.measureText(label).width + 8; R(g, W / 2 - tw / 2, rh - 12, tw, 11, '#f4ecd8'); R(g, W / 2 - tw / 2, rh - 12, tw, 1, '#6a4a2a'); R(g, W / 2 - tw / 2, rh - 2, tw, 1, '#6a4a2a'); g.fillStyle = '#2a2218'; g.fillText(label, W / 2, rh - 6.5); }
    });
  }
  // 사람 도트(16×16) — 방향 down/up/side, 걸음 0/1. 바깥선은 실루엣을 4방향으로 깔아서 만듦
  function person(pal) {
    const out = {};
    for (const dir of ['down', 'up', 'side']) for (const st of [0, 1]) {
      const body = mk(16, 16, (g) => {
        const hair = pal.h, skin = '#f0c8a0', bd = pal.b, ac = pal.a, dk = '#2a1e16';
        // 다리
        if (dir === 'side') { R(g, 6 + (st ? 1 : 0), 13, 2, 3, dk); R(g, 9 - (st ? 1 : 0), 13, 2, 3, '#4a3a2a'); }
        else { R(g, 5, 13, 2, st ? 2 : 3, dk); R(g, 9, 13, 2, st ? 3 : 2, dk); }
        // 몸
        R(g, 4, 8, 8, 6, bd); R(g, 4, 8, 8, 1, ac); if (pal.bag && dir !== 'down') R(g, dir === 'up' ? 5 : 3, 9, dir === 'up' ? 6 : 3, 4, pal.bag);
        if (dir !== 'side') { R(g, 3, 9, 1, 4, bd); R(g, 12, 9, 1, 4, bd); R(g, 3, 12, 1, 1, skin); R(g, 12, 12, 1, 1, skin); } else { R(g, 8, 9, 2, 4, bd); R(g, 8, 12, 2, 1, skin); }
        // 머리
        R(g, 4, 1, 8, 7, skin);
        if (dir === 'down') { R(g, 4, 1, 8, 3, hair); R(g, 4, 4, 1, 3, hair); R(g, 11, 4, 1, 3, hair); R(g, 6, 5, 1, 1, dk); R(g, 9, 5, 1, 1, dk); R(g, 7, 7, 2, 1, '#d8a888'); if (pal.glasses) { R(g, 5, 5, 3, 1, '#2a3a5a'); R(g, 8, 5, 3, 1, '#2a3a5a'); } }
        else if (dir === 'up') { R(g, 4, 1, 8, 7, hair); }
        else { R(g, 4, 1, 8, 3, hair); R(g, 4, 4, 4, 3, hair); R(g, 10, 5, 1, 1, dk); if (pal.glasses) R(g, 9, 5, 3, 1, '#2a3a5a'); }
        if (pal.bun) R(g, dir === 'side' ? 3 : 6, 0, 4, 2, hair);
      });
      out[dir + st] = mk(16, 16, (g) => { for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { g.drawImage(body, dx, dy); } g.globalCompositeOperation = 'source-in'; R(g, 0, 0, 16, 16, '#1d140e'); g.globalCompositeOperation = 'source-over'; g.drawImage(body, 0, 0); });
    }
    return out;
  }
  const SPR = {
    me: person({ h: '#3a2a1a', b: '#b8432f', a: '#e2b85a', bag: '#6a4a2a' }),
    reader1: person({ h: '#5a3a2a', b: '#4a6a9a', a: '#f0e0b0', glasses: true }),
    keeper1: person({ h: '#d8d0c0', b: '#5a3a2a', a: '#c8a060', bun: true }),
    shop: person({ h: '#2a2a2a', b: '#5a7a4a', a: '#e8dcb0' }),
    kid: person({ h: '#7a4a2a', b: '#d89a4a', a: '#f4ecd8' }),
    reader2: person({ h: '#8a3a2a', b: '#c8784a', a: '#f4ecd8' }),
    reader3: person({ h: '#3a2a4a', b: '#8a7ab8', a: '#f0e0b0', glasses: true }),
  };
  // 소환수 도트(마을에서 따라다님) — 동그란 몸 + 글자 한 자
  function petSprite(id) { const P = PETS[id]; return mk(16, 16, (g) => { R(g, 3, 4, 10, 10, '#1d140e'); R(g, 2, 5, 12, 8, '#1d140e'); R(g, 4, 5, 8, 8, P.c); R(g, 3, 6, 10, 6, P.c); R(g, 5, 6, 3, 2, 'rgba(255,255,255,0.35)'); R(g, 6, 8, 1, 2, '#1d140e'); R(g, 9, 8, 1, 2, '#1d140e'); R(g, 4, 14, 2, 1, '#1d140e'); R(g, 10, 14, 2, 1, '#1d140e'); if (id === 'swallow') { R(g, 1, 7, 2, 3, '#3a4a6a'); R(g, 13, 7, 2, 3, '#3a4a6a'); } if (id === 'haetae') { R(g, 4, 3, 2, 2, '#c89a40'); R(g, 10, 3, 2, 2, '#c89a40'); } }); }
  const PSPR = {}; for (const id in PETS) PSPR[id] = petSprite(id);
  TILE.well = mk(16, 16, (g) => { R(g, 0, 0, 16, 16, '#d8c08a'); R(g, 3, 6, 10, 9, '#8a8a9a'); R(g, 5, 8, 6, 4, '#4a7ab8'); R(g, 2, 2, 12, 3, '#8a5a2a'); R(g, 3, 4, 1, 3, '#6a4a2a'); R(g, 12, 4, 1, 3, '#6a4a2a'); });
  TILE.jar = mk(16, 16, (g) => { grassBase(g, 51); R(g, 4, 4, 8, 10, '#5a3a2a'); R(g, 3, 6, 10, 6, '#7a4a2a'); R(g, 5, 3, 6, 2, '#3a2418'); R(g, 5, 7, 2, 3, 'rgba(255,255,255,0.25)'); });
  TILE.gourd = mk(16, 16, (g) => { grassBase(g, 52); R(g, 4, 6, 9, 8, '#e8dcb0'); R(g, 6, 3, 5, 4, '#e8dcb0'); R(g, 8, 1, 1, 3, '#5a8a3a'); R(g, 5, 8, 2, 3, 'rgba(255,255,255,0.4)'); });
  TILE.chest = mk(16, 16, (g) => { grassBase(g, 53); R(g, 2, 6, 12, 8, '#8a5a2a'); R(g, 2, 6, 12, 3, '#a8703a'); R(g, 7, 8, 2, 3, '#e2b85a'); });
  TILE.stele = mk(16, 16, (g) => { grassBase(g, 54); R(g, 5, 2, 6, 12, '#9a9a9a'); R(g, 6, 4, 4, 1, '#6a6a6a'); R(g, 6, 7, 4, 1, '#6a6a6a'); });
  // 빈 페이지(아직 쓰이지 않은 장)
  TILE.blank = mk(16, 16, (g) => { R(g, 0, 0, 16, 16, '#efe6cf'); R(g, 0, 5, 16, 1, 'rgba(120,90,50,0.12)'); R(g, 0, 11, 16, 1, 'rgba(120,90,50,0.12)'); R(g, 3, 2, 1, 1, 'rgba(120,90,50,0.15)'); R(g, 12, 13, 1, 1, 'rgba(120,90,50,0.15)'); });
  // 솟대·장승(16×32) — 옛이야기 고을 장식
  const SOTDAE = mk(16, 32, (g) => { R(g, 7, 6, 2, 26, '#3f2832'); R(g, 8, 6, 1, 26, '#a8703a'); R(g, 3, 3, 10, 4, '#3f2832'); R(g, 4, 4, 8, 2, '#e8dcb0'); R(g, 11, 2, 3, 2, '#3f2832'); R(g, 12, 2, 1, 1, '#e2b85a'); R(g, 4, 1, 3, 3, '#3f2832'); R(g, 5, 2, 1, 1, '#e8dcb0'); R(g, 6, 29, 4, 3, '#5a4a36'); });
  function jang(face, hat) { return mk(16, 32, (g) => { R(g, 4, 4, 8, 28, '#3f2832'); R(g, 5, 5, 6, 26, '#b8844a'); R(g, 5, 5, 6, 3, hat); R(g, 4, 2, 8, 3, '#3f2832'); R(g, 5, 3, 6, 1, hat); R(g, 6, 10, 1, 2, '#3f2832'); R(g, 9, 10, 1, 2, '#3f2832'); R(g, 6, 9, 1, 1, '#f4ecd8'); R(g, 9, 9, 1, 1, '#f4ecd8'); R(g, 7, 13, 2, 2, '#8a4a2a'); R(g, 6, 16, 4, 1, '#3f2832'); R(g, face === 0 ? 6 : 7, 17, 3, 1, '#f4ecd8'); R(g, 6, 20, 4, 9, 'rgba(0,0,0,0.12)'); R(g, 7, 21, 1, 7, '#3f2832'); R(g, 8, 21, 1, 7, '#3f2832'); }); }
  const JANG = [jang(0, '#2a2a2a'), jang(1, '#b8432f')];
