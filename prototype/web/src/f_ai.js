  // ═════════ 북 대결 AI — 2단계(duel-ai.md): 위험 피하기 + 멈춰 쏘기 + 앞 겨냥 + 선호 거리 + 구석 피하기 ═════════
  function makeBrain(cfg) { return { cfg, tt: 0, goal: null, greedy: false, shots: 0 }; }
  // 후보 자리 c로 가는 동안(0.1~0.6초) 내 탄과 겹치는 정도. 반응 지연보다 최근에 생긴 탄은 아직 "못 본" 것으로 침
  function dangerAt(f, c, C) {
    let d = 0, dh = 0; const len = Math.hypot(c.x - f.x, c.y - f.y) || 1, steps = Math.round(C.look / 0.1);
    for (const b of A.shots) {
      if (A.t - b.born < C.react) continue; const rr = b.boom ? 26 : 0, left = b.maxLife ? b.maxLife - (b.life || 0) : 9;
      for (let k = 1; k <= steps; k++) {
        const t = k * 0.1; if (t > left) break; const fr = Math.min(1, (f.spd * t) / len), mx = f.x + (c.x - f.x) * fr, my = f.y + (c.y - f.y) * fr;
        let bx = b.x + b.vx * t, by = b.y + b.vy * t; if (!b.home && inWall(bx, by)) break;
        if (b.home) { bx = b.x + (mx - b.x) * Math.min(1, (b.sp * t) / (Math.hypot(mx - b.x, my - b.y) || 1)); by = b.y + (my - b.y) * Math.min(1, (b.sp * t) / (Math.hypot(mx - b.x, my - b.y) || 1)); }
        if (Math.hypot(mx - bx, my - by) < f.r + b.r + rr + C.margin) { if (b.home) dh += (1.1 - t) * b.dmg; else d += (1.1 - t) * b.dmg; break; }
      }
    }
    // 내 해태가 곧 내려칠 자리
    const mp = A.pet; if (mp && mp.id === 'haetae' && mp.cd < 0.5) { const near = Math.hypot(f.x - A.p.x, f.y - A.p.y) < 175, cx = near ? f.x : mp.x, cy = near ? f.y : mp.y; if (Math.hypot(c.x - cx, c.y - cy) < 95) d += 12 * C.W.pet; }
    return { d, dh };
  }
  function thinkFoe(f, C) {
    const me = A.p, cands = [{ x: f.x, y: f.y, stay: true }];
    for (let i = 0; i < 12; i++) for (const r of [30, 60]) { const a = i / 12 * Math.PI * 2; cands.push({ x: f.x + Math.cos(a) * r, y: f.y + Math.sin(a) * r, stay: false }); }
    const B = f.brain, greedy = Math.random() < C.greed, W2 = C.W, punish = me.still > 0.25 ? 1 + (C.punish - 1) * 2.5 : 1, Wf = WEAP[weapKey(f.weap)];
    let best = cands[0], bestS = -Infinity;
    for (const c of cands) {
      if (c.x < f.r + 6 || c.x > AW - f.r - 6 || c.y < f.r + 6 || c.y > AH - f.r - 6 || hitObs(c.x, c.y, f.r + 2)) continue;
      const dz = dangerAt(f, c, C), dg = dz.d, dm = Math.hypot(c.x - me.x, c.y - me.y), edge = Math.min(c.x, AW - c.x, c.y, AH - c.y);
      let s = -W2.danger * (dg + dz.dh * 0.05) * (greedy ? 0.3 : 1) - W2.range * Math.abs(dm - (Wf.range ? Math.min(C.range, Wf.range * 0.75) : C.range)) - W2.wall * Math.max(0, 50 - edge) / 50 * 10;
      if (dm < 45) s -= 20; if (!Wf.range && dm < 105) s -= (105 - dm) * 0.18;
      const shieldUp = me.body && me.body.counter && me.counterT <= 0.3, front = shieldUp ? ((c.x - me.x) * me.fx + (c.y - me.y) * me.fy) / (dm || 1) : 0;
      const see = los(c, me); if (c.stay && dg < 0.5 && see) s += W2.shoot * punish * (f.cd < 0.35 ? 1 : 0.45) * (Wf.range && dm > Wf.range ? 0 : 1) * (front > 0.5 ? 0.35 : 1);
      if (shieldUp && !c.stay && front < 0.4) s += 3; // 방패 옆으로 돌기
      if (!c.stay && see && f.cd < 0.5 && !los(f, me)) s += 6; // 벽 뒤면 보이는 곳으로
      if (B.goal && !c.stay && Math.hypot(c.x - B.goal.x, c.y - B.goal.y) < 18) s += 2; // 같은 방향 유지(흔들림 방지)
      s += Math.random();
      if (s > bestS) { bestS = s; best = c; }
    }
    B.greedy = greedy; return best;
  }
  function foeShoot(f, C) {
    const me = A.decoy && A.decoy.t > 0 ? A.decoy : A.p, F = FOES[D.foe], Wd = WEAP[weapKey(f.weap)], sp = Wd.form === 'line' ? f.shotSp : Wd.form === 'bomb' ? 285 : Wd.form === 'spray' ? 470 : 400, dx = me.x - f.x, dy = me.y - f.y, dd = Math.hypot(dx, dy), tt = dd / sp;
    if (Wd.range && dd > Wd.range) return; // 부채꼴은 가까울 때만
    if (!los(f, me)) return; // 벽에 막히면 안 쏨
    const B = f.brain; B.shots++;
    // 섞어 쏘기: 바로 겨냥 / 앞 겨냥. 내가 오래 멈춰 있으면(punish) 바로 겨냥 + 오차 줄임
    const pun = C.punish > 1 && me.still > 0.3, lead = pun ? 0 : (B.shots % 4 === 0 ? 0 : C.lead);
    const px = me.x + me.vx * tt * lead, py = me.y + me.vy * tt * lead;
    const err = (pun ? C.err * 0.6 : C.err) * Math.PI / 180, a = Math.atan2(py - f.y, px - f.x) + rnd(-err, err);
    fireWeapon(f, a, weapDmg(f, f.weap) * greedMul(f, f.stillT || 0), f.weap, false, me);
    f.fx = Math.cos(a); f.fy = Math.sin(a); f.cd = 1 / (F.rate * Wd.rate / 2.2 * (pun ? C.punish : 1)); f.rec = C.recover || 0;
  }
  function foeTick(f, dt) {
    const B = f.brain, C = B.cfg; f.flash = Math.max(0, f.flash - dt); f.cd -= dt;
    B.tt -= dt; if (B.tt <= 0) { B.tt = C.think * rnd(0.85, 1.15); B.goal = thinkFoe(f, C); }
    const g = B.goal; let moving = false; f.rec = Math.max(0, (f.rec || 0) - dt);
    if (g && !g.stay && f.rec <= 0) { const dx = g.x - f.x, dy = g.y - f.y, d = Math.hypot(dx, dy); if (d > 2) { const s = Math.min(d, f.spd * dt); f.x += dx / d * s; f.y += dy / d * s; f.fx = dx / d; f.fy = dy / d; moving = true; } else B.goal = { x: f.x, y: f.y, stay: true }; }
    pushOut(f); f.stillT = moving ? 0 : (f.stillT || 0) + dt;
    if (!moving && f.cd <= 0) foeShoot(f, C);
  }
