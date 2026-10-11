class_name Battle
extends Node2D
## 1장 전장(웹판 n_field.js 이식, D-170: 말 없이). 판의 상태 · 매 프레임 진행 · 목표 · 적·아군 생성 · 충돌.
## 아래(아군 본진)에서 위(장각 본진)로 진군: 황건 진영 3곳 점령 → 관문이 열림 → 정원지 → 장각.

signal finished(win: bool)

const W := Stage1.W
const H := Stage1.H
const GRID := 30.0
const STICK_DEAD := 8.0
const STICK_FULL := 50.0

@export var hero_data: HeroData

@export_group("출진 구성")
## 웹판 기본 유물 '도원의 맹약': 시작부터 진군 부대 수(보충 없음, D-180). 아군 강화는 '호령' 책략으로만.
## 장비(군막)를 옮기면 출진 구성에서 넘겨받는다.
@export var start_march := 4
## 진영을 점령할 때 한 번 나오는 진군 부대 수(보충 없음, D-180)
const MARCH_ON_CAPTURE := 4

@onready var world: Node2D = $World
@onready var ground: Node2D = $Ground
@onready var fx_layer: Node2D = $Fx
@onready var cam: Camera2D = $Camera
@onready var hud: Hud = $Hud

var t := 0.0
## play · pick(레벨업 책략 고르기 — 판이 멈춤) · end(이김) · dead(짐)
var state := "play"
var end_why := ""
var hit_stop := 0.0
var shake := 0.0
var kills := 0
## 공적 레벨(판 안) · 경험 · 밀린 레벨업 수. 책략은 tactics(D-172)
var lvl := 1
var xp := 0.0
var lvl_q := 0
var tactics: Tactics
var hero: Hero
var enemies: Array[Enemy] = []
var allies: Array[Ally] = []
## 적이 쏜 것 {pos, vel, dmg, r, c, life}
var shots: Array[Dictionary] = []
## 장수가 날린 기본 공격(D-171) {pos, dir, spd, travel, reach, hw, thick, bulge, dmg, pierce, push, hs, shake, hit, hits, c, c2}
var blades: Array[Dictionary] = []
## 그림 효과 {k, pos, t, …} — fx_layer.gd가 그림
var fx: Array[Dictionary] = []
## 주울 것(고기만두) {pos}
var drops: Array[Dictionary] = []
## 경험 구슬(D-183) {pos, v, pull} · 떨어진/주운 경험(봇 측정)
var orbs: Array[Dictionary] = []
var xp_dropped := 0.0
var xp_picked := 0.0
## 구슬이 빨려 오기 시작하는 거리(웹판 줍는 범위) · 자석이 떨어질 확률(처치 하나당) · 구슬 수 상한(넘으면 값을 합침)
const ORB_MAG := 64.0
const MAGNET_CHANCE := 0.004
const ORB_CAP := 400
## 막는 것 {rect, k: wall|water, tag: camp|keep|gate, door: ""|keep|gate}
var obs: Array[Dictionary] = []
## obs의 사각형만(충돌 검사용 — 매 프레임 수백 번 읽어서 따로 둠)
var obs_rects: Array[Rect2] = []
var obs_ver := 1
var flow := FlowField.new()
## 아군이 지키는 곳: id → {pos, r}
var anchors := {}
var home_pos: Vector2 = Stage1.HOME.pos
var home_r: float = Stage1.HOME.r
var home_hp: float = Stage1.HOME.hp
var home_max: float = Stage1.HOME.hp
var camps: Array[Dictionary] = []
var cap_n := 0
var cyz_on := false
var cyz_dead := false
var keep_open := false
var cyz: Enemy = null
var boss: Enemy = null
var party_t := 60.0
var rein_t := 4.0
## 들판 증원(D-186): 몇 초마다 · 장수를 쫓는 무리 상한 · 지금까지 낸 수(종류 섞기)
const REIN_GAP := 1.5
const REIN_CAP := 60
var rein_i := 0
## 포위 웨이브(D-182): 다음까지 남은 시간 · 몇 번째
var wave_t := 35.0
var wave_n := 0
## 웨이브 병력 체력 배율(웹판 에워싸는 무리 = 0.6)
var WAVE_HP := 0.6
var turret_t := 0.0
var home_t := 8.0
var lb_t := 0.0
var cyz_t := 4.0
var alert_home := false
## 지금 화면에 보이는 전장 범위
var view := Rect2(0, 0, 360, 640)
## 봇(테스트)이 넣는 이동. 0이면 사람 입력.
var bot_move := Vector2.ZERO
# 끌어서 이동(화면 어디든 누른 곳이 기준점)
var joy_on := false
var joy_id := -1
var joy_o := Vector2.ZERO
var joy_p := Vector2.ZERO

var _later: Array[Dictionary] = []
var _grid := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed(int(a.substr(7)))
		elif a.begins_with("--wave-hp="):
			WAVE_HP = float(a.substr(10))
	tactics = Tactics.new()
	tactics.name = "Tactics"
	add_child(tactics)
	tactics.setup(self)
	hero = Hero.new()
	hero.setup(self, hero_data, Stage1.START)
	world.add_child(hero)
	for c in Stage1.CAMPS:
		var d: Dictionary = c.duplicate()
		d.merge({"cap": false, "lead": null, "al_t": 0.0, "bks": []})
		camps.append(d)
	_build_obstacles()
	_setup_allies()
	_spawn_squads()
	for i in start_march:
		ally_spawn("sol", hero.position + Vector2(randf_range(-40, 40), randf_range(10, 40)), "march", "")
	_place_camera()
	hud.setup(self)
	Sound.music("fight", 0.3)
	banner(Stage1.NAME, "황건 진영 3곳의 막사를 부수고 진영장을 쓰러뜨리세요")
	if "--bot" in OS.get_cmdline_user_args():
		var bot: Node = load("res://scripts/bot.gd").new()
		add_child(bot)


# ─────────── 입력: 끌어서 이동 · 무쌍(스페이스) ───────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		# 무쌍 버튼은 몇 번째 손가락이든 받음(끌면서 다른 손가락으로 누름). 마우스는 터치로 바뀌어 여기로 옴
		if ev.pressed and hud.musou_hit(ev.position):
			hero.musou_go()
			get_viewport().set_input_as_handled()
		elif ev.pressed and not joy_on and state == "play" and not hud.blocks(ev.position):
			joy_on = true
			joy_id = ev.index
			joy_o = ev.position
			joy_p = ev.position
		elif not ev.pressed and ev.index == joy_id:
			joy_on = false
			joy_id = -1
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		if joy_on and ev.index == joy_id:
			joy_p = ev.position
	elif event is InputEventKey:
		var ev := event as InputEventKey
		if ev.pressed and not ev.echo and (ev.physical_keycode == KEY_SPACE or ev.physical_keycode == KEY_K):
			hero.musou_go()


func move_vec() -> Vector2:
	var v := Vector2.ZERO
	if joy_on:
		var d := joy_p - joy_o
		if d.length() > STICK_DEAD:
			v = d.normalized() * minf(1.0, d.length() / STICK_FULL)
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		v.x = -1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		v.x = 1
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		v.y = -1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		v.y = 1
	if bot_move != Vector2.ZERO:
		v = bot_move
	return v.normalized() if v.length() > 1.0 else v


# ─────────── 매 프레임 ───────────

func _process(delta: float) -> void:
	var dt := minf(delta, 0.033)  # 웹판과 같은 상한(프레임이 끊겨도 한 번에 0.033초까지만)
	if state == "play":
		_update(dt)
	_place_camera()
	ground.queue_redraw()
	fx_layer.queue_redraw()
	hud.refresh()


func _update(dt: float) -> void:
	if hit_stop > 0:
		hit_stop -= dt
		return
	t += dt
	_field_tick(dt)
	if state != "play":
		return
	hero.tick_timers(dt)
	shake = maxf(0.0, shake - dt)
	# 장수 이동
	var mv := move_vec()
	var moving := mv != Vector2.ZERO
	hero.last_pos = hero.position
	if moving:
		hero.position += mv * hero.spd * dt
		hero.face = mv.normalized()
		push_out(hero)
	hero.vel = (hero.position - hero.last_pos) / dt
	hero.still = 0.0 if moving else hero.still + dt
	for e in enemies:
		if not e.dead:
			e.tick(dt)
	# 장수가 쓰러졌으면(적에게 닿음) 이 프레임의 나머지(날아가던 참격 등)를 멈춤 — 안 그러면 진영장을 잡아 점령 회복이 들어갔음
	if state != "play":
		return
	_run_later()
	_tick_blades(dt)
	_tick_shots(dt)
	_sweep()
	var keep: Array[Dictionary] = []
	for f in fx:
		f.t -= dt
		if f.t > 0:
			keep.append(f)
	fx = keep


func _field_tick(dt: float) -> void:
	var p := hero
	var d := hero_data
	p.spd = 0.0 if p.stun > 0 else d.move_speed * tactics.speed_mul() * (d.musou_move_mul if p.musou_t > 0 else 1.0)
	# 공격: 무쌍 > 기본 공격(대표 무기가 날아감)
	if p.musou_t > 0:
		p.musou_tick(dt)
	elif p.stun <= 0:
		p.attack_tick(dt)
	# 아군 본진: 궁병이 가까운 적을 쏨 · 적이 붙으면 체력이 깎임
	turret_t -= dt
	if turret_t <= 0:
		turret_t = 0.7
		var tg := nearest_enemy(home_pos, home_r + 110)
		if tg != null:
			hurt_enemy(tg, 16)
			add_fx({"k": "shot", "pos": home_pos + Vector2(0, -20), "pos2": tg.position, "t": 0.15})
	var K := keep_rect()
	for e in enemies:
		if e.dead:
			continue
		if e.goal_home and not Unit.alive(e.engage) and e.position.distance_to(home_pos) < home_r + e.r:
			home_hp -= 1.2 * dt
		if e.boss:
			e.position = e.position.clamp(K.position + Vector2(e.r + 12, e.r + 12), K.end - Vector2(e.r + 12, e.r + 12))
	if home_hp <= home_max * 0.4 and not alert_home:
		alert_home = true
		banner("아군 본진이 밀려요!", "수비대가 버티기 어려워요 — 돌아가 도와요")
		Sound.play("alert", 0.5)
	if home_hp > home_max * 0.7:
		alert_home = false
	if home_hp <= 0:
		home_hp = 0
		finish(false, "home")
		return
	_camps_tick(dt)
	_party_tick(dt)
	_rein_tick(dt)
	_wave_tick(dt)
	_cyz_tick(dt)
	_separate()
	_ally_timers(dt)
	_engage_tick(dt)
	for a in allies:
		if not a.dead:
			a.tick(dt)
	tactics.tick(dt)
	_pickups()
	# 레벨업: 판을 멈추고 책략 3개 중 1개 고르기(밀린 만큼 한 번씩)
	if lvl_q > 0 and state == "play":
		lvl_q -= 1
		_open_pick()


func gain_xp(v: float) -> void:
	xp += v
	while xp >= TacticsData.xp_need(lvl):
		xp -= TacticsData.xp_need(lvl)
		lvl += 1
		lvl_q += 1


## 지금 고를 수 있는 책략(hud가 카드로 보여 줌)
var pick_opts: Array[Dictionary] = []


func _open_pick() -> void:
	pick_opts = tactics.options(3)
	Sound.play("accept", 0.35)
	state = "pick"
	joy_on = false
	hud.show_pick(pick_opts)


func choose(i: int) -> void:
	if state != "pick" or i < 0 or i >= pick_opts.size():
		return
	tactics.apply(pick_opts[i])
	pick_opts.clear()
	hud.hide_pick()
	state = "play"


## 진영(D-180): 병력은 살아 있는 막사에서만 나옴(막사마다 상한 · 장수가 가까우면 빨리) → 막사를 다 부수면 진영장 → 쓰러뜨리면 점령
func _camps_tick(dt: float) -> void:
	var B: Dictionary = Stage1.BARRACKS
	for c in camps:
		if c.cap:
			continue
		var left := 0
		for bk in c.bks:
			if not bk.alive:
				continue
			left += 1
			bk.spawn_t -= dt
			if bk.spawn_t > 0:
				continue
			var bp: Vector2 = bk.pos
			bk.spawn_t = float(B.gap_near) if hero.position.distance_to(bp) < float(B.near) else float(B.gap_far)
			if _count_barracks(bk.id) < int(B.cap) and enemies.size() < 240:
				_barracks_soldier(c, bk, float(c.mul) * (1.0 + minf(t, 600.0) / 600.0 * 0.25))
		if c.lead == null and left == 0:
			var lk: String = c.lk
			var at: Vector2 = c.pos + Vector2(0, -20)
			var L := spawn(lk, at, float(c.mul) * float(c.lm))
			L.elite = true
			L.ename = c.ln
			L.camp_lead = c.id
			L.set_post(at)
			L.aggro = 280
			L.touch = Units.ENEMY[lk].touch
			L.r *= 1.4 if lk == "ytbig" else 1.6
			c.lead = L
			banner("%s 등장!" % c.ln, "막사를 다 부쉈어요 — 쓰러뜨리면 진영 점령")
			Sound.play("alert", 0.35)


## 막사 옆에서 병력 하나(벽 · 물이면 막사 앞)
func _barracks_soldier(c: Dictionary, bk: Dictionary, mul: float) -> Enemy:
	var bp: Vector2 = bk.pos
	var at := bp + Vector2.from_angle(randf() * TAU) * randf_range(30, 50)
	if hit_obs(at, 12):
		at = bp + Vector2(randf_range(-20, 20), 34)
	var e := spawn("ytarch" if randf() < 0.2 else "ytb", at, mul)
	e.camp_id = c.id
	e.barracks_id = bk.id
	e.set_post(at)
	e.aggro = 220
	return e


func _count_barracks(id: String) -> int:
	var n := 0
	for e in enemies:
		if not e.dead and e.barracks_id == id and not e.building:
			n += 1
	return n


func barracks_left(c: Dictionary) -> int:
	var n := 0
	for bk in c.bks:
		if bk.alive:
			n += 1
	return n


## 황건 부대가 본진으로(45초마다, 살아 있는 막사 하나에서)
func _party_tick(dt: float) -> void:
	party_t -= dt
	if party_t > 0:
		return
	var src: Array = []
	for c in camps:
		if not c.cap:
			for bk in c.bks:
				if bk.alive:
					src.append([c, bk])
	if src.is_empty():
		return
	party_t = 45
	var pick: Array = src.pick_random()
	var c: Dictionary = pick[0]
	var bp: Vector2 = pick[1].pos
	for i in 8:
		var at := bp + Vector2(randf_range(-30, 30), 30 + randf_range(0, 20))
		if hit_obs(at, 12):
			at = bp + Vector2(0, 34)
		var e := spawn("ytdash" if i < 2 else "ytb", at, c.mul)
		e.goal_home = true
		e.aggro = 200
	banner("%s 막사에서 부대가 본진으로!" % c.n, "본진 체력을 지켜요")
	Sound.play("alert", 0.3)


## 들판 증원(D-186): 끊이지 않고 여러 방향에서 동시에 몰려옴(막사를 부수는 동안에도).
## REIN_GAP초마다 화면 바로 바깥 둘레를 방향 수만큼 고르게 나눈 곳(조금씩 흔듦)에서 나눠 나옴.
## 초당 5명 → 분당 +1.5(최대 14), 방향 3 → 2분 4 → 4분 5.
## 쉬는 건 장수를 쫓는 무리(자리 · 본진 목표가 없는 적)가 둘레 520px 안에 REIN_CAP 이상 · 적이 너무 많음 · 장각과 싸울 때뿐
## (전엔 3초마다 한 덩어리가 한 방향에서 왔고, 막사 옆에 서 있는 병력까지 '둘레 420px 안 40명'으로 세어 막사 앞에서 쉬었음).
func _rein_tick(dt: float) -> void:
	rein_t -= dt
	if rein_t > 0:
		return
	rein_t = REIN_GAP
	if boss != null or enemies.size() >= 300:
		return
	var chase := 0
	for e in enemies:
		if not e.dead and not e.has_post and not e.goal_home and not e.building and e.position.distance_to(hero.position) < 520:
			chase += 1
	if chase >= REIN_CAP:
		return
	var n := roundi(minf(14.0, 5.0 + t / 60.0 * 1.5) * REIN_GAP)
	var dirs := mini(5, 3 + int(t / 120.0))
	var m := mul_y(hero.position.y)
	var py := hero.position.y
	var off := randf() * TAU
	for d in dirs:
		var o := ring_pos(off + d * TAU / dirs + randf_range(-0.3, 0.3))
		if o == Vector2.INF:
			continue
		for j in n / dirs + (1 if d < n % dirs else 0):
			rein_i += 1
			var k := "ytb"
			if py < 1300 and rein_i % 6 == 5:
				k = "ytbig"
			elif py < 2300 and rein_i % 5 == 4:
				k = "ytarch"
			elif rein_i % 30 == 0:
				k = "ytdash"
			var at := Vector2(clampf(o.x + randf_range(-30, 30), 30, W - 30), clampf(o.y + randf_range(-30, 30), 30, H - 30))
			spawn(k, at, m)


## 포위 웨이브(D-182): 30~40초마다 장수 둘레 300px 원 위 사방에서 조여 옴(웹판 '에워싸는 무리'와 같은 수 · 체력 60%).
## 수 16 + 분당 5(최대 48) · 빠르기 +35%까지(10분) · 웨이브를 거듭할수록 돌격병 · 역사가 섞임.
## 벽 안 · 장수에게 걸어올 수 없는 자리는 뺌. 장각과 싸울 때는 쉼.
func _wave_tick(dt: float) -> void:
	wave_t -= dt
	if wave_t > 0:
		return
	wave_t = randf_range(30, 40)
	if boss != null or enemies.size() >= 300:
		return
	wave_n += 1
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var d: PackedInt32Array = flow.field("p", hero.position, t, 0.2).d
	var n := mini(48, 16 + int(t / 60.0 * 5.0))
	var R := 300.0
	var m := mul_y(hero.position.y) * WAVE_HP
	var sp := 1.0 + minf(t, 600.0) / 600.0 * 0.35
	var off := randf() * TAU
	var made := 0
	for i in n:
		var at := hero.position + Vector2.from_angle(off + float(i) / n * TAU) * R
		at = Vector2(clampf(at.x, 24, W - 24), clampf(at.y, 24, H - 24))
		if hit_obs(at, 14) or d[flow.cell_of(at)] < 0:
			continue
		var k := "ytb"
		if wave_n >= 2 and i % 6 == 3:
			k = "ytdash"
		elif wave_n >= 3 and i % 8 == 7:
			k = "ytbig"
		var e := spawn(k, at, m)
		e.spd0 *= sp
		e.spd = e.spd0
		made += 1
	if made > 0:
		banner("황건 무리가 에워싸요!", "사방에서 %d명이 조여 와요" % made)
		Sound.play("alert", 0.45)


## 관문이 열린 뒤: 정원지 쪽으로 6초마다 황건 무리
func _cyz_tick(dt: float) -> void:
	if not cyz_on or cyz_dead:
		return
	cyz_t -= dt
	if cyz_t > 0:
		return
	cyz_t = 6
	if enemies.size() >= 260:
		return
	for i in 10:
		var k := "ytbig" if i % 5 == 0 else ("ytarch" if i % 4 == 1 else "ytb")
		spawn(k, Vector2(randf_range(80, W - 80), randf_range(470, 520)), 1.3 * (1.0 + minf(t, 600.0) / 600.0 * 0.25))


## 겹치지 않게(30px 칸으로 나눠 이웃끼리만 밀어냄)
func _separate() -> void:
	_grid.clear()
	for e in enemies:
		if e.dead:
			continue
		var key := int(e.position.x / GRID) * 4096 + int(e.position.y / GRID)
		if _grid.has(key):
			_grid[key].append(e)
		else:
			_grid[key] = [e]
	for e in enemies:
		if e.dead or e.boss or e.building or e.air > 0:
			continue
		var cx := int(e.position.x / GRID)
		var cy := int(e.position.y / GRID)
		for i in range(-1, 2):
			for j in range(-1, 2):
				var l = _grid.get((cx + i) * 4096 + cy + j)
				if l == null:
					continue
				for o in l:
					if o == e:
						continue
					var dv: Vector2 = e.position - o.position
					var dd := dv.length()
					var m: float = (e.r + o.r) * 0.85
					if dd > 0.01 and dd < m:
						e.position += dv * ((m - dd) * 0.25 / dd)


## 아군에게 붙은 적(맞히는 쪽). _separate가 만든 칸을 씀.
func touching_enemy(at: Vector2, extra: float) -> Enemy:
	var cx := int(at.x / GRID)
	var cy := int(at.y / GRID)
	for i in range(-1, 2):
		for j in range(-1, 2):
			var l = _grid.get((cx + i) * 4096 + cy + j)
			if l == null:
				continue
			for e in l:
				if not e.dead and not e.building and e.air <= 0 and e.position.distance_to(at) < e.r + extra:
					return e
	return null


# ─────────── 아군 ───────────

## 본진: 유비 + 창병 6명(7초마다 보충). 점령한 진영: 수비대 창병 4명(18초마다 보충) + 진군 부대 4명이 한 번(보충 없음, D-180)
func _setup_allies() -> void:
	anchors["home"] = {"pos": home_pos + Vector2(0, -50), "r": 230.0}
	ally_spawn("liubei", home_pos + Vector2(0, -40), "guard", "home")
	for i in 6:
		ally_spawn("sol", home_pos + Vector2(randf_range(-60, 60), -30 + randf_range(-20, 20)), "guard", "home")


func ally_spawn(k: String, at: Vector2, mode: String, anchor_id: String) -> Ally:
	var a := Ally.new()
	a.setup(self, k, at, mode, anchor_id)
	world.add_child(a)
	allies.append(a)
	add_fx({"k": "ring", "pos": at, "t": 0.35, "r": 16.0, "c": Color("6a9ad8")})
	return a


func ally_down(a: Ally) -> void:
	if a.k == "liubei":
		lb_t = 15
		banner("유비가 물러났어요", "15초 뒤 본진으로 돌아와요")


func _count_allies(anchor_id: String, k := "") -> int:
	var n := 0
	for a in allies:
		if not a.dead and a.anchor == anchor_id and (k == "" or a.k == k):
			n += 1
	return n


func _ally_timers(dt: float) -> void:
	home_t -= dt
	if home_t <= 0:
		home_t = 7
		if _count_allies("home", "sol") < 6:
			ally_spawn("sol", home_pos + Vector2(randf_range(-40, 40), 0), "guard", "home")
	if lb_t > 0:
		lb_t -= dt
		if lb_t <= 0:
			ally_spawn("liubei", home_pos + Vector2(0, -30), "guard", "home")
			banner("유비가 본진으로 돌아왔어요", "")
	for c in camps:
		if not c.cap:
			continue
		c.al_t -= dt
		if c.al_t > 0:
			continue
		c.al_t = 18
		var gate := Vector2(camp_rect(c).get_center().x, camp_rect(c).end.y + 24)
		var aid: String = "camp_" + c.id
		if _count_allies(aid) < 4:
			ally_spawn("sol", gate + Vector2(randf_range(-20, 20), 0), "guard", aid)


## 황건이 아군과 붙으면 아군과 싸움(장수보다 가까울 때)
func _engage_tick(dt: float) -> void:
	for e in enemies:
		if e.dead or e.boss or e.building or e.no_eng:
			continue
		e.eng_t -= dt
		if e.eng_t > 0:
			continue
		e.eng_t = 0.3
		var best: Ally = null
		var bd := 70.0
		for a in allies:
			if a.dead:
				continue
			var dd := a.position.distance_to(e.position)
			if dd < bd:
				bd = dd
				best = a
		e.engage = best if best != null and bd < hero.position.distance_to(e.position) else null


# ─────────── 싸움 ───────────

func nearest_enemy(from: Vector2, max_d: float) -> Enemy:
	var best: Enemy = null
	var bd := max_d
	for e in enemies:
		if e.dead:
			continue
		var d := e.position.distance_to(from)
		if d < bd:
			bd = d
			best = e
	return best


## 기본 공격 하나를 날림. size = 연격 단계 크기 배율, col = 연격 단계 색 [날, 테두리]
func launch_blade(from: Vector2, a: float, A: BasicAttack, dmg: float, size: float, col: Array) -> void:
	blades.append({"pos": from, "dir": Vector2.from_angle(a), "spd": A.speed, "travel": 0.0, "reach": A.reach,
		"hw": A.width * size / 2, "thick": A.thickness * size, "bulge": A.bulge * size, "dmg": dmg, "pierce": A.pierce,
		"push": A.push, "hs": A.hit_stop, "shake": A.shake, "hit": {}, "hits": 0, "c": col[0], "c2": col[1]})


## 날아가는 기본 공격: 반달 모양(가운데 두껍고 끝이 뾰족함)에 닿은 적을 꿰뚫으며 벰. 적마다 한 번씩.
## 벽(물 말고)에 닿으면 사라짐(웹판 언월파와 같음). 장수급은 특성(lead_bonus)만큼 더 아프고 안 밀림.
func _tick_blades(dt: float) -> void:
	if blades.is_empty():
		return
	var keep: Array[Dictionary] = []
	for bl in blades:
		var dir: Vector2 = bl.dir
		var step: float = bl.spd * dt
		var p: Vector2 = bl.pos + dir * step
		bl.pos = p
		bl.travel += step
		if bl.travel > bl.reach:
			continue
		if in_wall(p, 2):
			add_fx({"k": "puff", "pos": p, "t": 0.2})
			continue
		var side := dir.orthogonal()
		var hw: float = bl.hw
		var n := 0
		var i := 0
		while i < enemies.size():
			var e := enemies[i]
			i += 1
			if e.dead or bl.hit.has(e.get_instance_id()):
				continue
			var d := e.position - p
			var ly := d.dot(side)
			if absf(ly) > hw + e.r:
				continue
			var tt := clampf(ly / hw, -1.0, 1.0)
			var s := 1.0 - tt * tt
			var lx := d.dot(dir)
			if lx > float(bl.bulge) * s + e.r or lx < (float(bl.bulge) - float(bl.thick)) * s - e.r - step:
				continue
			bl.hit[e.get_instance_id()] = true
			var lead := e.is_lead()
			hurt_enemy(e, float(bl.dmg) * (1.0 + hero_data.lead_bonus if lead else 1.0))
			n += 1
			if n <= 6:
				add_fx({"k": "spark", "pos": e.position + Vector2(0, -4), "t": 0.18, "a": dir.angle(), "c": bl.c})
			if not e.dead and not e.immovable() and bl.push > 0:
				e.position += dir * float(bl.push)
			if bl.pierce > 0:
				bl.pierce -= 1
				if bl.pierce == 0:
					break
		if n > 0:
			hero.cb_add(n, 0.6)
			if bl.hits == 0:
				hit_stop = maxf(hit_stop, bl.hs)
				shake = maxf(shake, bl.shake)
				Sound.play("hit", 0.18)
			bl.hits += n
		if bl.pierce == 0:
			continue
		keep.append(bl)
	blades = keep


## 한 번 휘두르기(무쌍의 회전 베기): 각 안의 적을 모두 벰. launch = 띄움, push = 밀침(장수급은 안 밀림). 맞힌 수를 돌려줌.
func swing(at: Vector2, a: float, arc: float, rad: float, dmg: float, col: Array, launch: bool, push: float) -> int:
	var n := 0
	var sparks := 0
	var i := 0
	while i < enemies.size():
		var e := enemies[i]
		i += 1
		if e.dead:
			continue
		var dv := e.position - at
		var d := dv.length()
		if d > rad + e.r:
			continue
		if arc < 6 and absf(angle_difference(a, dv.angle())) > arc / 2:
			continue
		var lead := e.immovable()
		hurt_enemy(e, dmg)
		n += 1
		if sparks < 6:
			sparks += 1
			add_fx({"k": "spark", "pos": e.position + Vector2(0, -4), "t": 0.18, "a": dv.angle(), "c": col[0]})
		if not e.dead and not lead and d > 0.1:
			if launch:
				e.air = 0.42
				e.air0 = 0.42
				e.kv = dv / d * 170
			elif push > 0:
				e.position += dv / d * push
	add_fx({"k": "slash", "pos": at, "a": a, "arc": arc, "r": rad, "t": 0.2, "c": col[0], "c2": col[1]})
	return n


## 무쌍 마무리 폭발: 둘레를 크게 베고 띄움(장수급은 피해 60%)
func blast(at: Vector2, rad: float, dmg: float) -> int:
	var n := 0
	var i := 0
	while i < enemies.size():
		var e := enemies[i]
		i += 1
		if e.dead:
			continue
		var dv := e.position - at
		var d := dv.length()
		if d > rad + e.r:
			continue
		var lead := e.immovable()
		hurt_enemy(e, dmg * (0.6 if e.is_lead() else 1.0))
		n += 1
		if not e.dead and not lead and d > 0.1:
			e.air = 0.5
			e.air0 = 0.5
			e.kv = dv / d * 240
	return n


func push_away(at: Vector2, rad: float, amount: float) -> void:
	for e in enemies:
		if e.dead or e.immovable():
			continue
		var dv := e.position - at
		var d := dv.length()
		if d > 0.1 and d < rad:
			e.position += dv / d * amount


func hurt_enemy(e: Enemy, d: float) -> void:
	if e.dead:
		return
	e.hp -= d
	e.flash = 0.1
	if e.is_lead() or e.building:
		add_fx({"k": "num", "pos": e.position + Vector2(randf_range(-6, 6), -e.r), "t": 0.7, "v": str(roundi(d)), "c": Color("fff2c0")})
	if e.hp <= 0:
		e.dead = true
		kills += 1
		add_fx({"k": "burst", "pos": e.position, "t": 0.3, "r": e.r * 0.6, "c": Color("f6e2a0")})
		Sound.play("slam" if e.building else "kill", 0.45 if e.building else 0.12)
		_on_kill(e)


## 적이 쓰러지면: 진영 병력 · 진영장(점령) · 정원지(본진 문) · 장각(평정)
func _on_kill(e: Enemy) -> void:
	if not e.boss:
		drop_orb(e.position, TacticsData.xp_of(e.k, e.elite))
	if e.boss:
		for o in enemies:
			if not o.dead and o != e:
				o.dead = true
		later(1.4, finish.bind(true, ""))
		var bn: String = e.def.n
		banner("%s%s 쓰러뜨렸어요!" % [bn, eul(bn)], "황건적의 난을 평정했어요")
		hit_stop = 0.15
		shake = 0.5
		return
	if e.building:
		var c := camp_by_id(e.camp_id)
		for bk in c.bks:
			if bk.id == e.barracks_id:
				bk.alive = false
		var total: int = c.bks.size()
		var done := total - barracks_left(c)
		add_fx({"k": "ring", "pos": e.position, "t": 0.5, "r": 60.0, "c": Color("ffb050")})
		shake = maxf(shake, 0.15)
		if done < total:
			banner("막사를 부쉈어요 (%d/%d)" % [done, total], "%s — 남은 막사 %d" % [c.n, total - done])
		return
	if e.camp_lead != "":
		var c := camp_by_id(e.camp_lead)
		c.cap = true
		cap_n += 1
		for o in enemies:
			if not o.dead and o.camp_id == c.id:
				o.dead = true
				kills += 1
				add_fx({"k": "burst", "pos": o.position, "t": 0.3, "r": o.r * 0.6, "c": Color("f6e2a0")})
		hero.heal(hero.max_hp * 0.15)
		var R := camp_rect(c)
		anchors["camp_" + c.id] = {"pos": Vector2(R.get_center().x, R.end.y + 40), "r": 260.0}
		c.al_t = 0.0
		for i in MARCH_ON_CAPTURE:
			ally_spawn("sol", Vector2(R.get_center().x + randf_range(-24, 24), R.end.y + 30 + randf_range(0, 14)), "march", "")
		add_fx({"k": "ring", "pos": c.pos, "t": 0.6, "r": 150.0, "c": Color("4a7ab8")})
		Sound.play("win", 0.35)
		if cap_n >= 3:
			open_door("gate")
			cyz_on = true
			var Z: Dictionary = Stage1.CYZ
			cyz = spawn("cyz", Z.pos, Z.m)
			cyz.elite = true
			cyz.ename = "황건 장수 정원지"
			cyz.set_post(Z.pos)
			cyz.aggro = 300
			cyz.touch = 22
			for i in int(Z.guards):
				var at: Vector2 = Z.pos + Vector2(randf_range(-150, 150), randf_range(-60, 90))
				var g := spawn("ytbig" if i % 4 == 0 else "ytb", at, 1.3)
				g.set_post(at)
				g.aggro = 260
			banner("%s 점령! 관문이 열렸어요" % c.n, "관문 너머의 정원지를 쓰러뜨려요")
		else:
			banner("%s 점령! (%d/3)" % [c.n, cap_n], "수비대가 진영을 지키고, 진군 부대 %d명이 다음 진영으로 먼저 가요" % MARCH_ON_CAPTURE)
		return
	if e.k == "cyz" and e.elite:
		cyz_dead = true
		keep_open = true
		open_door("keep")
		var K := keep_rect()
		for dx in [-24, 24]:
			drops.append({"k": "bun", "pos": Vector2(K.get_center().x + dx, K.end.y + 40)})
		var B: Dictionary = Stage1.KEEP
		boss = spawn(B.boss, K.get_center() + Vector2(0, -40), B.bm)
		boss.boss = true
		boss.touch = 22
		banner("정원지 격파! 장각 본진의 문이 열렸어요", "문 앞 고기만두로 기운을 차리고 장각에게")
		Sound.play("alert", 0.5)
		return
	if e.elite:
		return
	var r := randf()
	if r < 0.006:
		drops.append({"k": "bun", "pos": e.position})
	elif r < 0.006 + MAGNET_CHANCE:
		drops.append({"k": "magnet", "pos": e.position})


func later(delay: float, fn: Callable) -> void:
	_later.append({"t": t + delay, "fn": fn})


func _run_later() -> void:
	if _later.is_empty():
		return
	var due: Array[Callable] = []
	var keep: Array[Dictionary] = []
	for l in _later:
		if t >= float(l.t):
			due.append(l.fn)
		else:
			keep.append(l)
	_later = keep
	for fn in due:
		fn.call()


## 장각의 세 갈래 연사 한 번
func boss_volley(e: Enemy) -> void:
	if not Unit.alive(e):
		return
	var a := (hero.position - e.position).angle()
	for s in [-0.2, 0.0, 0.2]:
		shoot(e.position, Vector2.from_angle(a + s) * 200, 10, 5, Color("d8b040"))


func shoot(at: Vector2, vel: Vector2, dmg: float, rad: float, col: Color) -> void:
	shots.append({"pos": at, "vel": vel, "dmg": dmg, "r": rad, "c": col, "life": 0.0})


func _tick_shots(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for s in shots:
		var p: Vector2 = s.pos + s.vel * dt
		s.pos = p
		s.life += dt
		if p.x < -10 or p.y < -10 or p.x > W + 10 or p.y > H + 10 or p.distance_to(hero.position) > 700:
			continue
		if in_wall(p, s.r * 0.5):
			add_fx({"k": "puff", "pos": p, "t": 0.2})
			continue
		if p.distance_to(hero.position) < s.r + hero.r - 2:
			hero.hurt(s.dmg)
			continue
		keep.append(s)
	shots = keep


## 쓰러진 것 치우기. 장수급(진영장 · 정원지 · 장각)은 다른 곳이 붙잡고 있어 숨기기만 한다.
func _sweep() -> void:
	var gone_e := false
	for e in enemies:
		if e.dead:
			gone_e = true
			break
	if gone_e:
		for a in allies:
			if a.tg != null and a.tg.dead:
				a.tg = null
		var keep: Array[Enemy] = []
		for e in enemies:
			if not e.dead:
				keep.append(e)
			elif e.is_lead():
				e.visible = false
				e.set_process(false)
			else:
				e.queue_free()
		enemies = keep
	var gone_a := false
	for a in allies:
		if a.dead:
			gone_a = true
			break
	if gone_a:
		for e in enemies:
			if e.engage != null and e.engage.dead:
				e.engage = null
		var keep: Array[Ally] = []
		for a in allies:
			if a.dead:
				a.queue_free()
			else:
				keep.append(a)
		allies = keep


func _pickups() -> void:
	_tick_orbs()
	if drops.is_empty():
		return
	var keep: Array[Dictionary] = []
	for dr in drops:
		if hero.position.distance_to(dr.pos) >= hero.r + 14:
			keep.append(dr)
		elif dr.get("k", "bun") == "magnet":
			# 자석: 화면 둘레(200px 여유)의 구슬을 모두 끌어옴
			var V := view.grow(200)
			var n := 0
			for o in orbs:
				if V.has_point(o.pos):
					o.pull = true
					n += 1
			banner("자석!", "구슬 %d개를 끌어와요" % n)
			Sound.play("accept", 0.4)
			add_fx({"k": "ring", "pos": hero.position, "t": 0.5, "r": 120.0, "c": Color("6ac0e0")})
		else:
			hero.heal(hero.max_hp * 0.3)
			Sound.play("heal", 0.35)
	drops = keep


## 경험 구슬(D-183): 처치한 자리에 떨어짐. 너무 많으면 아무 구슬에 값을 더함(웹판과 같음)
func drop_orb(at: Vector2, v: float) -> void:
	xp_dropped += v
	if orbs.size() >= ORB_CAP:
		orbs[randi() % orbs.size()].v += v
		return
	orbs.append({"pos": at + Vector2(randf_range(-4, 4), randf_range(-4, 4)), "v": v, "pull": false})


## 가까이(ORB_MAG) 가면 빨려 오고, 닿으면 경험
func _tick_orbs() -> void:
	if orbs.is_empty():
		return
	var dt := get_process_delta_time()
	var hp := hero.position
	var keep: Array[Dictionary] = []
	var k := minf(1.0, dt * 11.0)
	for o in orbs:
		var p: Vector2 = o.pos
		var d := p.distance_to(hp)
		if o.pull or d < ORB_MAG:
			o.pull = true
			p += (hp - p) * k
			o.pos = p
			d = p.distance_to(hp)
		if d < hero.r + 8:
			xp_picked += float(o.v)
			gain_xp(o.v)
		else:
			keep.append(o)
	orbs = keep


func finish(win: bool, why: String) -> void:
	if state != "play":
		return
	state = "end" if win else "dead"
	end_why = why
	joy_on = false
	Sound.music("")
	Sound.play("win" if win else "lose", 0.45)
	get_tree().create_timer(0.7).timeout.connect(hud.show_end)
	finished.emit(win)


# ─────────── 생성 ───────────

func spawn(k: String, at: Vector2, mul: float) -> Enemy:
	var e := Enemy.new()
	e.setup(self, k, at, mul)
	world.add_child(e)
	enemies.append(e)
	return e


## 시간이 갈수록 단단해지는 배율(장각이 부르는 무리)
func time_mul() -> float:
	return 0.48 * (1.0 + t / 220.0 + pow(t / 300.0, 2))


## 위(장각 쪽)로 갈수록 · 시간이 갈수록 단단해지는 배율(들판 증원)
func mul_y(y: float) -> float:
	return (0.75 + (1.0 - y / H) * 1.1) * (1.0 + minf(t, 600.0) / 600.0 * 0.4)


## 길목의 황건 부대(가까이 가면 덤빔) · 진영 병력
func _spawn_squads() -> void:
	for s in Stage1.SQUADS:
		var n := roundi(float(s[2]) * 1.5)
		var y: float = s[1]
		for i in n:
			var k := "ytb"
			if i == 0 and n >= 10:
				k = "ytdash"
			elif y < 2300 and i % 4 == 3:
				k = "ytarch"
			elif y < 1400 and i % 6 == 1:
				k = "ytbig"
			var at := Vector2(clampf(float(s[0]) + randf_range(-55, 55), 30, W - 30), y + randf_range(-45, 45))
			var e := spawn(k, at, s[3])
			e.set_post(at)
			e.aggro = 230
	var B: Dictionary = Stage1.BARRACKS
	for c in camps:
		var i := 0
		for bp in c.barracks:
			var bk := {"id": "%s:%d" % [c.id, i], "pos": bp, "alive": true, "spawn_t": randf_range(0.5, 2.0)}
			c.bks.append(bk)
			var hut := spawn("barracks", bp, float(B.hp) * float(c.mul))
			hut.camp_id = c.id
			hut.barracks_id = bk.id
			hut.r = float(B.r)
			for j in int(B.start):
				_barracks_soldier(c, bk, float(c.mul))
			i += 1


## 화면 바로 바깥 둘레에서 a 방향의 빈 곳(안 되면 조금씩 돌려 봄). 장수에게 걸어올 수 없는 곳(닫힌 장각 본진 안 · 닫힌 관문 너머)은 뺀다
## — 웹판은 거기에도 생겨 벽에 줄지어 붙어 있었음. 못 찾으면 Vector2.INF.
func ring_pos(a: float) -> Vector2:
	var p := hero.position
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var d: PackedInt32Array = flow.field("p", p, t, 0.2).d
	for da in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05]:
		var rr := view.size.length() / 2 + randf_range(20, 70)
		var at := Vector2(clampf(p.x + cos(a + da) * rr, 24, W - 24), clampf(p.y + sin(a + da) * rr, 24, H - 24))
		if not hit_obs(at, 16) and at.distance_to(p) > 200 and d[flow.cell_of(at)] >= 0:
			return at
	return Vector2.INF


# ─────────── 지도 · 벽 · 길찾기 ───────────

func camp_rect(c: Dictionary) -> Rect2:
	var s: Vector2 = c.size
	return Rect2(c.pos - s / 2, s)


func keep_rect() -> Rect2:
	var K: Dictionary = Stage1.KEEP
	return Rect2(K.pos - K.size / 2, K.size)


func camp_by_id(id: String) -> Dictionary:
	for c in camps:
		if c.id == id:
			return c
	return {}


## 울타리(벽 다섯 조각, 남쪽 가운데가 문). door가 있으면 닫힌 문 조각을 따로 둠
func _fence(R: Rect2, gate_w: float, tag: String, door: String) -> Array[Dictionary]:
	var x0 := R.position.x
	var y0 := R.position.y
	var w := R.size.x
	var h := R.size.y
	var th := 12.0
	var g0 := R.get_center().x - gate_w / 2
	var g1 := R.get_center().x + gate_w / 2
	var out: Array[Dictionary] = []
	for rc in [Rect2(x0, y0, w, th), Rect2(x0, y0, th, h), Rect2(x0 + w - th, y0, th, h), Rect2(x0, y0 + h - th, g0 - x0, th), Rect2(g1, y0 + h - th, x0 + w - g1, th)]:
		out.append({"rect": rc, "k": "wall", "tag": tag, "door": ""})
	if door != "":
		out.append({"rect": Rect2(g0, y0 + h - th, gate_w, th), "k": "wall", "tag": tag, "door": door})
	return out


func _build_obstacles() -> void:
	obs.clear()
	# 진영엔 울타리가 없음(D-185 — 담 뒤로 숨어 적을 피하기 쉬웠음). 담은 장각 본진 · 관문만
	obs.append_array(_fence(keep_rect(), Stage1.CAMP_GATE_W, "keep", "keep"))
	var R: Dictionary = Stage1.RIVER
	var x0 := 0.0
	for br in R.bridges:
		obs.append({"rect": Rect2(x0, R.y0, br.x - x0, R.y1 - R.y0), "k": "water", "tag": "", "door": ""})
		x0 = br.y
	obs.append({"rect": Rect2(x0, R.y0, W - x0, R.y1 - R.y0), "k": "water", "tag": "", "door": ""})
	var G: Dictionary = Stage1.GATE
	obs.append({"rect": Rect2(0, G.y - 10, G.x0, 20), "k": "wall", "tag": "gate", "door": ""})
	obs.append({"rect": Rect2(G.x1, G.y - 10, W - G.x1, 20), "k": "wall", "tag": "gate", "door": ""})
	obs.append({"rect": Rect2(G.x0, G.y - 10, G.x1 - G.x0, 20), "k": "wall", "tag": "gate", "door": "gate"})
	_obs_changed()


func open_door(door: String) -> void:
	var keep: Array[Dictionary] = []
	for o in obs:
		if o.door != door:
			keep.append(o)
	obs = keep
	_obs_changed()


func _obs_changed() -> void:
	obs_rects.clear()
	for o in obs:
		obs_rects.append(o.rect)
	obs_ver += 1


## 벽·물에서 밀어내고 지도 밖으로 못 나가게
func push_out(u: Unit) -> void:
	for rc in obs_rects:
		var p := u.position
		if p.x + u.r < rc.position.x or p.x - u.r > rc.end.x or p.y + u.r < rc.position.y or p.y - u.r > rc.end.y:
			continue
		var c := p.clamp(rc.position, rc.end)
		var dv := p - c
		var d := dv.length()
		if d < u.r:
			if d > 0.01:
				u.position = c + dv / d * u.r
			else:
				# 가운데가 벽 안: 가장 얕은 쪽으로 뺌(웹판은 늘 위로 빼서 벽을 뚫고 넘어가기도 했음)
				var outs := [p.x - rc.position.x, rc.end.x - p.x, p.y - rc.position.y, rc.end.y - p.y]
				var k := outs.find(outs.min())
				if k == 0:
					u.position.x = rc.position.x - u.r
				elif k == 1:
					u.position.x = rc.end.x + u.r
				elif k == 2:
					u.position.y = rc.position.y - u.r
				else:
					u.position.y = rc.end.y + u.r
	u.position = u.position.clamp(Vector2(u.r + 4, u.r + 4), Vector2(W - u.r - 4, H - u.r - 4))


## 벽(물 말고)만 탄을 막음
func in_wall(p: Vector2, rad: float) -> bool:
	for o in obs:
		var rc: Rect2 = o.rect
		if o.k == "wall" and rc.grow(rad).has_point(p):
			return true
	return false


func hit_obs(p: Vector2, rad: float) -> bool:
	for rc in obs_rects:
		if rc.grow(rad).has_point(p):
			return true
	return false


func inside_walls(p: Vector2) -> bool:
	return keep_rect().grow(-4).has_point(p)


func in_view(p: Vector2, pad: float) -> bool:
	return view.grow(pad).has_point(p)


## 길찾기: key = 'p'(장수) · 'h'(본진) · ''(곧장). 0.18~0.26초마다 다시 봄.
func path_for(u: Unit, key: String, aim: Vector2) -> Vector2:
	if key == "" or u.position.distance_to(aim) < 40:
		return aim
	if u.pth_t > t and u.pth_k == key:
		return u.pth if u.has_pth else aim
	u.pth_t = t + 0.18 + randf() * 0.08
	u.pth_k = key
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var f := flow.field(key, aim, t, 0.2 if key == "p" else 0.0)
	if flow.clear(u.position, aim):
		u.has_pth = false
		return aim
	var nxt = flow.descend(u.position, f)
	if nxt == null:
		u.has_pth = false
		return aim
	u.pth = nxt
	u.has_pth = true
	return u.pth


## 지금 가야 할 곳(화살표 · 작은 지도 · 목표 글)
func field_target() -> Dictionary:
	if home_hp < home_max * 0.4:
		for e in enemies:
			if not e.dead and e.goal_home and e.position.distance_to(home_pos) < 400:
				return {"pos": home_pos, "n": "본진 지키기 (본진 %d%%)" % ceili(home_hp / home_max * 100), "warn": true}
	var best := {}
	var bd := INF
	for c in camps:
		if c.cap:
			continue
		var d := hero.position.distance_to(c.pos)
		if d < bd:
			bd = d
			best = c
	if not best.is_empty():
		var total: int = best.bks.size()
		var done := total - barracks_left(best)
		if best.lead != null:
			var lp: Vector2 = best.lead.position if Unit.alive(best.lead) else best.pos
			return {"pos": lp, "n": "%s 격파 · 막사 %d/%d" % [best.ln, done, total]}
		var bp: Vector2 = best.pos
		var bd2 := INF
		for bk in best.bks:
			if bk.alive and hero.position.distance_to(bk.pos) < bd2:
				bd2 = hero.position.distance_to(bk.pos)
				bp = bk.pos
		return {"pos": bp, "n": "%s · 막사 %d/%d 부수기" % [best.n, done, total]}
	if not cyz_dead:
		var zp: Vector2 = cyz.position if Unit.alive(cyz) else Stage1.CYZ.pos
		return {"pos": zp, "n": "관문 너머 황건 장수 정원지 격파"}
	var bp: Vector2 = boss.position if Unit.alive(boss) else keep_rect().get_center()
	return {"pos": bp, "n": "장각 본진 — 천공장군 장각 격파"}


## 진군 부대(D-180)가 갈 곳과 길찾기 키
func march_goal(from: Vector2) -> Dictionary:
	for c in camps:
		if c.cap:
			continue
		if c.lead != null:
			return {"key": "m_lead_" + c.id, "pos": c.lead.position if Unit.alive(c.lead) else c.pos}
		var best := {}
		var bd := INF
		for bk in c.bks:
			if bk.alive and from.distance_to(bk.pos) < bd:
				bd = from.distance_to(bk.pos)
				best = bk
		if not best.is_empty():
			return {"key": "m_" + String(best.id), "pos": best.pos}
		return {"key": "m_camp_" + c.id, "pos": c.pos}
	if not cyz_dead:
		return {"key": "m_cyz", "pos": cyz.position if Unit.alive(cyz) else Stage1.CYZ.pos}
	return {"key": "m_boss", "pos": boss.position if Unit.alive(boss) else keep_rect().get_center()}


# ─────────── 화면 ───────────

func _place_camera() -> void:
	var vs := get_viewport_rect().size
	# 장수를 화면 위에서 60% 자리에(앞쪽이 더 보이게)
	var c := hero.position + Vector2(0, -vs.y * 0.1)
	c.x = clampf(c.x, vs.x / 2, W - vs.x / 2)
	c.y = clampf(c.y, vs.y / 2, H - vs.y / 2)
	view = Rect2(c - vs / 2, vs)
	var sh := shake * 18.0
	cam.position = c + (Vector2(randf_range(-sh, sh), randf_range(-sh, sh)) if sh > 0 else Vector2.ZERO)


## 받침 있는 글자 뒤엔 '을', 없으면 '를'
static func eul(s: String) -> String:
	var c := s.unicode_at(s.length() - 1) - 0xAC00
	return "을" if c >= 0 and c < 11172 and c % 28 != 0 else "를"


func add_fx(f: Dictionary) -> void:
	fx.append(f)


func banner(title: String, sub: String) -> void:
	hud.banner(title, sub)
