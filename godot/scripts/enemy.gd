class_name Enemy
extends Unit
## 적(웹판 spawn · aimOf · enemyTick). 노리는 곳: 붙어 싸우는 아군 > 자리(post)·목표(본진)를 지키다 장수가 aggro 안에 오면 장수.

var k := ""
var def: Dictionary
var ai := "chase"
var spd := 60.0
var spd0 := 60.0
var touch := 9.0
var t := 0.0
var st := 0
var phase := 0
var elite := false
var boss := false
var ename := ""
var camp_id := ""
## 떨어뜨리는 경험 배율(들판 증원은 Battle.REIN_XP, D-187)
var xp_mul := 1.0
## 막사(D-180): 움직이지 않는 적. barracks_id = "진영id:번호"
var building := false
var barracks_id := ""
var camp_lead := ""
var has_post := false
var post := Vector2.ZERO
var goal_home := false
var aggro := 260.0
## 아군과 싸우지 않음(본진으로 곧장).
var no_eng := false
var engage: Unit = null
var eng_t := 0.0
var slow_t := 0.0
## 회전 언월에 다시 맞을 때까지
var orb_t := 0.0
# 띄워짐
var air := 0.0
var air0 := 0.0
var kv := Vector2.ZERO
# 쫓다가 막히면 옆으로 미끄러짐
var stuck := 0.0
var slide := 0.0
var slide_t := 0.0
# 돌진
var tdir := Vector2.ZERO
var _moving := false
var _anim_off := 0.0


func setup(b: Battle, key: String, at: Vector2, mul: float) -> void:
	battle = b
	k = key
	def = Units.ENEMY[key]
	position = at
	last_pos = at
	r = def.r
	max_hp = float(def.hp) * mul
	hp = max_hp
	spd = def.spd
	spd0 = spd
	touch = float(def.touch) * (0.9 + 0.1 * mul)
	ai = def.ai
	t = randf_range(0, 1.5)
	eng_t = randf() * 0.3
	tint = Color(def.c)
	tex = Sprites.sheet(def.spr) if String(def.spr) != "" else null
	_anim_off = r
	building = ai == "building"


func set_post(p: Vector2) -> void:
	has_post = true
	post = p


func is_lead() -> bool:
	return elite or boss


## 밀리거나 띄워지지 않음(장수급 · 막사)
func immovable() -> bool:
	return elite or boss or building


func tick(dt: float) -> void:
	var b := battle
	var hero := b.hero
	orb_t -= dt
	if building:
		flash = maxf(0.0, flash - dt)
		return
	if air > 0:
		air -= dt
		position += kv * dt
		kv *= pow(0.93, dt * 60.0)
		flash = maxf(0.0, flash - dt)
		b.push_out(self)
		if air <= 0:
			b.add_fx({"k": "puff", "pos": position + Vector2(0, 6), "t": 0.2})
		return
	# 노리는 곳
	var aim := hero.position
	var key := "p"
	var at_hero := true
	if Unit.alive(engage) and engage.position.distance_to(position) < 100:
		aim = engage.position
		key = ""
		at_hero = false
	elif (has_post or goal_home) and hero.position.distance_to(position) > aggro:
		at_hero = false
		if goal_home:
			aim = b.home_pos
			key = "h"
		else:
			aim = post
			key = ""
	var pm := aim if ai == "boss" else b.path_for(self, key, aim)
	var dv := pm - position
	var d := dv.length()
	if d == 0.0:
		d = 1.0
	t += dt
	flash = maxf(0.0, flash - dt)
	slow_t = maxf(0.0, slow_t - dt)
	spd = spd0 * (0.55 if slow_t > 0 else 1.0)
	var idle := false
	match ai:
		"chase":
			# 자리를 지키는 중 제자리에 왔으면 섬(웹판은 제자리에서 떨렸음)
			if not at_hero and key == "" and not Unit.alive(engage) and aim.distance_to(position) < 4.0:
				idle = true
				stuck = 0.0
			else:
				var v := dv / d
				if stuck > 0.25 and slide_t <= 0:
					slide_t = 0.9
				if slide_t > 0:
					slide_t -= dt
					var s := slide if slide != 0.0 else 1.0
					v = Vector2(-v.y * s, v.x * s)
				last_pos = position
				position += v * spd * dt
		"dash":
			if st == 0:
				position.x += sin(t * 2) * 20 * dt
				if t > 1.6:
					st = 1
					t = 0
					tdir = dv / d
			elif st == 1:
				if t > 0.4:
					st = 2
					t = 0
			else:
				position += tdir * 300 * dt * (0.55 if slow_t > 0 else 1.0)
				if t > 0.35:
					st = 0
					t = 0
		"shooter":
			var want := 1.0 if d > 150 else (-1.0 if d < 110 else 0.0)
			position += dv / d * spd * want * dt
			if t > (1.8 if elite else 3.0):
				t = 0
				if b.in_view(position, -10) and at_hero:
					b.shoot(position, dv / d * 170, 6, 5, Color("d8b040"))
		"boss":
			_boss_tick(dt, dv, d)
	if ai != "boss":
		b.push_out(self)
	if ai == "chase" and not idle:
		var mv := position.distance_to(last_pos)
		if mv < spd * dt * 0.35:
			stuck += dt
			if slide == 0.0:
				slide = 1.0 if randf() < 0.5 else -1.0
			if stuck > 1.2:
				slide = -slide
				stuck = 0.3
		elif stuck > 0:
			stuck = maxf(0.0, stuck - dt * 0.5)
			if stuck < 0.05:
				slide = 0.0
	# 닿으면 장수가 다침. 장수급에게 맞으면 밀려남
	if position.distance_to(hero.position) < r + hero.r:
		var iv0 := hero.inv
		hero.hurt(touch)
		if is_lead() and hero.inv > iv0:
			# 34px 밀려남. 한 번에 밀면 12px 벽을 뚫고 닫힌 본진 안으로 들어가서(웹판도 같음) 네 번에 나눠 벽 검사
			var kd := (hero.position - position).normalized() if hero.position != position else Vector2(0, 1)
			for _i in 4:
				hero.position += kd * 8.5
				b.push_out(hero)
			b.add_fx({"k": "ring", "pos": hero.position, "t": 0.25, "r": 20.0, "c": Color("d9705e")})


## 장각: 거리를 두며 탄막 · 세 갈래 연사 · 무리 부르기 · 누런 바람 돌진(체력 절반 아래에선 넷 다)
func _boss_tick(dt: float, dv: Vector2, d: float) -> void:
	var b := battle
	if st == 4:
		position += tdir * 260 * dt
		position = position.clamp(Vector2(60, 60), Vector2(Stage1.W - 60, Stage1.H - 60))
		if t > 0.7:
			st = 0
			t = 0
	else:
		var want := 1.0 if d > 230 else (-0.6 if d < 150 else 0.0)
		position += dv / d * spd * 1.6 * want * dt
	if st != 4 and t > 1.7:
		t = 0
		phase = (phase + 1) % 4
		var kind := phase if hp < max_hp * 0.5 else phase % 3
		if kind == 0:
			var n := 18 if hp < max_hp * 0.5 else 14
			var off := randf()
			for i in n:
				var a := (i + off) / n * TAU
				b.shoot(position, Vector2.from_angle(a) * 135, 11, 6, Color("e8c060"))
			b.add_fx({"k": "ring", "pos": position, "t": 0.3, "r": 60.0, "c": Color("e8c060")})
		elif kind == 1:
			for i in 3:
				b.later(i * 0.26, b.boss_volley.bind(self))
		elif kind == 2:
			for i in 8:
				b.spawn("ytb", position + Vector2(randf_range(-60, 60), randf_range(20, 60)), b.time_mul())
			b.banner("장각이 황건 무리를 불러내요!", "")
		else:
			st = 4
			t = 0
			tdir = dv / d
			b.banner("장각이 누런 바람을 타고 달려들어요!", "")


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	var b := battle
	if b == null:
		return
	if building:
		_draw_barracks()
		return
	var moved := anim_moved()
	_moving = moved.length() > 0.2
	if _moving:
		face_dir = Sprites.dir_of(moved)
	var lift := 0.0
	if air > 0 and air0 > 0:
		lift = sin(minf(1.0, (air0 - air) / air0) * PI) * 22
	if boss:
		draw_circle(Vector2.ZERO, r + 10 + sin(b.t * 4) * 3, Color(0.89, 0.72, 0.35, 0.25))
		if st == 4 or t > 1.6:
			draw_oval(Vector2.ZERO, r * 1.35, r * 1.2, Color("d9705e"), false, 2)
	var warn := (ai == "dash" and st == 1) or (ai == "shooter" and t > 1.4)
	if warn:
		draw_arc(Vector2.ZERO, r + 4, 0, TAU, 24, Color("d9705e"), 1.5)
	var size := r * (2.6 if boss else 2.5)
	draw_body(face_dir, Sprites.walk_step(_moving, b.t + _anim_off, 6), size, 1.0, lift, String(def.n).left(1))
	if elite:
		draw_arc(Vector2.ZERO, r + 6, 0, TAU, 32, Color(0.89, 0.72, 0.35, 0.6 + 0.3 * sin(b.t * 6)), 2.5)
	if hp < max_hp and not boss:
		draw_bar(0, -r - 7 - lift, r * 2, 3, hp / max_hp, Color("d9705e"))


## 막사: 누런 천막 + 황건 깃발 + 체력 막대(맞으면 번쩍)
func _draw_barracks() -> void:
	var cl := Color("fff2c0") if flash > 0 else Color("d8b860")
	draw_rect(Rect2(-24, 10, 48, 6), Color(0, 0, 0, 0.22))
	var tri := PackedVector2Array([Vector2(0, -26), Vector2(26, 12), Vector2(-26, 12)])
	draw_colored_polygon(tri, cl)
	tri.append(tri[0])
	draw_polyline(tri, Color("6a4a1a"), 2.5)
	draw_line(Vector2(0, -26), Vector2(0, 12), Color(0.42, 0.29, 0.1, 0.6), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(8, 12), Vector2(-8, 12)]), Color("3a2a1a"))
	draw_rect(Rect2(14, -34, 2, 24), Color("5a3a1a"))
	draw_colored_polygon(PackedVector2Array([Vector2(16, -34), Vector2(30, -31), Vector2(16, -26)]), Color("e8c040"))
	draw_bar(0, -40, 46, 4, hp / max_hp, Color("d9705e"))
