class_name Siege
extends RefCounted
## 황건 편 2 · 3장용 진행(D-211 — D-210에서 1장 '탁현 싸움'에서 떼어 냄): 정원지를 쓰러뜨리면 성문이 열리는 연출(D-206) →
## 장각의 요술 + 요술 제단(D-207 · D-209) → 장각 → 첫 사신수 해방(D-207). 수치는 SiegeData.
## 1장에서는 만들지 않음(Stage1.SIEGE = false → Battle.siege = null). 장이 켜면 Battle이 매 프레임 tick을 부르고,
## 처치(on_kill) · 목표(target) · 진군(march) · 바닥 그리기(draw_ground · draw_gate)에서 물어봄. 장각 노드는 Battle.boss.

var b: Battle
## 성문이 열리는 중(지난 초, -1 = 아님) · 다 열림 · 장각 본진 문이 열림
var gate_t := -1.0
var gate_open := false
var keep_open := false
## 요술 제단(하나라도 남아 있으면 장각 보호막) · 봉인된 사신수 빛 구슬 자리(INF = 없음) · 풀려나는 중(지난 초, -1 = 아님)
var altars: Array[Enemy] = []
var beast_pos := Vector2.INF
var beast_t := -1.0
## 장각의 요술: 켜짐 · 다음 낙뢰 · 폭풍까지 · 낙뢰 예고 {pos, t} · 폭풍 {pos, life, hit} · 장수가 폭풍 안
var sorc_on := false
var bolt_t := 0.0
var storm_t := 0.0
var bolts: Array[Dictionary] = []
var storms: Array[Dictionary] = []
var in_storm := false


func _init(battle: Battle) -> void:
	b = battle


## 정원지를 쓰러뜨림 → 성문이 열리기 시작
func start_gate() -> void:
	gate_t = 0.0
	b.hit_stop = 0.15
	b.shake = 0.35
	b.banner("정원지 격파!", "관문이 열려요")
	Sound.play("slam", 0.5)


func tick(dt: float) -> void:
	_gate_tick(dt)
	_sorcery_tick(dt)
	_beast_tick(dt)


## 성문 열림 연출(D-206): GATE_OPEN초 동안 문짝이 양옆으로 열리며(draw_gate) 먼지 · 흔들림 → 다 열리면 지나갈 수 있음.
## 장각 본진 문은 장각의 요술 때(D-209)
func _gate_tick(dt: float) -> void:
	if gate_t < 0:
		return
	var G: Dictionary = Stage1.GATE
	var n0 := int(gate_t / 0.16)
	gate_t += dt
	if int(gate_t / 0.16) != n0:
		b.add_fx({"k": "puff", "pos": Vector2(randf_range(float(G.x0) - 20, float(G.x1) + 20), float(G.y) + randf_range(4, 16)), "t": 0.3})
		b.shake = maxf(b.shake, 0.06)
	if gate_t < SiegeData.GATE_OPEN:
		return
	gate_t = -1.0
	gate_open = true
	b.note("관문 열림")
	b.open_door("gate")
	b.add_fx({"k": "ring", "pos": Vector2((float(G.x0) + float(G.x1)) / 2, float(G.y)), "t": 0.6, "r": 120.0, "c": Color("f0c040")})
	b.shake = maxf(b.shake, 0.3)
	Sound.play("win", 0.4)
	var S: Dictionary = SiegeData.SORCERY
	if b.t < float(S.at):
		b.banner("관문이 열렸어요!", "장각 본진 앞으로 — %s에 장각이 요술을 부려요" % Battle.mmss(float(S.at)))


## 장각의 요술(D-209): 성문이 열리고 SORCERY.at초가 지나면 장각 본진 문이 열리며 장각 · 요술 제단이 나옴(_open_keep).
## 제단이 남아 있는 동안 낙뢰(예고 원 → 내리꽂힘) · 폭풍(다가오는 회오리 — 안이면 느려지고 조금씩 다침). 제단을 다 부수면 멈춤
func _sorcery_tick(dt: float) -> void:
	var S: Dictionary = SiegeData.SORCERY
	var hero := b.hero
	if b.boss == null:
		if gate_open and b.t >= float(S.at):
			_open_keep()
		return
	if not sorc_on:
		return
	if altars_left() == 0 or not Unit.alive(b.boss):
		sorc_on = false
		bolts.clear()
		storms.clear()
		in_storm = false
		return
	# 낙뢰: 한 곳은 장수 자리, 나머지는 둘레
	bolt_t -= dt
	if bolt_t <= 0:
		bolt_t = float(S.bolt_gap)
		for i in int(S.bolts):
			var at := hero.position
			if i > 0:
				at += Vector2.from_angle(randf() * TAU) * randf_range(60, 140)
			bolts.append({"pos": at, "t": 0.0})
	var keep: Array[Dictionary] = []
	var struck := false
	for bo in bolts:
		bo.t += dt
		if bo.t < float(S.bolt_warn):
			keep.append(bo)
			continue
		struck = true
		b.add_fx({"k": "sky", "pos": bo.pos, "t": 0.25})
		b.add_fx({"k": "ring", "pos": bo.pos, "t": 0.3, "r": float(S.bolt_r), "c": Color("fff2b0")})
		if hero.position.distance_to(bo.pos) < float(S.bolt_r) + hero.r * 0.5:
			hero.hurt(float(S.bolt_dmg), "요술")
	bolts = keep
	if struck:
		Sound.play("slam", 0.25)
	# 폭풍: 화면 바로 밖에서 생겨 장수 쪽으로
	storm_t -= dt
	if storm_t <= 0:
		storm_t = float(S.storm_gap)
		var o := b.ring_pos(randf() * TAU)
		storms.append({"pos": o if o != Vector2.INF else hero.position + Vector2(0, -260), "life": float(S.storm_life), "hit": 0.0})
	in_storm = false
	var keep2: Array[Dictionary] = []
	for sm in storms:
		sm.life -= dt
		if sm.life <= 0:
			continue
		var dv: Vector2 = hero.position - sm.pos
		if dv.length() > 2:
			sm.pos += dv.normalized() * float(S.storm_spd) * dt
		if dv.length() < float(S.storm_r):
			in_storm = true
			sm.hit -= dt
			if sm.hit <= 0:
				sm.hit = 1.0
				hero.hurt(float(S.storm_dmg), "요술")
		keep2.append(sm)
	storms = keep2


## 장각 본진 문이 열리고 장각 · 요술 제단이 나옴 · 요술 시작(D-207 · D-209)
func _open_keep() -> void:
	keep_open = true
	b.open_door("keep")
	var K := b.keep_rect()
	for dx in [-24, 24]:
		b.drops.append({"k": "bun", "pos": Vector2(K.get_center().x + dx, K.end.y + 40)})
	var B: Dictionary = SiegeData.BOSS
	var boss := b.spawn(B.k, K.get_center() + Vector2(0, -40), float(B.m))
	boss.boss = true
	boss.touch = 22
	b.boss = boss
	# 요술 제단(D-207): 남아 있는 동안 장각은 보호막
	var A: Dictionary = SiegeData.ALTAR
	for ap in A.pos:
		var al := b.spawn("altar", ap, float(A.hp))
		al.r = float(A.r)
		altars.append(al)
	boss.shield = not altars.is_empty()
	sorc_on = not altars.is_empty()
	bolt_t = 1.5
	storm_t = 3.0
	b.note("장각의 요술")
	b.banner("장각이 요술을 부려요!", "낙뢰 · 폭풍 — 요술 제단 %d개를 부수면 요술과 보호막이 풀려요" % altars.size())
	Sound.play("alert", 0.6)


## 제단이 몇 개 남았나
func altars_left() -> int:
	var n := 0
	for a in altars:
		if not a.dead:
			n += 1
	return n


## 첫 사신수 해방(D-207): 장수가 봉인된 빛 구슬에 닿으면 BEAST.release초 동안 빛이 퍼지며 풀려남 → 판 끝(이김)
func _beast_tick(dt: float) -> void:
	if beast_pos == Vector2.INF:
		return
	var Bs: Dictionary = SiegeData.BEAST
	if beast_t < 0:
		if b.hero.position.distance_to(beast_pos) < b.hero.r + 14:
			beast_t = 0.0
			b.note("사신수 해방")
			b.banner("%s%s 풀려났어요!" % [Bs.n, "이" if Battle.eul(Bs.n) == "을" else "가"], "황건적의 난을 평정했어요")
			Sound.play("win", 0.5)
			b.shake = 0.25
		return
	var n0 := int(beast_t / 0.3)
	beast_t += dt
	if int(beast_t / 0.3) != n0:
		b.add_fx({"k": "ring", "pos": beast_pos, "t": 0.6, "r": 60.0 + beast_t * 60.0, "c": Color(Bs.c)})
	if beast_t >= float(Bs.release):
		beast_pos = Vector2.INF
		b.finish(true, "")


## 장각 · 요술 제단이 쓰러질 때(처리했으면 true)
func on_kill(e: Enemy) -> bool:
	if e.boss:
		for o in b.enemies:
			if not o.dead and o != e:
				o.dead = true
		b.note("장각 격파")
		# 첫 사신수(D-207): 쓰러진 자리에 봉인된 빛 구슬 — 장수가 닿으면 풀려나고 판이 끝남
		beast_pos = e.position.clamp(b.keep_rect().position + Vector2(40, 40), b.keep_rect().end - Vector2(40, 40))
		var bn: String = e.def.n
		b.banner("%s%s 쓰러뜨렸어요!" % [bn, Battle.eul(bn)], "봉인된 %s의 빛이 나타났어요 — 다가가 풀어 줘요" % SiegeData.BEAST.n)
		b.hit_stop = 0.15
		b.shake = 0.5
		return true
	if e.k == "altar":
		var total := altars.size()
		var left := altars_left()
		b.add_fx({"k": "ring", "pos": e.position, "t": 0.5, "r": 60.0, "c": Color("ffb050")})
		b.shake = maxf(b.shake, 0.15)
		b.note("요술 제단 %d/%d" % [total - left, total])
		if left == 0:
			if Unit.alive(b.boss):
				b.boss.shield = false
				b.add_fx({"k": "ring", "pos": b.boss.position, "t": 0.5, "r": 90.0, "c": Color("6ac0e0")})
			b.banner("요술 제단을 다 부쉈어요", "장각의 보호막이 풀렸어요 — 이제 장각을 쳐요")
		else:
			b.banner("요술 제단을 부쉈어요 (%d/%d)" % [total - left, total], "제단이 남아 있는 동안 장각은 다치지 않아요")
		return true
	return false


## 정원지를 쓰러뜨린 뒤 갈 곳(화살표 · 목표 글)
func target() -> Dictionary:
	var hero := b.hero
	var K := b.keep_rect()
	if b.boss == null:
		var kp := Vector2(K.get_center().x, K.end.y + 60)
		if not gate_open:
			return {"pos": kp, "n": "관문이 열려요"}
		return {"pos": kp, "n": "장각 본진 앞 — 장각의 요술까지 %s" % Battle.mmss(float(SiegeData.SORCERY.at) - b.t)}
	if beast_pos != Vector2.INF:
		return {"pos": beast_pos, "n": "봉인된 %s의 빛 — 다가가 풀어 주기" % SiegeData.BEAST.n}
	# 요술 제단이 남았으면 가까운 제단부터(장각은 보호 중, D-207)
	var left := altars_left()
	if left > 0:
		var ap := K.get_center()
		var ad := INF
		for a in altars:
			if not a.dead and hero.position.distance_to(a.position) < ad:
				ad = hero.position.distance_to(a.position)
				ap = a.position
		return {"pos": ap, "n": "장각 본진 · 요술 제단 부수기 %d/%d" % [altars.size() - left, altars.size()]}
	var bp: Vector2 = b.boss.position if Unit.alive(b.boss) else K.get_center()
	return {"pos": bp, "n": "장각 본진 — 천공장군 장각 격파"}


## 정원지를 쓰러뜨린 뒤 진군 부대가 갈 곳과 길찾기 키
func march() -> Dictionary:
	var K := b.keep_rect()
	if b.boss == null:
		return {"key": "m_keep", "pos": Vector2(K.get_center().x, K.end.y + 60)}
	for i in altars.size():
		if not altars[i].dead:
			return {"key": "m_altar_%d" % i, "pos": altars[i].position}
	return {"key": "m_boss", "pos": b.boss.position if Unit.alive(b.boss) else K.get_center()}


# ─────────── 바닥 그리기(ground.gd가 자기 _draw 안에서 부름) ───────────

## 요술 제단 빛줄기 · 장각의 요술 · 봉인된 사신수
func draw_ground(g: Node2D, V: Rect2) -> void:
	_altar_beams(g, V)
	_sorcery(g, V)
	_beast(g, V)


## 성문이 열리는 중이면 문짝을 그리고 true(D-206): 문짝 둘이 양쪽 경첩을 축으로 북쪽(장각 쪽)으로 돌아감
func draw_gate(g: Node2D, o: Rect2) -> bool:
	if gate_t < 0:
		return false
	var e := 1.0 - pow(1.0 - clampf(gate_t / SiegeData.GATE_OPEN, 0, 1), 2)
	var half := o.size.x / 2
	var y := o.get_center().y
	g.draw_rect(Rect2(o.position.x + 2, o.position.y + 3, o.size.x - 4, o.size.y - 6), Color(0.1, 0.07, 0.04, 0.5 * (1.0 - e)))
	for side in [-1.0, 1.0]:
		var hinge := Vector2(o.position.x if side < 0 else o.end.x, y)
		var tip := hinge + Vector2(-side, 0).rotated(side * e * 1.75) * half
		g.draw_line(hinge, tip, Color("3a2410"), 11)
		g.draw_line(hinge, tip, Color("7a4a24"), 8)
		g.draw_circle(hinge, 4, Color("5a3a1a"))
	return true


## 요술 제단 → 장각 빛줄기(D-207): 장각이 보호막인 동안 남은 제단마다(제단 · 장각 노드는 화면 근처에서만 다시 그려서 바닥에서 그림)
func _altar_beams(g: Node2D, V: Rect2) -> void:
	if not Unit.alive(b.boss) or not b.boss.shield:
		return
	var bp: Vector2 = b.boss.position + Vector2(0, -24)
	var a := 0.35 + 0.15 * sin(b.t * 8)
	for al in altars:
		if al.dead:
			continue
		var p: Vector2 = al.position + Vector2(0, -26)
		if not V.intersects(Rect2(p, Vector2.ZERO).expand(bp)):
			continue
		g.draw_line(p, bp, Color(0.95, 0.75, 0.3, a), 5)
		g.draw_line(p, bp, Color(1, 0.95, 0.7, a + 0.2), 1.5)


## 장각의 요술(D-209): 낙뢰 예고 = 원(안쪽 원이 차오름) · 폭풍 = 누런 회오리(도는 호 셋)
func _sorcery(g: Node2D, V: Rect2) -> void:
	var S: Dictionary = SiegeData.SORCERY
	var br := float(S.bolt_r)
	for bo in bolts:
		var p: Vector2 = bo.pos
		if not V.grow(br).has_point(p):
			continue
		var k := clampf(float(bo.t) / float(S.bolt_warn), 0, 1)
		g.draw_circle(p, br, Color(0.95, 0.85, 0.35, 0.12 + 0.18 * k))
		g.draw_arc(p, br, 0, TAU, 32, Color(0.95, 0.8, 0.3, 0.8), 2)
		g.draw_arc(p, br * k, 0, TAU, 32, Color(1, 0.95, 0.6, 0.7), 1.5)
	var sr := float(S.storm_r)
	for sm in storms:
		var p: Vector2 = sm.pos
		if not V.grow(sr).has_point(p):
			continue
		var fade := clampf(float(sm.life) / 1.0, 0, 1)
		g.draw_circle(p, sr, Color(0.7, 0.62, 0.38, 0.16 * fade))
		for i in 3:
			var a := b.t * 4.0 + i * TAU / 3
			g.draw_arc(p, sr * (0.35 + 0.2 * i), a, a + 2.2, 16, Color(0.85, 0.78, 0.5, 0.55 * fade), 2)


## 봉인된 사신수 빛 구슬(D-207, 그림은 에셋 전까지): 둥실거리며 빛남 → 풀려나는 동안 커지며 흐려짐
func _beast(g: Node2D, V: Rect2) -> void:
	if beast_pos == Vector2.INF or not V.has_point(beast_pos):
		return
	var Bs: Dictionary = SiegeData.BEAST
	var c := Color(Bs.c)
	var p: Vector2 = beast_pos + Vector2(0, sin(b.t * 3) * 3 - 6)
	if beast_t >= 0:
		var k := clampf(beast_t / float(Bs.release), 0, 1)
		g.draw_circle(p, 12 + 140 * k, Color(c, 0.35 * (1.0 - k)))
		g.draw_circle(p, 10 + 30 * k, Color(1, 1, 1, 0.9 * (1.0 - k)))
		return
	g.draw_circle(beast_pos + Vector2(0, 8), 10, Color(0, 0, 0, 0.2))
	g.draw_circle(p, 22 + sin(b.t * 5) * 3, Color(c, 0.25))
	g.draw_circle(p, 13, Color(c, 0.75))
	g.draw_circle(p, 8, Color(1, 1, 1, 0.95))
	for i in 3:
		var a := b.t * 2.0 + i * TAU / 3
		g.draw_circle(p + Vector2.from_angle(a) * 20, 2, Color(1, 1, 1, 0.8))
	g.call("_label", "봉인된 %s" % Bs.n, p + Vector2(0, -34), Color("cfe8f8"))
