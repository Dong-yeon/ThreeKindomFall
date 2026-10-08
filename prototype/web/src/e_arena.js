  // ═════════ 싸움판: book(책 읽기) · wild(떠도는 이야기) · duel(북 대결) ═════════
  let A = null;
  const pw = (k) => (A && A.pw[k]) || 0;
  function mkActor(side, o) { return Object.assign({ side, x: AW / 2, y: AH - 60, r: 12, hp: 100, max: 100, atk: 10, rate: 2.2, spd: 150, cd: 0, inv: 0, fx: 0, fy: -1, vx: 0, vy: 0, lx: 0, ly: 0, still: 0, flash: 0 }, o); }
  function mkPet(id, lvl, owner) { return { id, lvl, owner, sta: 100, tired: false, x: owner.x + 20, y: owner.y + (owner.side === 'me' ? 16 : -16), cd: 1, warn: 0, wx: 0, wy: 0 }; }
  function baseArena(kind) {
    A = { kind, state: 'play', t: 0, p: mkActor('me'), pw: {}, en: [], shots: [], ebul: [], fx: [], obs: [], doors: null, lean: { kind: 0, greed: 0, swift: 0 }, kills: 0, coins: 0, dealt: 0, taken: 0, shake: 0, start: performance.now(), foe: null, fpet: null, pi: 0, cleared: false };
    A.pet = SV.load.c && SV.pets[SV.load.c] ? mkPet(SV.load.c, SV.pets[SV.load.c].lvl, A.p) : null;
    A.weap = SV.load.b1 && SV.pets[SV.load.b1] ? { id: SV.load.b1, lvl: SV.pets[SV.load.b1].lvl } : null;
    A.sta = {}; for (const id of SV.party) A.sta[id] = 100; A.swapCd = 0; A.squad = []; A.oath = false;
    A.p.body = myBody(); A.p.counterT = 0; A.p.guardUsed = false;
    setMode('arena'); music('fight'); joy.on = false; $('hud').hidden = false; $('hpw').style.display = '';
  }
  function placeObs(n) { A.obs = []; let tries = 0; while (A.obs.length < n && tries++ < 60) { const w = rnd(40, 90), h = rnd(26, 46), o = { x: rnd(20, AW - 20 - w), y: rnd(110, AH - 170 - h), w, h, k: Math.random() < 0.55 ? 'wall' : 'pool' }; if (A.obs.some((q) => o.x < q.x + q.w + 30 && o.x + o.w + 30 > q.x && o.y < q.y + q.h + 30 && o.y + o.h + 30 > q.y)) continue; A.obs.push(o); } }
  function spawnSet(list, mul) { for (const [k, n] of list) for (let j = 0; j < n; j++) { let x, y, tries = 0; do { x = rnd(30, AW - 30); y = rnd(70, AH * 0.55); } while (tries++ < 30 && (hitObs(x, y, EN[k].r + 4) || Math.hypot(x - A.p.x, y - A.p.y) < 180)); spawn(k, x, y, mul); } }
  function spawn(k, x, y, mul) { const E = EN[k]; A.en.push({ side: 'en', k, x, y, r: E.r, hp: E.hp * mul, max: E.hp * mul, spd: E.spd, touch: E.touch * (0.9 + 0.1 * mul), ai: E.ai, t: rnd(0, 1.5), st: 0, vx: 0, vy: 0, flash: 0, phase: 0 }); }
  // 벽(책더미)만 탄을 막음. 시선: 두 점 사이에 벽이 있는지(8px 간격 표본)
  const inWall = (x, y, r = 0) => A.obs.some((o) => o.k === 'wall' && x + r > o.x && x - r < o.x + o.w && y + r > o.y && y - r < o.y + o.h);
  function los(a, b) { const d = Math.hypot(b.x - a.x, b.y - a.y), n = Math.ceil(d / 8); for (let i = 1; i < n; i++) { const t = i / n; if (inWall(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)) return false; } return true; }
  function hitObs(x, y, r) { return A.obs.some((o) => x + r > o.x && x - r < o.x + o.w && y + r > o.y && y - r < o.y + o.h); }
  function pushOut(e) { for (const o of A.obs) { const cx = clamp(e.x, o.x, o.x + o.w), cy = clamp(e.y, o.y, o.y + o.h), dx = e.x - cx, dy = e.y - cy, d = Math.hypot(dx, dy); if (d < e.r) { if (d > 0.01) { e.x = cx + dx / d * e.r; e.y = cy + dy / d * e.r; } else { e.y = o.y - e.r; } } }
    e.x = clamp(e.x, e.r + 4, (A.WW || AW) - e.r - 4); e.y = clamp(e.y, e.r + 4, (A.WH || AH) - e.r - 4); }
  const runK = () => A.kind === 'book' || A.kind === 'surv'; // 책장의 힘이 도는 판

  // ── 책 읽기
  function startBook() { baseArena('book'); SV.runs++; saveSV(); enterPage(0); }
  function enterPage(i) {
    A.pi = i; const P = PAGES[i]; A.en = []; A.shots = []; A.ebul = []; A.doors = null; A.cleared = false; A.p.x = AW / 2; A.p.y = AH - 50; if (A.pet) { A.pet.x = AW / 2 + 22; A.pet.y = AH - 36; }
    if (P.boss) A.obs = []; else placeObs(2 + Math.floor(Math.random() * 3));
    const mul = 1 + 0.14 * i;
    if (P.boss) spawn('boss', AW / 2, 120, 1 + 0.02 * i); else spawnSet(P.en, mul);
    hudUpdate(); banner(`${i + 1}장 · ${P.t}`, P.story || (P.boss ? '책의 마지막 장 — 놀부의 심술이 도깨비 박이 되었어요!' : ''));
  }
  // ── 떠도는 이야기(책 덤불)
  // 장(章)마다 다른 떠도는 이야기
  const WILD = { N: [[['wisp', 2]], [['wisp', 2], ['crow', 1]], [['vine', 1], ['wisp', 2]], [['crow', 2]], [['wisp', 3]]],
    W: [[['vine', 2], ['wisp', 2]], [['vine', 1], ['crow', 2]], [['vine', 3]]], E: [[['servant', 1], ['wisp', 2]], [['servant', 2]], [['servant', 1], ['crow', 2]]], S: [[['crow', 4]], [['crow', 3], ['wisp', 1]], [['crow', 2], ['vine', 1]]] };
  const WILDMUL = { N: 0.85, W: 1, E: 1.05, S: 1 };
  function startWild(zone = 'N') { baseArena('wild'); A.zone = zone; placeObs(1 + Math.floor(Math.random() * 2)); spawnSet(pick(WILD[zone] || WILD.N), WILDMUL[zone] || 0.85); hudUpdate(); banner('떠도는 이야기가 튀어나왔어요!', '흥부전에서 새어 나온 조각들'); }
  // ── 북 대결
  let D = null; // 3판 2선승 진행
  function startDuelRound() {
    const F = FOES[D.foe], fp = F.pets[D.fi % F.pets.length];
    baseArena('duel'); A.pet = D.myPet ? mkPet(D.myPet, SV.pets[D.myPet].lvl, A.p) : null; 
    A.obs = [{ x: 50, y: 250, w: 80, h: 30, k: 'wall' }, { x: AW - 130, y: AH - 280, w: 80, h: 30, k: 'wall' }, { x: AW - 120, y: 190, w: 60, h: 26, k: 'pool' }, { x: 60, y: AH - 216, w: 60, h: 26, k: 'pool' }];
    A.foe = mkActor('foe', { x: AW / 2, y: 110, hp: F.hp, max: F.hp, atk: F.atk, rate: F.rate, spd: F.spd, fy: 1, shotSp: F.shotSp });
    A.foe.brain = makeBrain(F.ai); A.foe.weap = F.weapon || null; A.foe.body = bodyOf(F.body || []); A.foe.counterT = 0; A.foe.guardUsed = false; A.foe.stillT = 0; A.fpet = mkPet(fp.id, fp.lvl, A.foe);
    hudUpdate(); banner(`${D.round}판 · ${F.n}`, `상대 소환수: ${PETS[fp.id].n} ${fp.lvl}단계`);
  }
  // ── 공통 대상
  const tgts = () => { const l = A.en.filter((e) => !e.dead); if (A.foe && A.foe.hp > 0) l.push(A.foe); return l; };
  function nearestOf(list, from) { let b = null, bd = 1e9; for (const e of list) { const d = Math.hypot(e.x - from.x, e.y - from.y); if (d < bd) { bd = d; b = e; } } return b; }
  // 무기 한 발(양쪽 공용). side 'me' → A.shots, 'foe' → A.ebul
  function weapKey(w) { return w ? w.id : 'none'; }
  function fireWeapon(owner, a, dmg, w, mine, target) {
    const Wd = WEAP[weapKey(w)], list = mine ? A.shots : A.ebul, sp0 = mine ? 430 : (owner.shotSp || 380), pierce = mine ? pw('pierce') : 0, ox = owner.x + Math.cos(a) * 14, oy = owner.y + Math.sin(a) * 14;
    const base = { pierce, hit: [], born: A.t, mine, life: 0, bnc: mine && owner === A.p ? 2 * pw('bounce') : 0, chain: mine && owner === A.p ? pw('chain') : 0, ch: pick(GLYPHS) };
    if (Wd.form === 'line') list.push(Object.assign({}, base, { x: ox, y: oy, vx: Math.cos(a) * sp0, vy: Math.sin(a) * sp0, dmg, r: mine ? 4 : 5, kind: mine ? 'page' : 'fpage', c: owner.side === 'foe' ? FOES[D.foe].c : null }));
    else if (Wd.form === 'fan') for (const s of [-0.32, 0, 0.32]) { const b = a + s, sp = 400; list.push(Object.assign({}, base, { hit: [], x: ox, y: oy, vx: Math.cos(b) * sp, vy: Math.sin(b) * sp, dmg, r: 5, kind: 'fan', maxLife: Wd.range / sp, c: '#e0b860' })); }
    else if (Wd.form === 'bomb') list.push(Object.assign({}, base, { x: ox, y: oy, vx: Math.cos(a) * 285, vy: Math.sin(a) * 285, dmg, r: 6, kind: 'seed', boom: 52, maxLife: 1.5, c: '#8aa04a' }));
    else if (Wd.form === 'spray') { const b = a + rnd(-0.1, 0.1); list.push(Object.assign({}, base, { x: ox, y: oy, vx: Math.cos(b) * 470, vy: Math.sin(b) * 470, dmg, r: 3.5, kind: 'coin', c: '#e2b85a' })); }
    else if (Wd.form === 'homing') list.push(Object.assign({}, base, { x: ox, y: oy, vx: Math.cos(a) * 300, vy: Math.sin(a) * 300, dmg, r: 4, kind: w && w.id === 'gumiho' ? 'fox' : 'feather', home: target, sp: mine ? 320 : 300, turn: mine ? (w && w.id === 'gumiho' ? 4 : 3.2) : 2.2, maxLife: 2.2, c: w && w.id === 'gumiho' ? '#ff9a4a' : '#7a9ac0' }));
  }
  function weapDmg(owner, w) { return owner.atk * WEAP[weapKey(w)].mul * (w ? petMul(w.lvl) : 1); }
  function shootPattern(t, mul = 1) {
    const p = A.p, a = Math.atan2(t.y - p.y, t.x - p.x), dmg = weapDmg(p, A.weap) * (1 + 0.25 * pw('dmg')) * greedMul(p, p.still) * mul * (1 + (A.atkBonus || 0)), n = 1 + pw('multi');
    for (let i = 0; i < n; i++) fireWeapon(p, a + (i - (n - 1) / 2) * 0.12, dmg, A.weap, true, t);
    for (let i = 0; i < pw('diag'); i++) for (const s of [-1, 1]) fireWeapon(p, a + s * 0.42, dmg * 0.8, A.weap, true, t);
    for (let i = 0; i < pw('back'); i++) fireWeapon(p, a + Math.PI, dmg * 0.8, A.weap, true, t);
    p.fx = Math.cos(a); p.fy = Math.sin(a); sfx('shoot', 0.12);
  }
  function explode(s, mine) { A.fx.push({ k: 'ring', x: s.x, y: s.y, t: 0.3, r: s.boom, c: '#8aa04a' }); if (mine) { for (const e of tgts()) if (Math.hypot(e.x - s.x, e.y - s.y) < s.boom + e.r) hurtTarget(e, s.dmg); } else if (Math.hypot(A.p.x - s.x, A.p.y - s.y) < s.boom + A.p.r) hurtPlayer(s.dmg); }
  // 교대: 데리고 다니는 소환수 중 책갈피가 아닌 다음 소환수로(기력 높은 순). 쉬는 소환수는 뒤에서 회복
  function swapCands() { return SV.party.filter((id) => SV.pets[id] && id !== SV.load.b1 && (!A.pet || id !== A.pet.id)); }
  function swapPet() { if (!A || A.state !== 'play' || A.swapCd > 0) return; const c = swapCands().sort((a, b) => (A.sta[b] ?? 100) - (A.sta[a] ?? 100)); if (!c.length) return; const id = c[0], old = A.pet; A.pet = mkPet(id, SV.pets[id].lvl, A.p); A.pet.sta = A.sta[id] ?? 100; A.pet.cd = 0.3; if (old) { A.pet.x = old.x; A.pet.y = old.y; } A.swapCd = 2.5; if (A.kind === 'duel') D.myPet = id; sfx('accept', 0.35); A.fx.push({ k: 'ring', x: A.pet.x, y: A.pet.y, t: 0.4, r: 24, c: PETS[id].c }); banner(`교대 — ${PETS[id].n}!`, ''); hudUpdate(); }
  // 구르기: 짧게 톡 친 쪽으로(키보드는 스페이스) — 잠깐 무적
  function dash(dx, dy) { if (!A || A.state !== 'play' || A.kind === 'mu') return; const p = A.p; if (p.dcd > 0 || p.dash) return; const d = Math.hypot(dx, dy); if (d < 0.01) { dx = -p.fy; dy = p.fx; } else { dx /= d; dy /= d; } const v = DASH.dist / DASH.time; const wg = p.body.wing ? 1.3 * Math.min(1.3, petMul(p.body.wing)) / 1 : 1; p.dash = { t: DASH.time, vx: dx * v * wg, vy: dy * v * wg }; p.inv = Math.max(p.inv, DASH.inv); sfx('dash', 0.3); p.dodge = DASH.inv; p.dcd = p.dcdMax = DASH.cd * (p.body.wing ? Math.max(0.45, 0.65 - 0.03 * (p.body.wing - 1)) : 1); A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.2, r: 16, c: '#f4ecd8' });
    // 구미호 둔갑: 구른 자리에 분신 — 적이 잠깐 분신을 노림
    if (p.body.decoy) { A.decoy = { x: p.x, y: p.y, vx: 0, vy: 0, still: 0, t: 1.5 + 0.1 * (p.body.decoy - 1), r: p.r, fx: p.fx, fy: p.fy }; A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.35, r: 26, c: '#ff9a4a' }); } }
  // 왼손에 책갈피를 꽂은 효과(맞았을 때) — 나·상대 공용
  function bodyOnHit(a, mine) { const b = a.body; if (!b) return;
    // (해태 방패는 shieldBlock에서 처리)
    if (b.guard && !a.guardUsed && a.hp < a.max * 0.3) { a.guardUsed = true; sfx('heal', 0.45); if (a.hp <= 0) a.hp = 1; heal(a, a.max * Math.min(0.5, 0.3 + 0.04 * (b.guard - 1))); A.fx.push({ k: 'ring', x: a.x, y: a.y, t: 0.5, r: 40, c: '#8fe08a' }); A.fx.push({ k: 'num', x: a.x, y: a.y - 34, t: 1.1, v: '박의 보살핌!', c: '#d8c070' }); } }
  // 해태 방패: 앞(바라보는 쪽 ±60°)에서 오는 탄 하나를 막고 쏜 쪽으로 되돌림. 재사용 2.2초(단계마다 −0.15초)
  const shieldCdMax = (a) => Math.max(1.2, 2.2 - 0.15 * (a.body.counter - 1));
  function shieldBlock(a, b, mine) { if (!a.body || !a.body.counter || a.counterT > 0) return false; const sp = Math.hypot(b.vx, b.vy) || 1, dot = (-b.vx / sp) * a.fx + (-b.vy / sp) * a.fy; if (dot < 0.5) return false;
    a.counterT = shieldCdMax(a); sfx('slam', 0.3); A.fx.push({ k: 'ring', x: a.x + a.fx * 14, y: a.y + a.fy * 14, t: 0.3, r: 22, c: '#e0b860' });
    const tgt = mine ? nearestOf(tgts(), a) : A.p, ang = tgt ? Math.atan2(tgt.y - a.y, tgt.x - a.x) : Math.atan2(-b.vy, -b.vx), v = Math.max(sp, 380), dmg = (b.dmg || 8) * (1 + 0.15 * (a.body.counter - 1));
    (mine ? A.shots : A.ebul).push({ x: a.x + Math.cos(ang) * 16, y: a.y + Math.sin(ang) * 16, vx: Math.cos(ang) * v, vy: Math.sin(ang) * v, dmg, r: 5, kind: 'refl', hit: [], born: A.t, pierce: 0, mine, life: 0, c: '#e0b860' });
    return true; }
  // 놀부의 욕심: 멈춰 있을수록 셈
  const greedMul = (a, still) => a.body && a.body.greed ? 1 + Math.min(0.4 * petMul(a.body.greed), still * 0.2 * petMul(a.body.greed)) : 1;
  function onHitFx(s, e) { if (!s.mine || e.side !== 'en' || !runK()) return; const atk = A.p.atk;
    if (pw('ink')) { e.ink = 3; e.inkDps = atk * 0.25 * pw('ink'); }
    if (pw('frost')) e.slowT = 1.2;
    if (pw('bolt') && Math.random() < Math.min(0.6, 0.3 * pw('bolt'))) { const near = A.en.filter((o) => !o.dead && o !== e && Math.hypot(o.x - e.x, o.y - e.y) < 130).sort((a, b) => Math.hypot(a.x - e.x, a.y - e.y) - Math.hypot(b.x - e.x, b.y - e.y)).slice(0, 2); for (const o of near) { A.fx.push({ k: 'bolt', x: e.x, y: e.y, x2: o.x, y2: o.y, t: 0.18 }); hurtEnemy(o, atk * 0.6, true); } }
    if (s.chain > 0 && !s.boom) { const nx = A.en.filter((o) => !o.dead && o !== e && !s.hit.includes(o)).sort((a, b) => Math.hypot(a.x - e.x, a.y - e.y) - Math.hypot(b.x - e.x, b.y - e.y))[0]; if (nx && Math.hypot(nx.x - e.x, nx.y - e.y) < 200) { const a = Math.atan2(nx.y - e.y, nx.x - e.x), sp = Math.hypot(s.vx, s.vy) || 430; A.shots.push(Object.assign({}, s, { x: e.x + Math.cos(a) * (e.r + 4), y: e.y + Math.sin(a) * (e.r + 4), vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, dmg: s.dmg * 0.7, hit: [e], chain: s.chain - 1, life: 0, gone: false, home: s.home ? nx : null })); } } }
  function hurtTarget(t, d) { if (t.side === 'foe') hurtFoe(t, d); else hurtEnemy(t, d); }
  function hurtEnemy(e, d, quiet) { if (e.dead) return; if (!quiet) sfx('hit', 0.18); e.hp -= d; e.flash = 0.1; A.dealt += d; if (A.kind !== 'mu' || e.boss || e.elite) A.fx.push({ k: 'num', x: e.x + rnd(-6, 6), y: e.y - e.r, t: quiet ? 0.45 : 0.7, v: Math.round(d), c: quiet ? '#9a8ad0' : '#fff2c0' });
    if (e.hp <= 0) { e.dead = true; A.kills++; if (A.kind === 'mu') { sfx('kill', 0.12); A.fx.push({ k: 'burst', x: e.x, y: e.y, t: 0.3, r: e.r * 0.6, c: '#f6e2a0' }); muKill(e); return; } sfx('kill', 0.25); const cn = e.ai === 'boss' ? 25 : A.kind === 'surv' ? (Math.random() < 0.04 ? 1 : 0) : 1; A.coins += cn; SV.coins += cn; revertFx(e);
      if (A.kind === 'surv') { if (e.k === 'cyz') { A.gems.push({ x: e.x, y: e.y, v: 25 }); banner('정원지의 먹물이 씻겼어요!', '황건 무리가 흔들려요'); } if (e.ai === 'boss') { for (const o of A.en) if (!o.dead && o !== e) { o.dead = true; revertFx(o); } A.later.push({ t: A.t + 1.4, fn: () => endRun() }); banner('도깨비 박의 먹물이 씻겼어요!', ''); } else if (Math.random() < 0.015) A.gems.push({ x: e.x, y: e.y, heal: true }); else { const v = e.k === 'servant' || e.k === 'vine' ? 3 : e.k === 'crow' ? 2 : 1; if (A.gems.length > 260) A.gems[Math.floor(Math.random() * A.gems.length)].v += v; else A.gems.push({ x: e.x + rnd(-4, 4), y: e.y + rnd(-4, 4), v }); } } if (pw('leech')) { if (A.kind === 'surv') { A.leechAcc = (A.leechAcc || 0) + 0.4 * pw('leech'); if (A.leechAcc >= 3) { A.leechAcc -= 3; heal(A.p, 3); } } else heal(A.p, 3 * pw('leech')); } } }
  // 먹물이 씻겨 원래대로 돌아옴(D-156): 하얗게 빛나며 위로 떠오르고, 먹물 방울이 떨어지고, 한마디
  function revertFx(e) { const E = EN[e.k]; A.fx.push({ k: 'revert', x: e.x, y: e.y, t: 0.9, r: e.r, ek: e.k, fd: e.fd || 'down' }); for (let i = 0; i < 6; i++) A.fx.push({ k: 'drop', x: e.x + rnd(-e.r, e.r), y: e.y + rnd(-e.r * 0.5, e.r * 0.5), vy: rnd(20, 60), t: rnd(0.5, 0.8) }); if (E.say && (e.k === 'servant' || e.k === 'boss' || Math.random() < 0.5)) A.fx.push({ k: 'say', x: e.x, y: e.y - e.r - 14, t: 1.3, v: e.say || pick(E.say) }); }
  function hurtFoe(f, d) { if (A.state !== 'play') return; sfx('hit', 0.2); f.hp -= d; f.flash = 0.1; A.dealt += d; bodyOnHit(f, false); A.fx.push({ k: 'num', x: f.x + rnd(-6, 6), y: f.y - f.r, t: 0.7, v: Math.round(d), c: '#fff2c0' }); if (f.hp <= 0) { f.hp = 0; A.fx.push({ k: 'burst', x: f.x, y: f.y, t: 0.6, c: FOES[D.foe].c, r: 16 }); roundEnd('me'); } }
  function heal(a, v) { const b = a.hp; a.hp = Math.min(a.max, a.hp + v); if (a.hp > b) A.fx.push({ k: 'num', x: a.x, y: a.y - 18, t: 0.7, v: '+' + Math.round(a.hp - b), c: '#8fe08a' }); }
  function hurtPlayer(d) { const p = A.p; if (p.inv > 0 || A.state !== 'play') return; if (A.kind === 'mu') { d *= (1 - 0.07 * sk('gap')) * (1 - (A.armRed || 0)); const sr = A.src || '?'; A.tk = A.tk || {}; A.tk[sr] = Math.round((A.tk[sr] || 0) + d); A.src = null; if (A.map && fieldHurt(d)) return; } p.hp -= d; p.inv = 0.6; A.taken += d; sfx('hurt', 0.35); A.shake = 0.22; bodyOnHit(p, true); A.fx.push({ k: 'num', x: p.x, y: p.y - 20, t: 0.7, v: '-' + Math.round(d), c: '#ff9a8a' }); if (p.hp <= 0) { p.hp = 0; if (A.kind === 'duel') roundEnd('foe'); else if (pw('extra') && !A.extraUsed) { A.extraUsed = true; p.hp = p.max * 0.5; p.inv = 2; sfx('heal', 0.5); A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.6, r: 50, c: '#ffd34a' }); banner('덧붙인 쪽!', '한 번 더 읽어 나가요'); } else die(); } }
  // ── 소환수(양쪽 공용). 상대 해태는 내려치기 전에 0.45초 예고
  function slam(pet, dmg, targets, mine) { sfx('slam', mine ? 0.18 : 0.3); const x = mine ? pet.x : pet.wx, y = mine ? pet.y : pet.wy; A.fx.push({ k: 'ring', x, y, t: 0.35, r: 78, c: '#e0b860' }); for (const e of targets) if (Math.hypot(e.x - x, e.y - y) < 78 + e.r) { if (mine) { hurtTarget(e, dmg); if (e.side === 'en' && !e.dead && e.ai !== 'boss') { e.tauntT = 2; e.tauntBy = pet; } } else hurtPlayer(dmg); } }
  function petTick(pet, dt) {
    const own = pet.owner, P = PETS[pet.id], mine = own.side === 'me', BH = P.beh || pet.id, oath = mine && A.oath && OATH.includes(pet.id);
    const pm = petMul(pet.lvl) * (mine ? 1 + 0.6 * pw('petup') : 1) * (oath ? 1.4 : 1) * (mine && A.kind === 'surv' ? 0.75 : 1), cdm = (mine ? 1 - 0.18 * Math.min(2, pw('petup')) : 1) * (oath ? 0.75 : 1);
    let tx = own.x - own.fx * 24 + 14, ty = own.y - own.fy * 24 + 6; if (pet.slot) { const a = A.t * 0.7 + pet.slot * 2.1; tx = own.x + Math.cos(a) * 36; ty = own.y + Math.sin(a) * 26 + 6; } if (pet.leap > 0) pet.leap -= dt; else { pet.x += (tx - pet.x) * Math.min(1, dt * 6); pet.y += (ty - pet.y) * Math.min(1, dt * 6); }
    const targets = mine ? tgts() : [A.p];
    if (pet.warn > 0) { pet.warn -= dt; if (pet.warn <= 0) slam(pet, own.atk * 1.1 * pm, targets, mine); return; }
    if (mine && A.sta && !pet.noSta) pet.sta = A.sta[pet.id] ?? pet.sta;
    if (pet.tired) { pet.sta = Math.min(100, pet.sta + 18 * dt); if (pet.sta >= 60) pet.tired = false; if (mine && A.sta) A.sta[pet.id] = pet.sta; return; }
    pet.cd -= dt; if (pet.cd > 0 || !targets.length) return; pet.cd = P.cd * cdm; const atk = own.atk;
    if (!pet.noSta) pet.sta -= STAMINA[pet.id] || 10; if (pet.sta <= 0) { pet.sta = 0; pet.tired = true; A.fx.push({ k: 'num', x: pet.x, y: pet.y - 16, t: 0.9, v: '지쳤어요', c: '#b8a888' }); if (mine && SV.party.length > 1) banner(`${PETS[pet.id].n}이(가) 지쳤어요`, '교대 버튼(Q)으로 바꿔 줘요'); } if (mine && A.sta) A.sta[pet.id] = pet.sta;
    const shot = (o) => (mine ? A.shots : A.ebul).push(Object.assign({ x: pet.x, y: pet.y, pierce: 0, hit: [], born: A.t, mine }, o));
    if (BH === 'haetae') { const t = nearestOf(targets, pet), near = t && Math.hypot(t.x - own.x, t.y - own.y) < 170;
      if (mine) { if (near) { pet.x = t.x + rnd(-6, 6); pet.y = t.y + 14; pet.leap = 0.25; } slam(pet, atk * 1.1 * pm, targets, true); }
      else { pet.warn = 0.45; if (near) { pet.wx = t.x; pet.wy = t.y; pet.x = t.x; pet.y = t.y - 14; pet.leap = 0.5; } else { pet.wx = pet.x; pet.wy = pet.y; } } }
    else if (BH === 'heung') { heal(own, own.max * (A.kind === 'surv' ? 0.03 : 0.05)); const t = nearestOf(targets, pet); if (t) shot({ vx: 0, vy: 0, dmg: atk * 1.3 * pm, r: 6, kind: 'seed', home: t, sp: 220, turn: mine ? 8 : 3.5, c: '#8aa04a' }); }
    else if (BH === 'nolbu') { const t = pick(targets); const a = Math.atan2(t.y - pet.y, t.x - pet.x) + rnd(-0.15, 0.15); shot({ vx: Math.cos(a) * 360, vy: Math.sin(a) * 360, dmg: atk * 0.45 * pm, r: 4, kind: 'coin', c: '#e2b85a' }); }
    else if (BH === 'blade') { const t = nearestOf(targets, pet); if (t) { const a = Math.atan2(t.y - pet.y, t.x - pet.x); shot({ vx: Math.cos(a) * 330, vy: Math.sin(a) * 330, dmg: atk * 1.0 * pm, r: 13, kind: 'blade', pierce: 99, maxLife: 0.75, c: '#6ac08a' }); } }
    else if (BH === 'gumiho') { const t = nearestOf(targets, pet); if (t) for (let i = 0; i < 3; i++) { const a = -Math.PI / 2 + (i - 1) * 0.9 + (mine ? 0 : Math.PI); shot({ x: pet.x + Math.cos(a) * 10, y: pet.y + Math.sin(a) * 10, vx: Math.cos(a) * 120, vy: Math.sin(a) * 120, dmg: atk * 0.42 * pm, r: 4, kind: 'foxfire', home: t, sp: mine ? 260 : 220, turn: mine ? 4 : 1.8, maxLife: mine ? 2.4 : 1.6, c: '#ff9a4a' }); } }
    else if (BH === 'swallow') { const t = nearestOf(targets, pet); if (t) shot({ vx: 0, vy: 0, dmg: atk * 0.5 * pm, r: 4, kind: 'peck', home: t, sp: mine ? 480 : 280, turn: mine ? 8 : 1.6, maxLife: mine ? 0 : 1.4, c: '#7a9ac0' }); }
  }
  // 적이 노리는 대상: 해태에게 맞으면 2초 해태(도발), 둔갑 분신이 있으면 분신, 아니면 나
  function aimOf(e) { if (e.tauntT > 0) { const tb = e.tauntBy || A.pet; if (tb && !tb.tired) return tb; } if (A.decoy && A.decoy.t > 0) return A.decoy; if (e.engage && !e.engage.dead && Math.hypot(e.engage.x - e.x, e.engage.y - e.y) < 100) return e.engage; if ((e.post || e.goal) && Math.hypot(A.p.x - e.x, A.p.y - e.y) > (e.aggro || 260)) return e.goal || e.post; return A.p; }
  function enemyTick(e, dt) {
    if (e.air > 0) { e.air -= dt; e.x += e.kvx * dt; e.y += e.kvy * dt; e.kvx *= 0.93; e.kvy *= 0.93; e.flash = Math.max(0, e.flash - dt); pushOut(e); if (e.air <= 0) A.fx.push({ k: 'puff', x: e.x, y: e.y + 6, t: 0.2 }); return; }
    const me = A.p, p = aimOf(e), pm = A.map && e.ai !== 'boss' ? fdPath(e, p) : p, dx = pm.x - e.x, dy = pm.y - e.y, d = Math.hypot(dx, dy) || 1; e.t += dt; e.flash = Math.max(0, e.flash - dt); e.tauntT = Math.max(0, (e.tauntT || 0) - dt);
    if (e.spd0 == null) e.spd0 = e.spd; e.slowT = Math.max(0, (e.slowT || 0) - dt); e.spd = e.spd0 * (e.slowT > 0 ? 0.55 : 1); e.orbT = Math.max(0, (e.orbT || 0) - dt);
    if (e.ink > 0) { e.ink -= dt; e.inkAcc = (e.inkAcc || 0) + dt; if (e.inkAcc >= 0.5) { e.inkAcc = 0; hurtEnemy(e, e.inkDps * 0.5, true); if (e.dead) return; } }
    if (e.ai === 'chase') { let vx = dx / d, vy = dy / d; if (e.stuck > 0.25 && !(e.slideT > 0)) e.slideT = 0.9; if (e.slideT > 0) { e.slideT -= dt; const s = e.slide || 1; const ox = vx; vx = -vy * s; vy = ox * s; } e.ox = e.x; e.oy = e.y; e.x += vx * e.spd * dt; e.y += vy * e.spd * dt; }
    else if (e.ai === 'dash') { if (e.st === 0) { e.x += Math.sin(e.t * 2) * 20 * dt; if (e.t > 1.6) { e.st = 1; e.t = 0; e.tx = dx / d; e.ty = dy / d; } } else if (e.st === 1) { if (e.t > 0.4) { e.st = 2; e.t = 0; } } else { e.x += e.tx * 300 * dt * (e.slowT > 0 ? 0.55 : 1); e.y += e.ty * 300 * dt * (e.slowT > 0 ? 0.55 : 1); if (e.t > 0.35) { e.st = 0; e.t = 0; } } }
    else if (e.ai === 'turret') { if (e.t > 2.2) { e.t = 0; const a = Math.atan2(dy, dx); for (const s of [-0.28, 0, 0.28]) A.ebul.push({ x: e.x, y: e.y, vx: Math.cos(a + s) * 155, vy: Math.sin(a + s) * 155, dmg: 9, r: 5, c: '#7aa04a', born: A.t }); } }
    else if (e.ai === 'shooter') { const want = d > 150 ? 1 : d < 110 ? -1 : 0; e.x += dx / d * e.spd * want * dt; e.y += dy / d * e.spd * want * dt; const mu = A.kind === 'mu'; if (e.t > (mu && !e.elite ? 3 : 1.8)) { e.t = 0; if ((!mu || inView(e, -10)) && (!mu || p === A.p)) A.ebul.push({ x: e.x, y: e.y, vx: dx / d * (mu ? 170 : 190), vy: dy / d * (mu ? 170 : 190), dmg: mu ? 6 : 10, r: 5, c: '#d8b040', born: A.t }); } }
    else if (e.ai === 'boss') { const sv = A.kind === 'surv' || A.kind === 'mu';
      if (sv) { if (e.st === 4) { e.x = clamp(e.x + e.tx * 260 * dt, 60, A.WW - 60); e.y = clamp(e.y + e.ty * 260 * dt, 60, A.WH - 60); if (e.t > 0.7) { e.st = 0; e.t = 0; } } else { const want = d > 230 ? 1 : d < 150 ? -0.6 : 0; e.x += dx / d * e.spd * 1.6 * want * dt; e.y += dy / d * e.spd * 1.6 * want * dt; } }
      else { e.x = AW / 2 + Math.sin(A.t * 0.6) * 90; if (e.st === 4) { e.y += e.ty * 260 * dt; e.cx = clamp(e.cx + e.tx * 260 * dt, 50, AW - 50); e.x = e.cx; e.y = clamp(e.y, 60, AH - 80); if (e.t > 0.6 || e.y > AH - 80) { e.st = 0; e.t = 0; } } else e.y += (120 - e.y) * dt; }
      if (e.st !== 4 && e.t > (A.kind === 'mu' ? 1.7 : 2.2)) { e.t = 0; e.phase = (e.phase + 1) % 4; const kind = e.hp < e.max * 0.5 ? e.phase : e.phase % 3;
        if (kind === 0) { const n = e.hp < e.max * 0.5 ? 18 : 14, off = rnd(0, 1); for (let i = 0; i < n; i++) { const a = (i + off) / n * Math.PI * 2; A.ebul.push({ x: e.x, y: e.y, vx: Math.cos(a) * 135, vy: Math.sin(a) * 135, dmg: 11, r: 6, c: '#e8c060', born: A.t }); } A.fx.push({ k: 'ring', x: e.x, y: e.y, t: 0.3, r: 60, c: '#e8c060' }); }
        else if (kind === 1) { for (let b = 0; b < 3; b++) A.later.push({ t: A.t + b * 0.26, fn: () => { if (e.dead) return; const q = aimOf(e), a = Math.atan2(q.y - e.y, q.x - e.x); for (const s of [-0.2, 0, 0.2]) A.ebul.push({ x: e.x, y: e.y, vx: Math.cos(a + s) * 200, vy: Math.sin(a + s) * 200, dmg: 10, r: 5, c: '#d8b040', born: A.t }); } }); }
        else if (kind === 2) { for (let k = 0; k < (A.kind === 'mu' ? 8 : 4); k++) spawn(e.k === 'zj' ? 'ytb' : 'wisp', e.x + rnd(-60, 60), e.y + rnd(20, 60), A.kind === 'mu' ? muMul(A.t) : e.k === 'zj' ? 0.9 : 1.4); banner(e.k === 'zj' ? '장각이 황건 무리를 불러내요!' : '박 속에서 도깨비불이 튀어나와요!', ''); }
        else { e.st = 4; e.t = 0; e.cx = e.x; e.tx = dx / d; e.ty = dy / d; banner(e.k === 'zj' ? '장각이 누런 바람을 타고 달려들어요!' : '도깨비 박이 굴러와요!', ''); } } }
    if (e.ai !== 'boss' && e.ai !== 'turret') pushOut(e);
    if (e.ai === 'chase') { const mv = Math.hypot(e.x - e.ox, e.y - e.oy); if (mv < e.spd * dt * 0.35) { e.stuck = (e.stuck || 0) + dt; if (!e.slide) e.slide = Math.random() < 0.5 ? 1 : -1; if (e.stuck > 1.2) { e.slide = -e.slide; e.stuck = 0.3; } } else if (e.stuck > 0) { e.stuck = Math.max(0, e.stuck - dt * 0.5); if (e.stuck < 0.05) e.slide = 0; } }
    if (Math.hypot(me.x - e.x, me.y - e.y) < e.r + me.r) { A.src = e.k + (e.elite ? '*' : e.boss ? '!' : ''); const iv0 = me.inv; hurtPlayer(e.touch); if (A.map && (e.elite || e.boss) && me.inv > iv0) { const kx = me.x - e.x, ky = me.y - e.y, kd = Math.hypot(kx, ky) || 1; me.x += kx / kd * 34; me.y += ky / kd * 34; pushOut(me); A.fx.push({ k: 'ring', x: me.x, y: me.y, t: 0.25, r: 20, c: '#d9705e' }); } }
  }
  function update(dt) {
    if (!A || A.state !== 'play') return; if (A.hitStop > 0) { A.hitStop -= dt; return; } A.t += dt; const p = A.p; if (!A.later) A.later = [];
    if (A.kind === 'surv') { survTick(dt); if (A.state !== 'play') return; }
    if (A.kind === 'mu') { muTick(dt); if (A.state !== 'play') return; }
    p.inv = Math.max(0, p.inv - dt); A.shake = Math.max(0, A.shake - dt); p.flash = Math.max(0, p.flash - dt);
    const [mx, my] = moveVec(), moving = mx !== 0 || my !== 0; const sp = p.spd * (1 + 0.15 * pw('speed'));
    p.lx = p.x; p.ly = p.y;
    p.dcd = Math.max(0, (p.dcd || 0) - dt); p.dodge = Math.max(0, (p.dodge || 0) - dt);
    const dashing = !!p.dash; if (p.dash) { p.x += p.dash.vx * dt; p.y += p.dash.vy * dt; pushOut(p); p.dash.t -= dt; if (p.dash.t <= 0) p.dash = null; }
    else if (moving) { p.x += mx * sp * dt; p.y += my * sp * dt; p.fx = mx; p.fy = my; pushOut(p); }
    p.vx = (p.x - p.lx) / dt; p.vy = (p.y - p.ly) / dt; p.still = moving || dashing ? 0 : p.still + dt;
    const T0 = tgts(), Wd = WEAP[weapKey(A.weap)]; p.cd -= dt;
    if (A.decoy) { A.decoy.t -= dt; if (A.decoy.t <= 0) A.decoy = null; }
    // 멈추면 낭독(제 힘). 시험용 '걸으며 읽기'를 켜면 움직이는 중에도 약하게(속도 절반 · 피해 60%)
    // 뱀서판(surv)은 늘 읽음(걸어도 제 힘)
    const sv = A.kind === 'surv', walkRead = moving && SV.walkFire && !sv, slowRead = walkRead;
    if (A.kind !== 'mu' && (!moving || walkRead || sv) && !dashing && T0.length && p.cd <= 0) { const vis = T0.filter((e) => los(p, e) && (!sv || Math.hypot(e.x - p.x, e.y - p.y) < 330)), t = nearestOf(vis.length || sv ? vis : T0, p); if (t && (!Wd.range || Math.hypot(t.x - p.x, t.y - p.y) < Wd.range + t.r)) { const fx0 = p.fx, fy0 = p.fy; shootPattern(t, slowRead ? 0.6 : 1); p.cd = 1 / (Wd.rate * (1 + 0.25 * pw('rate')) * (slowRead ? 0.5 : 1)); if (moving) { p.fx = fx0; p.fy = fy0; }
        // 해태 덮치기: 부채가 닿는 거리에서 한 걸음(28px) 들어가며 휘두름 — 무적 없음
        const td = Math.hypot(t.x - p.x, t.y - p.y); if (!moving && A.weap && A.weap.id === 'haetae' && td > 60 && los(p, t)) { const k = Math.min(28, td - 50) / td; p.dash = { t: 0.09, vx: (t.x - p.x) * k / 0.09, vy: (t.y - p.y) * k / 0.09, lunge: true }; A.fx.push({ k: 'ring', x: p.x, y: p.y, t: 0.18, r: 14, c: '#e0b860' }); } } }
    p.counterT = Math.max(0, p.counterT - dt); if (A.foe) A.foe.counterT = Math.max(0, A.foe.counterT - dt);
    A.swapCd = Math.max(0, (A.swapCd || 0) - dt); if (A.sta) for (const id in A.sta) if (!A.pet || id !== A.pet.id) A.sta[id] = Math.min(100, A.sta[id] + 15 * dt);
    if (pw('orbit') && runK()) { A.orbA = (A.orbA || 0) + dt * 3.4; const n = 2 * pw('orbit'); for (let i = 0; i < n; i++) { const a = A.orbA + i / n * Math.PI * 2, ox = p.x + Math.cos(a) * 40, oy = p.y + Math.sin(a) * 40; for (const e of A.en) if (!e.dead && e.orbT <= 0 && Math.hypot(e.x - ox, e.y - oy) < e.r + 8) { e.orbT = 0.45; hurtEnemy(e, p.atk * 0.6, true); } } }
    if (A.pet) petTick(A.pet, dt); if (A.squad) for (const q of A.squad) petTick(q, dt); if (A.ally) { A.ally.t -= dt; petTick(A.ally, dt); if (A.ally.t <= 0) { A.fx.push({ k: 'ring', x: A.ally.x, y: A.ally.y, t: 0.4, r: 24, c: '#7a9ac0' }); A.ally = null; } }
    if (A.foe && A.state === 'play') { foeTick(A.foe, dt); if (A.fpet) petTick(A.fpet, dt); }
    for (const e of A.en) enemyTick(e, dt);
    for (const l of A.later) if (!l.done && A.t >= l.t) { l.done = true; l.fn(); } A.later = A.later.filter((l) => !l.done);
    const steer = (s) => { if (!s.home) return; if (s.home.dead || s.home.hp <= 0) s.home = s.mine === false ? null : nearestOf(tgts(), s); if (s.home) { const a = Math.atan2(s.home.y - s.y, s.home.x - s.x), k = Math.min(1, dt * (s.turn || 8)); s.vx += (Math.cos(a) * s.sp - s.vx) * k; s.vy += (Math.sin(a) * s.sp - s.vy) * k; } };
    // 내 공격
    for (const s of A.shots) { steer(s); s.x += s.vx * dt; s.y += s.vy * dt; s.life = (s.life || 0) + dt;
      if (s.maxLife && s.life > s.maxLife) { s.gone = true; if (s.boom) explode(s, true); continue; }
      if ((A.kind === 'surv' || A.kind === 'mu') && Math.hypot(s.x - p.x, s.y - p.y) > 650) { s.gone = true; continue; }
      const BW = A.WW || AW, BH = A.WH || AH, outB = s.x < 0 || s.y < 0 || s.x > BW || s.y > BH, wallHit = !(s.mine && pw('through') && runK()) && inWall(s.x, s.y, s.r * 0.5);
      if ((outB || wallHit) && s.bnc > 0 && !s.boom) { const px = s.x - s.vx * dt, py = s.y - s.vy * dt; if (outB) { if (s.x < 0 || s.x > BW) s.vx = -s.vx; if (s.y < 0 || s.y > BH) s.vy = -s.vy; } else { if (!inWall(px, s.y, s.r * 0.5)) s.vx = -s.vx; else s.vy = -s.vy; } s.x = px; s.y = py; s.bnc--; s.dmg *= 0.7; s.hit = []; s.life = Math.min(s.life, (s.maxLife || 9) * 0.5); A.fx.push({ k: 'puff', x: s.x, y: s.y, t: 0.15 }); continue; }
      if (outB || wallHit) { s.gone = true; if (s.boom) explode(s, true); else if (s.x > 0 && s.x < BW) A.fx.push({ k: 'puff', x: s.x, y: s.y, t: 0.2 }); continue; }
      for (const e of tgts()) { if (s.hit.includes(e)) continue; if (Math.hypot(e.x - s.x, e.y - s.y) < e.r + s.r + (s.boom ? 20 : 0)) { if (e.side === 'foe' && !s.boom && shieldBlock(e, s, false)) { s.gone = true; break; } if (s.boom) { s.gone = true; explode(s, true); break; } hurtTarget(e, s.dmg); onHitFx(s, e); s.hit.push(e); if (s.pierce > 0) s.pierce--; else { s.gone = true; break; } } } if (A.state !== 'play') break; }
    A.shots = A.shots.filter((s) => !s.gone);
    // 나를 노리는 것
    for (const b of A.ebul) { steer(b); b.x += b.vx * dt; b.y += b.vy * dt; b.life = (b.life || 0) + dt;
      if ((b.home && b.life > 2.2) || (b.maxLife && b.life > b.maxLife)) { b.gone = true; if (b.boom) explode(b, false); continue; }
      if (b.x < -10 || b.y < -10 || b.x > (A.WW || AW) + 10 || b.y > (A.WH || AH) + 10 || ((A.kind === 'surv' || A.kind === 'mu') && Math.hypot(b.x - p.x, b.y - p.y) > 700)) { b.gone = true; continue; }
      if (inWall(b.x, b.y, b.r * 0.5)) { b.gone = true; if (b.boom) explode(b, false); else A.fx.push({ k: 'puff', x: b.x, y: b.y, t: 0.2 }); continue; }
      if (Math.hypot(b.x - p.x, b.y - p.y) < b.r + p.r - 2 + (b.boom ? 20 : 0)) { b.gone = true; if (!b.boom && shieldBlock(p, b, true)) continue; if (b.boom) explode(b, false); else { A.src = 'bullet'; hurtPlayer(b.dmg); } } }
    A.ebul = A.ebul.filter((b) => !b.gone); A.en = A.en.filter((e) => !e.dead);
    for (const f of A.fx) f.t -= dt; A.fx = A.fx.filter((f) => f.t > 0);
    if (A.state !== 'play') { hudUpdate(); return; }
    if (A.kind !== 'duel' && A.kind !== 'surv' && A.kind !== 'mu' && !A.en.length && !A.cleared) roomClear();
    if (A.doors) for (const dr of A.doors) if (p.x > dr.x && p.x < dr.x + dr.w && p.y < dr.y + dr.h + p.r) { takeDoor(dr); break; }
    hudUpdate();
  }
  function roomClear() { A.cleared = true; A.ebul = [];
    if (A.kind === 'wild') return wildWin();
    if (A.kind === 'story') return storyFightEnd(true);
    const P = PAGES[A.pi]; if (P.boss) return endRun();
    const open = () => { const ds = P.doors || [{ l: '다음 장으로', g: null }], n = ds.length, w = n === 1 ? 90 : n === 2 ? 120 : 96, gap = (AW - n * w) / (n + 1); A.doors = ds.map((d, i) => ({ ...d, x: gap + i * (w + gap), y: 6, w, h: 30 })); banner(P.doors ? '갈림길 — 고른 길이 결말을 바꿔요' : '책장이 넘어가요', P.doors ? '문으로 걸어 들어가세요' : '위쪽 문으로'); };
    if (P.pow) pickPower(open); else open(); }
  function takeDoor(dr) { if (dr.g) for (const k in dr.g) A.lean[k] += dr.g[k]; A.doors = null; if (dr.g) A.fx.push({ k: 'num', x: AW / 2, y: 60, t: 1.2, v: dr.l, c: '#e2b85a' }); enterPage(A.pi + 1); }

  // ═════════ 삼국지연의 「황건적 토벌」 뱀서판(D-162): 걸으며 자동 낭독 · 먹물 든 황건적 · 레벨업마다 힘 또는 장수 합류 · 도원결의 진화 · 정원지 일기토 · 장각 ═════════
  const OATH = ['liubei', 'guanyu', 'zhangfei'];
  const RECRUIT = ['liubei', 'guanyu', 'zhangfei', 'zhuge'];
  const SURV = { len: 480, W: 1600, H: 1600, book: '삼국지연의 「황건적 토벌」', scenes: [
    { t: 0, n: '탁현 들판', mix: [['ytb', 6], ['ytcav', 1]], rate: 0.8, grow: 0.6 },
    { t: 120, n: '황건 진영', mix: [['ytb', 4], ['ytarch', 2], ['ytcav', 2]], rate: 1.3, grow: 0.7 },
    { t: 240, n: '대흥산', mix: [['ytb', 4], ['ytarch', 2], ['ytbig', 1], ['ytcav', 1]], rate: 1.8, grow: 0.8 },
    { t: 360, n: '광종성', mix: [['ytb', 4], ['ytarch', 2], ['ytbig', 2], ['ytcav', 2]], rate: 2.3, grow: 0.9 } ],
    events: [{ t: 110, id: 'village' }, { t: 245, id: 'duel' }, { t: 350, id: 'fog' }] };
  const sceneAt = (t) => { let s = SURV.scenes[0]; for (const q of SURV.scenes) if (t >= q.t) s = q; return s; };
  const xpNeedS = (l) => 3 + 3 * l;
  const fmtT = (t) => `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, '0')}`;
  function wpick(mix) { let tot = 0; for (const [, w] of mix) tot += w; let r = Math.random() * tot; for (const [k, w] of mix) { r -= w; if (r <= 0) return k; } return mix[0][0]; }
  function ringPos() { const p = A.p; for (let i = 0; i < 12; i++) { const a = rnd(0, Math.PI * 2), r = Math.hypot(AW, A.VH) / 2 + rnd(20, 70), x = clamp(p.x + Math.cos(a) * r, 24, A.WW - 24), y = clamp(p.y + Math.sin(a) * r, 24, A.WH - 24); if (!hitObs(x, y, 16) && Math.hypot(x - p.x, y - p.y) > 200) return [x, y]; } return [clamp(p.x + 300, 24, A.WW - 24), p.y]; }
  function startSurv() {
    baseArena('surv'); A.WW = SURV.W; A.WH = SURV.H; A.VH = 600; A.p.x = SURV.W / 2; A.p.y = SURV.H / 2; if (A.pet) { A.pet.x = A.p.x + 20; A.pet.y = A.p.y + 16; }
    if (A.pet) A.pet.noSta = true; // 뱀서판: 장수는 지치지 않음
    A.gems = []; A.lvl = 1; A.xp = 0; A.lvlQ = 0; A.spawnAcc = 0; A.sceneI = -1; A.evDone = {}; A.bossOn = false; A.swarmT = 60; A.ally = null; A.calm = 0; SV.runs++; saveSV();
    A.obs = []; let tries = 0; while (A.obs.length < 12 && tries++ < 80) { const w = rnd(50, 110), h = rnd(26, 44), o = { x: rnd(80, SURV.W - 80 - w), y: rnd(80, SURV.H - 80 - h), w, h, k: 'wall' }; if (Math.hypot(o.x + w / 2 - A.p.x, o.y + h / 2 - A.p.y) < 180 || A.obs.some((q) => o.x < q.x + q.w + 60 && o.x + o.w + 60 > q.x && o.y < q.y + q.h + 60 && o.y + o.h + 60 > q.y)) continue; A.obs.push(o); }
    CAMX = A.p.x - AW / 2; CAMY = A.p.y - A.VH / 2; hudUpdate(); banner(SURV.book, '걸어도 글자가 날아가요 · 8분 버티면 장각');
  }
  function recruit(id) { if (!A || (A.pet && A.pet.id === id) || A.squad.some((q) => q.id === id)) return; const lv = SV.pets[id] ? SV.pets[id].lvl : 1; const q = Object.assign(mkPet(id, lv, A.p), { noSta: true, slot: A.squad.length + 1 }); q.x = A.p.x; q.y = A.p.y; A.squad.push(q); sfx('accept', 0.45); A.fx.push({ k: 'ring', x: A.p.x, y: A.p.y, t: 0.5, r: 40, c: PETS[id].c }); banner(`${PETS[id].n} 합류!`, PETS[id].d); checkOath(); }
  function checkOath() { if (A.oath) return; const ids = [A.pet && A.pet.id, ...A.squad.map((q) => q.id)]; if (OATH.every((i) => ids.includes(i))) { A.oath = true; heal(A.p, A.p.max); sfx('win', 0.4); for (let i = 0; i < 3; i++) A.fx.push({ k: 'ring', x: A.p.x, y: A.p.y, t: 0.6 + i * 0.15, r: 60 + i * 30, c: '#f0a0b8' }); banner('도원결의!', '세 형제의 공격이 크게 세지고 더 자주 나와요'); } }
  function gainXP(v) { A.xp += v; while (A.xp >= xpNeedS(A.lvl)) { A.xp -= xpNeedS(A.lvl); A.lvl++; A.lvlQ++; } }
  function survTick(dt) {
    const p = A.p, t = A.t, S = sceneAt(t), si = SURV.scenes.indexOf(S);
    if (si !== A.sceneI) { A.sceneI = si; banner(`${si + 1}장면 · ${S.n}`, si === 0 ? '걸으며 읽어요 · 글자 조각을 주워 힘을 골라요' : '먹물이 더 짙어져요'); }
    for (const ev of SURV.events) if (t >= ev.t && !A.evDone[ev.id]) { A.evDone[ev.id] = true; return survEvent(ev.id); }
    if (t >= SURV.len && !A.bossOn) { A.bossOn = true; const [x, y] = ringPos(); spawn('zj', x, y, 1.0); banner('천공장군 장각!', '마지막 장면 — 장각의 먹물을 씻어 내요'); sfx('alert', 0.5); }
    A.calm = Math.max(0, A.calm - dt);
    const local = Math.min(1, (t - S.t) / 120), rate = (S.rate + S.grow * local) * 1.3 * (A.bossOn ? 0.35 : 1) * (A.calm > 0 ? 0 : 1), mul = 0.5 * (1 + t / 100 * 0.8); A.spawnAcc += rate * dt;
    while (A.spawnAcc >= 1) { A.spawnAcc -= 1; if (A.en.length >= 140) continue; const [x, y] = ringPos(); spawn(wpick(S.mix), x, y, mul); }
    A.swarmT -= dt; if (A.swarmT <= 0 && !A.bossOn && A.calm <= 0) { A.swarmT = 60; const n = 10 + Math.floor(t / 60) * 2; for (let i = 0; i < n; i++) { const a = i / n * Math.PI * 2, x = clamp(p.x + Math.cos(a) * 280, 24, A.WW - 24), y = clamp(p.y + Math.sin(a) * 280, 24, A.WH - 24); if (!hitObs(x, y, 12)) spawn('ytb', x, y, mul * 0.8); } banner('황건 무리가 에워싸요!', '틈을 찾아 빠져나가요'); }
    for (const e of A.en) { const d = Math.hypot(e.x - p.x, e.y - p.y); if (e.ai === 'turret') { if (d > 900) e.dead = true; } else if (e.ai !== 'boss' && e.k !== 'cyz' && d > 760) { const [x, y] = ringPos(); e.x = x; e.y = y; } }
    // 겹치지 않게 살짝 밀기(칸 나눔)
    const cell = 30, G = new Map(); for (const e of A.en) { const k = ((e.x / cell) | 0) * 4096 + ((e.y / cell) | 0); let l = G.get(k); if (!l) G.set(k, (l = [])); l.push(e); }
    for (const e of A.en) { if (e.ai === 'boss' || e.ai === 'turret') continue; const cx = (e.x / cell) | 0, cy = (e.y / cell) | 0; for (let i = -1; i <= 1; i++) for (let j = -1; j <= 1; j++) { const l = G.get((cx + i) * 4096 + cy + j); if (!l) continue; for (const o of l) { if (o === e) continue; const dx = e.x - o.x, dy = e.y - o.y, d = Math.hypot(dx, dy), m = (e.r + o.r) * 0.85; if (d > 0.01 && d < m) { const k = (m - d) * 0.25 / d; e.x += dx * k; e.y += dy * k; } } } }
    // 글자 조각 줍기
    const mag = 72 + 40 * pw('magnet');
    for (const g of A.gems) { const d = Math.hypot(g.x - p.x, g.y - p.y); if (g.pull || d < mag) { g.pull = true; const k = Math.min(1, dt * 10); g.x += (p.x - g.x) * k; g.y += (p.y - g.y) * k; } if (d < p.r + 8) { g.got = true; if (g.heal) { heal(p, 22); sfx('heal', 0.3); } else gainXP(g.v); } }
    A.gems = A.gems.filter((g) => !g.got);
    CAMX = clamp(p.x - AW / 2, 0, A.WW - AW); CAMY = clamp(p.y - A.VH / 2, 0, A.WH - A.VH);
    if (A.lvlQ > 0) { A.lvlQ--; sfx('accept', 0.35); pickPower(() => {}); }
  }
  // 적군 사기가 무너짐: 화면 안 황건이 모두 씻겨 돌아가고 잠깐 조용해짐
  function routEnemies(sec) { for (const e of A.en) if (!e.dead && e.ai !== 'boss' && Math.hypot(e.x - A.p.x, e.y - A.p.y) < 420) { e.dead = true; A.kills++; revertFx(e); A.gems.push({ x: e.x, y: e.y, v: 1 }); } A.calm = sec; }
  function survEvent(id) {
    A.state = 'pick'; joy.on = false; const p = A.p;
    const missing = RECRUIT.filter((r) => !(A.pet && A.pet.id === r) && !A.squad.some((q) => q.id === r));
    const E = id === 'village' ? { h: '갈림길 · 불타는 마을', lead: '황건적이 마을에 불을 질렀어요. 백성들이 우왕좌왕해요.', o: [
      { l: '백성부터 구한다', d: '체력을 모두 회복 · 인 +2', fn: () => { A.lean.kind += 2; heal(p, p.max); } },
      { l: '의병을 모은다', d: missing.length ? `장수 하나가 합류해요 · 인 +1` : '모두 모였어요 — 공격 +15% · 인 +1', fn: () => { A.lean.kind += 1; if (missing.length && A.squad.length < 3) recruit(pick(missing)); else A.atkBonus = (A.atkBonus || 0) + 0.15; } },
      { l: '황건 군량을 빼앗는다', d: '이번 판 공격 +30% · 공 +2', fn: () => { A.lean.greed += 2; A.atkBonus = (A.atkBonus || 0) + 0.3; } } ] }
      : id === 'duel' ? { h: '정원지가 일기토를 청해요', lead: '황건 장수 정원지가 무리 앞으로 나와 외쳐요. "나와 겨룰 자 없느냐!"', o: [
      { l: '일기토를 받는다(줄다리기)', d: '이기면 적군 사기가 무너져 화면의 황건이 흩어지고 잠시 조용해져요 · 용 +2', fn: () => survDuel() },
      { l: '무리째 상대한다', d: '정원지가 강한 적으로 싸움판에 나와요 · 공 +1', fn: () => { A.lean.greed += 1; const [x, y] = ringPos(); spawn('cyz', x, y, 1.0); banner('정원지가 달려들어요!', '쓰러뜨리면 큰 글자 조각'); } } ] }
      : { h: '갈림길 · 누런 안개', lead: '장각이 하늘에 빌자 누런 안개가 깔려요. 광종성이 코앞이에요.', o: [
      { l: '안개 속 백성을 이끌고 빠져나간다', d: '체력 50% 회복 · 인 +2', fn: () => { A.lean.kind += 2; heal(p, p.max * 0.5); } },
      { l: '안개를 뚫고 돌격한다', d: '이동 +20% · 공격 +15% · 용 +2', fn: () => { A.lean.swift += 2; p.spd *= 1.2; A.atkBonus = (A.atkBonus || 0) + 0.15; } },
      { l: '장각의 군량고를 턴다', d: '공격 +30% · 공 +2', fn: () => { A.lean.greed += 2; A.atkBonus = (A.atkBonus || 0) + 0.3; } } ] };
    sfx('alert', 0.35);
    card(`<h2>${E.h}</h2><p class="lead">${E.lead}</p><p>고른 길이 결말을 바꿔요.</p>${E.o.map((o, i) => `<button class="opt" type="button" data-ev="${i}" style="grid-template-columns:1fr"><b>${o.l}</b><span>${o.d}</span></button>`).join('')}`, (c) => c.querySelectorAll('[data-ev]').forEach((b) => b.onclick = () => { closeCard(); E.o[+b.dataset.ev].fn(); if (A && A.state === 'pick') { A.state = 'play'; last = performance.now(); } hudUpdate(); }));
  }
  // 판 중간 일기토: 싸움판은 멈춰 두고 줄다리기로 → 끝나면 돌아옴
  function survDuel() { A.state = 'duel'; D = { foe: 'cyz', round: 1, wins: { me: 0, foe: 0 }, fi: 0, myPet: A.pet ? A.pet.id : null, bo: 1, need: 1, inRun: true }; talk(FOES.cyz.n, FOES.cyz.hi, () => startRope()); }
  function ropeBackToRun(winner) {
    D = null; setMode('arena'); music('fight'); $('act').hidden = true; $('hpw').style.display = ''; A.state = 'play'; last = performance.now();
    if (winner === 'me') { A.lean.swift += 2; routEnemies(12); A.gems.push({ x: A.p.x + 20, y: A.p.y, v: 20 }); banner('일기토 승리!', '황건 무리가 흩어졌어요 — 잠시 조용해요'); }
    else { A.p.hp = Math.max(1, A.p.hp - A.p.max * 0.25); const [x, y] = ringPos(); spawn('cyz', x, y, 0.8); banner('일기토에서 밀렸어요', '정원지가 싸움판에 나와요'); }
    hudUpdate();
  }
