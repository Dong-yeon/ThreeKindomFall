  // ═════════ 천하 지도 v0.18(D-168): 후한 13주를 줄여 그린 중국 지도 · 하북(유주 · 기주)에서 시작 · 1장 평정 → 사례(낙양) 안개가 걷힘 ═════════
  // 지도 위 이동은 자유, 안개 낀 주(州)에는 못 들어감. 강은 나루로만 건넘. 군영은 탁현.
  const CM = { W: 2400, H: 2000, G: 20,
    land: [[100, 420], [350, 330], [700, 250], [1000, 200], [1300, 180], [1650, 170], [1950, 220], [2150, 330], [2250, 450], [2180, 560], [2000, 640], [1880, 720], [1900, 800], [2050, 830], [2300, 860], [2280, 960], [2100, 1000], [2080, 1150], [2180, 1300], [2230, 1480], [2200, 1650], [2050, 1800], [1850, 1900], [1500, 1960], [1200, 1960], [950, 1900], [700, 1850], [450, 1700], [330, 1450], [350, 1200], [420, 1000], [300, 880], [150, 620]],
    provs: { you: { n: '유주', h: '幽州', x: 1750, y: 380 }, ji: { n: '기주', h: '冀州', x: 1500, y: 760 }, bing: { n: '병주', h: '并州', x: 1050, y: 520 }, liang: { n: '량주', h: '涼州', x: 500, y: 600 }, sili: { n: '사례', h: '司隸', x: 1150, y: 1010 }, yan: { n: '연주', h: '兗州', x: 1620, y: 1000 }, qing: { n: '청주', h: '青州', x: 1950, y: 900 }, xu: { n: '서주', h: '徐州', x: 1850, y: 1120 }, yu: { n: '예주', h: '豫州', x: 1500, y: 1150 }, jing: { n: '형주', h: '荊州', x: 1300, y: 1450 }, yang: { n: '양주', h: '揚州', x: 1900, y: 1450 }, yi: { n: '익주', h: '益州', x: 700, y: 1350 }, jiao: { n: '교주', h: '交州', x: 1400, y: 1850 } },
    rivers: [{ n: '황하', c: '#8a9a78', c2: '#c8b878', w: 24, lab: [[1330, 925], [960, 290]], pts: [[250, 700], [500, 640], [700, 560], [820, 300], [1000, 280], [1080, 420], [1060, 700], [1080, 930], [1200, 950], [1400, 930], [1600, 880], [1800, 820], [1905, 795]] },
      { n: '장강', c: '#3a6aa8', c2: '#6a9ad8', w: 28, lab: [[1500, 1490], [900, 1425]], pts: [[350, 1350], [600, 1380], [800, 1430], [1000, 1420], [1200, 1470], [1400, 1500], [1600, 1480], [1800, 1440], [2000, 1470], [2232, 1480]] }],
    cross: [{ x: 1160, y: 944, r: 34, n: '맹진 나루' }],
    wall: [[350, 330], [700, 280], [1000, 240], [1300, 230], [1650, 220], [1950, 262]],
    mounts: [[[1295, 420], [1300, 600], [1285, 800]], [[600, 1120], [850, 1135], [1040, 1150]], [[880, 640], [900, 820]], [[1560, 1300], [1700, 1330]]],
    camp: { x: 1640, y: 480, w: 360, h: 300 },
    roads: [[[1640, 630], [1560, 690], [1440, 770]], [[1440, 770], [1330, 850], [1215, 915], [1160, 944]], [[1160, 944], [1150, 1000], [1130, 1045]], [[1130, 1045], [1070, 1085], [1010, 1100]], [[1130, 1045], [1212, 1062], [1345, 990]], [[1640, 630], [1840, 670]], [[1560, 690], [1580, 815]]],
    spots: [
      { id: 'smith', k: 'bld', x: 1530, y: 470, n: '대장간', img: ['houseR', 5, 3, [2]], bw: 80, bh: 40 },
      { id: 'stable', k: 'bld', x: 1750, y: 470, n: '마구간', img: ['houseB', 5, 3, [2]], bw: 80, bh: 40 },
      { id: 'tent', k: 'bld', x: 1640, y: 405, n: '군막', tent: true, bw: 70, bh: 34 },
      { id: 'liubei', k: 'npc', x: 1700, y: 535, n: '유비' },
      { id: 'f1', k: 'stage', x: 1430, y: 770, n: '1장 황건적의 난', g: '黃', d: '탁현을 노리는 황건 진영 3곳 → 정원지 → 장각' },
      { id: 's2', k: 'stage', x: 1345, y: 985, n: '2장 사수관', g: '華', d: '관문을 지키는 화웅', lock: 'f1', gate: true },
      { id: 's3', k: 'stage', x: 1212, y: 1058, n: '3장 호뢰관', g: '呂', d: '천하무적 여포', lock: 's2', gate: true, big: true },
      { id: 'zhuo', k: 'city', x: 1840, y: 680, n: '탁현', d: '유비 · 관우 · 장비가 의형제를 맺은 고을', size: 1 },
      { id: 'ye', k: 'city', x: 1580, y: 840, n: '업', d: '기주의 큰 성', size: 2 },
      { id: 'luoyang', k: 'city', x: 1010, y: 1100, n: '낙양', d: '후한의 수도', size: 3 },
      { id: 'mengjin', k: 'ferry', x: 1160, y: 944, n: '맹진 나루', d: '황하를 건너는 나루 — 건너면 낙양' },
    ],
    tease: [['백마', 1470, 952], ['하비', 1900, 1110], ['허창', 1480, 1132], ['번성', 1272, 1352], ['양양', 1252, 1402], ['맥성', 1140, 1392], ['장안', 840, 1000], ['성도', 640, 1380], ['건업', 2020, 1432], ['오관', 1000, 1010]],
  };
  const WS = { x: 1640, y: 520, fx: 0, fy: 1, lx: 0, ly: 0, near: null, t: 0, wb: null, hd: 'right' };
  const RELICS = {
    oath: { n: '도원의 맹약', g: '盟', lv: 1, d: '시작부터 합류 부대 4명 · 아군 공격 +20%' },
    book: { n: '손자병법', g: '書', lv: 2, d: '책략 재사용 −15%' },
    tiger: { n: '호랑이 부적', g: '虎', lv: 2, d: '무쌍 게이지 +35% 빨리' },
    cart: { n: '군량 수레', g: '糧', lv: 3, d: '최대 체력 +20% · 초당 회복 +0.5' },
    saddle: { n: '명마 안장', g: '鞍', lv: 4, d: '말 체력 +50% · 짓밟기 +40%' },
    seal: { n: '옥새 조각', g: '璽', lv: 5, d: '공적 경험 +25%' },
  };
  // 갑옷: 입으면 관우 그림 색이 바뀜 · 말: 적토마(빠름 · 짓밟기) / 검은 군마(튼튼함)
  const ARMORS = { green: { n: '녹포', g: '袍', d: '기본 전포', hp: 0, atk: 0, red: 0, spd: 0, mg: 0, cost: 0 }, iron: { n: '철갑', g: '鐵', d: '체력 +25% · 받는 피해 −10% · 이동 −5%', hp: 0.25, atk: 0, red: 0.1, spd: -0.05, mg: 0, cost: 150 }, gold: { n: '금룡포', g: '龍', d: '공격 +10% · 무쌍 게이지 +20%', hp: 0, atk: 0.1, red: 0, spd: 0, mg: 0.2, cost: 300, need: 'f1' } };
  const HORSES = { red: { n: '적토마', g: '赤', d: '이동 +70% · 짓밟기 강함 · 체력 120', spr: 'a_horseS', hp: 120, spd: 255, tr: 1 }, black: { n: '검은 군마', g: '黑', d: '이동 +45% · 짓밟기 보통 · 체력 220', spr: 'a_horseBS', hp: 220, spd: 218, tr: 0.75 }, none: { n: '걸어서', g: '步', d: '말 없이 출진(말 버튼 없음)' } };
  const MUTS = { elite: { n: '황건 정예', d: '황건 체력 +30%', b: 0.3 }, raid: { n: '본진 기습 강화', d: '본진 기습 두 배 · 아군을 무시하고 달리는 기병', b: 0.3 } };
  const relSlots = (M) => Math.min(3, 1 + Math.floor(M.glv / 2));
  const upCostW = (lv) => 60 + 50 * lv;
  function wSV() { const M = muSV(); if (M.merit == null) Object.assign(M, { merit: 0, wpn: 0, arm: 0, sad: 0, rel: ['oath'], mut: {}, intro: false });
    if (!M.armor) Object.assign(M, { armor: 'green', armors: ['green'], hk: M.horse === false ? 'none' : 'red' }); M.horse = M.hk !== 'none'; if (!M.best) M.best = {}; return M; }
  const heroKey = (M) => (NS['gy_' + (M || wSV()).armor] ? 'gy_' + (M || wSV()).armor : 'p_guanyu');
  const stageOpen = (s) => !s.lock || (wSV().best[s.lock] && wSV().best[s.lock].win);
  // ── 땅 · 주(州) 격자(20칸): 바다 / 주 번호. 열린 주에만 들어갈 수 있음
  const PK = Object.keys(CM.provs); let CG = null;
  function inPoly(x, y, P) { let c = false; for (let i = 0, j = P.length - 1; i < P.length; j = i++) { const [xi, yi] = P[i], [xj, yj] = P[j]; if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) c = !c; } return c; }
  function cmGrid() { if (CG) return CG; const G = CM.G, gw = Math.ceil(CM.W / G), gh = Math.ceil(CM.H / G), pv = new Int8Array(gw * gh).fill(-1);
    for (let j = 0; j < gh; j++) for (let i = 0; i < gw; i++) { const x = (i + 0.5) * G, y = (j + 0.5) * G; if (!inPoly(x, y, CM.land)) continue; let b = 0, bd = 1e12; PK.forEach((k, n) => { const P = CM.provs[k], d = (P.x - x) ** 2 + (P.y - y) ** 2; if (d < bd) { bd = d; b = n; } }); pv[j * gw + i] = b; }
    const seg = []; for (let j = 0; j < gh; j++) for (let i = 0; i < gw; i++) { const a = pv[j * gw + i]; if (a < 0) continue; if (i < gw - 1) { const b = pv[j * gw + i + 1]; if (b >= 0 && b !== a) seg.push([(i + 1) * G, j * G, 0]); } if (j < gh - 1) { const b = pv[(j + 1) * gw + i]; if (b >= 0 && b !== a) seg.push([i * G, (j + 1) * G, 1]); } }
    return (CG = { gw, gh, pv, seg }); }
  const provAt = (x, y) => { const g = cmGrid(), i = Math.floor(x / CM.G), j = Math.floor(y / CM.G); if (i < 0 || j < 0 || i >= g.gw || j >= g.gh) return -1; return g.pv[j * g.gw + i]; };
  function openProvs() { const M = wSV(), o = new Set(['you', 'ji']); if (M.best.f1 && M.best.f1.win) o.add('sili'); return o; }
  let WOPEN = null; const isOpen = (pi) => pi >= 0 && WOPEN.has(PK[pi]);
  function segDist(x, y, ax, ay, bx, by) { const dx = bx - ax, dy = by - ay, t = clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0, 1); return Math.hypot(x - ax - dx * t, y - ay - dy * t); }
  function riverHit(x, y, r) { for (const R of CM.rivers) for (let k = 1; k < R.pts.length; k++) if (segDist(x, y, ...R.pts[k - 1], ...R.pts[k]) < R.w / 2 + r - 2) return !CM.cross.some((q) => Math.hypot(q.x - x, q.y - y) < q.r); return false; }
  function wBlocks() { if (WS.wb) return WS.wb; const C = CM.camp, x0 = C.x - C.w / 2, y0 = C.y - C.h / 2, t = 10, g0 = C.x - 36, g1 = C.x + 36;
    const b = [{ x: x0, y: y0, w: C.w, h: t }, { x: x0, y: y0, w: t, h: C.h }, { x: x0 + C.w - t, y: y0, w: t, h: C.h }, { x: x0, y: y0 + C.h - t, w: g0 - x0, h: t }, { x: g1, y: y0 + C.h - t, w: x0 + C.w - g1, h: t }];
    for (const s of CM.spots) if (s.k === 'bld') b.push({ x: s.x - s.bw / 2, y: s.y - s.bh, w: s.bw, h: s.bh, bld: 1 }); return (WS.wb = b); }
  function wFree(x, y, r) { if (x < r || y < r || x > CM.W - r || y > CM.H - r) return false; for (const [dx, dy] of [[0, 0], [r, 0], [-r, 0], [0, r], [0, -r]]) if (!isOpen(provAt(x + dx, y + dy))) return false; if (riverHit(x, y, r)) return false;
    for (const q of wBlocks()) { const cx = clamp(x, q.x, q.x + q.w), cy = clamp(y, q.y, q.y + q.h); if (Math.hypot(x - cx, y - cy) < r) return false; } return true; }
  function wMove(dx, dy) { const r = 10; if (wFree(WS.x + dx, WS.y + dy, r)) { WS.x += dx; WS.y += dy; return; } if (dx && wFree(WS.x + dx, WS.y, r)) { WS.x += dx; return; } if (dy && wFree(WS.x, WS.y + dy, r)) WS.y += dy; }
  // ── 들어가기(타이틀 · 판 끝난 뒤)
  function lobby(at) { worldEnter(at); }
  function worldEnter(at) {
    setMode('world'); A = null; $('hud').hidden = true; $('talk').hidden = true; TALK.on = false; inputLock = false; $('act').hidden = true; $('mbtn').hidden = true; closeCard(); fdArt(); music('town');
    const M = wSV(); WOPEN = openProvs(); CM_MINI = null; const s = at && CM.spots.find((q) => q.id === at);
    if (s) { WS.x = s.x; WS.y = s.y + 70; } else if (M.wpos2) { WS.x = M.wpos2.x; WS.y = M.wpos2.y; } else { WS.x = 1640; WS.y = 520; } if (!wFree(WS.x, WS.y, 10)) { WS.x = 1640; WS.y = 520; } WS.lx = WS.x; WS.ly = WS.y; WS.near = null; wPanel(null);
    if (!M.intro) { M.intro = true; saveSV(); setTimeout(() => talk('유비', ['운장, 황건적이 이 탁현 남쪽에 진을 쳤소.', '대장간 · 마구간 · 군막에서 무장을 갖추시오. 갑옷도 말도 직접 입혀 보고 고를 수 있소.', '준비가 되면 남쪽 문으로 나가시오. 황하 건너 낙양 쪽은 아직 안개에 덮여 있소.'], () => banner('천하 지도 — 하북', '끌어서 이동 · 건물이나 장에 다가가면 들어가요')), 300); }
    else if (s && M.best[s.id] && M.best[s.id].win && !M['seen_' + s.id]) { M['seen_' + s.id] = true; saveSV(); setTimeout(() => banner('사례(낙양) 쪽 안개가 걷혔어요!', '맹진 나루로 황하를 건너 사수관으로'), 200); }
  }
  // ── 매 프레임
  function worldUpdate(dt) { WS.t += dt; const M = wSV(); WS.lx = WS.x; WS.ly = WS.y;
    if (!inputLock && $('ov').hidden) { const [mx, my] = moveVec(); if (mx || my) { const H0 = HORSES[M.hk], sp = (M.hk !== 'none' ? H0.spd * 0.78 : 130) * (1 + ARMORS[M.armor].spd); wMove(mx * sp * dt, my * sp * dt); WS.fx = mx; WS.fy = my; } }
    let near = null, bd = 1e9; for (const s of CM.spots) { const d = Math.hypot(s.x - WS.x, (s.k === 'bld' ? s.y + 14 : s.y) - WS.y), R = s.k === 'stage' ? 62 : s.k === 'npc' ? 34 : s.k === 'city' ? 40 + s.size * 10 : 46; if (d < R && d < bd) { bd = d; near = s; } }
    if (near !== WS.near) { WS.near = near; wPanel(near); }
    if (Math.floor(WS.t * 2) !== Math.floor((WS.t - dt) * 2)) M.wpos2 = { x: Math.round(WS.x), y: Math.round(WS.y) }; }
  // 다가가면 아래에 뜨는 판(움직임을 막지 않음)
  function wPanel(s) { const el = $('wp'); if (!s) { el.hidden = true; return; } const M = wSV(); let h = '';
    if (s.id === 'smith') h = `<b>대장간</b><span>무기 · 갑옷 — 청룡언월도 Lv ${M.wpn} · ${ARMORS[M.armor].n}</span><button type="button" data-w="smith">들어가기</button>`;
    else if (s.id === 'stable') h = `<b>마구간</b><span>말 — ${HORSES[M.hk].n}${M.hk !== 'none' ? ` · 안장 Lv ${M.sad}` : ''}</span><button type="button" data-w="stable">들어가기</button>`;
    else if (s.id === 'tent') h = `<b>군막</b><span>유물 ${M.rel.length}/${relSlots(M)}칸 · 관우 Lv ${M.glv}</span><button type="button" data-w="tent">들어가기</button>`;
    else if (s.id === 'liubei') h = `<b>유비</b><span>현덕 · 아군 총대장</span><button type="button" data-w="liubei">말 걸기</button>`;
    else if (s.k === 'city' || s.k === 'ferry') h = `<b>${s.n}</b><span>${s.d}</span>`;
    else if (s.k === 'stage') { const open = stageOpen(s), b = M.best[s.id], ready = open && s.id === 'f1'; h = `<b>${s.n}</b><span>${!open ? `${CM.spots.find((q) => q.id === s.lock).n}을 평정하면 열려요` : !ready ? '길은 열렸어요 — 다음 시안에서 싸울 수 있어요' : `${s.d}${b ? ` · ${b.win ? `평정 ${fmtT(b.t)}` : `최고 ${b.cap}/3 점령`}` : ''}`}</span>${ready ? `<button type="button" data-w="${s.id}">출진 준비</button>` : ''}`; }
    el.innerHTML = h; el.hidden = false; const b = el.querySelector('[data-w]'); if (b) b.onclick = () => wOpen(b.dataset.w); }
  function wOpen(id) { const M = wSV(); joy.on = false; sfx('accept', 0.25); $('wp').hidden = true;
    if (id === 'liubei') { const lines = M.best.f1 && M.best.f1.win ? ['탁현을 지켜 냈구려, 운장. 백성들이 운장의 이름을 부르고 있소.', '황하 건너 낙양 쪽 안개가 걷혔소. 맹진 나루로 건너 사수관으로 가시오 — 화웅이 관문을 지킨다 하오.'] : ['황건 진영 세 곳을 무너뜨리면 관문이 열릴 것이오.', '본진은 내가 지키겠소. 진영을 점령하면 우리 병사들이 운장을 도우러 갈 것이오.']; return talk('유비', lines, () => wPanel(WS.near)); }
    if (id === 'smith') return eqOpen('wpn'); if (id === 'stable') return eqOpen('horse'); if (id === 'tent') return eqOpen('rel'); if (id === 'f1') return wSortie('f1'); }
  function wSortie(id) { const M = wSV(), s = CM.spots.find((q) => q.id === id), b = M.best[id], bonus = Object.keys(MUTS).filter((k) => M.mut[k]).reduce((a, k) => a + MUTS[k].b, 0), S = eqStats(eqCur());
    card(`<h2>${s.n}</h2><p class="lead">${s.d}</p><div class="stats"><span>관우</span><b>Lv ${M.glv} · 체력 ${S.hp} · 공격 ${S.atk}%</b><span>무기</span><b>청룡언월도 Lv ${M.wpn}</b><span>갑옷</span><b>${ARMORS[M.armor].n} Lv ${M.arm}</b><span>말</span><b>${M.hk === 'none' ? '없음' : `${HORSES[M.hk].n}(체력 ${S.hhp})`}</b><span>유물</span><b>${M.rel.map((k) => RELICS[k].n).join(' · ') || '없음'}</b><span>최고 기록</span><b>${b ? (b.win ? `평정 ${fmtT(b.t)}` : `${b.cap}/3 점령`) : '없음'}</b></div>
      <h3>변이 — 더 어렵게, 전공 더 많이</h3>${Object.entries(MUTS).map(([k, U]) => `<button class="opt${M.mut[k] ? ' on' : ''}" type="button" data-mut="${k}" style="grid-template-columns:1fr"><b>${M.mut[k] ? '☑' : '☐'} ${U.n} <small style="font-weight:400">전공 +${U.b * 100}%</small></b><span>${U.d}</span></button>`).join('')}
      <button class="go" type="button" id="go">출진${bonus ? ` (전공 +${Math.round(bonus * 100)}%)` : ''}</button><button class="sub" type="button" id="out">돌아가기</button>`, (c) => {
      c.querySelectorAll('[data-mut]').forEach((bt) => bt.onclick = () => { const k = bt.dataset.mut; M.mut[k] = !M.mut[k]; saveSV(); wSortie(id); });
      c.querySelector('#go').onclick = () => { closeCard(); $('wp').hidden = true; startField(); }; c.querySelector('#out').onclick = () => { closeCard(); wPanel(WS.near); }; }); }
  // ── 그리기: 바다 · 땅(풀) · 해안 · 주 경계 · 산 · 강 · 만리장성 · 길 · 나무 · 도시 · 군영 · 장 · 안개 · 관우 · 작은 지도
  let WM_IMG = null, CM_TREES = null, CM_PAT = null, CM_MINI = null;
  function wImgs() { if (WM_IMG || !NINJA) return WM_IMG; WM_IMG = {}; for (const s of CM.spots) if (s.img) { const [set, w, h, d] = s.img; WM_IMG[s.id] = houseImg(set, w, h, d, s.n); } return WM_IMG; }
  function cmTrees() { if (CM_TREES) return CM_TREES; const r = seeded(41), out = [], C = CM.camp; for (let i = 0; i < 900; i++) { const x = r() * CM.W, y = r() * CM.H; if (provAt(x, y) < 0 || provAt(x, y + 16) < 0) continue; if (Math.abs(x - C.x) < C.w / 2 + 30 && Math.abs(y - C.y) < C.h / 2 + 30) continue; if (riverHit(x, y, 26) || CM.cross.some((q) => Math.hypot(q.x - x, q.y - y) < 80)) continue; if (CM.spots.some((s) => Math.hypot(s.x - x, s.y - y) < 90)) continue;
      let nr = false; for (const rd of CM.roads) for (let k = 1; k < rd.length && !nr; k++) if (segDist(x, y, ...rd[k - 1], ...rd[k]) < 26) nr = true; if (nr) continue; out.push({ x, y, k: i % 3 }); } return (CM_TREES = out); }
  function cmPath(g, P, f) { g.beginPath(); P.forEach(([x, y], i) => (i ? g.lineTo(f(x, y)[0], f(x, y)[1]) : g.moveTo(f(x, y)[0], f(x, y)[1]))); }
  function cmMini() { if (CM_MINI) return CM_MINI; const g0 = cmGrid(), sc = 0.06; CM_MINI = mk(Math.ceil(CM.W * sc), Math.ceil(CM.H * sc), (g) => { g.fillStyle = '#3a5a80'; g.fillRect(0, 0, 999, 999); const cs = CM.G * sc;
      for (let j = 0; j < g0.gh; j++) for (let i = 0; i < g0.gw; i++) { const p = g0.pv[j * g0.gw + i]; if (p < 0) continue; g.fillStyle = WOPEN.has(PK[p]) ? (p % 2 ? '#7a9a52' : '#6a8a48') : '#8a867c'; g.fillRect(i * cs, j * cs, cs + 0.5, cs + 0.5); }
      g.lineCap = 'round'; for (const R of CM.rivers) { g.strokeStyle = R.c; g.lineWidth = 2; cmPath(g, R.pts, (x, y) => [x * sc, y * sc]); g.stroke(); } }); return CM_MINI; }
  function worldRender() { ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.imageSmoothingEnabled = false; SC = W / 360; OX = 0; OY = 0; const VH = H / SC, M = wSV(); if (!WOPEN) WOPEN = openProvs();
    CAMX = clamp(WS.x - 180, 0, CM.W - 360); CAMY = clamp(WS.y - VH * 0.55, 0, CM.H - VH); const vis = (x, y, m = 60) => x > CAMX - m && x < CAMX + 360 + m && y > CAMY - m && y < CAMY + VH + m, f = (x, y) => [X(x), Y(y)];
    // 바다
    ctx.fillStyle = '#3a6090'; ctx.fillRect(0, 0, W, H); ctx.strokeStyle = 'rgba(200,225,250,0.35)'; ctx.lineWidth = 1.5; for (let i = 0; i < 40; i++) { const x = ((i * 137 + WS.t * 10) % 420) - 30, y = (i * 71) % (VH + 40); ctx.beginPath(); ctx.moveTo(x * SC, y * SC); ctx.lineTo((x + 14) * SC, y * SC); ctx.stroke(); }
    // 땅(풀 무늬) · 해안
    if (!CM_PAT) { try { CM_PAT = ctx.createPattern(muChunk(), 'repeat'); } catch (e) { CM_PAT = null; } } cmPath(ctx, CM.land, f); ctx.closePath(); ctx.lineWidth = 7 * SC; ctx.strokeStyle = '#d8c890'; ctx.stroke(); if (CM_PAT && CM_PAT.setTransform) { CM_PAT.setTransform(new DOMMatrix().translate(X(0), Y(0)).scale(SC)); ctx.fillStyle = CM_PAT; } else ctx.fillStyle = '#6a9a48'; ctx.fill(); ctx.lineWidth = 1.5; ctx.strokeStyle = '#8a7a4a'; ctx.stroke();
    // 주 경계(점선)
    const g0 = cmGrid(); ctx.fillStyle = 'rgba(110,70,40,0.55)'; for (const [x, y, v] of g0.seg) { if (!vis(x, y, 20)) continue; if (((x + y) / 20) % 2 < 1) continue; if (v) ctx.fillRect(X(x), Y(y) - 1, CM.G * SC, 2.5); else ctx.fillRect(X(x) - 1, Y(y), 2.5, CM.G * SC); }
    // 산
    for (const rg of CM.mounts) for (let k = 1; k < rg.length; k++) { const [ax, ay] = rg[k - 1], [bx, by] = rg[k], n = Math.ceil(Math.hypot(bx - ax, by - ay) / 34); for (let i = 0; i <= n; i++) { const x = ax + (bx - ax) * i / n + ((i * 37) % 17) - 8, y = ay + (by - ay) * i / n + ((i * 23) % 13) - 6; if (!vis(x, y)) continue; ctx.fillStyle = '#6a7060'; ctx.beginPath(); ctx.moveTo(X(x - 20), Y(y + 12)); ctx.lineTo(X(x), Y(y - 18)); ctx.lineTo(X(x + 20), Y(y + 12)); ctx.fill(); ctx.fillStyle = '#8a9078'; ctx.beginPath(); ctx.moveTo(X(x), Y(y - 18)); ctx.lineTo(X(x + 20), Y(y + 12)); ctx.lineTo(X(x + 4), Y(y + 12)); ctx.fill(); ctx.fillStyle = '#eef0e8'; ctx.beginPath(); ctx.moveTo(X(x - 6), Y(y - 9)); ctx.lineTo(X(x), Y(y - 18)); ctx.lineTo(X(x + 6), Y(y - 9)); ctx.fill(); } }
    // 강 · 나루
    // 만리장성
    ctx.strokeStyle = '#8a7a6a'; ctx.lineWidth = 6 * SC; cmPath(ctx, CM.wall, f); ctx.stroke(); ctx.strokeStyle = '#b8a890'; ctx.lineWidth = 2 * SC; ctx.stroke(); for (const [x, y] of CM.wall) if (vis(x, y)) { ctx.fillStyle = '#8a7a6a'; ctx.fillRect(X(x - 7), Y(y - 12), 14 * SC, 14 * SC); ctx.fillStyle = '#5a4a3a'; ctx.fillRect(X(x - 7), Y(y - 14), 14 * SC, 3 * SC); }
    // 길
    for (const [w, col] of [[22, '#9a7a4a'], [16, '#c8a874']]) { ctx.strokeStyle = col; ctx.lineWidth = w * SC; for (const rd of CM.roads) { cmPath(ctx, rd, f); ctx.stroke(); } }
    ctx.lineCap = 'round'; ctx.lineJoin = 'round'; for (const R of CM.rivers) { ctx.strokeStyle = '#d8c890'; ctx.lineWidth = (R.w + 8) * SC; cmPath(ctx, R.pts, f); ctx.stroke(); ctx.strokeStyle = R.c; ctx.lineWidth = R.w * SC; ctx.stroke(); ctx.setLineDash([10 * SC, 14 * SC]); ctx.lineDashOffset = -WS.t * 12 * SC; ctx.strokeStyle = R.c2; ctx.lineWidth = 2.5 * SC; ctx.stroke(); ctx.setLineDash([]);
      for (const [lx, ly] of R.lab || []) if (vis(lx, ly)) { ctx.font = `700 ${Math.round(12 * SC)}px "Gowun Batang", serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.lineWidth = 3; ctx.strokeStyle = 'rgba(29,24,19,0.7)'; ctx.strokeText(R.n, X(lx), Y(ly)); ctx.fillStyle = '#eaf4ff'; ctx.fillText(R.n, X(lx), Y(ly)); } }
    for (const q of CM.cross) if (vis(q.x, q.y)) { ctx.fillStyle = '#8a6a3a'; ctx.fillRect(X(q.x - 16), Y(q.y - 22), 32 * SC, 44 * SC); ctx.fillStyle = '#a8845a'; for (let y = q.y - 20; y < q.y + 22; y += 7) ctx.fillRect(X(q.x - 14), Y(y), 28 * SC, 4 * SC); ctx.fillStyle = '#5a3a1a'; ctx.beginPath(); ctx.ellipse(X(q.x + 30), Y(q.y + 2 + Math.sin(WS.t * 2) * 1.5), 12 * SC, 5 * SC, 0, 0, 7); ctx.fill(); }
    // 나무
    if (TILE.bigTree) for (const tr of cmTrees()) if (vis(tr.x, tr.y, 30)) ctx.drawImage(TILE.bigTree[tr.k], X(tr.x - 16), Y(tr.y - 24), 32 * SC, 32 * SC);
    // 군영
    const C = CM.camp; if (vis(C.x, C.y, 260)) { ctx.fillStyle = 'rgba(200,168,116,0.35)'; ctx.fillRect(X(C.x - C.w / 2), Y(C.y - C.h / 2), C.w * SC, C.h * SC); for (const q of wBlocks()) if (!q.bld) fdPalisade(q); fdFlag(C.x - 52, C.y + C.h / 2 - 2, '#4a7ab8', '關'); fdFlag(C.x + 52, C.y + C.h / 2 - 2, '#4a7ab8', '劉'); fdLabel('관우의 군영', C.x, C.y + C.h / 2 + 22, '#cfe2f4'); if (NINJA && NS.bb_mil) for (const sx of [-50, 50]) sprAt(NS.bb_mil, 'down', 0, C.x + sx, C.y + C.h / 2 - 22, 22, false); }
    const IM = wImgs(); for (const s of CM.spots) { if (!vis(s.x, s.y, 120)) continue;
      if (s.k === 'bld') { if (s.tent) { fdTent(s.x - 22, s.y - 8, '#e8e0d0', '#4a7ab8'); fdTent(s.x + 22, s.y - 8, '#e8e0d0', '#4a7ab8'); fdTent(s.x, s.y - 18, '#f4ecd8', '#b8432f'); fdLabel(s.n, s.x, s.y + 12, '#fff2c0'); } else if (IM && IM[s.id]) ctx.drawImage(IM[s.id], X(s.x - 40), Y(s.y - 48), 80 * SC, 48 * SC);
        if (s.id === 'stable' && NINJA) for (const [hk, dx] of [['red', 52], ['black', -52]]) if (M.hk !== hk && NS[HORSES[hk].spr]) sprAt(NS[HORSES[hk].spr], dx > 0 ? 'left' : 'right', Math.floor(WS.t * 1.5) + (dx > 0 ? 1 : 0), s.x + dx, s.y + 6, 40, false);
        if (s.id === 'smith') { ctx.fillStyle = '#4a4a4a'; ctx.fillRect(X(s.x + 46), Y(s.y - 2), 12 * SC, 6 * SC); ctx.fillStyle = Math.sin(WS.t * 12) > 0 ? '#ffb050' : '#ff7a3a'; ctx.beginPath(); ctx.arc(X(s.x + 52), Y(s.y - 6), 3 * SC, 0, 7); ctx.fill(); } }
      else if (s.k === 'npc' && NINJA && NS.p_liubei) { sprAt(NS.p_liubei, dirOf(WS.x - s.x, WS.y - s.y), 0, s.x, s.y, 26, false); fdLabel('유비', s.x, s.y - 20, '#cfe2f4'); }
      else if (s.k === 'stage') wStage(s, M); else if (s.k === 'city') wCity(s); else if (s.k === 'ferry') fdLabel(s.n, s.x + 46, s.y - 24, '#fff2c0'); }
    // 안개(닫힌 주) · 주 이름 · 이야기 속 지명
    for (let gy = Math.floor((CAMY - 40) / 40) * 40; gy < CAMY + VH + 40; gy += 40) for (let gx = Math.floor((CAMX - 40) / 40) * 40; gx < CAMX + 400; gx += 40) { const p = provAt(gx + 20, gy + 20); if (p < 0 || WOPEN.has(PK[p])) continue; const hsh = Math.abs((gx * 73856093) ^ (gy * 19349663)) % 100, r = 30 + hsh % 12; ctx.fillStyle = `rgba(236,234,226,${0.78 + (hsh % 10) / 100})`; ctx.beginPath(); ctx.arc(X(gx + 20 + (hsh % 9) - 4), Y(gy + 20 + Math.sin(WS.t * 0.3 + hsh) * 3), r * SC, 0, 7); ctx.fill(); }
    for (const k of PK) { const P = CM.provs[k]; if (!vis(P.x, P.y, 80)) continue; const op = WOPEN.has(k); ctx.font = `700 ${Math.round(26 * SC)}px "Gowun Batang", serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = op ? 'rgba(70,50,20,0.22)' : 'rgba(90,80,64,0.55)'; ctx.fillText(P.h, X(P.x), Y(P.y)); ctx.font = `700 ${Math.round(12 * SC)}px "Gowun Dodum", sans-serif`; ctx.fillText(op ? P.n : `${P.n} — 안개`, X(P.x), Y(P.y + 24)); }
    for (const [n, x, y] of CM.tease) if (vis(x, y) && !isOpen(provAt(x, y))) { ctx.fillStyle = 'rgba(90,80,64,0.5)'; ctx.beginPath(); ctx.arc(X(x), Y(y), 4 * SC, 0, 7); ctx.fill(); ctx.font = `700 ${Math.round(10 * SC)}px "Gowun Dodum", sans-serif`; ctx.fillStyle = 'rgba(70,60,50,0.7)'; ctx.textAlign = 'center'; ctx.fillText(n, X(x), Y(y - 12)); }
    // 관우
    const mv = Math.hypot(WS.x - WS.lx, WS.y - WS.ly) > 0.2; if (WS.fx < -0.2) WS.hd = 'left'; else if (WS.fx > 0.2) WS.hd = 'right'; const hd = WS.hd, hk = heroKey(M);
    ctx.strokeStyle = '#ffd34a'; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.ellipse(X(WS.x), Y(WS.y + 12), 14 * SC, 5 * SC, 0, 0, 7); ctx.stroke();
    if (M.hk !== 'none' && NINJA && NS[HORSES[M.hk].spr]) { sprAt(NS[HORSES[M.hk].spr], hd, Math.floor(WS.t * (mv ? 9 : 1.5)), WS.x, WS.y + 8, 44, false); riderAt(NS[hk], hd, WS.x + (hd === 'left' ? 3 : -3), WS.y - 10 - (mv ? Math.abs(Math.sin(WS.t * 14)) * 2 : 0), 28); }
    else if (NINJA && NS[hk]) sprAt(NS[hk], dirOf(WS.fx, WS.fy), animF(mv, WS.t, 8), WS.x, WS.y, 30, false);
    if (WS.near) { const s = WS.near; ctx.strokeStyle = `rgba(255,211,74,${0.6 + 0.3 * Math.sin(WS.t * 6)})`; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.ellipse(X(s.x), Y(s.k === 'bld' ? s.y + 10 : s.y + 14), (s.k === 'stage' || s.k === 'city' ? 46 : 30) * SC, (s.k === 'stage' || s.k === 'city' ? 16 : 10) * SC, 0, 0, 7); ctx.stroke(); }
    // 다음 갈 곳 화살표
    const nx = CM.spots.find((s) => s.k === 'stage' && stageOpen(s) && !(M.best[s.id] && M.best[s.id].win)) || CM.spots.find((s) => s.id === 'f1');
    if (nx && Math.hypot(nx.x - WS.x, nx.y - WS.y) > 120) { const sx = X(nx.x), sy = Y(nx.y), x0 = 20, x1 = W - 20, y0 = 70, y1 = H - 90; if (sx < x0 || sx > x1 || sy < y0 || sy > y1) { const cx = X(WS.x), cy = Y(WS.y), a = Math.atan2(sy - cy, sx - cx); let k = 1e9; if (Math.cos(a) > 0.01) k = Math.min(k, (x1 - cx) / Math.cos(a)); if (Math.cos(a) < -0.01) k = Math.min(k, (x0 - cx) / Math.cos(a)); if (Math.sin(a) > 0.01) k = Math.min(k, (y1 - cy) / Math.sin(a)); if (Math.sin(a) < -0.01) k = Math.min(k, (y0 - cy) / Math.sin(a));
      const ax = cx + Math.cos(a) * k, ay = cy + Math.sin(a) * k; ctx.save(); ctx.translate(ax, ay); ctx.rotate(a); ctx.fillStyle = '#ffd34a'; ctx.strokeStyle = '#1d1813'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(13, 0); ctx.lineTo(-8, -10); ctx.lineTo(-4, 0); ctx.lineTo(-8, 10); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore(); ctx.font = '700 11px "Gowun Dodum", sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.lineWidth = 3; ctx.strokeStyle = '#1d1813'; const tx = nx.n.split(' ').slice(1).join(' '), lx = clamp(ax - Math.cos(a) * 30, 50, W - 50), ly = clamp(ay - Math.sin(a) * 20, 80, H - 100); ctx.strokeText(tx, lx, ly); ctx.fillStyle = '#fff2c0'; ctx.fillText(tx, lx, ly); } }
    // 위: 관우 · 전공 · 지역 / 작은 지도
    const pn = provAt(WS.x, WS.y); ctx.fillStyle = 'rgba(29,24,19,0.8)'; ctx.fillRect(0, 0, W, 44); ctx.font = '700 15px "Gowun Batang", serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#fff2c0'; ctx.fillText(`관우 Lv ${M.glv}`, 14, 22); ctx.font = '700 13px "Gowun Dodum", sans-serif'; ctx.fillStyle = '#e2b85a'; ctx.textAlign = 'right'; ctx.fillText(`전공 ${M.merit}`, W - 14, 22); ctx.fillStyle = '#d8ccb0'; ctx.textAlign = 'center'; ctx.font = '13px "Gowun Dodum", sans-serif'; ctx.fillText(pn >= 0 ? `${CM.provs[PK[pn]].h} ${CM.provs[PK[pn]].n}` : '천하 지도', W / 2, 22);
    const mm = cmMini(), mw = 92, mh = mw * mm.height / mm.width, mx = W - mw - 10, my = 52; ctx.globalAlpha = 0.92; ctx.fillStyle = '#1d1813'; ctx.fillRect(mx - 2, my - 2, mw + 4, mh + 4); ctx.imageSmoothingEnabled = true; ctx.drawImage(mm, mx, my, mw, mh); ctx.imageSmoothingEnabled = false; ctx.globalAlpha = 1; const ms = mw / CM.W;
    ctx.strokeStyle = 'rgba(255,250,240,0.8)'; ctx.lineWidth = 1; ctx.strokeRect(mx + CAMX * ms, my + CAMY * ms, 360 * ms, VH * ms); for (const s of CM.spots) if (s.k === 'stage') { ctx.fillStyle = stageOpen(s) ? (M.best[s.id] && M.best[s.id].win ? '#6a9ad8' : '#ffd34a') : '#5a564c'; ctx.fillRect(mx + s.x * ms - 2, my + s.y * ms - 2, 4, 4); } ctx.fillStyle = '#fffaf0'; ctx.beginPath(); ctx.arc(mx + WS.x * ms, my + WS.y * ms, 2.5, 0, 7); ctx.fill();
    if (joy.on) drawJoy(); }
  function wCity(s) { const w = 30 + s.size * 22, h = 18 + s.size * 10; ctx.fillStyle = 'rgba(0,0,0,0.2)'; ctx.fillRect(X(s.x - w / 2), Y(s.y + h / 2), w * SC, 5 * SC); ctx.fillStyle = '#b8a888'; ctx.fillRect(X(s.x - w / 2), Y(s.y - h / 2), w * SC, h * SC); ctx.strokeStyle = '#6a5a44'; ctx.lineWidth = 2; ctx.strokeRect(X(s.x - w / 2), Y(s.y - h / 2), w * SC, h * SC);
    ctx.fillStyle = '#8a6a4a'; for (let x = s.x - w / 2; x < s.x + w / 2; x += 8) ctx.fillRect(X(x), Y(s.y - h / 2 - 4), 5 * SC, 4 * SC); ctx.fillStyle = '#a8432f'; for (let i = 0; i < s.size; i++) { const rx = s.x - (s.size - 1) * 12 + i * 24; ctx.beginPath(); ctx.moveTo(X(rx - 12), Y(s.y - 2)); ctx.lineTo(X(rx), Y(s.y - 14)); ctx.lineTo(X(rx + 12), Y(s.y - 2)); ctx.fill(); } ctx.fillStyle = '#3a2410'; ctx.fillRect(X(s.x - 5), Y(s.y + h / 2 - 10), 10 * SC, 10 * SC); fdLabel(s.n, s.x, s.y + h / 2 + 14, '#fff2c0');
    if (NINJA) for (let i = 0; i <= s.size; i++) { const w2 = NS[['bb_n1', 'bb_n2', 'bb_n3', 'bb_n4'][(i + s.size) % 4]]; if (!w2) break; const ph = WS.t * 0.35 + i * 2.1 + s.x * 0.01, vx = Math.cos(ph); sprAt(w2, Math.abs(vx) < 0.15 ? 'down' : vx > 0 ? 'right' : 'left', Math.abs(vx) < 0.15 ? 0 : animF(true, WS.t + i, 6), s.x + Math.sin(ph) * (w / 2 + 8), s.y + h / 2 + 30 + (i % 2) * 8, 18, false); } }
  // 장 모형: 진영(1장) · 관문(2 · 3장)
  function wStage(s, M) { const open = stageOpen(s) && isOpen(provAt(s.x, s.y)), b = M.best[s.id], won = b && b.win;
    ctx.fillStyle = 'rgba(200,168,116,0.5)'; ctx.beginPath(); ctx.ellipse(X(s.x), Y(s.y + 10), 64 * SC, 24 * SC, 0, 0, 7); ctx.fill();
    if (open && !won) { ctx.strokeStyle = `rgba(255,211,74,${0.5 + 0.4 * Math.sin(WS.t * 4)})`; ctx.lineWidth = 2; ctx.beginPath(); ctx.ellipse(X(s.x), Y(s.y + 10), 68 * SC, 26 * SC, 0, 0, 7); ctx.stroke(); }
    if (!s.gate) { for (const [dx, dy] of [[-30, -6], [26, -10], [0, 14]]) fdTent(s.x + dx, s.y + dy, won ? '#e8e0d0' : '#d8b860', won ? '#4a7ab8' : '#a8782a'); fdFlag(s.x - 46, s.y + 4, won ? '#4a7ab8' : '#d8b040', won ? '關' : s.g); fdFlag(s.x + 46, s.y, won ? '#4a7ab8' : '#d8b040', won ? '關' : s.g); for (let i = 0; i < 9; i++) fdPalisade({ x: s.x - 60 + i * 13, y: s.y + 30, w: 10, h: 2 }); }
    else { const w = s.big ? 120 : 92, h = s.big ? 46 : 36; ctx.fillStyle = '#8a8478'; ctx.fillRect(X(s.x - w / 2), Y(s.y - h), w * SC, h * SC); ctx.fillStyle = '#5a564c'; for (let x = s.x - w / 2; x < s.x + w / 2; x += 12) ctx.fillRect(X(x), Y(s.y - h - 6), 8 * SC, 6 * SC); ctx.fillStyle = '#3a2410'; ctx.beginPath(); ctx.moveTo(X(s.x - 14), Y(s.y)); ctx.lineTo(X(s.x - 14), Y(s.y - 18)); ctx.quadraticCurveTo(X(s.x), Y(s.y - 30), X(s.x + 14), Y(s.y - 18)); ctx.lineTo(X(s.x + 14), Y(s.y)); ctx.fill(); fdFlag(s.x - w / 2 + 8, s.y - h - 4, open ? '#d9705e' : '#8a8478', s.g); fdFlag(s.x + w / 2 - 8, s.y - h - 4, open ? '#d9705e' : '#8a8478', s.g); }
    fdLabel(won ? `${s.n} — 평정` : s.n, s.x, s.y + 44, won ? '#cfe2f4' : open ? '#fff2c0' : '#e8e0d0'); }
  // ═════════ 무장 화면(D-168): 관우를 보며 입혀 보기 — 무기 · 갑옷 · 말 · 유물 1~3 (대장간 · 마구간 · 군막이 같은 화면, 여는 칸만 다름) ═════════
  const EQ = { tab: 'wpn', ri: 0, trial: null, dir: 'down', raf: 0, swing: 0 };
  const eqCur = () => { const M = wSV(); return { armor: M.armor, hk: M.hk, rel: [...M.rel] }; };
  const wTier = (lv) => (lv >= 6 ? 2 : lv >= 3 ? 1 : 0);
  function eqStats(L) { const M = wSV(), A0 = ARMORS[L.armor], H0 = HORSES[L.hk], R = new Set(L.rel);
    return { hp: Math.round(fdHP(M) * (1 + 0.08 * M.arm) * (1 + A0.hp) * (R.has('cart') ? 1.2 : 1)), atk: Math.round(fdAtk(M) * 10 * (1 + 0.08 * M.wpn) * (1 + A0.atk)), red: Math.round(A0.red * 100), mg: Math.round(((1 + A0.mg) * (R.has('tiger') ? 1.35 : 1) - 1) * 100),
      hhp: L.hk === 'none' ? 0 : Math.round(H0.hp * (1 + 0.2 * M.sad) * (R.has('saddle') ? 1.5 : 1)), spd: Math.round((L.hk === 'none' ? 100 : H0.spd / 150 * 100) * (1 + A0.spd)) }; }
  // 청룡언월도(전투 · 무장 화면 공용): 강화 Lv 3 비취빛, Lv 6 금빛
  function drawGuandao(g, px, py, a, len, s, tier) { const bx = px - Math.cos(a) * 11 * s, by = py - Math.sin(a) * 11 * s, tx = px + Math.cos(a) * len, ty = py + Math.sin(a) * len;
    g.lineCap = 'round'; g.strokeStyle = '#1d1813'; g.lineWidth = 3.6 * s; g.beginPath(); g.moveTo(bx, by); g.lineTo(tx, ty); g.stroke(); g.strokeStyle = '#8a5a2a'; g.lineWidth = 2 * s; g.stroke();
    g.fillStyle = '#c83a2a'; g.beginPath(); g.arc(px + Math.cos(a) * (len - 4 * s), py + Math.sin(a) * (len - 4 * s), 2.2 * s, 0, 7); g.fill();
    g.save(); g.translate(tx, ty); g.rotate(a); if (tier) { g.shadowColor = tier === 2 ? 'rgba(255,210,90,0.9)' : 'rgba(106,224,150,0.9)'; g.shadowBlur = 8 * s; } g.fillStyle = ['#e8f0ea', '#c8f8d8', '#fff2b0'][tier]; g.strokeStyle = '#1d1813'; g.lineWidth = 1.2 * Math.max(1, s / 2);
    g.beginPath(); g.moveTo(-3 * s, -1.5 * s); g.quadraticCurveTo(5 * s, -9 * s, 14 * s, -4 * s); g.quadraticCurveTo(8 * s, -0.5 * s, 10 * s, 3.5 * s); g.lineTo(-3 * s, 2 * s); g.closePath(); g.fill(); g.shadowBlur = 0; g.stroke();
    g.fillStyle = tier === 2 ? '#e2b85a' : '#4a8a5a'; g.fillRect(-3 * s, -1.5 * s, 4 * s, 3.5 * s); g.restore(); g.lineCap = 'butt'; }
  function eqOpen(tab) { EQ.tab = tab; EQ.ri = 0; EQ.trial = null; EQ.swing = 0.6; joy.on = false; eqDraw(); }
  function eqTrialL() { const L = eqCur(), T = EQ.trial; if (!T) return L; if (T.armor) L.armor = T.armor; if (T.hk) L.hk = T.hk; if (T.rel !== undefined) { const r = L.rel.filter((k) => k !== T.rel); r.splice(Math.min(EQ.ri, r.length), 0, T.rel); L.rel = r.filter(Boolean).slice(0, relSlots(wSV())); } return L; }
  function eqDraw() { const M = wSV(), L = eqTrialL(), S0 = eqStats(eqCur()), S1 = eqStats(L), sl = relSlots(M), T = EQ.trial, title = { wpn: '대장간', armor: '대장간', horse: '마구간', rel: '군막' }[EQ.tab];
    const df = (a, b, u = '') => (a === b ? `<b>${b}${u}</b>` : `${a}${u} → <b class="${b > a ? 'up' : 'dn'}">${b}${u}</b>`);
    const slots = [{ k: 'wpn', g: '刀', n: '무기', v: `Lv ${M.wpn}` }, { k: 'armor', g: ARMORS[L.armor].g, n: '갑옷', v: ARMORS[L.armor].n }, { k: 'horse', g: HORSES[L.hk].g, n: '말', v: HORSES[L.hk].n }, ...[0, 1, 2].map((i) => ({ k: 'rel', i, g: i < sl ? (L.rel[i] ? RELICS[L.rel[i]].g : '+') : '鎖', n: `유물 ${i + 1}`, v: i < sl ? (L.rel[i] ? RELICS[L.rel[i]].n : '빈 칸') : `Lv ${[1, 2, 4][i]}`, lock: i >= sl }))];
    const sh = slots.map((s, j) => `<button type="button" data-slot="${j}" class="${(EQ.tab === s.k && (s.k !== 'rel' || EQ.ri === s.i)) ? 'on' : ''}" ${s.lock ? 'disabled' : ''}><i>${s.g}</i><small>${s.n}</small><em>${s.v}</em></button>`).join('');
    let list = '', act = '';
    if (EQ.tab === 'wpn') { const c = upCostW(M.wpn), tr = wTier(M.wpn); list = `<div class="opt sk evo" style="cursor:default"><span class="ic" style="background:#4a8a5a;color:#fffaf0">刀</span><b>청룡언월도 <em>장착</em></b><span>Lv ${M.wpn} · 공격 +${M.wpn * 8}% · 칼날 ${['은빛', '비취빛', '금빛'][tr]} — 4타 연격 · 마무리 일격</span></div><p class="eqnote">강화 Lv 3에 칼날이 비취빛, Lv 6에 금빛으로 바뀌어요.</p>`; act = `<button class="go" type="button" id="equp" ${M.merit >= c ? '' : 'disabled'}>강화 Lv ${M.wpn} → ${M.wpn + 1} · 전공 ${c}</button>`; }
    else if (EQ.tab === 'armor') { list = Object.entries(ARMORS).map(([k, R]) => { const own = M.armors.includes(k), on = M.armor === k, tri = T && T.armor === k, lk = R.need && !(M.best[R.need] && M.best[R.need].win); return `<button class="opt sk${on ? ' evo' : ''}${tri ? ' tri' : ''}" type="button" data-armor="${k}"><span class="ic" style="background:${{ green: '#3f7a3a', iron: '#6a7080', gold: '#c8a040' }[k]};color:#fffaf0">${R.g}</span><b>${R.n}${on ? ' <em>장착</em>' : own ? '' : lk ? ' <small>1장 평정 후</small>' : ` <small>전공 ${R.cost}</small>`}</b><span>${R.d}</span></button>`; }).join('');
      const k = T && T.armor, R = k && ARMORS[k], own = k && M.armors.includes(k), lk = R && R.need && !(M.best[R.need] && M.best[R.need].win), c = upCostW(M.arm);
      act = (k && k !== M.armor ? (own ? `<button class="go" type="button" id="eqon">${R.n} 장착</button>` : `<button class="go" type="button" id="eqbuy" ${lk || M.merit < R.cost ? 'disabled' : ''}>${lk ? '1장을 평정하면 살 수 있어요' : `전공 ${R.cost}으로 사서 장착`}</button>`) : '') + `<button class="sub" type="button" id="eqarm" ${M.merit >= c ? '' : 'disabled'}>갑옷 강화 Lv ${M.arm} → ${M.arm + 1}(체력 +8%) · 전공 ${c}</button>`; }
    else if (EQ.tab === 'horse') { list = Object.entries(HORSES).map(([k, R]) => `<button class="opt sk${M.hk === k ? ' evo' : ''}${T && T.hk === k ? ' tri' : ''}" type="button" data-hk="${k}"><span class="ic" style="background:${{ red: '#c0503a', black: '#3a3a40', none: '#c8b890' }[k]};color:#fffaf0">${R.g}</span><b>${R.n}${M.hk === k ? ' <em>장착</em>' : ''}</b><span>${R.d}</span></button>`).join('');
      const c = upCostW(M.sad); act = (T && T.hk && T.hk !== M.hk ? `<button class="go" type="button" id="eqon">${HORSES[T.hk].n}${T.hk === 'none' ? '(으)로 출진' : ' 장착'}</button>` : '') + `<button class="sub" type="button" id="eqsad" ${M.merit >= c ? '' : 'disabled'}>안장 강화 Lv ${M.sad} → ${M.sad + 1}(말 체력 +20%) · 전공 ${c}</button>`; }
    else { const need = gNeed(M.glv), cur = M.rel[EQ.ri]; list = `<div class="eqlv"><b>관우 Lv ${M.glv}</b><div class="xp"><i style="width:${Math.min(100, M.gxp / need * 100)}%"></i></div><span>경험 ${M.gxp}/${need} · 유물 칸 ${sl}/3 (Lv 2 · 4에서 늘어요)</span></div>` + Object.entries(RELICS).map(([k, R]) => { const where = M.rel.indexOf(k), lk = M.glv < R.lv; return `<button class="opt sk${where === EQ.ri ? ' evo' : ''}${T && T.rel === k ? ' tri' : ''}" type="button" data-rel="${k}" ${lk ? 'disabled' : ''}><span class="ic" style="background:${where >= 0 ? '#e2b85a' : '#e8d8b0'}">${R.g}</span><b>${R.n}${where >= 0 ? ` <em>유물 ${where + 1}</em>` : ''}</b><span>${lk ? `관우 Lv ${R.lv}에 열려요` : R.d}</span></button>`; }).join('');
      act = (T && T.rel && T.rel !== cur ? `<button class="go" type="button" id="eqon">유물 ${EQ.ri + 1}칸에 ${RELICS[T.rel].n} 장착</button>` : '') + (cur ? `<button class="sub" type="button" id="eqoff">유물 ${EQ.ri + 1}칸 비우기</button>` : '') + `<button class="sub" type="button" id="reset">기록 지우기</button>`; }
    card(`<div class="eqh"><h2>${title}</h2><span>전공 ${M.merit}</span></div><div class="eqv"><canvas id="eqc" width="600" height="340"></canvas><button type="button" class="eqrot" id="eqrot">⟲ 돌려 보기</button>${T ? '<span class="eqtry">입어 보는 중</span>' : ''}</div><div class="eqslots">${sh}</div>
      <div class="eqst">체력 ${df(S0.hp, S1.hp)} · 공격 ${df(S0.atk, S1.atk, '%')} · 이동 ${df(S0.spd, S1.spd, '%')}${S1.red || S0.red ? ` · 받는 피해 −${df(S0.red, S1.red, '%')}` : ''}${S1.mg || S0.mg ? ` · 무쌍 +${df(S0.mg, S1.mg, '%')}` : ''}${S1.hhp || S0.hhp ? ` · 말 체력 ${df(S0.hhp, S1.hhp)}` : ''}</div>
      <div class="eql">${list}</div><div class="eqbtns">${act}<button class="sub" type="button" id="out">나가기</button></div><p style="font-size:.72rem;margin:0">시안 v0.18 · 그림·소리: Ninja Adventure (CC0, pixel-boy)</p>`, (c) => {
      c.querySelectorAll('[data-slot]').forEach((b) => b.onclick = () => { const s = slots[+b.dataset.slot]; EQ.tab = s.k; if (s.k === 'rel') EQ.ri = s.i; EQ.trial = null; sfx('accept', 0.15); eqDraw(); });
      c.querySelectorAll('[data-armor]').forEach((b) => b.onclick = () => { EQ.trial = b.dataset.armor === M.armor ? null : { armor: b.dataset.armor }; EQ.swing = 0.6; eqDraw(); });
      c.querySelectorAll('[data-hk]').forEach((b) => b.onclick = () => { EQ.trial = b.dataset.hk === M.hk ? null : { hk: b.dataset.hk }; eqDraw(); });
      c.querySelectorAll('[data-rel]').forEach((b) => b.onclick = () => { EQ.trial = b.dataset.rel === M.rel[EQ.ri] ? null : { rel: b.dataset.rel }; eqDraw(); });
      const on = (id, fn) => { const b = c.querySelector('#' + id); if (b) b.onclick = fn; };
      const pay = (cost) => { if (M.merit < cost) return false; M.merit -= cost; sfx('win', 0.3); return true; };
      on('equp', () => { if (pay(upCostW(M.wpn))) { M.wpn++; EQ.swing = 0.6; saveSV(); eqDraw(); } }); on('eqarm', () => { if (pay(upCostW(M.arm))) { M.arm++; saveSV(); eqDraw(); } }); on('eqsad', () => { if (pay(upCostW(M.sad))) { M.sad++; saveSV(); eqDraw(); } });
      on('eqbuy', () => { const k = T.armor; if (pay(ARMORS[k].cost)) { M.armors.push(k); M.armor = k; EQ.trial = null; saveSV(); eqDraw(); } });
      on('eqon', () => { if (T.armor) M.armor = T.armor; if (T.hk) { M.hk = T.hk; M.horse = T.hk !== 'none'; } if (T.rel) M.rel = eqTrialL().rel; EQ.trial = null; sfx('accept', 0.3); saveSV(); eqDraw(); });
      on('eqoff', () => { M.rel.splice(EQ.ri, 1); EQ.trial = null; saveSV(); eqDraw(); });
      on('eqrot', () => { EQ.dir = { down: 'left', left: 'up', up: 'right', right: 'down' }[EQ.dir]; });
      on('reset', () => { resetSV(); closeCard(); worldEnter(); }); on('out', () => { closeCard(); wPanel(WS.near); });
      if (!EQ.raf) EQ.raf = requestAnimationFrame(eqLoop); }); }
  // 무장 화면 그림: 관우(입어 보는 갑옷 색) · 청룡언월도(가끔 휘두름) · 말 · 유물 패
  function eqLoop() { const cv = document.getElementById('eqc'); if (!cv || $('ov').hidden) { EQ.raf = 0; return; } EQ.raf = requestAnimationFrame(eqLoop); if (!NINJA) return;
    const g = cv.getContext('2d'), L = eqTrialL(), M = wSV(), t = performance.now() / 1000, Wc = cv.width, Hc = cv.height; g.setTransform(1, 0, 0, 1, 0, 0); g.imageSmoothingEnabled = false;
    const bgc = { wpn: ['#4a2a1a', '#8a4a24'], armor: ['#4a2a1a', '#8a4a24'], horse: ['#3a3020', '#7a6a3a'], rel: ['#3a1a1a', '#7a2a24'] }[EQ.tab], gr = g.createLinearGradient(0, 0, 0, Hc); gr.addColorStop(0, bgc[0]); gr.addColorStop(1, bgc[1]); g.fillStyle = gr; g.fillRect(0, 0, Wc, Hc);
    if (EQ.tab === 'wpn' || EQ.tab === 'armor') { const fl = 0.5 + 0.5 * Math.sin(t * 9); g.fillStyle = `rgba(255,150,60,${0.15 + 0.1 * fl})`; g.beginPath(); g.arc(Wc * 0.85, Hc * 0.75, 90, 0, 7); g.fill(); g.fillStyle = '#3a3a3a'; g.fillRect(Wc * 0.78, Hc * 0.72, 70, 26); g.fillStyle = '#2a2a2a'; g.fillRect(Wc * 0.8, Hc * 0.8, 46, 40); }
    g.fillStyle = 'rgba(0,0,0,0.28)'; g.beginPath(); g.ellipse(Wc / 2, Hc * 0.86, 150, 26, 0, 0, 7); g.fill();
    const hk = NS['gy_' + L.armor] || NS.p_guanyu, cx = Wc / 2, ride = L.hk !== 'none' && NS[HORSES[L.hk].spr], s = 9; EQ.swing = Math.max(0, EQ.swing - 1 / 60); if (EQ.swing <= 0 && Math.floor(t * 10) % 34 === 0) EQ.swing = 0.6;
    let hx, hy, side; if (ride) { const Hw = NS[HORSES[L.hk].spr], hw = 23 * s * 0.95, hh = hw * Hw.h / Hw.w, f = Math.floor(t * 2) % 2; side = EQ.dir === 'left' ? 'left' : 'right'; const hy0 = Hc * 0.86 - hh; g.save(); if (side === 'left') { g.translate(cx + hw / 2, hy0); g.scale(-1, 1); g.drawImage(Hw.fr[f], 0, 0, hw, hh); } else g.drawImage(Hw.fr[f], cx - hw / 2, hy0, hw, hh); g.restore();
      const rs = 16 * s * 0.85; const by = hy0 + hh * 0.32 + Math.sin(t * 3) * 2; if (hk.tall) drawRide(g, hk, side, cx + (side === 'left' ? 10 : -10), by, rs * 0.8); else g.drawImage(hk.frame(side, 0), cx - rs / 2 + (side === 'left' ? 10 : -10), hy0 - rs * 0.62 + Math.sin(t * 3) * 2, rs, rs); hx = cx + (side === 'left' ? -6 : 6); hy = hk.tall ? by - rs * 0.8 * 22 / 16 * 0.32 : hy0 - rs * 0.1; }
    else { const rs = 16 * s * 1.1, f = Math.floor(t * 2) % 2 ? 0 : 0; side = EQ.dir; drawW(g, hk, EQ.dir, f, cx - rs / 2, Hc * 0.86 - rs * (hk.tall ? 1.08 : 0.98) + Math.sin(t * 2.5) * 2, rs); hx = cx + (EQ.dir === 'left' ? -1 : 1) * (hk.tall ? 24 : 18); hy = Hc * 0.86 - rs * (hk.tall ? 0.6 : 0.42); }
    const sw = EQ.swing > 0 ? 1 - EQ.swing / 0.6 : -1, base = side === 'left' ? -2.3 : side === 'up' ? -1.35 : -0.85, a = sw >= 0 ? base + Math.sin(sw * Math.PI) * 2.6 * (side === 'left' ? -1 : 1) : base + Math.sin(t * 1.5) * 0.05;
    drawGuandao(g, hx, hy, a, 34 * 4.2, 4.2, wTier(M.wpn));
    L.rel.forEach((k, i) => { const ang = t * 0.8 + i / Math.max(1, L.rel.length) * 6.28, rx = cx + Math.cos(ang) * 170, ry = Hc * 0.42 + Math.sin(ang) * 40; g.fillStyle = 'rgba(255,230,150,0.25)'; g.beginPath(); g.arc(rx, ry, 30, 0, 7); g.fill(); g.fillStyle = '#e2b85a'; g.strokeStyle = '#1d1813'; g.lineWidth = 3; g.beginPath(); g.arc(rx, ry, 22, 0, 7); g.fill(); g.stroke(); g.fillStyle = '#2a1a10'; g.font = '700 26px "Gowun Batang", serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(RELICS[k].g, rx, ry + 1); });
    g.fillStyle = 'rgba(29,24,19,0.7)'; g.fillRect(0, Hc - 44, Wc, 44); g.fillStyle = '#fff2c0'; g.font = '700 24px "Gowun Batang", serif'; g.textAlign = 'center'; g.textBaseline = 'middle'; g.fillText(`관우 · ${ARMORS[L.armor].n} · 청룡언월도 Lv ${M.wpn}${L.hk !== 'none' ? ` · ${HORSES[L.hk].n}` : ''}`, Wc / 2, Hc - 22); }
