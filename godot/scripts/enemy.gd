class_name Enemy
extends Unit
## 적(웹판 spawn · aimOf · enemyTick). 노리는 곳: 붙어 싸우는 아군 > 자리(post)·목표(본진)를 지키다 장수가 aggro 안에 오면 장수.

## 장각이 다음 공격을 쓰는 간격(초, D-192 — 처음 1.7)
const BOSS_GAP := 1.2
## 공격 예고(초, D-194): 이만큼 전에 다음 공격을 정하고 빨간 테두리로 알림. 돌진이면 그때 방향을 정해 갈 길을 보여 줌
## (전엔 0.1초 전 테두리뿐이고 돌진 방향은 공격 순간에 정해서 사람이 피할 틈이 없었음)
const BOSS_WARN := 0.5

var k := ""
var def: Dictionary
var ai := "chase"
## ai를 숫자로(매 프레임 문자열 match가 정수 비교보다 10배쯤 느려서, D-200). 없으면 -1
const AI_CODE := {"chase": 0, "dash": 1, "shooter": 2, "boss": 3, "tower": 4}
const AI_CHASE := 0
const AI_DASH := 1
const AI_SHOOTER := 2
const AI_BOSS := 3
const AI_TOWER := 4
var _ai := AI_CHASE
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
## 막사 보호(D-202): 진영 수비탑이 하나라도 남아 있으면 피해를 받지 않고 아무도 겨누지 않음
var shield := false
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
## 장각이 예고 중인 다음 공격(-1 = 아직). 0 탄막 · 1 세 갈래 연사 · 2 무리 부르기 · 3 돌진
var next_kind := -1
var _moving := false
var _anim_off := 0.0
## 이름 첫 글자(그림이 없을 때 동그라미 위에) · 마지막으로 그린 상태(그릴 것이 바뀌었는지 보려고, D-201)
var _glyph := ""
var _dk_face := ""
var _dk_step := -1
var _dk_lift := -1.0
var _dk_warn := false
var _dk_flash := false
var _dk_hp := -1.0
var _dk_shield := false
## 수비탑이 장수를 노리는 중(사거리 안 · 화면 안, D-202)
var _aiming := false


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
	_ai = AI_CODE.get(ai, -1)
	t = randf_range(0, 1.5)
	eng_t = randf() * 0.3
	tint = Color(def.c)
	tex = Sprites.sheet(def.spr) if String(def.spr) != "" else null
	_anim_off = r
	_glyph = String(def.n).left(1)
	building = ai == "building" or ai == "tower"


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
		if _ai == AI_TOWER:
			_tower_tick(dt)
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
	# 매 프레임 적마다 도는 곳이라 위치 · 장수 위치는 한 번만 읽고, Battle 함수(path_for · push_out)는 빠른 길을 여기서 먼저 봄
	# (D-200 — 함수 부르기 · 속성 읽기가 비쌈. 검사 차례 · 계산은 그대로라 결과는 같음)
	var p := position
	var hp := hero.position
	# 노리는 곳
	var aim := hp
	var key := "p"
	var at_hero := true
	if engage != null and Unit.alive(engage) and engage.position.distance_to(p) < 100:
		aim = engage.position
		key = ""
		at_hero = false
	elif (has_post or goal_home) and hp.distance_to(p) > aggro:
		at_hero = false
		if goal_home:
			aim = b.home_pos
			key = "h"
		else:
			aim = post
			key = ""
	# 길찾기: Battle.path_for와 같은 차례 — 곧장 갈 때 · 지난 경로가 아직 살아 있을 때는 부르지 않음
	var pm := aim
	if _ai != AI_BOSS and key != "" and p.distance_to(aim) >= 40:
		if pth_t > b.t and pth_k == key:
			if has_pth:
				pm = pth
		else:
			pm = b.path_for(self, key, aim)
	var dv := pm - p
	var d := dv.length()
	if d == 0.0:
		d = 1.0
	t += dt
	flash = maxf(0.0, flash - dt)
	slow_t = maxf(0.0, slow_t - dt)
	spd = spd0 * (0.55 if slow_t > 0 else 1.0)
	var idle := false
	if _ai == AI_CHASE:
		# 자리를 지키는 중 제자리에 왔으면 섬(웹판은 제자리에서 떨렸음)
		if not at_hero and key == "" and (engage == null or not Unit.alive(engage)) and aim.distance_to(p) < 4.0:
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
			last_pos = p
			p += v * spd * dt
			position = p
	elif _ai == AI_DASH:
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
		p = position
	elif _ai == AI_SHOOTER:
		var want := 1.0 if d > 150 else (-1.0 if d < 110 else 0.0)
		position += dv / d * spd * want * dt
		if t > (1.8 if elite else 3.0):
			t = 0
			if b.in_view(position, -10) and at_hero:
				b.shoot(position, dv / d * 170, 6, 5, Color("d8b040"))
		p = position
	elif _ai == AI_BOSS:
		_boss_tick(dt, dv, d)
		p = position
	if _ai != AI_BOSS:
		# 벽 · 물 밀어내기: Battle.push_out과 같음 — 벽 · 물 띠에 걸칠 때만 부르고, 아니면 지도 안 가두기만
		var bands := b.obs_bands
		var near := false
		var i := 0
		while i < bands.size():
			if p.y + r >= bands[i] and p.y - r <= bands[i + 1]:
				near = true
				break
			i += 2
		if near:
			b.push_out(self)
			p = position
		else:
			var q := p.clamp(Vector2(r + 4, r + 4), Vector2(Battle.W - r - 4, Battle.H - r - 4))
			if q != p:
				position = q
				p = q
	if _ai == AI_CHASE and not idle:
		var mv := p.distance_to(last_pos)
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
	# 닿으면 장수가 다침. 장수급에게 맞으면 밀려남(장수는 이 적의 차례 안에서 여기 전엔 움직이지 않음)
	if p.distance_to(hp) < r + hero.r:
		var iv0 := hero.inv
		hero.hurt(touch)
		if is_lead() and hero.inv > iv0:
			# 34px 밀려남. 한 번에 밀면 12px 벽을 뚫고 닫힌 본진 안으로 들어가서(웹판도 같음) 네 번에 나눠 벽 검사
			var kd := (hero.position - position).normalized() if hero.position != position else Vector2(0, 1)
			for _i in 4:
				hero.position += kd * 8.5
				b.push_out(hero)
			b.add_fx({"k": "ring", "pos": hero.position, "t": 0.25, "r": 20.0, "c": Color("d9705e")})


## 수비탑(D-202): 장수가 사거리 안이고 탑이 화면에 보이면 gap초마다 화살 한 발(피할 수 있는 탄 — 장수만 맞음).
## 그렇지 않으면 쏠 준비만 해 두어, 들어오면 경고(warn초 — 빨간 고리) 뒤 첫 발
func _tower_tick(dt: float) -> void:
	var b := battle
	var T: Dictionary = Stage1.TOWER
	var gap: float = T.gap
	var hp_pos := b.hero.position
	_aiming = position.distance_to(hp_pos) <= float(T.range) and b.in_view(position, -10)
	if not _aiming:
		t = minf(t + dt, gap - float(T.warn))
		return
	t += dt
	if t >= gap:
		t = 0.0
		var at := position + Vector2(0, -34)
		b.shoot(at, (hp_pos - at).normalized() * float(T.spd), float(T.dmg), 5, Color("e07040"))


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
	if st != 4 and next_kind < 0 and t > BOSS_GAP - BOSS_WARN:
		phase = (phase + 1) % 4
		next_kind = phase if hp < max_hp * 0.5 else phase % 3
		if next_kind == 3:
			tdir = dv / d
	if st != 4 and t > BOSS_GAP:
		t = 0
		var kind := next_kind
		next_kind = -1
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
			b.banner("장각이 누런 바람을 타고 달려들어요!", "")


## 화면 근처에서 매 프레임(Battle._redraw_units): 걷는 방향을 고치고, 그릴 것이 지난번에 그린 것과 다를 때만 다시 그림(D-201).
## 위치는 노드 위치라 다시 그리지 않아도 따라가고, 그림이 바뀌는 건 걷는 방향 · 걸음(초당 6칸) · 번쩍임 · 띄워짐 ·
## 경고 · 체력뿐 — 전엔 매 프레임 다시 그렸음. 장수급 · 장각은 둘레 빛이 매 프레임 일렁여서 늘 그림.
## (Unit.anim_moved · Sprites.dir_of · walk_step과 같은 계산을 함수 부르기 없이 함)
func refresh_look() -> void:
	if building:
		# 수비탑은 사거리 원 · 경고 고리가 있어 늘 그림(진영마다 2개뿐)
		if _ai == AI_TOWER or (flash > 0) != _dk_flash or hp / max_hp != _dk_hp or shield != _dk_shield:
			queue_redraw()
		return
	var p := position
	if _anim_last == Vector2.INF:
		_anim_last = p
	var moved := p - _anim_last
	_anim_last = p
	_moving = moved.length() > 0.2
	if _moving:
		if absf(moved.x) > absf(moved.y):
			face_dir = "right" if moved.x > 0 else "left"
		else:
			face_dir = "up" if moved.y < 0 else "down"
	if boss or elite:
		queue_redraw()
		return
	var step := int(floor((battle.t + _anim_off) * 6)) % 4 if _moving else 0
	var lift := 0.0
	if air > 0 and air0 > 0:
		lift = sin(minf(1.0, (air0 - air) / air0) * PI) * 22
	var warn := (_ai == AI_DASH and st == 1) or (_ai == AI_SHOOTER and t > 1.4)
	if face_dir != _dk_face or step != _dk_step or lift != _dk_lift or warn != _dk_warn \
			or (flash > 0) != _dk_flash or hp / max_hp != _dk_hp:
		queue_redraw()


## 다시 그리기는 refresh_look(화면 근처 · 바뀌었을 때)이 부름. 그린 상태를 적어 둠
func _draw() -> void:
	var b := battle
	if b == null:
		return
	# 처음 그릴 때 걷기 기준 위치를 잡음(전엔 여기서 anim_moved가 했음)
	if _anim_last == Vector2.INF:
		_anim_last = position
	_dk_flash = flash > 0
	_dk_hp = hp / max_hp
	_dk_shield = shield
	if building:
		if _ai == AI_TOWER:
			_draw_tower()
		else:
			_draw_barracks()
		return
	var lift := 0.0
	if air > 0 and air0 > 0:
		lift = sin(minf(1.0, (air0 - air) / air0) * PI) * 22
	if boss:
		draw_circle(Vector2.ZERO, r + 10 + sin(b.t * 4) * 3, Color(0.89, 0.72, 0.35, 0.25))
		if st == 4 or next_kind >= 0:
			# 예고: 공격이 가까울수록 테두리가 굵고 진해짐. 돌진이면 갈 길(0.7초 × 260)을 미리 그림
			var k := 1.0 if st == 4 else clampf(1.0 - (BOSS_GAP - t) / BOSS_WARN, 0.0, 1.0)
			draw_oval(Vector2.ZERO, r * 1.35, r * 1.2, Color(0.85, 0.44, 0.37, 0.5 + 0.5 * k), false, 2 + 3 * k)
			if next_kind == 3 or st == 4:
				var tip := tdir * 182
				draw_line(Vector2.ZERO, tip, Color(0.85, 0.3, 0.25, 0.25 + 0.35 * k), r * 1.6)
				draw_line(tip, tip - tdir.rotated(0.5) * 18, Color(0.9, 0.3, 0.25, 0.8), 3)
				draw_line(tip, tip - tdir.rotated(-0.5) * 18, Color(0.9, 0.3, 0.25, 0.8), 3)
	var warn := (_ai == AI_DASH and st == 1) or (_ai == AI_SHOOTER and t > 1.4)
	if warn:
		draw_arc(Vector2.ZERO, r + 4, 0, TAU, 24, Color("d9705e"), 1.5)
	var size := r * (2.6 if boss else 2.5)
	var step := Sprites.walk_step(_moving, b.t + _anim_off, 6)
	draw_body(face_dir, step, size, 1.0, lift, _glyph)
	if elite:
		draw_arc(Vector2.ZERO, r + 6, 0, TAU, 32, Color(0.89, 0.72, 0.35, 0.6 + 0.3 * sin(b.t * 6)), 2.5)
	if hp < max_hp and not boss:
		draw_bar(0, -r - 7 - lift, r * 2, 3, hp / max_hp, Color("d9705e"))
	_dk_face = face_dir
	_dk_step = step
	_dk_lift = lift
	_dk_warn = warn


## 수비탑: 나무 망루 + 황건 깃발 + 체력 막대(맞으면 번쩍). 노리는 중엔 사거리 원, 쏘기 직전엔 망대에 빨간 고리
func _draw_tower() -> void:
	var T: Dictionary = Stage1.TOWER
	var wood := Color("fff2c0") if flash > 0 else Color("a8743a")
	var dark := Color("5a3a1a")
	if _aiming:
		draw_arc(Vector2.ZERO, float(T.range), 0, TAU, 72, Color(0.85, 0.35, 0.25, 0.3), 1.5)
	draw_rect(Rect2(-18, 10, 36, 6), Color(0, 0, 0, 0.22))
	draw_line(Vector2(-13, 12), Vector2(-9, -26), dark, 3)
	draw_line(Vector2(13, 12), Vector2(9, -26), dark, 3)
	draw_line(Vector2(-11, 2), Vector2(10, -16), dark, 2)
	draw_line(Vector2(11, 2), Vector2(-10, -16), dark, 2)
	draw_rect(Rect2(-15, -36, 30, 11), wood)
	draw_rect(Rect2(-15, -36, 30, 11), dark, false, 1.5)
	var roof := PackedVector2Array([Vector2(-18, -36), Vector2(18, -36), Vector2(0, -50)])
	draw_colored_polygon(roof, Color("d8b040"))
	roof.append(roof[0])
	draw_polyline(roof, dark, 1.5)
	draw_rect(Rect2(-1, -62, 2, 13), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -62), Vector2(12, -59), Vector2(1, -55)]), Color("e8c040"))
	if _aiming and t > float(T.gap) - float(T.warn):
		draw_arc(Vector2(0, -31), 13, 0, TAU, 24, Color("d9705e"), 2)
	draw_bar(0, -70, 40, 4, hp / max_hp, Color("d9705e"))


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
	if shield:
		# 수비탑이 남아 있는 동안: 푸른 보호막(D-202)
		draw_circle(Vector2(0, -6), 36, Color(0.55, 0.75, 0.95, 0.16))
		draw_arc(Vector2(0, -6), 36, 0, TAU, 40, Color(0.6, 0.8, 1.0, 0.7), 2)
