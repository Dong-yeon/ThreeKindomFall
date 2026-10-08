  // ═════════ 1장 지도 판(D-164): 진삼국무쌍식 — 세로로 긴 전장 · 거점 점령 · 적토마 · 4타 연격 · 무쌍 ═════════
  // 아래(아군 본진)에서 위(장각 본진)로 진군. 황건 진영 3곳 점령 → 관문이 열림 → 정원지 → 장각
  const F1 = {
    id: 'f1', n: '1장 황건적의 난', W: 840, H: 3000,
    start: { x: 420, y: 2780 },
    home: { x: 420, y: 2895, r: 70, hp: 900, n: '아군 본진' },
    river: { y0: 2330, y1: 2400, bridges: [[130, 230], [375, 465], [610, 710]] },
    roads: [[[420, 2930], [420, 2420], [420, 1320], [420, 740], [420, 450]], [[420, 2470], [190, 2420], [190, 2150]], [[420, 2200], [630, 1880], [630, 1660]], [[420, 1500], [260, 1260], [260, 1160]], [[420, 2640], [690, 2600]]],
    village: { x: 690, y: 2590, r: 56, hp: 500, at: 75, n: '탁현 마을' },
    camps: [
      { id: 'a', n: '서쪽 황건 진영', x: 190, y: 2050, w: 250, h: 190, need: 50, lk: 'ytbig', ln: '황건 장수 등무', lm: 12, mul: 0.85 },
      { id: 'b', n: '동쪽 황건 진영', x: 630, y: 1560, w: 250, h: 190, need: 70, lk: 'ytbig', ln: '황건 역사 대장', lm: 14, mul: 1.1 },
      { id: 'c', n: '북쪽 황건 진영', x: 260, y: 1060, w: 250, h: 190, need: 90, lk: 'ytarch', ln: '황건 궁대장', lm: 36, mul: 1.35 },
    ],
    gate: { y: 720, x0: 375, x1: 465 },
    cyz: { x: 420, y: 590, m: 7, guards: 18 },
    keep: { x: 420, y: 300, w: 440, h: 300, boss: 'zj', bm: 7 },
    squads: [[420, 2500, 8, 0.6], [260, 2250, 10, 0.7], [610, 2170, 10, 0.75], [420, 1870, 12, 0.85], [720, 1280, 10, 0.95], [420, 1360, 12, 1], [140, 1520, 10, 1], [620, 960, 12, 1.15], [420, 830, 12, 1.2]],
  };
  const inRect = (o, R, m = 0) => o.x > R.x - R.w / 2 - m && o.x < R.x + R.w / 2 + m && o.y > R.y - R.h / 2 - m && o.y < R.y + R.h / 2 + m;
  // 울타리(벽 다섯 조각, 남쪽 가운데가 문). door: 닫힌 문 조각을 따로 둠
  function fdWalls(R, gateW, tag, door) { const x0 = R.x - R.w / 2, y0 = R.y - R.h / 2, t = 12, g0 = R.x - gateW / 2, g1 = R.x + gateW / 2, k = 'wall';
    const out = [{ x: x0, y: y0, w: R.w, h: t, k, tag }, { x: x0, y: y0, w: t, h: R.h, k, tag }, { x: x0 + R.w - t, y: y0, w: t, h: R.h, k, tag }, { x: x0, y: y0 + R.h - t, w: g0 - x0, h: t, k, tag }, { x: g1, y: y0 + R.h - t, w: x0 + R.w - g1, h: t, k, tag }];
    if (door) out.push({ x: g0, y: y0 + R.h - t, w: gateW, h: t, k, tag, door }); return out; }
  const mulY = (y) => (0.75 + (1 - y / F1.H) * 1.1) * (1 + Math.min(A.t, 600) / 600 * 0.4);
  function fdSpawn(k, x, y, mul, o) { spawn(k, x, y, mul * (A.mutHp || 1)); const e = A.en[A.en.length - 1]; if (o) Object.assign(e, o); return e; }
  const HORSE = { n: '적토마', hp: 120, spd: 255 };
  const fdHP = (M) => Math.round(MU_HP * (1 + 0.06 * (M.glv - 1))), fdAtk = (M) => 10 * (1 + 0.05 * (M.glv - 1)), gNeed = (lv) => 150 + 120 * (lv - 1);

  // ── (v0.14~0.16 로비 카드 — v0.17부터 천하 지도로 바뀜, 코드는 남김)
  function lobbyCard() {
    setMode('title'); $('hud').hidden = true; $('talk').hidden = true; TALK.on = false; inputLock = false; $('act').hidden = true; $('mbtn').hidden = true; A = null; fdArt();
    const M = muSV(), pic = (() => { try { const w = NINJA && NS.p_guanyu; return w ? w.frame('down', 0).toDataURL() : ''; } catch (e) { return ''; } })(), need = gNeed(M.glv), b = M.best.f1;
    card(`<h2>관우 무쌍</h2><div class="lobby">${pic ? `<img class="pimg big" alt="" src="${pic}">` : '<span class="pimg big" style="display:flex;align-items:center;justify-content:center;font:700 2.4rem var(--f-display);color:#4a8a5a">關</span>'}<div><b>관우 Lv ${M.glv}</b><span>체력 ${fdHP(M)} · 공격 ${Math.round(fdAtk(M) * 10)}%</span><div class="xp"><i style="width:${Math.min(100, M.gxp / need * 100)}%"></i></div><span>경험 ${M.gxp} / ${need}</span></div></div>
      <h3>장 고르기</h3><button class="opt" type="button" data-ch="f1" style="grid-template-columns:1fr"><b>1장 황건적의 난</b><span>황건 진영 3곳 점령 → 관문의 정원지 → 장각 본진 · ${b ? (b.win ? `클리어 ${fmtT(b.t)}` : `최고 ${b.cap}/3 점령`) : '기록 없음'}</span></button>
      <button class="opt" type="button" disabled style="grid-template-columns:1fr"><b>2장 호뢰관 — 다음 시안</b></button>
      <h3>말</h3><button class="opt" type="button" id="horse" style="grid-template-columns:1fr;${M.horse ? 'border-color:#b8432f;border-width:2px' : ''}"><b>${M.horse ? '적토마 — 타고 나감' : '말 없이 — 걸어서 나감'}</b><span>눌러서 바꾸기 · 말 위: 빠르고 넓게 휘두름 + 짓밟기, 장수에겐 피해 절반 · 진영 안에는 못 들어감</span></button>
      <p style="font-size:.8rem">끌어서 이동만 하면 관우가 알아서 4타 연격을 이어 가요. <b>말</b> 버튼으로 타고 내리고, 게이지가 차면 <b>무쌍</b>. 레벨이 오르면 책략을 골라요. 키보드: 방향키 · E 말 · 스페이스 무쌍.</p>
      <button class="sub" type="button" id="reset">기록 지우기</button><p style="font-size:.75rem">시안 v0.16 · 그림·소리: Ninja Adventure (CC0, pixel-boy) · 소리 끄기는 오른쪽 위 ♪</p>`, (c) => {
      c.querySelector('[data-ch="f1"]').onclick = () => { closeCard(); startField(); };
      c.querySelector('#horse').onclick = () => { M.horse = !M.horse; saveSV(); lobby(); };
      c.querySelector('#reset').onclick = () => { resetSV(); lobby(); }; });
    if (!pic) setTimeout(() => { if (MODE === 'title' && !A && document.querySelector('#ov:not([hidden]) .lobby')) lobby(); }, 400);
  }

  // ── 판 시작
  function startField() {
    const M = muSV(), C = F1; fdArt();
    baseArena('mu'); A.pet = null; A.weap = null; A.squad = []; A.ch = C; A.map = C; A.hero = 'p_guanyu'; A.WW = C.W; A.WH = C.H; A.VH = 600;
    const W0 = wSV(), RL = new Set(W0.rel), MT = W0.mut || {}; A.rel = RL; A.mut = { ...MT }; A.cdMul = RL.has('book') ? 0.85 : 1; A.mgMul = RL.has('tiger') ? 1.35 : 1; A.xpMul = RL.has('seal') ? 1.25 : 1; A.regen0 = RL.has('cart') ? 0.5 : 0; A.trMul = RL.has('saddle') ? 1.4 : 1; A.alMul = RL.has('oath') ? 1.2 : 1; A.mutHp = MT.elite ? 1.3 : 1; const AR0 = ARMORS[W0.armor] || ARMORS.green, HR0 = HORSES[W0.hk] || HORSES.red; A.armRed = AR0.red; A.mgMul *= 1 + AR0.mg; A.footSpd = 150 * (1 + AR0.spd); A.hspd = (HR0.spd || 255) * (1 + AR0.spd); A.hspr = HR0.spr || 'a_horseS'; A.trMul *= HR0.tr || 1; A.wtier = wTier(W0.wpn); A.hero = heroKey(W0);
    const p = A.p; p.x = C.start.x; p.y = C.start.y; p.fx = 0; p.fy = -1; p.max = p.hp = Math.round(fdHP(M) * (1 + 0.08 * W0.arm) * (1 + AR0.hp) * (RL.has('cart') ? 1.2 : 1)); p.atk = fdAtk(M) * (1 + 0.08 * W0.wpn) * (1 + AR0.atk); p.spd = 150; p.r = 12; p.body = bodyOf([]); p.stunT = 0;
    A.sk = {}; A.skCd = {}; A.evo = {}; A.gems = []; A.drops = []; A.fires = []; A.warns = []; A.lvl = 1; A.xp = 0; A.lvlQ = 0; A.chestQ = 0; A.regenAcc = 0; A.gold = 0; A.orbA = 0; A.boss = null; A.fence = null;
    A.cb = { i: 0, t: 0.3, idle: 9, side: 1 }; A.cbN = 0; A.cbMax = 0; A.cbMile = 0; A.cbPop = null; A.mg = 0; A.musouT = 0; A.musouK = 0; A.hitStop = 0;
    A.home = { ...C.home, max: C.home.hp }; A.vil = { ...C.village, max: C.village.hp, st: 'wait' }; A.camps = C.camps.map((c) => ({ ...c, cap: false, kills: 0, lead: null, spawnT: 0 })); A.cyzOn = false; A.cyzDead = false; A.keepOpen = false;
    A.obsVer = 1; FDG = null; A.wsw = null; fdAllySetup(); A.partyT = 60; A.reinT = 4; A.turretT = 0; A.capN = 0; A.vilSaved = null; A.alerts = {};
    A.obs = []; for (const c of A.camps) A.obs.push(...fdWalls(c, 70, 'camp')); A.obs.push(...fdWalls(C.keep, 70, 'keep', 'keep'));
    { const R = C.river; let x0 = 0; for (const [a, b] of R.bridges) { A.obs.push({ x: x0, y: R.y0, w: a - x0, h: R.y1 - R.y0, k: 'water' }); x0 = b; } A.obs.push({ x: x0, y: R.y0, w: C.W - x0, h: R.y1 - R.y0, k: 'water' }); }
    const g = C.gate; A.obs.push({ x: 0, y: g.y - 10, w: g.x0, h: 20, k: 'wall', tag: 'gate' }, { x: g.x1, y: g.y - 10, w: C.W - g.x1, h: 20, k: 'wall', tag: 'gate' }, { x: g.x0, y: g.y - 10, w: g.x1 - g.x0, h: 20, k: 'wall', tag: 'gate', door: 'gate' });
    // 길목의 황건 부대(가까이 가면 덤빔)
    for (const [x, y, n0, m] of C.squads) for (let i = 0, n = Math.round(n0 * 1.5); i < n; i++) { const k = i === 0 && n >= 10 ? 'ytcav' : y < 2300 && i % 4 === 3 ? 'ytarch' : y < 1400 && i % 6 === 1 ? 'ytbig' : 'ytb', ex = clamp(x + rnd(-55, 55), 30, C.W - 30), ey = y + rnd(-45, 45); fdSpawn(k, ex, ey, m, { post: { x: ex, y: ey }, aggro: 230 }); }
    for (const c of A.camps) for (let i = 0; i < 10; i++) fdSpawn(i % 4 === 3 ? 'ytarch' : 'ytb', c.x + rnd(-c.w / 2 + 30, c.w / 2 - 30), c.y + rnd(-c.h / 2 + 30, c.h / 2 - 40), c.mul, { campId: c.id, post: null, aggro: 220 });
    for (const e of A.en) if (e.campId) e.post = { x: e.x, y: e.y };
    const hh = Math.round((HR0.hp || HORSE.hp) * (1 + 0.2 * W0.sad) * (RL.has('saddle') ? 1.5 : 1)); A.horse = M.horse ? { x: p.x, y: p.y, hp: hh, max: hh, st: 'ride', t: 0, fd: 'right' } : null; A.ride = !!A.horse;
    M.runs++; saveSV(); CAMX = clamp(p.x - AW / 2, 0, C.W - AW); CAMY = clamp(p.y - A.VH * 0.6, 0, C.H - A.VH);
    if (RL.has('oath')) for (let i = 0; i < 4; i++) alSpawn('sol', p.x + rnd(-40, 40), p.y + rnd(10, 40), 'join', null);
    $('mbtn').hidden = false; $('wp').hidden = true; hudUpdate(); banner(C.n, '황건 진영 3곳을 점령하세요 — 진영 안에는 걸어서');
  }
  const fdLead = (e) => e.boss || e.elite;
  const cbStage = () => (A.cbN >= 150 ? 3 : A.cbN >= 50 ? 2 : 1);
  const CB_COL = [null, ['#fffaf0', '#a89a80'], ['#d8ffe0', '#4a8a5a'], ['#fff2b0', '#e2a83a']];
  const HITS = [{ arc: 2.1, r: 80, m: 1.0, cd: 0.26 }, { arc: 2.4, r: 84, m: 1.0, cd: 0.26 }, { arc: 0.9, r: 112, m: 1.35, cd: 0.3, push: 24 }, { arc: 6.3, r: 104, m: 2.3, cd: 0.5, fin: true }];
  // 연격 수: 맞히면 쌓이고, 2.2초 못 맞히면 끊김, 맞으면 절반
  function cbAdd(n, gauge) { if (!n) return; A.cbN += n; A.cb.idle = 0; if (gauge) A.mg = Math.min(100, A.mg + n * gauge * (A.mgMul || 1)); if (A.cbN > A.cbMax) A.cbMax = A.cbN;
    const mil = [50, 100, 150, 300, 500, 1000, 2000].filter((m) => A.cbN >= m).pop() || 0; if (mil > A.cbMile) { A.cbMile = mil; A.cbPop = { t: 1.3, v: `${mil} 연격!`, c: CB_COL[cbStage()][1] }; sfx('accept', 0.3); } }
  function swing(a, H, dmg, col, launch) { const p = A.p; let n = 0, sparks = 0;
    for (const e of A.en) { if (e.dead) continue; const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy); if (d > H.r + e.r) continue; const da = Math.abs(((Math.atan2(dy, dx) - a) + Math.PI * 3) % (Math.PI * 2) - Math.PI); if (H.arc < 6 && da > H.arc / 2) continue;
      const lead = fdLead(e); dmgE(e, dmg * (lead && A.ride ? 0.5 : 1)); n++; if (sparks++ < 6) A.fx.push({ k: 'spark', x: e.x, y: e.y - 4, t: 0.18, a: Math.atan2(dy, dx), c: col[0] });
      if (!e.dead && !lead && d > 0.1) { if (launch) { e.air = e.air0 = 0.42; e.kvx = dx / d * 170; e.kvy = dy / d * 170; } else if (H.push) { e.x += dx / d * H.push; e.y += dy / d * H.push; } } }
    A.fx.push({ k: 'slash', x: p.x, y: p.y, a, arc: H.arc, r: H.r, t: 0.2, c: col[0], c2: col[1] }); return n; }
  // ── 걸어서: 4타 연격(4타 = 마무리 일격: 한 바퀴 베기 · 띄우기 · 짧은 멈춤)
  function comboTick(dt) { const p = A.p, C = A.cb; C.t -= dt; C.idle += dt; if (C.idle > 1.5) C.i = 0; if (C.idle > 2.2 && A.cbN) { A.cbN = 0; A.cbMile = 0; }
    if (C.t > 0) return; const st = cbStage(), H0 = HITS[C.i], rk = 1 + 0.06 * (st - 1), H = { ...H0, r: H0.r * rk }, tg = nearest(1, p, H.r + 24)[0]; if (!tg) { C.t = 0.06; return; }
    const a = Math.atan2(tg.y - p.y, tg.x - p.x), dmg = muAtk() * 2.0 * H.m * [1, 1, 1.15, 1.3][st], col = CB_COL[st]; p.fx = Math.cos(a); p.fy = Math.sin(a);
    const n = swing(a, H, dmg, col, H.fin); cbAdd(n, 0.6); A.cb.side = C.i === 1 ? -1 : 1; fdSwingFx(a, H.arc, H.fin ? 'spin' : C.i === 2 ? 'thrust' : 'arc', H.fin ? 0.22 : 0.16); C.t = H.cd / (1 + 0.1 * (st - 1)); sfx(H.fin ? 'slam' : 'hit', H.fin ? 0.2 : 0.1);
    if (H.fin) { if (n) { A.hitStop = 0.045; A.shake = Math.max(A.shake, 0.12); } const wl = sk('wave'); if (wl) { const ev = A.evo.wave, k = ev ? 5 : [1, 1, 2, 2, 3][wl - 1]; for (let i = 0; i < k; i++) { const b = a + (i - (k - 1) / 2) * (ev ? 0.4 : 0.32), sp = ev ? 430 : 340; A.shots.push({ x: p.x, y: p.y, vx: Math.cos(b) * sp, vy: Math.sin(b) * sp, dmg: muAtk() * (ev ? 3.0 : [1.8, 2.2, 2.2, 2.6, 2.6][wl - 1]), r: ev ? 18 : 13, kind: 'blade', pierce: 99, hit: [], born: A.t, mine: true, life: 0, maxLife: ev ? 0.9 : 0.7 }); } } }
    C.i = (C.i + 1) % 4; }
  // ── 말 위: 좌우 휘두르기(넓고 약함) + 짓밟기
  function rideTick(dt) { const p = A.p, C = A.cb, Hs = A.horse; C.t -= dt; C.idle += dt; if (C.idle > 2.2 && A.cbN) { A.cbN = 0; A.cbMile = 0; }
    Hs.x = p.x; Hs.y = p.y; if (Math.abs(p.vx) > 5) Hs.fd = p.vx < 0 ? 'left' : 'right';
    const sp = Math.hypot(p.vx, p.vy); let n = 0;
    if (sp > 60) for (const e of A.en) { if (e.dead || (e.trT || 0) > 0) continue; const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy); if (d < e.r + 17) { e.trT = 0.5; const lead = fdLead(e); dmgE(e, muAtk() * 1.4 * (A.trMul || 1) * (lead ? 0.5 : 1)); n++; if (!e.dead && !lead && d > 0.1) { e.air = e.air0 = 0.3; e.kvx = dx / d * 210; e.kvy = dy / d * 210; } A.fx.push({ k: 'spark', x: e.x, y: e.y, t: 0.15, a: Math.atan2(dy, dx), c: '#ffd8a0' }); } }
    if (n) { cbAdd(n, 0.5); sfx('hit', 0.12); }
    if (C.t > 0) return; const tg = nearest(1, p, 104)[0]; if (!tg) { C.t = 0.08; return; } C.side = -(C.side || 1);
    const a = Math.atan2(tg.y - p.y, tg.x - p.x), st = cbStage(), m = swing(a, { arc: 2.7, r: 90 }, muAtk() * 1.25 * [1, 1, 1.15, 1.3][st], CB_COL[st], false); cbAdd(m, 0.5); fdSwingFx(a, 2.7, 'arc', 0.2); C.t = 0.42; sfx('hit', 0.1); }
  function horseFall() { const p = A.p, Hs = A.horse; A.ride = false; Hs.st = 'down'; Hs.t = 8; Hs.hp = 0; const a = rnd(0, 6.28); Hs.x = clamp(p.x + Math.cos(a) * 110, 30, F1.W - 30); Hs.y = clamp(p.y + Math.sin(a) * 110, 30, F1.H - 30); p.stunT = 0.7; p.inv = 1.0; A.shake = 0.25; banner('낙마!', '적토마가 달아났어요 — 8초 뒤 다시 부를 수 있어요'); sfx('hurt', 0.4); A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.4, r: 36, c: '#a8784a' }); }
  function dismount(silent) { const p = A.p, Hs = A.horse; if (!A.ride) return; A.ride = false; Hs.st = 'idle'; const R = insideWalls(p); if (R) { Hs.x = R.x; Hs.y = R.y + R.h / 2 + 30; } else { Hs.x = p.x + 18; Hs.y = p.y + 6; } A.cb.i = 0; A.cb.t = 0.15; if (!silent) sfx('accept', 0.2); A.fx.push({ k: 'ring', x: p.x, y: p.y + 6, t: 0.3, r: 22, c: '#c8a874' }); }
  function mount() { const p = A.p, Hs = A.horse; A.ride = true; Hs.st = 'ride'; Hs.x = p.x; Hs.y = p.y; A.cb.t = 0.2; sfx('accept', 0.25); A.fx.push({ k: 'ring', x: p.x, y: p.y + 6, t: 0.35, r: 26, c: '#c8a874' }); }
  const insideWalls = (o) => A.camps.find((c) => inRect(o, c, -4)) || (inRect(o, F1.keep, -4) ? F1.keep : null);
  function horseBtn() { if (!A || A.kind !== 'mu' || !A.map || A.state !== 'play' || !A.horse) return; const p = A.p, Hs = A.horse;
    if (A.ride) return dismount(); if (Hs.st === 'down' || p.stunT > 0) return; if (insideWalls(p)) { banner('진영 안에는 말이 못 들어와요', ''); return; }
    if (Math.hypot(Hs.x - p.x, Hs.y - p.y) < 44) return mount(); Hs.st = 'come'; sfx('accept', 0.2); }
  function musouGo() { if (!A || A.kind !== 'mu' || !A.map || A.state !== 'play' || A.mg < 100 || A.musouT > 0 || A.p.stunT > 0) return; A.mg = 0; A.musouT = 2.3; A.musouK = 0; A.shake = 0.2; banner('무쌍 난무!', ''); sfx('win', 0.3); }
  // 맞을 때(hurtPlayer에서): 무쌍 중 무적 · 말 위면 말이 맞음 · 걸어서 맞으면 연격 절반
  function fieldHurt(d) { const p = A.p; if (A.musouT > 0) return true; A.mg = Math.min(100, A.mg + d * 0.35);
    if (A.ride && A.horse) { A.horse.hp -= d * 0.8; p.inv = 0.45; A.fx.push({ k: 'num', x: p.x, y: p.y - 22, t: 0.6, v: '-' + Math.round(d * 0.8), c: '#e0b080' }); sfx('hurt', 0.25); if (A.horse.hp <= 0) horseFall(); return true; }
    if (A.cbN) { A.cbN = Math.floor(A.cbN / 2); A.cbMile = [50, 100, 150, 300, 500, 1000, 2000].filter((m) => A.cbN >= m).pop() || 0; } return false; }

  // ── 매 프레임(muTick에서 넘어옴)
  function fieldTick(dt) {
    const p = A.p, C = F1, t = A.t;
    if (sk('gun') || A.regen0) { A.regenAcc += (0.4 * sk('gun') + (A.regen0 || 0)) * dt; if (A.regenAcc >= 1) { const v = Math.floor(A.regenAcc); A.regenAcc -= v; p.hp = Math.min(p.max, p.hp + v); } }
    p.stunT = Math.max(0, (p.stunT || 0) - dt); if (A.wsw) A.wsw.t -= dt;
    const inRiver = (o) => o.y > C.river.y0 && o.y < C.river.y1 && !C.river.bridges.some(([a, b]) => o.x > a && o.x < b);
    p.spd = (p.stunT > 0 ? 0 : A.ride ? (A.hspd || HORSE.spd) : (A.footSpd || 150)) * (inRiver(p) ? (A.ride ? 0.75 : 0.6) : 1) * (A.musouT > 0 ? 0.6 : 1);
    if (A.ride && insideWalls(p)) dismount(true);
    // 말(안 탈 때): 쉬면 회복 · 부르면 달려옴
    const Hs = A.horse; if (Hs && !A.ride) { Hs.hp = Math.min(Hs.max, Hs.hp + (Hs.st === 'down' ? 6 : 4) * dt);
      if (Hs.st === 'down') { Hs.t -= dt; if (Hs.t <= 0) Hs.st = 'idle'; }
      else if (Hs.st === 'come') { const dx = p.x - Hs.x, dy = p.y - Hs.y, d = Math.hypot(dx, dy); if (insideWalls(p)) Hs.st = 'idle'; else if (d < 20) mount(); else { const s = Math.min(d, 330 * dt); Hs.x += dx / d * s; Hs.y += dy / d * s; if (Math.abs(dx) > 1) Hs.fd = dx < 0 ? 'left' : 'right'; } } }
    // 공격: 무쌍 > 말 위 > 걸어서
    if (A.musouT > 0) { A.musouT -= dt; A.musouK -= dt; p.inv = Math.max(p.inv, 0.15);
      if (A.musouK <= 0 && A.musouT > 0.3) { A.musouK = 0.16; A.orbA = (A.orbA || 0) + 1.3; fdSwingFx(A.orbA, 0, 'spin', 0.16); const n = swing(A.orbA, { arc: 6.3, r: 120 }, muAtk() * 2.2, ['#fff2b0', '#e2a83a'], false); cbAdd(n, 0); for (const e of A.en) { if (e.dead || fdLead(e)) continue; const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy); if (d < 130 && d > 0.1) { e.x += dx / d * 8; e.y += dy / d * 8; } } A.shake = Math.max(A.shake, 0.08); sfx('slam', 0.12); }
      if (A.musouT <= 0) { let n = 0; for (const e of A.en) { if (e.dead) continue; const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy); if (d > 190 + e.r) continue; dmgE(e, muAtk() * 7 * (fdLead(e) ? 0.6 : 1)); n++; if (!e.dead && !fdLead(e) && d > 0.1) { e.air = e.air0 = 0.5; e.kvx = dx / d * 240; e.kvy = dy / d * 240; } }
        cbAdd(n, 0); A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.5, r: 220, c: '#ffd34a' }, { k: 'ring', x: p.x, y: p.y, t: 0.35, r: 140, c: '#fff2b0' }); A.shake = 0.4; A.hitStop = 0.08; sfx('slam', 0.5); } }
    else if (p.stunT > 0) { /* 넘어짐 */ } else if (A.ride) rideTick(dt); else comboTick(dt);
    if (A.cbPop) { A.cbPop.t -= dt; if (A.cbPop.t <= 0) A.cbPop = null; }
    // 아군 본진: 궁병이 가까운 적을 쏨 · 적이 붙으면 체력이 깎임
    const H = A.home; A.turretT -= dt; if (A.turretT <= 0) { A.turretT = 0.7; const tg = nearest(1, H, H.r + 110)[0]; if (tg) { dmgE(tg, 16); A.fx.push({ k: 'shot', x: H.x, y: H.y - 20, x2: tg.x, y2: tg.y, t: 0.15 }); } }
    const V = A.vil;
    for (const e of A.en) { if (e.dead) continue; if (e.trT > 0) e.trT -= dt; if (inRiver(e)) e.slowT = Math.max(e.slowT || 0, 0.05);
      if (e.goal === H && !e.engage && Math.hypot(e.x - H.x, e.y - H.y) < H.r + e.r) H.hp -= 1.2 * dt; else if (e.goal === V && V.st === 'raid' && Math.hypot(e.x - V.x, e.y - V.y) < V.r + e.r) V.hp -= 1.4 * dt;
      if (e.boss) { const K = F1.keep; e.x = clamp(e.x, K.x - K.w / 2 + e.r + 12, K.x + K.w / 2 - e.r - 12); e.y = clamp(e.y, K.y - K.h / 2 + e.r + 12, K.y + K.h / 2 - e.r - 12); } }
    if (H.hp <= H.max * 0.4 && !A.alerts.home) { A.alerts.home = true; banner('아군 본진이 밀려요!', '수비대가 버티기 어려워요 — 돌아가 도와요'); sfx('alert', 0.5); } if (H.hp > H.max * 0.7) A.alerts.home = false;
    if (H.hp <= 0) { H.hp = 0; return muEnd(false, 'home'); }
    // 돌발: 탁현 마을 습격
    if (V.st === 'wait' && t >= V.at) { V.st = 'raid'; V.max = V.hp; for (let i = 0; i < 14; i++) { const a = rnd(-1.4, 0.2), r = rnd(170, 230); fdSpawn(i < 2 ? 'ytbig' : i < 4 ? 'ytcav' : 'ytb', clamp(V.x + Math.cos(a) * r, 30, C.W - 30), V.y + Math.sin(a) * r, 0.7, { goal: V, aggro: 170, raid: true }); } banner('탁현 마을이 습격당해요!', '구하러 가면 군량과 보물 상자 — 오른쪽 아래'); sfx('alert', 0.5); }
    if (V.st === 'raid') { if (V.hp <= 0) { V.st = 'lost'; A.vilSaved = false; for (const e of A.en) if (e.raid) e.goal = H; banner('탁현 마을이 불탔어요…', '황건 부대가 본진으로 향해요'); sfx('lose', 0.3); }
      else if (!A.en.some((e) => e.raid && !e.dead)) { V.st = 'saved'; A.vilSaved = true; heal(p, p.max * 0.4); A.chestQ++; banner('탁현 마을을 구했어요!', '마을 사람들이 군량을 내줬어요'); sfx('win', 0.35); } }
    // 돌발: 본진 기습(진영 2곳을 점령했거나 3분이 지나면 한 번) — 말을 타고 돌아가야 막을 수 있음
    if (!A.raidHome && (A.capN >= 2 || t >= 180)) { A.raidHome = true; if (A.mut.raid) for (let i = 0; i < 14; i++) fdSpawn('ytcav', i % 2 ? rnd(30, 90) : rnd(C.W - 90, C.W - 30), rnd(2500, 2650), 1.3, { goal: H, aggro: 60, noEng: true }); for (let i = 0; i < (A.mut.raid ? 50 : 30); i++) { const L = i % 2, x = L ? rnd(30, 90) : rnd(C.W - 90, C.W - 30), y = rnd(2560, 2700); fdSpawn(i % 4 === 0 ? 'ytcav' : i % 5 === 3 ? 'ytbig' : 'ytb', x, y, 1.3, { goal: H, aggro: 160 }); } banner('본진 기습!', '유비와 수비대가 막아요 — 많이 밀리면 돌아가 도와요'); sfx('alert', 0.6); }
    // 진영: 병력 채움 → 병력을 다 줄이면 진영장 등장 → 쓰러뜨리면 점령
    for (const c of A.camps) { if (c.cap) continue; c.spawnT -= dt;
      if (!c.lead && c.spawnT <= 0) { c.spawnT = Math.hypot(p.x - c.x, p.y - c.y) < 320 ? 0.55 : 1.6; if (A.en.filter((e) => e.campId === c.id && !e.dead).length < 22 && A.en.length < 240) { const x = c.x + rnd(-c.w / 2 + 30, c.w / 2 - 30), y = c.y + rnd(-c.h / 2 + 30, c.h / 2 - 40); fdSpawn(Math.random() < 0.2 ? 'ytarch' : 'ytb', x, y, c.mul * (1 + Math.min(t, 600) / 600 * 0.25), { campId: c.id, post: { x, y }, aggro: 220 }); } }
      if (!c.lead && c.kills >= c.need) { const L = fdSpawn(c.lk, c.x, c.y - 20, c.mul * c.lm, { elite: true, ename: c.ln, campLead: c.id, post: { x: c.x, y: c.y - 20 }, aggro: 280 }); L.max = L.hp; L.touch = EN[c.lk].touch; L.r *= c.lk === 'ytbig' ? 1.4 : 1.6; c.lead = L; banner(`${c.ln} 등장!`, '쓰러뜨리면 진영 점령'); sfx('alert', 0.35); } }
    // 황건 부대가 본진으로(점령 안 된 진영에서 45초마다)
    A.partyT -= dt; const open = A.camps.filter((c) => !c.cap); if (A.partyT <= 0 && open.length) { A.partyT = 45; const c = pick(open); for (let i = 0; i < 8; i++) fdSpawn(i < 2 ? 'ytcav' : 'ytb', c.x + rnd(-30, 30), c.y + c.h / 2 + 30 + rnd(0, 30), c.mul, { goal: H, aggro: 200 }); banner(`${c.n}에서 부대가 본진으로!`, '본진 체력을 지켜요'); }
    // 들판 증원: 관우 둘레가 비면 황건 무리가 몰려옴(쓸어버리는 맛)
    A.reinT -= dt; if (A.reinT <= 0) { A.reinT = 3; if (!insideWalls(p) && !A.boss && A.en.length < 260) { let near = 0; for (const e of A.en) if (!e.dead && Math.hypot(e.x - p.x, e.y - p.y) < 420) near++; if (near < 40) { const n = 12 + Math.floor(Math.random() * 7), [x0, y0] = ringPos(), m = mulY(p.y); for (let i = 0; i < n; i++) { const k = p.y < 1300 && i % 6 === 5 ? 'ytbig' : p.y < 2300 && i % 5 === 4 ? 'ytarch' : i === 0 && Math.random() < 0.5 ? 'ytcav' : 'ytb'; fdSpawn(k, clamp(x0 + rnd(-40, 40), 30, C.W - 30), clamp(y0 + rnd(-40, 40), 30, C.H - 30), m, {}); } } } }
    if (A.cyzOn && !A.cyzDead) { A.cyzT = (A.cyzT || 4) - dt; if (A.cyzT <= 0) { A.cyzT = 6; if (A.en.length < 260) for (let i = 0; i < 10; i++) fdSpawn(i % 5 === 0 ? 'ytbig' : i % 4 === 1 ? 'ytarch' : 'ytb', rnd(80, C.W - 80), rnd(470, 520), 1.3 * (1 + Math.min(t, 600) / 600 * 0.25), {}); } }
    // 겹치지 않게
    const cell = 30, G = new Map(); for (const e of A.en) { const k = ((e.x / cell) | 0) * 4096 + ((e.y / cell) | 0); let l = G.get(k); if (!l) G.set(k, (l = [])); l.push(e); }
    for (const e of A.en) { if (e.boss || e.air > 0) continue; const cx = (e.x / cell) | 0, cy = (e.y / cell) | 0; for (let i = -1; i <= 1; i++) for (let j = -1; j <= 1; j++) { const l = G.get((cx + i) * 4096 + cy + j); if (!l) continue; for (const o of l) { if (o === e) continue; const dx = e.x - o.x, dy = e.y - o.y, d = Math.hypot(dx, dy), m = (e.r + o.r) * 0.85; if (d > 0.01 && d < m) { const k = (m - d) * 0.25 / d; e.x += dx * k; e.y += dy * k; } } } }
    fdAllyTimers(dt); fdEngage(dt); alTick(dt, G, cell);
    skillTick(dt);
    for (const it of A.drops) { const d = Math.hypot(it.x - p.x, it.y - p.y); if (d < p.r + 14) { it.got = true; if (it.k === 'bun') { heal(p, p.max * 0.3); sfx('heal', 0.35); } else if (it.k === 'bomb') { for (const e of A.en) if (!e.dead && !fdLead(e) && inView(e, 40)) dmgE(e, e.hp); A.shake = 0.3; A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.5, r: 260, c: '#ffb050' }); sfx('slam', 0.5); } else if (it.k === 'chest') A.chestQ++; } }
    A.drops = A.drops.filter((it) => !it.got);
    CAMX = clamp(p.x - AW / 2, 0, C.W - AW); CAMY = clamp(p.y - A.VH * 0.6, 0, C.H - A.VH);
    if (A.chestQ > 0) { A.chestQ--; return openChest(); }
    if (A.lvlQ > 0) { A.lvlQ--; return levelUp(); }
  }
  // 적이 쓰러지면(muKill에서 넘어옴)
  function fieldKill(e) {
    if (e.boss) { for (const o of A.en) if (!o.dead && o !== e) o.dead = true; A.later.push({ t: A.t + 1.4, fn: () => muEnd(true) }); banner(`${EN[e.k].n}${eul(EN[e.k].n)} 쓰러뜨렸어요!`, '황건적의 난을 평정했어요'); A.hitStop = 0.15; A.shake = 0.5; return; }
    const xp = e.k === 'cyz' ? 40 : e.elite ? 20 : e.k === 'ytbig' ? 4 : e.k === 'ytarch' || e.k === 'ytcav' ? 2 : 1; gainXPm(xp);
    if (e.campId) { const c = A.camps.find((q) => q.id === e.campId); if (c && !c.cap && !c.lead) c.kills++; }
    if (e.campLead) { const c = A.camps.find((q) => q.id === e.campLead); c.cap = true; A.capN++; for (const o of A.en) if (!o.dead && o.campId === c.id) { o.dead = true; A.kills++; A.fx.push({ k: 'burst', x: o.x, y: o.y, t: 0.3, r: o.r * 0.6, c: '#f6e2a0' }); }
      heal(A.p, A.p.max * 0.15); A.drops.push({ k: 'chest', x: e.x, y: e.y }); c.ag = { x: c.x, y: c.y + c.h / 2 + 40, r: 260 }; c.alT = 0; A.fx.push({ k: 'ring', x: c.x, y: c.y, t: 0.6, r: 150, c: '#4a7ab8' }); sfx('win', 0.35);
      if (A.capN >= 3) { A.obs = A.obs.filter((o) => o.door !== 'gate'); A.obsVer++; A.cyzOn = true; const Z = F1.cyz; const z = fdSpawn('cyz', Z.x, Z.y, Z.m, { elite: true, ename: '황건 장수 정원지', post: { x: Z.x, y: Z.y }, aggro: 300 }); z.max = z.hp; z.touch = 22; for (let i = 0; i < Z.guards; i++) { const x = Z.x + rnd(-150, 150), y = Z.y + rnd(-60, 90); fdSpawn(i % 4 === 0 ? 'ytbig' : 'ytb', x, y, 1.3, { post: { x, y }, aggro: 260 }); } banner(`${c.n} 점령! 관문이 열렸어요`, '관문 너머의 정원지를 쓰러뜨려요'); }
      else banner(`${c.n} 점령! (${A.capN}/3)`, '아군 창병이 진영을 지키고, 부대가 관우에게 합류해요'); return; }
    if (e.k === 'cyz' && e.elite) { A.cyzDead = true; A.keepOpen = true; A.obs = A.obs.filter((o) => o.door !== 'keep'); A.obsVer++; A.drops.push({ k: 'chest', x: e.x, y: e.y }); const K = F1.keep; for (const dx of [-24, 24]) A.drops.push({ k: 'bun', x: K.x + dx, y: K.y + K.h / 2 + 40 }); const b = fdSpawn(K.boss, K.x, K.y - 40, K.bm, {}); A.boss = b; b.boss = true; b.touch = 22; banner('정원지 격파! 장각 본진의 문이 열렸어요', '문 앞 고기만두로 기운을 차리고 장각에게'); sfx('alert', 0.5); return; }
    if (e.elite) { A.drops.push({ k: 'chest', x: e.x, y: e.y }); return; }
    const r = Math.random(); if (r < 0.006) A.drops.push({ k: 'bun', x: e.x, y: e.y }); else if (r < 0.0075) A.drops.push({ k: 'bomb', x: e.x, y: e.y });
  }
  // ── 끝: 관우 경험(판 밖 레벨)
  function fieldEnd(win, why) {
    if (A.state === 'end' || A.state === 'dead') return; A.state = win ? 'end' : 'dead'; sfx(win ? 'win' : 'lose', 0.4); $('mbtn').hidden = true;
    const M = muSV(), W0 = wSV(), mb = Object.keys(A.mut || {}).filter((k) => A.mut[k]).length * 0.3, gx = Math.floor(A.kills / 8) + A.capN * 25 + (A.cyzDead ? 40 : 0) + (A.vilSaved ? 25 : 0) + (win ? 120 : 0), lv0 = M.glv; const mer = Math.round(gx * (1 + mb)); W0.merit += mer; M.gxp += gx; while (M.gxp >= gNeed(M.glv)) { M.gxp -= gNeed(M.glv); M.glv++; }
    const b = M.best.f1; if (win) { if (!b || !b.win || A.t < b.t) M.best.f1 = { win: true, t: A.t, cap: 3 }; M.clears++; } else if (!b || (!b.win && A.capN > (b.cap || 0))) M.best.f1 = { win: false, t: A.t, cap: A.capN }; saveSV();
    const head = win ? '1장 황건적의 난 평정!' : why === 'home' ? '아군 본진이 함락됐어요' : why === true ? '물러났어요' : '관우가 쓰러졌어요';
    setTimeout(() => card(`<h2>${head}</h2><div class="stats"><span>걸린 시간</span><b>${fmtT(A.t)}</b><span>점령한 진영</span><b>${A.capN} / 3</b><span>탁현 마을</span><b>${A.vilSaved === true ? '구함' : A.vilSaved === false ? '불탐' : '—'}</b><span>쓰러뜨린 적</span><b>${A.kills}</b><span>최대 연격</span><b>${A.cbMax}</b><span>공적 레벨</span><b>${A.lvl}</b><span>관우 경험</span><b>+${gx}${M.glv > lv0 ? ` · Lv ${M.glv}로!` : ''}</b><span>전공</span><b>+${mer}${mb ? ` (변이 +${Math.round(mb * 100)}%)` : ''}</b></div>${skBar()}<p>${win ? '' : '대장간 · 군막에서 무장을 꾸미고 다시 도전해요.'}</p><button class="go" type="button" id="back">군영으로</button>`, (c) => { c.querySelector('#back').onclick = () => { closeCard(); lobby('f1'); }; }), 700);
  }
  // 지금 가야 할 곳(화살표 · 작은 지도 · 목표 글)
  function fieldTarget(skipHome) { const p = A.p, V = A.vil, H = A.home;
    if (V.st === 'raid') return { x: V.x, y: V.y, n: `탁현 마을 구하기 (마을 ${Math.ceil(V.hp / V.max * 100)}%)` };
    if (!skipHome && H.hp < H.max * 0.4 && A.en.some((e) => e.goal === H && !e.dead && Math.hypot(e.x - H.x, e.y - H.y) < 400)) return { x: H.x, y: H.y, n: `본진 지키기 (본진 ${Math.ceil(H.hp / H.max * 100)}%)` };
    const open = A.camps.filter((c) => !c.cap); if (open.length) { const c = open.reduce((a, b) => Math.hypot(b.x - p.x, b.y - p.y) < Math.hypot(a.x - p.x, a.y - p.y) ? b : a); return { x: c.x, y: c.y, n: `${c.n} 점령 — ${c.lead ? `${c.ln} 격파` : `병력 ${Math.max(0, c.need - c.kills)} 남음`} (${A.capN}/3)` }; }
    if (!A.cyzDead) { const z = A.en.find((e) => e.k === 'cyz' && e.elite && !e.dead); return { x: z ? z.x : F1.cyz.x, y: z ? z.y : F1.cyz.y, n: '관문 너머 황건 장수 정원지 격파' }; }
    const b = A.boss; return { x: b ? b.x : F1.keep.x, y: b ? b.y : F1.keep.y, n: '장각 본진 — 천공장군 장각 격파' }; }
  function fieldHud() { const p = A.p; $('page').textContent = F1.n; $('pause').style.display = ''; $('bag').style.display = 'none'; $('swap').style.display = 'none'; $('hpw').style.display = 'none';
    const T = fieldTarget(), g = $('goal'), gh = `<b>목표</b>${T.n}`; g.hidden = false; if (g.innerHTML !== gh) g.innerHTML = gh;
    const h = `<span class="tag">처치 ${A.kills}</span><span class="tag" style="border-color:#4a7ab8">본진 ${Math.ceil(A.home.hp / A.home.max * 100)}%</span><span class="tag" style="border-color:#6a9ad8">아군 ${A.al.length}</span>${[...ACT, ...PAS].filter((k) => sk(k)).map((k) => `<span class="tag" style="border-color:${SK[k].c}">${SK[k].g}${A.evo[k] ? '진' : sk(k)}</span>`).join('')}`; if ($('tags').innerHTML !== h) $('tags').innerHTML = h;
    // 버튼: 말 · 무쌍
    const bh = $('bHorse'), Hs = A.horse; if (!Hs) bh.style.display = 'none'; else { bh.style.display = ''; const lab = A.ride ? '내리기' : Hs.st === 'down' ? `${Math.ceil(Hs.t)}초` : insideWalls(p) ? '진영 안' : Math.hypot(Hs.x - p.x, Hs.y - p.y) < 44 ? '타기' : Hs.st === 'come' ? '오는 중' : '부르기'; if (bh.dataset.l !== lab) { bh.dataset.l = lab; bh.innerHTML = `<i>馬</i><b>${lab}</b>`; } bh.disabled = Hs.st === 'down' || (!A.ride && !!insideWalls(p)); bh.style.setProperty('--hp', `${Hs.hp / Hs.max * 100}%`); }
    const bm = $('bMusou'); bm.style.setProperty('--g', `${A.mg}%`); bm.classList.toggle('full', A.mg >= 100 && A.musouT <= 0); }
  // ── 그리기
  let FD_TREES = null;
  function fdTrees() { if (FD_TREES) return FD_TREES; const r = seeded(17), out = [], C = F1; for (let i = 0; i < 90; i++) { const x = 20 + r() * (C.W - 40), y = 120 + r() * (C.H - 300); const near = (q, m) => Math.abs(q.x - x) < q.w / 2 + m && Math.abs(q.y - y) < q.h / 2 + m;
      if (A.camps.some((c) => near(c, 40)) || near(C.keep, 40) || Math.abs(x - 420) < 60 || (y > C.river.y0 - 30 && y < C.river.y1 + 30) || Math.hypot(x - C.village.x, y - C.village.y) < 110 || Math.hypot(x - C.home.x, y - C.home.y) < 140 || Math.abs(y - C.gate.y) < 40) continue; out.push({ x, y, k: i % 3 }); } return (FD_TREES = out); }
  function fieldBg() { const VH = A.VH, C = F1; ctx.fillStyle = '#2a3a1e'; ctx.fillRect(OX, OY, AW * SC, VH * SC); const ch = muChunk(), cs = 256; ctx.imageSmoothingEnabled = false;
    for (let gy = Math.floor(CAMY / cs) * cs; gy < CAMY + VH; gy += cs) for (let gx = Math.floor(CAMX / cs) * cs; gx < CAMX + AW; gx += cs) ctx.drawImage(ch, X(gx), Y(gy), cs * SC + 1, cs * SC + 1);
    // 길
    ctx.lineCap = 'round'; ctx.lineJoin = 'round'; for (const [w, col] of [[30, '#9a7a4a'], [24, '#c8a874']]) { ctx.strokeStyle = col; ctx.lineWidth = w * SC; for (const rd of C.roads) { ctx.beginPath(); rd.forEach(([x, y], i) => (i ? ctx.lineTo(X(x), Y(y)) : ctx.moveTo(X(x), Y(y)))); ctx.stroke(); } }
    // 강 · 다리
    const R = C.river; if (R.y1 > CAMY && R.y0 < CAMY + VH) { ctx.fillStyle = '#4a7ab8'; ctx.fillRect(X(0), Y(R.y0), C.W * SC, (R.y1 - R.y0) * SC); ctx.strokeStyle = 'rgba(207,226,244,0.6)'; ctx.lineWidth = 1.5; for (let i = 0; i < 40; i++) { const x = (i * 97 + A.t * 18) % C.W, y = R.y0 + 10 + (i * 37) % (R.y1 - R.y0 - 20); ctx.beginPath(); ctx.moveTo(X(x), Y(y)); ctx.lineTo(X(x + 14), Y(y)); ctx.stroke(); }
      ctx.fillStyle = '#3a5a90'; ctx.fillRect(X(0), Y(R.y0), C.W * SC, 3 * SC); for (const [a, b] of R.bridges) { ctx.fillStyle = '#8a6a3a'; ctx.fillRect(X(a), Y(R.y0 - 6), (b - a) * SC, (R.y1 - R.y0 + 12) * SC); ctx.fillStyle = '#a8845a'; for (let y = R.y0 - 4; y < R.y1 + 4; y += 8) ctx.fillRect(X(a + 3), Y(y), (b - a - 6) * SC, 5 * SC); ctx.fillStyle = '#5a3a1a'; ctx.fillRect(X(a), Y(R.y0 - 6), 4 * SC, (R.y1 - R.y0 + 12) * SC); ctx.fillRect(X(b - 4), Y(R.y0 - 6), 4 * SC, (R.y1 - R.y0 + 12) * SC); } }
    // 나무(장식)
    if (TILE.bigTree) for (const tr of fdTrees()) { if (tr.x < CAMX - 30 || tr.x > CAMX + AW + 30 || tr.y < CAMY - 30 || tr.y > CAMY + VH + 30) continue; ctx.drawImage(TILE.bigTree[tr.k], X(tr.x - 16), Y(tr.y - 24), 32 * SC, 32 * SC); }
    // 아군 본진
    const H = A.home; if (H.y - 120 < CAMY + VH) { ctx.fillStyle = 'rgba(200,168,116,0.55)'; ctx.beginPath(); ctx.ellipse(X(H.x), Y(H.y), (H.r + 30) * SC, (H.r + 6) * SC, 0, 0, 7); ctx.fill(); for (const [dx, dy] of [[-48, -6], [0, -20], [48, -6]]) fdTent(H.x + dx, H.y + dy, '#e8e0d0', '#4a7ab8'); fdFlag(H.x - 70, H.y - 30, '#4a7ab8', '劉'); fdFlag(H.x + 70, H.y - 30, '#4a7ab8', '關'); fdLabel('아군 본진', H.x, H.y + 30, '#cfe2f4'); if (H.hp < H.max) fdBar(H.x, H.y - 50, 80, H.hp / H.max, '#4a7ab8'); }
    // 탁현 마을
    const V = A.vil; for (const [dx, dy] of [[-26, -14], [22, -20], [0, 18]]) fdHouse(V.x + dx, V.y + dy, V.st === 'lost'); fdLabel(V.st === 'lost' ? '탁현 마을(불탐)' : '탁현 마을', V.x, V.y + 42, V.st === 'raid' ? '#ffb0a0' : '#fff2c0'); if (V.st === 'raid') { fdBar(V.x, V.y - 44, 70, V.hp / V.max, '#d9705e'); if (Math.floor(A.t * 3) % 2) { ctx.strokeStyle = 'rgba(217,80,60,0.8)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(X(V.x), Y(V.y), (V.r + 10) * SC, 0, 7); ctx.stroke(); } }
    // 진영 · 관문 · 본진 벽
    for (const c of A.camps) { if (c.y + c.h < CAMY - 40 || c.y - c.h > CAMY + VH + 40) continue; ctx.fillStyle = c.cap ? 'rgba(160,190,220,0.25)' : 'rgba(150,110,60,0.3)'; ctx.fillRect(X(c.x - c.w / 2), Y(c.y - c.h / 2), c.w * SC, c.h * SC); for (const [dx, dy] of [[-70, -40], [60, -45], [-60, 30], [70, 25]]) fdTent(c.x + dx, c.y + dy, c.cap ? '#e8e0d0' : '#d8b860', c.cap ? '#4a7ab8' : '#a8782a'); fdFlag(c.x, c.y - 10, c.cap ? '#4a7ab8' : '#d8b040', c.cap ? '關' : '黃');
      fdLabel(c.cap ? `${c.n} — 점령` : `${c.n} · ${c.lead ? c.ln : `병력 ${Math.max(0, c.need - c.kills)}`}`, c.x, c.y - c.h / 2 - 14, c.cap ? '#cfe2f4' : '#ffd8a0'); }
    for (const o of A.obs) { if (o.k === 'water' || o.y > CAMY + VH + 20 || o.y + o.h < CAMY - 20) continue; if (o.tag === 'camp') fdPalisade(o); else fdStone(o); }
    const K = C.keep; if (K.y + K.h / 2 > CAMY) fdLabel(A.keepOpen ? '장각 본진' : '장각 본진(닫힘)', K.x, K.y - K.h / 2 - 14, '#ffb0a0');
    muFloorFx(); }
  function fdTent(x, y, cl, rf) { ctx.fillStyle = 'rgba(0,0,0,0.2)'; ctx.fillRect(X(x - 15), Y(y + 10), 30 * SC, 4 * SC); ctx.fillStyle = cl; ctx.beginPath(); ctx.moveTo(X(x), Y(y - 16)); ctx.lineTo(X(x + 16), Y(y + 10)); ctx.lineTo(X(x - 16), Y(y + 10)); ctx.fill(); ctx.strokeStyle = rf; ctx.lineWidth = 2 * SC; ctx.stroke(); ctx.fillStyle = '#3a2a1a'; ctx.beginPath(); ctx.moveTo(X(x), Y(y - 2)); ctx.lineTo(X(x + 5), Y(y + 10)); ctx.lineTo(X(x - 5), Y(y + 10)); ctx.fill(); }
  function fdFlag(x, y, col, g) { ctx.fillStyle = '#5a3a1a'; ctx.fillRect(X(x - 1.5), Y(y - 34), 3 * SC, 40 * SC); const wv = Math.sin((A ? A.t : WS.t) * 4 + x) * 2; ctx.fillStyle = col; ctx.beginPath(); ctx.moveTo(X(x + 1.5), Y(y - 34)); ctx.lineTo(X(x + 24), Y(y - 31 + wv)); ctx.lineTo(X(x + 24), Y(y - 15 + wv)); ctx.lineTo(X(x + 1.5), Y(y - 18)); ctx.fill(); glyph(g, x + 12, y - 25 + wv * 0.5, 10, '#fffaf0'); }
  function fdHouse(x, y, burnt) { ctx.fillStyle = burnt ? '#3a3028' : '#d8c8a8'; ctx.fillRect(X(x - 14), Y(y - 6), 28 * SC, 16 * SC); ctx.fillStyle = burnt ? '#1d1813' : '#8a5a3a'; ctx.beginPath(); ctx.moveTo(X(x - 18), Y(y - 6)); ctx.lineTo(X(x), Y(y - 20)); ctx.lineTo(X(x + 18), Y(y - 6)); ctx.fill(); ctx.fillStyle = '#5a3a1a'; ctx.fillRect(X(x - 3), Y(y + 2), 6 * SC, 8 * SC); if (burnt) { ctx.fillStyle = 'rgba(90,80,70,0.5)'; ctx.beginPath(); ctx.arc(X(x + 4), Y(y - 26 - ((A ? A.t : WS.t) * 8) % 10), 6 * SC, 0, 7); ctx.fill(); } }
  function fdPalisade(o) { const post = (x, y) => { ctx.fillStyle = '#6a4a2a'; ctx.fillRect(X(x - 3), Y(y - 12), 6 * SC, 16 * SC); ctx.fillStyle = '#a8784a'; ctx.fillRect(X(x - 3), Y(y - 12), 6 * SC, 3 * SC); }; ctx.fillStyle = '#5a3a1a'; ctx.fillRect(X(o.x), Y(o.y + o.h / 2 - 2), o.w * SC, 4 * SC);
    if (o.w >= o.h) for (let x = o.x + 4; x <= o.x + o.w - 2; x += 9) post(x, o.y + o.h / 2); else for (let y = o.y + 4; y <= o.y + o.h; y += 9) post(o.x + o.w / 2, y); }
  function fdStone(o) { ctx.fillStyle = o.door ? '#7a4a24' : '#8a8478'; ctx.fillRect(X(o.x), Y(o.y), o.w * SC, o.h * SC); ctx.strokeStyle = o.door ? '#3a2410' : '#5a564c'; ctx.lineWidth = 1.5; ctx.strokeRect(X(o.x), Y(o.y), o.w * SC, o.h * SC);
    if (o.door) { ctx.fillStyle = '#c8a050'; ctx.fillRect(X(o.x + o.w / 2 - 2), Y(o.y + 2), 4 * SC, (o.h - 4) * SC); } else { ctx.strokeStyle = 'rgba(60,56,48,0.6)'; ctx.lineWidth = 1; const horiz = o.w >= o.h; for (let s = 14; s < (horiz ? o.w : o.h); s += 14) { ctx.beginPath(); if (horiz) { ctx.moveTo(X(o.x + s), Y(o.y)); ctx.lineTo(X(o.x + s), Y(o.y + o.h)); } else { ctx.moveTo(X(o.x), Y(o.y + s)); ctx.lineTo(X(o.x + o.w), Y(o.y + s)); } ctx.stroke(); } } }
  function fdLabel(s, x, y, col) { ctx.font = `700 ${Math.round(10 * SC)}px "Gowun Dodum", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(29,24,19,0.85)'; ctx.strokeText(s, X(x), Y(y)); ctx.fillStyle = col; ctx.fillText(s, X(x), Y(y)); }
  function fdBar(x, y, w, f, col) { ctx.fillStyle = '#3a3024'; ctx.fillRect(X(x - w / 2), Y(y), w * SC, 5 * SC); ctx.fillStyle = col; ctx.fillRect(X(x - w / 2), Y(y), w * SC * Math.max(0, f), 5 * SC); }
  // 관우(말 위면 말 + 탄 관우). 걸어서면 false → 보통 그리기
  function fieldDrawHero() { const p = A.p, Hs = A.horse, blink = p.inv > 0 && Math.floor(p.inv * 20) % 2 && A.musouT <= 0;
    if (A.musouT > 0) { ctx.fillStyle = `rgba(255,210,90,${0.25 + 0.15 * Math.sin(A.t * 30)})`; ctx.beginPath(); ctx.arc(X(p.x), Y(p.y), 30 * SC, 0, 7); ctx.fill(); }
    const HW = NS[A.hspr || 'a_horseS'] || NS.a_horse; if (!A.ride || !Hs || !NINJA || !HW) return false; const mv = Math.hypot(p.vx, p.vy) > 10, bob = mv ? Math.abs(Math.sin(A.t * 14)) * 2 : 0;
    sprAt(HW, Hs.fd || 'right', Math.floor(A.t * (mv ? 9 : 1.5)), p.x, p.y + 8, 44, false, blink ? 0.4 : 1); riderAt(NS[A.hero], Hs.fd === 'left' ? 'left' : 'right', p.x + (Hs.fd === 'left' ? 3 : -3), p.y - 10 - bob, 28, blink ? 0.4 : 1); return true; }
  function fieldOver() { const p = A.p, Hs = A.horse;
    if (Hs && !A.ride && NINJA && (NS[A.hspr || 'a_horseS'] || NS.a_horse)) { ctx.globalAlpha = Hs.st === 'down' ? 0.45 : 1; sprAt(NS[A.hspr || 'a_horseS'] || NS.a_horse, Hs.fd || 'right', Hs.st === 'come' ? Math.floor(A.t * 9) : 0, Hs.x, Hs.y, 40, false); ctx.globalAlpha = 1; if (Hs.st !== 'come') fdLabel(Hs.st === 'down' ? `${HORSES[wSV().hk] ? HORSES[wSV().hk].n : '말'} ${Math.ceil(Hs.t)}초` : (HORSES[wSV().hk] || HORSES.red).n, Hs.x, Hs.y - 22, '#ffd8a0'); }
    const bw = 30, by = p.y + (A.ride ? 22 : 18); ctx.fillStyle = '#3a3024'; ctx.fillRect(X(p.x - bw / 2), Y(by), bw * SC, 4 * SC); ctx.fillStyle = p.hp / p.max < 0.3 ? '#d9705e' : '#6fae6a'; ctx.fillRect(X(p.x - bw / 2), Y(by), bw * SC * p.hp / p.max, 4 * SC);
    if (A.ride && Hs) { ctx.fillStyle = '#3a3024'; ctx.fillRect(X(p.x - bw / 2), Y(by + 5), bw * SC, 3 * SC); ctx.fillStyle = '#c8884a'; ctx.fillRect(X(p.x - bw / 2), Y(by + 5), bw * SC * Hs.hp / Hs.max, 3 * SC); }
    if (p.stunT <= 0) fdWeapon(); if (p.stunT > 0) fdLabel('넘어짐!', p.x, p.y - 30, '#ffb0a0'); }
  // 화면 위 겹쳐 그리기(작은 지도 · 목표 화살표 · 연격 수)
  function fieldOverlay() { const C = F1, p = A.p, VH = A.VH;
    // 목표 화살표(화면 밖일 때)
    const T = fieldTarget(), sx = X(T.x), sy = Y(T.y), x0 = OX + 16, x1 = OX + AW * SC - 16, y0 = OY + 40, y1 = OY + VH * SC - 16;
    if (sx < x0 || sx > x1 || sy < y0 || sy > y1) { const cx = X(p.x), cy = Y(p.y), a = Math.atan2(sy - cy, sx - cx); let k = 1e9; if (Math.cos(a) > 0.01) k = Math.min(k, (x1 - cx) / Math.cos(a)); if (Math.cos(a) < -0.01) k = Math.min(k, (x0 - cx) / Math.cos(a)); if (Math.sin(a) > 0.01) k = Math.min(k, (y1 - cy) / Math.sin(a)); if (Math.sin(a) < -0.01) k = Math.min(k, (y0 - cy) / Math.sin(a));
      const ax = cx + Math.cos(a) * k, ay = cy + Math.sin(a) * k, pul = 1 + 0.12 * Math.sin(A.t * 8); ctx.save(); ctx.translate(ax, ay); ctx.rotate(a); ctx.fillStyle = A.vil.st === 'raid' || T.n.startsWith('본진') ? '#ff8a6a' : '#ffd34a'; ctx.strokeStyle = '#1d1813'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(12 * pul, 0); ctx.lineTo(-8 * pul, -9 * pul); ctx.lineTo(-4 * pul, 0); ctx.lineTo(-8 * pul, 9 * pul); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore();
      ctx.font = '700 11px "Gowun Dodum", sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; const lx = clamp(ax - Math.cos(a) * 26, x0 + 22, x1 - 22), ly = clamp(ay - Math.sin(a) * 18, y0 + 6, y1 - 6), tx = `${Math.round(Math.hypot(T.x - p.x, T.y - p.y) / 10)}보`; ctx.lineWidth = 3; ctx.strokeStyle = '#1d1813'; ctx.strokeText(tx, lx, ly); ctx.fillStyle = '#fff2c0'; ctx.fillText(tx, lx, ly); }
    // 작은 지도
    const mw = 44, mh = Math.round(mw * C.H / C.W), mx = OX + AW * SC - mw - 6, my = OY + 26, s = mw / C.W, P = (x, y) => [mx + x * s, my + y * s];
    A.mmR = [mx, my, mw, mh]; ctx.fillStyle = 'rgba(29,24,19,0.62)'; ctx.fillRect(mx - 2, my - 2, mw + 4, mh + 14); ctx.font = '700 9px "Gowun Dodum", sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#fff2c0'; ctx.fillText('지도 ▸', mx + mw / 2, my + mh + 6); ctx.fillStyle = 'rgba(90,120,60,0.55)'; ctx.fillRect(mx, my, mw, mh);
    ctx.fillStyle = '#4a7ab8'; ctx.fillRect(mx, my + C.river.y0 * s, mw, (C.river.y1 - C.river.y0) * s); ctx.fillStyle = A.capN >= 3 ? 'rgba(138,132,120,0.6)' : '#8a8478'; ctx.fillRect(mx, my + (C.gate.y - 10) * s, mw, 2);
    const K = C.keep; ctx.strokeStyle = A.boss ? '#ff6a4a' : '#d9705e'; ctx.lineWidth = 1.5; ctx.strokeRect(mx + (K.x - K.w / 2) * s, my + (K.y - K.h / 2) * s, K.w * s, K.h * s);
    for (const c of A.camps) { ctx.fillStyle = c.cap ? '#6a9ad8' : '#e2b040'; ctx.fillRect(mx + (c.x - c.w / 2) * s, my + (c.y - c.h / 2) * s, c.w * s, c.h * s); }
    const [vx, vy] = P(A.vil.x, A.vil.y); ctx.fillStyle = A.vil.st === 'raid' ? (Math.floor(A.t * 4) % 2 ? '#ff6a4a' : '#ffd34a') : A.vil.st === 'lost' ? '#555' : '#e8d8a8'; ctx.fillRect(vx - 2.5, vy - 2.5, 5, 5);
    const [hx, hy] = P(A.home.x, A.home.y); ctx.fillStyle = A.home.hp < A.home.max * 0.5 && Math.floor(A.t * 4) % 2 ? '#ff6a4a' : '#6a9ad8'; ctx.fillRect(hx - 3, hy - 3, 6, 6);
    if (!A.cyzDead && A.cyzOn) { const z = A.en.find((e) => e.k === 'cyz' && e.elite); if (z) { const [zx, zy] = P(z.x, z.y); ctx.fillStyle = '#ff6a4a'; ctx.beginPath(); ctx.arc(zx, zy, 2.5, 0, 7); ctx.fill(); } }
    if (A.boss) { const [bx, by] = P(A.boss.x, A.boss.y); ctx.fillStyle = '#ff6a4a'; ctx.beginPath(); ctx.arc(bx, by, 3, 0, 7); ctx.fill(); }
    for (const e of A.en) if (e.goal === A.home && !e.dead) { const [ex, ey] = P(e.x, e.y); ctx.fillStyle = '#ff8a6a'; ctx.fillRect(ex - 0.8, ey - 0.8, 1.6, 1.6); }
    ctx.fillStyle = '#9ac0f0'; for (const a of A.al) { const [ax, ay] = P(a.x, a.y); ctx.fillRect(ax - 0.8, ay - 0.8, 1.6, 1.6); }
    if (A.horse && !A.ride) { const [qx, qy] = P(A.horse.x, A.horse.y); ctx.fillStyle = '#c8884a'; ctx.fillRect(qx - 1.5, qy - 1.5, 3, 3); }
    ctx.strokeStyle = 'rgba(255,250,240,0.7)'; ctx.lineWidth = 1; ctx.strokeRect(mx + CAMX * s, my + CAMY * s, AW * s, VH * s); const [px, py] = P(p.x, p.y); ctx.fillStyle = '#fffaf0'; ctx.beginPath(); ctx.arc(px, py, 2.5, 0, 7); ctx.fill();
    // 연격 수
    if (A.cbN > 0) { const st = cbStage(), col = CB_COL[st], al = Math.max(0.35, 1 - Math.max(0, A.cb.idle - 1.2)), rx = mx - 10, ry = my + mh + 34; ctx.globalAlpha = al; ctx.textAlign = 'right'; ctx.textBaseline = 'alphabetic'; ctx.lineWidth = 4; ctx.strokeStyle = '#1d1813';
      ctx.font = `700 ${st === 3 ? 30 : st === 2 ? 27 : 24}px "Gowun Batang", serif`; ctx.strokeText(A.cbN, rx, ry); ctx.fillStyle = col[0]; ctx.fillText(A.cbN, rx, ry); ctx.font = '700 12px "Gowun Dodum", sans-serif'; ctx.strokeText('연격', rx, ry + 16); ctx.fillStyle = col[1]; ctx.fillText('연격', rx, ry + 16); ctx.globalAlpha = 1; }
    if (A.cbPop) { const f = A.cbPop, k = Math.min(1, (1.3 - f.t) * 6), al = Math.min(1, f.t * 2); ctx.globalAlpha = al; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.font = `700 ${Math.round(26 + 10 * (1 - k))}px "Gowun Batang", serif`; ctx.lineWidth = 5; ctx.strokeStyle = '#1d1813'; const yy = OY + VH * SC * 0.32 - (1.3 - f.t) * 14; ctx.strokeText(f.v, W / 2, yy); ctx.fillStyle = f.c; ctx.fillText(f.v, W / 2, yy); ctx.globalAlpha = 1; }
    if (A.musouT > 0) { const g = ctx.createRadialGradient(W / 2, OY + VH * SC / 2, Math.min(W, H) * 0.3, W / 2, OY + VH * SC / 2, Math.max(W, H) * 0.7); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(60,30,0,0.45)'); ctx.fillStyle = g; ctx.fillRect(OX, OY, AW * SC, VH * SC); } }
  $('bHorse').onpointerdown = (e) => { e.preventDefault(); e.stopPropagation(); horseBtn(); };
  $('bMusou').onpointerdown = (e) => { e.preventDefault(); e.stopPropagation(); musouGo(); };
  // ═════════ v0.15: 그림 다듬기 · 청룡언월도 · 길찾기 · 전장 지도 ═════════
  // 관우(녹건 · 붉은 얼굴 · 검은 수염) · 장각(누런 두건)을 Ninja Adventure 인물 색을 바꿔 만듦
  let FD_ART = false;
  function fdArt() { if (FD_ART || !NINJA || !NS.p_guanyu || !NS.e_zj) return; FD_ART = true;
    if (NS.bb_gy) { NS.gy_green = NS.bb_gy; NS.gy_iron = NS.bb_gyI; NS.gy_gold = NS.bb_gyG; NS.p_guanyu = NS.gy_green; return; } // B.B.Bits 그림: 갑옷별 그림이 따로 있음
    const hex = (h) => [parseInt(h.slice(1, 3), 16), parseInt(h.slice(3, 5), 16), parseInt(h.slice(5, 7), 16)];
    const swap = (w, mp) => { const M = Object.entries(mp).map(([a, b]) => [hex(a), hex(b)]), fr = {};
      for (const d of DIRS) for (let r = 0; r < w.rows; r++) { const src = w.frame(d, r); fr[d + r] = mk(src.width, src.height, (g) => { g.drawImage(src, 0, 0); const im = g.getImageData(0, 0, src.width, src.height), px = im.data;
        for (let i = 0; i < px.length; i += 4) { if (!px[i + 3]) continue; for (const [a, b] of M) if (px[i] === a[0] && px[i + 1] === a[1] && px[i + 2] === a[2]) { px[i] = b[0]; px[i + 1] = b[1]; px[i + 2] = b[2]; break; } } g.putImageData(im, 0, 0); }); }
      return { walker: true, rows: w.rows, frame: (dir, f) => fr[dir + (f % w.rows)] || fr.down0 }; };
    const G0 = NS.p_guanyu, base = { '#fce2ca': '#cf5a3e', '#c8966b': '#9a3a28', '#d14b34': '#1d1813', '#8f3e56': '#2a1c18' };
    NS.gy_green = swap(G0, { ...base, '#4e484a': '#3f7a3a', '#3b3643': '#2c5a30', '#56864c': '#7ab04a', '#a8a129': '#e2b85a' });
    NS.gy_iron = swap(G0, { ...base, '#4e484a': '#5a6470', '#3b3643': '#4a5260', '#56864c': '#a8b0b8', '#a8a129': '#d8dce0' });
    NS.gy_gold = swap(G0, { ...base, '#4e484a': '#3f7a3a', '#3b3643': '#1f4a2a', '#56864c': '#e2b85a', '#a8a129': '#fff0a0' }); NS.p_guanyu = NS.gy_green;
    NS.e_zj = swap(NS.e_zj, { '#c8966b': '#e8c040', '#8f3e56': '#b88a2a', '#56864c': '#e8e0c8', '#a8a129': '#c89a30', '#d78b4a': '#f0d060', '#f1c471': '#fff0a0' }); }
  // 청룡언월도: 평소엔 비스듬히 들고, 벨 때 칼날이 호를 그리며 돎(찌르기는 앞으로 뻗음)
  function fdSwingFx(a, arc, kind, T) { A.wsw = { a0: kind === 'spin' ? a : a - arc / 2 * (A.cb.side || 1), a1: kind === 'spin' ? a + Math.PI * 2 : a + arc / 2 * (A.cb.side || 1), t: T, T, thrust: kind === 'thrust' }; }
  function fdWeapon() { const p = A.p, S = A.wsw, ride = A.ride && A.horse; let a, len = 30;
    if (S && S.t > 0) { const k = 1 - S.t / S.T, e = 1 - (1 - k) * (1 - k); a = S.a0 + (S.a1 - S.a0) * e; if (S.thrust) len = 24 + 18 * Math.sin(k * Math.PI); }
    else { const fx = ride ? (A.horse.fd === 'left' ? -1 : 1) : p.fx; a = fx < -0.2 ? -2.25 : fx > 0.2 ? -0.9 : p.fy < 0 ? -1.35 : -1.75; }
    const hx = p.x + (ride ? 0 : 2), hy = p.y + (ride ? -12 : 1); drawGuandao(ctx, X(hx), Y(hy), a, len * SC, SC, A.wtier || 0); }
  // ── 길찾기: 20px 칸. 벽 칸은 막고, 관우 · 본진 · 마을까지의 칸 거리를 BFS로(흐름장). 가는 길이 트였으면 곧장, 막혔으면 흐름을 따라 문으로 돌아감
  const FG = 20; let FDG = null;
  function fdGridBuild() { const C = F1, gw = Math.ceil(C.W / FG), gh = Math.ceil(C.H / FG), blk = new Uint8Array(gw * gh);
    for (const o of A.obs) { if (o.k !== 'wall' && o.k !== 'water') continue; const x0 = Math.max(0, Math.floor((o.x - 4) / FG)), x1 = Math.min(gw - 1, Math.floor((o.x + o.w + 3) / FG)), y0 = Math.max(0, Math.floor((o.y - 4) / FG)), y1 = Math.min(gh - 1, Math.floor((o.y + o.h + 3) / FG)); for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) blk[y * gw + x] = 1; }
    FDG = { gw, gh, blk, ver: A.obsVer, f: {} }; }
  function fdField(key, tx, ty) { if (!FDG || FDG.ver !== A.obsVer) fdGridBuild(); const G = FDG, { gw, gh, blk } = G, cx = clamp(Math.floor(tx / FG), 0, gw - 1), cy = clamp(Math.floor(ty / FG), 0, gh - 1), src = cy * gw + cx; let F = G.f[key];
    if (F && F.src === src) return F; if (F && key === 'p' && A.t - F.at < 0.2) return F;
    const d = new Int16Array(gw * gh).fill(-1), q = new Int32Array(gw * gh); let h = 0, n = 0; d[src] = 0; q[n++] = src;
    while (h < n) { const c = q[h++], x = c % gw, y = (c / gw) | 0, dc = d[c] + 1; if (x > 0 && d[c - 1] < 0 && !blk[c - 1]) { d[c - 1] = dc; q[n++] = c - 1; } if (x < gw - 1 && d[c + 1] < 0 && !blk[c + 1]) { d[c + 1] = dc; q[n++] = c + 1; } if (y > 0 && d[c - gw] < 0 && !blk[c - gw]) { d[c - gw] = dc; q[n++] = c - gw; } if (y < gh - 1 && d[c + gw] < 0 && !blk[c + gw]) { d[c + gw] = dc; q[n++] = c + gw; } }
    return (G.f[key] = { src, d, at: A.t }); }
  function fdClear(ax, ay, bx, by) { const G = FDG, n = Math.ceil(Math.hypot(bx - ax, by - ay) / (FG * 0.5)); for (let i = 1; i < n; i++) { const t = i / n, x = (ax + (bx - ax) * t) / FG | 0, y = (ay + (by - ay) * t) / FG | 0; if (x >= 0 && y >= 0 && x < G.gw && y < G.gh && G.blk[y * G.gw + x]) return false; } return true; }
  function fdPath(e, tgt) { const key = tgt === A.p ? 'p' : tgt === A.home ? 'h' : tgt === A.vil ? 'v' : null; if (!key || Math.hypot(tgt.x - e.x, tgt.y - e.y) < 40) return tgt;
    if (e.pthT > A.t && e.pthK === key) return e.pth || tgt; e.pthT = A.t + 0.18 + Math.random() * 0.08; e.pthK = key;
    const F = fdField(key, tgt.x, tgt.y), G = FDG; if (fdClear(e.x, e.y, tgt.x, tgt.y)) { e.pth = null; return tgt; }
    let cx = clamp(Math.floor(e.x / FG), 0, G.gw - 1), cy = clamp(Math.floor(e.y / FG), 0, G.gh - 1), c = cy * G.gw + cx; if (F.d[c] < 0) { e.pth = null; return tgt; }
    for (let s = 0; s < 3; s++) { const x = c % G.gw, y = (c / G.gw) | 0; let b = c; for (const o of [-1, 1, -G.gw, G.gw]) { const nc = c + o; if ((o === -1 && x === 0) || (o === 1 && x === G.gw - 1) || nc < 0 || nc >= F.d.length) continue; if (F.d[nc] >= 0 && F.d[nc] < F.d[b]) b = nc; } if (b === c) break; c = b; }
    e.pth = { x: (c % G.gw + 0.5) * FG, y: (((c / G.gw) | 0) + 0.5) * FG }; return e.pth; }
  // ── 전장 지도(작은 지도를 누르거나 M): 판을 멈추고 전체를 크게
  function fieldMapOpen() { if (!A || !A.map || A.state !== 'play') return; A.state = 'pause'; joy.on = false; const C = F1, Hc = Math.round(Math.min(innerHeight * 0.6, 540)), Wc = Math.round(Hc * C.W / C.H), T = fieldTarget();
    const st = (c) => (c.cap ? '<b style="color:#4a7ab8">점령</b>' : c.lead ? `<b style="color:#b8432f">${c.ln}</b>` : `병력 ${Math.max(0, c.need - c.kills)}`), V = A.vil;
    card(`<h2>전장 지도</h2><div class="fmap"><canvas id="fmc" width="${Wc * 2}" height="${Hc * 2}" style="width:${Wc}px;height:${Hc}px"></canvas><div class="fleg"><span class="now"><b>지금 목표</b>${T.n}</span>${A.camps.map((c) => `<span><i style="background:${c.cap ? '#6a9ad8' : '#e2b040'}"></i>${c.n} · ${st(c)}</span>`).join('')}<span><i style="background:${V.st === 'lost' ? '#555' : V.st === 'raid' ? '#ff6a4a' : '#e8d8a8'}"></i>탁현 마을 · ${V.st === 'wait' ? '조용함' : V.st === 'raid' ? `습격 중 ${Math.ceil(V.hp / V.max * 100)}%` : V.st === 'saved' ? '구함' : '불탐'}</span><span><i style="background:#6a9ad8"></i>아군 본진 · ${Math.ceil(A.home.hp / A.home.max * 100)}%</span><span><i style="background:#8a8478"></i>관문 · ${A.capN >= 3 ? '열림' : `진영 ${A.capN}/3 점령 시 열림`}</span><span><i style="background:#d9705e"></i>장각 본진 · ${A.keepOpen ? '열림' : '정원지를 쓰러뜨리면 열림'}</span><span style="color:var(--paper-muted)">흰 점 관우 · 파란 점 아군 · 갈색 적토마 · 빨간 점 황건 · 강은 다리로만</span></div></div><button class="go" type="button" id="cont">계속</button>`, (cc) => {
      const cv2 = cc.querySelector('#fmc'), g = cv2.getContext('2d'), s = (Wc * 2) / C.W, P = (x, y) => [x * s, y * s]; g.fillStyle = '#5a7a3c'; g.fillRect(0, 0, cv2.width, cv2.height);
      g.lineCap = 'round'; g.strokeStyle = '#c8a874'; g.lineWidth = 14 * s; for (const rd of C.roads) { g.beginPath(); rd.forEach(([x, y], i) => (i ? g.lineTo(...P(x, y)) : g.moveTo(...P(x, y)))); g.stroke(); }
      g.fillStyle = '#4a7ab8'; g.fillRect(0, C.river.y0 * s, cv2.width, (C.river.y1 - C.river.y0) * s); g.fillStyle = '#a8845a'; for (const [a, b] of C.river.bridges) g.fillRect(a * s, (C.river.y0 - 6) * s, (b - a) * s, (C.river.y1 - C.river.y0 + 12) * s);
      for (const o of A.obs) { if (o.k === 'water') continue; g.fillStyle = o.door ? '#7a4a24' : o.tag === 'camp' ? '#6a4a2a' : '#8a8478'; g.fillRect(o.x * s, o.y * s, Math.max(2, o.w * s), Math.max(2, o.h * s)); }
      for (const c of A.camps) { g.fillStyle = c.cap ? 'rgba(106,154,216,0.55)' : 'rgba(226,176,64,0.55)'; g.fillRect((c.x - c.w / 2) * s, (c.y - c.h / 2) * s, c.w * s, c.h * s); }
      const K = C.keep; g.fillStyle = 'rgba(217,112,94,0.35)'; g.fillRect((K.x - K.w / 2) * s, (K.y - K.h / 2) * s, K.w * s, K.h * s);
      const dot = (x, y, r, col, ring) => { g.fillStyle = col; g.beginPath(); g.arc(x * s, y * s, r, 0, 7); g.fill(); if (ring) { g.strokeStyle = ring; g.lineWidth = 2; g.stroke(); } };
      for (const a of A.al) dot(a.x, a.y, a.k === 'liubei' ? 4.5 : 1.8, '#6a9ad8', a.k === 'liubei' ? '#fffaf0' : null);
      for (const e of A.en) if (!e.dead) dot(e.x, e.y, e.elite || e.boss ? 5 : 1.6, e.elite || e.boss ? '#ff4a3a' : 'rgba(255,90,70,0.8)', e.elite || e.boss ? '#1d1813' : null);
      g.fillStyle = V.st === 'lost' ? '#555' : V.st === 'raid' ? '#ff6a4a' : '#e8d8a8'; g.fillRect(V.x * s - 6, V.y * s - 6, 12, 12); g.fillStyle = '#6a9ad8'; g.fillRect(A.home.x * s - 7, A.home.y * s - 7, 14, 14);
      if (A.horse && !A.ride) dot(A.horse.x, A.horse.y, 4, '#c8884a', '#1d1813'); g.strokeStyle = '#ffd34a'; g.lineWidth = 3; g.beginPath(); g.arc(T.x * s, T.y * s, 16, 0, 7); g.stroke(); dot(A.p.x, A.p.y, 6, '#fffaf0', '#1d1813');
      cc.querySelector('#cont').onclick = () => { closeCard(); A.state = 'play'; last = performance.now(); }; });
  }
  const fieldMapHit = (x, y) => A && A.mmR && x >= A.mmR[0] - 6 && x <= A.mmR[0] + A.mmR[2] + 6 && y >= A.mmR[1] - 6 && y <= A.mmR[1] + A.mmR[3] + 14;
  // ═════════ v0.16: 아군 · 강 ═════════
  // 아군: 본진 수비대(유비 + 창병) · 점령한 진영 수비대 · 점령한 진영에서 관우에게 합류하는 부대
  const AL = { sol: { n: '아군 창병', hp: 60, atk: 9, spd: 84, r: 10, spr: 'bb_mil', g: '창' }, liubei: { n: '유비', hp: 420, atk: 20, spd: 90, r: 12, spr: 'p_liubei', g: '유' } };
  function alSpawn(k, x, y, mode, anchor) { const D = AL[k], m = (1 + 0.15 * (A.capN || 0)) * (A.alMul || 1); const a = { side: 'al', k, x, y, r: D.r, hp: D.hp * m, max: D.hp * m, atk: D.atk * m, spd: D.spd, cd: rnd(0, 0.6), hitCd: 0, scan: 0, mode, anchor, tg: null, fd: 'down', lx: x, ly: y, slot: Math.random() * 6.28 }; A.al.push(a); A.fx.push({ k: 'ring', x, y, t: 0.35, r: 16, c: '#6a9ad8' }); return a; }
  function alTick(dt, G, cell) { const p = A.p;
    for (const a of A.al) { if (a.dead) continue; a.cd -= dt; a.hitCd -= dt; a.scan -= dt;
      if (a.scan <= 0) { a.scan = 0.3; const R = a.mode === 'join' ? 210 : a.anchor.r, cx = a.mode === 'join' ? p.x : a.anchor.x, cy = a.mode === 'join' ? p.y : a.anchor.y; let best = null, bd = 1e9;
        for (const e of A.en) { if (e.dead || e.air > 0 || Math.hypot(e.x - cx, e.y - cy) > R) continue; const d = Math.hypot(e.x - a.x, e.y - a.y); if (d < bd) { bd = d; best = e; } } a.tg = best; }
      if (a.tg && a.tg.dead) a.tg = null;
      let gx, gy, reach = 0; if (a.tg) { gx = a.tg.x; gy = a.tg.y; reach = a.r + a.tg.r + 5; } else if (a.mode === 'join') { gx = p.x + Math.cos(a.slot) * 46; gy = p.y + Math.sin(a.slot) * 46 + 10; reach = 10; } else { gx = a.anchor.x + Math.cos(a.slot) * 50; gy = a.anchor.y + Math.sin(a.slot) * 36; reach = 10; }
      const d = Math.hypot(gx - a.x, gy - a.y); a.lx = a.x; a.ly = a.y;
      if (d > reach) { const tgt = !a.tg && a.mode === 'join' && d > 120 ? fdPath(a, p) : { x: gx, y: gy }, mx = tgt.x - a.x, my = tgt.y - a.y, md = Math.hypot(mx, my) || 1, sp = a.spd * (a.mode === 'join' && !a.tg && d > 160 ? 2.2 : 1), s = Math.min(md, sp * dt); a.x += mx / md * s; a.y += my / md * s; pushOut(a); }
      else if (a.tg && a.cd <= 0) { a.cd = a.k === 'liubei' ? 0.6 : 0.8; dmgE(a.tg, a.atk); A.fx.push({ k: 'spark', x: a.tg.x, y: a.tg.y - 3, t: 0.15, a: Math.atan2(a.tg.y - a.y, a.tg.x - a.x), c: '#a8c8f0' }); }
      // 붙은 황건에게 맞음
      if (a.hitCd <= 0) { const cx = (a.x / cell) | 0, cy = (a.y / cell) | 0; let hit = 0; for (let i = -1; i <= 1 && !hit; i++) for (let j = -1; j <= 1 && !hit; j++) { const l = G.get((cx + i) * 4096 + cy + j); if (!l) continue; for (const e of l) if (!e.dead && !(e.air > 0) && Math.hypot(e.x - a.x, e.y - a.y) < e.r + a.r + 3) { hit = e.touch; break; } } if (hit) { a.hp -= hit * 0.6; a.hitCd = 0.6; } }
      if (a.hp <= 0) { a.dead = true; A.fx.push({ k: 'burst', x: a.x, y: a.y, t: 0.3, r: 6, c: '#6a9ad8' }); if (a.k === 'liubei') { A.lbT = 15; banner('유비가 물러났어요', '15초 뒤 본진으로 돌아와요'); } } }
    A.al = A.al.filter((a) => !a.dead); }
  function fdAllySetup() { A.al = []; const H = A.home; A.homeG = { x: H.x, y: H.y - 50, r: 230 }; alSpawn('liubei', H.x, H.y - 40, 'guard', A.homeG); for (let i = 0; i < 6; i++) alSpawn('sol', H.x + rnd(-60, 60), H.y - 30 + rnd(-20, 20), 'guard', A.homeG); A.homeT = 8; A.lbT = 0; }
  function fdAllyTimers(dt) { const H = A.home; A.homeT -= dt; if (A.homeT <= 0) { A.homeT = 7; if (A.al.filter((a) => a.anchor === A.homeG && a.k === 'sol').length < 6) alSpawn('sol', H.x + rnd(-40, 40), H.y, 'guard', A.homeG); }
    if (A.lbT > 0) { A.lbT -= dt; if (A.lbT <= 0) { alSpawn('liubei', H.x, H.y - 30, 'guard', A.homeG); banner('유비가 본진으로 돌아왔어요', ''); } }
    for (const c of A.camps) { if (!c.cap) continue; c.alT = (c.alT ?? 0) - dt; if (c.alT > 0) continue; c.alT = 18; const gate = { x: c.x, y: c.y + c.h / 2 + 24 };
      if (A.al.filter((a) => a.anchor === c.ag).length < 4) alSpawn('sol', gate.x + rnd(-20, 20), gate.y, 'guard', c.ag);
      if (A.al.filter((a) => a.mode === 'join').length < 10) for (let i = 0; i < 2; i++) alSpawn('sol', gate.x + rnd(-24, 24), gate.y + rnd(0, 14), 'join', null); } }
  // 황건이 아군과 붙으면 아군과 싸움(관우보다 가까울 때)
  function fdEngage(dt) { const p = A.p; for (const e of A.en) { if (e.dead || e.boss || e.noEng) continue; e.engT = (e.engT || Math.random() * 0.3) - dt; if (e.engT > 0) continue; e.engT = 0.3; let best = null, bd = 70; for (const a of A.al) { const d = Math.hypot(a.x - e.x, a.y - e.y); if (d < bd) { bd = d; best = a; } } e.engage = best && bd < Math.hypot(p.x - e.x, p.y - e.y) ? best : null; } }
  function fieldDrawAllies() { if (!A.al) return; for (const a of A.al) { if (a.x < CAMX - 30 || a.x > CAMX + AW + 30 || a.y < CAMY - 30 || a.y > CAMY + A.VH + 30) continue; const D = AL[a.k], w = NINJA && NS[D.spr], mv = Math.hypot(a.x - a.lx, a.y - a.ly) > 0.2;
      ctx.strokeStyle = 'rgba(106,154,216,0.9)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.ellipse(X(a.x), Y(a.y + a.r * 0.9), a.r * 1.1 * SC, a.r * 0.45 * SC, 0, 0, 7); ctx.stroke();
      if (mv) a.fd = dirOf(a.x - a.lx, a.y - a.ly); else if (a.tg) a.fd = dirOf(a.tg.x - a.x, a.tg.y - a.y);
      if (w) sprAt(w, a.fd, animF(mv, A.t + a.slot, 7), a.x, a.y, a.k === 'liubei' ? 28 : 24, false); else { circle(a.x, a.y, a.r, '#6a9ad8', '#1d1813'); glyph(D.g, a.x, a.y, 10, '#fffaf0'); }
      if (a.hp < a.max) fdBar(a.x, a.y - a.r - 10, a.k === 'liubei' ? 30 : 20, a.hp / a.max, '#6a9ad8'); if (a.k === 'liubei') fdLabel('유비', a.x, a.y - a.r - 18, '#cfe2f4'); } }
