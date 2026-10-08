  // ═════════ 입력: 어디든 끌면 조이스틱(마을·싸움판 같음), 키보드는 방향키·WASD ═════════
  const joy = { on: false, ox: 0, oy: 0, x: 0, y: 0, id: null }, keys = {};
  let inputLock = false;
  cv.addEventListener('pointerdown', (e) => { if (MODE === 'army') { armyTap(e.clientX, e.clientY); return; } if (inputLock) return; if (MODE === 'arena' && (!A || A.state !== 'play')) return; if (MODE === 'arena' && A.map && fieldMapHit(e.clientX, e.clientY)) { fieldMapOpen(); return; } joy.on = true; joy.id = e.pointerId; joy.ox = joy.x = e.clientX; joy.oy = joy.y = e.clientY; joy.t0 = performance.now(); });
  addEventListener('pointermove', (e) => { if (joy.on && e.pointerId === joy.id) { joy.x = e.clientX; joy.y = e.clientY; } });
  const up = (e) => { if (e.pointerId === joy.id) { const tap = performance.now() - joy.t0 < 230 && Math.hypot(joy.x - joy.ox, joy.y - joy.oy) < 12; joy.on = false; joy.id = null; if (tap && MODE === 'arena' && A && A.state === 'play') { const p = A.p; dash(e.clientX - X(p.x), e.clientY - Y(p.y)); } } };
  addEventListener('pointerup', up); addEventListener('pointercancel', up);
  addEventListener('keydown', (e) => { if (MODE === 'rope' && /^[1-4]$/.test(e.key) && $('ov').hidden) { ropeChoose(['read', 'guard', 'charge', 'swap'][+e.key - 1]); return; } if ((e.key === 'q' || e.key === 'Q') && MODE === 'arena' && A && A.state === 'play') { swapPet(); return; }
    if ((e.key === ' ' || e.key === 'Shift') && MODE === 'arena' && A && A.state === 'play') { e.preventDefault(); if (A.kind === 'mu') { musouGo(); return; } const [mx, my] = moveVec(); dash(mx, my); return; } if ((e.key === 'e' || e.key === 'E') && MODE === 'arena' && A && A.kind === 'mu') { horseBtn(); return; } if ((e.key === 'm' || e.key === 'M') && MODE === 'arena' && A && A.map) { fieldMapOpen(); return; } if ((e.key === 'e' || e.key === 'E' || e.key === 'Enter') && MODE === 'world' && !TALK.on && $('ov').hidden) { const b = $('wp').querySelector('[data-w]'); if (b) { e.preventDefault(); b.click(); return; } } keys[e.key.toLowerCase()] = true; if (TALK.on && TALK.opts && TALK.i >= TALK.lines.length - 1 && /^[1-4]$/.test(e.key)) { pickChoice(+e.key - 1); return; } if ((e.key === 'Enter' || e.key === ' ') && TALK.on) { e.preventDefault(); talkNext(); } });
  addEventListener('keyup', (e) => { keys[e.key.toLowerCase()] = false; });
  addEventListener('blur', () => { for (const k in keys) keys[k] = false; joy.on = false; });
  function moveVec() { let x = 0, y = 0; if (joy.on) { const dx = joy.x - joy.ox, dy = joy.y - joy.oy, d = Math.hypot(dx, dy); if (d > 8) { const k = Math.min(1, d / 50); x = dx / d * k; y = dy / d * k; } }
    if (keys.arrowleft || keys.a) x = -1; if (keys.arrowright || keys.d) x = 1; if (keys.arrowup || keys.w) y = -1; if (keys.arrowdown || keys.s) y = 1; const d = Math.hypot(x, y); if (d > 1) { x /= d; y /= d; } return [x, y]; }
  // 마을용: 끈 방향의 큰 축 하나만(칸 이동)
  function gridDir() { const [x, y] = moveVec(); if (Math.abs(x) < 0.3 && Math.abs(y) < 0.3) return null; return Math.abs(x) > Math.abs(y) ? (x > 0 ? 'right' : 'left') : (y > 0 ? 'down' : 'up'); }
  const DV = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };

  // ═════════ 대화 상자 ═════════
  const TALK = { on: false, lines: [], i: 0, name: '', done: null, opts: null };
  function talk(name, lines, done) { TALK.opts = null; TALK.on = true; TALK.name = name; TALK.lines = lines; TALK.i = 0; TALK.done = done || null; inputLock = true; joy.on = false; showTalk(); }
  function showTalk() { const t = $('talk'); t.hidden = false; const last = TALK.i >= TALK.lines.length - 1, ops = last && TALK.opts;
    t.innerHTML = `${TALK.name ? `<b>${TALK.name}</b>` : ''}${TALK.lines[TALK.i]}${ops ? `<div class="ch">${TALK.opts.map((o, i) => `<button type="button" data-ch="${i}">${o.l}</button>`).join('')}</div>` : `<span class="nx">${!last ? '눌러서 계속 ▼' : '눌러서 닫기'}</span>`}`;
    if (ops) t.querySelectorAll('[data-ch]').forEach((b) => b.onclick = (e) => { e.stopPropagation(); pickChoice(+b.dataset.ch); }); }
  // 대화 선택지: 마지막 줄에 버튼 2~3개 — 고르기 전엔 닫히지 않음
  function choose(name, lines, opts) { if (typeof lines === 'string') lines = [lines]; TALK.on = true; TALK.name = name; TALK.lines = lines; TALK.i = 0; TALK.done = null; TALK.opts = opts; inputLock = true; joy.on = false; showTalk(); }
  function pickChoice(i) { const o = TALK.opts && TALK.opts[i]; if (!o) return; TALK.on = false; TALK.opts = null; $('talk').hidden = true; inputLock = false; sfx('accept', 0.25); o.fn && o.fn(); }
  function talkNext() { if (!TALK.on) return; if (TALK.opts && TALK.i >= TALK.lines.length - 1) return; TALK.i++; if (TALK.i >= TALK.lines.length) { TALK.on = false; $('talk').hidden = true; inputLock = false; const d = TALK.done; TALK.done = null; d && d(); } else showTalk(); }
  $('talk').addEventListener('click', talkNext);

  // ═════════ 지도 48×48: 가운데 책방골 — 북쪽 박골 들길 → 옛이야기 고을(도서관 1) / 서·동·남은 흥부전 결말을 보면 펼쳐지는 장(章) ═════════
  const MW = 48, MH = 76;
  const GROUND = [], SOLID = [];
  for (let y = 0; y < MH; y++) { GROUND.push(new Array(MW).fill('grass')); SOLID.push(new Array(MW).fill(false)); }
  const setG = (x, y, k, solid) => { if (x < 0 || y < 0 || x >= MW || y >= MH) return; GROUND[y][x] = k; SOLID[y][x] = !!solid; };
  const rect = (x0, y0, x1, y1, k, solid) => { for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) setG(x, y, k, solid); };
  const trees = (list) => { for (const [x, y] of list) setG(x, y, 'tree', true); };
  const flowers = (list) => { for (const [x, y] of list) setG(x, y, 'flower'); };
  const deco = (list, k) => { for (const [x, y] of list) setG(x, y, k, true); };
  // 큰 장식(여러 칸 그림, 한 칸 차지): 감나무·솟대·장승
  const DECOR = [];
  const big = (x, y, k) => { DECOR.push({ x, y, k }); setG(x, y, 'grass', true); };
  // ── 테두리 숲
  for (let i = 0; i < Math.max(MW, MH); i++) for (const j of [0, 1]) { setG(i, j, 'tree', true); setG(i, MH - 1 - j, 'tree', true); setG(j, i, 'tree', true); setG(MW - 1 - j, i, 'tree', true); }
  // ── 옛이야기 고을(북쪽 끝, y 2~9): 옛이야기관의 고을 — 초가·장독대·박 넝쿨·감나무·솟대·장승
  rect(4, 6, 44, 7, 'path'); rect(7, 5, 7, 5, 'path'); rect(38, 5, 38, 5, 'path'); rect(23, 8, 24, 9, 'path');
  deco([[11, 3], [12, 3], [13, 3], [11, 4], [13, 4]], 'jar'); deco([[34, 3], [35, 3], [34, 4]], 'jar');
  deco([[16, 5], [17, 5], [30, 5], [31, 5], [42, 3]], 'gourd'); deco([[44, 8]], 'stele');
  big(15, 3, 'treeO'); big(32, 3, 'treeO'); big(21, 8, 'sotdae'); big(26, 8, 'jangseung'); big(27, 8, 'jangseung2'); big(5, 9, 'treeO'); big(42, 9, 'treeO');
  flowers([[9, 8], [18, 8], [29, 8], [41, 6], [12, 8], [35, 8]]); setG(25, 6, 'sign', true);
  rect(2, 10, 45, 10, 'fence', true); rect(23, 10, 24, 10, 'path');
  // ── 박골 들길(y 11~41): 굽이굽이 긴 길 — 떠도는 페이지, 길의 독자 3명
  rect(23, 11, 24, 16, 'path'); rect(8, 15, 24, 16, 'path'); rect(8, 15, 9, 26, 'path'); rect(8, 25, 39, 26, 'path'); rect(38, 25, 39, 34, 'path'); rect(23, 33, 39, 34, 'path'); rect(23, 33, 24, 41, 'path');
  rect(3, 12, 6, 22, 'bush'); rect(12, 18, 20, 23, 'bush'); rect(28, 12, 37, 20, 'bush'); rect(41, 14, 44, 30, 'bush'); rect(4, 29, 18, 38, 'bush'); rect(27, 28, 35, 31, 'bush'); rect(30, 36, 44, 40, 'bush');
  trees([[11, 12], [14, 12], [18, 13], [26, 12], [27, 16], [39, 12], [40, 18], [21, 18], [11, 22], [3, 25], [5, 27], [14, 27], [20, 28], [24, 29], [25, 22], [33, 23], [36, 22], [40, 32], [43, 33], [36, 38], [20, 36], [17, 40], [26, 37], [10, 40], [5, 40], [29, 40], [44, 40], [3, 34], [21, 31], [12, 25]]);
  flowers([[21, 13], [26, 14], [6, 24], [16, 28], [31, 23], [35, 27], [41, 35], [27, 39], [19, 38], [10, 17]]); setG(22, 39, 'sign', true);
  // ── 책방골(가운데, x 16~31, y 42~57): 울타리 고리 + 네 문, 사방 큰길
  rect(23, 42, 24, 57, 'path'); rect(2, 49, 45, 50, 'path');
  rect(16, 42, 31, 42, 'fence', true); rect(16, 57, 31, 57, 'fence', true); rect(16, 42, 16, 57, 'fence', true); rect(31, 42, 31, 57, 'fence', true);
  rect(23, 42, 24, 42, 'path'); rect(23, 57, 24, 57, 'path'); rect(16, 49, 16, 50, 'path'); rect(31, 49, 31, 50, 'path'); rect(23, 58, 24, 58, 'path');
  rect(20, 47, 20, 48, 'path'); rect(28, 47, 28, 48, 'path'); rect(20, 55, 20, 56, 'path');
  rect(26, 52, 30, 55, 'dirt'); setG(28, 53, 'well', true);
  flowers([[17, 43], [30, 43], [22, 45], [25, 44], [17, 56], [25, 55], [18, 51], [30, 47]]); setG(22, 48, 'sign', true);
  trees([[17, 46], [30, 45], [17, 53]]);
  // ── 흥부네 박밭(서, 결말 '착한' 뒤)
  rect(4, 43, 13, 46, 'dirt'); deco([[5, 44], [7, 44], [9, 44], [11, 44], [6, 45], [8, 45], [10, 45], [12, 45]], 'gourd'); deco([[4, 53], [5, 53], [4, 54]], 'jar');
  trees([[3, 56], [14, 43], [14, 56], [9, 55]]); flowers([[6, 52], [11, 53], [13, 47]]); big(10, 53, 'treeO');
  // ── 놀부네 곳간 길(동, 결말 '욕심' 뒤)
  rect(34, 43, 44, 43, 'fence', true); deco([[40, 45]], 'chest'); deco([[42, 45], [43, 45], [42, 46]], 'jar');
  rect(35, 52, 43, 55, 'bush'); trees([[33, 46], [44, 53], [38, 56], [33, 56]]); flowers([[36, 46], [39, 47]]);
  // ── 제비 언덕(남, 결말 '날갯짓' 뒤)
  rect(23, 59, 24, 72, 'path'); rect(5, 61, 15, 67, 'bush'); rect(32, 63, 42, 70, 'bush'); trees([[4, 69], [10, 71], [18, 63], [29, 61], [44, 60], [20, 69], [27, 71], [15, 71], [36, 60]]);
  flowers([[8, 69], [12, 60], [19, 66], [28, 65], [30, 68], [40, 61], [21, 61], [26, 67]]); big(27, 64, 'sotdae');
  setG(22, 72, 'sign', true); setG(3, 48, 'sign', true); setG(44, 51, 'sign', true);
  const SIGNS = {
    '22,48': ['「책방골」', '↑ 박골 들길 → 옛이야기 고을(옛이야기관)', '← · → · ↓ 길은 아직 빈 페이지예요. 흥부전의 결말을 보면 그 이야기의 장이 펼쳐진대요.'],
    '22,39': ['「박골 들길」', '↑ 굽이굽이 올라가면 옛이야기 고을.', '흩어진 페이지가 날아다녀요. 부딪히면 싸움 — 피해 다녀도 돼요.'],
    '25,6': ['「옛이야기 고을」', '옛이야기관 — 사서장 먹선. 끝까지 읽은 책이 있는 독자만 도전할 수 있어요.', '장독대와 박 넝쿨, 솟대와 장승이 지키는 마을이에요.'],
    '22,72': ['「영웅전 고을 가는 길」', '영웅전관(삼국지연의·수호전…) — 다음 시안에서 열려요.'],
    '3,48': ['「모험 고을 가는 길」', '모험관(서유기·아라비안나이트…) — 다음 시안에서 열려요.'],
    '44,51': ['「괴담 고을 가는 길」', '괴담관(전설의 고향 같은 옛 괴담들…) — 다음 시안에서 열려요.'],
  };
  const BUILDINGS = [
    { id: 'library', x: 19, y: 2, w: 10, h: 4, roof: '#7a3a2a', label: '옛이야기관', doors: [4, 5], k: { roof: 'red', wall: 'stone' } },
    { id: 'house3', x: 5, y: 3, w: 5, h: 3, roof: '#5a6a3a', label: '', doors: [2], k: { roof: 'blue', wall: 'stone' } },
    { id: 'house4', x: 36, y: 3, w: 5, h: 3, roof: '#5a6a3a', label: '', doors: [2], k: { roof: 'blue', wall: 'stone' } },
    { id: 'home', x: 18, y: 44, w: 5, h: 3, roof: '#8a5a2a', label: '내 집', doors: [2], k: { roof: 'red', wall: 'wood' } },
    { id: 'shop', x: 26, y: 44, w: 5, h: 3, roof: '#3a5a7a', label: '책방', doors: [2], k: { roof: 'blue', wall: 'wood' } },
    { id: 'house2', x: 18, y: 52, w: 5, h: 3, roof: '#5a6a3a', label: '', doors: [2], k: { roof: 'blue', wall: 'stone' } },
  ];
  const DOOR = {};
  for (const b of BUILDINGS) { b.img = building(b.w, b.h, b.roof, b.label, b.doors); rect(b.x, b.y, b.x + b.w - 1, b.y + b.h - 1, 'grass', true); for (const d of b.doors) DOOR[`${b.x + d},${b.y + b.h - 1}`] = b.id; }
  // 결말로 펼쳐지는 장(빈 페이지로 덮여 있음)
  const ZONES = [
    { id: 'W', n: '흥부네 박밭', need: 'kind', x0: 2, y0: 42, x1: 15, y1: 57 },
    { id: 'E', n: '놀부네 곳간 길', need: 'greed', x0: 32, y0: 42, x1: 45, y1: 57 },
    { id: 'S', n: '제비 언덕', need: 'swift', x0: 2, y0: 59, x1: 45, y1: 73 },
  ];
  const zoneAt = (x, y) => ZONES.find((z) => x >= z.x0 && x <= z.x1 && y >= z.y0 && y <= z.y1);
  const lockedAt = (x, y) => { const z = zoneAt(x, y); return !!(z && !(SV.revealed && SV.revealed[z.id])); };
  function areaName(x, y) { if (x >= 16 && x <= 31 && y >= 42 && y <= 57) return '책방골'; if (y <= 10) return '옛이야기 고을'; if (y <= 41) return '박골 들길'; const z = zoneAt(x, y); return z ? z.n : '책방골 바깥'; }
  function checkReveals() { if (!SV.revealed) SV.revealed = {}; const fresh = ZONES.filter((z) => SV.endings[z.need] && !SV.revealed[z.id]); for (const z of fresh) SV.revealed[z.id] = true; if (fresh.length) { saveSV(); setTimeout(() => banner('새 장이 펼쳐졌어요!', fresh.map((z) => z.n).join(' · ')), 400); } }
  // 떨어진 낱장(밟으면 줍기, 한 번씩)
  const LEAVES = [{ id: 'n1', x: 4, y: 13 }, { id: 'n2', x: 43, y: 15 }, { id: 'n3', x: 6, y: 37 }, { id: 'w1', x: 13, y: 53 }, { id: 'e1', x: 37, y: 55 }, { id: 's1', x: 8, y: 63 }, { id: 's2', x: 39, y: 69 }];
  // 사람들 — sight: 그 방향으로 몇 칸을 보는지(독자는 눈이 마주치면 북 대결)
  const NPCS = [
    { id: 'reader1', x: 16, y: 14, dir: 'down', sight: 2, spr: 'reader1', foe: 'reader1', name: '책벌레 도윤' },
    { id: 'reader2', x: 10, y: 21, dir: 'left', sight: 2, spr: 'reader2', foe: 'reader2', name: '이야기꾼 소리' },
    { id: 'reader3', x: 30, y: 27, dir: 'up', sight: 2, spr: 'reader3', foe: 'reader3', name: '꼬마 사서 보람' },
    { id: 'elder', x: 29, y: 6, dir: 'down', spr: 'shop', name: '옛이야기관 문지기', lines: ['사서장님은 책을 끝까지 읽어 본 독자하고만 겨루셔.', '박골 들길의 독자들을 이겨 보면 감이 올 거야. 동행으로 누굴 데려가고, 몸에 누굴 책갈피로 꽂을지도 잘 생각하고.'] },
    { id: 'granny', x: 10, y: 5, dir: 'down', spr: 'kid', name: '장독대 할머니', lines: ['이 고을은 옛이야기가 오래 묵어서 장맛이 깊어.', '저기 솟대 위 새가 하늘 소식을, 장승이 나쁜 기운을 막아 준단다.'] },
    { id: 'kid', x: 25, y: 53, dir: 'down', spr: 'kid', name: '동네 아이', lines: ['들길엔 책에서 흩어진 페이지가 날아다녀! 부딪히면 싸움이 붙어.', `이기면 낱장이 나와. ${LEAVES_PER_BOOK}장 모으면 책방에서 한 권으로 묶어 준대.`, '흥부전을 끝까지 읽으면 빈 페이지였던 길이 펼쳐진대. 결말마다 다른 길이!'] },
    { id: 'heungkid', x: 7, y: 48, dir: 'right', spr: 'reader1', name: '흥부네 막내', zone: 'W', gift: { coins: 30 }, lines: ['우리 박밭에 와 줬구나! 형아 덕분에 박이 주렁주렁 열렸어.', '이거 받아. 박 속에서 나온 엽전이야. (엽전 +30)'] },
    { id: 'swallowkeeper', x: 25, y: 63, dir: 'down', spr: 'reader2', name: '제비 언덕 아가씨', zone: 'S', gift: { leaves: 2 }, lines: ['제비가 물어 온 낱장이에요. 강남 갔다 오면서 주워 왔대요. (낱장 +2)'] },
  ];
  const isDirt = (x, y) => GROUND[y] && (GROUND[y][x] === 'dirt' || GROUND[y][x] === 'well');
  function dirtTile(x, y) { if (!TILE.dirt9) return TILE.path[0]; const n = !isDirt(x, y - 1), s = !isDirt(x, y + 1), w = !isDirt(x - 1, y), e = !isDirt(x + 1, y); const r = n ? 0 : s ? 2 : 1, c = w ? 0 : e ? 2 : 1; return TILE.dirt9[r * 3 + c]; }
  const isPath = (x, y) => GROUND[y] && (GROUND[y][x] === 'path' || (GROUND[y][x] === 'sign') || DOOR[`${x},${y}`] || (x < 0 || x >= MW));
  function pathTile(x, y) { const n = !isPath(x, y - 1), s = !isPath(x, y + 1), w = !isPath(x - 1, y), e = !isPath(x + 1, y); const r = n && !s ? 0 : s && !n ? 2 : 1, c = w && !e ? 0 : e && !w ? 2 : 1; return TILE.path9[r * 3 + c]; }
  const npcAt = (x, y) => NPCS.find((n) => n.x === x && n.y === y && !(n.zone && lockedAt(n.x, n.y)));
  const passable = (x, y) => x >= 0 && y >= 0 && x < MW && y < MH && !SOLID[y][x] && !npcAt(x, y) && !lockedAt(x, y);
  // ═════════ 흩어진 페이지(보이는 만남): 들길·열린 장을 날아다니고, 부딪히면 싸움. 가까우면 다가옴 ═════════
  const PZ = [{ id: 'N', x0: 3, y0: 12, x1: 44, y1: 40, max: 7, set: 'N' }, { id: 'W', x0: 3, y0: 43, x1: 15, y1: 56, max: 3, set: 'W' }, { id: 'E', x0: 32, y0: 44, x1: 44, y1: 56, max: 3, set: 'E' }, { id: 'S', x0: 3, y0: 60, x1: 44, y1: 72, max: 4, set: 'S' }];
  let FLY = []; let flySpawnT = 0;
  const flyOpen = (z) => z.id === 'N' || (SV.revealed && SV.revealed[z.id]);
  const flyFree = (x, y) => x >= 0 && y >= 0 && x < MW && y < MH && !SOLID[y][x] && !lockedAt(x, y) && !npcAt(x, y) && !DOOR[`${x},${y}`] && !FLY.some((f) => f.x === x && f.y === y);
  function spawnFly(z, far) { for (let k = 0; k < 40; k++) { const x = z.x0 + Math.floor(Math.random() * (z.x1 - z.x0 + 1)), y = z.y0 + Math.floor(Math.random() * (z.y1 - z.y0 + 1)); if (!flyFree(x, y)) continue; if (far && Math.abs(x - T.x) + Math.abs(y - T.y) < 7) continue; FLY.push({ x, y, px: x, py: y, fx: x, fy: y, t: 1, next: 0.4 + Math.random(), z: z.id, ph: Math.random() * 6 }); return; } }
  function flyUpdate(dt) {
    flySpawnT -= dt; if (flySpawnT <= 0) { flySpawnT = 6; for (const z of PZ) if (flyOpen(z) && FLY.filter((f) => f.z === z.id).length < z.max) spawnFly(z, true); }
    for (const f of FLY) { f.ph += dt; if (f.t < 1) { f.t = Math.min(1, f.t + dt / 0.45); f.px = f.fx + (f.x - f.fx) * f.t; f.py = f.fy + (f.y - f.fy) * f.t; continue; }
      f.next -= dt; if (f.next > 0) continue; f.next = 0.5 + Math.random() * 0.7; const z = PZ.find((q) => q.id === f.z), d = Math.abs(f.x - T.x) + Math.abs(f.y - T.y);
      let opts = Object.values(DV).map(([dx, dy]) => [f.x + dx, f.y + dy]).filter(([x, y]) => x >= z.x0 && x <= z.x1 && y >= z.y0 && y <= z.y1 && (flyFree(x, y) || (x === T.x && y === T.y)));
      if (d <= 4 && Math.random() < 0.6) opts.sort((a, b) => (Math.abs(a[0] - T.x) + Math.abs(a[1] - T.y)) - (Math.abs(b[0] - T.x) + Math.abs(b[1] - T.y))); else opts.sort(() => Math.random() - 0.5);
      if (opts.length) { f.fx = f.x; f.fy = f.y; [f.x, f.y] = opts[0]; f.t = 0; } }
    if (!inputLock && $('ov').hidden && MODE === 'town') { const hit = FLY.find((f) => Math.abs(f.px - T.px) < 0.6 && Math.abs(f.py - T.py) < 0.6); if (hit) { FLY = FLY.filter((f) => f !== hit); inputLock = true; joy.on = false; sfx('alert', 0.35); const zs = hit.z; flash(() => { inputLock = false; startWild(zs); }); } }
  }

  // ═════════ 마을 상태 ═════════
  const T = { x: SV.pos.x, y: SV.pos.y, px: SV.pos.x, py: SV.pos.y, dir: SV.pos.d || 'up', moving: false, fromX: 0, fromY: 0, t: 0, step: 0, petX: SV.pos.x, petY: SV.pos.y + 1, petFX: 0, petFY: 0, petPX: SV.pos.x, petPY: SV.pos.y + 1, sinceEnc: 0, bang: null, time: 0 };
  const STEP = 0.16;
  function placeTown(x, y, d) { T.x = T.px = x; T.y = T.py = y; T.dir = d; T.moving = false; const [dx, dy] = DV[d]; T.petX = T.petPX = x - dx; T.petY = T.petPY = y - dy; if (!passable(T.petX, T.petY) && !(T.petX === x && T.petY === y)) { T.petX = T.petPX = x; T.petY = T.petPY = y; } SV.pos = { x, y, d }; }
  const musicFor = () => { const a = areaName(T.x, T.y); return a === '책방골' || a === '옛이야기 고을' ? 'town' : 'road'; };
  function enterTown() { checkReveals(); music(musicFor()); setMode('town'); $('hud').hidden = false; $('hpw').style.display = 'none'; hudUpdate(); }
  function tryMove(dir) {
    T.dir = dir; const [dx, dy] = DV[dir], nx = T.x + dx, ny = T.y + dy, key = `${nx},${ny}`;
    if (DOOR[key]) return enterBuilding(DOOR[key]);
    if (SIGNS[key] && !lockedAt(nx, ny)) return talk('', SIGNS[key]);
    if (GROUND[ny] && GROUND[ny][nx] === 'chest' && !lockedAt(nx, ny)) { if (SV.picked.chestE) return talk('', ['텅 빈 곳간 상자예요.']); SV.picked.chestE = true; SV.coins += 60; saveSV(); hudUpdate(); sfx('kill', 0.5); return talk('', ['놀부네 곳간 상자를 열었어요!', '엽전 60닢이 쏟아졌어요. 놀부가 알면 펄쩍 뛰겠네요.']); }
    if (lockedAt(nx, ny)) { T.dir = dir; return talk('', ['빈 페이지예요. 아직 쓰이지 않은 이야기라 지나갈 수 없어요.', '흥부전의 다른 결말을 보면 이 장이 펼쳐질지도 몰라요.']); }
    const n = npcAt(nx, ny); if (n) return talkNpc(n);
    if (!passable(nx, ny)) return;
    T.fromX = T.x; T.fromY = T.y; T.petFX = T.petX; T.petFY = T.petY; T.petX = T.x; T.petY = T.y; T.x = nx; T.y = ny; T.moving = true; T.t = 0; T.step ^= 1;
  }
  function arrived() {
    SV.pos = { x: T.x, y: T.y, d: T.dir }; hudUpdate(); music(musicFor());
    // 독자의 시선
    for (const n of NPCS) { if (!n.sight || SV.beaten[n.id]) continue; const [dx, dy] = DV[n.dir]; for (let k = 1; k <= n.sight; k++) { const sx = n.x + dx * k, sy = n.y + dy * k; if (SOLID[sy] && SOLID[sy][sx]) break; if (sx === T.x && sy === T.y) { spotted(n); return; } } }
    const lf = LEAVES.find((l) => l.x === T.x && l.y === T.y && !SV.picked[l.id]); if (lf) { SV.picked[lf.id] = true; SV.leaves++; saveSV(); hudUpdate(); banner('떨어진 낱장을 주웠어요!', `낱장 ${SV.leaves}/${LEAVES_PER_BOOK}`); }
  }
  function spotted(n) { sfx('alert', 0.5); inputLock = true; joy.on = false; T.bang = { n, t: 0.8 }; T.dir = { left: 'right', right: 'left', up: 'down', down: 'up' }[n.dir]; setTimeout(() => { T.bang = null; const F = FOES[n.foe]; talk(F.n, F.hi, () => duelIntro(n.foe)); }, 800); }
  function talkNpc(n) {
    n.dir = { left: 'right', right: 'left', up: 'down', down: 'up' }[T.dir];
    if (n.foe) { const F = FOES[n.foe]; if (SV.beaten[n.foe]) return talk(F.n, F.lose.slice(-1)); return talk(F.n, F.hi, () => duelIntro(n.foe)); }
    if (n.gift) { if (SV.picked['gift_' + n.id]) return talk(n.name, [n.lines[0], '또 와 줘서 고마워!']); SV.picked['gift_' + n.id] = true; if (n.gift.coins) SV.coins += n.gift.coins; if (n.gift.leaves) SV.leaves += n.gift.leaves; saveSV(); hudUpdate(); sfx('kill', 0.4); return talk(n.name, n.lines); }
    talk(n.name, n.lines);
  }
  let flashT = 0, flashCb = null; function flash(cb) { flashT = 0.6; flashCb = cb; }
  function townUpdate(dt) {
    T.time += dt;
    if (flashT > 0) { flashT -= dt; if (flashT <= 0) { const cb = flashCb; flashCb = null; cb && cb(); } return; }
    if (T.bang) { T.bang.t -= dt; }
    if (T.moving) { T.t += dt / STEP; if (T.t >= 1) { T.t = 1; T.moving = false; T.px = T.x; T.py = T.y; T.petPX = T.petX; T.petPY = T.petY; arrived(); } else { T.px = T.fromX + (T.x - T.fromX) * T.t; T.py = T.fromY + (T.y - T.fromY) * T.t; T.petPX = T.petFX + (T.petX - T.petFX) * T.t; T.petPY = T.petFY + (T.petY - T.petFY) * T.t; } }
    if (!T.moving && !inputLock && $('ov').hidden) { const d = gridDir(); if (d) tryMove(d); }
    flyUpdate(dt);
  }
  // ═════════ 마을 그리기 ═════════
  let Z = 2;
  function townZoom() { Z = clamp(Math.floor(Math.min(W / (16 * 11), H / (16 * 14))), 2, 6); }
  function townRender() {
    townZoom(); ctx.setTransform(DPR, 0, 0, DPR, 0, 0); ctx.imageSmoothingEnabled = false; ctx.fillStyle = '#1d1813'; ctx.fillRect(0, 0, W, H);
    const tz = TS * Z; let cx = (T.px + 0.5) * tz - W / 2, cy = (T.py + 0.5) * tz - H / 2 - 20;
    cx = clamp(cx, 0, Math.max(0, MW * tz - W)); cy = clamp(cy, -60, Math.max(0, MH * tz - H)); cx = Math.round(cx); cy = Math.round(cy);
    const x0 = Math.max(0, Math.floor(cx / tz)), y0 = Math.max(0, Math.floor(cy / tz)), x1 = Math.min(MW - 1, Math.ceil((cx + W) / tz)), y1 = Math.min(MH - 1, Math.ceil((cy + H) / tz));
    const wf = Math.floor(T.time * 2) % 2, bf = Math.floor(T.time * 1.5) % 2;
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) { const k = GROUND[y][x], h = (x * 7 + y * 13) % 4; let img = TILE.grass[h];
      if (k === 'path') img = TILE.path9 ? pathTile(x, y) : TILE.path[h % 2]; else if (k === 'flower' && TILE.flowerV) img = TILE.flowerV[(x * 3 + y) % TILE.flowerV.length]; else if (k === 'water') img = TILE.water[wf]; else if (k === 'bush') img = TILE.bush[(bf + x + y) % 2]; else if (k === 'dirt') img = dirtTile(x, y); else if (k === 'tree') img = TILE.tree2 && h === 3 ? TILE.tree2 : TILE.tree; else if (k === 'jar' && TILE.jarV) img = TILE.jarV[(x + y) % TILE.jarV.length]; else if (k === 'chest' && SV.picked.chestE && TILE.chestOpen) img = TILE.chestOpen; else if (k !== 'grass') img = TILE[k] || TILE.grass[0];
      if (lockedAt(x, y)) img = TILE.blank;
      ctx.drawImage(img, x * tz - cx, y * tz - cy, tz, tz); }
    for (const b of BUILDINGS) ctx.drawImage(b.img, b.x * tz - cx, b.y * tz - cy, b.w * tz, b.h * tz);
    for (const l of LEAVES) { if (SV.picked && SV.picked[l.id]) continue; const lx = l.x * tz - cx, ly = l.y * tz - cy + Math.round(Math.sin(T.time * 3) * Z); ctx.fillStyle = '#1d140e'; ctx.fillRect(lx + 4 * Z, ly + 4 * Z, 9 * Z, 8 * Z); ctx.fillStyle = '#fffaf0'; ctx.fillRect(lx + 5 * Z, ly + 5 * Z, 7 * Z, 6 * Z); ctx.fillStyle = '#8a6a3a'; ctx.fillRect(lx + 6 * Z, ly + 7 * Z, 5 * Z, Z); ctx.fillRect(lx + 6 * Z, ly + 9 * Z, 4 * Z, Z); }
    // 사람들·큰 나무 (y 순서)
    const list = [];
    if (TILE.bigTree) for (let y = Math.max(0, y0 - 1); y <= Math.min(MH - 1, y1 + 1); y++) for (let x = Math.max(0, x0 - 1); x <= Math.min(MW - 1, x1 + 1); x++) if (GROUND[y][x] === 'tree') { const img = TILE.bigTree[(x * 5 + y * 3) % 3]; list.push({ y: y + 0.2, draw: () => ctx.drawImage(img, x * tz - cx - tz / 2, y * tz - cy - tz, tz * 2, tz * 2) }); }
    for (const d of DECOR) { if (d.x < x0 - 2 || d.x > x1 + 2 || d.y < y0 - 1 || d.y > y1 + 3 || lockedAt(d.x, d.y)) continue; list.push({ y: d.y + 0.2, draw: () => { const sx = d.x * tz - cx, sy = d.y * tz - cy;
      if (d.k === 'treeO') { if (TILE.treeO) ctx.drawImage(TILE.treeO, sx - tz, sy - 2 * tz, tz * 3, tz * 3); else ctx.drawImage(TILE.bigTree ? TILE.bigTree[0] : TILE.tree, sx - tz / 2, sy - tz, tz * 2, tz * 2); }
      else if (d.k === 'sotdae') ctx.drawImage(SOTDAE, sx, sy - tz, tz, tz * 2); else ctx.drawImage(JANG[d.k === 'jangseung2' ? 1 : 0], sx, sy - tz, tz, tz * 2); } }); }
    for (const f of FLY) { if (f.px < x0 - 1 || f.px > x1 + 1 || f.py < y0 - 1 || f.py > y1 + 1) continue; list.push({ y: f.py + 0.1, draw: () => drawFly(f, cx, cy, tz) }); }
    list.push(...NPCS.filter((n) => !(n.zone && lockedAt(n.x, n.y))).map((n) => ({ y: n.y, draw: () => drawPerson(SPR[n.spr], n.x, n.y, n.dir, 0, cx, cy, tz) })));
    const fol = SV.load.c; if (fol && PSPR[fol]) list.push({ y: T.petPY - 0.01, draw: () => { const w = NINJA && NS['p_' + fol]; if (w) { drawWalker(w, T.dir, T.moving ? walkF() : (w.strip ? Math.floor(T.time * 4) : 0), T.petPX * tz - cx, T.petPY * tz - cy + (w.strip ? tz - tz * w.h / w.w : 0), tz); return; } const bob = T.moving ? Math.round(Math.sin(T.t * Math.PI) * Z) : 0; ctx.drawImage(PSPR[fol], T.petPX * tz - cx, T.petPY * tz - cy - bob, tz, tz); } });
    list.push({ y: T.py, draw: () => { const ac = auraColors(), bx = T.px * tz - cx + tz / 2, by = T.py * tz - cy + tz - 2 * Z; ctx.strokeStyle = '#ffd34a'; ctx.lineWidth = Math.max(2, Z); ctx.beginPath(); ctx.ellipse(bx, by, 7 * Z, 2.6 * Z, 0, 0, 7); ctx.stroke(); ac.forEach((c, i) => { ctx.save(); ctx.globalAlpha = 0.45 + 0.2 * Math.sin(T.time * 3 + i); ctx.fillStyle = c; ctx.beginPath(); ctx.ellipse(bx, by, (7 + i * 2) * Z, (2.5 + i) * Z, 0, 0, 7); ctx.fill(); ctx.restore(); }); const bd = SV.load.b1; if (bd && NINJA && NS['p_' + bd]) { const s2 = tz * 1.7, hov = Math.sin(T.time * 2.4) * 2 * Z; ctx.globalAlpha = 0.38; drawWalker(NS['p_' + bd], T.dir, NS['p_' + bd].strip ? Math.floor(T.time * 4) : 0, T.px * tz - cx + tz / 2 - s2 / 2, T.py * tz - cy + tz - s2 - 2 * Z + hov, s2); ctx.globalAlpha = 1; }
      drawPerson(SPR.me, T.px, T.py, T.dir, T.moving ? (SPR.me.walker ? walkF() : T.step) : 0, cx, cy, tz, T.moving && !SPR.me.walker ? Math.round(Math.sin(T.t * Math.PI) * Z) : 0); if (GROUND[T.y][T.x] === 'bush' && !T.moving) ctx.drawImage(TILE.bush[bf], 0, 9, 16, 7, T.px * tz - cx, T.py * tz - cy + 9 * Z, tz, 7 * Z); } });
    list.sort((a, b) => a.y - b.y).forEach((o) => o.draw());
    { const bx = T.px * tz - cx + tz / 2, by = T.py * tz - cy - 3 * Z + Math.sin(T.time * 5) * 2 * Z; ctx.fillStyle = '#ffd34a'; ctx.strokeStyle = '#3f2832'; ctx.lineWidth = Z; ctx.beginPath(); ctx.moveTo(bx - 4 * Z, by - 5 * Z); ctx.lineTo(bx + 4 * Z, by - 5 * Z); ctx.lineTo(bx, by); ctx.closePath(); ctx.fill(); ctx.stroke(); }
    if (T.bang && T.bang.t > 0) { const n = T.bang.n, bx = n.x * tz - cx + tz / 2, by = n.y * tz - cy - 4 * Z; ctx.fillStyle = '#fffaf0'; ctx.strokeStyle = '#1d140e'; ctx.lineWidth = Z; ctx.fillRect(bx - 4 * Z, by - 10 * Z, 8 * Z, 10 * Z); ctx.strokeRect(bx - 4 * Z, by - 10 * Z, 8 * Z, 10 * Z); ctx.fillStyle = '#b8432f'; ctx.fillRect(bx - Z, by - 8 * Z, 2 * Z, 5 * Z); ctx.fillRect(bx - Z, by - 2 * Z, 2 * Z, Z); }
    if (flashT > 0) { const a = Math.floor(flashT * 10) % 2 ? 0.85 : 0.1; ctx.fillStyle = `rgba(29,24,19,${a})`; ctx.fillRect(0, 0, W, H); }
    if (joy.on) drawJoy();
  }
  const walkF = () => (T.step ? (T.t < 0.5 ? 1 : 2) : (T.t < 0.5 ? 3 : 0));
  function drawPerson(spr, x, y, dir, st, cx, cy, tz, bob = 0) { if (spr.walker) { drawWalker(spr, dir, st, x * tz - cx, y * tz - cy - bob, tz); return; } const key = (dir === 'left' || dir === 'right' ? 'side' : dir) + st, img = spr[key], dx = x * tz - cx, dy = y * tz - cy - bob;
    if (dir === 'left') { ctx.save(); ctx.translate(dx + tz, dy); ctx.scale(-1, 1); ctx.drawImage(img, 0, 0, tz, tz); ctx.restore(); } else ctx.drawImage(img, dx, dy, tz, tz); }
  // 흩어진 페이지: 펄럭이며 떠다니는 종이 한 장
  function drawFly(f, cx, cy, tz) { const bx = f.px * tz - cx + tz / 2, by = f.py * tz - cy + tz / 2, hov = Math.sin(f.ph * 3) * 3 * Z, w = Math.max(0.25, Math.abs(Math.cos(f.ph * 2.2))) * 6 * Z;
    ctx.fillStyle = 'rgba(40,30,20,0.22)'; ctx.beginPath(); ctx.ellipse(bx, by + 6 * Z, 5 * Z, 1.6 * Z, 0, 0, 7); ctx.fill();
    ctx.save(); ctx.translate(bx, by - 3 * Z + hov); ctx.rotate(Math.sin(f.ph * 1.7) * 0.25); ctx.fillStyle = '#3f2832'; ctx.fillRect(-w - Z, -5 * Z - Z, 2 * w + 2 * Z, 10 * Z + 2 * Z); ctx.fillStyle = '#fffaf0'; ctx.fillRect(-w, -5 * Z, 2 * w, 10 * Z); ctx.fillStyle = '#b8a888'; for (let i = -3; i <= 3; i += 2) ctx.fillRect(-w + Z, i * Z, Math.max(0, 2 * w - 2 * Z), Math.max(1, Z * 0.6)); ctx.fillStyle = '#b8432f'; ctx.fillRect(-w, -5 * Z, Math.min(2 * w, 2 * Z), 10 * Z); ctx.restore(); }
  function drawJoy() { ctx.globalAlpha = 0.45; ctx.strokeStyle = '#f4ecd8'; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(joy.ox, joy.oy, 50, 0, 7); ctx.stroke(); const dx = joy.x - joy.ox, dy = joy.y - joy.oy, d = Math.hypot(dx, dy), k = d > 50 ? 50 / d : 1; ctx.fillStyle = '#f4ecd8'; ctx.beginPath(); ctx.arc(joy.ox + dx * k, joy.oy + dy * k, 20, 0, 7); ctx.fill(); ctx.globalAlpha = 1; }
