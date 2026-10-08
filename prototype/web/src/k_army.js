  // ═════════ 군세 대결(D-162, 시험): 클래시 로얄식 — 두 갈래 길 · 진영 탑 · 군량 · 장수/병종 카드 6장 ═════════
  // 카드를 고르고 내 진영(아래 절반)을 누르면 병사가 나감. 병사는 알아서 다리를 건너 가까운 적과 성을 공격. 상성: 창병 > 기병 > 궁병 > 창병
  const FW = 360, FH = 600, RIV0 = 288, RIV1 = 312, LANES = [80, 280];
  const UT = {
    spear: { n: '창병', g: '창', cost: 3, cnt: 3, hp: 130, dmg: 15, rng: 20, spd: 40, rate: 1.0, r: 8, c: '#6a7a9a', hint: '기병에 강해요' },
    arch: { n: '궁병', g: '궁', cost: 3, cnt: 3, hp: 70, dmg: 13, rng: 105, spd: 38, rate: 0.85, r: 8, proj: 'arrow', c: '#5a8a4a', hint: '창병에 강해요 · 멀리서' },
    cav: { n: '기병', g: '기', cost: 4, cnt: 2, hp: 200, dmg: 24, rng: 22, spd: 70, rate: 1.0, r: 10, bld: true, c: '#a8703a', hint: '궁병에 강해요 · 성만 노려요' },
    shield: { n: '방패병', g: '방', cost: 2, cnt: 1, hp: 420, dmg: 9, rng: 20, spd: 34, rate: 1.0, r: 11, c: '#4a6a8a', hint: '튼튼해요 · 화살에 덜 다쳐요' },
    fire: { n: '화계', g: '화', cost: 4, spell: true, rad: 55, dmg: 120, tdmg: 40, c: '#d9583a', hint: '어디든 범위 불 — 무리에 강해요' },
  };
  const GEN = {
    zhangfei: { cost: 5, hp: 720, dmg: 40, rng: 24, spd: 44, rate: 1.0, r: 12, roar: true, hint: '장판교 고함 — 둘레 적이 장비만 노려요' },
    zhuge: { cost: 5, hp: 380, dmg: 30, rng: 115, spd: 38, rate: 0.75, r: 11, proj: 'fire', splash: 38, hint: '화공 — 멀리서 범위 불' },
    liubei: { cost: 4, hp: 520, dmg: 22, rng: 22, spd: 40, rate: 1.0, r: 11, healer: true, hint: '인덕 — 둘레 아군 회복' },
    guanyu: { cost: 5, hp: 640, dmg: 48, rng: 26, spd: 42, rate: 0.9, r: 12, cleave: 32, hint: '반달 베기 — 둘레를 함께 벰' },
    cyz: { cost: 5, hp: 700, dmg: 36, rng: 24, spd: 42, rate: 1.0, r: 12, hint: '황건 장수' },
  };
  const MULT = { spear: { cav: 2 }, cav: { arch: 2 }, arch: { spear: 1.6, shield: 0.6 } };
  const TSPR = { me: { spear: 't_spear', arch: 't_arch', shield: 't_shield', cav: ['a_horse', 't_rider'] }, foe: { spear: 'e_ytb', arch: 'e_ytarch', shield: 'e_ytbig', cav: ['a_horseB', 'e_ytb'] } };
  const ARMY_AI = { cyz: { push: [7, 9], think: [0.5, 0.85], react: 0.9, desc: '몰아붙이기 — 군량이 차면 한쪽 길로 밀어붙여요' } };
  const cardOf = (c) => (c.startsWith('g:') ? Object.assign({ n: PETS[c.slice(2)] ? PETS[c.slice(2)].n : FOES[c.slice(2)] ? FOES[c.slice(2)].n.split(' ').pop() : c.slice(2), g: (PETS[c.slice(2)] || { g: '장' }).g, c: (PETS[c.slice(2)] || { c: '#d89a3a' }).c, gen: true }, GEN[c.slice(2)]) : UT[c]);
  let AR = null;
  const shuffle = (a) => { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  function startArmy(foe) {
    const st = SV.load.c && GEN[SV.load.c] ? SV.load.c : 'zhangfei';
    const tw = (side, x, y, main) => ({ side, x, y, main, isT: true, hp: main ? 1200 : 700, max: main ? 1200 : 700, r: main ? 22 : 16, rng: main ? 132 : 118, dmg: main ? 28 : 24, rate: 1, cd: 0.5, flash: 0 });
    AR = { foe, t: 120, ot: 0, phase: 'main', elx: { me: 5, foe: 5 }, units: [], proj: [], fx: [], q: { me: shuffle(['g:' + st, 'spear', 'arch', 'cav', 'shield', 'fire']), foe: shuffle(['g:' + foe, 'spear', 'arch', 'cav', 'shield', 'fire']) }, sel: null, st: 'play', crowns: { me: 0, foe: 0 }, ai: { foe: { t: 1.6, push: 7 }, me: { t: 1.6, push: 7 } }, auto: { me: false }, time: 0, hitT: 0, elxShown: -1,
      towers: [tw('me', 80, 492, false), tw('me', 280, 492, false), tw('me', 180, 556, true), tw('foe', 80, 108, false), tw('foe', 280, 108, false), tw('foe', 180, 44, true)] };
    setMode('army'); music('fight'); joy.on = false; inputLock = false; $('hud').hidden = false; $('hpw').style.display = 'none'; $('talk').hidden = true; armyUI(); hudUpdate();
    if (!SV.tutArmy) { SV.tutArmy = true; saveSV(); armyHelp(); } else banner(`군세 대결 · ${FOES[foe].n}`, '카드를 고르고 내 진영을 눌러요');
  }
  function armyHelp() {
    AR.st = 'help';
    card(`<h2>군세 대결</h2><p class="lead">아래 카드를 누르고 <b>내 진영(아래 절반)</b>을 누르면 군사가 나가요.</p><div class="rps"><div><b>군량</b> — 카드마다 값이 있어요. 군량은 저절로 차올라요(마지막 30초는 두 배).</div><div><b>성</b> — 앞 성 2개 · 본진 1개. 2분 동안 더 많이 무너뜨리면 승리, 본진을 무너뜨리면 바로 승리.</div><div><b>상성</b> — 창병 &gt; 기병 &gt; 궁병 &gt; 창병. 방패병은 튼튼, 화계는 어디든 범위 불.</div><div><b>장수</b> — 비싸지만 강하고 기술이 있어요(장비: 고함으로 적을 끌어당김).</div></div><p>군사는 알아서 다리를 건너 가까운 적과 성을 공격해요.</p><button class="go" type="button" id="ok">시작</button>`, (c) => { c.querySelector('#ok').onclick = () => { closeCard(); AR.st = 'play'; last = performance.now(); armyUI(); }; });
  }
  const costOf = (c) => cardOf(c).cost;
  const hand = (side) => AR.q[side].slice(0, 3);
  function playCard(side, i, x, y) {
    const c = AR.q[side][i]; if (!c || i > 2) return false; const C = cardOf(c); if (AR.elx[side] < C.cost) return false;
    AR.elx[side] -= C.cost; AR.q[side].splice(i, 1); AR.q[side].push(c); deploy(side, c, x, y); return true;
  }
  function mkU(side, x, y, o) { return Object.assign({ side, x, y, hp: o.hp, max: o.hp, cd: 0.3, rt: 0, tg: null, dead: false, fd: side === 'me' ? 'up' : 'down', t: Math.random() * 3, roarT: 2.5, healT: 2, deployT: 0.7, flash: 0 }, o); }
  function deploy(side, c, x, y) {
    if (c === 'fire') { const F = UT.fire; AR.fx.push({ k: 'fire', x, y, t: 0.7, r: F.rad }); for (const u of AR.units) if (u.side !== side && !u.dead && Math.hypot(u.x - x, u.y - y) <= F.rad + u.r) hurtU(u, F.dmg); for (const t of AR.towers) if (t.side !== side && !t.dead && Math.hypot(t.x - x, t.y - y) < F.rad + t.r) hurtT(t, F.tdmg, side); sfx('slam', 0.35); return; }
    if (c.startsWith('g:')) { const id = c.slice(2); AR.units.push(mkU(side, x, y, Object.assign({ type: 'gen', gen: id, spr: side === 'me' ? 'p_' + id : 'e_' + id }, GEN[id]))); AR.fx.push({ k: 'ring', x, y, t: 0.5, r: 30, c: side === 'me' ? '#e2b85a' : '#d9705e' }); sfx('accept', 0.3); return; }
    const T = UT[c]; for (let i = 0; i < T.cnt; i++) { const a = i / T.cnt * 6.28 + 0.6, off = T.cnt > 1 ? 13 : 0; AR.units.push(mkU(side, clamp(x + Math.cos(a) * off, 10, FW - 10), y + Math.sin(a) * off, Object.assign({ type: c, spr: TSPR[side][c] }, T))); }
    sfx('step', 0.4);
  }
  const alive = (o) => o && !o.dead;
  function hurtU(u, d) { if (u.dead) return; u.hp -= d; u.flash = 0.1; if (u.hp <= 0) { u.dead = true; if (u.side === 'foe') { AR.fx.push({ k: 'wash', x: u.x, y: u.y, t: 0.7 }); if (u.type === 'gen' || Math.random() < 0.12) AR.fx.push({ k: 'say', x: u.x, y: u.y - 16, t: 1.1, v: u.type === 'gen' ? '…먹물이 걷히는구나' : pick(['휴…', '집에 갈래', '어, 내가 왜…']) }); } else AR.fx.push({ k: 'puff', x: u.x, y: u.y, t: 0.5 }); if (AR.hitT <= 0) { sfx('kill', 0.15); AR.hitT = 0.08; } } }
  function hurtT(t, d, by) { if (t.dead || AR.st !== 'play') return; t.hp -= d; t.flash = 0.1; if (t.hp <= 0) { t.hp = 0; t.dead = true; AR.crowns[by] = t.main ? 3 : Math.min(3, AR.crowns[by] + 1); sfx('kill', 0.5); AR.fx.push({ k: 'boom', x: t.x, y: t.y, t: 0.8 }); banner(by === 'me' ? '성을 무너뜨렸어요!' : '성이 무너졌어요!', `나 ${AR.crowns.me} : ${AR.crowns.foe} 상대`); if (t.main) { for (const o of AR.towers) if (o.side === t.side) { o.dead = true; o.hp = 0; } } if (t.main || AR.phase === 'ot') armyEnd(); hudUpdate(); } }
  function pickTarget(u) {
    if (alive(u.taunt) && u.tauntT > 0) return u.taunt;
    if (!u.bld) { let best = null, bd = 110 + u.rng; for (const o of AR.units) if (o.side !== u.side && !o.dead && o.deployT <= 0.3) { const d = Math.hypot(o.x - u.x, o.y - u.y); if (d < bd) { bd = d; best = o; } } if (best) return best; }
    const et = AR.towers.filter((t) => t.side !== u.side && !t.dead), lane = u.x < FW / 2 ? 0 : 1;
    return et.find((t) => !t.main && (t.x < FW / 2 ? 0 : 1) === lane) || et.find((t) => t.main) || et[0] || null;
  }
  function waypoint(u, t) {
    const home = (y) => (u.side === 'me' ? y > RIV1 : y < RIV0), inRiv = (y) => y >= RIV0 - 3 && y <= RIV1 + 3;
    if (home(u.y) !== home(t.y) && !inRiv(t.y) || inRiv(u.y)) {
      const bx = Math.abs(u.x - LANES[0]) < Math.abs(u.x - LANES[1]) ? LANES[0] : LANES[1];
      if (!inRiv(u.y) && home(u.y)) { const by = u.side === 'me' ? RIV1 + 5 : RIV0 - 5; if (Math.abs(u.x - bx) > 4 || Math.abs(u.y - by) > 4) return { x: bx, y: by }; }
      if (inRiv(u.y) || home(u.y)) return { x: bx, y: u.side === 'me' ? RIV0 - 8 : RIV1 + 8 };
    }
    return t;
  }
  function attack(u, t) {
    const m = t.isT ? 1 : ((MULT[u.type] && MULT[u.type][t.type]) || 1), dmg = u.dmg * m;
    if (u.proj) { const d = Math.hypot(t.x - u.x, t.y - u.y); AR.proj.push({ x: u.x, y: u.y, sx: u.x, sy: u.y, tg: t, tx: t.x, ty: t.y, t: 0, dur: Math.max(0.12, d / 330), kind: u.proj, dmg, side: u.side, splash: u.splash || 0, type: u.type }); }
    else hitAt(u.side, t, dmg, u.cleave || 0, u.type);
    if (AR.hitT <= 0) { sfx('hit', 0.07); AR.hitT = 0.07; }
  }
  function hitAt(side, t, dmg, area, type) {
    if (area) { for (const o of AR.units) if (o.side !== side && !o.dead && Math.hypot(o.x - t.x, o.y - t.y) < area + o.r) hurtU(o, dmg * ((MULT[type] && MULT[type][o.type]) || 1)); if (t.isT) hurtT(t, dmg, side); AR.fx.push({ k: 'ring', x: t.x, y: t.y, t: 0.25, r: area, c: side === 'me' ? '#f6e2a0' : '#e8a080' }); return; }
    if (t.isT) hurtT(t, dmg, side); else hurtU(t, dmg);
  }
  function uTick(u, dt) {
    if (u.dead) return; u.t += dt; u.flash = Math.max(0, u.flash - dt); if (u.deployT > 0) { u.deployT -= dt; return; }
    u.tauntT = Math.max(0, (u.tauntT || 0) - dt); u.moving = false;
    if (u.roar) { u.roarT -= dt; if (u.roarT <= 0) { u.roarT = 6; let n = 0; for (const o of AR.units) if (o.side !== u.side && !o.dead && Math.hypot(o.x - u.x, o.y - u.y) < 90) { o.taunt = u; o.tauntT = 2.5; o.tg = u; n++; } if (n) { AR.fx.push({ k: 'ring', x: u.x, y: u.y, t: 0.45, r: 90, c: '#e2b85a' }); AR.fx.push({ k: 'say', x: u.x, y: u.y - 20, t: 1, v: '이놈들!' }); sfx('slam', 0.3); } } }
    if (u.healer) { u.healT -= dt; if (u.healT <= 0) { u.healT = 2; for (const o of AR.units) if (o.side === u.side && !o.dead && Math.hypot(o.x - u.x, o.y - u.y) < 80) o.hp = Math.min(o.max, o.hp + 25); AR.fx.push({ k: 'ring', x: u.x, y: u.y, t: 0.4, r: 80, c: '#8fe08a' }); } }
    u.rt -= dt; if (u.rt <= 0 || !alive(u.tg)) { u.rt = 0.35; u.tg = pickTarget(u); }
    const t = u.tg; if (!t) return;
    const dd = Math.hypot(t.x - u.x, t.y - u.y) - (t.r || 0) - u.r;
    if (dd <= u.rng && !(waypoint(u, t) !== t && !u.proj)) { u.cd -= dt; if (u.cd <= 0) { u.cd = 1 / u.rate; attack(u, t); } u.fd = dirOf(t.x - u.x, t.y - u.y); }
    else { const w = waypoint(u, t), dx = w.x - u.x, dy = w.y - u.y, dl = Math.hypot(dx, dy) || 1, sp = u.spd * dt; u.x += dx / dl * Math.min(sp, dl); u.y += dy / dl * Math.min(sp, dl); u.fd = dirOf(dx, dy); u.moving = true; }
  }
  function towerTick(t, dt) {
    if (t.dead) return; t.flash = Math.max(0, t.flash - dt); t.cd -= dt; if (t.cd > 0) return;
    let best = null, bd = t.rng; for (const o of AR.units) if (o.side !== t.side && !o.dead && o.deployT <= 0) { const d = Math.hypot(o.x - t.x, o.y - t.y) - o.r; if (d < bd) { bd = d; best = o; } }
    if (!best) return; t.cd = 1 / t.rate; AR.proj.push({ x: t.x, y: t.y - 10, sx: t.x, sy: t.y - 10, tg: best, tx: best.x, ty: best.y, t: 0, dur: Math.max(0.12, bd / 380), kind: 'arrow', dmg: t.dmg, side: t.side, splash: 0, type: 'tower' });
  }
  // 상대(와 시험용 내 쪽 자동) 생각: 막을 게 있으면 상성 맞는 카드로 막고, 군량이 차면 약한 쪽 길로 밀어붙임
  function armyAI(side, dt) {
    const S = AR.ai[side], C = ARMY_AI[AR.foe] || ARMY_AI.cyz; S.t -= dt; if (S.t > 0) return; S.t = rnd(C.think[0], C.think[1]);
    const op = side === 'me' ? 'foe' : 'me', e = AR.elx[side], hd = hand(side), mineHalf = (y) => (side === 'foe' ? y < RIV0 + 70 : y > RIV1 - 70);
    const th = AR.units.filter((u) => u.side === op && !u.dead && mineHalf(u.y));
    if (th.length && Math.random() < C.react) {
      const cx = th.reduce((s, u) => s + u.x, 0) / th.length, cy = th.reduce((s, u) => s + u.y, 0) / th.length, cl = th.filter((u) => Math.hypot(u.x - cx, u.y - cy) < 55).length;
      let best = -1, bs = 0;
      hd.forEach((c, i) => { if (costOf(c) > e) return; let sc = 0; if (c === 'fire') sc = cl >= 3 ? 2.5 + cl * 0.4 : 0; else if (c.startsWith('g:')) sc = 1.4 + th.length * 0.25; else { for (const u of th) sc += ((MULT[c] && MULT[c][u.type]) || 1) - 0.55; if (c === 'shield') sc += 0.6; } if (sc > bs) { bs = sc; best = i; } });
      if (best >= 0 && bs > 0.8) { const c = hd[best], lead = th.reduce((a, b) => (side === 'foe' ? (a.y < b.y ? a : b) : (a.y > b.y ? a : b))); const x = c === 'fire' ? cx : clamp(lead.x + rnd(-18, 18), 16, FW - 16), y = c === 'fire' ? cy : side === 'foe' ? clamp(lead.y - 55, 40, RIV0 - 14) : clamp(lead.y + 55, RIV1 + 14, FH - 40); playCard(side, best, x, y); return; }
    }
    if (e >= S.push) {
      const myT = AR.towers.filter((t) => t.side === op && !t.dead && !t.main).sort((a, b) => a.hp - b.hp)[0], lx = myT ? myT.x : FW / 2;
      const order = [hd.find((c) => c.startsWith('g:')), 'shield', 'cav', 'spear', 'arch'].filter(Boolean); let i = -1; for (const o of order) { const k = hd.indexOf(o); if (k >= 0 && costOf(o) <= e) { i = k; break; } }
      if (i < 0) i = hd.findIndex((c) => c !== 'fire' && costOf(c) <= e);
      if (i >= 0) { const c = hd[i], y = side === 'foe' ? (c === 'arch' ? 150 : rnd(200, 262)) : (c === 'arch' ? 450 : rnd(338, 400)); playCard(side, i, clamp(lx + rnd(-16, 16), 16, FW - 16), y); S.push = rnd(C.push[0], C.push[1]); }
    }
  }
  function armyUpdate(dt) {
    if (!AR || AR.st !== 'play') return; AR.time += dt; AR.hitT = Math.max(0, AR.hitT - dt);
    const dbl = AR.phase === 'ot' || AR.t <= 30, rate = (dbl ? 2 : 1) / 2.8; for (const s of ['me', 'foe']) AR.elx[s] = Math.min(10, AR.elx[s] + rate * dt);
    if (AR.phase === 'main') { AR.t -= dt; if (AR.t <= 0) { AR.t = 0; if (AR.crowns.me !== AR.crowns.foe) return armyEnd(); AR.phase = 'ot'; AR.ot = 30; banner('연장전!', '먼저 성을 무너뜨리는 쪽이 이겨요 · 군량 두 배'); } }
    else { AR.ot -= dt; if (AR.ot <= 0) { AR.ot = 0; return armyEnd(); } }
    armyAI('foe', dt); if (AR.auto.me) armyAI('me', dt);
    for (const u of AR.units) uTick(u, dt);
    // 겹치지 않게
    for (let i = 0; i < AR.units.length; i++) { const a = AR.units[i]; if (a.dead || a.deployT > 0) continue; for (let j = i + 1; j < AR.units.length; j++) { const b = AR.units[j]; if (b.dead || b.deployT > 0) continue; const dx = b.x - a.x, dy = b.y - a.y, d = Math.hypot(dx, dy), m = (a.r + b.r) * 0.9; if (d > 0.01 && d < m) { const k = (m - d) * 0.5 / d; a.x -= dx * k * 0.5; a.y -= dy * k * 0.5; b.x += dx * k * 0.5; b.y += dy * k * 0.5; } } }
    for (const u of AR.units) { u.x = clamp(u.x, 8, FW - 8); u.y = clamp(u.y, 8, FH - 8); }
    for (const t of AR.towers) towerTick(t, dt);
    for (const p of AR.proj) { p.t += dt; if (alive(p.tg)) { p.tx = p.tg.x; p.ty = p.tg.y; } const k = Math.min(1, p.t / p.dur); p.x = p.sx + (p.tx - p.sx) * k; p.y = p.sy + (p.ty - p.sy) * k; if (k >= 1) { p.done = true; if (p.splash) { const fake = alive(p.tg) ? p.tg : { x: p.tx, y: p.ty }; hitAt(p.side, fake, p.dmg, p.splash, p.type); if (p.kind === 'fire') AR.fx.push({ k: 'fire', x: p.tx, y: p.ty, t: 0.35, r: p.splash }); } else if (alive(p.tg)) hitAt(p.side, p.tg, p.dmg, 0, p.type); } }
    AR.proj = AR.proj.filter((p) => !p.done); AR.units = AR.units.filter((u) => !u.dead);
    for (const f of AR.fx) f.t -= dt; AR.fx = AR.fx.filter((f) => f.t > 0);
    if (Math.floor(AR.elx.me) !== AR.elxShown) armyUI(); else { const fl = $('elxFill'); if (fl) fl.style.width = `${AR.elx.me * 10}%`; }
    hudUpdate();
  }
  function armyEnd() {
    if (AR.st === 'end') return; AR.st = 'end'; const c = AR.crowns; let w = c.me > c.foe ? 'me' : c.foe > c.me ? 'foe' : null;
    if (!w) { const hp = (s) => AR.towers.filter((t) => t.side === s).reduce((m, t) => Math.min(m, t.hp / t.max), 1); const a = hp('me'), b = hp('foe'); w = a > b + 0.001 ? 'me' : b > a + 0.001 ? 'foe' : null; }
    sfx(w === 'me' ? 'win' : 'lose', 0.4); const st = SV.load.c; const xp = st && SV.pets[st] ? petXPLine(st, w === 'me' ? 20 : 8) : ''; if (w === 'me') SV.duels.w++; else if (w === 'foe') SV.duels.l++; saveSV();
    setTimeout(() => { $('act').hidden = true; card(`<h2>${w === 'me' ? '군세 대결 승리!' : w === 'foe' ? '군세 대결 패배' : '무승부'}</h2><p class="lead">${FOES[AR.foe].n}: "${w === 'me' ? '…졌다. 먹물이 걷히니 내가 왜 싸웠는지 모르겠구나.' : w === 'foe' ? '하하! 황건의 기세를 봤느냐!' : '제법이구나. 다음엔 끝을 보자.'}"</p><div class="stats"><span>무너뜨린 성</span><b>나 ${c.me} : ${c.foe} 상대</b><span>걸린 시간</span><b>${fmtT(AR.time)}</b>${xp}</div><button class="go" type="button" id="again">다시 겨루기</button><button class="sub" type="button" id="back">책방으로</button>`, (cc) => { cc.querySelector('#again').onclick = () => { closeCard(); startArmy(AR.foe); }; cc.querySelector('#back').onclick = () => { closeCard(); AR = null; title(); }; }); }, 700);
  }
  // ── 아래 카드 줄(엄지 자리)
  function armyUI() {
    const el = $('act'); if (!AR || MODE !== 'army') { el.hidden = true; return; } el.hidden = false; AR.elxShown = Math.floor(AR.elx.me);
    const hd = hand('me'), nx = cardOf(AR.q.me[3]), on = AR.st === 'play';
    el.innerHTML = `<div class="army"><div class="hand"><div class="next"><small>다음</small><i style="color:${nx.c}">${nx.g}</i></div>${hd.map((c, i) => { const C = cardOf(c), ok = AR.elx.me >= C.cost; return `<button type="button" data-cd="${i}" class="${AR.sel === i ? 'on' : ''} ${ok ? '' : 'poor'}" ${on ? '' : 'disabled'} style="--c:${C.c}"><em>${C.cost}</em><i>${C.g}</i><b>${C.n}</b><small>${C.hint}</small></button>`; }).join('')}</div><div class="elx"><div class="bar"><i id="elxFill" style="width:${AR.elx.me * 10}%"></i>${Array.from({ length: 9 }, (_, k) => `<s style="left:${(k + 1) * 10}%"></s>`).join('')}</div><b>군량 ${Math.floor(AR.elx.me)}</b></div></div>`;
    el.querySelectorAll('[data-cd]').forEach((b) => b.onclick = () => { const i = +b.dataset.cd; AR.sel = AR.sel === i ? null : i; armyUI(); });
  }
  function armyHud() { const F = FOES[AR.foe]; $('page').textContent = `군세 대결 · ${F.n.split(' ').pop()}`; $('pause').style.display = 'none'; $('swap').style.display = 'none'; $('bag').style.display = 'none'; $('goal').hidden = true;
    const tl = AR.phase === 'ot' ? `연장 ${fmtT(AR.ot)}` : fmtT(AR.t), h = `<span class="tag" style="${AR.phase === 'ot' || AR.t <= 30 ? 'border-color:var(--bad)' : ''}">${tl}</span><span class="tag">성 나 ${AR.crowns.me} : ${AR.crowns.foe} 상대</span><span class="tag" style="border-color:#c89a50">${AR.t <= 30 || AR.phase === 'ot' ? '군량 두 배' : '상성: 창 > 기 > 궁 > 창'}</span>`; if ($('tags').innerHTML !== h) $('tags').innerHTML = h; }
  function armyTap(cx, cy) {
    if (!AR || AR.st !== 'play' || !$('ov').hidden) return; const x = (cx - OX) / SC, y = (cy - OY) / SC; if (x < 0 || x > FW || y < 0 || y > FH) return;
    if (AR.sel == null) { banner('먼저 아래 카드를 골라요', '그다음 내 진영을 눌러요'); return; }
    const c = AR.q.me[AR.sel], C = cardOf(c);
    if (!C.spell && y < RIV1 + 8) { banner('내 진영(아래 절반)에만 놓을 수 있어요', '화계는 어디든'); return; }
    if (AR.elx.me < C.cost) { banner(`군량이 모자라요 (${C.cost} 필요)`, ''); return; }
    playCard('me', AR.sel, clamp(x, 12, FW - 12), clamp(y, 12, FH - 12)); AR.sel = null; armyUI();
  }
  // ── 그리기
  function armyLayout() { const top = ($('hud').hidden ? 0 : $('hud').offsetHeight) + 4, ab = $('act'), bot = H - (ab.hidden ? 8 : ab.offsetHeight + 16); SC = Math.min(W / FW, (bot - top) / FH); OX = (W - FW * SC) / 2; OY = top + Math.max(0, (bot - top - FH * SC) / 2); CAMX = 0; CAMY = 0; }
  function armyBg() { return mk(FW, FH, (g) => { for (let y = 0; y < FH; y += 16) for (let x = 0; x < FW; x += 16) g.drawImage(TILE.grass[((x / 16) * 7 + (y / 16) * 13) % 4], x, y);
    const pt = TILE.path9 ? TILE.path9[4] : TILE.path[0]; for (const lx of LANES) for (let y = 96; y < 520; y += 16) { g.drawImage(pt, lx - 16, y); g.drawImage(pt, lx, y); } for (let x = 80; x < 296; x += 16) { g.drawImage(pt, x, 92); g.drawImage(pt, x, 500); }
    for (let x = 0; x < FW; x += 16) { g.drawImage(TILE.water[0], x, RIV0); g.drawImage(TILE.water[1], x, RIV0 + 8); }
    for (const lx of LANES) { g.fillStyle = '#6a4a2a'; g.fillRect(lx - 20, RIV0 - 3, 40, RIV1 - RIV0 + 6); g.fillStyle = '#a8784a'; for (let y = RIV0 - 2; y < RIV1 + 3; y += 5) g.fillRect(lx - 18, y, 36, 3); }
    g.fillStyle = 'rgba(255,255,255,0.18)'; g.fillRect(0, RIV1 + 6, FW, 2); g.fillRect(0, RIV0 - 8, FW, 2); }); }
  function armyRender() {
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.imageSmoothingEnabled = false; ctx.fillStyle = '#1d1813'; ctx.fillRect(0, 0, W, H); if (!AR) return; armyLayout();
    if (!AR.bg || AR.bgN !== NINJA) { AR.bg = armyBg(); AR.bgN = NINJA; AR.timg = null; } ctx.drawImage(AR.bg, OX, OY, FW * SC, FH * SC);
    if (AR.sel != null) { const C = cardOf(AR.q.me[AR.sel]); ctx.fillStyle = 'rgba(80,140,230,0.16)'; if (C.spell) ctx.fillRect(OX, OY, FW * SC, FH * SC); else ctx.fillRect(OX, Y(RIV1 + 8), FW * SC, (FH - RIV1 - 8) * SC); ctx.strokeStyle = 'rgba(80,140,230,0.7)'; ctx.setLineDash([6, 5]); ctx.lineWidth = 2; ctx.strokeRect(OX + 1, C.spell ? OY + 1 : Y(RIV1 + 8), FW * SC - 2, C.spell ? FH * SC - 2 : (FH - RIV1 - 8) * SC - 1); ctx.setLineDash([]); }
    if (!AR.timg && NINJA) AR.timg = { me: houseImg('houseB', 2, 2, [], ''), foe: houseImg('houseR', 2, 2, [], ''), meK: houseImg('houseB', 3, 2, [1], ''), foeK: houseImg('houseR', 3, 2, [1], '') };
    const list = [];
    for (const t of AR.towers) list.push({ y: t.y, draw: () => { const w = (t.main ? 48 : 34), h = t.main ? 34 : 34; if (t.dead) { ctx.fillStyle = '#5a4a3a'; ctx.fillRect(X(t.x - w / 2), Y(t.y - 6), w * SC, 14 * SC); ctx.fillStyle = 'rgba(60,50,40,0.5)'; ctx.beginPath(); ctx.arc(X(t.x), Y(t.y - 10 - Math.sin(AR.time * 2) * 3), 8 * SC, 0, 7); ctx.fill(); return; }
      const img = AR.timg && AR.timg[t.side + (t.main ? 'K' : '')]; if (img) ctx.drawImage(img, X(t.x - w / 2), Y(t.y - h / 2), w * SC, h * SC); else { ctx.fillStyle = t.side === 'me' ? '#4a6a9a' : '#b8432f'; ctx.fillRect(X(t.x - w / 2), Y(t.y - h / 2), w * SC, h * SC); }
      if (t.flash > 0) { ctx.fillStyle = 'rgba(255,255,255,0.4)'; ctx.fillRect(X(t.x - w / 2), Y(t.y - h / 2), w * SC, h * SC); }
      ctx.fillStyle = t.side === 'me' ? '#4a7ab8' : '#d9483a'; ctx.beginPath(); ctx.moveTo(X(t.x + w / 2 - 4), Y(t.y - h / 2 - 12)); ctx.lineTo(X(t.x + w / 2 + 8), Y(t.y - h / 2 - 8)); ctx.lineTo(X(t.x + w / 2 - 4), Y(t.y - h / 2 - 4)); ctx.fill(); ctx.fillStyle = '#3a2a1a'; ctx.fillRect(X(t.x + w / 2 - 5), Y(t.y - h / 2 - 12), 1.5 * SC, 14 * SC);
      const bw = w; ctx.fillStyle = '#3a3024'; ctx.fillRect(X(t.x - bw / 2), Y(t.y - h / 2 - 7), bw * SC, 4 * SC); ctx.fillStyle = t.side === 'me' ? '#6fae6a' : '#d9705e'; ctx.fillRect(X(t.x - bw / 2), Y(t.y - h / 2 - 7), bw * SC * t.hp / t.max, 4 * SC); } });
    for (const u of AR.units) list.push({ y: u.y, draw: () => { const sz = u.type === 'gen' ? 30 : u.type === 'cav' ? 26 : 22, al = u.deployT > 0 ? 0.5 : 1; ctx.globalAlpha = al;
      ctx.strokeStyle = u.side === 'me' ? '#4a7ab8' : '#d9483a'; ctx.lineWidth = 2; ctx.beginPath(); ctx.ellipse(X(u.x), Y(u.y + sz * 0.38), sz * 0.36 * SC, sz * 0.13 * SC, 0, 0, 7); ctx.stroke();
      const f = u.moving ? Math.floor((u.t) * 8) : 0;
      if (NINJA && Array.isArray(u.spr)) { const hw = NS[u.spr[0]], rw = NS[u.spr[1]]; if (hw) sprAt(hw, u.fd === 'left' ? 'left' : 'right', f, u.x, u.y + 4, sz, u.flash > 0, al); if (rw) sprAt(rw, u.side === 'me' ? 'up' : 'down', 0, u.x, u.y - sz * 0.32, sz * 0.75, u.flash > 0, al); }
      else if (NINJA && NS[u.spr]) sprAt(NS[u.spr], u.fd, f, u.x, u.y, sz, u.flash > 0, al);
      else { const C = cardOf(u.type === 'gen' ? 'g:' + u.gen : u.type); circle(u.x, u.y, u.r, C.c, u.side === 'me' ? '#4a7ab8' : '#d9483a'); glyph(C.g, u.x, u.y, u.r, '#fffaf0'); }
      if (u.type === 'gen') { ctx.font = `700 ${Math.round(9 * SC)}px "Gowun Dodum", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.lineWidth = 2.5; ctx.strokeStyle = '#1d1813'; const nm = cardOf('g:' + u.gen).n; ctx.strokeText(nm, X(u.x), Y(u.y - sz * 0.62)); ctx.fillStyle = u.side === 'me' ? '#cfe2f4' : '#ffd0c0'; ctx.fillText(nm, X(u.x), Y(u.y - sz * 0.62)); }
      if (u.side === 'foe' && u.hp > 0) { ctx.fillStyle = `rgba(36,22,48,${0.2 + 0.4 * u.hp / u.max})`; ctx.beginPath(); ctx.arc(X(u.x + 3), Y(u.y - 2), sz * 0.12 * SC, 0, 7); ctx.fill(); }
      if (u.tauntT > 0) circle(u.x, u.y, u.r + 5, null, 'rgba(226,184,90,0.9)');
      if (u.hp < u.max) { const bw = sz * 0.8; ctx.fillStyle = '#3a3024'; ctx.fillRect(X(u.x - bw / 2), Y(u.y - sz * 0.55 - (u.type === 'gen' ? 8 : 0)), bw * SC, 3 * SC); ctx.fillStyle = u.side === 'me' ? '#6fae6a' : '#d9705e'; ctx.fillRect(X(u.x - bw / 2), Y(u.y - sz * 0.55 - (u.type === 'gen' ? 8 : 0)), bw * SC * u.hp / u.max, 3 * SC); }
      ctx.globalAlpha = 1; } });
    list.sort((a, b) => a.y - b.y).forEach((o) => o.draw());
    for (const p of AR.proj) { if (p.kind === 'fire') { ctx.fillStyle = 'rgba(255,140,60,0.5)'; ctx.beginPath(); ctx.arc(X(p.x), Y(p.y), 7 * SC, 0, 7); ctx.fill(); ctx.fillStyle = '#ffd38a'; ctx.beginPath(); ctx.arc(X(p.x), Y(p.y), 3 * SC, 0, 7); ctx.fill(); } else { const a = Math.atan2(p.ty - p.sy, p.tx - p.sx); ctx.strokeStyle = p.side === 'me' ? '#3a2a1a' : '#6a1a0a'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.moveTo(X(p.x - Math.cos(a) * 6), Y(p.y - Math.sin(a) * 6)); ctx.lineTo(X(p.x), Y(p.y)); ctx.stroke(); } }
    for (const f of AR.fx) { if (f.k === 'ring') { ctx.globalAlpha = Math.min(1, f.t * 2.5); ctx.strokeStyle = f.c; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(X(f.x), Y(f.y), f.r * SC * (1.15 - f.t), 0, 7); ctx.stroke(); ctx.globalAlpha = 1; }
      else if (f.k === 'fire') { ctx.globalAlpha = Math.min(1, f.t * 2); ctx.fillStyle = 'rgba(255,120,50,0.35)'; ctx.beginPath(); ctx.arc(X(f.x), Y(f.y), f.r * SC, 0, 7); ctx.fill(); for (let i = 0; i < 9; i++) { const a = i / 9 * 6.28 + AR.time * 3, rr = f.r * (0.3 + 0.6 * ((i * 37) % 10) / 10); ctx.fillStyle = i % 2 ? '#ffd38a' : '#ff7a3a'; ctx.beginPath(); ctx.arc(X(f.x + Math.cos(a) * rr), Y(f.y + Math.sin(a) * rr - (0.7 - f.t) * 12), 3.5 * SC, 0, 7); ctx.fill(); } ctx.globalAlpha = 1; }
      else if (f.k === 'wash') { ctx.globalAlpha = Math.min(1, f.t * 2); for (let i = 0; i < 5; i++) { const a = i / 5 * 6.28 + f.t * 5, rr = 6 + (0.7 - f.t) * 22; ctx.fillStyle = i % 2 ? '#fff6c8' : '#ffffff'; ctx.fillRect(X(f.x + Math.cos(a) * rr) - 2, Y(f.y + Math.sin(a) * rr - (0.7 - f.t) * 14) - 2, 4, 4); } ctx.globalAlpha = 1; }
      else if (f.k === 'puff') { ctx.globalAlpha = f.t * 2; circle(f.x, f.y, 4 + (0.5 - f.t) * 20, null, '#5a4a36'); ctx.globalAlpha = 1; }
      else if (f.k === 'boom') { ctx.globalAlpha = Math.min(1, f.t * 1.5); for (let i = 0; i < 12; i++) { const a = i / 12 * 6.28, rr = 10 + (0.8 - f.t) * 50; circle(f.x + Math.cos(a) * rr, f.y + Math.sin(a) * rr, 4, i % 2 ? '#e2b85a' : '#8a6a4a'); } ctx.globalAlpha = 1; }
      else if (f.k === 'say') { ctx.globalAlpha = Math.min(1, f.t * 3); ctx.font = `700 ${Math.round(10 * SC)}px "Gowun Dodum", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; const tw = ctx.measureText(f.v).width + 10; ctx.fillStyle = '#fffaf0'; ctx.strokeStyle = '#3a2a1a'; ctx.lineWidth = 1.2; ctx.fillRect(X(f.x) - tw / 2, Y(f.y - (1.1 - f.t) * 8) - 8 * SC, tw, 16 * SC); ctx.strokeRect(X(f.x) - tw / 2, Y(f.y - (1.1 - f.t) * 8) - 8 * SC, tw, 16 * SC); ctx.fillStyle = '#2a2218'; ctx.fillText(f.v, X(f.x), Y(f.y - (1.1 - f.t) * 8)); ctx.globalAlpha = 1; } }
    // 시간
    { const tl = AR.phase === 'ot' ? `연장 ${fmtT(AR.ot)}` : fmtT(AR.t); ctx.font = `700 ${Math.round(14 * SC)}px "Gowun Dodum", sans-serif`; ctx.textAlign = 'left'; ctx.textBaseline = 'top'; ctx.lineWidth = 3; ctx.strokeStyle = '#1d1813'; ctx.strokeText(tl, OX + 8, OY + 8); ctx.fillStyle = AR.phase === 'ot' || AR.t <= 30 ? '#ff9a8a' : '#fff2c0'; ctx.fillText(tl, OX + 8, OY + 8); }
  }
