class_name Tactics
extends Node
## 판 안 책략(D-172): 가진 것 · 레벨 · 진화 · 레벨업 고르기 · 매 프레임 공격(웹판 skillTick · skillOptions · applyOpt).
## 공격 6칸(1칸 = 장수 기본 공격 "basic", 처음부터 Lv1) + 보조 6칸. 진화 = 공격 Lv5 + 짝 보조(가지고만 있으면).
## 책략 공격은 연격 수 · 무쌍 게이지를 쌓지 않는다(웹판과 같음 — 연격 수는 기본 공격 명중으로만).


var b: Battle
## 키 → 레벨 / 진화함
var lv := {}
var evo := {}
## 칸 순서(얻은 차례). 공격 칸 맨 앞은 늘 장수 기본 공격
var act_order: Array[String] = ["basic"]
var pas_order: Array[String] = []
## 고른 기록 "Lv2 연노 1" · "Lv12 진화 청룡 강림"
var history: Array[String] = []
var cd := {}
var orb_a := 0.0
## 화살비 떨어질 곳 {pos, r, t, T, dmg} · 불길 {pos, r, t, T, tick, dmg}
var warns: Array[Dictionary] = []
var fires: Array[Dictionary] = []
## 연노 · 비도 {k, pos, dir, spd, dmg, hits, travel, reach, hit} · 진천뢰 {from, to, t, T, r, dmg, push}
var darts: Array[Dictionary] = []
var bombs: Array[Dictionary] = []
var _regen_acc := 0.0


func setup(battle: Battle) -> void:
	b = battle
	lv["basic"] = 1


# ─────────── 이름 · 짝 ───────────

func is_act(k: String) -> bool:
	return k == "basic" or TacticsData.ACT.has(k)


func level(k: String) -> int:
	return lv.get(k, 0)


func evolved(k: String) -> bool:
	return evo.get(k, false)


func pair_of(k: String) -> String:
	if k == "basic":
		return b.hero_data.basic_evo_pair if b.hero_data.basic_evo != null else ""
	return String(TacticsData.DEFS[k].get("pair", ""))


func name_of(k: String) -> String:
	if k == "basic":
		return evo_name(k) if evolved(k) else b.hero_data.basic.display_name
	return String(TacticsData.DEFS[k].n) if not evolved(k) else evo_name(k)


func evo_name(k: String) -> String:
	if k == "basic":
		return b.hero_data.basic_evo.display_name if b.hero_data.basic_evo != null else ""
	return String(TacticsData.DEFS[k].get("en", ""))


func evo_desc(k: String) -> String:
	return b.hero_data.basic_evo_desc if k == "basic" else String(TacticsData.DEFS[k].get("ed", ""))


func glyph_of(k: String) -> String:
	if k == "basic":
		return b.hero_data.basic_evo.glyph if evolved(k) else b.hero_data.basic.glyph
	return String(TacticsData.DEFS[k].g)


func color_of(k: String) -> Color:
	if k == "basic":
		return Color("4a8a5a") if not evolved(k) else Color("2a9a78")
	return Color(String(TacticsData.DEFS[k].c))


## 이 레벨로 올릴 때의 설명(nl = 오를 레벨)
func level_desc(k: String, nl: int) -> String:
	if k == "basic":
		var A := b.hero_data.basic
		return "가장 가까운 적 쪽으로 날아가 꿰뚫어요" if nl <= 1 else String(A.at_level(A.level_desc, nl - 1, ""))
	var d = TacticsData.DEFS[k].d
	return String(d[nl - 1]) if d is Array else String(d)


## 이 보조를 짝으로 하는 공격(장수 기본 공격 포함)
func pairs_for(pas: String) -> Array[String]:
	var out: Array[String] = []
	if b.hero_data.basic_evo != null and b.hero_data.basic_evo_pair == pas:
		out.append("basic")
	for k in TacticsData.ACT:
		if String(TacticsData.DEFS[k].pair) == pas:
			out.append(k)
	return out


func can_evolve(k: String) -> bool:
	return is_act(k) and level(k) >= TacticsData.MAX_LV and not evolved(k) and pair_of(k) != "" and level(pair_of(k)) > 0


func evo_count() -> int:
	return evo.size()


# ─────────── 보조 효과 ───────────

func _per(k: String) -> float:
	return float(TacticsData.DEFS[k].per) * level(k)


func power_mul() -> float:
	return 1.0 + _per("mu")


func hurt_mul() -> float:
	return 1.0 - _per("gap")


func cd_mul() -> float:
	return maxf(0.4, 1.0 - _per("ji"))


func speed_mul() -> float:
	return 1.0 + _per("sin")


func ally_mul() -> float:
	return 1.0 + _per("cmd")


func area_mul() -> float:
	return 1.0 + _per("art")


func gauge_mul() -> float:
	return 1.0 + _per("spirit")


## 수치 하나: 진화했으면 evo 값, 배열이면 지금 레벨 값
func val(k: String, key: String):
	var d: Dictionary = TacticsData.DEFS[k]
	if evolved(k) and d.evo.has(key):
		return d.evo[key]
	var v = d[key]
	if v is Array:
		return v[clampi(level(k), 1, TacticsData.MAX_LV) - 1]
	return v


# ─────────── 레벨업 고르기 ───────────

## 3개 후보. 진화할 수 있으면 먼저(무조건 보임), 나머지는 무게를 둔 뽑기(웹판 skillOptions · pickOpts와 같은 무게)
## o = {k, evo?, new?, ready?(고르면 다음에 진화 가능)}
func options(n := 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var res: Array[Dictionary] = []
	for k in act_order:
		if can_evolve(k):
			res.append({"k": k, "evo": true})
		elif level(k) < TacticsData.MAX_LV:
			pool.append({"k": k, "w": 3.0})
	if act_order.size() < TacticsData.ACT_SLOTS:
		for k in TacticsData.ACT:
			if not lv.has(k):
				pool.append({"k": k, "w": 2.0, "new": true})
	for k in pas_order:
		if level(k) < TacticsData.MAX_LV:
			pool.append({"k": k, "w": 2.0})
	if pas_order.size() < TacticsData.PAS_SLOTS:
		for k in TacticsData.PAS:
			if not lv.has(k):
				pool.append({"k": k, "w": 1.6, "new": true})
	while res.size() > n:
		res.pop_back()
	while res.size() < n and not pool.is_empty():
		var tot := 0.0
		for o in pool:
			tot += float(o.w)
		var r := randf() * tot
		var i := 0
		while i < pool.size() - 1:
			r -= float(pool[i].w)
			if r <= 0:
				break
			i += 1
		res.append(pool[i])
		pool.remove_at(i)
	if res.is_empty():
		res.append({"k": "bun"})
	for o in res:
		o["ready"] = _completes(o)
	return res


## 이걸 고르면 다음 고르기에 진화가 나오는가(카드가 빛남)
func _completes(o: Dictionary) -> bool:
	var k: String = o.k
	if k == "bun" or o.get("evo", false):
		return false
	if is_act(k):
		return level(k) + 1 == TacticsData.MAX_LV and pair_of(k) != "" and level(pair_of(k)) > 0
	if level(k) == 0:
		for a in pairs_for(k):
			if level(a) >= TacticsData.MAX_LV and not evolved(a):
				return true
	return false


func apply(o: Dictionary) -> void:
	var k: String = o.k
	var tag := ""
	if k == "bun":
		b.hero.heal(b.hero.max_hp * 0.3)
		tag = "고기만두"
	elif o.get("evo", false):
		evo[k] = true
		tag = "진화 " + evo_name(k)
		b.banner("진화 — %s!" % evo_name(k), evo_desc(k))
		Sound.play("win", 0.4)
		b.add_fx({"k": "ring", "pos": b.hero.position, "t": 0.6, "r": 90.0, "c": Color("7ae8c0")})
	else:
		if not lv.has(k):
			(act_order if is_act(k) else pas_order).append(k)
			cd[k] = 0.3
		lv[k] = level(k) + 1
		tag = "%s %d" % [String(TacticsData.DEFS[k].n) if k != "basic" else b.hero_data.basic.display_name, lv[k]]
	history.append("Lv%d %s" % [b.lvl, tag])


## 보급 상자(D-195 · D-205): 진화할 수 있는 공격이 있으면 진화(먼저 얻은 것), 아니면 가진 책략 중 Lv5가 아닌 것
## Stage1.CHEST min~max개를 한 단계씩. 올릴 것도 없으면 고기만두. 고른 기록에 '상자'로 남김. 돌려주는 글 = 알림 아랫줄
func open_chest() -> String:
	for k in act_order:
		if can_evolve(k):
			evo[k] = true
			history.append("Lv%d 상자: 진화 %s" % [b.lvl, evo_name(k)])
			return "진화 — %s!" % evo_name(k)
	var can: Array[String] = []
	for k in act_order + pas_order:
		if level(k) < TacticsData.MAX_LV:
			can.append(k)
	if can.is_empty():
		b.hero.heal(b.hero.max_hp * 0.3)
		history.append("Lv%d 상자: 고기만두" % b.lvl)
		return "고기만두 — 기운을 차렸어요"
	can.shuffle()
	var n := mini(can.size(), randi_range(int(Stage1.CHEST.min), int(Stage1.CHEST.max)))
	var ups: Array[String] = []
	for k in can.slice(0, n):
		lv[k] = level(k) + 1
		ups.append("%s %d" % [name_of(k), lv[k]])
	history.append("Lv%d 상자: %s" % [b.lvl, ", ".join(ups)])
	return "레벨 업 — " + ", ".join(ups)


# ─────────── 매 프레임 ───────────

func tick(dt: float) -> void:
	var h := b.hero
	var gun := float(TacticsData.DEFS.gun.per) * level("gun")
	if gun > 0:
		_regen_acc += gun * dt
		if _regen_acc >= 1.0:
			var v := floorf(_regen_acc)
			_regen_acc -= v
			h.hp = minf(h.max_hp, h.hp + v)
	var atk := h.atk * power_mul()
	for k in act_order:
		if k == "basic" or k == "orbit":
			continue
		cd[k] = float(cd.get(k, 0.0)) - dt
		if cd[k] > 0:
			continue
		match k:
			"arrow":
				_arrow(atk)
			"fire":
				_fire(atk)
			"bolt":
				_bolt(atk)
			"xbow":
				_xbow(atk)
			"bomb":
				_bomb(atk)
			"knife":
				_knife(atk)
			"drum":
				_drum(atk)
	_orbit(dt, atk)
	_tick_warns(dt)
	_tick_fires(dt)
	_tick_darts(dt)
	_tick_bombs(dt)


func _in_view() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e in b.enemies:
		if not e.dead and not e.shield and b.in_view(e.position, 0):
			out.append(e)
	return out


func _nearest(n: int, max_d: float) -> Array[Enemy]:
	var p := b.hero.position
	var c: Array = []
	for e in b.enemies:
		if not e.dead and not e.shield:
			var d := e.position.distance_to(p)
			if d < max_d:
				c.append([d, e])
	c.sort_custom(func(x, y): return x[0] < y[0])
	var out: Array[Enemy] = []
	for i in mini(n, c.size()):
		out.append(c[i][1])
	return out


func _hit_area(at: Vector2, r: float, dmg: float) -> int:
	var n := 0
	var i := 0
	while i < b.enemies.size():
		var e := b.enemies[i]
		i += 1
		if not e.dead and not e.shield and e.position.distance_to(at) < r + e.r:
			b.hurt_enemy(e, dmg)
			n += 1
	return n


## 회전 언월: 칼날이 장수 둘레를 늘 돎(적마다 0.35초에 한 번)
func orbit_blades() -> Array[Vector2]:
	var out: Array[Vector2] = []
	if level("orbit") == 0:
		return out
	var n := int(val("orbit", "blades"))
	var R := float(val("orbit", "radius")) * area_mul()
	for i in n:
		out.append(b.hero.position + Vector2.from_angle(orb_a + float(i) / n * TAU) * R)
	return out


func _orbit(dt: float, atk: float) -> void:
	if level("orbit") == 0:
		return
	orb_a += dt * float(val("orbit", "spin"))
	var dmg := atk * float(val("orbit", "mult"))
	var gap := float(TacticsData.DEFS.orbit.hit_gap)
	for p in orbit_blades():
		var i := 0
		while i < b.enemies.size():
			var e := b.enemies[i]
			i += 1
			if not e.dead and not e.shield and e.orb_t <= 0 and e.position.distance_to(p) < e.r + 12:
				e.orb_t = gap
				b.hurt_enemy(e, dmg)


## 화살 비: 화면 안 적 자리에 0.45초 뒤 떨어짐
func _arrow(atk: float) -> void:
	cd["arrow"] = float(val("arrow", "cd")) * cd_mul()
	var tg := _in_view()
	if tg.is_empty():
		cd["arrow"] = 0.3
		return
	var T := float(TacticsData.DEFS.arrow.delay)
	for i in int(val("arrow", "count")):
		var e: Enemy = tg.pick_random()
		warns.append({"pos": e.position + Vector2(randf_range(-12, 12), randf_range(-12, 12)), "r": float(val("arrow", "r")) * area_mul(),
			"t": T, "T": T, "dmg": atk * float(val("arrow", "mult"))})


func _tick_warns(dt: float) -> void:
	if warns.is_empty():
		return
	var keep: Array[Dictionary] = []
	for w in warns:
		w.t -= dt
		if w.t > 0:
			keep.append(w)
			continue
		_hit_area(w.pos, w.r, w.dmg)
		b.add_fx({"k": "rain", "pos": w.pos, "r": w.r, "t": 0.3})
	warns = keep


## 화계: 가까운 적 무리에 불 항아리 → 땅이 0.4초마다 탐
func _fire(atk: float) -> void:
	cd["fire"] = float(val("fire", "cd")) * cd_mul()
	var tg := _nearest(12, 320)
	var p := b.hero.position
	for i in int(val("fire", "count")):
		var at: Vector2 = tg.pick_random().position if not tg.is_empty() else p + Vector2(randf_range(-120, 120), randf_range(-120, 120))
		var dur := float(val("fire", "dur"))
		fires.append({"pos": at, "r": float(val("fire", "r")) * area_mul(), "t": dur, "T": dur, "tick": 0.0, "dmg": atk * float(val("fire", "mult"))})


func _tick_fires(dt: float) -> void:
	if fires.is_empty():
		return
	var keep: Array[Dictionary] = []
	var gap := float(TacticsData.DEFS.fire.tick)
	for f in fires:
		f.t -= dt
		f.tick -= dt
		if f.tick <= 0:
			f.tick = gap
			_hit_area(f.pos, f.r, f.dmg)
		if f.t > 0:
			keep.append(f)
	fires = keep


## 낙뢰: 화면 안 적에게 벼락. 진화하면 사슬처럼 세 번 번짐(70%)
func _bolt(atk: float) -> void:
	cd["bolt"] = float(val("bolt", "cd")) * cd_mul()
	var tg := _in_view()
	if tg.is_empty():
		cd["bolt"] = 0.3
		return
	var dmg := atk * float(val("bolt", "mult"))
	var r := float(val("bolt", "r")) * area_mul()
	var chain := int(TacticsData.DEFS.bolt.evo.chain) if evolved("bolt") else 0
	for i in int(val("bolt", "count")):
		var e: Enemy = tg.pick_random()
		var at := e.position
		b.add_fx({"k": "sky", "pos": at, "t": 0.25})
		Sound.play("hit", 0.2)
		_hit_area(at, r, dmg)
		var prev := at
		for c in chain:
			var nx: Enemy = null
			var bd := 140.0
			for o in b.enemies:
				var d := o.position.distance_to(prev)
				if not o.dead and not o.shield and d > 4 and d < bd:
					bd = d
					nx = o
			if nx == null:
				break
			b.add_fx({"k": "chain", "pos": prev, "pos2": nx.position, "t": 0.2})
			b.hurt_enemy(nx, dmg * 0.7)
			prev = nx.position


## 연노: 가장 가까운 적 쪽으로 꿰뚫는 화살
func _xbow(atk: float) -> void:
	cd["xbow"] = float(val("xbow", "cd")) * cd_mul()
	var reach := float(TacticsData.DEFS.xbow.reach)
	var tg := b.nearest_enemy(b.hero.position, reach)
	if tg == null:
		cd["xbow"] = 0.15
		return
	var a := (tg.position - b.hero.position).angle()
	var n := int(val("xbow", "count"))
	var sp := float(val("xbow", "spread"))
	for i in n:
		_dart("xbow", a + (i - (n - 1) / 2.0) * sp, float(TacticsData.DEFS.xbow.speed), reach, atk * float(val("xbow", "mult")), int(val("xbow", "pierce")))


## 비도: 사방으로 고르게(돌려 가며)
func _knife(atk: float) -> void:
	cd["knife"] = float(val("knife", "cd")) * cd_mul()
	if b.nearest_enemy(b.hero.position, 260) == null:
		cd["knife"] = 0.3
		return
	var n := int(val("knife", "count"))
	var off := randf() * TAU
	for i in n:
		_dart("knife", off + float(i) / n * TAU, float(TacticsData.DEFS.knife.speed), float(val("knife", "reach")), atk * float(val("knife", "mult")), int(val("knife", "pierce")))


func _dart(k: String, a: float, spd: float, reach: float, dmg: float, pierce: int) -> void:
	darts.append({"k": k, "pos": b.hero.position, "dir": Vector2.from_angle(a), "spd": spd, "dmg": dmg, "hits": pierce + 1, "travel": 0.0, "reach": reach, "hit": {}})


func _tick_darts(dt: float) -> void:
	if darts.is_empty():
		return
	var keep: Array[Dictionary] = []
	for s in darts:
		var step: float = s.spd * dt
		var p: Vector2 = s.pos + s.dir * step
		s.pos = p
		s.travel += step
		if s.travel > s.reach:
			continue
		if b.in_wall(p, 2):
			b.add_fx({"k": "puff", "pos": p, "t": 0.2})
			continue
		var i := 0
		while i < b.enemies.size() and s.hits > 0:
			var e := b.enemies[i]
			i += 1
			if e.dead or e.shield or s.hit.has(e.get_instance_id()) or e.position.distance_to(p) > e.r + 5:
				continue
			s.hit[e.get_instance_id()] = true
			b.hurt_enemy(e, s.dmg)
			s.hits -= 1
		if s.hits > 0:
			keep.append(s)
	darts = keep


## 진천뢰: 가까운 적 무리에 던져 0.55초 뒤 터짐 · 졸개는 밀려남
func _bomb(atk: float) -> void:
	cd["bomb"] = float(val("bomb", "cd")) * cd_mul()
	var tg := _nearest(12, 300)
	if tg.is_empty():
		cd["bomb"] = 0.3
		return
	var T := float(TacticsData.DEFS.bomb.fly)
	for i in int(val("bomb", "count")):
		var to: Vector2 = tg.pick_random().position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
		bombs.append({"from": b.hero.position, "to": to, "t": 0.0, "T": T, "r": float(val("bomb", "r")) * area_mul(),
			"dmg": atk * float(val("bomb", "mult")), "push": float(val("bomb", "push"))})


func _tick_bombs(dt: float) -> void:
	if bombs.is_empty():
		return
	var keep: Array[Dictionary] = []
	for m in bombs:
		m.t += dt
		if m.t < m.T:
			keep.append(m)
			continue
		_blast(m.to, m.r, m.dmg, m.push, Color("ffb050"))
	bombs = keep


## 전고: 둘레에 충격파(둘레에 적이 있을 때만). 진화하면 울릴 때마다 무쌍 게이지도 참
func _drum(atk: float) -> void:
	cd["drum"] = float(val("drum", "cd")) * cd_mul()
	var r := float(val("drum", "r")) * area_mul()
	if b.nearest_enemy(b.hero.position, r) == null:
		cd["drum"] = 0.3
		return
	_blast(b.hero.position, r, atk * float(val("drum", "mult")), float(val("drum", "push")), Color("e8a060"))
	if evolved("drum"):
		b.hero.mg = minf(100.0, b.hero.mg + float(TacticsData.DEFS.drum.evo.gauge) * gauge_mul())


func _blast(at: Vector2, r: float, dmg: float, push: float, col: Color) -> void:
	var i := 0
	while i < b.enemies.size():
		var e := b.enemies[i]
		i += 1
		if e.dead or e.shield:
			continue
		var dv := e.position - at
		var d := dv.length()
		if d > r + e.r:
			continue
		b.hurt_enemy(e, dmg)
		if not e.dead and not e.immovable() and d > 0.1:
			e.position += dv / d * push
	b.add_fx({"k": "ring", "pos": at, "t": 0.35, "r": r, "c": col})
	b.add_fx({"k": "burst", "pos": at, "t": 0.3, "r": r * 0.3, "c": col})
	b.shake = maxf(b.shake, 0.08)
	Sound.play("slam", 0.2)
