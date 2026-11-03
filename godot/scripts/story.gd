class_name Story
extends RefCounted
## 장마다 하나씩 있는 이야기 사건(D-242, ChapterData의 story — 연의 황건 편 소재, D-210).
## ambush(2장 청주 구원): at초에 황건 대열(cnt명 · 체력 × hp · march px/초)이 관문 남쪽 길(from)에서 본진으로 진군 →
##   장수가 대열보다 먼저 매복 자리(같은 길 위, 장수 높이를 y0~y1로 자른 곳)에 가 있으면
##   대열이 trigger px 안에 들 때 매복병이 양옆에서 덮치고 대열이 slow초 휘청임 → 대열을 다 쓰러뜨리면 보급 상자 + 경험. 대열이 자리를 지나치면 매복 실패.
## rescue(3장 동탁 구출): at초에 황건에게 쫓기는 동탁이 화면 밖에서 나타나 본진으로 도망(escort) — 추격대는 동탁만 노리고 gap초마다 더 옴(waves번) →
##   본진에 닿으면 구함(경험 xp) · 동탁은 고맙다는 말도 없이 무시하고 감(연의 제1회) / 쓰러지면 실패(벌은 없음).
## folk(6장 서주 백성 피난, D-252): at초부터 gap초마다 waves번, 백성 per명이 화면 밖에서 나타나 본진으로 피난(escort) — 조조군 추격대(cnt명)가 백성을 노림 →
##   본진에 닿은 백성마다 전공 merit · 경험 xp, 다 끝나면 구한 수 알림 · 절반 넘게 구하면 thanks(연의 제11~12회 — 도겸이 서주를 맡기려 함)
## Battle이 tick · target · on_kill · on_home · on_ally_dead · draw를 부름. 결과는 Battle.note와 res(봇 · 기록)

var b: Battle
var S: Dictionary
## 상태: wait → on → done(res = 성공 · 실패)
var st := "wait"
var res := ""
var t0 := -1.0
var col: Array[Enemy] = []
var ambushed := false
var npc: Ally = null
## 매복 자리(판마다 대열이 나온 자리에서 정함)
var spot := Vector2.ZERO
var wave_t := 0.0
var waves := 0
## 술이 식기 전에(D-245): 다음 알림 차례 · 화웅과 일기토가 시작된 판 시각(-1 = 아직)
var beat_i := 0
var duel_t0 := -1.0
var cold := false
## 서주 백성(D-252): 지금 피난 중인 백성 · 구한 수 · 잃은 수
var folks: Array[Ally] = []
## 무리마다 백성 묶음(D-254 — 화면 밖 무리 화살표)
var folk_grps: Array = []
var saved := 0
var lost := 0


func _init(battle: Battle, data: Dictionary) -> void:
	b = battle
	S = data


func tick(dt: float) -> void:
	if S.k == "wine":
		_wine_tick()
		return
	if S.k == "trio":
		_trio_tick()
		return
	if st == "wait":
		if b.t >= float(S.at) and not b.won and not b.duel():
			_start()
		return
	if st != "on":
		return
	if S.k == "ambush":
		_ambush_tick()
	elif S.k == "folk":
		_folk_tick(dt)
	else:
		_rescue_tick(dt)


func _start() -> void:
	st = "on"
	t0 = b.t
	if S.k == "ambush":
		# 대열은 관문 남쪽 길(정원지 대군과 같은 길 — 걸을 수 있는 길)에서 본진으로. 매복 자리는 같은 길 위, 장수와 같은 높이(y0~y1 안)라
		# 장수가 옆으로 몇 걸음 가면 닿고 대열은 한참 걸어와야 함(전엔 대열 → 본진 사이에 자리를 둬 장수가 가다가 대열을 다 베었음)
		var from: Vector2 = S.from
		spot = Vector2(float(Stage1.ARMY.road_x), clampf(b.hero.position.y, float(S.y0), float(S.y1)))
		var m := b.mul_y(from.y) * float(S.get("hp", 1.0))
		for i in int(S.cnt):
			# 넷씩 줄지어(관문 남쪽으로 — 전엔 북쪽으로 늘어서 닫힌 관문 너머에 끼었음)
			var p := from + Vector2((i % 4 - 1.5) * 22.0, (i / 4) * 20.0)
			var e := b.spawn("ytb", p, m)
			e.goal_home = true
			e.march_spd = float(S.march)
			e.aggro = 110.0
			e.xp_mul = Battle.REIN_XP
			col.append(e)
		b.note("청주 구원 — 황건 대열")
		b.banner("황건 대열이 청주로 향해요!", "대열보다 먼저 매복 자리에 가 있으면 매복병이 덮쳐요")
	elif S.k == "folk":
		waves = 0
		wave_t = 0.0
		b.note("%s — 시작" % S.n)
	else:
		var p := Vector2.INF
		for _k in 8:
			p = b.ring_pos(randf() * TAU)
			if p != Vector2.INF and p.distance_to(b.home_pos) > 900:
				break
		if p == Vector2.INF:
			st = "done"
			res = "없음"
			return
		npc = b.ally_spawn(String(S.npc), p, "escort", "")
		_pursuers(p)
		waves = 1
		wave_t = float(S.gap)
		b.note("동탁 구출 — 동탁 나타남")
		b.banner("황건에게 쫓기는 관군 장수!", "동탁을 본진까지 지켜 줘요")
	Sound.play("alert", 0.5)


## 동탁(또는 백성) 뒤쪽(본진 반대편)에서 추격대 — 그 아군만 노림(백성이면 무리 중 하나씩 돌아가며)
func _pursuers(at: Vector2, prey: Array = []) -> void:
	var away := (at - b.home_pos).normalized()
	var m := b.mul_y(at.y)
	for i in int(S.cnt):
		var p := at + away * randf_range(110, 170) + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		if b.hit_obs(p, 12):
			p = at + away * 120
		var e := b.spawn("ytdash" if i % 6 == 2 else "ytb", p, m)
		e.hunt_ally = npc if prey.is_empty() else prey[i % prey.size()]
		e.no_eng = true
		e.aggro = 0.0
		e.xp_mul = Battle.REIN_XP


func _alive_col() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e in col:
		if is_instance_valid(e) and not e.dead:
			out.append(e)
	return out


func _ambush_tick() -> void:
	var live := _alive_col()
	# 거의 다(남은 게 cnt의 10% 이하) 쓰러뜨리면 끝 — 길을 잃고 흩어진 몇 명 때문에 안 끝나지 않게
	if live.size() <= int(S.cnt) / 10:
		_finish("성공" if ambushed else "막음")
		return
	# limit초가 지나도 안 끝나면(대열이 길에 끼는 등) 실패로 끝내고 남은 대열은 그냥 본진으로
	if b.t - t0 > float(S.limit):
		_finish("실패")
		return
	if ambushed:
		return
	# 대열 가운데(흩어진 몇 명 · 돌진에 흔들리지 않게)
	var c := Vector2.ZERO
	for e in live:
		c += e.position
	c /= live.size()
	if c.distance_to(b.home_pos) < spot.distance_to(b.home_pos) - 60:
		# 대열이 매복 자리를 지나침
		_finish("실패")
		b.banner("매복이 늦었어요…", "황건 대열이 본진으로 가요 — 막아요")
		return
	# 장수가 매복 자리에 있고 대열의 누군가가 장수 trigger px 안에 들면(대열 길이 길로 휘어 와도)
	var nd := INF
	for e in live:
		nd = minf(nd, e.position.distance_to(b.hero.position))
	if b.hero.position.distance_to(spot) < float(S.r) and nd < float(S.trigger):
		ambushed = true
		for side in [-1.0, 1.0]:
			for j in int(S.allies):
				b.ally_spawn("sol", spot + Vector2(side * randf_range(90, 130), randf_range(-60, 60)), "march", "")
		for e in live:
			e.slow_t = float(S.slow)
			e.flash = 0.2
		b.add_fx({"k": "ring", "pos": spot, "t": 0.6, "r": 160.0, "c": Color("f0c040")})
		b.shake = maxf(b.shake, 0.3)
		b.note("매복!")
		b.banner("매복!", "양옆에서 의용병이 덮쳐요 — 대열이 흔들려요")
		Sound.play("slam", 0.5)


func _rescue_tick(dt: float) -> void:
	if not Unit.alive(npc):
		return
	wave_t -= dt
	if wave_t <= 0 and waves < int(S.waves):
		waves += 1
		wave_t = float(S.gap)
		_pursuers(npc.position)


## 백성 무리 하나(D-252): 본진에서 먼 둘레에 per명 + 추격대
## 나온 자리의 방향(장수에게서 — 알림 글, D-254). 못 나왔으면 빈 글
func _folk_wave() -> String:
	var p := Vector2.INF
	for _k in 8:
		p = b.ring_pos(randf() * TAU)
		if p != Vector2.INF and p.distance_to(b.home_pos) > 900:
			break
	if p == Vector2.INF:
		return ""
	var grp: Array = []
	for j in int(S.per):
		var a := b.ally_spawn(String(S.npc), p + Vector2((j - 1) * 24.0, randf_range(-10, 10)), "escort", "")
		folks.append(a)
		grp.append(a)
	folk_grps.append(grp)
	_pursuers(p, grp)
	b.note("%s — 무리 %d" % [S.n, waves])
	return dir_name(p - b.hero.position)


## 방향 이름(화면 위 = 북쪽): 여덟 방위
static func dir_name(d: Vector2) -> String:
	const N := ["동쪽", "남동쪽", "남쪽", "남서쪽", "서쪽", "북서쪽", "북쪽", "북동쪽"]
	return N[posmod(roundi(d.angle() / (PI / 4)), 8)]


## 화면 밖 무리 화살표(D-254): 무리마다 아직 피난 중인 백성 하나의 자리
func folk_marks() -> Array[Vector2]:
	var out: Array[Vector2] = []
	if S.k != "folk" or st != "on":
		return out
	for grp in folk_grps:
		for a in grp:
			if is_instance_valid(a) and not a.dead and a.mode == "escort":
				out.append(a.position)
				break
	return out


func _folk_tick(dt: float) -> void:
	wave_t -= dt
	if wave_t <= 0 and waves < int(S.waves):
		waves += 1
		wave_t = float(S.gap)
		var dn := _folk_wave()
		var from := "%s에서 " % dn if dn != "" else ""
		# 진영 부대 알림(45초마다)과 같은 때가 많음 — 알림 차례(D-255)가 줄을 세움
		if waves == 1:
			b.banner(line(S.hi[0]), "%s와요 — %s" % [from, line(S.hi[1])])
		else:
			b.banner("백성 무리가 %s또 쫓겨 와요!" % from, "본진까지 지켜 줘요 (%d/%d)" % [waves, int(S.waves)])
	if waves >= int(S.waves) and _folks_alive().is_empty():
		_folk_end()


func _folks_alive() -> Array[Ally]:
	var out: Array[Ally] = []
	# 쓰러지거나 본진에 닿은 백성은 지워짐(freed) — 먼저 걸러 냄
	var keep: Array[Ally] = []
	for a in folks:
		if is_instance_valid(a):
			keep.append(a)
			if not a.dead and a.mode == "escort":
				out.append(a)
	folks = keep
	return out


func _folk_end() -> void:
	var tot := int(S.waves) * int(S.per)
	_finish("%d/%d" % [saved, tot])
	if saved * 2 > tot:
		b.later(0.8, b.banner.bind(line(S.thanks[0]), "백성 %d/%d명을 구했어요 — %s" % [saved, tot, line(S.thanks[1])]))
	else:
		b.later(0.8, b.banner.bind("백성 %d/%d명을 구했어요" % [saved, tot], "다음엔 더 많이 지켜 줘요"))


## 동탁 · 백성이 본진에 닿음(Battle.captive_home)
func on_home(a: Ally) -> bool:
	if S.k == "folk" and a in folks:
		a.dead = true
		_release(a)
		saved += 1
		b.gain_xp(float(S.xp))
		b.bonus_merit += int(S.merit)
		b.add_fx({"k": "ring", "pos": b.home_pos, "t": 0.4, "r": 40.0, "c": Color("f0d878")})
		Sound.play("heal", 0.3)
		return true
	if a != npc:
		return false
	a.dead = true
	for e in b.enemies:
		if not e.dead and e.hunt_ally == npc:
			e.hunt_ally = null
			e.aggro = 260.0
	b.gain_xp(float(S.xp))
	_finish("성공")
	b.banner("동탁을 구했어요!", "경험 +%d" % int(S.xp))
	b.later(2.6, b.banner.bind("동탁: \"벼슬도 없는 것들이로군.\"", "고맙다는 말도 없이 무시하고 가 버렸어요…"))
	Sound.play("heal", 0.4)
	return true


## 노리던 아군이 없어진 추격대는 보통 적처럼
func _release(a: Ally) -> void:
	for e in b.enemies:
		if not e.dead and e.hunt_ally == a:
			e.hunt_ally = null
			e.aggro = 260.0


func on_ally_dead(a: Ally) -> void:
	if S.k == "folk" and a in folks:
		lost += 1
		_release(a)
		return
	if a == npc and st == "on":
		_finish("실패")
		b.banner("동탁이 쓰러졌어요…", "아쉬워하는 사람은 별로 없어요")


## 술이 식기 전에(D-245, 4장): 정한 때마다 연합 장수가 쓰러지는 알림(beats) → 관문 장수(화웅)와 일기토가 시작되면 warm초를 잼 →
## 그 안에 쓰러뜨리면 "술이 아직 따뜻해요" + 전공 merit(연의 제5회 — 관우가 데운 술이 식기 전에 화웅을 벰)
func _wine_tick() -> void:
	_beats()
	if b.siege == null:
		return
	var g: Enemy = b.siege.guard
	if duel_t0 < 0 and Unit.alive(g) and not b.arena.is_empty() and b.arena.lead == g and b.arena.st == "on":
		duel_t0 = b.t
		st = "on"
		b.banner("%s — %d초!" % [S.n, int(S.warm)], "데운 술이 식기 전에 %s%s 베어요" % [g.ename, Battle.eul(g.ename)])
	if duel_t0 >= 0 and not cold and st == "on" and b.t - duel_t0 > float(S.warm):
		cold = true
		b.banner("술이 식었어요…", "그래도 %s%s 베어요" % [g.ename if Unit.alive(g) else "적장", Battle.eul(g.ename if Unit.alive(g) else "적장")])


## 관문이 열린 뒤 정한 때마다 알림(beats — [판 시각, 제목, 아랫줄])
func _beats() -> void:
	while beat_i < S.beats.size() and b.t >= float(S.beats[beat_i][0]) and b.siege != null and b.siege.gate_open:
		b.banner(line(S.beats[beat_i][1]), line(S.beats[beat_i][2]))
		b.note(line(S.beats[beat_i][1]))
		beat_i += 1


## 삼영전(D-247, 5장 trio): 관문 장수(여포)가 나오면 출진 장수가 아닌 장수들(MetaData.HEROES)이 동료로 와서 함께 에워쌈(Companion —
## 마무리는 출진 장수: 동료는 여포를 conf.floor 아래로 못 깎음). 여포는 일기토가 아님(guard.no_duel)
func _trio_tick() -> void:
	_beats()
	if st != "wait" or b.siege == null or not Unit.alive(b.siege.guard):
		return
	st = "on"
	var g: Enemy = b.siege.guard
	var names: Array[String] = []
	var C: Dictionary = S.conf
	var i := 0
	for path in MetaData.HEROES:
		var hd: HeroData = load(path)
		if hd == null or hd.id == b.hero_data.id:
			continue
		var at := g.position + Vector2(-140 + 280 * (i % 2), 160)
		var c := Companion.new()
		c.setup_companion(b, hd, C, at, g)
		b.world.add_child(c)
		b.allies.append(c)
		b.companion = c
		b.cmp_log = {"goal_hp": g.max_hp, "left_t": -1.0, "why": ""}
		b.cmp_log_update(c)
		b.add_fx({"k": "ring", "pos": at, "t": 0.5, "r": 28.0, "c": Color("6a9ad8")})
		names.append(hd.display_name)
		i += 1
	b.note("%s — %s" % [S.n, ", ".join(names)])
	b.later(1.6, b.banner.bind(String(S.n) + "!", "%s%s 함께 %s%s 에워싸요" % [" · ".join(names), Battle.jo(names[-1] if not names.is_empty() else "", "이", "가"), g.ename, Battle.eul(g.ename)]))


## 장 글(D-246): {장수 id: 글, "": 기본}이면 출진 장수 것, {hero}는 출진 장수 이름
func line(v) -> String:
	var s := ""
	if v is Dictionary:
		s = String(v.get(b.hero_data.id, v.get("", "")))
	else:
		s = String(v)
	return s.replace("{hero}", b.hero_data.display_name)


func on_kill(e: Enemy) -> void:
	if S.k != "wine" or st != "on" or b.siege == null or e != b.siege.guard:
		return
	var took := b.t - duel_t0
	if took <= float(S.warm):
		b.bonus_merit += int(S.merit)
		_finish("성공")
		b.later(0.9, b.banner.bind(line(S.get("won", "술이 아직 따뜻해요!")), "%.0f초 만에 베었어요 — 전공 +%d" % [took, int(S.merit)]))
	else:
		_finish("식음")


func _finish(r: String) -> void:
	if st == "done":
		return
	st = "done"
	res = r
	b.note("%s %s" % [S.n, r])
	if S.k == "ambush" and r == "성공":
		b.drops.append({"k": "chest", "pos": spot})
		b.gain_xp(float(S.xp))
		b.banner("%s!" % S.n, "보급 상자 · 경험 +%d" % int(S.xp))
		Sound.play("win", 0.45)


## 목표 줄(사건이 진행 중일 때만 — 없으면 빈 것)
func target() -> Dictionary:
	if st != "on" or S.k == "wine":
		return {}
	if S.k == "ambush":
		var live := _alive_col()
		if ambushed:
			var c: Vector2 = live[0].position if not live.is_empty() else spot
			return {"pos": c, "n": "%s — 황건 대열 쓰러뜨리기 (%d명)" % [S.n, live.size()], "warn": true}
		return {"pos": spot, "n": "%s — 매복 자리로! (대열보다 먼저)" % S.n, "warn": true}
	if S.k == "folk":
		var live := _folks_alive()
		if live.is_empty():
			return {}
		var near: Ally = live[0]
		for a in live:
			if a.position.distance_to(b.hero.position) < near.position.distance_to(b.hero.position):
				near = a
		return {"pos": near.position, "n": "%s — 백성을 본진까지 (%d명 피난 중 · 구함 %d)" % [S.n, live.size(), saved], "warn": true}
	if Unit.alive(npc):
		return {"pos": npc.position, "n": "%s — 동탁을 본진까지 (동탁 %d%%)" % [S.n, ceili(npc.hp / npc.max_hp * 100)], "warn": true}
	return {}


## 바닥: 매복 자리(아직이면 깜빡이는 점선 원 + 글)
func draw(g: Node2D, V: Rect2) -> void:
	if S.k != "ambush" or st != "on" or ambushed:
		return
	if not V.grow(80).has_point(spot):
		return
	var a := 0.5 + 0.3 * sin(b.t * 5)
	g.draw_arc(spot, float(S.r), 0, TAU, 40, Color(0.94, 0.75, 0.25, a), 3)
	var f := Fonts.small()
	g.draw_string_outline(f, spot + Vector2(-50, 5), "매복 자리", HORIZONTAL_ALIGNMENT_CENTER, 100, 11, 3, Color(0.11, 0.09, 0.07))
	g.draw_string(f, spot + Vector2(-50, 5), "매복 자리", HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color("fff2c0"))
