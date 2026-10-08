  // ═════════ 화면 카드 · 상태 띠 ═════════
  function card(html, bind) { $('card').innerHTML = html; $('ov').hidden = false; joy.on = false; bind && bind($('card')); }
  function closeCard() { $('ov').hidden = true; }
  let bannerT = 0; function banner(t, s) { const b = $('banner'); b.innerHTML = `${t}${s ? `<small>${s}</small>` : ''}`; b.classList.add('show'); clearTimeout(bannerT); bannerT = setTimeout(() => b.classList.remove('show'), 2200); }
  const petIcon = (id) => `<span class="ic" style="background:${PETS[id].c}">${PETS[id].g}</span>`;
  const owned = () => Object.keys(PETS).filter((id) => SV.pets[id]);
  const petLine = (id) => { const P = SV.pets[id]; return `${PETS[id].n} ${P.lvl}단계`; };
  const xpBar = (id) => { const P = SV.pets[id]; return `<div class="xp"><i style="width:${Math.min(100, P.xp / xpNeed(P.lvl) * 100)}%"></i></div>`; };
  function petOpts(sel, attr = 'data-pet', disable = () => false) { return owned().map((id) => { const P = PETS[id]; return `<button class="opt ${id === sel ? 'on' : ''}" type="button" ${attr}="${id}" ${disable(id) ? 'disabled' : ''}>${petIcon(id)}<b>${P.n} · ${SV.pets[id].lvl}단계 <small style="font-weight:400;color:var(--paper-muted)">${P.role}</small></b><span>${P.d}</span></button>`; }).join(''); }
  // ── 데리고 다니기(최대 5) · 동행(처음 나가는 소환수, 싸움 중 교대) · 책갈피(몸 하나 — 그 소환수의 무기 형태 + 몸 효과). 마을에서만 바꿈
  const SLOT_ALL = ['c', 'b1'];
  const slotName = { c: '동행', b1: '책갈피' };
  const slotOf = (id) => SLOT_ALL.find((k) => SV.load[k] === id) || null;
  const inParty = (id) => SV.party.includes(id);
  function slotEffect(slot, id) { if (slot === 'c') return `${PETS[id].d} · 기력을 쓰면 지쳐서 교대가 필요해요`; return `<b>${WEAP[id].n}</b>(공격) — ${WEAP[id].d}<br><b>${BODY[id].n}</b>(몸) — ${BODY[id].d}${SV.pets[id].lvl > 1 ? ` (${SV.pets[id].lvl}단계: 더 셈)` : ''}`; }
  function assign(slot, id) { const L = SV.load; if (id) { const from = slotOf(id); if (from) L[from] = null; if (!inParty(id) && SV.party.length < PARTY_MAX) SV.party.push(id); } L[slot] = id; saveSV(); }
  function togglePartyMember(id) { if (inParty(id)) { if (SV.party.length <= 1) return; SV.party = SV.party.filter((p) => p !== id); for (const k of SLOT_ALL) if (SV.load[k] === id) SV.load[k] = null; } else if (SV.party.length < PARTY_MAX) SV.party.push(id); saveSV(); }
  function loadoutHTML(withParty) {
    const L = SV.load, row = (k) => { const id = L[k]; const eff = id ? slotEffect(k, id) : k === 'c' ? '혼자 싸워요' : '맨 책장 · 몸 효과 없음'; return `<button class="opt" type="button" data-slotpick="${k}">${id ? petIcon(id) : '<span class="ic" style="background:#e8dcb0">' + slotName[k][0] + '</span>'}<b>${slotName[k]} · ${id ? `${PETS[id].n} ${SV.pets[id].lvl}단계` : '—'}</b><span>${eff}</span></button>`; };
    const party = withParty ? `<h3>데리고 다니기 ${SV.party.length}/${PARTY_MAX}</h3><p style="font-size:.8rem">데려간 소환수끼리 싸움 중 <b>교대</b>(Q·교대 버튼)할 수 있어요. 기술을 쓰면 기력이 줄고, 쉬는 동안 뒤에서 회복해요.</p><div style="display:flex;flex-wrap:wrap;gap:6px">${owned().map((id) => `<button class="sub" style="padding:6px 10px;${inParty(id) ? 'border-color:#6b5a3a;border-width:2px;font-weight:700' : 'opacity:.6'}" type="button" data-party="${id}">${inParty(id) ? '✓ ' : ''}${PETS[id].n} ${SV.pets[id].lvl}</button>`).join('')}</div>` : '';
    return `<p style="font-size:.82rem"><b>동행</b>은 곁에서 함께 싸우고, <b>책갈피</b>는 그 인물의 쪽에 꽂아 두는 것 — 영혼이 나를 감싸 공격 방식과 몸 효과를 줘요. 한 소환수는 한 곳에만.</p>${SLOT_ALL.map(row).join('')}${party}`;
  }
  function chooseSlot(slot, back) {
    const cur = SV.load[slot];
    card(`<h2>${slot === 'c' ? '동행으로 데려가기' : '책갈피 꽂기'}</h2><p>${slot === 'c' ? '싸움이 시작되면 먼저 나가는 소환수예요. 지치면 교대해요.' : '영혼이 나를 감싸요 — 공격 방식(무기)과 몸 효과가 함께 바뀌어요. 책갈피의 소환수는 지치지 않아요.'}</p>
      ${owned().map((id) => { const at = slotOf(id); return `<button class="opt ${cur === id ? 'on' : ''}" type="button" data-pick="${id}" ${cur === id ? 'disabled' : ''}>${petIcon(id)}<b>${PETS[id].n} ${SV.pets[id].lvl}단계${at ? ` <small style="color:#8a5a2a">[지금 ${slotName[at]}]</small>` : ''}${inParty(id) ? '' : ' <small style="color:#8a5a2a">(서재에 있음)</small>'}</b><span>${slotEffect(slot, id)}</span></button>`; }).join('')}
      <button class="sub" type="button" id="clear" ${cur ? '' : 'disabled'}>비우기</button><button class="go" type="button" id="back">돌아가기</button>`, (c) => {
      c.querySelectorAll('[data-pick]').forEach((b) => b.onclick = () => { assign(slot, b.dataset.pick); hudUpdate(); back(); });
      c.querySelector('#clear').onclick = () => { assign(slot, null); hudUpdate(); back(); };
      c.querySelector('#back').onclick = back; });
  }
  function bindLoadout(c, redraw) { c.querySelectorAll('[data-slotpick]').forEach((b) => b.onclick = () => chooseSlot(b.dataset.slotpick, redraw)); c.querySelectorAll('[data-party]').forEach((b) => b.onclick = () => { togglePartyMember(b.dataset.party); hudUpdate(); redraw(); }); }
  const loadSummary = () => `책갈피 ${SV.load.b1 ? `${PETS[SV.load.b1].n}(${WEAP[SV.load.b1].n} · ${BODY[SV.load.b1].n})` : '없음(맨 책장)'} · 데리고 다니기 ${SV.party.map((id) => PETS[id].n).join(', ')}`;
  // 삼국지연의로 바꾼 뒤(D-161): 설화 마을(책방골)은 잠시 닫고, 판이 끝나면 책방 메뉴(처음 화면)로
  const HUB_OFF = true;
  function backToTown(x, y, d) { closeCard(); A = null; D = null; if (HUB_OFF) { saveSV(); return title(); } placeTown(x, y, d); saveSV(); enterTown(); }
  const HOME_FRONT = [20, 47, 'down'];
  function hudUpdate() {
    if (MODE === 'story') return storyHud(); if (MODE === 'rope') return ropeHud(); if (MODE === 'army') return armyHud(); $('goal').hidden = true;
    if (MODE === 'town') { $('page').textContent = areaName(T.x, T.y); $('pause').style.display = 'none'; $('swap').style.display = 'none'; $('bag').style.display = ''; const h = [`<span class="tag" style="border-color:var(--gold)">엽전 ${SV.coins}</span>`, `<span class="tag">흥부전 ${SV.books.heung || 0}권</span>`, `<span class="tag">낱장 ${SV.leaves}/${LEAVES_PER_BOOK}</span>`, `<span class="tag">인장 ${SV.seals.length}/1</span>`, (SV.load.c ? `<span class="tag" style="border-color:${PETS[SV.load.c].c}">동행 ${petLine(SV.load.c)}</span>` : ''), (SV.load.b1 ? `<span class="tag" style="border-color:${PETS[SV.load.b1].c}">책갈피 ${petLine(SV.load.b1)}</span>` : '<span class="tag">책갈피 없음</span>'), `<span class="tag">데려감 ${SV.party.length}/${PARTY_MAX}</span>`].join(''); if ($('tags').innerHTML !== h) $('tags').innerHTML = h; return; }
    if (!A) return; if (A.kind === 'mu') return muHud(); $('pause').style.display = ''; $('bag').style.display = 'none'; $('swap').style.display = swapCands().length ? '' : 'none'; $('swap').textContent = A.swapCd > 0 ? `교대 ${A.swapCd.toFixed(1)}` : '교대'; const p = A.p;
    $('page').textContent = A.kind === 'book' ? `흥부전 ${A.pi + 1}/${PAGES.length}장 · ${PAGES[A.pi].t}` : A.kind === 'wild' ? '떠도는 이야기' : A.kind === 'story' ? A.title : A.kind === 'surv' ? `황건적 토벌 · ${sceneAt(A.t).n}` : `북 대결 ${D.round}판 · ${FOES[D.foe].n}`;
    const hp = $('hp'); hp.style.width = `${p.hp / p.max * 100}%`; hp.style.background = p.hp / p.max < 0.3 ? 'var(--bad)' : 'var(--good)';
    const tg = [`<span class="tag">체력 ${Math.ceil(p.hp)}/${p.max}</span>`]; if (A.pet) tg.push(`<span class="tag" style="border-color:${PETS[A.pet.id].c}">동행 ${PETS[A.pet.id].n} ${A.pet.lvl}</span>`); if (A.pet && !A.pet.noSta) tg.push(`<span class="tag">기력 ${Math.round(A.pet.sta)}${A.pet.tired ? ' 지침' : ''}</span>`); if (A.squad && A.squad.length) tg.push(`<span class="tag" style="border-color:#f0a0b8">장수 ${A.squad.map((q) => PETS[q.id].n).join('·')}${A.oath ? ' · 도원결의' : ''}</span>`); tg.push(`<span class="tag">${A.weap ? `책갈피 ${PETS[A.weap.id].n} · ${WEAP[A.weap.id].n}` : '맨 책장'}</span>`);
    if (A.kind === 'duel') tg.push(`<span class="tag">나 ${D.wins.me} : ${D.wins.foe} 상대</span>`); else tg.push(`<span class="tag" style="border-color:var(--gold)">엽전 +${A.coins}</span>`);
    const pk = Object.keys(A.pw); if (pk.length > 3) tg.push(`<span class="tag">힘 ${pk.map((k) => POW[k].ic + (A.pw[k] > 1 ? A.pw[k] : '')).join('·')}</span>`); else for (const k of pk) tg.push(`<span class="tag">${POW[k].n}${A.pw[k] > 1 ? '×' + A.pw[k] : ''}</span>`);
    const h = tg.join(''); if ($('tags').innerHTML !== h) $('tags').innerHTML = h;
  }
  // ── 처음 화면
  function title() {
    if (MU_ON) return lobby();
    setMode('title'); $('hud').hidden = true; $('talk').hidden = true; TALK.on = false; inputLock = false; $('act').hidden = true;
    const blank = !SV.opened, me = SV.name || '독자', st = SV.load.c && PETS[SV.load.c];
    card(`<h2>북마스터 — 삼국지연의</h2><p class="lead">누가 삼국지연의에 먹물을 쏟고 있어요. 책 속으로 들어가 이야기를 바로잡아요.</p>${blank ? '<p>화면을 <b>끌면</b> 걸어요(키보드: 방향키·WASD). 책 속 싸움에서는 걸어도 글자가 날아가요. 짧게 톡 = 구르기(스페이스).</p><button class="go" type="button" id="start">새로 시작</button>' : `<p>${me}${st ? ` · 첫 장수 ${st.n}` : ''} · 모은 장수 ${owned().filter((i) => !PETS[i].npc).map((i) => PETS[i].n).join(', ') || '없음'}</p>
      <button class="go" type="button" id="surv">${SURV.book} 읽기 <small style="font-weight:400">(뱀서판 · 8분)</small></button>
      <button class="sub" type="button" id="army">군세 대결 — 황건 장수 정원지 <small>(클래시 로얄식 · 시험)</small></button>
      <button class="sub" type="button" id="rope">일기토 — 정원지 <small>(줄다리기 · 시험)</small></button>
      <button class="sub" type="button" id="new">처음부터(기록 지움)</button>`}
      <p style="font-size:.78rem">시안 v0.12 · 그림·소리: Ninja Adventure (CC0, pixel-boy) · 소리 끄기는 오른쪽 위 ♪</p>`, (c) => {
      const on = (id, fn) => { const b = c.querySelector('#' + id); if (b) b.onclick = fn; };
      on('start', () => opening()); on('surv', () => { closeCard(); startSurv(); }); on('army', () => { closeCard(); startArmy('cyz'); }); on('rope', () => { closeCard(); duelIntro('cyz'); });
      on('new', () => { resetSV(); opening(); }); });
  }
  function intro() { SV.intro = true; saveSV(); talk('책방 주인', ['어서 와. 책방골에 처음 온 독자구나.', '이 세계에선 책을 끝까지 읽으면 그 이야기가 네 안으로 옮겨 와. 책은 빈 종이가 되고, 결말의 인물을 부를 수 있게 되지.', '해태를 맡길게. 첫 소환수야. 그리고 흥부전 한 권. 내 집 서재에서 읽을 수 있어.', '북쪽 문으로 나가 박골 들길을 지나면 옛이야기 고을이 있어. 나머지 길은 아직 빈 페이지야 — 흥부전을 끝까지 읽으면 결말에 따라 펼쳐질 거야. 거기 옛이야기관 사서장을 이기면 인장을 받아. 그게 북마스터로 가는 첫걸음이야.', '사서장은 책을 끝까지 읽어 본 독자하고만 겨뤄. 먼저 흥부전부터 읽어 봐.']); }
  // ── 건물
  function enterBuilding(id) {
    if (id === 'shop') return shopCard(); if (id === 'home') return homeCard(); if (id === 'library') return libraryCard(); if (id === 'house3' || id === 'house4') return talk('', ['안에서 책장 넘기는 소리만 들려요. 문은 잠겨 있어요.']);
    talk('', ['문이 잠겨 있어요.']);
  }
  function shopCard() {
    const canBuy = SV.coins >= BOOK_PRICE, canBind = SV.leaves >= LEAVES_PER_BOOK;
    card(`<h2>책방</h2><p class="lead">"흥부전은 늘 있어. 낱장을 모아 오면 묶어 주기도 하고."</p><div class="stats"><span>엽전</span><b>${SV.coins}닢</b><span>낱장</span><b>${SV.leaves}/${LEAVES_PER_BOOK}</b><span>흥부전</span><b>${SV.books.heung || 0}권</b></div>
      <button class="opt" type="button" id="buy" ${canBuy ? '' : 'disabled'}><span class="ic" style="background:#b8432f;color:#fffaf0;border-radius:4px">흥</span><b>흥부전 ★1 사기 — ${BOOK_PRICE}닢</b><span>${canBuy ? '책장 9장 · 결말 3개' : `${BOOK_PRICE - SV.coins}닢 모자라요`}</span></button>
      <button class="opt" type="button" id="bind" ${canBind ? '' : 'disabled'}><span class="ic" style="background:#e8dcb0">낱</span><b>낱장 ${LEAVES_PER_BOOK}장 묶기 → 흥부전 1권</b><span>${canBind ? '공짜로 묶어 줘요' : `책 덤불에서 ${LEAVES_PER_BOOK - SV.leaves}장 더`}</span></button>
      <button class="opt" type="button" disabled><span class="ic" style="background:#c9b892">?</span><b>★2 이상의 책</b><span>인장이 있어야 다음 고을 책방에서 팔아요</span></button>
      <button class="sub" type="button" id="out">나가기</button>`, (c) => {
      c.querySelector('#buy').onclick = () => { SV.coins -= BOOK_PRICE; SV.books.heung = (SV.books.heung || 0) + 1; saveSV(); shopCard(); hudUpdate(); };
      c.querySelector('#bind').onclick = () => { SV.leaves -= LEAVES_PER_BOOK; SV.books.heung = (SV.books.heung || 0) + 1; saveSV(); shopCard(); hudUpdate(); };
      c.querySelector('#out').onclick = () => { closeCard(); placeTown(28, 47, 'down'); hudUpdate(); }; });
  }
  function homeCard() {
    const nb = SV.books.heung || 0;
    card(`<h2>내 집 · 서재</h2><p class="lead">끝까지 읽은 책은 빈 종이가 돼요. 쓰러지면 책은 남아요.</p>
      <div class="opt" style="cursor:default"><span class="ic" style="background:#b8432f;color:#fffaf0;border-radius:4px">흥</span><b>흥부전 ★1 — ${nb}권</b><span>본 결말 ${Object.keys(SV.endings).length}/3 · ${['kind', 'greed', 'swift'].map((k) => SV.endings[k] ? ENDINGS[k].t : '???').join(' · ')}</span></div>
      <h3>책갈피</h3>${loadoutHTML(true)}
      <button class="go" type="button" id="read" ${nb ? '' : 'disabled'}>${nb ? '흥부전을 펼친다' : '읽을 책이 없어요 — 책방에서 구해요'}</button><button class="sub" type="button" id="out">나가기</button>`, (c) => {
      bindLoadout(c, homeCard);
      c.querySelector('#read').onclick = () => { if (!(SV.books.heung > 0)) return; closeCard(); startBook(); };
      c.querySelector('#out').onclick = () => { closeCard(); placeTown(...HOME_FRONT); hudUpdate(); }; });
  }
  function libraryCard() {
    const F = FOES.keeper1, done = SV.beaten.keeper1;
    card(`<h2>옛이야기관</h2><p class="lead">${done ? '"인장을 가진 독자로군. 언제든 다시 겨뤄 주지."' : '"북 대결을 하러 왔나?"'}</p><p>사서장 <b>먹선</b> · 이야기 줄다리기 3판 2선승 · 순서: ${F.pets.map((p) => `${PETS[p.id].n} ${p.lvl}단계`).join(' → ')}<br>버릇: ${ROPE_AI.keeper1.desc}.</p>
      <div class="stats"><span>내 소환수</span><b>${owned().map(petLine).join(', ')}</b><span>인장</span><b>${SV.seals.length ? SV.seals.join(', ') : '없음'}</b></div>
      <button class="go" type="button" id="duel">북 대결 신청${Object.keys(SV.endings).length ? '' : ' (끝까지 읽은 책 필요)'}</button><button class="sub" type="button" id="out">나가기</button>`, (c) => {
      c.querySelector('#duel').onclick = () => { closeCard(); if (!Object.keys(SV.endings).length) return talk(F.n, ['자네, 책을 끝까지 읽어 본 적은 있나?', '이야기가 몸에 옮겨 온 적도 없는 독자와는 겨루지 않네. 흥부전을 끝까지 읽고 오게.']); talk(F.n, F.hi, () => duelIntro('keeper1')); };
      c.querySelector('#out').onclick = () => { closeCard(); placeTown(23, 6, 'down'); hudUpdate(); }; });
  }
  // 책은 가방에서 어디서든 펼침(덮으면 그 자리로) — 사용자 지적: 집에서만 읽는 건 불편
  function bagBooks() { const nb = SV.books.heung || 0, st = SV.story; return `<h3>책 펼치기</h3><button class="opt" type="button" id="rd1"><span class="ic" style="background:#b8432f;color:#fffaf0;border-radius:4px">흥</span><b>${CH1.title}</b><span>${st && !st.done ? '이어서 읽기' : st && st.done ? '다시 읽기(처음부터)' : '걸어 다니며 풀어 가는 이야기'}</span></button><button class="opt" type="button" id="rd0" ${nb ? '' : 'disabled'}><span class="ic" style="background:#c9b892;border-radius:4px">흥</span><b>흥부전 싸움판 · 예전 시안 (${nb}권)</b><span>${nb ? '책장 9장을 싸우며 넘기기 — 결말에 따라 마을 길이 열려요' : '책방에서 구해요'}</span></button><button class="opt" type="button" id="rdS"><span class="ic" style="background:#24162f;color:#fff2c0;border-radius:4px">흥</span><b>흥부전 · 뱀서판 (시험)</b><span>걸으며 자동 낭독 · 몰려오는 먹물 · 레벨업마다 힘 고르기 · 8분 + 도깨비 박</span></button>`; }
  function bindBooks(c) { c.querySelector('#rd1').onclick = () => { if (!SV.story || SV.story.done) SV.story = newStory(); saveSV(); storyStart(!!(SV.story.x !== CH1.start.x || SV.story.step), 'town'); }; const r0 = c.querySelector('#rd0'); if (r0) r0.onclick = () => { if (!(SV.books.heung > 0)) return; closeCard(); startBook(); }; c.querySelector('#rdS').onclick = () => { closeCard(); startSurv(); }; }
  function bagCard() {
    card(`<h2>가방</h2>${bagBooks()}<div class="stats"><span>엽전</span><b>${SV.coins}닢</b><span>흥부전</span><b>${SV.books.heung || 0}권</b><span>낱장</span><b>${SV.leaves}/${LEAVES_PER_BOOK}</b><span>인장</span><b>${SV.seals.join(', ') || '없음'}</b><span>북 대결</span><b>${SV.duels.w}승 ${SV.duels.l}패</b></div>
      <h3>책갈피</h3>${loadoutHTML(true)}<p style="font-size:.8rem">경험: 싸운 동행은 전부, 책갈피의 소환수는 절반을 받아요. ${owned().map((id) => `${PETS[id].n} 다음 단계까지 ${xpNeed(SV.pets[id].lvl) - SV.pets[id].xp}`).join(' · ')}</p>
      <button class="sub" type="button" id="out">닫기</button>`, (c) => {
      bindLoadout(c, bagCard); bindBooks(c);
      c.querySelector('#out').onclick = closeCard; });
  }
  $('swap').onclick = () => swapPet();
  $('snd').onclick = () => { setAudio(!audioOn); $('snd').textContent = audioOn ? '♪' : '♪̸'; $('snd').style.opacity = audioOn ? 1 : 0.5; };
  $('bag').onclick = () => { if (MODE === 'town' && !inputLock) bagCard(); else if (MODE === 'story' && !inputLock) storyBag(); };
  function pauseCard() { if (A.kind === 'mu') return muPause(); const canQuit = A.kind !== 'duel';
    card(`<h2>잠깐 멈춤</h2><p>${A.kind === 'book' ? `${A.pi + 1}장 「${PAGES[A.pi].t}」` : A.kind === 'wild' ? '떠도는 이야기' : A.kind === 'story' ? A.title : A.kind === 'surv' ? `${SURV.book} · ${sceneAt(A.t).n} · ${fmtT(A.t)}` : `북 대결 ${D.round}판`}</p><button class="go" type="button" id="cont">계속</button><button class="opt" type="button" id="wf" style="grid-template-columns:1fr"><b>걸으며 읽기(시험용): ${SV.walkFire ? '켬' : '끔'}</b><span>${SV.walkFire ? '움직이는 중에도 약하게 쏴요(속도 절반 · 피해 60%). 멈추면 제 힘.' : '멈췄을 때만 글자가 날아가요(기본).'} 눌러서 바꾸기 — 둘 다 해 보고 손맛을 알려 주세요.</span></button>${canQuit ? `<button class="sub" type="button" id="quit">${A.kind === 'book' || A.kind === 'surv' ? '책을 덮는다(책은 남음)' : A.kind === 'story' ? '물러난다(이야기로)' : '도망친다'}</button>` : '<button class="sub" type="button" id="quit">기권(이번 대결 짐)</button>'}`, (c) => {
      c.querySelector('#cont').onclick = () => { closeCard(); A.state = 'play'; last = performance.now(); };
      c.querySelector('#wf').onclick = () => { SV.walkFire = !SV.walkFire; saveSV(); pauseCard(); };
      c.querySelector('#quit').onclick = () => { if (A.kind === 'duel') { closeCard(); A.state = 'play'; D.wins.foe = D.need - 1; roundEnd('foe'); return; } if (A.kind === 'story') { closeCard(); A.state = 'play'; return storyFightEnd(false, true); } const back = A.kind === 'book' ? HOME_FRONT : [SV.pos.x, SV.pos.y, SV.pos.d]; saveSV(); backToTown(...back); }; }); }
  $('pause').onclick = () => { if (!A || A.state !== 'play') return; A.state = 'pause'; pauseCard(); };
  // ── 책장의 힘
  function pickPower(after) {
    A.state = 'pick'; const pool = Object.keys(POW).filter((k) => !(POW[k].surv && A.kind !== 'surv') && !(k === 'heal' && A.p.hp > A.p.max * 0.8) && !(POW[k].once && pw(k)) && !(k === 'bounce' && pw('bounce') >= 2) && !(k === 'chain' && pw('chain') >= 2)); const opts = []; while (opts.length < 3 && pool.length) opts.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
    // 뱀서판: 장수 합류 카드가 섞여 나옴(데려간 장수 3명까지) — 유비·관우·장비가 모이면 도원결의
    if (A.kind === 'surv' && A.lvl >= 4 && A.squad.length < 3) { const rc = RECRUIT.filter((r) => !(A.pet && A.pet.id === r) && !A.squad.some((q) => q.id === r)); if (rc.length && Math.random() < 0.28) opts[Math.floor(Math.random() * opts.length)] = 'rc:' + pick(rc); }
    const optHTML = (k) => { if (k.startsWith('rc:')) { const id = k.slice(3), oathN = OATH.filter((o) => o === id || (A.pet && A.pet.id === o) || A.squad.some((q) => q.id === o)).length; return `<button class="opt" type="button" data-pw="${k}" style="border-color:${PETS[id].c};border-width:2px">${petIcon(id)}<b>${PETS[id].n} 합류 <small style="font-weight:400;color:var(--paper-muted)">${PETS[id].role}</small></b><span>${PETS[id].d}${OATH.includes(id) ? ` · 도원결의 ${oathN}/3` : ''}</span></button>`; } return `<button class="opt" type="button" data-pw="${k}"><span class="ic" style="background:#e8d8b0">${POW[k].ic}</span><b>${POW[k].n}${pw(k) ? ` (+${pw(k)})` : ''}</b><span>${POW[k].d}</span></button>`; };
    card(`<h2>${A.kind === 'surv' ? `Lv ${A.lvl} — ` : ''}책장의 힘</h2><p>${A.kind === 'surv' ? '힘을 고르거나 장수를 맞아들여요.' : '이번 독서 동안만 쓰는 힘을 하나 고르세요.'}</p>${opts.map(optHTML).join('')}`, (c) => {
      c.querySelectorAll('[data-pw]').forEach((b) => b.onclick = () => { const k = b.dataset.pw; if (k.startsWith('rc:')) { closeCard(); A.state = 'play'; last = performance.now(); recruit(k.slice(3)); after(); hudUpdate(); return; } A.pw[k] = pw(k) + 1; if (k === 'hpup') { A.p.max += 25; heal(A.p, 25); } if (k === 'heal') heal(A.p, A.p.max * 0.45); closeCard(); A.state = 'play'; last = performance.now(); after(); hudUpdate(); }); });
  }
  function petXPLine(id, v) { if (!id || !SV.pets[id]) return ''; const ups = gainPetXP(id, v); return `<span>${PETS[id].n} 경험</span><b>+${v}${ups ? ` · ${SV.pets[id].lvl}단계로!` : ''}</b>`; }
  function xpLines(v) { let h = petXPLine(A.pet && A.pet.id, v); const b = SV.load.b1; if (b && (!A.pet || b !== A.pet.id)) h += petXPLine(b, Math.ceil(v / 2)); return h; }
  // ── 쓰러짐(책·떠도는 이야기)
  function die() { if (A.kind === 'story') return storyFightEnd(false); if (A.kind === 'mu') return muEnd(false);
    if (A.kind === 'surv') { sfx('lose', 0.4); A.state = 'dead'; const tt = A.t, xp = xpLines(Math.round(A.kills / 6)); saveSV();
      setTimeout(() => card(`<h2>책이 덮였어요</h2><p class="lead">「${sceneAt(tt).n}」에서 먹물에 삼켜졌어요.</p><div class="stats"><span>버틴 시간</span><b>${fmtT(tt)} / ${fmtT(SURV.len)}</b><span>씻어 낸 조각</span><b>${A.kills}</b><span>레벨</span><b>${A.lvl}</b>${xp}</div><p>책은 그대로 남아요. 가방에서 다시 펼칠 수 있어요.</p><button class="go" type="button" id="back">책방골로</button>`, (c) => { c.querySelector('#back').onclick = () => backToTown(SV.pos.x, SV.pos.y, SV.pos.d); }), 500); return; } sfx('lose', 0.4); A.state = 'dead'; const k = A.kind, xp = xpLines(A.kills * 2); saveSV();
    setTimeout(() => card(`<h2>${k === 'book' ? '책이 덮였어요' : '눈앞이 하얘졌어요'}</h2><p class="lead">${k === 'book' ? `${A.pi + 1}장 「${PAGES[A.pi].t}」에서 쓰러졌어요.` : '떠도는 이야기에게 졌어요.'}</p><div class="stats"><span>쓰러뜨린 적</span><b>${A.kills}</b><span>모은 엽전</span><b>${A.coins}닢</b>${xp}</div><p>${k === 'book' ? '책은 그대로 남아 있어요. 서재에서 다시 펼칠 수 있어요.' : '집에서 깨어나요. 모은 엽전은 남아요.'}</p><button class="go" type="button" id="back">${k === 'book' ? '서재로' : '집으로'}</button>`, (c) => { c.querySelector('#back').onclick = () => { backToTown(...HOME_FRONT); if (k === 'book') homeCard(); }; }), 500); }
  // ── 떠도는 이야기 승리
  function wildWin() { sfx('win', 0.35); A.state = 'end'; const lv = Math.random() < 0.3 ? 2 : 1; SV.leaves += lv; const xp = xpLines(A.kills * 4); saveSV();
    setTimeout(() => card(`<h2>떠도는 이야기를 잠재웠어요</h2><div class="stats"><span>낱장</span><b>+${lv} (${SV.leaves}/${LEAVES_PER_BOOK})</b><span>엽전</span><b>+${A.coins}</b>${xp}</div>${SV.leaves >= LEAVES_PER_BOOK ? '<p>낱장이 다 모였어요! 책방에서 흥부전 한 권으로 묶을 수 있어요.</p>' : ''}<button class="go" type="button" id="back">계속 걷기</button>`, (c) => { c.querySelector('#back').onclick = () => backToTown(SV.pos.x, SV.pos.y, SV.pos.d); }), 400); }
  // ── 책 결말
  function endRun() {
    sfx('win', 0.4); A.state = 'end'; const L = A.lean, order = ['kind', 'swift', 'greed']; let best = order[0]; for (const k of order) if (L[k] > L[best]) best = k;
    const E = (A.kind === 'surv' ? ENDINGS_YT : ENDINGS)[best], isNew = !SV.pets[E.pet]; let bonus = '';
    if (isNew) { SV.pets[E.pet] = { lvl: 1, xp: 0 }; if (SV.party.length < PARTY_MAX) SV.party.push(E.pet); } else { SV.pets[E.pet].lvl++; bonus = `${PETS[E.pet].n}${((PETS[E.pet].n.charCodeAt(PETS[E.pet].n.length - 1) - 0xac00) % 28) ? '이' : '가'} 한 단계 강해졌어요 → ${SV.pets[E.pet].lvl}단계`; }
    SV.endings[best] = (SV.endings[best] || 0) + 1; SV.clears++; if (A.kind !== 'surv') SV.books.heung = Math.max(0, (SV.books.heung || 0) - 1); A.coins += 30; SV.coins += 30;
    const sv = A.kind === 'surv', xp = xpLines(sv ? Math.round(A.kills / 5) + 20 : A.kills * 3 + 20); saveSV(); const sec = Math.round((performance.now() - A.start) / 1000);
    const LN = sv ? ['인', '공', '용'] : ['착함', '욕심', '날램'];
    setTimeout(() => card(`<h2>${sv ? `${SURV.book}을 다 읽었어요` : '흥부전을 다 읽었어요'}</h2><h3>${E.t}</h3><p class="lead">${E.txt}</p>${isNew ? `<div class="opt on" style="cursor:default">${petIcon(E.pet)}<b>${sv ? '새 장수' : '새 소환수'}: ${PETS[E.pet].n}</b><span>${PETS[E.pet].d}</span></div>` : `<p><b>${bonus}</b></p>`}<p class="lead" style="font-size:.92rem">${sv ? '먹물이 씻긴 이야기가 옮겨 와, 책장은 다시 하얘졌어요.' : '이야기가 모두 옮겨 와, 흥부전은 빈 종이가 되었어요.'}</p><div class="stats"><span>고른 길</span><b>${LN[0]} ${L.kind} · ${LN[1]} ${L.greed} · ${LN[2]} ${L.swift}</b>${sv ? `<span>장수</span><b>${[A.pet && A.pet.id, ...A.squad.map((q) => q.id)].filter(Boolean).map((i) => PETS[i].n).join(' · ')}${A.oath ? ' (도원결의)' : ''}</b>` : ''}<span>${sv ? '버틴 시간' : '걸린 시간'}</span><b>${sv ? fmtT(A.t) : `${Math.floor(sec / 60)}분 ${sec % 60}초`}</b><span>모은 엽전</span><b>${A.coins}닢 (마무리 +30)</b>${xp}</div><button class="go" type="button" id="back">${sv ? '책방으로' : `서재로 (흥부전 ${SV.books.heung || 0}권)`}</button>`, (c) => { c.querySelector('#back').onclick = () => { if (sv) { backToTown(SV.pos.x, SV.pos.y, SV.pos.d); return; } backToTown(...HOME_FRONT); homeCard(); }; }), 700);
  }
  // ── 북 대결
  function duelIntro(foeId) {
    const bo = FOES[foeId].bestOf || 3; D = { foe: foeId, round: 1, wins: { me: 0, foe: 0 }, fi: 0, myPet: SV.load.c, bo, need: Math.ceil(bo / 2) };
    duelPick();
  }
  function duelPick() {
    const F = FOES[D.foe], fp = F.pets[D.fi % F.pets.length], single = D.bo === 1, C = ROPE_AI[D.foe] || ROPE_AI.reader1, fb = F.body && F.body[0] ? BK[F.body[0].id] : null;
    const pips = single ? '<div class="pips"><span>단판 승부</span></div>' : `<div class="pips">${Array.from({ length: D.need }, (_, i) => `<i class="${i < D.wins.me ? 'w' : ''}"></i>`).join('')}<span style="margin:0 8px">나 ${D.wins.me} : ${D.wins.foe} 상대</span>${Array.from({ length: D.need }, (_, i) => `<i class="${i < D.wins.foe ? 'l' : ''}"></i>`).join('')}</div>`;
    const comps = SV.party.filter((id) => SV.pets[id] && id !== SV.load.b1); if (!D.myPet || !comps.includes(D.myPet)) D.myPet = comps[0] || null;
    card(`<h2>북 대결${single ? '' : ` · ${D.round}판`}</h2>${pips}<p class="lead">${F.n} — 이야기 줄다리기</p><div class="rps"><div><b>${PETS[fp.id].n} ${fp.lvl}단계</b> — ${sigOf(fp.id)}</div>${fb ? `<div>${BSIG[fb]}</div>` : ''}<div><b>버릇</b> — ${C.desc}</div>${SV.load.b1 ? `<div>내 ${BSIG[BK[SV.load.b1]]}</div>` : ''}</div>
      <h3>${single ? '함께 나설 소환수' : '이번 판에 나설 소환수'}</h3>${comps.map((id) => `<button class="opt ${id === D.myPet ? 'on' : ''}" type="button" data-pet="${id}">${petIcon(id)}<b>${PETS[id].n} · ${SV.pets[id].lvl}단계</b><span>${sigOf(id)}</span></button>`).join('') || '<p>나설 소환수가 없어요 — 혼자 겨뤄요.</p>'}<p style="font-size:.8rem">데려간 소환수끼리는 대결 중에도 교대할 수 있어요(한 수를 써요).</p><button class="go" type="button" id="go">대결 시작</button>`, (c) => {
      c.querySelectorAll('[data-pet]').forEach((b) => b.onclick = () => { D.myPet = b.dataset.pet; duelPick(); });
      c.querySelector('#go').onclick = () => { closeCard(); startRope(); }; });
  }
  function roundEnd(winner) {
    if (A.state !== 'play') return; A.state = 'round'; D.wins[winner]++; const F = FOES[D.foe]; const xp = xpLines(winner === 'me' ? 18 : 8); saveSV();
    const over = D.wins.me >= D.need || D.wins.foe >= D.need;
    setTimeout(() => { if (over) return duelEnd(); card(`<h2>${D.round}판 — ${winner === 'me' ? '이겼어요!' : '졌어요'}</h2><div class="pips"><span>나 ${D.wins.me} : ${D.wins.foe} 상대</span></div><div class="stats"><span>준 피해</span><b>${Math.round(A.dealt)}</b><span>받은 피해</span><b>${Math.round(A.taken)}</b>${xp}</div><button class="go" type="button" id="next">다음 판</button>`, (c) => { c.querySelector('#next').onclick = () => { D.round++; D.fi++; duelPick(); }; }); }, 700);
  }
  function duelEnd() {
    const F = FOES[D.foe], win = D.wins.me >= D.need, id = D.foe; let extra = ''; sfx(win ? 'win' : 'lose', 0.4);
    if (win) { SV.duels.w++; if (!SV.beaten[id]) { SV.coins += F.reward; extra = `<span>상금</span><b>${F.reward}닢</b>`; if (F.seal && !SV.seals.includes(F.seal)) { SV.seals.push(F.seal); extra += `<span>인장</span><b>${F.seal}</b>`; } } SV.beaten[id] = true; } else SV.duels.l++;
    saveSV(); const lines = win ? F.lose : F.win, keeper = id === 'keeper1';
    card(`<h2>${win ? '북 대결 승리!' : '북 대결 패배'}</h2><p class="lead">${F.n}: "${lines[0]}"</p><div class="stats"><span>결과</span><b>${D.bo === 1 ? (win ? '단판 승' : '단판 패') : `${D.wins.me} : ${D.wins.foe}`}</b>${extra}</div>${win && keeper ? '<p class="lead">첫 인장을 받았어요! 이번 시안은 여기까지예요 — 다음 고을(★2 책·두 번째 도서관)은 다음 시안에서.</p>' : ''}${!win ? '<p>소환수를 키우거나(떠도는 이야기·책 읽기), 흥부전의 다른 결말로 새 소환수를 얻어 다시 와요.</p>' : ''}<button class="go" type="button" id="back">마을로</button>`, (c) => {
      c.querySelector('#back').onclick = () => { if (win) backToTown(keeper ? 23 : SV.pos.x, keeper ? 6 : SV.pos.y, keeper ? 'down' : SV.pos.d); else backToTown(...HOME_FRONT); if (lines.length > 1) talk(F.n, lines.slice(1)); }; });
  }
  // 시험용: 상대 골라 바로 줄다리기
  function ropeTestCard() {
    card(`<h2>북 대결 · 이야기 줄다리기(시험)</h2><p>상대를 골라요. 이긴 기록은 실제로 남아요.</p>${['reader1', 'reader2', 'reader3', 'keeper1'].map((id) => `<button class="opt" type="button" data-foe="${id}" style="grid-template-columns:1fr"><b>${FOES[id].n}${FOES[id].bestOf > 1 ? ' · 3판 2선승' : ' · 단판'}</b><span>${(ROPE_AI[id] || {}).desc || ''}</span></button>`).join('')}<button class="sub" type="button" id="back">돌아가기</button>`, (c) => {
      c.querySelectorAll('[data-foe]').forEach((b) => b.onclick = () => { closeCard(); duelIntro(b.dataset.foe); }); c.querySelector('#back').onclick = title; });
  }
