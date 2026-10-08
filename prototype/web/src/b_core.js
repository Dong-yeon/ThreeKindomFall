(function () {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const cv = $('cv'), ctx = cv.getContext('2d');
  // 싸움판(책장 한 장) 크기 — 세로 화면 기준
  const AW = 360, AH = 600;
  let W = 0, H = 0, DPR = 1, SC = 1, OX = 0, OY = 0;
  function resize() { DPR = Math.min(2, window.devicePixelRatio || 1); W = innerWidth; H = innerHeight; cv.width = Math.round(W * DPR); cv.height = Math.round(H * DPR); const top = 74; SC = Math.min(W / AW, (H - top - 8) / AH); OX = (W - AW * SC) / 2; OY = top + (H - top - AH * SC) / 2; }
  addEventListener('resize', resize); resize();
  const rnd = (a, b) => a + Math.random() * (b - a), pick = (a) => a[Math.floor(Math.random() * a.length)], clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
  let MODE = 'title'; // title | town | arena
  const setMode = (m) => { MODE = m; const ac = document.getElementById('act'); if (ac && m !== 'rope' && m !== 'army') ac.hidden = true; };

  // ═════════ 저장 ═════════
  const SAVE = 'bw_save1';
  const fresh = () => ({ v: 1, coins: 0, books: { heung: 1 }, leaves: 0, pets: {}, endings: {}, seals: [], beaten: {}, pos: { x: 20, y: 47, d: 'down' }, mapv: 4, picked: {}, revealed: {}, pet: null, load: { c: null, b1: null }, party: [], runs: 0, clears: 0, duels: { w: 0, l: 0 }, intro: false, name: '', opened: false, story: null });
  let SV = (() => { try { const s = JSON.parse(localStorage.getItem(SAVE)); return s && s.v === 1 ? s : null; } catch (e) { return null; } })() || fresh();
  if (!SV.load) SV.load = { c: SV.pets[SV.pet] ? SV.pet : 'haetae', w: null };
  { const L = SV.load, old = ['hat', 'armor', 'pants', 'shoes'].map((k) => L[k]).filter(Boolean); for (const k of ['hat', 'armor', 'pants', 'shoes']) delete L[k]; if (!('b1' in L)) L.b1 = old[0] || null; delete L.b2; if ('w' in L) { if (L.w && !L.b1) L.b1 = L.w; delete L.w; } if (L.b1 && L.b1 === L.c) L.c = null; }
  if (!SV.party) SV.party = Object.keys(SV.pets).slice(0, 5);
  const PARTY_MAX = 5;
  // 동행 기력: 싸움마다 100에서 시작, 기술을 쓸 때마다 줄고 0이면 지쳐 쉼(쉬는 동안 조금씩 회복). 교대한 소환수는 뒤에서 회복
  const STAMINA = { haetae: 20, heung: 25, nolbu: 7, swallow: 6, gumiho: 15, zhangfei: 20, zhuge: 15, liubei: 25, guanyu: 16, ytsoldier: 7 };
  if (SV.mapv !== 4) { SV.pos = { x: 20, y: 47, d: 'down' }; SV.mapv = 4; SV.picked = {}; }
  if (!SV.revealed) SV.revealed = {};
  if (!SV.picked) SV.picked = {};
  const saveSV = () => { try { localStorage.setItem(SAVE, JSON.stringify(SV)); } catch (e) {} };
  const resetSV = () => { SV = fresh(); if (!SV.picked) SV.picked = {}; if (!SV.revealed) SV.revealed = {}; saveSV(); };
  const BOOK_PRICE = 70, LEAVES_PER_BOOK = 5;
  const xpNeed = (lvl) => 30 + 20 * (lvl - 1);
  const petMul = (lvl) => 1 + 0.12 * (lvl - 1);
  function gainPetXP(id, v) { const P = SV.pets[id]; if (!P) return 0; let ups = 0; P.xp += v; while (P.xp >= xpNeed(P.lvl) && P.lvl < 20) { P.xp -= xpNeed(P.lvl); P.lvl++; ups++; } return ups; }

  // ═════════ 소환수 — 끝까지 읽은 책의 인물 ═════════
  const PETS = {
    haetae: { n: '해태', g: '해', c: '#e0b860', from: '책방 주인이 맡긴 첫 소환수', d: '1.3초마다 가까운 적에게 뛰어올라 내려쳐요(범위)', role: '범위', cd: 1.3 },
    heung: { n: '흥부', g: '흥', c: '#d8c070', from: '흥부전 · 착한 결말', d: '3초마다 주인 체력 5% 회복 + 박씨', role: '회복', cd: 3 },
    nolbu: { n: '놀부', g: '놀', c: '#a87a5a', from: '흥부전 · 욕심의 결말', d: '0.6초마다 엽전을 마구 던져요(연사)', role: '연사', cd: 0.6 },
    swallow: { n: '제비', g: '제', c: '#7a9ac0', from: '흥부전 · 날갯짓의 결말', d: '0.45초마다 따라가며 쪼아요(추적)', role: '추적', cd: 0.45 },
    gumiho: { n: '구미호', g: '구', c: '#e8904a', from: '책방 주인이 맡긴 첫 소환수', d: '1.4초마다 여우불 3개를 띄워 따라가며 날려요(추적)', role: '홀림', cd: 1.4 },
    // ── 삼국지연의(D-161): beh = 같은 행동 틀(해태 = 내려치기·도발, 구미호 = 유도 불씨, 흥부 = 회복, blade = 반달 베기)
    zhangfei: { n: '장비', g: '장', c: '#5a4a3a', from: '탁현의 장사', d: '1.3초마다 뛰어들어 장팔사모로 내려치고, 맞은 적은 2초 동안 장비만 노려요(장판교 고함)', role: '돌격', cd: 1.3, beh: 'haetae', body: 'counter' },
    zhuge: { n: '제갈량', g: '량', c: '#d8d0b8', from: '와룡', d: '1.4초마다 화공 불씨 3개를 띄워 휘어 따라가며 날려요', role: '책략', cd: 1.4, beh: 'gumiho', body: 'decoy' },
    liubei: { n: '유비', g: '유', c: '#c8b070', from: '돗자리 장수', d: '3초마다 주인 체력 5% 회복 + 쌍검을 던져요(인덕)', role: '인덕', cd: 3, beh: 'heung', body: 'guard' },
    guanyu: { n: '관우', g: '관', c: '#4a8a5a', from: '해량의 의인', d: '1.6초마다 청룡언월도로 반달 베기 — 적을 꿰뚫어요', role: '무예', cd: 1.6, beh: 'blade', body: 'greed' },
    ytsoldier: { n: '황건 졸개', g: '황', c: '#d8b040', from: '황건적', d: '수가 많아요', role: '무리', cd: 1, beh: 'nolbu', npc: true },
  };
  // 무기에 책갈피 — 날리는 책장에 인물이 책갈피로 꽂혀 공격 방식이 바뀜(판 밖에서 정함). 책장의 힘은 그 위에 쌓임
  const WEAP = {
    none: { n: '맨 책장', d: '곧게 날아가는 책장', rate: 2.2, mul: 1, form: 'line' },
    haetae: { n: '해태 부채', d: '가까이서 글자 3개를 부채꼴로 + 덮치기(멈추면 가까운 적에게 한 걸음 들어감) — 사거리 짧고 셈', rate: 1.7, mul: 0.7, form: 'fan', range: 165 },
    heung: { n: '박씨 폭탄', d: '느린 박씨가 맞거나 멈추면 터져 둘레에 피해', rate: 1.1, mul: 1.5, form: 'bomb' },
    nolbu: { n: '엽전 연사', d: '엽전을 빠르게 흩뿌려요 — 약하지만 많이', rate: 4.6, mul: 0.52, form: 'spray' },
    swallow: { n: '제비 깃털', d: '따라가는 깃털 — 잘 맞지만 약하고, 날쌘 상대는 피함', rate: 2.3, mul: 0.75, form: 'homing' },
    gumiho: { n: '여우불 글자', d: '글자가 여우불이 되어 휘어 따라가요 — 벽 뒤 적도 노림', rate: 2.0, mul: 0.62, form: 'homing' },
    zhangfei: { n: '장팔사모', d: '가까이서 글자 3개를 부채꼴로 + 덮치기 — 사거리 짧고 셈', rate: 1.7, mul: 0.7, form: 'fan', range: 165 },
    zhuge: { n: '화공 글자', d: '글자가 불씨가 되어 휘어 따라가요 — 벽 뒤 적도 노림', rate: 2.0, mul: 0.62, form: 'homing' },
    liubei: { n: '쌍고검', d: '느린 쌍검이 맞거나 멈추면 터져 둘레에 피해', rate: 1.1, mul: 1.5, form: 'bomb' },
    guanyu: { n: '청룡언월도', d: '곧게 날아가는 큰 글자 — 공격력 +20%', rate: 2.0, mul: 1.2, form: 'line' },
  };
  const DASH = { dist: 72, time: 0.14, inv: 0.26, cd: 1.0 };
  // 책갈피 꽂기는 두 손에만(사용자 결정) — 오른손 = 책장(무기, 공격 방식), 왼손 = 방어·보조(아래 BODY 효과). 샤먼킹의 칼+방패 두 매개체 구조.
  // 효과는 소환수가 정함. 숫자만 오르는 효과 없이 행동이 바뀌는 효과만. 단계가 오르면 효과가 세짐(petMul)
  const GEAR_SLOTS = ['b1'];
  const BODY = {
    haetae: { n: '해태 방패', d: '앞에서 날아오는 탄 하나를 막아 쏜 쪽으로 되돌려 보내요(2.2초마다) — 멈춰 쏠 때 앞을 지켜 줌' },
    heung: { n: '박의 보살핌', d: '왼손의 박 — 한 판에 한 번, 체력이 30% 아래로 떨어지면 박이 터지며 체력 회복' },
    nolbu: { n: '놀부의 욕심', d: '왼손의 엽전 주머니 — 멈춰 있을수록 공격이 세져요(1초에 +20%, 최대 +40%), 움직이면 처음부터' },
    swallow: { n: '제비 깃부채', d: '구르기 재사용이 빨라지고(−35%) 더 멀리 굴러요(+30%)' },
    gumiho: { n: '구미호 둔갑', d: '구르면 그 자리에 분신이 남아 1.5초 동안 적이 분신을 노려요' },
    zhangfei: { n: '장판교 버티기', d: '앞에서 날아오는 탄 하나를 막아 되돌려요(2.2초마다)' },
    zhuge: { n: '짚단 허수아비', d: '구르면 그 자리에 허수아비가 남아 1.5초 동안 적이 그쪽을 노려요' },
    liubei: { n: '인덕', d: '한 판에 한 번, 체력이 30% 아래로 떨어지면 크게 회복' },
    guanyu: { n: '의기', d: '멈춰 있을수록 공격이 세져요(최대 +40%)' },
  };
  const bodyOpen = (k) => k === 'b1';
  // 왼손 효과 묶음(나·상대 공용): 값은 그 소환수 단계
  function bodyOf(list) { const g = { counter: 0, guard: 0, greed: 0, wing: 0, decoy: 0 }; for (const p of list) { if (!p) continue; const k = (PETS[p.id] && PETS[p.id].body) || { haetae: 'counter', heung: 'guard', nolbu: 'greed', swallow: 'wing', gumiho: 'decoy' }[p.id]; if (k) g[k] = Math.max(g[k], p.lvl); } return g; }
  const auraColors = () => GEAR_SLOTS.filter((k) => bodyOpen(k) && SV.load[k] && PETS[SV.load[k]]).map((k) => PETS[SV.load[k]].c);
  const myBody = () => bodyOf(GEAR_SLOTS.filter((k) => bodyOpen(k) && SV.load[k] && SV.pets[SV.load[k]]).map((k) => ({ id: SV.load[k], lvl: SV.pets[SV.load[k]].lvl })));
  // 책장의 힘(책 한 번 읽는 동안만)
  const POW = {
    multi: { n: '겹장', d: '책장을 하나 더 날려요', ic: '겹' }, back: { n: '앞뒤 낭독', d: '뒤로도 책장을 날려요', ic: '뒤' }, diag: { n: '사선 낭독', d: '양옆 비스듬히 2장 더', ic: '사' },
    pierce: { n: '꿰뚫는 책장', d: '책장이 적 하나를 뚫고 지나가요', ic: '뚫' }, rate: { n: '빠른 넘김', d: '공격 속도 +25%', ic: '빠' }, dmg: { n: '굵은 활자', d: '공격력 +25%', ic: '굵' },
    hpup: { n: '단단한 표지', d: '최대 체력 +25, 그만큼 회복', ic: '표' }, leech: { n: '쪽 빨아들이기', d: '적을 쓰러뜨릴 때마다 체력 +3', ic: '흡' }, petup: { n: '소환 공명', d: '펫 공격 +60%, 더 자주', ic: '공' },
    speed: { n: '가벼운 발', d: '이동 속도 +15%', ic: '발' }, heal: { n: '회복의 쪽', d: '체력 45% 회복', ic: '회' },
    // 궁수의 전설식 기믹(책 맛으로)
    through: { n: '스며드는 책장', d: '책장이 책더미 벽을 뚫고 지나가요', ic: '스', once: true }, bounce: { n: '튕기는 책장', d: '벽·가장자리에 닿으면 튕겨요(2번, 튕길 때마다 피해 −30%)', ic: '튕' },
    chain: { n: '이어 읽기', d: '맞힌 뒤 가까운 다른 적에게 이어져요(피해 −30%)', ic: '이' }, ink: { n: '번지는 먹물', d: '맞은 적이 3초 동안 먹물 피해(초당 공격력의 25%)', ic: '먹' },
    frost: { n: '얼어붙은 문장', d: '맞은 적이 1.2초 동안 느려져요(−45%)', ic: '얼' }, bolt: { n: '번개 문장', d: '맞힐 때 30% 확률로 근처 적 2명에게 번개(공격력 60%)', ic: '번' },
    orbit: { n: '맴도는 쪽지', d: '쪽지 2개가 둘레를 돌며 닿는 적을 베어요', ic: '맴' }, nova: { n: '마침표', d: '적이 쓰러지면 그 자리가 터져 둘레에 피해(공격력 80%)', ic: '마' },
    extra: { n: '덧붙인 쪽', d: '이번 독서에서 한 번, 쓰러져도 체력 50%로 다시 일어나요', ic: '덧', once: true },
    magnet: { n: '책장 자석', d: '글자 조각을 더 멀리서 끌어와요', ic: '자', surv: true },
  };
  // 적: 책에서 새어 나온 조각들
  const EN = {
    wisp: { n: '도깨비불', c: '#6a8ac8', r: 11, hp: 28, spd: 76, touch: 10, ai: 'chase', say: ['휴…', '시원하다!', '어디 갔었지?'] },
    crow: { n: '까치', c: '#3a3a4a', r: 10, hp: 25, spd: 60, touch: 9, ai: 'dash', say: ['깍깍!', '반가운 손님!', '깍?'] },
    vine: { n: '박 넝쿨', c: '#5a8a3a', r: 15, hp: 54, spd: 0, touch: 7, ai: 'turret', say: ['사르륵…', '햇볕 좋다'] },
    servant: { n: '놀부네 머슴', c: '#8a6a4a', r: 15, hp: 76, spd: 38, touch: 12, ai: 'shooter', say: ['어, 내가 왜 이랬지?', '머리가 맑아졌어…'] },
    boss: { n: '놀부의 도깨비 박', c: '#e8dcb0', r: 38, hp: 1300, spd: 26, touch: 18, ai: 'boss' },
    // 황건적(먹물에 물든 군사)
    ytb: { n: '황건 졸개', c: '#d8b040', r: 10, hp: 26, spd: 74, touch: 9, ai: 'chase', say: ['어, 내가 왜 칼을…', '집에 가고 싶다', '휴…'] },
    ytarch: { n: '황건 궁수', c: '#c89a30', r: 11, hp: 30, spd: 40, touch: 8, ai: 'shooter', say: ['활이 무겁네…', '농사나 짓자'] },
    ytcav: { n: '황건 기병', c: '#a8782a', r: 12, hp: 30, spd: 60, touch: 11, ai: 'dash', horse: 'a_horseBS', rider: 'e_ytb', say: ['워워!', '말이 놀랐어'] },
    ytbig: { n: '황건 역사', c: '#e2b85a', r: 15, hp: 90, spd: 34, touch: 14, ai: 'chase', say: ['힘만 셌지 뭐…', '머리가 맑아졌어'] },
    cyz: { n: '황건 장수 정원지', c: '#d89a3a', r: 18, hp: 420, spd: 46, touch: 16, ai: 'shooter', say: ['…졌다. 먹물이 걷히는구나'] },
    zj: { n: '천공장군 장각', c: '#e2c060', r: 30, hp: 1500, spd: 28, touch: 18, ai: 'boss', walker: true },
  };
  // 흥부전 ★1 — 책장 9장
  const PAGES = [
    { t: '흥부네 초가 앞', en: [['wisp', 4]], pow: 1 },
    { t: '박골 들길', en: [['wisp', 4], ['vine', 1], ['crow', 1]], pow: 1 },
    { t: '굶는 식구들', en: [['wisp', 3], ['crow', 3]], story: '초가에서 흥부네 아이들 우는 소리가 들려요.', doors: [{ l: '주먹밥을 나눈다', g: { kind: 2 } }, { l: '놀부네 곳간을 엿본다', g: { greed: 2 } }] },
    { t: '처마 밑', en: [['crow', 3], ['vine', 1], ['wisp', 2]], story: '다리 다친 제비가 처마 밑에 떨어져 있어요.', pow: 1, doors: [{ l: '제비 다리를 묶어 준다', g: { swift: 2 } }, { l: '서둘러 지나간다', g: { greed: 1 } }] },
    { t: '놀부네 담장', en: [['servant', 3], ['wisp', 3]], pow: 1 },
    { t: '박 넝쿨 숲', en: [['vine', 2], ['servant', 2], ['crow', 4]] },
    { t: '열린 박', en: [['servant', 3], ['wisp', 5]], story: '지붕 위 커다란 박이 금빛으로 빛나요.', pow: 1, doors: [{ l: '흥부와 함께 박을 탄다', g: { kind: 2 } }, { l: '박을 몰래 가져간다', g: { greed: 2 } }, { l: '제비를 따라 남쪽 하늘로', g: { swift: 2 } }] },
    { t: '놀부네 마당', en: [['servant', 3], ['vine', 2], ['crow', 4], ['wisp', 3]], pow: 1 },
    { t: '놀부의 도깨비 박', boss: true },
  ];
  // 낭독: 멈춰 서서 읽으면 그 이야기의 글자가 날아감(D-156)
  const GLYPHS = ['유', '관', '장', '의', '충', '용', '인', '덕', '도', '원', '천', '하'];
  // 황건적 토벌 결말(고른 길: kind = 인(백성) · greed = 공(군량·공) · swift = 용(돌격))
  const ENDINGS_YT = { kind: { pet: 'liubei', t: '인의 결말', txt: '백성을 먼저 지킨 의병의 소문이 퍼져, 돗자리 장수 유비가 뜻을 함께하겠다며 찾아와요.' }, greed: { pet: 'guanyu', t: '공의 결말', txt: '군량과 공을 쌓아 이름을 떨치자, 수염 긴 장사 관우가 솜씨를 겨루러 와서 그대로 남아요.' }, swift: { pet: 'zhangfei', t: '용의 결말', txt: '앞장서 장각의 진을 꿰뚫자, 고기 장수 장비가 껄껄 웃으며 술잔을 내밀어요.' } };
  const ENDINGS = { kind: { pet: 'heung', t: '착한 결말', txt: '흥부네 지붕마다 박이 열리고, 굶던 아이들이 배불리 웃어요.' }, greed: { pet: 'nolbu', t: '욕심의 결말', txt: '금은보화를 끌어안은 놀부가 웃어요. 박 속에서 도깨비가 고개를 숙이네요.' }, swift: { pet: 'swallow', t: '날갯짓의 결말', txt: '은혜를 갚은 제비가 남쪽 하늘로 높이 날아올라요.' } };

  // ═════════ 북 대결 상대 — 성격 = AI 가중치 묶음 (duel-ai.md) ═════════
  const FOES = {
    reader1: { n: '책벌레 도윤', g: '윤', c: '#9ab0d8', hp: 170, atk: 6, rate: 1.5, spd: 115, shotSp: 330, pets: [{ id: 'swallow', lvl: 1 }], weapon: null, bestOf: 1, reward: 40,
      ai: { think: 0.3, react: 0.35, err: 20, lead: 0.4, look: 0.35, greed: 0.3, range: 175, margin: 3, punish: 1, recover: 0.35, W: { danger: 3.2, range: 0.05, wall: 1.2, shoot: 18, pet: 1.0 } },
      hi: ['어, 너도 책 읽는구나!', '이야기 줄다리기 한 판 할래? 난 거짓말 못 해. 단판 승부야!'], lose: ['으앗… 기색을 너무 솔직하게 보였나 봐.', '옛이야기관 사서장님은 기색으로 속여. 조심해!'], win: ['헤헤, 내가 이겼다! 소환수를 더 키워서 와.'] },
    reader2: { n: '이야기꾼 소리', g: '소', c: '#d89a6a', hp: 200, atk: 7, rate: 1.6, spd: 120, shotSp: 340, pets: [{ id: 'nolbu', lvl: 2 }], weapon: null, bestOf: 1, reward: 50,
      ai: { think: 0.26, react: 0.3, err: 16, lead: 0.5, look: 0.4, greed: 0.25, range: 165, margin: 3, punish: 1, recover: 0.35, W: { danger: 3.4, range: 0.05, wall: 1.2, shoot: 18, pet: 1.0 } },
      hi: ['이야기 하나 들려줄까? 놀부가 기운을 모으고 또 모으는 이야기!', '단판이야. 덤벼!'], lose: ['내 이야기가 끝나 버렸네…', '보람이는 처음부터 기운을 들고 와. 큰 읽기가 올 땐 막아!'], win: ['이야기는 내가 더 길었네! 다음에 또 와.'] },
    reader3: { n: '꼬마 사서 보람', g: '보', c: '#b0a0d8', hp: 220, atk: 7, rate: 1.6, spd: 125, shotSp: 340, pets: [{ id: 'heung', lvl: 2 }], weapon: { id: 'nolbu', lvl: 1 }, body: [{ id: 'nolbu', lvl: 1 }], bestOf: 1, reward: 60,
      ai: { think: 0.22, react: 0.28, err: 13, lead: 0.6, look: 0.45, greed: 0.2, range: 170, margin: 4, punish: 1, recover: 0.3, W: { danger: 3.8, range: 0.05, wall: 1.3, shoot: 20, pet: 1.1 } },
      hi: ['나도 언젠간 사서장이 될 거야.', '놀부 책갈피를 꽂았어 — 기운 하나 들고 시작하지. 단판 승부!'], lose: ['으으… 책갈피를 다시 생각해 봐야겠다.', '사서장님은 해태로 막기를 노려. 기운을 모으면 막기가 헛수가 돼!'], win: ['헤헤, 책갈피 꽂기는 내가 한 수 위!'] },
    keeper1: { n: '옛이야기관 사서장 먹선', g: '먹', c: '#c08a6a', hp: 400, atk: 9, rate: 2.0, spd: 142, shotSp: 400, pets: [{ id: 'nolbu', lvl: 3 }, { id: 'swallow', lvl: 3 }, { id: 'nolbu', lvl: 3 }], weapon: { id: 'haetae', lvl: 2 }, body: [{ id: 'haetae', lvl: 2 }], bestOf: 3, reward: 120, seal: '옛이야기 인장',
      ai: { think: 0.12, react: 0.18, err: 7, lead: 0.9, look: 0.55, greed: 0.08, range: 115, margin: 5, punish: 1.1, recover: 0.3, W: { danger: 4.5, range: 0.07, wall: 1.6, shoot: 22, pet: 1.4 } },
      hi: ['옛이야기관에 온 걸 환영하네.', '북 대결은 이야기 줄다리기 — 줄을 자네 쪽 끝까지 끌어오면 이기네.', '내 기색은 믿지 말게. 자네 버릇은 내가 읽을 테니.', '해태 책갈피를 꽂았네 — 막으면 크게 되받아치지. 셋 중 둘을 먼저 이기면 인장을 주겠네. 소환수는 놀부, 제비, 다시 놀부일세.'], lose: ['허허… 책을 제대로 읽었구먼.', '옛이야기 인장을 받게. 다음 고을 책방에 더 깊은 책이 들어올 걸세.'], win: ['아직 이야기가 덜 쌓였네. 소환수를 더 키워 오게.'] },
    cyz: { n: '황건 장수 정원지', g: '정', c: '#d89a3a', hp: 300, atk: 8, rate: 1.6, spd: 120, shotSp: 340, pets: [{ id: 'ytsoldier', lvl: 2 }], weapon: null, bestOf: 1, reward: 0,
      ai: { think: 0.3, react: 0.3, err: 16, lead: 0.5, look: 0.4, greed: 0.25, range: 170, margin: 3, punish: 1, recover: 0.35, W: { danger: 3.2, range: 0.05, wall: 1.2, shoot: 18, pet: 1.0 } },
      hi: ['나는 황건의 장수 정원지! 일기토로 승부를 내자!'], lose: ['크윽… 먹물이 걷히니 내가 왜 싸웠는지 모르겠구나.'], win: ['하하! 다음엔 더 단단히 오너라!'] },
  };
