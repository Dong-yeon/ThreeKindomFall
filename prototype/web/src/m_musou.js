  // ═════════ 관우 무쌍(D-163): 탕탕특공대식 — 관우 혼자 · 한 장 10분 · 레벨업마다 기술 · 기술 + 짝 패시브 = 진화 · 정예·보물 상자 · 마지막 장수 ═════════
  // 판 밖: 로비(금 · 강화 · 장 고르기). 판 안: 끌어서 이동만, 공격은 전부 자동
  const SK = {
    // 공격 기술(최대 Lv5) — evo: 짝 패시브가 있으면 Lv5 뒤 진화
    sword: { n: '청룡언월도', g: '청', act: true, c: '#4a8a5a', d: ['앞을 크게 벱니다', '피해 +15%', '범위가 넓어져요', '더 자주 벱니다', '피해 +20% · 범위 +10%'], evo: 'mu', en: '청룡 강림', ed: '둘레를 한 바퀴 베고 반달 바람을 날려요' },
    wave: { n: '언월파', g: '파', act: true, c: '#6ac08a', d: ['마무리 일격에 반달 바람이 나가요', '피해 +20%', '바람 +1', '피해 +20%', '바람 +1'], evo: 'mu', en: '질풍 언월', ed: '마무리마다 반달 바람 5줄기' },
    orbit: { n: '회전 언월', g: '회', act: true, c: '#8ab8a0', d: ['칼날 2개가 둘레를 돌아요', '피해 +25%', '칼날 +1', '돌기가 빨라져요', '칼날 +1'], evo: 'gap', en: '철벽 언월', ed: '칼날 6개가 넓게 돌아요' },
    arrow: { n: '화살 비', g: '시', act: true, c: '#b8a060', d: ['적 무리에 화살비를 내려요', '화살비 +1', '피해 +25%', '더 자주 내려요', '화살비 +2'], evo: 'ji', en: '만전 화살', ed: '하늘을 덮는 화살비' },
    fire: { n: '화계', g: '화', act: true, c: '#e0703a', d: ['불 항아리를 던져 땅을 태워요', '불길 +1', '오래 타요', '피해 +30%', '불길 +1'], evo: 'gun', en: '적벽 화공', ed: '거대한 불바다' },
    bolt: { n: '낙뢰', g: '뢰', act: true, c: '#e8d860', d: ['적에게 벼락을 떨어뜨려요', '벼락 +1', '피해 +25%', '더 자주 떨어져요', '벼락 +2'], evo: 'gap', en: '뇌신 강림', ed: '벼락이 사슬처럼 번져요' },
    // 패시브(최대 Lv5)
    mu: { n: '무력', g: '무', c: '#b8432f', d: ['공격 +10%'] },
    gap: { n: '갑옷', g: '갑', c: '#6a7a8a', d: ['받는 피해 −7%'] },
    sin: { n: '신속', g: '신', c: '#4a9ad8', d: ['이동 +8%'] },
    ji: { n: '지략', g: '지', c: '#8a6ac0', d: ['책략 재사용 −8%'] },
    gun: { n: '군량', g: '량', c: '#c89a40', d: ['초당 체력 회복 +0.4'] },
    gi: { n: '깃발', g: '깃', c: '#d85a7a', d: ['줍는 범위 +30%'] },
  };
  const MU_ON = true; // 처음 화면 = 관우 무쌍 로비(책방·줄다리기·군세 메뉴는 닫음, 코드는 남김)
  const ACT = ['wave', 'arrow', 'fire', 'bolt'], PAS = ['mu', 'gap', 'ji', 'gun']; // v0.14 지도 판: 8종(검 · 회전 언월 · 신속 · 깃발은 뺌)
  // 장(챕터): 10분, 시간표대로 적이 늘고 정예 · 무리 · 마지막 장수
  const MU_CH = [
    { id: 'c1', n: '1장 황건적의 난', boss: 'zj', len: 600, mix: [[0, [['ytb', 1]]], [90, [['ytb', 4], ['ytcav', 1]]], [210, [['ytb', 6], ['ytarch', 1], ['ytcav', 1]]], [360, [['ytb', 6], ['ytarch', 1], ['ytcav', 2], ['ytbig', 1]]], [480, [['ytb', 5], ['ytarch', 1.5], ['ytcav', 2], ['ytbig', 2]]]],
      elites: [{ t: 240, k: 'ytbig', n: '황건 역사 대장' }, { t: 390, k: 'cyz', n: '황건 장수 정원지' }, { t: 510, k: 'ytbig', n: '황건 역사 대장' }], swarms: [150, 300, 450, 560] },
    { id: 'c2', n: '2장 호뢰관', locked: true },
  ];
  const muSV = () => { if (!SV.mu) SV.mu = { gold: 0, atkLv: 0, hpLv: 0, best: {}, clears: 0, runs: 0 }; const M = SV.mu; if (M.glv == null) { M.glv = 1; M.gxp = 0; } if (M.horse == null) M.horse = true; return M; };
  const MU_UP = { atkLv: { n: '무력 단련', d: '공격 +8%', step: 0.08 }, hpLv: { n: '체력 단련', d: '체력 +10%', step: 0.1 } };
  const upCost = (lv) => 60 + 60 * lv;
  // ── 로비
  function lobbySurv() {
    setMode('title'); $('hud').hidden = true; $('talk').hidden = true; TALK.on = false; inputLock = false; $('act').hidden = true; A = null;
    const M = muSV(), pic = (() => { try { const w = NINJA && NS.p_guanyu; return w ? w.frame('down', 0).toDataURL() : ''; } catch (e) { return ''; } })();
    card(`<h2>관우 무쌍</h2><div class="lobby">${pic ? `<img class="pimg big" alt="" src="${pic}">` : '<span class="pimg big" style="display:flex;align-items:center;justify-content:center;font:700 2.4rem var(--f-display);color:#4a8a5a">關</span>'}<div><b>관우</b><span>청룡언월도 · 체력 ${Math.round(MU_HP * (1 + 0.1 * M.hpLv))} · 공격 ${Math.round(100 * (1 + 0.08 * M.atkLv))}%</span><span class="gold">금 ${M.gold}</span></div></div>
      <h3>장 고르기</h3>${MU_CH.map((c) => `<button class="opt" type="button" data-ch="${c.id}" ${c.locked ? 'disabled' : ''} style="grid-template-columns:1fr"><b>${c.n}${c.locked ? ' — 다음 시안' : ''}</b><span>${c.locked ? '' : `10분 버티고 마지막 장수를 쓰러뜨리면 클리어 · 최고 ${M.best[c.id] ? (M.best[c.id] >= c.len ? '클리어!' : fmtT(M.best[c.id])) : '기록 없음'}`}</span></button>`).join('')}
      <h3>강화</h3>${Object.keys(MU_UP).map((k) => { const U = MU_UP[k], lv = M[k], cost = upCost(lv); return `<button class="opt" type="button" data-up="${k}" ${M.gold >= cost ? '' : 'disabled'} style="grid-template-columns:1fr"><b>${U.n} Lv ${lv} → ${lv + 1}</b><span>${U.d} · 금 ${cost}</span></button>`; }).join('')}
      <p style="font-size:.8rem">끌어서 이동만 하면 관우가 알아서 싸워요. 레벨이 오르면 기술을 고르고, 기술을 Lv5까지 올린 뒤 짝 패시브가 있으면 <b>진화</b>해요.</p><button class="sub" type="button" id="reset">기록 지우기</button><p style="font-size:.75rem">시안 v0.13 · 그림·소리: Ninja Adventure (CC0, pixel-boy) · 소리 끄기는 오른쪽 위 ♪</p>`, (c) => {
      c.querySelectorAll('[data-ch]').forEach((b) => b.onclick = () => { closeCard(); startMu(b.dataset.ch); });
      c.querySelectorAll('[data-up]').forEach((b) => b.onclick = () => { const k = b.dataset.up, cost = upCost(M[k]); if (M.gold < cost) return; M.gold -= cost; M[k]++; saveSV(); sfx('accept', 0.4); lobby(); });
      c.querySelector('#reset').onclick = () => { resetSV(); lobby(); }; });
    if (!pic) setTimeout(() => { if (MODE === 'title' && !A && document.querySelector('#ov:not([hidden]) .lobby')) lobby(); }, 400); // 그림이 늦게 오면 다시 그림
  }
  // ── 판 시작
  function startMu(chId) {
    const C = MU_CH.find((c) => c.id === chId) || MU_CH[0], M = muSV();
    baseArena('mu'); A.pet = null; A.weap = null; A.squad = []; A.ch = C; A.hero = 'p_guanyu'; A.WW = 2400; A.WH = 2400; A.VH = 600; A.obs = [];
    const p = A.p; p.x = A.WW / 2; p.y = A.WH / 2; p.max = p.hp = Math.round(MU_HP * (1 + MU_UP.hpLv.step * M.hpLv)); p.atk = 10 * (1 + MU_UP.atkLv.step * M.atkLv); p.spd = 150; p.r = 12; p.body = bodyOf([]);
    A.sk = { sword: 1 }; A.skCd = { sword: 0.4 }; A.evo = {}; A.gems = []; A.drops = []; A.fires = []; A.warns = []; A.lvl = 1; A.xp = 0; A.lvlQ = 0; A.spawnAcc = 0; A.gold = 0; A.orbA = 0; A.boss = null; A.fence = null; A.eliteDone = {}; A.swarmDone = {}; A.chestQ = 0; A.regenAcc = 0;
    M.runs++; saveSV(); CAMX = p.x - AW / 2; CAMY = p.y - A.VH / 2; hudUpdate(); banner(C.n, '끌어서 피하기만 — 관우가 알아서 벱니다');
  }
  const sk = (k) => (A.sk && A.sk[k]) || 0;
  const eul = (s) => ((s.charCodeAt(s.length - 1) - 0xac00) % 28 ? '을' : '를');
  const muAtk = () => A.p.atk * (1 + 0.1 * sk('mu'));
  const muCd = () => Math.max(0.4, (1 - 0.08 * sk('ji')) * ((A && A.cdMul) || 1));
  const xpNeedM = (l) => (A && A.map ? Math.round(8 + 6 * l + 0.3 * l * l) : Math.round(5 + 6 * l + 0.12 * l * l));
  const muMul = (t) => 0.48 * (1 + t / 220 + (t / 300) ** 2); // 시간에 따라 적 체력 배율(0분 0.5 → 5분 1.6 → 10분 3.7)
  function muSpawn(k, x, y, t) { spawn(k, x, y, muMul(t)); const e = A.en[A.en.length - 1]; e.spd *= 1 + Math.min(t, 600) / 600 * 0.35; return e; } // 뒤로 갈수록 조금씩 빨라짐
  const MU_CAP = 300, MU_HP = 150;
  const muEnemies = () => A.en.filter((e) => !e.dead);
  function nearest(n, from, maxD) { const f = from || A.p, out = []; for (const e of A.en) { if (e.dead) continue; const d = Math.hypot(e.x - f.x, e.y - f.y); if (!maxD || d < maxD) out.push([d, e]); } out.sort((a, b) => a[0] - b[0]); return out.slice(0, n).map((x) => x[1]); }
  function inView(e, pad = 20) { return e.x > CAMX - pad && e.x < CAMX + AW + pad && e.y > CAMY - pad && e.y < CAMY + A.VH + pad; }
  function dmgE(e, d) { if (!e.dead) hurtEnemy(e, d, true); }
  // ── 기술
  function skillTick(dt) {
    const p = A.p, cdm = muCd(), atk = muAtk();
    for (const k of ACT) { const lv = sk(k); if (!lv || (A.map && k === 'wave')) continue; A.skCd[k] = (A.skCd[k] || 0) - dt; if (A.skCd[k] > 0) continue; const ev = A.evo[k];
      if (k === 'sword') { const R = ev ? 130 : [92, 92, 108, 108, 118][lv - 1], t = nearest(1, p, R + 26)[0]; A.skCd[k] = (ev ? 0.75 : [1.05, 1.0, 0.95, 0.8, 0.75][lv - 1]) * cdm; if (!t) { A.skCd[k] = 0.1; continue; }
        const a = Math.atan2(t.y - p.y, t.x - p.x), arc = ev ? Math.PI * 2 : 2.4, dmg = atk * (ev ? 4.6 : [2.6, 3.0, 3.0, 3.2, 3.8][lv - 1]);
        for (const e of A.en) { if (e.dead) continue; const dx = e.x - p.x, dy = e.y - p.y, d = Math.hypot(dx, dy); if (d > R + e.r) continue; let da = Math.abs(((Math.atan2(dy, dx) - a) + Math.PI * 3) % (Math.PI * 2) - Math.PI); if (da <= arc / 2) dmgE(e, dmg); }
        A.fx.push({ k: 'slash', x: p.x, y: p.y, a, arc, r: R, t: 0.2 }); p.fx = Math.cos(a); p.fy = Math.sin(a); sfx('slam', 0.12);
        if (ev) for (let i = 0; i < 4; i++) { const b = a + i * Math.PI / 2; A.shots.push({ x: p.x, y: p.y, vx: Math.cos(b) * 340, vy: Math.sin(b) * 340, dmg: atk * 1.6, r: 15, kind: 'blade', pierce: 99, hit: [], born: A.t, mine: true, life: 0, maxLife: 0.8 }); } }
      else if (k === 'wave') { const n = ev ? 5 : [1, 1, 2, 2, 3][lv - 1]; A.skCd[k] = (ev ? 0.9 : lv >= 4 ? 1.25 : 1.6) * cdm; const t = nearest(1, p, 400)[0], a0 = t ? Math.atan2(t.y - p.y, t.x - p.x) : Math.atan2(p.fy, p.fx);
        for (let i = 0; i < n; i++) { const b = a0 + (i - (n - 1) / 2) * (ev ? 0.35 : 0.28), sp = ev ? 420 : 330; A.shots.push({ x: p.x, y: p.y, vx: Math.cos(b) * sp, vy: Math.sin(b) * sp, dmg: atk * (ev ? 2.4 : [1.4, 1.7, 1.7, 1.9, 2.1][lv - 1]), r: ev ? 18 : 13, kind: 'blade', pierce: 99, hit: [], born: A.t, mine: true, life: 0, maxLife: ev ? 1.0 : 0.85 }); } }
      else if (k === 'arrow') { const n = ev ? 8 : [1, 2, 2, 3, 5][lv - 1]; A.skCd[k] = (ev ? 1.3 : lv >= 4 ? 1.9 : 2.4) * cdm; const tg = muEnemies().filter((e) => inView(e)); if (!tg.length) { A.skCd[k] = 0.3; continue; }
        for (let i = 0; i < n; i++) { const e = pick(tg); A.warns.push({ x: e.x + rnd(-12, 12), y: e.y + rnd(-12, 12), r: ev ? 48 : 36, t: 0.45, dmg: atk * (ev ? 3.0 : lv >= 3 ? 2.4 : 1.9), kind: 'arrow' }); } }
      else if (k === 'fire') { const n = ev ? 5 : [1, 2, 2, 2, 3][lv - 1]; A.skCd[k] = (ev ? 2.6 : 3.2) * cdm; const tg = nearest(12, p, 320); for (let i = 0; i < n; i++) { const e = tg.length ? pick(tg) : null, x = e ? e.x : p.x + rnd(-120, 120), y = e ? e.y : p.y + rnd(-120, 120); A.fires.push({ x, y, r: ev ? 72 : 42, t: ev ? 4.5 : lv >= 3 ? 3.6 : 2.8, tick: 0, dmg: atk * (ev ? 0.9 : lv >= 4 ? 0.7 : 0.55) }); } sfx('slam', 0.15); }
      else if (k === 'bolt') { const n = ev ? 6 : [1, 2, 2, 3, 5][lv - 1]; A.skCd[k] = (ev ? 1.2 : lv >= 4 ? 1.5 : 1.9) * cdm; const tg = muEnemies().filter((e) => inView(e)); if (!tg.length) { A.skCd[k] = 0.3; continue; }
        for (let i = 0; i < n; i++) { const e = pick(tg), dmg = atk * (ev ? 3.2 : lv >= 3 ? 2.8 : 2.2); A.fx.push({ k: 'sky', x: e.x, y: e.y, t: 0.25 }); for (const o of A.en) if (!o.dead && Math.hypot(o.x - e.x, o.y - e.y) < 26 + o.r) dmgE(o, dmg);
          if (ev) { let prev = e; for (let c = 0; c < 3; c++) { const nx = nearest(2, prev, 140).find((o) => o !== prev && !o.dead); if (!nx) break; A.fx.push({ k: 'bolt', x: prev.x, y: prev.y, x2: nx.x, y2: nx.y, t: 0.2 }); dmgE(nx, dmg * 0.7); prev = nx; } } } sfx('hit', 0.2); }
    }
    // 회전 언월(늘 돎)
    const ol = sk('orbit'); if (ol) { const ev = A.evo.orbit, n = ev ? 6 : [2, 2, 3, 3, 4][ol - 1], R = ev ? 78 : 58, sp = ev ? 4.4 : ol >= 4 ? 4.0 : 3.2, dmg = atk * (ev ? 1.8 : ol >= 2 ? 1.25 : 1.0); A.orbA += dt * sp;
      for (let i = 0; i < n; i++) { const a = A.orbA + i / n * Math.PI * 2, ox = p.x + Math.cos(a) * R, oy = p.y + Math.sin(a) * R; for (const e of A.en) if (!e.dead && (e.orbT || 0) <= 0 && Math.hypot(e.x - ox, e.y - oy) < e.r + 12) { e.orbT = 0.35; dmgE(e, dmg); } } }
    // 화살비 떨어짐 · 불길
    for (const w of A.warns) { w.t -= dt; if (w.t <= 0) { w.done = true; for (const e of A.en) if (!e.dead && Math.hypot(e.x - w.x, e.y - w.y) < w.r + e.r) dmgE(e, w.dmg); A.fx.push({ k: 'rain', x: w.x, y: w.y, r: w.r, t: 0.3 }); } }
    A.warns = A.warns.filter((w) => !w.done);
    for (const f of A.fires) { f.t -= dt; f.tick -= dt; if (f.tick <= 0) { f.tick = 0.4; for (const e of A.en) if (!e.dead && Math.hypot(e.x - f.x, e.y - f.y) < f.r + e.r) dmgE(e, f.dmg); } }
    A.fires = A.fires.filter((f) => f.t > 0);
  }
  // ── 매 프레임(싸움판 update 앞에서)
  function muTick(dt) {
    if (A.map) return fieldTick(dt);
    const p = A.p, t = A.t, C = A.ch;
    // 체력 회복(군량)
    if (sk('gun')) { A.regenAcc += 0.4 * sk('gun') * dt; if (A.regenAcc >= 1) { const v = Math.floor(A.regenAcc); A.regenAcc -= v; p.hp = Math.min(p.max, p.hp + v); } }
    p.spd = 150 * (1 + 0.08 * sk('sin'));
    // 시간표: 무리 · 정예 · 마지막 장수
    let mix = C.mix[0][1]; for (const [tt, m] of C.mix) if (t >= tt) mix = m;
    if (!A.boss && t >= C.len) { const [x, y] = ringPos(); spawn(C.boss, x, y, C.bossMul || 8); A.boss = A.en[A.en.length - 1]; A.boss.boss = true; A.boss.touch = 22; const hw = AW / 2 - 14, hh = Math.min(A.VH / 2 - 40, 280), fx = clamp(p.x, hw + 20, A.WW - hw - 20), fy = clamp(p.y, hh + 20, A.WH - hh - 20); A.fence = { x: fx, y: fy, hw, hh }; A.boss.x = fx; A.boss.y = fy - hh + 60; for (const e of A.en) if (e !== A.boss && (Math.abs(e.x - fx) > hw || Math.abs(e.y - fy) > hh)) e.dead = true; banner(`${EN[C.boss].n}!`, '울타리 안에서 마지막 승부'); sfx('alert', 0.5); }
    for (const el of C.elites) if (t >= el.t && !A.eliteDone[el.t]) { A.eliteDone[el.t] = true; const [x, y] = ringPos(); spawn(el.k, x, y, muMul(t) * (el.k === 'cyz' ? 3 : 14)); const e = A.en[A.en.length - 1]; e.elite = true; e.touch = Math.round(EN[el.k].touch * 1.4); e.max = e.hp; e.r *= el.k === 'cyz' ? 1.1 : 1.5; e.ename = el.n; banner(`${el.n} 등장!`, '쓰러뜨리면 보물 상자'); sfx('alert', 0.35); }
    for (const st of C.swarms) if (t >= st && !A.swarmDone[st] && !A.boss) { A.swarmDone[st] = true; const n = 16 + Math.floor(t / 60 * 5); for (let i = 0; i < n; i++) { const a = i / n * Math.PI * 2, x = clamp(p.x + Math.cos(a) * 300, 24, A.WW - 24), y = clamp(p.y + Math.sin(a) * 300, 24, A.WH - 24); const e = muSpawn('ytb', x, y, t); e.hp = e.max = e.hp * 0.6; } /* 에워싸는 무리는 쓸어버리는 맛 — 체력 60% */ banner('황건 무리가 에워싸요!', '틈을 찾아 빠져나가요'); }
    if (!A.boss) { const u = t / 600, rate = (1.4 + 6 * u + 14 * u * u) * (t < 30 ? 0.6 : 1); A.spawnAcc += rate * dt; while (A.spawnAcc >= 1) { A.spawnAcc -= 1; if (A.en.length >= MU_CAP) continue; const [x, y] = ringPos(); muSpawn(wpick(mix), x, y, t); } }
    for (const e of A.en) { if (e.boss || e.elite) continue; const d = Math.hypot(e.x - p.x, e.y - p.y); if (d > 800) { const [x, y] = ringPos(); e.x = x; e.y = y; } }
    // 겹치지 않게
    const cell = 30, G = new Map(); for (const e of A.en) { const k = ((e.x / cell) | 0) * 4096 + ((e.y / cell) | 0); let l = G.get(k); if (!l) G.set(k, (l = [])); l.push(e); }
    for (const e of A.en) { if (e.boss) continue; const cx = (e.x / cell) | 0, cy = (e.y / cell) | 0; for (let i = -1; i <= 1; i++) for (let j = -1; j <= 1; j++) { const l = G.get((cx + i) * 4096 + cy + j); if (!l) continue; for (const o of l) { if (o === e) continue; const dx = e.x - o.x, dy = e.y - o.y, d = Math.hypot(dx, dy), m = (e.r + o.r) * 0.85; if (d > 0.01 && d < m) { const k = (m - d) * 0.25 / d; e.x += dx * k; e.y += dy * k; } } } }
    // 울타리(마지막 장수)
    if (A.fence) { const F = A.fence, inF = (o) => { o.x = clamp(o.x, F.x - F.hw + o.r, F.x + F.hw - o.r); o.y = clamp(o.y, F.y - F.hh + o.r, F.y + F.hh - o.r); }; inF(p); for (const e of A.en) inF(e); }
    skillTick(dt);
    // 줍기: 구슬 · 금 · 고기만두 · 깃발(전부 끌어옴) · 화약(화면 적 쓸기)
    const mag = 64 * (1 + 0.3 * sk('gi'));
    for (const g of A.gems) { const d = Math.hypot(g.x - p.x, g.y - p.y); if (g.pull || d < mag) { g.pull = true; const k = Math.min(1, dt * 11); g.x += (p.x - g.x) * k; g.y += (p.y - g.y) * k; } if (d < p.r + 8) { g.got = true; gainXPm(g.v); } }
    A.gems = A.gems.filter((g) => !g.got);
    for (const it of A.drops) { const d = Math.hypot(it.x - p.x, it.y - p.y); if (it.k === 'gold' && d < mag) { const k = Math.min(1, dt * 11); it.x += (p.x - it.x) * k; it.y += (p.y - it.y) * k; } if (d < p.r + 12) { it.got = true;
      if (it.k === 'gold') { A.gold += it.v; sfx('kill', 0.15); } else if (it.k === 'bun') { heal(p, p.max * 0.3); sfx('heal', 0.35); } else if (it.k === 'flag') { for (const g of A.gems) g.pull = true; banner('깃발 — 구슬을 모두 끌어와요', ''); sfx('accept', 0.3); } else if (it.k === 'bomb') { for (const e of A.en) if (!e.dead && !e.boss && !e.elite && inView(e, 40)) dmgE(e, e.hp); A.shake = 0.3; A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.5, r: 260, c: '#ffb050' }); sfx('slam', 0.5); } else if (it.k === 'chest') { A.chestQ++; } } }
    A.drops = A.drops.filter((it) => !it.got);
    const fc = A.fence || p; CAMX = clamp(fc.x - AW / 2, 0, A.WW - AW); CAMY = clamp(fc.y - A.VH / 2, 0, A.WH - A.VH);
    if (A.chestQ > 0) { A.chestQ--; return openChest(); }
    if (A.lvlQ > 0) { A.lvlQ--; return levelUp(); }
  }
  function gainXPm(v) { A.xp += v * (A.xpMul || 1); while (A.xp >= xpNeedM(A.lvl)) { A.xp -= xpNeedM(A.lvl); A.lvl++; A.lvlQ++; } }
  // 적이 쓰러지면(hurtEnemy에서 부름)
  function muKill(e) {
    if (A.map) return fieldKill(e);
    if (e.boss) { A.gold += 150; for (const o of A.en) if (!o.dead && o !== e) { o.dead = true; } A.later.push({ t: A.t + 1.2, fn: () => muEnd(true) }); banner(`${EN[e.k].n}${eul(EN[e.k].n)} 쓰러뜨렸어요!`, '마지막 장수 격파'); return; }
    if (e.elite) { A.drops.push({ k: 'chest', x: e.x, y: e.y }); A.drops.push({ k: 'gold', x: e.x + 14, y: e.y, v: 25 }); A.gems.push({ x: e.x - 10, y: e.y, v: 15 }); banner(`${e.ename || EN[e.k].n} 격파!`, '보물 상자를 주워요'); return; }
    const v = e.k === 'ytbig' ? 4 : e.k === 'ytarch' || e.k === 'ytcav' ? 2 : 1; if (A.gems.length > 300) A.gems[Math.floor(Math.random() * A.gems.length)].v += v; else A.gems.push({ x: e.x, y: e.y, v });
    const r = Math.random(); if (r < 0.015) A.drops.push({ k: 'gold', x: e.x + 6, y: e.y, v: 2 }); else if (r < 0.019) A.drops.push({ k: 'bun', x: e.x, y: e.y }); else if (r < 0.0205) A.drops.push({ k: 'flag', x: e.x, y: e.y }); else if (r < 0.0215) A.drops.push({ k: 'bomb', x: e.x, y: e.y });
  }
  // ── 레벨업 · 보물 상자
  function skillOptions() {
    const out = [], nAct = ACT.filter((k) => sk(k)).length, nPas = PAS.filter((k) => sk(k)).length;
    for (const k of ACT) { const S = SK[k], lv = sk(k); if (lv >= 5 && !A.evo[k] && sk(S.evo)) out.push({ k, evo: true, w: 100 }); else if (lv && lv < 5) out.push({ k, w: 3 }); else if (!lv && nAct < 6) out.push({ k, w: 2 }); }
    for (const k of PAS) { const lv = sk(k); if (lv && lv < 5) out.push({ k, w: 2 }); else if (!lv && nPas < 6) out.push({ k, w: 1.6 }); }
    return out;
  }
  function pickOpts(n) { const pool = skillOptions(), res = []; const ev = pool.filter((o) => o.evo); res.push(...ev.slice(0, n)); const rest = pool.filter((o) => !o.evo); while (res.length < n && rest.length) { let tot = rest.reduce((s, o) => s + o.w, 0), r = Math.random() * tot, i = 0; for (; i < rest.length; i++) { r -= rest[i].w; if (r <= 0) break; } res.push(rest.splice(Math.min(i, rest.length - 1), 1)[0]); } return res; }
  function applyOpt(o) { if (o.evo) { A.evo[o.k] = true; banner(`진화 — ${SK[o.k].en}!`, SK[o.k].ed); sfx('win', 0.35); } else if (o.k === 'gold') { A.gold += 20; } else { A.sk[o.k] = sk(o.k) + 1; if (!A.skCd[o.k]) A.skCd[o.k] = 0.3; } }
  const stars = (lv) => '★'.repeat(lv) + '☆'.repeat(5 - lv);
  function optHTML(o, i) { if (o.k === 'gold') return `<button class="opt sk" type="button" data-o="${i}"><span class="ic" style="background:#e2b85a">금</span><b>금 20</b><span>모든 기술이 가득 찼어요</span></button>`; const S = SK[o.k], lv = sk(o.k);
    if (o.evo) return `<button class="opt sk evo" type="button" data-o="${i}"><span class="ic" style="background:${S.c};color:#fffaf0">${S.g}</span><b>진화 · ${S.en}</b><span>${S.ed}</span></button>`;
    return `<button class="opt sk" type="button" data-o="${i}"><span class="ic" style="background:${S.c};color:#fffaf0">${S.g}</span><b>${S.n} <small class="st">${stars(lv + 1)}</small>${lv ? '' : ' <em>새 기술</em>'}</b><span>${S.act ? S.d[lv] : S.d[0]}${S.act && !lv && S.evo ? ` · 진화 짝: ${SK[S.evo].n}` : ''}${!S.act ? ` · ${ACT.filter((a) => SK[a].evo === o.k).map((a) => SK[a].n + ' 진화 짝').join('')}` : ''}</span></button>`; }
  function levelUp() {
    A.state = 'pick'; joy.on = false; const opts = pickOpts(3); if (!opts.length) opts.push({ k: 'gold' }); sfx('accept', 0.35);
    card(`<h2>${A.map ? '공적 ' : ''}Lv ${A.lvl} — 기술 고르기</h2>${skBar()}${opts.map(optHTML).join('')}`, (c) => c.querySelectorAll('[data-o]').forEach((b) => b.onclick = () => { applyOpt(opts[+b.dataset.o]); closeCard(); A.state = 'play'; last = performance.now(); hudUpdate(); }));
  }
  function openChest() {
    A.state = 'pick'; joy.on = false; const n = Math.random() < 0.25 ? 3 : 1, got = pickOpts(n); if (!got.length) got.push({ k: 'gold' }); got.forEach(applyOpt); sfx('win', 0.35);
    card(`<h2>보물 상자</h2><p class="lead">${n > 1 ? '대박! 셋이나 나왔어요.' : '기술 하나가 올랐어요.'}</p>${got.map((o) => o.k === 'gold' ? '<div class="opt sk"><b>금 20</b></div>' : `<div class="opt sk ${o.evo ? 'evo' : ''}" style="cursor:default"><span class="ic" style="background:${SK[o.k].c};color:#fffaf0">${SK[o.k].g}</span><b>${o.evo ? `진화 · ${SK[o.k].en}` : `${SK[o.k].n} <small class="st">${stars(sk(o.k))}</small>`}</b><span>${o.evo ? SK[o.k].ed : (SK[o.k].act ? SK[o.k].d[sk(o.k) - 1] : SK[o.k].d[0])}</span></div>`).join('')}<button class="go" type="button" id="ok">계속</button>`, (c) => { c.querySelector('#ok').onclick = () => { closeCard(); A.state = 'play'; last = performance.now(); hudUpdate(); }; });
  }
  const skBar = () => `<div class="skbar">${[...ACT, ...PAS].filter((k) => sk(k)).map((k) => `<span style="border-color:${SK[k].c}"><i style="color:${SK[k].c}">${SK[k].g}</i>${A.evo[k] ? '진' : sk(k)}</span>`).join('')}</div>`;
  function muPause() { card(`<h2>잠깐 멈춤</h2><p>${A.ch.n} · ${fmtT(A.t)} · Lv ${A.lvl}</p>${skBar()}<button class="go" type="button" id="cont">계속</button><button class="sub" type="button" id="quit">그만두기(얻은 금은 받아요)</button>`, (c) => {
    c.querySelector('#cont').onclick = () => { closeCard(); A.state = 'play'; last = performance.now(); };
    c.querySelector('#quit').onclick = () => { closeCard(); A.state = 'play'; muEnd(false, true); }; }); }
  // ── 끝
  function muEnd(win, quit) {
    if (A.map) return fieldEnd(win, quit);
    if (A.state === 'end' || A.state === 'dead') return; A.state = win ? 'end' : 'dead'; sfx(win ? 'win' : 'lose', 0.4); const M = muSV(), C = A.ch, tt = Math.min(A.t, C.len), bonus = Math.floor(A.kills / 40) + (win ? 100 : 0), gold = A.gold + bonus;
    M.gold += gold; if (!M.best[C.id] || tt > M.best[C.id] || win) M.best[C.id] = win ? C.len : Math.max(M.best[C.id] || 0, Math.min(tt, C.len - 1)); if (win) M.clears++; saveSV();
    setTimeout(() => card(`<h2>${win ? `${C.n} 클리어!` : quit ? '물러났어요' : '관우가 쓰러졌어요'}</h2><p class="lead">${win ? '황건적의 기세가 꺾였어요.' : `${fmtT(A.t)} 버텼어요.`}</p><div class="stats"><span>쓰러뜨린 적</span><b>${A.kills}</b><span>레벨</span><b>${A.lvl}</b><span>얻은 금</span><b>${gold} (판에서 ${A.gold} + 마무리 ${bonus})</b></div>${skBar()}<p>${win ? '' : '금으로 강화하고 다시 도전해요.'}</p><button class="go" type="button" id="back">로비로</button>`, (c) => { c.querySelector('#back').onclick = () => { closeCard(); lobby(); }; }), 600);
  }
  function muHud() { if (A.map) return fieldHud(); const p = A.p; $('page').textContent = A.ch.n; $('pause').style.display = ''; $('bag').style.display = 'none'; $('swap').style.display = 'none'; $('goal').hidden = true; $('hpw').style.display = 'none';
    const h = `<span class="tag">처치 ${A.kills}</span><span class="tag" style="border-color:var(--gold)">금 ${A.gold}</span>${[...ACT, ...PAS].filter((k) => sk(k)).map((k) => `<span class="tag" style="border-color:${SK[k].c}">${SK[k].g}${A.evo[k] ? '진' : sk(k)}</span>`).join('')}`; if ($('tags').innerHTML !== h) $('tags').innerHTML = h; }
  // ── 그리기: 풀밭(256칸 조각을 깔아 씀) · 불길 · 화살비 경고 · 칼날 · 벤 자리 · 관우 체력 막대 · 울타리
  let MU_CHUNK = null, MU_CHUNK_N = null;
  function muChunk() { if (MU_CHUNK && MU_CHUNK_N === NINJA) return MU_CHUNK; MU_CHUNK_N = NINJA; return (MU_CHUNK = mk(256, 256, (g) => { for (let y = 0; y < 256; y += 16) for (let x = 0; x < 256; x += 16) { const h = ((x / 16) * 7 + (y / 16) * 13) % 4; g.drawImage(TILE.grass[h], x, y); }
    const fl = TILE.flowerV || [TILE.flower]; for (let i = 0; i < 6; i++) { const x = (i * 83 + 37) % 240, y = (i * 59 + 91) % 240; g.drawImage(fl[i % fl.length], x - (x % 16), y - (y % 16)); }
    if (TILE.bush) for (let i = 0; i < 3; i++) { const x = (i * 97 + 150) % 224, y = (i * 61 + 30) % 224; g.drawImage(TILE.bush[0], x - (x % 16), y - (y % 16)); g.drawImage(TILE.bush[1], x - (x % 16) + 16, y - (y % 16)); } })); }
  function muBg() { if (A.map) return fieldBg(); const VH = A.VH; ctx.fillStyle = '#2a3a1e'; ctx.fillRect(OX, OY, AW * SC, VH * SC); const ch = muChunk(), cs = 256; ctx.imageSmoothingEnabled = false;
    for (let gy = Math.floor(CAMY / cs) * cs; gy < CAMY + VH; gy += cs) for (let gx = Math.floor(CAMX / cs) * cs; gx < CAMX + AW; gx += cs) ctx.drawImage(ch, X(gx), Y(gy), cs * SC + 1, cs * SC + 1);
    ctx.strokeStyle = '#3a2a1a'; ctx.lineWidth = 4; ctx.strokeRect(X(0), Y(0), A.WW * SC, A.WH * SC);
    muFloorFx(); }
  function muFloorFx() {
    for (const f of A.fires) { const fl = 0.85 + 0.15 * Math.sin(A.t * 20 + f.x); ctx.fillStyle = `rgba(255,110,40,${0.28 * Math.min(1, f.t)})`; ctx.beginPath(); ctx.arc(X(f.x), Y(f.y), f.r * fl * SC, 0, 7); ctx.fill(); for (let i = 0; i < 6; i++) { const a = i / 6 * 6.28 + A.t * 2, rr = f.r * (0.3 + 0.5 * ((i * 37) % 10) / 10); ctx.fillStyle = i % 2 ? '#ffd38a' : '#ff7a3a'; ctx.beginPath(); ctx.arc(X(f.x + Math.cos(a) * rr), Y(f.y + Math.sin(a) * rr - (A.t * 30 + i * 7) % 10), 3 * SC, 0, 7); ctx.fill(); } }
    for (const w of A.warns) { ctx.strokeStyle = `rgba(217,80,60,${0.5 + 0.5 * Math.sin(A.t * 30)})`; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(X(w.x), Y(w.y), w.r * SC, 0, 7); ctx.stroke(); ctx.fillStyle = 'rgba(217,80,60,0.12)'; ctx.fill(); }
    for (const it of A.drops) { const bob = Math.sin(A.t * 4 + it.x) * 2; const x = it.x, y = it.y + bob;
      if (it.k === 'gold') { circle(x, y, 5, '#f0c850', '#8a6a1a'); ctx.fillStyle = '#8a6a1a'; ctx.fillRect(X(x) - 1.5 * SC, Y(y) - 1.5 * SC, 3 * SC, 3 * SC); }
      else if (it.k === 'bun') { circle(x, y, 7, '#fff6e8', '#8a6a4a'); glyph('만', x, y, 7, '#8a5a2a'); }
      else if (it.k === 'flag') { ctx.fillStyle = '#5a3a1a'; ctx.fillRect(X(x - 1), Y(y - 10), 2 * SC, 18 * SC); ctx.fillStyle = '#d85a7a'; ctx.beginPath(); ctx.moveTo(X(x + 1), Y(y - 10)); ctx.lineTo(X(x + 13), Y(y - 6)); ctx.lineTo(X(x + 1), Y(y - 2)); ctx.fill(); }
      else if (it.k === 'bomb') { circle(x, y, 7, '#3a3030', '#1d1813'); ctx.strokeStyle = '#e2b85a'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(X(x + 4), Y(y - 5)); ctx.lineTo(X(x + 8), Y(y - 10)); ctx.stroke(); }
      else if (it.k === 'chest') { ctx.fillStyle = '#8a5a2a'; ctx.fillRect(X(x - 10), Y(y - 7), 20 * SC, 14 * SC); ctx.fillStyle = '#e2b85a'; ctx.fillRect(X(x - 10), Y(y - 2), 20 * SC, 3 * SC); ctx.fillRect(X(x - 2), Y(y - 4), 4 * SC, 6 * SC); ctx.strokeStyle = 'rgba(255,230,120,0.8)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(X(x), Y(y), (14 + Math.sin(A.t * 5) * 2) * SC, 0, 7); ctx.stroke(); } }
    if (A.fence) { const F = A.fence, post = (x, y) => { ctx.fillStyle = '#6a4a2a'; ctx.fillRect(X(x) - 2.5 * SC, Y(y) - 10 * SC, 5 * SC, 13 * SC); ctx.fillStyle = '#a8784a'; ctx.fillRect(X(x) - 2.5 * SC, Y(y) - 10 * SC, 5 * SC, 2.5 * SC); }; ctx.strokeStyle = '#5a3a1a'; ctx.lineWidth = 2.5 * SC; ctx.strokeRect(X(F.x - F.hw), Y(F.y - F.hh), F.hw * 2 * SC, F.hh * 2 * SC); ctx.strokeStyle = '#8a6a3a'; ctx.lineWidth = 1.5 * SC; ctx.strokeRect(X(F.x - F.hw), Y(F.y - F.hh - 5), F.hw * 2 * SC, F.hh * 2 * SC);
      for (let x = -F.hw; x <= F.hw; x += 22) { post(F.x + x, F.y - F.hh); post(F.x + x, F.y + F.hh); } for (let y = -F.hh; y <= F.hh; y += 22) { post(F.x - F.hw, F.y + y); post(F.x + F.hw, F.y + y); } } }
  function muOver() { if (A.map) return fieldOver(); const p = A.p, ol = sk('orbit');
    if (ol) { const ev = A.evo.orbit, n = ev ? 6 : [2, 2, 3, 3, 4][ol - 1], R = ev ? 78 : 58; for (let i = 0; i < n; i++) { const a = A.orbA + i / n * Math.PI * 2, ox = p.x + Math.cos(a) * R, oy = p.y + Math.sin(a) * R; ctx.save(); ctx.translate(X(ox), Y(oy)); ctx.rotate(a + Math.PI / 2); ctx.strokeStyle = '#8ab8a0'; ctx.lineWidth = 4 * SC; ctx.beginPath(); ctx.arc(0, 0, 10 * SC, -1.2, 1.2); ctx.stroke(); ctx.strokeStyle = '#e8fff0'; ctx.lineWidth = 1.5 * SC; ctx.beginPath(); ctx.arc(0, 0, 10 * SC, -1, 1); ctx.stroke(); ctx.restore(); } }
    const bw = 30; ctx.fillStyle = '#3a3024'; ctx.fillRect(X(p.x - bw / 2), Y(p.y + 18), bw * SC, 4 * SC); ctx.fillStyle = p.hp / p.max < 0.3 ? '#d9705e' : '#6fae6a'; ctx.fillRect(X(p.x - bw / 2), Y(p.y + 18), bw * SC * p.hp / p.max, 4 * SC); }
  function muFx(f) { if (f.k === 'spark') { ctx.globalAlpha = Math.min(1, f.t * 7); ctx.strokeStyle = f.c || '#fff2c0'; ctx.lineWidth = 2; for (let i = -1; i <= 1; i++) { const a = f.a + i * 0.6, r0 = 3 + (0.18 - f.t) * 40, r1 = r0 + 7; ctx.beginPath(); ctx.moveTo(X(f.x + Math.cos(a) * r0), Y(f.y + Math.sin(a) * r0)); ctx.lineTo(X(f.x + Math.cos(a) * r1), Y(f.y + Math.sin(a) * r1)); ctx.stroke(); } ctx.globalAlpha = 1; return true; }
    if (f.k === 'shot') { ctx.globalAlpha = Math.min(1, f.t * 8); ctx.strokeStyle = '#e8e0c8'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(X(f.x), Y(f.y)); ctx.lineTo(X(f.x2), Y(f.y2)); ctx.stroke(); ctx.globalAlpha = 1; return true; }
    if (f.k === 'slash') { ctx.save(); ctx.globalAlpha = Math.min(1, f.t * 6); ctx.translate(X(f.x), Y(f.y)); ctx.strokeStyle = f.c || 'rgba(200,255,220,0.9)'; ctx.lineWidth = 10 * SC * f.t / 0.2 + 2; ctx.beginPath(); ctx.arc(0, 0, f.r * 0.8 * SC, f.a - f.arc / 2, f.a + f.arc / 2); ctx.stroke(); ctx.strokeStyle = f.c2 || 'rgba(74,138,90,0.8)'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(0, 0, f.r * SC, f.a - f.arc / 2, f.a + f.arc / 2); ctx.stroke(); ctx.restore(); return true; }
    if (f.k === 'rain') { ctx.globalAlpha = Math.min(1, f.t * 4); ctx.strokeStyle = '#5a3a1a'; ctx.lineWidth = 1.5; for (let i = 0; i < 7; i++) { const a = i * 2.4, rr = f.r * ((i * 37) % 10) / 10, x = f.x + Math.cos(a) * rr, y = f.y + Math.sin(a) * rr; ctx.beginPath(); ctx.moveTo(X(x - 4), Y(y - 12 + (0.3 - f.t) * 30)); ctx.lineTo(X(x), Y(y + (0.3 - f.t) * 30 - 2)); ctx.stroke(); } ctx.globalAlpha = 1; return true; }
    if (f.k === 'sky') { ctx.globalAlpha = Math.min(1, f.t * 5); ctx.strokeStyle = '#fff6a0'; ctx.lineWidth = 3; ctx.beginPath(); let y = f.y - 220, x = f.x; ctx.moveTo(X(x), Y(y)); while (y < f.y) { y += 30; x = f.x + rnd(-10, 10); ctx.lineTo(X(x), Y(Math.min(y, f.y))); } ctx.stroke(); ctx.fillStyle = 'rgba(255,240,140,0.4)'; ctx.beginPath(); ctx.arc(X(f.x), Y(f.y), 26 * SC, 0, 7); ctx.fill(); ctx.globalAlpha = 1; return true; }
    return false; }
