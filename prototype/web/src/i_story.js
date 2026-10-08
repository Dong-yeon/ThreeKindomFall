  // ═════════ 책 속 이야기 — 흥부전 1장 「쫓겨난 흥부네」 (D-154·155·156) ═════════
  // 걷고 · 말 걸고 · 줍고 · 건네며 푼다. 방법 4가지(하나만 해도 됨). 싸움은 이야기가 부를 때만(곳간 머슴 · 뒷산 먹물 얼룩), 모두 피할 수 있음
  const jo = (w, a, b) => { w = String(w || ''); const c = w.charCodeAt(w.length - 1); return c >= 0xac00 && c <= 0xd7a3 && (c - 0xac00) % 28 ? a : b; };
  const MIND = { kind: '착함', wit: '꾀', greed: '욕심', swift: '날램' };
  const IT = {
    bam: { n: '밤 한 톨', d: '밤나무 아래에서 주운 밤' },
    bapal: { n: '밥알', d: '놀부 아내의 주걱에 맞고 뺨에 붙은 밥알 몇 톨', food: 'kind' },
    ssal: { n: '쌀 한 되', d: '장터 심부름 품삯', food: 'wit' },
    sum: { n: '쌀 한 섬', d: '놀부네 곳간에서 짊어지고 나온 쌀', food: 'greed' },
    namul: { n: '나물', d: '뒷산에서 캔 나물 — 다섯 줌이면 죽을 쑬 수 있어요', food: 'swift' },
    jim: { n: '짐 보따리', d: '짐꾼이 주막 주인에게 갖다 달래요' },
    yeot: { n: '엿', d: '엿장수가 장터 아래쪽 아이에게 갖다 달래요' },
    coin: { n: '엽전 꾸러미', d: '장터 할머니가 잃어버린 엽전' },
    bone: { n: '뼈다귀', d: '주막에서 얻은 뼈다귀 — 개가 좋아할 것 같아요' },
  };
  const CH1 = {
    title: '흥부전 1장 「쫓겨난 흥부네」', short: '흥부전 1장 · 쫓겨난 흥부네',
    rows: ["TTTTTTTTTTTTTTTTTTTTTTTTTTTT", "TTTTTTTTTTTTTTTTTTTTTTTTTTTT", "TT:::T##################..TT", "TTT:::#BBB.BBBBBB.#.BBB#.TTT", "TT::T:#BBB.BBBBBB.#.BBB#..TT", "TT::::#BBB.BBBBBB.#.BBB#:.TT", "TT::::#.=.f...==.f#dddd..TTT", "TT:T::#.=.....==..#dddd#..TT", "TT::::#.========..#dddd#..TT", "TT:::T#.......==.f#dddd#.:TT", "TT::::#...f...==..#dddd#..TT", "TTT:::#.......==..#dddd#..TT", "TT::::#jj.....=====dddd#..TT", "TT::T:#j..T.f.==..#cddc#..TT", "TT::::#.......==..#dddd#T.TT", "TT::::########==########.TTT", "TT:T::........==..........TT", "TT::::T:::::..==.....BBBB.TT", "TT:T::::::::f.==.T...BBBB.TT", "TT:::::::T::..==....=BBBB.TT", "TT:::::::::T..==....====..TT", "TTT::::T::::..==.jj.=.....TT", "TT::T:::::::..==....=.f.j.TT", "TT:::s:::T::.s==.f..=....jTT", "TT:::=====================TT", "TT:::=====================TT", "TT::::::::::..==s...=.....TT", "TT::T::::::T..==....=BBBB.TT", "TT::::::T:::..==.cc.=BBBB.TT", "TT::::::::::..==....=BBBB.TT", "TTT:::::::::.f==....====..TT", "TT::::::::T:..==..f.=.....TT", "TT::::T:::::..==.........TTT", "TT:T::::::::..==T.........TT", "TT.........BBB==....T.....TT", "TT..T..T...BBB==...T....f.TT", "TT.........BBB==......T...TT", "TT....f..===========......TT", "TT.T...f.===========......TT", "TT.........dddddd...f.....TT", "TT...T.....ddddddf.....T..TT", "TT......T.................TT", "TTTTTTTTTTTTTTTTTTTTTTTTTTTT", "TTTTTTTTTTTTTTTTTTTTTTTTTTTT"],
    houses: [
      { id: 'kitchen', x: 7, y: 3, w: 3, h: 3, set: 'houseO', label: '부엌', doors: [1] },
      { id: 'manor', x: 11, y: 3, w: 6, h: 3, set: 'houseR', label: '놀부네', doors: [3] },
      { id: 'store', x: 20, y: 3, w: 3, h: 3, set: 'houseB', label: '곳간', doors: [1] },
      { id: 'inn', x: 21, y: 17, w: 4, h: 3, set: 'houseB', label: '주막', doors: [1] },
      { id: 'rice', x: 21, y: 27, w: 4, h: 3, set: 'houseB', label: '쌀가게', doors: [1] },
      { id: 'hut', x: 11, y: 34, w: 3, h: 3, set: 'houseO', label: '', doors: [1] },
    ],
    start: { x: 17, y: 37, d: 'left' },
  };
  CH1.h = CH1.rows.length; CH1.w = CH1.rows[0].length;
  const CHK = { T: 'tree', '.': 'grass', ':': 'bush', '=': 'path', '#': 'fence', j: 'jar', c: 'chest', s: 'sign', f: 'flower', d: 'dirt', B: 'grass' };
  const SG = CH1.rows.map((r) => [...r].map((c) => CHK[c] || 'grass'));
  const SSOL = CH1.rows.map((r) => [...r].map((c) => 'T#jcsB'.includes(c)));
  const SDOOR = {}; for (const b of CH1.houses) for (const d of b.doors) SDOOR[`${b.x + d},${b.y + b.h - 1}`] = b.id;
  const SSIGN = {
    '13,23': ['「갈림길」', '↑ 놀부네 기와집 · ← 뒷산 · → 장터 · ↓ 흥부네 움막'],
    '5,23': ['「뒷산」', '나물이 많이 나요. 요즘 시커먼 먹물 얼룩이 돌아다닌대요 — 닿으면 싸움, 피해 가도 돼요.'],
    '16,26': ['「장터」', '장날! 쌀가게에서 일손 구함.'],
  };
  // 사람들(움직이지 않음). 머슴은 고개를 돌리며 3칸을 봄
  const SN = [
    { id: 'heung', x: 10, y: 36, dir: 'right', spr: 'p_heung', n: '흥부' },
    { id: 'wife', x: 16, y: 39, dir: 'left', spr: 'reader2', n: '흥부 아내' },
    { id: 'baby', x: 12, y: 40, dir: 'up', spr: 'kid', n: '흥부네 막내' },
    { id: 'girl', x: 14, y: 40, dir: 'up', spr: 'n_girl', n: '흥부네 큰딸' },
    { id: 'nolbu', x: 12, y: 11, dir: 'down', spr: 'p_nolbu', n: '놀부' },
    { id: 'nwife', x: 9, y: 7, dir: 'down', spr: 'n_nwife', n: '놀부 아내' },
    { id: 'guard', x: 21, y: 9, dir: 'up', spr: 'e_servant', n: '놀부네 머슴' },
    { id: 'dog', x: 23, y: 6, dir: 'left', spr: 'a_dog', n: '누렁이' },
    { id: 'porter', x: 18, y: 19, dir: 'down', spr: 'n_porter', n: '짐꾼' },
    { id: 'inn', x: 24, y: 20, dir: 'left', spr: 'n_inn', n: '주막 주인' },
    { id: 'yeot', x: 19, y: 21, dir: 'down', spr: 'n_yeot', n: '엿장수' },
    { id: 'kid', x: 17, y: 31, dir: 'down', spr: 'reader1', n: '장터 아이' },
    { id: 'granny', x: 23, y: 23, dir: 'down', spr: 'n_granny', n: '장터 할머니' },
    { id: 'rice', x: 19, y: 28, dir: 'down', spr: 'n_rice', n: '쌀가게 주인' },
  ];
  // 땅에 떨어진 것(밟으면 줍기)
  const SP = [
    { id: 'bam', x: 19, y: 36, it: 'bam' },
    { id: 'n1', x: 3, y: 20, it: 'namul' }, { id: 'n2', x: 10, y: 18, it: 'namul' }, { id: 'n3', x: 8, y: 22, it: 'namul' }, { id: 'n4', x: 6, y: 29, it: 'namul' }, { id: 'n5', x: 9, y: 32, it: 'namul' }, { id: 'n6', x: 3, y: 27, it: 'namul' },
    { id: 'coin', x: 12, y: 21, it: 'coin', when: () => ST.f.grannyAsked },
  ];
  const BLOTS0 = [{ id: 'b1', x: 4, y: 19 }, { id: 'b2', x: 9, y: 27 }, { id: 'b3', x: 6, y: 31 }];
  const HILL = { x0: 2, y0: 17, x1: 11, y1: 33 };
  const GSEQ = [['up', 1.6], ['right', 1.2], ['down', 2.0], ['left', 1.4]];
  const METHOD = { kind: '놀부네 부엌 — 주걱 맞고 얻은 밥알', wit: '장터 심부름 — 품삯 쌀 한 되', greed: '놀부네 곳간 — 쌀 한 섬', swift: '뒷산 — 나물 다섯 줌으로 쑨 나물죽' };
  const HINT = { kind: '놀부네 부엌에서 밥 냄새가 났는데…', wit: '장터에 일손이 모자란대요…', greed: '놀부네 곳간엔 쌀이 산더미래요. 머슴 눈만 피하면?', swift: '뒷산엔 나물이 많대요. 먹물 얼룩만 조심하면…' };

  let ST = null, Q = null; // ST = 저장되는 진행(SV.story), Q = 화면 상태
  const newStory = () => ({ ch: 1, x: CH1.start.x, y: CH1.start.y, d: CH1.start.d, inv: {}, f: {}, mind: { kind: 0, wit: 0, greed: 0, swift: 0 }, fed: [], got: {}, blots: {}, step: 0, thread: null, done: false });
  const has = (it) => (ST.inv[it] || 0) > 0;
  function addItem(it, n = 1) { ST.inv[it] = (ST.inv[it] || 0) + n; }
  function useItem(it, n = 1) { ST.inv[it] = Math.max(0, (ST.inv[it] || 0) - n); if (!ST.inv[it]) delete ST.inv[it]; }
  function gainMind(k, v) { ST.mind[k] += v; banner(`${MIND[k]} +${v}`, '내가 한 일이 결말을 바꿔요'); }
  const npcXY = (id) => { if (id === 'dog' && ST.f.dogFed) return [24, 7]; const n = SN.find((q) => q.id === id); return [n.x, n.y]; };
  const sNpcAt = (x, y) => SN.find((n) => { const [nx, ny] = npcXY(n.id); return nx === x && ny === y; });
  const sPass = (x, y) => x >= 0 && y >= 0 && x < CH1.w && y < CH1.h && !SSOL[y][x] && !sNpcAt(x, y);
  const errands = () => (ST.f.jimDone ? 1 : 0) + (ST.f.yeotDone ? 1 : 0) + (ST.f.coinDone ? 1 : 0);
  const foodsIn = () => ['bapal', 'ssal', 'sum', 'namul'].filter((k) => k === 'namul' ? (ST.inv.namul || 0) >= 5 : has(k));
  const saveST = () => { ST.x = Q.x; ST.y = Q.y; ST.d = Q.dir; SV.story = ST; saveSV(); };

  // ── 지금 할 일 + 금빛 ▼ 대상(칸 좌표 목록)
  function goal() {
    const f = ST.f, P = npcXY;
    if (ST.done) return { t: '1장을 다 읽었어요 — 가방에서 다시 읽을 수 있어요', tg: [] };
    if (ST.step === 0) return { t: '흥부에게 말 걸기', tg: [P('heung')] };
    if (ST.step <= 2) return has('bam') ? { t: '배고픈 막내에게 밤 건네기', tg: [P('baby')] } : { t: '밤나무 아래 떨어진 밤 줍기', tg: [[19, 36]] };
    const fs = foodsIn(), ag = areaGoal();
    if (ag) { if (fs.length) { ag.t += ' · 먹을 것은 흥부 아내에게'; ag.tg.push(P('wife')); } return ag; }
    if (fs.length) return { t: '흥부 아내에게 먹을 것 건네기', tg: [P('wife')] };
    if (ST.fed.length) return { t: '흥부에게 말 걸면 1장을 마쳐요(다른 방법도 해 봐도 돼요)', tg: [P('heung')] };
    return { t: '먹을 것 구하기 — 놀부네 · 장터 · 뒷산 중 하나', tg: [[14, 15], [16, 25], [5, 24]] };
  }
  // 지금 있는 곳(마지막으로 들른 곳)의 다음 할 일 — 끝났으면 null
  function areaGoal() {
    const f = ST.f, P = npcXY, th = ST.thread;
    if (th === 'nolbu' && !f.slapped && !has('bapal') && !ST.fed.includes('kind')) return f.askedNolbu ? { t: '부엌 앞 놀부 아내 찾아가기', tg: [P('nwife')] } : { t: '놀부에게 부탁하기', tg: [P('nolbu')] };
    if (th === 'store' && !f.tookSum) { const tg = [[21, 5]]; if (has('bone') && !f.dogFed) tg.push(P('dog')); return { t: f.guardFree ? '곳간 문 열기' : '머슴 눈(빨간 칸)을 피해 곳간 문으로', tg }; }
    if (th === 'market' && !f.gotRice) {
      if (!f.job) return { t: '쌀가게 주인에게 일 구하기', tg: [P('rice')] };
      const n = errands();
      if (n < 3) { const tg = []; if (!f.jimDone) tg.push(has('jim') ? P('inn') : P('porter')); if (!f.yeotDone) tg.push(has('yeot') ? P('kid') : P('yeot')); if (!f.coinDone) tg.push(has('coin') ? P('granny') : f.grannyAsked ? [12, 21] : P('granny')); return { t: `장터 심부름 ${n}/3 — 짐 · 엿 · 엽전`, tg }; }
      return { t: '쌀가게 주인에게 품삯 받기', tg: [P('rice')] };
    }
    if (th === 'hill' && !ST.fed.includes('swift')) { const n = ST.inv.namul || 0; if (n < 5) { const left = SP.filter((p) => p.it === 'namul' && !ST.got[p.id]).sort((a, b) => (Math.abs(a.x - Q.x) + Math.abs(a.y - Q.y)) - (Math.abs(b.x - Q.x) + Math.abs(b.y - Q.y))); return { t: `뒷산에서 나물 캐기 ${n}/5 · 먹물 얼룩은 피하거나 지우기`, tg: left.slice(0, 2).map((p) => [p.x, p.y]) }; } }
    return null;
  }
  function areaThread(x, y) { if (x >= 19 && x <= 25 && y >= 2 && y <= 14) return 'store'; if (x >= 7 && x <= 17 && y >= 3 && y <= 14) return 'nolbu'; if (x >= 16 && y >= 17 && y <= 33) return 'market'; if (x >= HILL.x0 && x <= HILL.x1 && y >= HILL.y0 && y <= HILL.y1) return 'hill'; return null; }

  // ── 시작·이어 읽기
  function storyStart(resume, from) {
    if (!SV.story) SV.story = newStory(); ST = SV.story; closeCard(); $('talk').hidden = true; const fromWas = Q && Q.from;
    Q = { from: from || fromWas || 'title', x: ST.x, y: ST.y, px: ST.x, py: ST.y, dir: ST.d || 'up', moving: false, fromX: 0, fromY: 0, t: 0, step: 0, time: 0, shake: 0, turnT: resume ? 0 : 1.1, flashT: 0, flashCb: null, bang: null, gi: 0, gt: GSEQ[0][1], grace: 1, blots: [] };
    const [dx, dy] = DV[Q.dir]; Q.petX = Q.petPX = Q.x - dx; Q.petY = Q.petPY = Q.y - dy; if (!sPass(Q.petX, Q.petY)) { Q.petX = Q.petPX = Q.x; Q.petY = Q.petPY = Q.y; }
    for (const b of BLOTS0) if (!ST.blots[b.id]) Q.blots.push({ id: b.id, x: b.x, y: b.y, px: b.x, py: b.y, fx: b.x, fy: b.y, t: 1, next: 1, ph: Math.random() * 6 });
    setMode('story'); music('road'); joy.on = false; inputLock = false; $('hud').hidden = false; $('hpw').style.display = 'none'; storyHud(); saveST();
    setTimeout(() => banner(CH1.title, resume ? '이어서 읽어요' : '화면을 끌면 걸어요 · 금빛 ▼을 따라가요'), resume ? 100 : 700);
  }
  // ── 걷기
  const SSTEP = 0.16;
  function sTryMove(dir) {
    Q.dir = dir; const [dx, dy] = DV[dir], nx = Q.x + dx, ny = Q.y + dy, key = `${nx},${ny}`;
    if (SDOOR[key]) return sDoor(SDOOR[key]);
    if (SSIGN[key]) return talk('', SSIGN[key]);
    const n = sNpcAt(nx, ny); if (n) return sTalk(n);
    if (!sPass(nx, ny)) return;
    Q.fromX = Q.x; Q.fromY = Q.y; Q.petFX = Q.petX; Q.petFY = Q.petY; Q.petX = Q.x; Q.petY = Q.y; Q.x = nx; Q.y = ny; Q.moving = true; Q.t = 0; Q.step ^= 1;
  }
  function sArrived() {
    const th = areaThread(Q.x, Q.y); if (th && ST.step >= 3) ST.thread = th;
    const p = SP.find((q) => q.x === Q.x && q.y === Q.y && !ST.got[q.id] && (!q.when || q.when()));
    if (p) { ST.got[p.id] = true; addItem(p.it); sfx('kill', 0.4); const I = IT[p.it]; if (p.it === 'bam' && ST.step < 2) ST.step = 2; if (p.it === 'namul') { ST.thread = 'hill'; banner(`나물을 캤어요 ${ST.inv.namul}/5`, ST.inv.namul >= 5 ? '다 모았어요! 흥부 아내에게 가져가요' : ''); } else banner(`${I.n}${jo(I.n, '을', '를')} 주웠어요`, I.d); }
    saveST(); storyHud();
  }
  // ── 문
  function sDoor(id) {
    if (id === 'kitchen') return talk('', ['부엌에서 밥 냄새가 솔솔 나요.', '부엌 앞에 놀부 아내가 지키고 서 있어요.']);
    if (id === 'manor') return talk('', ['안채 문이 잠겨 있어요.', '안에서 엽전 세는 소리만 짤랑짤랑 들려요.']);
    if (id === 'inn') return talk('', ['주막 안은 장꾼들로 북적여요. 주인은 문 옆에 있어요.']);
    if (id === 'rice') return talk('', ['쌀가마가 그득해요. 주인은 가게 앞에 있어요.']);
    if (id === 'hut') return talk('', ['움막 안엔 빈 솥뿐이에요.']);
    if (id === 'store') { if (ST.f.tookSum) return talk('', ['쌀가마를 뺀 자리만 휑해요.']); ST.thread = 'store';
      return choose('', '곳간 안에 쌀가마가 산더미처럼 쌓여 있어요.', [{ l: '쌀 한 섬을 짊어진다', fn: () => { ST.f.tookSum = true; addItem('sum'); sfx('kill', 0.5); saveST(); storyHud(); talk('', ['영차! 쌀 한 섬을 짊어졌어요.', '(놀부가 알면 펄쩍 뛰겠네요)']); } }, { l: '그만둔다', fn: () => {} }]); }
  }
  // ── 말 걸기
  function sTalk(n) {
    const f = ST.f, me = SV.name || '독자', after = () => { saveST(); storyHud(); };
    if (n.id !== 'guard' || f.guardFree) n.face = { left: 'right', right: 'left', up: 'down', down: 'up' }[Q.dir];
    switch (n.id) {
      case 'heung':
        if (ST.step === 0) return talk('흥부', ['아이고, 처음 뵙는 분이네요. 저는 흥부예요.', '형님 댁에서 쫓겨나 이 움막에 사는데… 아이들이 사흘을 굶었어요.', '저 밤나무 아래 밤 한 톨이라도 있으면 막내한테 줄 텐데…'], () => { ST.step = has('bam') ? 2 : 1; after(); });
        if (ST.step < 3) return talk('흥부', [has('bam') ? '밤을 주우셨군요! 막내한테 주세요. 제일 배고파해요.' : '밤나무 아래를 봐 주세요. 막내가 제일 배고파해요.']);
        if (ST.fed.length) return choose('흥부', `${me}님 덕분에 아이들이 웃어요. 이제 1장을 마칠까요?`, [{ l: '1장을 마친다', fn: chapterEnd }, { l: '조금 더 둘러본다', fn: () => {} }]);
        if (foodsIn().length) return talk('흥부', ['먹을 걸 구하셨어요? 집사람한테 주세요!']);
        return talk('흥부', ['형님 댁에 부탁해 볼까, 장터에서 품을 팔까, 뒷산에서 나물을 캘까…', '어느 쪽이든 고마워요.']);
      case 'baby':
        if (has('bam') && ST.step < 3) return choose('흥부네 막내', '배고파… 꼬르륵…', [{ l: '밤 한 톨을 건넨다', fn: () => { useItem('bam'); ST.step = 3; sfx('heal', 0.4); after(); talk('흥부네 막내', ['와아, 밤이다! 고마워!', '…그래도 아직 배고파.'], () => talk('흥부', ['고맙습니다. 그래도 열두 식구가 먹으려면 더 있어야 해요.', '형님 댁에 부탁해 볼까, 장터에서 품을 팔까, 뒷산에서 나물을 캘까…'], () => banner('방법은 여러 가지예요', '위쪽 "지금 할 일"과 금빛 ▼을 보세요'))); } }, { l: '나중에', fn: () => {} }]);
        return talk('흥부네 막내', [ST.fed.length ? '배불러! 헤헤.' : '배고파…']);
      case 'girl': return talk('흥부네 큰딸', [ST.fed.length ? '오늘은 배불리 잘 수 있겠어요!' : '동생들이 자꾸 울어요… 저도 배고프지만 참아요.']);
      case 'wife': {
        const fs = foodsIn();
        if (!fs.length) return talk('흥부 아내', [ST.fed.length ? '오늘은 정말 고마웠어요.' : '솥이 텅 비었어요…', (ST.inv.namul || 0) > 0 && (ST.inv.namul || 0) < 5 ? `나물은 다섯 줌은 있어야 죽을 쑤겠어요. (지금 ${ST.inv.namul}줌)` : '무엇이든 먹을 것만 있으면…']);
        return choose('흥부 아내', ST.fed.length ? '또 구해 오셨어요?' : '그게… 먹을 거예요?', [...fs.map((k) => ({ l: `${k === 'namul' ? '나물 다섯 줌' : IT[k].n}${jo(k === 'namul' ? '줌' : IT[k].n, '을', '를')} 건넨다`, fn: () => feed(k) })), { l: '아직이요', fn: () => {} }]); }
      case 'nolbu':
        if (!f.askedNolbu) return talk('놀부', ['뭐? 흥부네 먹을 걸 꿔 달라고?', '흥! 쌀 한 톨도 없다! 썩 나가거라!'], () => { f.askedNolbu = true; ST.thread = 'nolbu'; after(); banner('부엌 쪽에서 밥 냄새가 나요', '놀부 아내에게 가 볼까요?'); });
        return talk('놀부', ['아직도 안 갔느냐! 곳간 근처엔 얼씬도 마라!']);
      case 'nwife':
        if (!f.slapped) return choose('놀부 아내', '부엌에 무슨 볼일이냐?', [{ l: '흥부네 아이들 밥 좀 나눠 주세요', fn: () => { ST.thread = 'nolbu'; talk('놀부 아내', ['뭐야? 이 주걱 맛 좀 봐라!'], () => { Q.shake = 0.35; sfx('slam', 0.5); f.slapped = true; addItem('bapal'); after(); talk('', ['철썩! 주걱이 뺨에 붙었다 떨어졌어요.', '뺨에 밥알이 잔뜩 붙었어요!'], () => choose('놀부 아내', '…왜 그렇게 쳐다보느냐?', [{ l: '(밥알을 떼며) 고맙습니다', fn: () => talk('놀부 아내', ['…별 이상한 아이 다 보겠네.']) }, { l: '왜 그렇게 모질게 하세요?', fn: () => { f.clueWife = true; after(); talk('놀부 아내', ['……', '저 양반도 어릴 땐 안 그랬어. 동생이랑 박 넝쿨 아래서 같이 놀던 사람인데.', '어서 가. 내 마음 바뀌기 전에.']); } }])); }); } }, { l: '아무것도 아니에요', fn: () => {} }]);
        return talk('놀부 아내', ['또 왔느냐? 주걱이 아직 뜨끈하다.']);
      case 'guard':
        if (f.guardFree) return talk('놀부네 머슴', ['곳간 문… 못 본 걸로 할게요.', '흥부 아재네 아이들, 배불리 먹였으면 좋겠네요.']);
        return spotted();
      case 'dog':
        if (f.dogFed) return talk('누렁이', ['헥헥. (꼬리를 흔들어요)']);
        if (has('bone')) return choose('누렁이', '으르렁… 왈왈!', [{ l: '뼈다귀를 건넨다', fn: () => { useItem('bone'); f.dogFed = true; ST.thread = 'store'; after(); talk('누렁이', ['킁킁… 와구와구!', '(누렁이가 꼬리를 흔들며 개구멍을 비켜 줬어요)']); } }, { l: '물러난다', fn: () => {} }]);
        return talk('누렁이', ['으르렁… 왈왈!', '(개구멍을 지키고 있어요. 뭘 주면 비켜 줄까요?)']);
      case 'porter':
        if (!f.job) return talk('짐꾼', ['장날이라 바빠 죽겠네. 일손 구하는 건 쌀가게 주인이야.']);
        if (!f.jimTaken) return talk('짐꾼', ['쌀가게에서 보냈다고? 잘됐다!', '이 짐 보따리, 주막 주인한테 좀 갖다줄래?'], () => { f.jimTaken = true; addItem('jim'); after(); banner('짐 보따리를 받았어요', '주막 주인에게'); });
        return talk('짐꾼', [f.jimDone ? '고마워! 덕분에 허리 폈다.' : '주막은 장터 위쪽이야. 주인은 문 옆에 있어.']);
      case 'inn':
        if (has('jim')) return choose('주막 주인', '어서 와요. 무슨 일로?', [{ l: '짐 보따리를 건넨다', fn: () => { useItem('jim'); f.jimDone = true; addItem('bone'); after(); talk('주막 주인', ['아이고, 기다리던 짐이네! 고마워요.', '이건 덤 — 국 끓이고 남은 뼈다귀야. 개나 주렴.', '그러고 보니 놀부네 동쪽 담 개구멍엔 누렁이가 지키고 있다더라.']); } }, { l: '아무것도 아니에요', fn: () => {} }]);
        return talk('주막 주인', [f.jimDone ? '또 와요!' : '장날엔 손님이 많아요.']);
      case 'yeot':
        if (f.job && !f.yeotTaken) return talk('엿장수', ['쌀가게 심부름꾼이구나?', '이 엿, 장터 아래쪽 아이한테 갖다주렴. 돈은 받았어.'], () => { f.yeotTaken = true; addItem('yeot'); after(); banner('엿을 받았어요', '장터 아래쪽 아이에게'); });
        return talk('엿장수', [f.yeotTaken && !f.yeotDone ? '아이는 장터 아래쪽에 있어.' : '엿 사려~ 달달한 엿!']);
      case 'kid':
        if (has('yeot')) return choose('장터 아이', '엿장수 아저씨가 엿 갖다준댔는데…', [{ l: '엿을 건넨다', fn: () => { useItem('yeot'); f.yeotDone = true; after(); talk('장터 아이', ['와, 엿이다! 고마워!']); } }, { l: '나중에', fn: () => {} }]);
        return talk('장터 아이', [f.yeotDone ? '엿 맛있다!' : '엿 먹고 싶다…']);
      case 'granny':
        if (!f.job) return talk('장터 할머니', ['아이고, 오늘 장은 사람이 많기도 하지.']);
        if (!f.grannyAsked) return talk('장터 할머니', ['쌀가게 심부름꾼이라고? 마침 잘 왔네.', '장 보러 오다가 엽전 꾸러미를 흘렸지 뭐야. 갈림길 근처였던 것 같은데…'], () => { f.grannyAsked = true; after(); });
        if (has('coin')) return choose('장터 할머니', '찾았니?', [{ l: '엽전 꾸러미를 건넨다', fn: () => { useItem('coin'); f.coinDone = true; after(); talk('장터 할머니', ['아이고 고마워라! 이 할미 장 볼 돈이야.']); } }, { l: '아직이요', fn: () => {} }]);
        return talk('장터 할머니', [f.coinDone ? '복 받을 거야.' : '갈림길 근처를 잘 봐 주렴. 반짝이는 게 있을 거야.']);
      case 'rice':
        if (!f.job) return talk('쌀가게 주인', ['쌀? 공짜는 없지.', '장날이라 일손이 모자라. 심부름 세 개만 해 주면 쌀 한 되 주마.', '짐꾼 · 엿장수 · 할머니한테 가 보렴.'], () => { f.job = true; ST.thread = 'market'; after(); });
        if (errands() < 3) return talk('쌀가게 주인', [`심부름 ${errands()}/3 — 짐꾼 · 엿장수 · 할머니.`]);
        if (!f.gotRice) return talk('쌀가게 주인', ['다 했다고? 소문 들었다. 일 잘하는구나!', '자, 약속한 쌀 한 되.'], () => { f.gotRice = true; addItem('ssal'); sfx('kill', 0.5); after(); banner('쌀 한 되를 받았어요', '흥부 아내에게'); });
        return talk('쌀가게 주인', ['또 일손 필요하면 부르마.']);
    }
  }
  function feed(k) {
    const L = { bapal: ['밥알 몇 톨이지만… 막내 입에라도 넣어 줄게요.', '(아이들이 밥알을 한 톨씩 나눠 먹으며 웃어요)'], ssal: ['쌀 한 되나! 장터에서 일하셨군요.', '(하얀 쌀밥이 지어져요. 아이들이 솥 앞에 모여요)'], sum: ['이렇게 많은 쌀을… 어디서요?', '…형님 댁 곳간이요? 아이들 생각하면 고맙긴 한데… 마음이 무거워요.', '(쌀밥이 산더미처럼 지어져요)'], namul: ['나물을 다섯 줌이나! 먹물 얼룩을 피해 다니셨군요.', '(나물죽이 보글보글 끓어요)'] }[k];
    const m = IT[k].food, pts = k === 'sum' ? 2 : 1; useItem(k, k === 'namul' ? 5 : 1); if (!ST.fed.includes(m)) ST.fed.push(m); sfx('heal', 0.5); saveST(); storyHud();
    talk('흥부 아내', L, () => { gainMind(m, pts); saveST(); storyHud(); setTimeout(() => choose('흥부 아내', `아이들이 배를 채웠어요. 고마워요, ${SV.name || '독자'}님.`, [{ l: '1장을 마친다', fn: chapterEnd }, { l: '다른 방법도 해 본다', fn: () => banner('더 둘러봐요', '흥부에게 말 걸면 언제든 1장을 마쳐요') }]), 350); });
  }
  // ── 머슴의 눈(시선 잠입): 고개를 돌리며 3칸. 머슴이 들으면 싸움(이기면 먹물이 씻겨 비켜 줌)
  function guardSees(x, y) { if (ST.f.guardFree) return false; const [gx, gy] = npcXY('guard'), [dx, dy] = DV[GSEQ[Q.gi][0]]; for (let k = 1; k <= 3; k++) { const sx = gx + dx * k, sy = gy + dy * k; if (sx < 0 || sy < 0 || sx >= CH1.w || sy >= CH1.h || SSOL[sy][sx]) break; if (sx === x && sy === y) return true; } return false; }
  function sightTiles() { const out = []; if (ST.f.guardFree) return out; const [gx, gy] = npcXY('guard'), [dx, dy] = DV[GSEQ[Q.gi][0]]; for (let k = 1; k <= 3; k++) { const sx = gx + dx * k, sy = gy + dy * k; if (SSOL[sy] && SSOL[sy][sx]) break; out.push([sx, sy]); } return out; }
  function spotted() { if (Q.bang) return; sfx('alert', 0.5); inputLock = true; joy.on = false; ST.thread = 'store'; const [gx, gy] = npcXY('guard'); Q.bang = { x: gx, y: gy, t: 0.8, cb: () => { inputLock = false; talk('놀부네 머슴', ['게 섰거라! 곳간 도둑이다!', '(머슴의 눈이 먹물처럼 시커메요!)'], () => fightFlash('guard')); } }; }
  // ── 뒷산 먹물 얼룩(보이는 만남): 떠돌다 가까우면 다가옴. 닿으면 싸움
  function blotsUpdate(dt) {
    Q.grace = Math.max(0, Q.grace - dt);
    for (const b of Q.blots) { b.ph += dt; if (b.t < 1) { b.t = Math.min(1, b.t + dt / 0.5); b.px = b.fx + (b.x - b.fx) * b.t; b.py = b.fy + (b.y - b.fy) * b.t; continue; }
      b.next -= dt; if (b.next > 0) continue; b.next = 0.55 + Math.random() * 0.7; const d = Math.abs(b.x - Q.x) + Math.abs(b.y - Q.y);
      let opts = Object.values(DV).map(([dx, dy]) => [b.x + dx, b.y + dy]).filter(([x, y]) => x >= HILL.x0 && x <= HILL.x1 && y >= HILL.y0 && y <= HILL.y1 && !SSOL[y][x] && !Q.blots.some((o) => o !== b && o.x === x && o.y === y));
      if (d <= 4 && Math.random() < 0.55 && Q.grace <= 0) opts.sort((p, q) => (Math.abs(p[0] - Q.x) + Math.abs(p[1] - Q.y)) - (Math.abs(q[0] - Q.x) + Math.abs(q[1] - Q.y))); else opts.sort(() => Math.random() - 0.5);
      if (opts.length) { b.fx = b.x; b.fy = b.y; [b.x, b.y] = opts[0]; b.t = 0; } }
    if (!inputLock && $('ov').hidden && Q.grace <= 0) { const hit = Q.blots.find((b) => Math.abs(b.px - Q.px) < 0.6 && Math.abs(b.py - Q.py) < 0.6); if (hit) { sfx('alert', 0.35); ST.thread = 'hill'; fightFlash('blot', hit.id); } }
  }
  // ── 싸움(이야기가 부를 때만): 기존 싸움판 그대로(동행·책갈피). 이기면 먹물이 씻김 + 낱장
  function fightFlash(kind, id) { inputLock = true; joy.on = false; Q.flashT = 0.6; Q.flashCb = () => { inputLock = false; storyFight(kind, id); }; }
  function storyFight(kind, id) {
    const C = kind === 'guard' ? { set: [['servant', 1], ['wisp', 2]], mul: 1.2, t: '곳간 앞 · 먹물에 물든 머슴', obs: 2 } : { set: [['wisp', 2], ['crow', 1]], mul: 0.8, t: '뒷산 · 먹물 얼룩', obs: 1 };
    const go = () => { baseArena('story'); A.story = { kind, id }; A.title = C.t; placeObs(C.obs); spawnSet(C.set, C.mul); for (const e of A.en) if (e.k === 'servant') e.say = '어, 내가 왜 이랬지?'; hudUpdate(); banner(C.t, '움직이면 피하고 · 멈추면 글자가 날아가요'); };
    if (!SV.tutFight) { SV.tutFight = true; saveSV(); const pn = SV.load.c ? PETS[SV.load.c].n : ''; return card(`<h2>첫 싸움</h2><p class="lead">먹물에 물든 이야기 조각이에요. 글자로 먹물을 씻어 내요.</p><div class="stats"><span>움직이면</span><b>피하기</b><span>멈추면</span><b>글자가 날아감(낭독)</b><span>톡 치면</span><b>구르기(잠깐 무적)</b>${pn ? `<span>${pn}</span><b>알아서 함께 싸워요</b>` : ''}</div><p>이기면 먹물이 씻겨 원래대로 돌아와요. 져도 이야기는 이어져요.</p><button class="go" type="button" id="go">알겠어요</button>`, (c) => { c.querySelector('#go').onclick = () => { closeCard(); go(); }; }); }
    go();
  }
  function storyFightEnd(win, fled) {
    if (!A || A.state === 'end') return; const { kind, id } = A.story; A.state = 'end'; sfx(win ? 'win' : 'lose', 0.4); const xp = xpLines(win ? A.kills * 3 + 6 : A.kills * 2); if (win) SV.leaves++; saveSV();
    const lead = win ? (kind === 'guard' ? '머슴 몸에서 먹물이 씻겨 나갔어요.' : '먹물 얼룩이 씻겨 사라졌어요.') : fled ? '싸움에서 물러났어요.' : '먹물에 밀려 눈앞이 하얘졌어요.';
    setTimeout(() => card(`<h2>${win ? '먹물을 씻어 냈어요' : fled ? '물러났어요' : '밀려났어요'}</h2><p class="lead">${lead}</p><div class="stats">${win ? '<span>낱장</span><b>+1</b>' : ''}<span>씻어 낸 조각</span><b>${A.kills}</b>${xp}</div>${win ? '' : '<p>괜찮아요, 이야기는 이어져요. 다른 길로 가도 되고요.</p>'}<button class="go" type="button" id="back">이야기로 돌아가기</button>`, (c) => { c.querySelector('#back').onclick = () => { closeCard(); A = null; backToStory(kind, id, win); }; }), win ? 600 : 400);
  }
  function backToStory(kind, id, win) {
    setMode('story'); music('road'); $('hpw').style.display = 'none'; Q.grace = 1.5; inputLock = false;
    const place = (x, y, d) => { Q.x = Q.px = x; Q.y = Q.py = y; Q.dir = d; Q.moving = false; Q.petX = Q.petPX = x; Q.petY = Q.petPY = y + 1; };
    if (kind === 'guard') { if (win) { ST.f.guardFree = true; saveST(); storyHud(); talk('놀부네 머슴', ['어… 내가 왜 이랬지? 아까 먹물이 튀더니 눈앞이 캄캄해서…', '흥부 아재네 아이들 굶는 건 나도 알아요.', '곳간 문… 못 본 걸로 할게요.']); } else { place(14, 16, 'down'); saveST(); storyHud(); banner('놀부네에서 쫓겨났어요', '머슴의 빨간 눈을 피해 다시 가 봐요'); } return; }
    if (win) { ST.blots[id] = true; Q.blots = Q.blots.filter((b) => b.id !== id); banner('먹물 얼룩을 지웠어요', '뒷산이 조금 맑아졌어요'); }
    else { const b = Q.blots.find((q) => q.id === id); if (b) { b.x = b.fx = b.px = 10; b.y = b.fy = b.py = 31; b.t = 1; } place(6, 25, 'right'); banner('뒷산 입구로 밀려났어요', '얼룩은 피해 가도 돼요'); }
    saveST(); storyHud();
  }
  // ── 1장 끝
  function chapterEnd() {
    ST.done = true; SV.ch1 = { fed: ST.fed.slice(), mind: Object.assign({}, ST.mind), clue: !!ST.f.clueWife, n: ((SV.ch1 && SV.ch1.n) || 0) + 1 }; saveST(); sfx('win', 0.4);
    inputLock = true; Q.turnT = 1.1; storyHud();
    const miss = ['kind', 'wit', 'greed', 'swift'].filter((m) => !ST.fed.includes(m));
    setTimeout(() => { inputLock = false; card(`<h2>1장 「쫓겨난 흥부네」 끝</h2><p class="lead">흥부네 아이들이 오랜만에 배를 채우고 잠들었어요.</p><h3>내가 한 일</h3><div class="stats">${ST.fed.map((m) => `<span>${MIND[m]}</span><b style="text-align:left">${METHOD[m]}</b>`).join('')}</div><h3>마음</h3><p>착함 ${ST.mind.kind} · 꾀 ${ST.mind.wit} · 욕심 ${ST.mind.greed} · 날램 ${ST.mind.swift} — 이 마음이 3장의 결말로 이어져요.</p>${ST.f.clueWife ? '<p>놀부 아내의 말을 기억해 두세요. 나중에 쓸모가 있을지도.</p>' : ''}${miss.length ? `<h3>못 해 본 방법</h3><p>${miss.map((m) => HINT[m]).join('<br>')}</p>` : ''}<p class="lead" style="font-size:.92rem">2장 「처마 밑 제비」는 다음 시안에서 이어져요.</p><button class="go" type="button" id="hub">책방골로 나가기</button><button class="sub" type="button" id="again">1장 처음부터 다시 읽기</button>`, (c) => {
      c.querySelector('#hub').onclick = () => { SV.intro = true; saveSV(); backToTown(...HOME_FRONT); banner('책방골', '예전 시안의 마을 — 둘러보기'); };
      c.querySelector('#again').onclick = () => { SV.story = newStory(); saveSV(); storyStart(false); }; }); }, 900);
  }
  // ── 상태 띠 · 가방
  function storyHud() {
    if (!ST || !Q) return; $('page').textContent = CH1.short; $('pause').style.display = 'none'; $('swap').style.display = 'none'; $('bag').style.display = '';
    const G = goal(), gh = `<b>지금 할 일</b>${G.t}`; const ge = $('goal'); ge.hidden = false; if (ge.innerHTML !== gh) ge.innerHTML = gh;
    const ks = Object.keys(ST.inv); const h = ks.length ? ks.map((k) => `<span class="tag">${k === 'namul' ? `나물 ${ST.inv.namul}/5` : IT[k].n}${k !== 'namul' && ST.inv[k] > 1 ? ' ×' + ST.inv[k] : ''}</span>`).join('') : '<span class="tag" style="opacity:.6">가방 비었음</span>';
    if ($('tags').innerHTML !== h) $('tags').innerHTML = h;
  }
  function storyBag() {
    const ks = Object.keys(ST.inv);
    card(`<h2>가방</h2>${ks.length ? ks.map((k) => `<div class="opt" style="cursor:default"><span class="ic" style="background:#e8dcb0">${IT[k].n[0]}</span><b>${IT[k].n}${k === 'namul' ? ` ${ST.inv.namul}/5` : ST.inv[k] > 1 ? ' ×' + ST.inv[k] : ''}</b><span>${IT[k].d}</span></div>`).join('') : '<p>아직 아무것도 없어요. 땅에 반짝이는 걸 밟으면 주워요.</p>'}<h3>마음</h3><p>착함 ${ST.mind.kind} · 꾀 ${ST.mind.wit} · 욕심 ${ST.mind.greed} · 날램 ${ST.mind.swift}</p><p style="font-size:.82rem">사람에게 걸어 들어가면 말 걸기 · 물건은 그 사람에게 말 걸면 건넬 수 있어요.</p><button class="go" type="button" id="out">닫기</button><button class="sub" type="button" id="close">책 덮기(${Q.from === 'town' ? '책방골로' : '처음 화면으로'} · 저장됨)</button>`, (c) => {
      c.querySelector('#out').onclick = closeCard; c.querySelector('#close').onclick = () => { saveST(); closeCard(); if (Q.from === 'town') backToTown(SV.pos.x, SV.pos.y, SV.pos.d); else title(); }; });
  }
  // ── 매 프레임
  function storyUpdate(dt) {
    Q.time += dt; Q.shake = Math.max(0, Q.shake - dt); Q.turnT = Math.max(0, Q.turnT - dt);
    if (Q.flashT > 0) { Q.flashT -= dt; if (Q.flashT <= 0 && Q.flashCb) { const cb = Q.flashCb; Q.flashCb = null; cb(); } return; }
    if (Q.bang) { Q.bang.t -= dt; if (Q.bang.t <= 0) { const cb = Q.bang.cb; Q.bang = null; cb(); } }
    if (!ST.f.guardFree) { Q.gt -= dt; if (Q.gt <= 0) { Q.gi = (Q.gi + 1) % GSEQ.length; Q.gt = GSEQ[Q.gi][1]; } }
    if (Q.moving) { Q.t += dt / SSTEP; if (Q.t >= 1) { Q.t = 1; Q.moving = false; Q.px = Q.x; Q.py = Q.y; Q.petPX = Q.petX; Q.petPY = Q.petY; sArrived(); } else { Q.px = Q.fromX + (Q.x - Q.fromX) * Q.t; Q.py = Q.fromY + (Q.y - Q.fromY) * Q.t; Q.petPX = Q.petFX + (Q.petX - Q.petFX) * Q.t; Q.petPY = Q.petFY + (Q.petY - Q.petFY) * Q.t; } }
    if (!Q.moving && !inputLock && $('ov').hidden) { const d = gridDir(); if (d) sTryMove(d); }
    blotsUpdate(dt);
    if (!inputLock && $('ov').hidden && !Q.bang && MODE === 'story' && guardSees(Q.x, Q.y)) spotted();
  }
  // ── 그리기
  const sIsPath = (x, y) => SG[y] && (SG[y][x] === 'path' || SG[y][x] === 'sign' || SDOOR[`${x},${y}`] || x < 0 || x >= CH1.w);
  function sPathTile(x, y) { const n = !sIsPath(x, y - 1), s = !sIsPath(x, y + 1), w = !sIsPath(x - 1, y), e = !sIsPath(x + 1, y); const r = n && !s ? 0 : s && !n ? 2 : 1, c = w && !e ? 0 : e && !w ? 2 : 1; return TILE.path9[r * 3 + c]; }
  const sIsDirt = (x, y) => SG[y] && SG[y][x] === 'dirt';
  function sDirtTile(x, y) { if (!TILE.dirt9) return TILE.path[0]; const n = !sIsDirt(x, y - 1), s = !sIsDirt(x, y + 1), w = !sIsDirt(x - 1, y), e = !sIsDirt(x + 1, y); const r = n ? 0 : s ? 2 : 1, c = w ? 0 : e ? 2 : 1; return TILE.dirt9[r * 3 + c]; }
  const PICON = {};
  function outl(fn) { const body = mk(16, 16, fn); return mk(16, 16, (g) => { for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) g.drawImage(body, dx, dy); g.globalCompositeOperation = 'source-in'; R(g, 0, 0, 16, 16, '#1d140e'); g.globalCompositeOperation = 'source-over'; g.drawImage(body, 0, 0); }); }
  function picon(it) { if (PICON[it]) return PICON[it];
    return (PICON[it] = outl((g) => { if (it === 'bam') { R(g, 6, 5, 5, 8, '#8a4a22'); R(g, 5, 7, 7, 5, '#8a4a22'); R(g, 7, 4, 3, 1, '#6a3a1a'); R(g, 6, 11, 5, 2, '#e8d0a0'); R(g, 7, 6, 2, 2, 'rgba(255,255,255,0.45)'); }
      else if (it === 'namul') { R(g, 7, 8, 2, 6, '#3a6a2a'); R(g, 3, 5, 5, 3, '#5aa040'); R(g, 9, 4, 5, 3, '#6ab848'); R(g, 4, 9, 3, 2, '#4a9038'); R(g, 9, 8, 4, 2, '#5aa040'); R(g, 10, 5, 2, 1, '#a8e080'); }
      else if (it === 'coin') { R(g, 3, 7, 7, 6, '#c89a40'); R(g, 4, 6, 5, 8, '#c89a40'); R(g, 6, 9, 1, 2, '#5a3a10'); R(g, 8, 4, 6, 6, '#f0d070'); R(g, 9, 3, 4, 8, '#f0d070'); R(g, 10, 6, 2, 2, '#8a6a2a'); }
      else { R(g, 4, 4, 8, 8, '#e8dcb0'); } })); }
  function drawBlot(b, cx, cy, tz) { const bx = b.px * tz - cx + tz / 2, by = b.py * tz - cy + tz / 2 + Math.sin(b.ph * 3) * Z, r = 6 * Z;
    ctx.fillStyle = 'rgba(40,30,20,0.25)'; ctx.beginPath(); ctx.ellipse(bx, by + r * 0.95, r, r * 0.3, 0, 0, 7); ctx.fill();
    ctx.fillStyle = '#24162f'; ctx.beginPath(); for (let i = 0; i <= 12; i++) { const a = i / 12 * Math.PI * 2, rr = r * (1 + 0.16 * Math.sin(b.ph * 4 + i * 1.7)); const px = bx + Math.cos(a) * rr, py = by + Math.sin(a) * rr * 0.85; if (i) ctx.lineTo(px, py); else ctx.moveTo(px, py); } ctx.closePath(); ctx.fill();
    ctx.beginPath(); ctx.arc(bx - r * 0.5, by + r * 0.9 + Math.sin(b.ph * 5) * Z, Z * 1.4, 0, 7); ctx.arc(bx + r * 0.4, by + r * 1.05, Z, 0, 7); ctx.fill();
    ctx.fillStyle = '#fffaf0'; ctx.fillRect(bx - 3 * Z, by - 2 * Z, 2 * Z, 2 * Z); ctx.fillRect(bx + Z, by - 2 * Z, 2 * Z, 2 * Z); ctx.fillStyle = '#b8432f'; ctx.fillRect(bx - 2 * Z, by - Z, Z, Z); ctx.fillRect(bx + 2 * Z, by - Z, Z, Z); }
  function drawNpc(n, cx, cy, tz) { const [x, y] = npcXY(n.id), dir = n.id === 'guard' && !ST.f.guardFree ? GSEQ[Q.gi][0] : (n.face || n.dir), w = NINJA && NS[n.spr], sx = x * tz - cx, sy = y * tz - cy;
    if (w && w.walker) drawWalker(w, dir, 0, sx, sy, tz);
    else if (w && w.strip) { const hh = tz * w.h / w.w; drawWalker(w, dir === 'left' ? 'left' : 'right', n.id === 'dog' && ST.f.dogFed ? Math.floor(Q.time * 4) : 0, sx, sy + tz - hh, tz); }
    else if (SPR[n.spr]) drawPerson(SPR[n.spr], x, y, dir === 'left' || dir === 'right' ? dir : dir, 0, cx, cy, tz);
    else { ctx.fillStyle = '#c8a070'; ctx.beginPath(); ctx.arc(sx + tz / 2, sy + tz / 2, tz * 0.4, 0, 7); ctx.fill(); }
    if (n.id === 'guard' && !ST.f.guardFree) { ctx.fillStyle = 'rgba(36,22,48,0.7)'; ctx.beginPath(); ctx.arc(sx + tz * 0.35, sy + tz * 0.55, 2.4 * Z, 0, 7); ctx.arc(sx + tz * 0.66, sy + tz * 0.7, 1.8 * Z, 0, 7); ctx.fill(); } }
  function marker(x, y, cx, cy, tz) { const bx = x * tz - cx + tz / 2, by = y * tz - cy - 4 * Z + Math.sin(Q.time * 5) * 2 * Z, top = 118;
    if (bx > 8 && bx < W - 8 && by > top && by < H - 8) { ctx.fillStyle = '#ffd34a'; ctx.strokeStyle = '#3f2832'; ctx.lineWidth = Z; ctx.beginPath(); ctx.moveTo(bx - 5 * Z, by - 6 * Z); ctx.lineTo(bx + 5 * Z, by - 6 * Z); ctx.lineTo(bx, by); ctx.closePath(); ctx.fill(); ctx.stroke(); return; }
    // 화면 밖: 가장자리 화살표
    const mx = W / 2, my = (H + top) / 2, dx = bx - mx, dy = by + 3 * Z - my, a = Math.atan2(dy, dx), m = 22, kx = dx ? ((dx > 0 ? W - m : m) - mx) / dx : 1e9, ky = dy ? ((dy > 0 ? H - m : top + m) - my) / dy : 1e9, k = Math.min(Math.abs(kx), Math.abs(ky));
    const ex = mx + dx * k, ey = my + dy * k, s = 9 + Math.sin(Q.time * 5) * 1.5; ctx.save(); ctx.translate(ex, ey); ctx.rotate(a); ctx.fillStyle = '#ffd34a'; ctx.strokeStyle = '#3f2832'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(s, 0); ctx.lineTo(-s * 0.8, -s * 0.8); ctx.lineTo(-s * 0.4, 0); ctx.lineTo(-s * 0.8, s * 0.8); ctx.closePath(); ctx.fill(); ctx.stroke(); ctx.restore(); }
  const sWalkF = () => (Q.step ? (Q.t < 0.5 ? 1 : 2) : (Q.t < 0.5 ? 3 : 0));
  function storyRender() {
    townZoom(); ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.imageSmoothingEnabled = false; ctx.fillStyle = '#1d1813'; ctx.fillRect(0, 0, W, H);
    const tz = TS * Z, MWp = CH1.w * tz, MHp = CH1.h * tz; let cx = (Q.px + 0.5) * tz - W / 2, cy = (Q.py + 0.5) * tz - H * 0.5;
    cx = MWp <= W ? (MWp - W) / 2 : clamp(cx, 0, MWp - W); cy = clamp(cy, -110, Math.max(-110, MHp - H + 10));
    if (Q.shake > 0) { cx += rnd(-1, 1) * Q.shake * 24; cy += rnd(-1, 1) * Q.shake * 24; } cx = Math.round(cx); cy = Math.round(cy);
    const x0 = Math.max(0, Math.floor(cx / tz)), y0 = Math.max(0, Math.floor(cy / tz)), x1 = Math.min(CH1.w - 1, Math.ceil((cx + W) / tz)), y1 = Math.min(CH1.h - 1, Math.ceil((cy + H) / tz)), bf = Math.floor(Q.time * 1.5) % 2;
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) { const k = SG[y][x], h = (x * 7 + y * 13) % 4; let img = TILE.grass[h];
      if (k === 'path') img = TILE.path9 ? sPathTile(x, y) : TILE.path[h % 2]; else if (k === 'dirt') img = sDirtTile(x, y); else if (k === 'bush') img = TILE.bush[(bf + x + y) % 2]; else if (k === 'flower' && TILE.flowerV) img = TILE.flowerV[(x * 3 + y) % TILE.flowerV.length]; else if (k === 'jar' && TILE.jarV) img = TILE.jarV[(x + y) % TILE.jarV.length]; else if (k === 'chest' || k === 'fence' || k === 'sign') img = TILE[k];
      ctx.drawImage(img, x * tz - cx, y * tz - cy, tz, tz); }
    for (const b of CH1.houses) { if (!b.img || b.ninja !== NINJA) { b.img = NINJA ? houseImg(b.set, b.w, b.h, b.doors, b.label) : building(b.w, b.h, '#8a5a2a', b.label, b.doors); b.ninja = NINJA; } ctx.drawImage(b.img, b.x * tz - cx, b.y * tz - cy, b.w * tz, b.h * tz); }
    // 머슴의 눈(빨간 칸)
    for (const [sx, sy] of sightTiles()) { const px = sx * tz - cx, py = sy * tz - cy; ctx.fillStyle = 'rgba(217,80,60,0.28)'; ctx.fillRect(px, py, tz, tz); ctx.strokeStyle = 'rgba(184,67,47,0.6)'; ctx.lineWidth = Math.max(1, Z * 0.6); ctx.strokeRect(px + 1, py + 1, tz - 2, tz - 2); }
    // 떨어진 것
    for (const p of SP) { if (ST.got[p.id] || (p.when && !p.when()) || p.x < x0 - 1 || p.x > x1 + 1 || p.y < y0 - 1 || p.y > y1 + 1) continue; const px = p.x * tz - cx, py = p.y * tz - cy + Math.round(Math.sin(Q.time * 3 + p.x) * Z); ctx.drawImage(picon(p.it), px, py, tz, tz); if (Math.sin(Q.time * 4 + p.y) > 0.6) { ctx.fillStyle = '#fffaf0'; ctx.fillRect(px + tz * 0.75, py + tz * 0.1, Z, 3 * Z); ctx.fillRect(px + tz * 0.75 - Z, py + tz * 0.1 + Z, 3 * Z, Z); } }
    const list = [];
    if (TILE.bigTree) for (let y = Math.max(0, y0 - 1); y <= Math.min(CH1.h - 1, y1 + 1); y++) for (let x = Math.max(0, x0 - 1); x <= Math.min(CH1.w - 1, x1 + 1); x++) if (SG[y][x] === 'tree') { const img = TILE.bigTree[(x * 5 + y * 3) % 3]; list.push({ y: y + 0.2, draw: () => ctx.drawImage(img, x * tz - cx - tz / 2, y * tz - cy - tz, tz * 2, tz * 2) }); }
    for (const n of SN) { const [nx, ny] = npcXY(n.id); if (nx < x0 - 1 || nx > x1 + 1 || ny < y0 - 1 || ny > y1 + 2) continue; list.push({ y: ny, draw: () => drawNpc(n, cx, cy, tz) }); }
    for (const b of Q.blots) list.push({ y: b.py + 0.1, draw: () => drawBlot(b, cx, cy, tz) });
    const fol = SV.load.c; if (fol) list.push({ y: Q.petPY - 0.01, draw: () => { const w = NINJA && NS['p_' + fol]; if (w) { drawWalker(w, Q.dir, Q.moving ? sWalkF() : (w.strip ? Math.floor(Q.time * 4) : 0), Q.petPX * tz - cx, Q.petPY * tz - cy + (w.strip ? tz - tz * w.h / w.w : 0), tz); if (fol === 'gumiho') { for (let i = 0; i < 3; i++) { const a = Q.time * 2.2 + i * 2.09, ox = Q.petPX * tz - cx + tz / 2 + Math.cos(a) * 7 * Z, oy = Q.petPY * tz - cy + tz * 0.3 + Math.sin(a) * 3 * Z; ctx.fillStyle = 'rgba(255,154,74,0.45)'; ctx.fillRect(ox - 2 * Z, oy - 2 * Z, 4 * Z, 4 * Z); ctx.fillStyle = '#ffd38a'; ctx.fillRect(ox - Z / 2, oy - Z / 2, Z, Z); } } return; } if (PSPR[fol]) ctx.drawImage(PSPR[fol], Q.petPX * tz - cx, Q.petPY * tz - cy, tz, tz); } });
    list.push({ y: Q.py, draw: () => { const bx = Q.px * tz - cx + tz / 2, by = Q.py * tz - cy + tz - 2 * Z; ctx.strokeStyle = '#ffd34a'; ctx.lineWidth = Math.max(2, Z); ctx.beginPath(); ctx.ellipse(bx, by, 7 * Z, 2.6 * Z, 0, 0, 7); ctx.stroke();
      drawPerson(SPR.me, Q.px, Q.py, Q.dir, Q.moving ? (SPR.me.walker ? sWalkF() : Q.step) : 0, cx, cy, tz, Q.moving && !SPR.me.walker ? Math.round(Math.sin(Q.t * Math.PI) * Z) : 0); if (SG[Q.y][Q.x] === 'bush' && !Q.moving) ctx.drawImage(TILE.bush[bf], 0, 9, 16, 7, Q.px * tz - cx, Q.py * tz - cy + 9 * Z, tz, 7 * Z); } });
    list.sort((a, b) => a.y - b.y).forEach((o) => o.draw());
    if (Q.bang) { const bx = Q.bang.x * tz - cx + tz / 2, by = Q.bang.y * tz - cy - 4 * Z; ctx.fillStyle = '#fffaf0'; ctx.strokeStyle = '#1d140e'; ctx.lineWidth = Z; ctx.fillRect(bx - 4 * Z, by - 10 * Z, 8 * Z, 10 * Z); ctx.strokeRect(bx - 4 * Z, by - 10 * Z, 8 * Z, 10 * Z); ctx.fillStyle = '#b8432f'; ctx.fillRect(bx - Z, by - 8 * Z, 2 * Z, 5 * Z); ctx.fillRect(bx - Z, by - 2 * Z, 2 * Z, Z); }
    if (!TALK.on && $('ov').hidden && Q.turnT <= 0) for (const [tx, ty] of goal().tg.slice(0, 3)) marker(tx, ty, cx, cy, tz);
    if (Q.flashT > 0) { const a = Math.floor(Q.flashT * 10) % 2 ? 0.85 : 0.1; ctx.fillStyle = `rgba(29,24,19,${a})`; ctx.fillRect(0, 0, W, H); }
    if (Q.turnT > 0) { const k = Q.turnT / 1.1, edge = W * (1 - Math.min(1, (1 - k) * 1.4)); ctx.fillStyle = '#f4ecd8'; ctx.fillRect(0, 0, edge, H); ctx.fillStyle = 'rgba(120,90,50,0.25)'; ctx.fillRect(edge - 6, 0, 6, H); ctx.globalAlpha = Math.min(1, k * 1.5); ctx.fillStyle = '#2a2218'; ctx.font = '700 20px "Gowun Batang", serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; if (edge > W * 0.6) ctx.fillText(CH1.title, Math.min(W / 2, edge / 2), H / 2); ctx.globalAlpha = 1; }
    if (joy.on) drawJoy();
  }

  // ═════════ 시작 흐름(D-155): 이름 → 책방(지워지는 책) → 질문 → 해태 / 구미호 → 바로 1장 ═════════
  function opening() { nameCard(); }
  function nameCard() {
    setMode('title'); $('hud').hidden = true;
    card(`<h2>이름을 알려 줄래?</h2><p class="lead">책방골 책방 주인이 안경 너머로 너를 봐요.</p><input id="nm" class="name" maxlength="8" placeholder="이름(8자까지)" autocomplete="off" enterkeyhint="done"><button class="go" type="button" id="ok">이 이름으로</button>`, (c) => {
      const i = c.querySelector('#nm'); i.value = SV.name || ''; const ok = () => { SV.name = (i.value.trim() || '독자').slice(0, 8); saveSV(); shopScene(); };
      c.querySelector('#ok').onclick = ok; i.onkeydown = (e) => { e.stopPropagation(); if (e.key === 'Enter') ok(); }; i.onkeyup = (e) => e.stopPropagation(); });
  }
  function shopScene() {
    const me = SV.name;
    card(`<div class="book" aria-hidden="true"><div class="blot"></div><p>천하의 형세는 나뉜 지 오래면 합쳐지고, 합쳐진 지 오래면 다시 나뉘는 법…</p><p>누런 두건을 두른 무리가 들고일어나자, 탁현의 세 사람이 복숭아밭에서 형제가 되기를 맹세했어요.</p></div><p class="lead">책방 주인: "${me}, 마침 잘 왔다. 이걸 봐."</p><p>책장의 글자가 먹물에 번지더니 하얗게 지워져요.</p><p class="lead">"누가 삼국지연의에 먹물을 쏟고 있어. 황건적이 먹물에 물들어 날뛰고, 이대로면 도원결의도 사라져."</p><button class="go" type="button" id="ok">어떻게 해요?</button>`, (c) => { c.querySelector('#ok').onclick = () => quiz(0, { h: 0, g: 0 }); });
  }
  const QUIZ = [
    { q: '"이야기 속에서 친구가 괴롭힘을 당하면, 너는?"', a: [['앞에 나서서 막아 준다', 'h'], ['꾀를 내서 몰래 돕는다', 'g']] },
    { q: '"싸움이 붙으면 어떻게 할래?"', a: [['가까이 붙어서 세게!', 'h'], ['멀리서 요리조리!', 'g']] },
    { q: '"마지막으로 — 더 끌리는 친구는?"', a: [['듬직하게 지켜 주는 친구', 'h'], ['재주가 많아 놀라게 하는 친구', 'g']] },
  ];
  function quiz(i, sc) {
    if (i >= 2 && sc.h !== sc.g) return starterCard(sc.h > sc.g ? 'zhangfei' : 'zhuge');
    if (i >= 3) return starterCard(sc.h >= sc.g ? 'zhangfei' : 'zhuge');
    const Qz = QUIZ[i];
    card(`${i === 0 ? '<p>"책 속으로 들어가려면 함께할 장수가 있어야 해. 몇 가지만 물어볼게."</p>' : ''}<h2>책방 주인의 질문 ${i + 1}</h2><p class="lead">${Qz.q}</p>${Qz.a.map(([l, k]) => `<button class="opt" type="button" data-k="${k}" style="grid-template-columns:1fr"><b>${l}</b></button>`).join('')}`, (c) => {
      c.querySelectorAll('[data-k]').forEach((b) => b.onclick = () => { sc[b.dataset.k]++; quiz(i + 1, sc); }); });
  }
  function petPortrait(id) { try { const w = NINJA && NS['p_' + id]; const src = w ? (w.walker ? w.frame('down', 0) : w.fr[0]) : PSPR[id]; return src.toDataURL(); } catch (e) { return ''; } }
  function starterCard(rec) {
    const S = { zhangfei: { t: '지키는 근접', d: '뛰어들어 장팔사모로 내려치고, 맞은 적은 2초 동안 장비만 노려요(장판교 고함).', b: '책갈피로 꽂으면: 장팔사모(부채꼴) + 장판교 버티기(막고 되돌리기)' }, zhuge: { t: '홀리는 원거리', d: '화공 불씨 3개를 띄워 휘어 따라가며 날려요.', b: '책갈피로 꽂으면: 화공 글자 + 짚단 허수아비(구르면 분신)' } };
    card(`<h2>함께 갈 첫 장수</h2><p>책방 주인: "${PETS[rec].n}${jo(PETS[rec].n, '이', '가')} 너랑 잘 맞겠구나. 그래도 고르는 건 너야."</p>${['zhangfei', 'zhuge'].map((id) => `<button class="opt starter ${id === rec ? 'on' : ''}" type="button" data-st="${id}"><img class="pimg" alt="" src="${petPortrait(id)}"><b>${PETS[id].n} · ${S[id].t}${id === rec ? ' <em>추천</em>' : ''}</b><span>${S[id].d}<br><small>${S[id].b}</small></span></button>`).join('')}<p style="font-size:.8rem">나는 독자 — 걸으며 읽으면 글자가 날아가 먹물을 씻어 내요. 못 고른 쪽과 유비·관우도 책 속에서 만날 수 있어요.</p>`, (c) => {
      c.querySelectorAll('[data-st]').forEach((b) => b.onclick = () => pickStarter(b.dataset.st)); });
  }
  function pickStarter(id) {
    SV.pets = { [id]: { lvl: 1, xp: 0 } }; SV.party = [id]; SV.load = { c: id, b1: null }; SV.pet = id; SV.opened = true; SV.intro = true; SV.story = newStory(); saveSV(); sfx('accept', 0.4);
    const me = SV.name, pn = PETS[id].n;
    card(`<h2>${me}${jo(me, '과', '와')} ${pn}</h2><img class="pimg big" alt="" src="${petPortrait(id)}"><p class="lead">"좋아. 황건적 토벌부터 같이 읽어 보자. 먹물에 물든 황건적을 씻어 내는 거야."</p><p><b>끌면</b> 걸어요. 걷는 동안에도 글자가 날아가요. 짧게 톡 치면 구르기. 쓰러진 적이 남긴 글자 조각을 주우면 힘을 고르거나 <b>장수를 맞아들여요</b> — 유비·관우·장비가 모이면 <b>도원결의</b>!</p><button class="go" type="button" id="go">삼국지연의를 펼친다</button>`, (c) => { c.querySelector('#go').onclick = () => { closeCard(); startSurv(); }; });
  }
