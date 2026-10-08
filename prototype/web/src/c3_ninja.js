  // ═════════ Ninja Adventure 입히기: 타일·건물·사람(4방향 걷기)·적·소환수·소리 ═════════
  let NINJA = false; const NS = {}; let NATI = null; // NS[key] = 걷기 그림(방향·프레임) 또는 줄 그림
  const DIRS = ['down', 'up', 'left', 'right'];
  function nload(src) { return new Promise((res) => { const i = new Image(); i.onload = () => res(i); i.onerror = () => res(null); i.src = src; }); }
  function nWalker(img, m) { const fr = {}; for (let c = 0; c < 4; c++) for (let r = 0; r < m.rows; r++) fr[DIRS[c] + r] = mk(16, 16, (g) => g.drawImage(img, c * 16, m.y + r * 16, 16, 16, 0, 0, 16, 16)); return { walker: true, rows: m.rows, frame: (dir, f) => fr[dir + (f % m.rows)] || fr[dir + '0'] }; }
  function bbWalker(img, m) { const fr = {}; for (let c = 0; c < 4; c++) for (let r = 0; r < 4; r++) fr[DIRS[c] + r] = mk(16, 32, (g) => g.drawImage(img, m.x + c * 16, m.y + r * 32, 16, 32, 0, 0, 16, 32)); return { walker: true, tall: true, rows: 4, frame: (dir, f) => fr[dir + (f % 4)] || fr[dir + '0'] }; }
  // 키 큰 그림(16x32)은 폭 0.8칸·높이 1.6칸, 발(그림자)을 칸 바닥에 맞춤. 어느 캔버스에나 그림
  function drawW(g, w, dir, f, x, y, s) { if (w.tall) { const sw = s * 0.8, sh = s * 1.6; g.drawImage(w.frame(dir, f), x + (s - sw) / 2, y + s * 1.1 - sh, sw, sh); } else g.drawImage(w.frame(dir, f), x, y, s, s); }
  // 말 위: 키 큰 그림은 허리 위(22줄)만 — 앉은 모습. cx = 가운데, by = 허리(안장) 높이, sw = 폭
  function drawRide(g, w, dir, cx, by, sw) { const fr = w.frame(dir, 0); if (w.tall) { const sh = sw * 22 / 16; g.drawImage(fr, 0, 0, 16, 22, cx - sw / 2, by - sh, sw, sh); } else g.drawImage(fr, cx - sw / 2, by - sw * 0.75, sw, sw); }
  function nStrip(img, m) { const fr = []; for (let i = 0; i < m.n; i++) fr.push(mk(m.w, m.h, (g) => g.drawImage(img, i * m.w, m.y, m.w, m.h, 0, 0, m.w, m.h))); return { strip: true, w: m.w, h: m.h, fr }; }
  // ── 소리: 효과음은 짧게, 음악은 고을·들길·싸움
  let audioOn = (() => { try { return localStorage.getItem('bw_audio') !== '0'; } catch (e) { return true; } })();
  const SNDP = {}; let musicEl = null, musicKey = '';
  function sfx(k, vol = 0.4) { if (!audioOn || !NA.aud[k]) return; try { const pool = (SNDP[k] = SNDP[k] || []); let el = pool.find((e) => e.paused || e.ended); if (!el) { if (pool.length >= 4) return; el = new Audio(NA.aud[k]); pool.push(el); } el.volume = vol; el.currentTime = 0; const pr = el.play(); if (pr && pr.catch) pr.catch(() => {}); } catch (e) {} }
  function music(k) { if (musicKey === k && musicEl && !musicEl.paused) return; musicKey = k; try { if (musicEl) musicEl.pause(); musicEl = null; if (!audioOn || !k || !NA.aud[k]) return; musicEl = new Audio(NA.aud[k]); musicEl.loop = true; musicEl.volume = 0.3; const pr = musicEl.play(); if (pr && pr.catch) pr.catch(() => {}); } catch (e) {} }
  function setAudio(on) { audioOn = on; try { localStorage.setItem('bw_audio', on ? '1' : '0'); } catch (e) {} const k = musicKey; musicKey = ''; if (on) music(k); else if (musicEl) musicEl.pause(); }
  Promise.all([nload(NA.tiles), nload(NA.sprites), typeof BB !== 'undefined' ? nload(BB.img) : null]).then(([ti, sp, bbi]) => {
    if (!ti || !sp) return; NATI = ti;
    const M = NA.tmeta, t = (i) => mk(16, 16, (g) => g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, 0, 0, 16, 16));
    const on = (base, i) => mk(16, 16, (g) => { g.drawImage(base, 0, 0); g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, 0, 0, 16, 16); });
    const g0 = t(M.grass[0]);
    TILE.grass = [g0, t(M.grass[3]), g0, t(M.grass[4])];
    TILE.path9 = M.path9.map((i) => on(g0, i)); TILE.path = [TILE.path9[4], TILE.path9[4]];
    TILE.dirt9 = M.dirt9.map((i) => on(g0, i));
    TILE.bush = [on(g0, M.tall[0]), on(g0, M.tall[1])];
    TILE.flowerV = M.flower.map((i) => on(g0, i)); TILE.flower = TILE.flowerV[0];
    TILE.fence = on(g0, M.fence[0]); TILE.sign = on(g0, M.sign[0]); TILE.well = on(TILE.dirt9[4], M.well[0]);
    TILE.tree = g0; TILE.tree2 = null;
    TILE.jar = on(g0, M.jar[0]); TILE.jarV = M.jar.map((i) => on(g0, i)); TILE.gourd = on(g0, M.gourd[0]); TILE.chest = on(g0, M.chest[0]); TILE.chestOpen = on(g0, M.chest[1]); TILE.stele = on(g0, M.stele[0]);
    TILE.treeO = mk(48, 48, (g) => M.treeO.forEach((i, n) => g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, (n % 3) * 16, Math.floor(n / 3) * 16, 16, 16)));
    TILE.bigTree = ['treeA', 'treeB', 'treeC'].map((k) => mk(32, 32, (g) => M[k].forEach((i, n) => g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, (n % 2) * 16, Math.floor(n / 2) * 16, 16, 16))));
    TILE.shelf = mk(32, 32, (g) => M.shelf.forEach((i, n) => g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, (n % 2) * 16, Math.floor(n / 2) * 16, 16, 16)));
    // 건물: 지붕(위 두 줄) + 앞면(문·창). 가운데 칸은 늘려 씀
    const setOf = { library: 'houseR', shop: 'houseB', home: 'houseO', house2: 'houseO', house3: 'houseB' };
    for (const b of BUILDINGS) b.img = houseImg(setOf[b.id] || 'houseO', b.w, b.h, b.doors, b.label);
    for (const k in NA.smeta) { const m = NA.smeta[k]; NS[k] = m.kind === 'grid' ? nWalker(sp, m) : nStrip(sp, m); }
    for (const k of ['me', 'reader1', 'reader2', 'reader3', 'keeper1', 'shop', 'kid']) if (NS[k]) SPR[k] = NS[k];
    // B.B.Bits 삼국지 캐릭터(16x32) — 있으면 관우·유비·장비·장각·황건 그림을 바꿔 끼움
    if (bbi) { for (const k in BB.meta) NS[k] = bbWalker(bbi, BB.meta[k]); for (const [to, from] of [['p_guanyu', 'bb_gy'], ['p_liubei', 'bb_lb'], ['p_zhangfei', 'bb_zf'], ['e_zj', 'bb_zj'], ['e_ytb', 'bb_ytb'], ['e_ytarch', 'bb_ytarch'], ['e_ytbig', 'bb_ytbig'], ['e_cyz', 'bb_cyz']]) if (NS[from]) NS[to] = NS[from]; }
    NINJA = true; fdArt(); // 그림이 늦게 로드돼도 갑옷별 그림을 만든다
  });
  // 건물 그림: 지붕(위 줄들) + 앞면(문·창). 가운데 칸은 늘려 씀. set = houseO·houseB·houseR
  function houseImg(set, w, h, doors, label) { const S = NA.tmeta[set], ti = NATI;
    return mk(w * 16, h * 16, (g) => { const put = (i, c, r) => g.drawImage(ti, (i % 16) * 16, Math.floor(i / 16) * 16, 16, 16, c * 16, r * 16, 16, 16);
      for (let r = 0; r < h; r++) for (let c = 0; c < w; c++) { const last = c === w - 1, first = c === 0; let i;
        if (r < h - 1) { const row = r === 0 ? 0 : 4; i = S[row + (first ? 0 : last ? 3 : (c % 2 ? 1 : 2))]; }
        else i = S[8 + (first ? 0 : last ? 3 : doors.includes(c) ? 1 : 2)];
        put(i, c, r); }
      if (label) { const W = w * 16, y = (h - 2) * 16 + 3; g.font = '700 9px sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; const tw = g.measureText(label).width + 8, x0 = Math.round(W / 2 - tw / 2); g.fillStyle = '#3a2418'; g.fillRect(x0 - 1, y - 1, tw + 2, 12); g.fillStyle = '#f4ecd8'; g.fillRect(x0, y, tw, 10); g.fillStyle = '#2a2218'; g.fillText(label, W / 2, y + 5.5); } }); }
  // 걷기 그림 그리기(마을·싸움판 공용). x,y = 화면 좌표(왼쪽 위), s = 한 칸 크기
  function drawWalker(w, dir, f, x, y, s) { if (w.walker) drawW(ctx, w, dir, f, x, y, s); else if (w.strip) { const im = w.fr[f % w.fr.length]; if (dir === 'left') { ctx.save(); ctx.translate(x + s, y); ctx.scale(-1, 1); ctx.drawImage(im, 0, 0, s, s * w.h / w.w); ctx.restore(); } else ctx.drawImage(im, x, y, s, s * w.h / w.w); } }
  const dirOf = (fx, fy) => Math.abs(fx) > Math.abs(fy) ? (fx > 0 ? 'right' : 'left') : (fy < 0 ? 'up' : 'down');
