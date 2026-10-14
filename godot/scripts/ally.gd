class_name Ally
extends Unit
## 아군(웹판 alSpawn · alTick). guard = 본진·점령한 진영을 지킴(그대로) /
## march = 진군 부대(D-180): 장수 둘레를 돌지 않고 다음 목표(Battle.march_goal)로 먼저 가서 싸움. 보충 없음, 받는 피해를 줄이지 않음.
## 아군 강화는 '호령' 책략으로만(D-180 — 점령 수 · 도원의 맹약 배율은 뺌).

var k := "sol"
var def: Dictionary
var atk := 9.0
var spd := 84.0
var cd := 0.0
var hit_cd := 0.0
var scan := 0.0
var mode := "guard"
var anchor := ""
var tg: Enemy = null
var slot := 0.0
var size := 24.0
## 지키는 아군이 적이 없을 때 자리 둘레를 천천히 거닒(2026-10-13): 다음에 자리를 바꿀 때까지 · 자리 거리.
## 판의 다른 난수(--seed 재현)에 영향이 없게 따로 된 난수
var stroll_t := 0.0
var stroll_r := 1.0
static var _rng := RandomNumberGenerator.new()


func setup(b: Battle, key: String, at: Vector2, m: String, anchor_id: String) -> void:
	battle = b
	k = key
	def = Units.ALLY[key]
	position = at
	last_pos = at
	mode = m
	anchor = anchor_id
	r = def.r
	max_hp = float(def.hp) * b.tactics.ally_mul()
	hp = max_hp
	atk = float(def.atk)
	spd = def.spd
	size = def.size
	cd = randf_range(0, 0.6)
	slot = randf() * TAU
	tint = Color(def.c)
	tex = Sprites.sheet(def.spr)


func tick(dt: float) -> void:
	var b := battle
	var hero := b.hero
	cd -= dt
	hit_cd -= dt
	scan -= dt
	if mode == "escort":
		_escort_tick(dt)
		return
	var march := mode == "march"
	var anc: Dictionary = b.anchors.get(anchor, {})
	if scan <= 0:
		scan = 0.3
		var rad: float = 160.0 if march else float(anc.get("r", 200.0))
		var center: Vector2 = position if march else anc.get("pos", position)
		var best: Enemy = null
		var bd := INF
		for e in b.enemies:
			if e.dead or e.shield or e.prop or e.air > 0 or e.position.distance_to(center) > rad:
				continue
			var dd := e.position.distance_to(position)
			if dd < bd:
				bd = dd
				best = e
		tg = best
	if tg != null and not Unit.alive(tg):
		tg = null
	var g: Vector2
	var reach := 10.0
	if tg != null:
		g = tg.position
		reach = r + tg.r + 5
	elif march:
		var G := b.march_goal(position)
		g = G.pos + Vector2(cos(slot) * 34, sin(slot) * 26)
	else:
		stroll_t -= dt
		# 유비(총대장)는 거닐지 않고 본진 가운데를 지킴
		if stroll_t <= 0 and k != "liubei":
			stroll_t = _rng.randf_range(2.5, 5.5)
			slot = _rng.randf() * TAU
			stroll_r = _rng.randf_range(0.3, 1.3)
		var ap: Vector2 = anc.get("pos", position)
		g = ap + Vector2(cos(slot) * 50, sin(slot) * 36) * stroll_r
	var d := g.distance_to(position)
	last_pos = position
	if d > reach:
		var to := g
		if tg == null and march and d > 60:
			var G := b.march_goal(position)
			to = b.path_for(self, G.key, G.pos)
		var m := to - position
		var md := m.length()
		if md == 0.0:
			md = 1.0
		# 진군 부대는 빨리, 지키는 아군이 자리 둘레를 거닐 땐 천천히(멀리서 돌아올 땐 제 빠르기)
		var sp := spd * (1.25 if march and tg == null else (0.4 if tg == null and d < 90 else 1.0))
		position += m / md * minf(md, sp * dt)
		b.push_out(self)
	elif tg != null and cd <= 0:
		cd = def.cd
		b.hurt_enemy(tg, atk * b.tactics.ally_mul())
		b.add_fx({"k": "spark", "pos": tg.position + Vector2(0, -3), "t": 0.15, "a": (tg.position - position).angle(), "c": Color("a8c8f0")})
	# 붙은 황건에게 맞음
	if hit_cd <= 0:
		var hit := b.touching_enemy(position, r + 3, k == "liubei")
		if hit != null:
			# 수비대는 웹판처럼 60%만, 진군 부대는 다 받음(D-180)
			hp -= hit.touch * (1.0 if march else 0.6)
			hit_cd = 0.6
	if hp <= 0:
		dead = true
		b.add_fx({"k": "burst", "pos": position, "t": 0.3, "r": 6.0, "c": Color("6a9ad8")})
		b.ally_down(self)


## 감옥에서 풀려난 의용병(2026-10-14): 싸우지 않고 본진으로 걸어감(적이 노림, 받는 피해 그대로). 본진에 닿으면 본진 수비대(Battle.captive_home)
func _escort_tick(dt: float) -> void:
	var b := battle
	var to := b.path_for(self, "h", b.home_pos)
	var m := to - position
	if m.length() > 0.01:
		last_pos = position
		position += m.normalized() * minf(m.length(), spd * dt)
		b.push_out(self)
	if position.distance_to(b.home_pos) < b.home_r + 10:
		mode = "guard"
		anchor = "home"
		b.captive_home(self)
		return
	if hit_cd <= 0:
		var hit := b.touching_enemy(position, r + 3)
		if hit != null:
			# 받는 피해 × 0.65(호위 안 하면 절반쯤 쓰러짐) — 길목 부대에 셋이 한꺼번에 쓰러지지 않고 장수가 구하러 갈 틈이 있게
			hp -= hit.touch * 0.65
			hit_cd = 0.6
	if hp <= 0:
		dead = true
		b.add_fx({"k": "burst", "pos": position, "t": 0.3, "r": 6.0, "c": Color("6a9ad8")})


## 다시 그리기는 Battle._redraw_units가 화면 근처에 있을 때만 부름
func _draw() -> void:
	Perf.begin(&"그리기:아군")
	_draw_impl()
	Perf.end()


func _draw_impl() -> void:
	var b := battle
	if b == null:
		return
	if k == "supply":
		# 보급 수레(코드로 그린 임시): 바퀴 둘 + 짐칸 + 푸른 덮개
		draw_rect(Rect2(-16, 6, 32, 5), Color(0, 0, 0, 0.22))
		draw_rect(Rect2(-15, -12, 30, 14), Color("8a5a2a"))
		draw_rect(Rect2(-13, -20, 26, 9), Color("4a7ab8"))
		draw_rect(Rect2(-15, -12, 30, 14), Color("3a2410"), false, 1.5)
		for wx in [-9.0, 9.0]:
			draw_circle(Vector2(wx, 4), 5, Color("3a2410"))
			draw_circle(Vector2(wx, 4), 2, Color("a8743a"))
		draw_bar(0, -28, 34, 4, hp / max_hp, Color("6a9ad8"))
		draw_label("보급 수레", Vector2(0, -36), Color("cfe2f4"))
		return
	draw_oval(Vector2(0, r * 0.9), r * 1.1, r * 0.45, Color(0.42, 0.6, 0.85, 0.9), false, 2)
	var moved := anim_moved()
	var mv := moved.length() > 0.2
	if mv:
		face_dir = Sprites.dir_of(moved)
	elif Unit.alive(tg):
		face_dir = Sprites.dir_of(tg.position - position)
	draw_body(face_dir, Sprites.walk_step(mv, b.t + slot, 7), size, 1.0, 0.0, String(def.n).left(1))
	if hp < max_hp:
		draw_bar(0, -r - 10, 30.0 if k == "liubei" else 20.0, 3, hp / max_hp, Color("6a9ad8"))
	if k == "liubei":
		draw_label(def.n, Vector2(0, -r - 18), Color("cfe2f4"))
