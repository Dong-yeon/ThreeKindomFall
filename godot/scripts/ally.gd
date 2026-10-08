class_name Ally
extends Unit
## 아군(웹판 alSpawn · alTick). guard = 본진·점령한 진영을 지킴 / join = 장수를 따라다니며 싸움.

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
	# 점령한 진영이 많을수록 단단해짐 · 출진 구성 배율(도원의 맹약)
	var mul := (1.0 + 0.15 * b.cap_n) * b.ally_mul
	r = def.r
	max_hp = float(def.hp) * mul
	hp = max_hp
	atk = float(def.atk) * mul
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
	var join := mode == "join"
	var anc: Dictionary = b.anchors.get(anchor, {})
	if scan <= 0:
		scan = 0.3
		var rad: float = 210.0 if join else float(anc.get("r", 200.0))
		var center: Vector2 = hero.position if join else anc.get("pos", position)
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
	elif join:
		g = hero.position + Vector2(cos(slot) * 46, sin(slot) * 46 + 10)
	else:
		var ap: Vector2 = anc.get("pos", position)
		g = ap + Vector2(cos(slot) * 50, sin(slot) * 36)
	var d := g.distance_to(position)
	last_pos = position
	if d > reach:
		var to := g
		if tg == null and join and d > 120:
			to = b.path_for(self, "p", hero.position)
		var m := to - position
		var md := m.length()
		if md == 0.0:
			md = 1.0
		var sp := spd * (2.2 if join and tg == null and d > 160 else 1.0)
		position += m / md * minf(md, sp * dt)
		b.push_out(self)
	elif tg != null and cd <= 0:
		cd = def.cd
		b.hurt_enemy(tg, atk)
		b.add_fx({"k": "spark", "pos": tg.position + Vector2(0, -3), "t": 0.15, "a": (tg.position - position).angle(), "c": Color("a8c8f0")})
	# 붙은 황건에게 맞음
	if hit_cd <= 0:
		var hit := b.touching_enemy(position, r + 3)
		if hit != null:
			hp -= hit.touch * 0.6
			hit_cd = 0.6
	if hp <= 0:
		dead = true
		b.add_fx({"k": "burst", "pos": position, "t": 0.3, "r": 6.0, "c": Color("6a9ad8")})
		b.ally_down(self)


func _process(_dt: float) -> void:
	queue_redraw()


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
