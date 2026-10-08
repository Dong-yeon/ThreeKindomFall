  // ═════════ 북 대결 = 이야기 줄다리기 (D-160) ═════════
  // 체력 대신 줄 하나. 매 턴 둘이 동시에 세 수 중 하나 — 읽기는 모으기를, 막기는 읽기를, 모으기는 막기를 이김(상성은 수끼리).
  // 소환수는 기술 4개 대신 고유 기술 하나로 규칙을 비틈. 상대 기색(두 수 중 하나로 좁혀 줌)은 성격에 따라 거짓일 수 있음.
  const RL = 7; // 줄 끝(이 칸까지 끌어오면 이김)
  const RMAX = 14; // 이 수가 지나면 줄이 기운 쪽이 이김
  const MV = { read: { n: '읽기', g: '읽', c: '#b8432f', d: '모으기를 이겨요' }, guard: { n: '막기', g: '막', c: '#a8823a', d: '읽기를 되받아쳐요' }, charge: { n: '모으기', g: '모', c: '#4a6a9a', d: '막기를 헛수로 · 기운 +' }, swap: { n: '교대', g: '교', c: '#7a6a5a', d: '' } };
  const MS = ['read', 'guard', 'charge'];
  const SIG = { blade: '청룡언월도 — 읽기가 1칸 더 세요', zhangfei: '장판교 고함 — 막기에 성공하면 크게 되받아쳐요(되받아침 +1)', zhuge: '읽어 내기(한 판 2번) — 상대 기색이 진짜인지 봐요', liubei: '인덕 — 밀릴 때 1칸 덜 밀려요', ytsoldier: '무리 — 기운을 5까지 쌓고, 모을 때 +1 더', haetae: '막기에 성공하면 크게 되받아쳐요(되받아침 +1)', gumiho: '여우 눈(한 판 2번) — 상대 기색이 진짜인지 봐요', heung: '밀릴 때 1칸 덜 밀려요', nolbu: '기운을 5까지 쌓고, 모을 때 +1 더', swallow: '같은 수를 내면 내 쪽으로 1칸' };
  const BK = { haetae: 'counter', heung: 'guard', nolbu: 'greed', swallow: 'wing', gumiho: 'decoy', zhangfei: 'counter', zhuge: 'decoy', liubei: 'guard', guanyu: 'greed' };
  const BSIG = { counter: '해태 책갈피 — 되받아침 +1', guard: '흥부 책갈피 — 한 판에 한 번 밀림을 막아요', greed: '놀부 책갈피 — 기운 1을 들고 시작', wing: '제비 책갈피 — 교대해도 수를 안 써요', decoy: '구미호 책갈피 — 한 판에 한 번 둔갑: 상대가 수를 아무렇게나 다시 골라요' };
  const TELL = { guard: ['몸을 앞으로 기울여요', '읽기 · 모으기 중 하나?'], read: ['책장에서 손을 떼요', '막기 · 모으기 중 하나?'], charge: ['숨을 짧게 몰아쉬어요', '읽기 · 막기 중 하나?'] };
  // 상대 성격: honest = 기색이 맞을 확률, learn = 내 버릇을 읽는 정도, temp = 낮을수록 계산대로, rand = 아무 수나 낼 확률
  const ROPE_AI = {
    reader1: { honest: 0.92, learn: 0.1, temp: 1.3, rand: 0.3, desc: '솔직해요 — 기색이 거의 맞아요' },
    reader2: { honest: 0.78, learn: 0.25, temp: 0.9, rand: 0.2, bias: { charge: 0.35 }, desc: '기운 모으기를 좋아해요' },
    reader3: { honest: 0.7, learn: 0.35, temp: 0.7, rand: 0.15, bias: { read: 0.25 }, desc: '읽기를 좋아해요 · 가끔 기색으로 속여요' },
    cyz: { honest: 0.8, learn: 0.2, temp: 1.0, rand: 0.22, bias: { charge: 0.2 }, desc: '거칠고 솔직해요 — 기운을 모아 한 방을 노려요' },
    keeper1: { honest: 0.55, learn: 0.45, temp: 0.55, rand: 0.08, desc: '기색으로 자주 속이고, 내 버릇을 읽어요' },
  };
  const lvB = (l) => (l >= 6 ? 2 : l >= 3 ? 1 : 0);
  const sg = (id) => (id && PETS[id] && PETS[id].beh) || id; // 같은 행동 틀(장비 = 해태, 제갈량 = 구미호, 유비 = 흥부 …)
  const sigOf = (id) => SIG[id] || SIG[sg(id)] || '';
  let RP = null;
  function ropeSide(pet, lvl, body) { return { pet, lvl, body, ki: body === 'greed' ? 1 : 0, kiMax: sg(pet) === 'nolbu' ? 5 : 3, guardUsed: false, decoyUsed: false, eyes: 2 }; }
  function startRope() {
    const F = FOES[D.foe], fp = F.pets[D.fi % F.pets.length], my = D.myPet && SV.pets[D.myPet] ? D.myPet : null;
    RP = { a: ropeSide(my, my ? SV.pets[my].lvl : 1, SV.load.b1 ? BK[SV.load.b1] : null), b: ropeSide(fp.id, fp.lvl, F.body && F.body[0] ? BK[F.body[0].id] : null), R: 0, shownR: 0, turn: 1, st: 'choose', t: 0, hist: [], fm: null, tell: null, note: '', rev: null };
    setMode('rope'); music('fight'); joy.on = false; inputLock = false; $('hud').hidden = false; $('hpw').style.display = 'none'; $('talk').hidden = true;
    ropeAI(); ropeUI(); hudUpdate();
    if (!SV.tutRope) { SV.tutRope = true; saveSV(); ropeHelp(); }
  }
  function ropeHelp() {
    RP.st = RP.st === 'choose' ? 'help' : RP.st;
    card(`<h2>이야기 줄다리기</h2><p class="lead">체력 대신 줄 하나. 줄을 <b>내 쪽 끝</b>까지 끌어오면 이겨요.</p><p>매 턴 둘이 <b>동시에</b> 하나를 골라요.</p><div class="rps"><div><b style="color:${MV.read.c}">읽기</b> → 모으기를 이겨요(2칸 + 기운만큼)</div><div><b style="color:${MV.guard.c}">막기</b> → 읽기를 되받아쳐요(2칸)</div><div><b style="color:${MV.charge.c}">모으기</b> → 막기를 헛수로 만들어요(기운 +2 · 1칸)</div></div><p><b>기색</b>: 상대 몸짓이 두 수 중 하나로 좁혀 줘요. 성격에 따라 거짓일 때도 있어요. 상대 <b>기운</b>이 많으면 큰 읽기가 올지도!</p><p>소환수마다 <b>고유 기술</b>이 하나씩 있어요. 교대도 한 수예요.</p><button class="go" type="button" id="ok">알겠어요</button>`, (c) => { c.querySelector('#ok').onclick = () => { closeCard(); if (RP.st === 'help') RP.st = 'choose'; ropeUI(); }; });
  }
  // 한 수 풀기(바꾸지 않음): ma = 나, mb = 상대 → d(+면 내 쪽으로), 새 기운, 설명
  function ropeResolve(ma, mb) {
    const a = RP.a, b = RP.b; let d = 0, ka = a.ki, kb = b.ki, txt = '';
    const P = (s) => 2 + s.ki + lvB(s.lvl) + (sg(s.pet) === 'blade' ? 1 : 0), refl = (s) => 2 + (sg(s.pet) === 'haetae' ? (s.lvl >= 3 ? 2 : 1) : 0) + (s.body === 'counter' ? 1 : 0), gain = (s, n) => Math.min(s.kiMax, s.ki + n + (sg(s.pet) === 'nolbu' ? 1 : 0));
    const A = ma === 'swap' ? 'none' : ma, B = mb === 'swap' ? 'none' : mb;
    if (A === 'read' && B === 'read') { const pa = P(a), pb = P(b); d = pa - pb; ka = 0; kb = 0; txt = `맞읽기! 힘 ${pa} : ${pb}`; }
    else if (A === 'read' && B === 'charge') { d = P(a); ka = 0; txt = `읽기가 모으기를 끊었어요 · ${P(a)}칸`; }
    else if (A === 'read' && B === 'guard') { d = -refl(b); ka = 0; txt = `상대가 막고 되받아쳤어요 · ${refl(b)}칸`; }
    else if (A === 'guard' && B === 'read') { d = refl(a); kb = 0; txt = `막고 되받아쳤어요 · ${refl(a)}칸`; }
    else if (A === 'charge' && B === 'read') { d = -P(b); kb = 0; txt = `모으다 읽기에 끊겼어요 · ${P(b)}칸`; }
    else if (A === 'guard' && B === 'charge') { kb = gain(b, 2); d = -1; txt = '막기가 헛수! 상대 기운 +2 · 1칸'; }
    else if (A === 'charge' && B === 'guard') { ka = gain(a, 2); d = 1; txt = '상대 막기가 헛수! 기운 +2 · 1칸'; }
    else if (A === 'charge' && B === 'charge') { ka = gain(a, 1); kb = gain(b, 1); txt = '둘 다 기운을 모아요'; }
    else if (A === 'guard' && B === 'guard') { txt = '서로 노려봐요'; }
    else if (A === 'none' && B === 'read') { d = -P(b); kb = 0; txt = `교대하는 틈에 읽혔어요 · ${P(b)}칸`; }
    else if (A === 'none' && B === 'charge') { kb = gain(b, 1); txt = '교대하는 동안 상대가 기운을 모아요'; }
    else if (B === 'none' && A === 'read') { d = P(a); ka = 0; txt = `상대가 교대하는 틈에 읽었어요 · ${P(a)}칸`; }
    else if (B === 'none' && A === 'charge') { ka = gain(a, 1); txt = '상대가 교대하는 동안 기운을 모아요'; }
    else txt = '숨을 고르며 서로를 봐요';
    if (A === B && A !== 'none') { if (sg(a.pet) === 'swallow' && sg(b.pet) !== 'swallow') { d += 1; txt += ' · 제비가 1칸 당겨요'; } else if (sg(b.pet) === 'swallow' && sg(a.pet) !== 'swallow') { d -= 1; txt += ' · 상대 제비가 1칸 당겨요'; } }
    if (d < 0 && sg(a.pet) === 'heung' && d < -1) { d += 1; txt += ' · 흥부가 버텨요'; } if (d > 0 && sg(b.pet) === 'heung' && d > 1) { d -= 1; txt += ' · 상대 흥부가 버텨요'; }
    return { d, ka, kb, txt };
  }
  // 상대의 수 정하기 + 기색
  function ropeAI() {
    const C = ROPE_AI[D.foe] || ROPE_AI.reader1, a = RP.a, b = RP.b;
    const p = { read: 1, guard: 1, charge: 1 };
    if (a.ki >= 2) p.read += 0.8; if (a.ki === 0) { p.read -= 0.35; p.charge += 0.45; } if (a.ki >= a.kiMax) p.charge -= 0.7;
    if (b.ki >= 2) p.guard += 0.6; if (RP.R <= -RL + 3) p.read += 0.4; if (RP.R >= RL - 3) p.guard += 0.3;
    let tp = 0; for (const m of MS) { p[m] = Math.max(0.05, p[m]); tp += p[m]; } for (const m of MS) p[m] /= tp;
    const H = RP.hist.slice(-8).filter((h) => h.me !== 'swap');
    if (H.length >= 2 && C.learn) { const cnt = { read: 0.3, guard: 0.3, charge: 0.3 }; H.forEach((h, i) => { cnt[h.me] += 0.6 + i * 0.12; }); cnt[H[H.length - 1].me] += 0.4; const tc = cnt.read + cnt.guard + cnt.charge; for (const m of MS) p[m] = (1 - C.learn) * p[m] + C.learn * cnt[m] / tc; }
    const ev = {}; for (const m of MS) { let e = 0; for (const x of MS) { const r = ropeResolve(x, m); let v = -r.d + 0.45 * (r.kb - b.ki) - 0.4 * (r.ka - a.ki); if (RP.R + r.d <= -RL) v += 6; if (RP.R + r.d >= RL) v -= 6; e += p[x] * v; } ev[m] = e + ((C.bias && C.bias[m]) || 0); }
    let mv = MS[0]; if (Math.random() < C.rand) mv = pick(MS); else { const mx = Math.max(...MS.map((m) => ev[m])), w = MS.map((m) => Math.exp((ev[m] - mx) / C.temp)); let r = Math.random() * w.reduce((s, v) => s + v, 0); for (let i = 0; i < 3; i++) { r -= w[i]; if (r <= 0) { mv = MS[i]; break; } } }
    RP.fm = mv; const honest = Math.random() < C.honest; RP.tell = honest ? pick(MS.filter((m) => m !== mv)) : mv; RP.tellTrue = honest; RP.note = ''; RP.eye = false;
  }
  function ropeChoose(m) {
    if (!RP || RP.st !== 'choose' || !$('ov').hidden) return;
    if (m === 'swap') return ropeSwapCard();
    ropeTurn(m);
  }
  function ropeSwapTo(id) { const a = RP.a; a.pet = id; a.lvl = SV.pets[id].lvl; a.kiMax = sg(id) === 'nolbu' ? 5 : 3; a.ki = Math.min(a.ki, a.kiMax); D.myPet = id; }
  function ropeSwapCard() {
    const c0 = SV.party.filter((id) => SV.pets[id] && id !== SV.load.b1 && id !== RP.a.pet); if (!c0.length) return;
    const free = RP.a.body === 'wing';
    card(`<h2>교대</h2><p>${free ? '제비 책갈피 — 교대해도 수를 안 써요.' : '교대도 한 수예요. 그 틈에 상대가 읽으면 밀려요.'}</p>${c0.map((id) => `<button class="opt" type="button" data-sw="${id}">${petIcon(id)}<b>${PETS[id].n} · ${SV.pets[id].lvl}단계</b><span>${sigOf(id)}</span></button>`).join('')}<button class="sub" type="button" id="no">그만두기</button>`, (c) => {
      c.querySelectorAll('[data-sw]').forEach((b) => b.onclick = () => { closeCard(); const id = b.dataset.sw; if (free) { ropeSwapTo(id); sfx('accept', 0.3); banner(`교대 — ${PETS[id].n}`, sigOf(id)); ropeUI(); hudUpdate(); } else ropeTurn('swap', id); });
      c.querySelector('#no').onclick = closeCard; });
  }
  function ropeDecoy() { const a = RP.a; if (!RP || RP.st !== 'choose' || a.body !== 'decoy' || a.decoyUsed) return; a.decoyUsed = true; RP.fm = pick(MS); RP.tell = null; RP.note = '여우에 홀려 상대가 수를 아무렇게나 다시 골랐어요'; sfx('accept', 0.4); ropeUI(); }
  function ropeEye() { const a = RP.a; if (!RP || RP.st !== 'choose' || a.pet !== 'gumiho' || a.eyes <= 0 || RP.eye || !RP.tell) return; a.eyes--; RP.eye = true; sfx('accept', 0.35); ropeUI(); }
  function ropeTurn(m, swapTo) {
    if (swapTo) ropeSwapTo(swapTo);
    const r = ropeResolve(m, RP.fm);
    if (r.d < 0 && RP.a.body === 'guard' && !RP.a.guardUsed) { RP.a.guardUsed = true; r.d = 0; r.txt += ' · 박의 보살핌이 막았어요'; }
    if (r.d > 0 && RP.b.body === 'guard' && !RP.b.guardUsed) { RP.b.guardUsed = true; r.d = 0; r.txt += ' · 상대 박의 보살핌이 막았어요'; }
    RP.a.ki = r.ka; RP.b.ki = r.kb; RP.R = clamp(RP.R + r.d, -RL, RL); RP.hist.push({ me: m, foe: RP.fm, d: r.d }); RP.rev = { me: m, foe: RP.fm, r, swap: swapTo }; RP.st = 'reveal'; RP.t = 0;
    sfx(r.d > 0 ? 'hit' : r.d < 0 ? 'hurt' : 'shoot', 0.35); ropeUI(); hudUpdate();
  }
  function ropeUpdate(dt) {
    if (!RP) return; RP.shownR += (RP.R - RP.shownR) * Math.min(1, dt * (RP.st === 'reveal' && RP.t < 0.4 ? 0 : 6));
    if (RP.st !== 'reveal') return; RP.t += dt;
    if (RP.t > 1.6) { const over = Math.abs(RP.R) >= RL || (RP.turn >= RMAX && RP.R !== 0); if (over) { RP.st = 'end'; return ropeRoundEnd(RP.R > 0 ? 'me' : 'foe'); } RP.turn++; ropeAI(); RP.st = 'choose'; ropeUI(); hudUpdate(); }
  }
  function ropeRoundEnd(winner) {
    sfx(winner === 'me' ? 'win' : 'lose', 0.35); D.wins[winner]++; const v = winner === 'me' ? 18 : 8; let xp = RP.a.pet ? petXPLine(RP.a.pet, v) : ''; if (SV.load.b1 && SV.load.b1 !== RP.a.pet) xp += petXPLine(SV.load.b1, Math.ceil(v / 2)); saveSV();
    const over = D.wins.me >= D.need || D.wins.foe >= D.need;
    if (D.inRun) return setTimeout(() => card(`<h2>일기토 — ${winner === 'me' ? '이겼어요!' : '밀렸어요'}</h2><p class="lead">${winner === 'me' ? FOES[D.foe].lose[0] : FOES[D.foe].win[0]}</p><div class="stats"><span>몇 수</span><b>${RP.turn}수</b>${xp}</div><button class="go" type="button" id="back">싸움판으로</button>`, (c) => { c.querySelector('#back').onclick = () => { closeCard(); ropeBackToRun(winner); }; }), 500);
    setTimeout(() => { if (over) { $('act').hidden = true; return duelEnd(); } card(`<h2>${D.round}판 — ${winner === 'me' ? '이겼어요!' : '졌어요'}</h2><div class="pips"><span>나 ${D.wins.me} : ${D.wins.foe} 상대</span></div><div class="stats"><span>몇 수</span><b>${RP.turn}수</b>${xp}</div><button class="go" type="button" id="next">다음 판</button>`, (c) => { c.querySelector('#next').onclick = () => { D.round++; D.fi++; duelPick(); }; }); }, 500);
  }
  // ── 아래 버튼(엄지 자리)
  function ropeUI() {
    const el = $('act'); if (!RP || MODE !== 'rope') { el.hidden = true; return; } el.hidden = false; const on = RP.st === 'choose', a = RP.a;
    const sw = SV.party.some((id) => SV.pets[id] && id !== SV.load.b1 && id !== a.pet), dec = a.body === 'decoy' && !a.decoyUsed;
    el.innerHTML = `<div class="row3">${MS.map((m, i) => `<button type="button" data-mv="${m}" ${on ? '' : 'disabled'} style="--c:${MV[m].c}"><i>${MV[m].g}</i><b>${MV[m].n}</b><small>${m === 'read' ? `${2 + a.ki + lvB(a.lvl)}칸 · ` : ''}${MV[m].d}</small><kbd>${i + 1}</kbd></button>`).join('')}</div><div class="row2"><button type="button" id="mvSwap" ${on && sw ? '' : 'disabled'}>교대${a.body === 'wing' ? '(무료)' : ''}</button>${sg(a.pet) === 'gumiho' ? `<button type="button" id="mvEye" ${on && a.eyes > 0 && !RP.eye && RP.tell ? '' : 'disabled'}>${a.pet === 'gumiho' ? '여우 눈' : '읽어 내기'}(${a.eyes})</button>` : ''}${dec ? `<button type="button" id="mvDecoy" ${on ? '' : 'disabled'}>둔갑(한 번)</button>` : ''}<button type="button" id="mvHelp">규칙</button></div>`;
    el.querySelectorAll('[data-mv]').forEach((b) => b.onclick = () => ropeChoose(b.dataset.mv));
    const s = el.querySelector('#mvSwap'); if (s) s.onclick = () => ropeChoose('swap'); const dc = el.querySelector('#mvDecoy'); if (dc) dc.onclick = ropeDecoy; const ey = el.querySelector('#mvEye'); if (ey) ey.onclick = ropeEye; el.querySelector('#mvHelp').onclick = () => { if (RP.st === 'choose') ropeHelp(); };
  }
  function ropeHud() {
    const F = FOES[D.foe]; $('page').textContent = `북 대결${D.bo > 1 ? ` ${D.round}판` : ''} · ${F.n}`; $('pause').style.display = 'none'; $('swap').style.display = 'none'; $('bag').style.display = 'none'; $('goal').hidden = true;
    const h = [`<span class="tag">나 ${D.wins.me} : ${D.wins.foe} 상대</span>`, `<span class="tag">${RP.turn}/${RMAX}수</span>`, RP.a.pet ? `<span class="tag" style="border-color:${PETS[RP.a.pet].c}">${PETS[RP.a.pet].n} ${RP.a.lvl}</span>` : '<span class="tag">동행 없음</span>', SV.load.b1 ? `<span class="tag">책갈피 ${PETS[SV.load.b1].n}</span>` : ''].join('');
    if ($('tags').innerHTML !== h) $('tags').innerHTML = h;
  }
  // ── 그리기(세로 화면: 위 상대 · 가운데 줄 · 아래 나)
  function ropeRender() {
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.imageSmoothingEnabled = false; ctx.fillStyle = '#1d1813'; ctx.fillRect(0, 0, W, H); if (!RP) return;
    const top = ($('hud').hidden ? 0 : $('hud').offsetHeight) + 6, ab = $('act'), bot = H - (ab.hidden ? 12 : ab.offsetHeight + 18), Ha = Math.max(300, bot - top), s = Math.min(W / 360, Ha / 520), cx = W / 2, pw = Math.min(W - 16, 380 * s);
    const rr = (x, y, w, h, r) => { ctx.beginPath(); if (ctx.roundRect) ctx.roundRect(x, y, w, h, r); else ctx.rect(x, y, w, h); };
    const txt = (t, x, y, sz, col, al = 'center', wt = 700, fam = '"Gowun Dodum", sans-serif') => { ctx.font = `${wt} ${Math.round(sz)}px ${fam}`; ctx.textAlign = al; ctx.textBaseline = 'middle'; ctx.fillStyle = col; ctx.fillText(t, x, y); };
    const spr = (w, dir, f, x, y, size) => { if (!w) return; if (w.walker) drawWalker(w, dir, f, x - size / 2, y - size / 2, size); else { const hh = size * w.h / w.w; drawWalker(w, dir === 'left' ? 'left' : 'right', f, x - size / 2, y - hh / 2, size); } };
    ctx.fillStyle = '#ece0c4'; rr(cx - pw / 2, top, pw, Ha, 14 * s); ctx.fill(); ctx.strokeStyle = 'rgba(120,90,50,0.12)'; ctx.lineWidth = 1; for (let y = top + 26 * s; y < top + Ha - 8; y += 26 * s) { ctx.beginPath(); ctx.moveTo(cx - pw / 2 + 12, y); ctx.lineTo(cx + pw / 2 - 12, y); ctx.stroke(); }
    const F = FOES[D.foe], a = RP.a, b = RP.b, fy = top + Ha * 0.12, ty = top + Ha * 0.27, y1 = top + Ha * 0.37, y2 = top + Ha * 0.79, my = top + Ha * 0.9, mid = (y1 + y2) / 2, half = (y2 - y1) / 2, T = performance.now() / 1000;
    const rev = RP.st === 'reveal' ? RP.rev : null, pull = rev && RP.t > 0.35 && RP.t < 0.9 ? Math.sign(rev.r.d) : 0;
    // 상대
    spr(NINJA && (NS[D.foe] || NS['e_' + D.foe]), 'down', 0, cx - 30 * s, fy - (pull < 0 ? 3 * s : 0), 54 * s); if (b.pet) { spr(NINJA && NS['p_' + b.pet], 'left', Math.floor(T * 3) % 2, cx + 30 * s, fy + 8 * s, 38 * s); }
    txt(F.n.split(' ').pop(), cx - pw / 2 + 14 * s, fy - 14 * s, 13 * s, '#3a2a1a', 'left'); for (let i = 0; i < b.kiMax; i++) { ctx.beginPath(); ctx.arc(cx - pw / 2 + (20 + i * 13) * s, fy + 4 * s, 4.6 * s, 0, 7); ctx.fillStyle = i < b.ki ? '#e2b85a' : 'rgba(90,70,40,0.18)'; ctx.fill(); ctx.strokeStyle = '#6b5a3a'; ctx.lineWidth = 1; ctx.stroke(); } txt('기운', cx - pw / 2 + 14 * s, fy + 18 * s, 10 * s, '#7a6a52', 'left', 400);
    if (b.pet) txt(`${PETS[b.pet].n} ${b.lvl}`, cx + pw / 2 - 14 * s, fy - 14 * s, 11 * s, '#3a2a1a', 'right'); if (b.body) txt('책갈피 ' + { counter: '해태', guard: '흥부', greed: '놀부', wing: '제비', decoy: '구미호' }[b.body], cx + pw / 2 - 14 * s, fy + 22 * s, 10 * s, '#7a6a52', 'right', 400);
    // 기색 말풍선
    { const bw = pw - 28 * s, bx = cx - bw / 2, bh = 40 * s, by = ty - bh / 2; ctx.fillStyle = '#fffaf0'; ctx.strokeStyle = '#b8a682'; ctx.lineWidth = 1.5; rr(bx, by, bw, bh, 10 * s); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.moveTo(cx - 36 * s, by); ctx.lineTo(cx - 28 * s, by - 7 * s); ctx.lineTo(cx - 20 * s, by); ctx.fill();
      if (RP.st === 'choose' || RP.st === 'help') { if (RP.tell) { const tl = TELL[RP.tell]; txt(`기색: ${F.n.split(' ').pop()}${jo(F.n, '이', '가')} ${tl[0]}`, cx, ty - 8 * s, 11.5 * s, '#2a2218'); txt(`→ ${tl[1]}${RP.eye ? (RP.tellTrue ? '  → 진짜!' : '  → 거짓!') : ''}`, cx, ty + 9 * s, 11 * s, RP.eye ? (RP.tellTrue ? '#4a7a3a' : '#b8432f') : '#7a6a52', 'center', 700); } else txt(RP.note || '기색을 읽을 수 없어요', cx, ty, 11.5 * s, '#a8582a'); }
      else if (rev) txt(rev.r.txt, cx, ty, Math.min(12 * s, (bw - 10) / Math.max(10, rev.r.txt.length) * 1.7), '#2a2218'); }
    // 줄
    ctx.lineCap = 'round'; ctx.strokeStyle = '#6b4a2a'; ctx.lineWidth = 9 * s; ctx.beginPath(); ctx.moveTo(cx, y1); ctx.lineTo(cx, y2); ctx.stroke(); ctx.strokeStyle = '#c8a070'; ctx.lineWidth = 5 * s; ctx.setLineDash([6 * s, 5 * s]); ctx.lineDashOffset = -RP.shownR * 6 * s; ctx.beginPath(); ctx.moveTo(cx, y1); ctx.lineTo(cx, y2); ctx.stroke(); ctx.setLineDash([]); ctx.lineCap = 'butt';
    for (let i = -RL; i <= RL; i++) { const y = mid + i / RL * half, w = i === 0 ? 16 : i % 4 === 0 ? 11 : 6; ctx.strokeStyle = i === 0 ? '#6b5a3a' : 'rgba(90,70,40,0.45)'; ctx.lineWidth = i === 0 ? 2 : 1; ctx.beginPath(); ctx.moveTo(cx - w * s - 7 * s, y); ctx.lineTo(cx - 7 * s, y); ctx.moveTo(cx + 7 * s, y); ctx.lineTo(cx + 7 * s + w * s, y); ctx.stroke(); }
    ctx.fillStyle = '#b8432f'; rr(cx - 26 * s, y1 - 12 * s, 52 * s, 10 * s, 4 * s); ctx.fill(); txt('상대 끝', cx, y1 - 22 * s, 10 * s, '#b8432f'); ctx.fillStyle = '#e2b85a'; rr(cx - 26 * s, y2 + 2 * s, 52 * s, 10 * s, 4 * s); ctx.fill(); txt('내 끝', cx, y2 + 22 * s, 10 * s, '#8a6a2a');
    { const ky = mid + clamp(RP.shownR, -RL, RL) / RL * half; ctx.fillStyle = '#d9483a'; ctx.strokeStyle = '#3f2832'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(cx, ky); ctx.lineTo(cx - 15 * s, ky - 9 * s); ctx.lineTo(cx - 15 * s, ky + 9 * s); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.moveTo(cx, ky); ctx.lineTo(cx + 15 * s, ky - 9 * s); ctx.lineTo(cx + 15 * s, ky + 9 * s); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.beginPath(); ctx.arc(cx, ky, 5 * s, 0, 7); ctx.fill(); ctx.stroke();
      const n = Math.round(RP.shownR); txt(n === 0 ? '가운데' : n > 0 ? `내 쪽 ${n}` : `상대 쪽 ${-n}`, cx + 24 * s, ky, 10.5 * s, n > 0 ? '#8a6a2a' : n < 0 ? '#b8432f' : '#7a6a52', 'left'); }
    // 지난 수(왼쪽 세로)
    const hs = RP.hist.slice(-6); hs.forEach((h, i) => { const x = cx - pw / 2 + 22 * s, y = y1 + 8 * s + i * 26 * s, chip = (m, xx) => { ctx.fillStyle = MV[m].c; rr(xx - 9 * s, y - 9 * s, 18 * s, 18 * s, 4 * s); ctx.fill(); txt(MV[m].g, xx, y + 1, 10.5 * s, '#fffaf0', 'center', 700, '"Gowun Batang", serif'); }; chip(h.foe, x); chip(h.me, x + 21 * s); ctx.fillStyle = h.d > 0 ? '#5a8a3a' : h.d < 0 ? '#b8432f' : '#9a8a6a'; txt(h.d > 0 ? `+${h.d}` : h.d < 0 ? `${h.d}` : '0', x + 42 * s, y, 10 * s, ctx.fillStyle, 'left'); });
    if (hs.length) txt('상대·나', cx - pw / 2 + 32 * s, y1 - 8 * s, 9 * s, '#9a8a6a', 'center', 400);
    // 드러내기: 두 수 카드
    if (rev) { const k = Math.min(1, RP.t / 0.3), card2 = (m, y, who) => { const w = 64 * s, h = 70 * s, x = cx + pw / 2 - 18 * s - w; ctx.globalAlpha = k; ctx.fillStyle = '#fffaf0'; ctx.strokeStyle = MV[m].c; ctx.lineWidth = 3; rr(x, y - h / 2, w, h, 10 * s); ctx.fill(); ctx.stroke(); txt(MV[m].g, x + w / 2, y - 8 * s, 28 * s, MV[m].c, 'center', 700, '"Gowun Batang", serif'); txt(`${who} ${MV[m].n}`, x + w / 2, y + 22 * s, 10 * s, '#3a2a1a'); ctx.globalAlpha = 1; };
      card2(rev.foe, mid - half * 0.5, '상대'); card2(rev.me, mid + half * 0.5, '나'); }
    // 나
    spr(NINJA && NS.me, 'up', 0, cx - 30 * s, my + (pull > 0 ? 3 * s : 0), 50 * s); if (a.pet) spr(NINJA && NS['p_' + a.pet], 'right', Math.floor(T * 3) % 2, cx + 30 * s, my + 4 * s, 38 * s);
    for (let i = 0; i < a.kiMax; i++) { ctx.beginPath(); ctx.arc(cx - pw / 2 + (20 + i * 13) * s, my - 2 * s, 4.6 * s, 0, 7); ctx.fillStyle = i < a.ki ? '#e2b85a' : 'rgba(90,70,40,0.18)'; ctx.fill(); ctx.strokeStyle = '#6b5a3a'; ctx.lineWidth = 1; ctx.stroke(); } txt('내 기운', cx - pw / 2 + 14 * s, my + 14 * s, 10 * s, '#7a6a52', 'left', 400);
    if (a.pet) { txt(`${PETS[a.pet].n} ${a.lvl}`, cx + pw / 2 - 14 * s, my - 18 * s, 11 * s, '#3a2a1a', 'right'); }
    if (a.pet) txt(sigOf(a.pet).split(' — ').pop().slice(0, 22), cx, top + Ha - 10 * s, 10 * s, '#7a6a52', 'center', 400);
  }
