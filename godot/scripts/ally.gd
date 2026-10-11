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
	var march := mode == "march"
	var anc: Dictionary = b.anchors.get(anchor, {})
	if scan <= 0:
		scan = 0.3
		var rad: float = 160.0 if march else float(anc.get("r", 200.0))
		var center: Vector2 = position if march else anc.get("pos", position)
		var best: Enemy = null
		var bd := INF
		for e in b.enemies:
			if e.dead or e.air > 0 or e.position.distance_to(center) > rad:
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
		var ap: Vector2 = anc.get("pos", position)
		g = ap + Vector2(cos(slot) * 50, sin(slot) * 36)
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
		var sp := spd * (1.25 if march and tg == null else 1.0)
		position += m / md * minf(md, sp * dt)
		b.push_out(self)
	elif tg != null and cd <= 0:
		cd = def.cd
		b.hurt_enemy(tg, atk * b.tactics.ally_mul())
		b.add_fx({"k": "spark", "pos": tg.position + Vector2(0, -3), "t": 0.15, "a": (tg.position - position).angle(), "c": Color("a8c8f0")})
	# 붙은 황건에게 맞음
	if hit_cd <= 0:
		var hit := b.touching_enemy(position, r + 3)
		if hit != null:
			# 수비대는 웹판처럼 60%만, 진군 부대는 다 받음(D-180)
			hp -= hit.touch * (1.0 if march else 0.6)
			hit_cd = 0.6
	if hp <= 0:
		dead = true
		b.add_fx({"k": "burst", "pos": position, "t": 0.3, "r": 6.0, "c": Color("6a9ad8")})
		b.ally_down(self)


## 다시 그리기는 Battle._redraw_units가 화면 근처에 있을 때만 부름
func _draw() -> void:
	var b := battle
	if b == null:
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
