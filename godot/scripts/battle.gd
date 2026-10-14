class_name Battle
extends Node2D
## 1장 전장(웹판 n_field.js 이식, D-170: 말 없이). 판의 상태 · 매 프레임 진행 · 목표 · 적·아군 생성 · 충돌.
## 1장 탁현 싸움(D-210 · D-211 · D-214): 황건 진영 3곳(수비탑 2개 → 진영장 격파 · 보급 상자)을 자유롭게 점령 → 곧바로 정원지의 대군
## (선봉 → 중군 → 정원지 본대)이 길을 따라 본진으로 진군 — 정원지(1장 최종 보스, 2단계)를 쓰러뜨리면 이기고 대군이 본진에 닿으면 짐.
## 사건 시간표(Stage1): 2:30 탁현 마을 습격 · 4:00 늑대 · 들개 · 5:00 본진 기습.
## 2 · 3장용(성문 열림 · 장각의 요술 · 요술 제단 · 장각 · 첫 사신수 해방)은 siege.gd(Siege)로 떼어 둠 — 1장에선 siege = null.

signal finished(win: bool)

const W := Stage1.W
const H := Stage1.H
const GRID := 30.0
const STICK_DEAD := 8.0
const STICK_FULL := 50.0
## 화면 밖 이만큼까지는 인물을 다시 그림(장각 그림 높이 ~90px · 띄워짐 · 화면 흔들림을 덮음)
const DRAW_PAD := 120.0
## 흐름장을 프레임마다 미리 넓혀 두는 칸 수(D-199, 이 PC에서 약 0.4ms). 지도는 42×150 = 6300칸.
## 1200 · 2500은 넓히는 프레임 자체가 1~2ms씩 늘고, 0이면 물어볼 때 한꺼번에 넓히는 일이 잦았음
const FLOW_WORK := 600

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
## tap(웹에서 첫 터치 전 '화면을 눌러 시작' — 판이 멈춤) · play · pick(레벨업 책략 고르기 — 판이 멈춤) · pause(일시정지, D-197) · end(이김) · dead(짐)
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
## obs_rects의 세로 범위를 겹치는 것끼리 합친 띠 [위, 아래, 위, 아래, …](push_out이 띠 근처에서만 사각형을 봄)
var obs_bands := PackedFloat64Array()
var obs_ver := 1
var flow := FlowField.new()
## 아군이 지키는 곳: id → {pos, r}
var anchors := {}
var home_pos: Vector2 = Stage1.HOME.pos
var home_r: float = Stage1.HOME.r
var home_hp: float = Stage1.HOME.hp
var home_max: float = Stage1.HOME.hp
## 진영: Stage1.CAMPS + {cap 점령함, lead 진영장, al_t 수비대 보충, tws 수비탑 {id, pos, alive}, call_t 다음 호위병까지}
var camps: Array[Dictionary] = []
var cap_n := 0
## 판의 사건 {t, n}(수비탑 · 점령 · 상자 · 관문 · 정원지 · 장각 — 봇이 사건마다 걸린 시간을 출력, D-205)
var events: Array[Dictionary] = []
var cyz_on := false
var cyz_dead := false
## 정원지 단계(1 · 2, D-211) · 1장을 이겨 끝나는 중(증원이 멈춤)
var cyz_phase := 1
var won := false
## 정원지의 대군(D-214): 첫 부대 출진 시각(-1 = 아직) · 진영 셋을 점령한 시각 ·
## 부대 {i, spawned, lead(부장), met_t · met_d(장수가 처음 만난 시각 · 그때 본진까지 거리), hunt_t(유비에게 돌격병까지), warned}
var army_t0 := -1.0
var cap3_t := -1.0
var army: Array[Dictionary] = []
var cyz: Enemy = null
## 장수가 정원지 곁(260px)에 있던 시간(봇 출력)
var cyz_eng := 0.0
## 장수가 받은 피해 출처별 합(봇 출력 — Hero.hurt의 src) · 마지막으로 받은 피해의 출처(사망 원인)
var hurt_log := {}
var last_hurt := ""
## 회복을 얻은 수 · 출처별(D-216 봇 출력): 물체 · 부장 · 처치 · 카드 · 마을
var heal_log := {}
## 보스 울타리(D-216 1단계): {} = 없음 / {st: warn · on, t: 예고 남은 초, lead: 부장 · 정원지, c: 중심, r, t0: 생긴 때, beat: 다음 북소리까지}
var arena := {}
## 끝난 울타리 기록(봇 출력): {n: 부대, ln: 이름, t0, t1, d: 중심에서 본진까지}
var arena_log: Array[Dictionary] = []
## 카메라가 울타리 중심을 보는 정도(0 = 장수 · 1 = 울타리 중심)
var cam_k := 0.0
## 몰려오는 무리(Stage1.SURGE): 다음까지 · 예고 중인 무리 {a: 장수에서 본 방향, t: 남은 예고 초, at: 나올 자리} · 지금까지 온 수(봇 출력)
var surge_t := 0.0
var surge_warn := {}
var surge_n := 0
## 감옥에서 풀려난 의용병 수 · 본진에 닿은 수(봇 출력)
var captive_freed := 0
var captive_safe := 0
## 장각(2 · 3장, Siege가 만듦 — 1장엔 없음)
var boss: Enemy = null
## 2 · 3장용 진행(D-211): 성문 열림 · 장각의 요술 · 요술 제단 · 장각 · 사신수. 1장(Stage1.SIEGE = false)엔 없음
var siege: Siege = null
## 탁현 마을(D-208): wait · raid(습격 중) · saved · lost · 남은 시간 · 등무 / 본진 기습을 했나 / 유비(쓰러지면 짐)
var vil_st := "wait"
var vil_t := 0.0
var deng: Enemy = null
## 마을 사건 시각(봇 출력용, D-215): 습격 시작 · 장수가 등무 곁(200px)에 처음 온 때 · 끝(구함 · 불탐) — -1 = 아직
var vil_t0 := -1.0
var vil_hero_t := -1.0
var vil_end_t := -1.0
## 스토리 동료(D-212 · D-215): 1장은 마을 습격 때 장비(Stage1.COMPANION)
var companion: Companion = null
## 동료가 한 일(봇 출력용): 이름 · 처치 · 목표에게 준 피해와 그 최대 체력 · 남은 체력 비율 · 물러난 때와 까닭("" = 아직 싸움)
var cmp_log := {}
var home_raided := false
var liubei: Ally = null
## 늑대 · 들개 무리가 나왔나(D-209) · 진행 중인 진영 id(수비탑을 처음 친 곳 — 점령할 때까지 목표, D-209)
var pack_done := false
var cur_camp := ""
var party_t := 60.0
var rein_t := 4.0
## 들판 증원(D-186): 몇 초마다 · 장수를 쫓는 무리 상한 · 떨어뜨리는 경험 배율(D-187 — 많이 오되 레벨은 천천히) · 지금까지 낸 수(종류 섞기)
const REIN_GAP := 1.5
const REIN_CAP := 60
const REIN_XP := 0.25
var rein_i := 0
## 포위 웨이브(D-182): 다음까지 남은 시간 · 몇 번째
var wave_t := 35.0
var wave_n := 0
## 웨이브 병력 체력 배율(웹판 에워싸는 무리 = 0.6)
var WAVE_HP := 0.6
var turret_t := 0.0
var home_t := 8.0
var alert_home := false
## 지금 화면에 보이는 전장 범위
var view := Rect2(0, 0, 360, 640)
## 봇(테스트)이 넣는 이동. 0이면 사람 입력.
var bot_move := Vector2.ZERO
## 봇이 돌리는 중(앱 포커스를 잃어도 자동으로 멈추지 않음)
var bot_on := false
# 끌어서 이동(화면 어디든 누른 곳이 기준점)
var joy_on := false
var joy_id := -1
var joy_o := Vector2.ZERO
var joy_p := Vector2.ZERO

var _later: Array[Dictionary] = []
## _separate가 만든 30px 칸(touching_enemy도 씀): 칸마다 첫 적 번호(_cell_head) → 같은 칸 다음 적 번호(_cell_next).
## 번호는 그때의 enemies(_cell_units) 차례. 칸 (cx, cy)의 자리 = (cx + _cell_ox) * _cell_gh + cy + _cell_oy(둘레 한 칸 여유).
var _cell_units: Array[Enemy] = []
var _cell_head := PackedInt32Array()
var _cell_next := PackedInt32Array()
var _cell_gw := 0
var _cell_gh := 0
var _cell_ox := 0
var _cell_oy := 0
## _separate가 적마다 읽어 둔 칸 · 위치 · 반지름 · 밀림(0 쓰러짐 · 1 칸에만 · 2 밀림)
var _sep_cx := PackedInt32Array()
var _sep_cy := PackedInt32Array()
var _sep_pos := PackedVector2Array()
var _sep_r := PackedFloat64Array()
var _sep_mv := PackedByteArray()


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
		d.merge({"cap": false, "lead": null, "al_t": 0.0, "tws": [], "call_t": 0.0, "burn_t": -1.0})
		camps.append(d)
	_build_obstacles()
	if Stage1.SIEGE:
		siege = Siege.new(self)
	_setup_allies()
	_spawn_squads()
	_spawn_props()
	_make_terrain()
	for i in start_march:
		ally_spawn("sol", hero.position + Vector2(randf_range(-40, 40), randf_range(10, 40)), "march", "")
	_place_camera()
	hud.setup(self)
	var args := OS.get_cmdline_user_args()
	if "--bot" in args:
		var bot: Node = load("res://scripts/bot.gd").new()
		add_child(bot)
	# 웹(iOS Safari 등)은 사용자가 화면을 누르기 전엔 소리를 낼 수 없어서, 첫 터치까지 '화면을 눌러 시작'으로 판을 멈춰 둠.
	# PC에서 확인할 땐 --tap-start
	if (OS.has_feature("web") or "--tap-start" in args) and not "--bot" in args:
		state = "tap"
		hud.show_tap()
	else:
		_start()


## 판 시작: 배경음 · 첫 알림(웹은 첫 터치 때 — 사용자 동작 안에서 소리를 켜야 브라우저가 허락함)
func _start() -> void:
	state = "play"
	hud.hide_tap()
	Sound.music("fight", 0.3)
	banner(Stage1.NAME, "황건 진영 3곳: 수비탑을 부숴야 진영장을 칠 수 있어요")


# ─────────── 입력: 끌어서 이동 · 무쌍(스페이스) ───────────

func _unhandled_input(event: InputEvent) -> void:
	if state == "tap":
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			_start()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		# 무쌍 버튼은 몇 번째 손가락이든 받음(끌면서 다른 손가락으로 누름). 마우스는 터치로 바뀌어 여기로 옴
		if ev.pressed and hud.pause_hit(ev.position):
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif ev.pressed and hud.musou_hit(ev.position):
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
		elif ev.pressed and not ev.echo and (ev.physical_keycode == KEY_ESCAPE or ev.physical_keycode == KEY_P):
			toggle_pause()


## 일시정지(D-197): 판 · 배경음이 멈추고 멈춤 창. 레벨업 고르는 중 · 판이 끝난 뒤엔 안 됨
func toggle_pause() -> void:
	if state == "play":
		state = "pause"
		joy_on = false
		joy_id = -1
		Sound.set_paused(true)
		hud.show_pause()
	elif state == "pause":
		resume()


func resume() -> void:
	if state != "pause":
		return
	state = "play"
	hud.hide_pause()
	Sound.set_paused(false)


## 앱이 뒤로 가거나(안드로이드 · iOS) 창이 포커스를 잃으면 자동으로 멈춤(D-177의 모바일 필수 항목)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == "play" and not bot_on:
			toggle_pause()


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
	# 한 프레임에 나아가는 판 시간 상한(2026-10-13: 0.033 → 0.066). 전엔 웹판과 같은 0.033이라 30fps 아래에선 판 전체가 슬로모션이 됐음
	# (저사양 태블릿 웹 13fps면 실제 속도의 약 45%). 이제 15fps까지는 제 속도, 그보다 끊기면 그만큼만 느려짐
	var dt := minf(delta, 0.066)
	if state == "play":
		_update(dt)
	# 장수가 들어선 칸의 흐름장을 미리 넓혀 둠 — 'p'는 0.2초마다만 새로 만들어서 대개 몇 프레임 뒤에 이어받음
	Perf.begin(&"길찾기")
	if flow.ver == obs_ver:
		flow.prefetch("p", hero.position)
	flow.work(FLOW_WORK)
	Perf.end()
	_place_camera()
	Perf.begin(&"그리기 요청")
	_redraw_units()
	Perf.end()
	_terrain_check()
	ground.queue_redraw()
	fx_layer.queue_redraw()
	hud.refresh()


## 화면(+ DRAW_PAD) 근처 인물만 다시 그림. 전엔 인물마다 _process에서 매 프레임 다시 그려서
## 지도(840×3000) 대부분 화면 밖인 적까지 그렸음(D-198). 화면 밖에 남은 지난 그림은 보이지 않음.
func _redraw_units() -> void:
	var V := view.grow(DRAW_PAD)
	for e in enemies:
		if V.has_point(e.position):
			e.refresh_look()
	for a in allies:
		if V.has_point(a.position):
			a.queue_redraw()


## 판 한 프레임. 성능 측정(D-198)은 구간별로 잼 — 이름 붙지 않은 나머지는 '판:기타'
func _update(dt: float) -> void:
	Perf.begin(&"판:기타")
	_update_impl(dt)
	Perf.end()


func _update_impl(dt: float) -> void:
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
	Perf.begin(&"적 움직임")
	var dl := duel()
	for e in enemies:
		if not e.dead and (not dl or e.arena_side > 0):
			e.tick(dt)
	Perf.end()
	# 장수가 쓰러졌으면(적에게 닿음) 이 프레임의 나머지(날아가던 참격 등)를 멈춤 — 안 그러면 진영장을 잡아 점령 회복이 들어갔음
	if state != "play":
		return
	_run_later()
	Perf.begin(&"기본 공격")
	_tick_blades(dt)
	Perf.end()
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
	if siege != null and siege.in_storm:
		p.spd *= float(SiegeData.SORCERY.storm_slow)
	# 공격: 무쌍 > 기본 공격(대표 무기가 날아감)
	Perf.begin(&"기본 공격")
	if p.musou_t > 0:
		p.musou_tick(dt)
	elif p.stun <= 0:
		p.attack_tick(dt)
	Perf.end()
	# 아군 본진: 궁병이 가까운 적을 쏨 · 적이 붙으면 체력이 깎임
	turret_t -= dt
	if turret_t <= 0:
		turret_t = 0.7
		var tg := nearest_enemy(home_pos, home_r + 110)
		if tg != null and not duel():
			hurt_enemy(tg, 16)
			add_fx({"k": "shot", "pos": home_pos + Vector2(0, -20), "pos2": tg.position, "t": 0.15})
	var K := keep_rect()
	for e in enemies:
		if e.dead:
			continue
		if e.goal_home and not duel() and not Unit.alive(e.engage) and e.position.distance_to(home_pos) < home_r + e.r:
			home_hp -= 1.2 * dt
		if e.boss:
			# 요술 제단이 남아 있는 동안(보호막) 장각은 본진 안쪽 절반에서만 — 문을 막아서 장수가 못 들어왔음(D-207)
			var hi := K.end - Vector2(e.r + 12, e.r + 12)
			if e.shield:
				hi.y = K.get_center().y
			e.position = e.position.clamp(K.position + Vector2(e.r + 12, e.r + 12), hi)
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
	Perf.begin(&"생성")
	# 일기토 중엔 시간표 · 생성 · 대군이 멈춤(끝나면 이어짐 — 정해진 시각이 지났으면 그때 일어남)
	if not duel():
		_village_tick(dt)
		_pack_tick()
		_home_raid_tick()
		_camps_tick(dt)
		_granary_tick(dt)
		_party_tick(dt)
		_rein_tick(dt)
		_wave_tick(dt)
		_surge_tick(dt)
		_army_tick(dt)
	_cyz_tick(dt)
	if siege != null:
		siege.tick(dt)
	Perf.end()
	Perf.begin(&"충돌")
	_separate()
	Perf.end()
	Perf.begin(&"아군")
	_ally_timers(dt)
	_engage_tick(dt)
	var dla := duel()
	for a in allies:
		if not a.dead and not dla:
			a.tick(dt)
	Perf.end()
	_arena_tick(dt)
	Perf.begin(&"책략")
	tactics.tick(dt)
	Perf.end()
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


## 탁현 마을 습격(D-208): VILLAGE.at초가 지나고 장수가 마을에서 far px 넘게 떨어져 있으면(D-209) 등무 + 습격대가 마을 둘레에 자리 잡음
## (가까이 오면 장수에게 덤빔) → limit초 안에 등무를 쓰러뜨리면 구함(_on_kill), 시간이 다 되면 마을이 불타고 남은 습격대는 본진으로
func _village_tick(dt: float) -> void:
	var V: Dictionary = Stage1.VILLAGE
	if vil_st == "wait":
		if t < float(V.at) or hero.position.distance_to(V.pos) <= float(V.far):
			return
		vil_st = "raid"
		vil_t = float(V.limit)
		var vp: Vector2 = V.pos
		var lk: String = V.lk
		deng = spawn(lk, vp + Vector2(0, -10), float(V.mul) * float(V.lm))
		deng.elite = true
		deng.ename = V.ln
		deng.touch = Units.ENEMY[lk].touch
		deng.r *= 1.4
		deng.raid = true
		deng.set_post(vp + Vector2(0, -10))
		deng.aggro = 220
		for i in int(V.raiders):
			var at := vp + Vector2.from_angle(randf() * TAU) * randf_range(50, 110)
			if hit_obs(at, 12):
				at = vp + Vector2(randf_range(-30, 30), 40)
			var e := spawn("ytbig" if i < 2 else "ytb", at, float(V.mul))
			e.raid = true
			e.set_post(at)
			e.aggro = 170
		vil_t0 = t
		note("탁현 마을 습격")
		_companion_come()
		banner("%s이 습격당해요!" % V.n, "%s%s %s%s 막아요 — %d초 안에 함께 쓰러뜨려요" % [companion.hd.display_name, jo(companion.hd.display_name, "이", "가"), String(V.ln).get_slice(" ", String(V.ln).get_slice_count(" ") - 1), eul(V.ln), int(V.limit)]
			if companion != null else "%s%s %d초 안에 쓰러뜨려요 — 오른쪽 아래" % [V.ln, eul(V.ln), int(V.limit)])
		Sound.play("alert", 0.5)
	elif vil_st == "raid":
		if vil_hero_t < 0 and Unit.alive(deng) and hero.position.distance_to(deng.position) < 200:
			vil_hero_t = t
		vil_t -= dt
		if vil_t > 0:
			return
		vil_st = "lost"
		vil_end_t = t
		if companion_on():
			companion.leave("lost")
		for e in enemies:
			if not e.dead and e.raid:
				e.has_post = false
				e.goal_home = true
				e.aggro = 160
		note("탁현 마을 불탐")
		banner("%s이 불탔어요…" % V.n, "%s의 습격대가 본진으로 향해요" % V.ln)
		Sound.play("lose", 0.3)


## 스토리 동료(D-212 · D-215): 마을 습격이 시작되면 동료 장수가 마을 동쪽에서 나타나 등무를 맡음(장수를 호위하지 않음)
func _companion_come() -> void:
	var C: Dictionary = Stage1.COMPANION
	var hd: HeroData = load(C.hero)
	if hd == null:
		return
	var at: Vector2 = C.from
	companion = Companion.new()
	companion.setup_companion(self, hd, C, at, deng)
	world.add_child(companion)
	allies.append(companion)
	add_fx({"k": "ring", "pos": at, "t": 0.5, "r": 28.0, "c": Color("6a9ad8")})
	cmp_log = {"goal_hp": deng.max_hp, "left_t": -1.0, "why": ""}
	cmp_log_update(companion)
	note("%s 등장" % hd.display_name)


func cmp_log_update(c: Companion) -> void:
	cmp_log.n = c.hd.display_name
	cmp_log.kills = c.kills
	cmp_log.dealt = c.dealt
	cmp_log.hp = c.hp / c.max_hp


## 동료가 아직 싸우는 중인가(물러나 사라진 동료는 queue_free돼 있어 Unit.alive에 넘기면 오류)
func companion_on() -> bool:
	return is_instance_valid(companion) and not companion.dead and not companion.leaving


## 동료가 물러남(Companion.leave): 마을이 끝났거나(saved · lost) 많이 다쳤을 때(hurt)
func companion_left(c: Companion) -> void:
	cmp_log_update(c)
	cmp_log.left_t = t
	cmp_log.why = c.why
	note("%s 물러남(%s)" % [c.hd.display_name, {"saved": "마을 구함", "lost": "마을 불탐", "hurt": "다침"}.get(c.why, c.why)])
	if c.why == "hurt":
		# 마을이 끝나서 물러날 땐 마을 알림(구함 · 불탐)이 대신함
		banner("%s%s 물러나요" % [c.hd.display_name, jo(c.hd.display_name, "이", "가")], "%s%s 막다 많이 다쳤어요 — 서둘러요" % [Stage1.VILLAGE.ln, eul(Stage1.VILLAGE.ln)])


## 늑대 · 들개 무리(D-209): PACK.at초에 한 번, 화면 바로 밖 dirs방향에서 늑대(멈칫 → 덮침) · 들개(빠르게 쫓음)가 장수에게
func _pack_tick() -> void:
	var P: Dictionary = Stage1.PACK
	if pack_done or t < float(P.at):
		return
	pack_done = true
	var m := mul_y(hero.position.y)
	var dirs := int(P.dirs)
	var nw := int(P.wolves)
	var off := randf() * TAU
	for i in nw + int(P.dogs):
		var o := ring_pos(off + (i % dirs) * TAU / dirs + randf_range(-0.2, 0.2))
		if o == Vector2.INF:
			continue
		var at := Vector2(clampf(o.x + randf_range(-30, 30), 30, W - 30), clampf(o.y + randf_range(-30, 30), 30, H - 30))
		spawn("wolf" if i < nw else "dog", at, m)
	note("늑대 · 들개 무리")
	banner("늑대 · 들개 무리가 덮쳐요!", "빠르니 둘러싸이지 않게 조심해요")
	Sound.play("alert", 0.5)


## 본진 기습(D-208 · D-209): HOME_RAID.at초에 한 번, 본진 양옆에서. 돌격병은 유비만 노리고(아군과 붙지 않음), 나머지는 본진으로.
## 유비 · 수비대가 막고, 많이 밀리면 장수가 돌아가 도와야 함(유비가 쓰러지면 짐)
func _home_raid_tick() -> void:
	var R: Dictionary = Stage1.HOME_RAID
	if home_raided or t < float(R.at):
		return
	home_raided = true
	for i in int(R.n):
		var x := randf_range(30, 90) if i % 2 == 1 else randf_range(W - 90, W - 30)
		var k := "ytdash" if i % 4 == 0 else ("ytbig" if i % 5 == 3 else "ytb")
		var e := spawn(k, Vector2(x, randf_range(2560, 2700)), float(R.mul))
		if k == "ytdash":
			e.hunt_lb = true
			e.no_eng = true
		else:
			e.goal_home = true
		e.aggro = 160
	note("본진 기습")
	banner("본진 기습!", "돌격병이 유비를 노려요 — 유비가 쓰러지면 져요")
	Sound.play("alert", 0.6)


## 진영(D-205): 진영장이 처음부터 진영 안에서 호위병을 부름(장수가 가까우면 자주 · 진영 병력 상한 — 전엔 막사가 냄, D-202).
## 수비탑이 하나라도 서 있으면 진영장은 보호막 → 탑을 다 부수고 진영장을 쓰러뜨리면 점령
func _camps_tick(dt: float) -> void:
	if camps_paused():
		return
	var L: Dictionary = Stage1.LEAD
	for c in camps:
		if c.cap or not Unit.alive(c.lead):
			continue
		c.call_t -= dt
		if c.call_t > 0:
			continue
		var lp: Vector2 = c.lead.position
		c.call_t = float(L.call_near) if hero.position.distance_to(lp) < float(L.near) else float(L.call_far)
		var room := int(L.cap) - _count_guards(c.id)
		if room <= 0 or enemies.size() >= 240:
			continue
		for i in mini(room, int(L.call_n)):
			_guard(c, float(c.mul) * (1.0 + minf(t, 600.0) / 600.0 * 0.25))
		if in_view(lp, 40):
			add_fx({"k": "ring", "pos": lp, "t": 0.35, "r": 46.0, "c": Color("e8c060")})


## 대군이 나와 있는 동안 남은 진영이 병력을 내지 않음(ARMY.pause_camps — 대군과 진영을 한꺼번에 상대하지 않게)
func camps_paused() -> bool:
	return bool(Stage1.ARMY.pause_camps) and army_t0 >= 0 and not cyz_dead


## 진영장 곁에 호위병 하나(벽 · 물이면 진영장 앞). 장수가 멀면 진영장을 따라다님
func _guard(c: Dictionary, mul: float) -> Enemy:
	var L: Enemy = c.lead
	var lp := L.position
	var at := lp + Vector2.from_angle(randf() * TAU) * randf_range(30, 55)
	if hit_obs(at, 12):
		at = lp + Vector2(randf_range(-20, 20), 34)
	var e := spawn("ytarch" if randf() < 0.12 else "ytb", at, mul)
	e.camp_id = c.id
	e.set_post(at)
	e.guard_of = L
	e.guard_off = at - lp
	e.aggro = 220
	return e


## 진영의 살아 있는 병력(진영장 · 수비탑 빼고)
func _count_guards(id: String) -> int:
	var n := 0
	for e in enemies:
		if not e.dead and e.camp_id == id and not e.building and not e.elite:
			n += 1
	return n


## 진영에 남은 수비탑 수(남아 있으면 진영장은 보호 중, D-205)
func towers_left(c: Dictionary) -> int:
	var n := 0
	for tw in c.tws:
		if tw.alive:
			n += 1
	return n


## 목표 진영(D-209): 진행 중인 진영(cur_camp — 수비탑을 처음 친 곳)이 있으면 점령할 때까지 그곳, 없으면 장수에게서 가장 가까운 진영.
## 전엔 늘 가장 가까운 진영이라, 탑이 진영 밖에 있다 보니 적을 피하다 다른 진영으로 화살표가 넘어갔음
func focus_camp() -> Dictionary:
	if cur_camp != "":
		var cc := camp_by_id(cur_camp)
		if not cc.is_empty() and not cc.cap:
			return cc
		cur_camp = ""
	var best := {}
	var bd := INF
	for c in camps:
		if c.cap:
			continue
		var d := hero.position.distance_to(c.pos)
		if d < bd:
			bd = d
			best = c
	return best


## 판의 사건 하나를 적어 둠(봇 출력용)
func note(n: String) -> void:
	events.append({"t": t, "n": n})


## 황건 부대가 본진으로(45초마다, 점령 안 된 진영 하나의 진영장 곁에서)
func _party_tick(dt: float) -> void:
	party_t -= dt
	if party_t > 0 or camps_paused():
		return
	var src: Array[Dictionary] = []
	for c in camps:
		if not c.cap and Unit.alive(c.lead):
			src.append(c)
	if src.is_empty():
		return
	party_t = 45
	var c: Dictionary = src.pick_random()
	var lp: Vector2 = c.lead.position
	for i in 8:
		var at := lp + Vector2(randf_range(-30, 30), 30 + randf_range(0, 20))
		if hit_obs(at, 12):
			at = lp + Vector2(0, 34)
		var e := spawn("ytdash" if i < 2 else "ytb", at, c.mul)
		e.goal_home = true
		e.aggro = 200
	banner("%s에서 부대가 본진으로!" % c.n, "본진 체력을 지켜요")
	Sound.play("alert", 0.3)


## 들판 증원(D-186): 끊이지 않고 여러 방향에서 동시에 몰려옴(진영을 치는 동안에도).
## REIN_GAP초마다 화면 바로 바깥 둘레를 방향 수만큼 고르게 나눈 곳(조금씩 흔듦)에서 나눠 나옴.
## 초당 7.5명 → 분당 +2.25(최대 21, D-189 — 처음엔 5 · 1.5 · 14), 방향 3 → 2분 4 → 4분 5.
## 쉬는 건 장수를 쫓는 무리(자리 · 본진 목표가 없는 적)가 둘레 520px 안에 REIN_CAP 이상 · 적이 너무 많음 · 장각과 싸울 때뿐
## (전엔 3초마다 한 덩어리가 한 방향에서 왔고, 막사 옆에 서 있는 병력까지 '둘레 420px 안 40명'으로 세어 막사 앞에서 쉬었음).
func _rein_tick(dt: float) -> void:
	rein_t -= dt
	if rein_t > 0:
		return
	rein_t = REIN_GAP
	if boss != null or won or enemies.size() >= 300:
		return
	var chase := 0
	for e in enemies:
		if not e.dead and not e.has_post and not e.goal_home and not e.building and e.position.distance_to(hero.position) < 520:
			chase += 1
	# 적 밀도(D-209): 상한 · 수에 시간 배율
	var dn := density()
	if chase >= REIN_CAP * dn:
		return
	var n := roundi(minf(21.0, 7.5 + t / 60.0 * 2.25) * REIN_GAP * dn)
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
			# 궁수 약 12% · 돌격병 약 7%(2026-10-13 적 역할 — 전엔 20% · 3%)
			elif py < 2300 and rein_i % 8 == 4:
				k = "ytarch"
			elif rein_i % 14 == 0:
				k = "ytdash"
			var at := Vector2(clampf(o.x + randf_range(-30, 30), 30, W - 30), clampf(o.y + randf_range(-30, 30), 30, H - 30))
			spawn(k, at, m).xp_mul = REIN_XP


## 적 밀도 시간 배율(D-209, Stage1.DENSITY)
func density() -> float:
	return 1.0 + t / float(Stage1.DENSITY.per)


## 포위 웨이브(D-182): 30~40초마다 장수 둘레 300px 원 위 사방에서 조여 옴(체력은 웹판 '에워싸는 무리'처럼 60%).
## 수 32 + 분당 10(최대 96, D-191 — 처음엔 웹판과 같은 16 + 5 · 48) · 빠르기 +35%까지(10분) · 웨이브를 거듭할수록 돌격병 · 역사가 섞임.
## 벽 안 · 장수에게 걸어올 수 없는 자리는 뺌. 장각과 싸울 때는 쉼.
func _wave_tick(dt: float) -> void:
	wave_t -= dt
	if wave_t > 0:
		return
	wave_t = randf_range(30, 40)
	if boss != null or won or enemies.size() >= 300:
		return
	wave_n += 1
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var f := flow.field("p", hero.position, t, 0.2)
	var n := mini(96, 32 + int(t / 60.0 * 10.0))
	var R := 300.0
	var m := mul_y(hero.position.y) * WAVE_HP
	var sp := 1.0 + minf(t, 600.0) / 600.0 * 0.35
	var off := randf() * TAU
	var made := 0
	for i in n:
		var at := hero.position + Vector2.from_angle(off + float(i) / n * TAU) * R
		at = Vector2(clampf(at.x, 24, W - 24), clampf(at.y, 24, H - 24))
		if hit_obs(at, 14) or not flow.reach(f, flow.cell_of(at)):
			continue
		var k := "ytb"
		if wave_n >= 2 and i % 12 == 3:
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


## 몰려오는 무리(Stage1.SURGE): gap초마다 화면 밖 한 방향(걸어올 수 있는 자리)을 정해 warn초 예고 → 그 자리에 무리가 모여 나와 장수를 쫓음
func _surge_tick(dt: float) -> void:
	var S: Dictionary = Stage1.SURGE
	if won or boss != null or t < float(S.from):
		return
	if not surge_warn.is_empty():
		surge_warn.t = float(surge_warn.t) - dt
		if float(surge_warn.t) <= 0:
			_surge_go(surge_warn.at)
			surge_warn = {}
		return
	surge_t -= dt
	if surge_t > 0:
		return
	surge_t = float(S.gap)
	if not arena.is_empty() or enemies.size() >= int(S.cap):
		return
	for _i in 6:
		var p := ring_pos(randf() * TAU)
		if p != Vector2.INF:
			surge_warn = {"a": (p - hero.position).angle(), "t": float(S.warn), "at": p}
			Sound.play("alert", 0.25)
			return


func _surge_go(at: Vector2) -> void:
	var S: Dictionary = Stage1.SURGE
	var n := mini(int(S.max), int(S.n0) + int(float(S.per_min) * t / 60.0))
	var m := mul_y(at.y) * float(S.hp)
	var made := 0
	for i in n:
		var p := at + Vector2.from_angle(randf() * TAU) * randf_range(0, float(S.spread))
		p = Vector2(clampf(p.x, 24, W - 24), clampf(p.y, 24, H - 24))
		if hit_obs(p, 12):
			continue
		var e := spawn("ytdash" if i % int(S.dash_every) == int(S.dash_every) - 1 else "ytb", p, m)
		e.xp_mul = REIN_XP
		made += 1
	if made > 0:
		surge_n += 1
		add_fx({"k": "ring", "pos": at, "t": 0.4, "r": float(S.spread) + 20.0, "c": Color("d9705e")})


## 정원지의 대군(D-214): 진영 ARMY.after곳을 점령하면 곧바로 출진 — 부대마다 ARMY.units[].at초에(앞 부대 부장이 쓰러지고 rest초 뒤가 더 이르면 그때) 관문 앞에서 나와 길을 따라 본진으로 진군.
## 부대의 대장(부장 · 본대는 정원지도)이 본진에 닿으면 짐. 본진에서 danger px 안에 들어오면 가까울수록 자주 돌격병을 유비에게 보냄.
## 장수가 부대 대장을 처음 260px 안에서 만난 때 · 그때 본진까지 거리를 적어 둠(봇 출력)
func _army_tick(dt: float) -> void:
	var A: Dictionary = Stage1.ARMY
	if won or cap_n < int(A.after):
		return
	if army_t0 < 0:
		army_t0 = t
		for i in A.units.size():
			army.append({"i": i, "spawned": false, "lead": null, "met_t": -1.0, "met_d": -1.0, "kill_t": -1.0, "kill_d": -1.0, "eng": 0.0, "hunt_t": 0.0, "warned": false})
		note("정원지 대군 출진")
		banner("정원지의 대군이 출진해요!", "선봉 · 중군 · 본대가 길을 따라 본진으로 — 본진에 닿기 전에 막아요")
		Sound.play("alert", 0.6)
	if Unit.alive(cyz) and hero.position.distance_to(cyz.position) < 260:
		cyz_eng += dt
	for u in army:
		var U: Dictionary = A.units[u.i]
		if not u.spawned:
			# 정한 때가 되었거나, 앞 부대의 부장이 쓰러지고 ARMY.rest초가 지났으면(빨리 깨면 덜 기다림 — 2026-10-13: 전엔 곧바로)
			var pk: float = army[u.i - 1].kill_t if u.i > 0 else -1.0
			var prev_done: bool = pk >= 0 and t >= pk + float(A.rest)
			if t >= army_t0 + float(U.at) or prev_done:
				_spawn_unit(u, U)
			continue
		var head := _army_head(u)
		if head == null:
			continue
		var dh := head.position.distance_to(home_pos)
		# 장수가 부장 곁(260px)에 있던 시간 = 실제로 싸운 시간(봇 출력 — 지나가다 스친 '만남'과 구별)
		if Unit.alive(u.lead) and hero.position.distance_to(u.lead.position) < 260:
			u.eng += dt
		if u.met_t < 0 and hero.position.distance_to(head.position) < 260:
			u.met_t = t
			u.met_d = dh
			note("%s%s 만남(본진까지 %dpx)" % [U.n, jo(U.n, "과", "와"), int(dh)])
		if dh < home_r + float(A.reach):
			finish(false, "army")
			return
		if dh < float(A.danger):
			if not u.warned:
				u.warned = true
				banner("%s%s 본진에 다가와요!" % [U.n, jo(U.n, "이", "가")], "돌격병이 유비를 노려요 — 막으러 가요")
				Sound.play("alert", 0.5)
			u.hunt_t -= dt
			if u.hunt_t <= 0:
				var k := clampf((dh - home_r) / (float(A.danger) - home_r), 0.0, 1.0)
				u.hunt_t = lerpf(float(A.hunt_near), float(A.hunt_far), k)
				for j in int(A.hunt_n):
					var e := spawn("ytdash", head.position + Vector2(randf_range(-30, 30), randf_range(10, 40)), float(A.smul))
					e.hunt_lb = true
					e.no_eng = true
					e.aggro = 160


## 부대의 대장 중 본진에 가장 가까운 것(부장 · 본대는 정원지도). 없으면 null
func _army_head(u: Dictionary) -> Enemy:
	var best: Enemy = null
	var cands: Array = [u.lead]
	if Stage1.ARMY.units[u.i].get("boss", false):
		cands.append(cyz)
	for e in cands:
		if Unit.alive(e) and (best == null or e.position.distance_to(home_pos) < best.position.distance_to(home_pos)):
			best = e
	return best


## 지금 본진에 가장 가까운 부대 {u, head, d}(나와 있고 대장이 살아 있는 것 중). 없으면 {}
func army_front() -> Dictionary:
	var out := {}
	for u in army:
		if not u.spawned:
			continue
		var head := _army_head(u)
		if head == null:
			continue
		var d := head.position.distance_to(home_pos)
		if out.is_empty() or d < float(out.d):
			out = {"u": u, "head": head, "d": d}
	return out


## 부대 하나가 관문 앞에서 출진: 부장 + 병사(부장 곁을 따라 걷는 대열). 본대면 정원지도
func _spawn_unit(u: Dictionary, U: Dictionary) -> void:
	var A: Dictionary = Stage1.ARMY
	var at := Vector2(float(A.road_x), float(A.y0))
	var lk: String = U.lk
	var L := spawn(lk, at, float(U.lm))
	L.elite = true
	L.ename = U.ln
	L.touch = Units.ENEMY[lk].touch
	L.r *= 1.4
	L.goal_home = true
	L.march_spd = float(A.march)
	L.march_slow = float(A.slow)
	L.march_slow_r = float(A.slow_r)
	# 장수를 쫓지 않고 계속 진군(D-214)
	L.aggro = 0.0
	L.army_unit = u.i
	L.army_lead = true
	# 내려찍기(2026-10-13 적 역할)
	L.pat = A[String(U.get("pat", "slam"))]
	L.pat_cd = randf_range(2.0, 4.0)
	u.lead = L
	u.spawned = true
	var m := float(A.smul) * (1.0 + minf(t, 600.0) / 600.0 * 0.25)
	for j in int(U.count):
		var k := "ytb"
		if j % 5 == 0:
			k = "ytbig"
		elif j % 8 == 1:
			k = "ytarch"
		elif j % 12 == 2:
			k = "ytdash"
		var off := Vector2(randf_range(-110, 110), randf_range(-40, 90))
		var e := spawn(k, at + off, m)
		e.army_unit = u.i
		e.set_post(at + off)
		e.guard_of = L
		e.guard_off = off
		e.aggro = 200
	note("%s 출진" % U.n)
	if U.get("boss", false):
		_spawn_cyz(at + Vector2(0, -20), u.i)
	else:
		banner("정원지 대군 · %s 출진!" % U.n, "%s%s 이끌어요 — 쓰러뜨리면 부대가 흩어지고 보급 상자" % [U.ln, jo(U.ln, "이", "가")])
		Sound.play("alert", 0.4)


## 받침이 있으면 a, 없으면 b(과/와 · 이/가)
static func jo(s: String, a: String, b: String) -> String:
	return a if eul(s) == "을" else b


## 아직 안 나온 부대가 나오기까지 남은 초(정한 때와 앞 부장이 쓰러지고 rest초 뒤 중 먼저 오는 쪽)
func _unit_eta(u: Dictionary) -> float:
	var A: Dictionary = Stage1.ARMY
	var at := army_t0 + float(A.units[u.i].at)
	var pk: float = army[u.i - 1].kill_t if u.i > 0 else -1.0
	if pk >= 0:
		at = minf(at, pk + float(A.rest))
	return at - t


## 쓰러진 대군 부장 수
func _army_leads_down() -> int:
	var n := 0
	for u in army:
		if u.spawned and not Unit.alive(u.lead):
			n += 1
	return n


## 정원지 2단계(D-211): 체력 phase2 아래 또는 부장 CYZ.leads2명이 쓰러지면 분노 — 돌진 · 땅 내려찍기를 번갈아(공격 간격 × gap2), 싸울 때 빠르기 × spd2, 남은 군사 rally명을 부름
func _cyz_tick(_dt: float) -> void:
	if not cyz_on or cyz_dead:
		return
	var Z: Dictionary = Stage1.CYZ
	if cyz_phase == 1 and Unit.alive(cyz) and (cyz.hp <= cyz.max_hp * float(Z.phase2) or _army_leads_down() >= int(Z.leads2)):
		var in_duel := duel()
		cyz_phase = 2
		# 혼자 버티지 않고 장수에게 달려듦(2026-10-13)
		cyz.aggro = float(Z.aggro2)
		cyz.skill_list = ["charge", "slam"]
		cyz.sk_i = 0
		cyz.gap_mul = float(Z.gap2)
		cyz.spd0 *= float(Z.spd2)
		# 일기토 중엔 부하를 부르지 않음(1:1)
		for i in (0 if in_duel else int(Z.rally)):
			var at: Vector2 = cyz.position + Vector2.from_angle(randf() * TAU) * randf_range(60, 160)
			at = at.clamp(Vector2(40, 745), Vector2(W - 40, H - 40))
			if hit_obs(at, 12):
				at = cyz.position + Vector2(randf_range(-30, 30), 40)
			var re := spawn("ytbig" if i % 4 == 0 else ("ytdash" if i % 5 == 2 else "ytb"), at, 1.3)
			# 울타리 안에서 부른 군사는 울타리 안(D-216)
			if not arena.is_empty() and arena.st == "on" and at.distance_to(arena.c) < float(arena.r):
				re.arena_side = 1
		note("정원지 2단계")
		banner("정원지가 분노해요!", "돌진 · 땅 내려찍기를 피해요" if in_duel else "남은 군사를 모두 불러요 — 돌진 · 땅 내려찍기를 피해요")
		add_fx({"k": "ring", "pos": cyz.position, "t": 0.6, "r": 120.0, "c": Color("d9705e")})
		shake = maxf(shake, 0.3)
		Sound.play("alert", 0.6)


## 정원지(D-211 · D-214): 본대와 함께 출진해 본진으로 진군. 진영장처럼 예고 있는 공격을 쓰고(Enemy.make_lead), 장수가 가까우면 맞서 싸움
func _spawn_cyz(at: Vector2, unit_i: int) -> void:
	cyz_on = true
	note("정원지 등장")
	var Z: Dictionary = Stage1.CYZ
	cyz = spawn("cyz", at, Z.m)
	cyz.make_lead({"ln": "황건 장수 정원지", "id": "", "skill": "fan"}, Rect2(0, 0, W, H))
	# 1단계: 부채꼴 화살 · 내려찍기를 번갈아(2026-10-13 — 공격 간격 LEAD.gap 3초라 내려찍기는 6초마다)
	cyz.skill_list = ["fan", "slam"]
	cyz.march_home = true
	cyz.march_spd = float(Stage1.ARMY.march)
	cyz.army_unit = unit_i
	cyz.touch = 22
	banner("정원지가 본대를 이끌고 나왔어요!", "1장 최종 결전 — 정원지를 쓰러뜨리면 이겨요")
	Sound.play("alert", 0.6)


## 분:초
static func mmss(s: float) -> String:
	var n := maxi(0, ceili(s))
	return "%d:%02d" % [n / 60, n % 60]


## 겹치지 않게(30px 칸으로 나눠 이웃끼리만 밀어냄). 적은 enemies 차례로, 이웃은 칸 차례 · 칸 안 enemies 차례로 봄.
## 칸을 Dictionary 대신 번호 배열로 두고, 위치 · 반지름을 배열로 읽어 다 민 뒤 한 번만 씀(D-198 — 미는 차례 · 계산은 같아 결과도 같음).
func _separate() -> void:
	var list := enemies
	var n := list.size()
	_cell_units = list
	_cell_next.resize(n)
	_sep_cx.resize(n)
	_sep_cy.resize(n)
	_sep_pos.resize(n)
	_sep_r.resize(n)
	_sep_mv.resize(n)
	var x0 := 1 << 30
	var y0 := 1 << 30
	var x1 := -x0
	var y1 := -y0
	for i in n:
		var e := list[i]
		if e.dead:
			_sep_mv[i] = 0
			continue
		var p := e.position
		var cx := int(p.x / GRID)
		var cy := int(p.y / GRID)
		_sep_cx[i] = cx
		_sep_cy[i] = cy
		_sep_pos[i] = p
		_sep_r[i] = e.r
		# 대군 부장 · 정원지는 밀리지 않음(2026-10-13 — 자기 병사들에게 떠밀려 진군 빠르기의 약 5배로 본진에 닿았음)
		_sep_mv[i] = 1 if e.boss or e.building or e.air > 0 or e.army_lead or e.march_home else 2
		x0 = mini(x0, cx)
		x1 = maxi(x1, cx)
		y0 = mini(y0, cy)
		y1 = maxi(y1, cy)
	if x1 < x0:
		_cell_gw = 0
		_cell_gh = 0
		_cell_head.resize(0)
		return
	_cell_ox = 1 - x0
	_cell_oy = 1 - y0
	_cell_gw = x1 - x0 + 3
	_cell_gh = y1 - y0 + 3
	var gh := _cell_gh
	_cell_head.resize(_cell_gw * gh)
	_cell_head.fill(-1)
	# 뒤에서부터 앞에 끼워 넣어 칸 안은 enemies 차례가 됨
	for i in range(n - 1, -1, -1):
		if _sep_mv[i] == 0:
			continue
		var c := (_sep_cx[i] + _cell_ox) * gh + _sep_cy[i] + _cell_oy
		_cell_next[i] = _cell_head[c]
		_cell_head[c] = i
	for i in n:
		if _sep_mv[i] != 2:
			continue
		var pe := _sep_pos[i]
		var p0 := pe
		var re := _sep_r[i]
		var c0 := (_sep_cx[i] + _cell_ox) * gh + _sep_cy[i] + _cell_oy
		for di in range(-1, 2):
			for dj in range(-1, 2):
				var k := _cell_head[c0 + di * gh + dj]
				while k >= 0:
					if k != i:
						var dv := pe - _sep_pos[k]
						var dd := dv.length()
						var m := (re + _sep_r[k]) * 0.85
						if dd > 0.01 and dd < m:
							pe += dv * ((m - dd) * 0.25 / dd)
					k = _cell_next[k]
		if pe != p0:
			_sep_pos[i] = pe
			list[i].position = pe


## 아군에게 붙은 적(맞히는 쪽). _separate가 만든 칸을 씀.
## 유비를 위협할 수 있는 적인가(2026-10-14 사람 손맛 "유비 문제" — 장수를 쫓아온 졸개가 본진 근처에서 유비에게 붙어 쓰러뜨렸음):
## 본진으로 가는 적(본진 기습 · 진영 부대 · 불탄 마을 습격대) · 유비를 노리는 돌격병 · 정원지의 대군만. 예고되는 위협이라 '왜 쓰러졌는지' 알 수 있게
static func threatens_lb(e: Enemy) -> bool:
	return e.goal_home or e.hunt_lb or e.army_unit >= 0


## liubei = 유비가 맞는 쪽이면 유비를 위협하는 적만(threatens_lb)
func touching_enemy(at: Vector2, extra: float, liubei_only := false) -> Enemy:
	Perf.begin(&"충돌")
	var e := _touching_enemy_impl(at, extra, liubei_only)
	Perf.end()
	return e


func _touching_enemy_impl(at: Vector2, extra: float, liubei_only: bool) -> Enemy:
	var cx := int(at.x / GRID) + _cell_ox
	var cy := int(at.y / GRID) + _cell_oy
	for i in range(-1, 2):
		var gx := cx + i
		if gx < 0 or gx >= _cell_gw:
			continue
		for j in range(-1, 2):
			var gy := cy + j
			if gy < 0 or gy >= _cell_gh:
				continue
			var k := _cell_head[gx * _cell_gh + gy]
			while k >= 0:
				var e := _cell_units[k]
				if not e.dead and not e.building and e.air <= 0 and e.position.distance_to(at) < e.r + extra and (not liubei_only or threatens_lb(e)):
					return e
				k = _cell_next[k]
	return null


# ─────────── 아군 ───────────

## 본진: 유비 + 창병 6명(7초마다 보충). 점령한 진영: 수비대 창병 4명(18초마다 보충) + 진군 부대 4명이 한 번(보충 없음, D-180)
func _setup_allies() -> void:
	anchors["home"] = {"pos": home_pos + Vector2(0, -50), "r": 230.0}
	liubei = ally_spawn("liubei", home_pos + Vector2(0, -40), "guard", "home")
	for i in 6:
		ally_spawn("sol", home_pos + Vector2(randf_range(-60, 60), -30 + randf_range(-20, 20)), "guard", "home")


func ally_spawn(k: String, at: Vector2, mode: String, anchor_id: String) -> Ally:
	var a := Ally.new()
	a.setup(self, k, at, mode, anchor_id)
	world.add_child(a)
	allies.append(a)
	add_fx({"k": "ring", "pos": at, "t": 0.35, "r": 16.0, "c": Color("6a9ad8")})
	return a


## 유비(아군 총대장)가 쓰러지면 짐(D-208 — 전엔 15초 뒤 본진으로 돌아왔음)
func ally_down(a: Ally) -> void:
	if a.k == "liubei":
		finish(false, "liubei")


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
		var lb_ok := threatens_lb(e)
		for a in allies:
			if a.dead or (a == liubei and not lb_ok):
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
		if e.dead or e.shield or e.prop or (e.arena_side < 0 and duel()):
			continue
		var d := e.position.distance_to(from)
		if d < bd:
			bd = d
			best = e
	return best


## 기본 공격 하나를 날림. size = 연격 단계 크기 배율, col = 연격 단계 색 [날, 테두리]
## who = 날린 동료(Companion, D-215) — null이면 출진 장수(연격 수 · 멈칫 · 장수 특성은 출진 장수만)
func launch_blade(from: Vector2, a: float, A: BasicAttack, dmg: float, size: float, col: Array, who: Companion = null) -> void:
	blades.append({"pos": from, "dir": Vector2.from_angle(a), "spd": A.speed, "travel": 0.0, "reach": A.reach, "spear": A.shape == "spear",
		"hw": A.width * size / 2, "thick": A.thickness * size, "bulge": A.bulge * size, "dmg": dmg, "pierce": A.pierce,
		"push": A.push, "hs": A.hit_stop, "shake": A.shake, "hit": {}, "hits": 0, "c": col[0], "c2": col[1], "who": who, "cmp": who != null})


## 날아가는 기본 공격: 반달 모양(가운데 두껍고 끝이 뾰족함) · 창(곧은 막대, 끝 = pos, D-215)에 닿은 적을 꿰뚫으며 벰. 적마다 한 번씩.
## 벽(물 말고)에 닿으면 사라짐(웹판 언월파와 같음). 장수급은 특성(lead_bonus)만큼 더 아프고 안 밀림.
## 동료(who)의 것은 연격 수 · 멈칫에 안 들어가고, 장수급을 체력 COMPANION.floor 아래로 못 깎음(마무리는 출진 장수).
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
		var spear: bool = bl.spear
		# 동료가 날린 것인데 동료가 이미 사라졌으면 함께 사라짐
		if bl.cmp and not is_instance_valid(bl.who):
			continue
		var who: Companion = bl.who if bl.cmp else null
		var n := 0
		var i := 0
		while i < enemies.size():
			var e := enemies[i]
			i += 1
			if e.dead or e.shield or bl.hit.has(e.get_instance_id()):
				continue
			var d := e.position - p
			var ly := d.dot(side)
			var lx := d.dot(dir)
			if spear:
				# 창: 끝(p)에서 뒤로 길이 2·hw, 굵기 thick인 막대(이번 프레임에 지나온 길 포함)
				if absf(ly) > float(bl.thick) / 2 + e.r or lx > e.r or lx < -2.0 * hw - e.r - step:
					continue
			else:
				if absf(ly) > hw + e.r:
					continue
				var tt := clampf(ly / hw, -1.0, 1.0)
				var s := 1.0 - tt * tt
				if lx > float(bl.bulge) * s + e.r or lx < (float(bl.bulge) - float(bl.thick)) * s - e.r - step:
					continue
			bl.hit[e.get_instance_id()] = true
			var lead := e.is_lead()
			if who != null:
				var dmg: float = bl.dmg * (1.0 + who.hd.lead_bonus if lead else 1.0)
				if e.elite:
					dmg = minf(dmg, maxf(0.0, e.hp - e.max_hp * float(who.C.floor)))
				if e == who.goal:
					who.dealt += dmg
				if dmg > 0:
					hurt_enemy(e, dmg)
					if e.dead:
						who.kills += 1
			else:
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
		if n > 0 and who == null:
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
		if e.dead or e.shield:
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
		if e.dead or e.shield:
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
	# 수비탑이 남은 진영의 진영장은 피해를 받지 않음(D-205) · 일기토를 지켜보는 울타리 밖 적은 다치지 않음
	# 일기토 중엔 울타리 안(arena_side 1)만 다침 — 밖의 건물 · 진영 목표 · 물체도 그대로
	if e.dead or e.shield or (e.arena_side <= 0 and duel()):
		return
	# 수비탑을 처음 친 진영 = 진행 중인 진영(D-209)
	if cur_camp == "" and e.tower_id != "":
		cur_camp = e.camp_id
	e.hp -= d
	e.flash = 0.1
	if (e.is_lead() or e.building) and not e.prop:
		add_fx({"k": "num", "pos": e.position + Vector2(randf_range(-6, 6), -e.r), "t": 0.7, "v": str(roundi(d)), "c": Color("fff2c0")})
	if e.hp <= 0:
		e.dead = true
		kills += 1
		add_fx({"k": "burst", "pos": e.position, "t": 0.3, "r": e.r * 0.6, "c": Color("f6e2a0")})
		Sound.play("hit" if e.prop else ("slam" if e.building else "kill"), 0.3 if e.prop else (0.45 if e.building else 0.12))
		_on_kill(e)


## 적이 쓰러지면: 진영 병력 · 진영장(점령) · 정원지(본진 문) · 장각(평정)
func _on_kill(e: Enemy) -> void:
	if e.prop:
		_prop_loot(e)
		return
	if not e.boss:
		drop_orb(e.position, TacticsData.xp_of(e.k, e.elite) * e.xp_mul)
	# 2 · 3장: 장각 · 요술 제단(D-211 — siege.gd)
	if siege != null and siege.on_kill(e):
		return
	if e.building:
		var c := camp_by_id(e.camp_id)
		for tw in c.tws:
			if tw.id == e.tower_id:
				tw.alive = false
		var total: int = c.tws.size()
		var left := towers_left(c)
		var kind: String = c.get("obj", "tower")
		var on := obj_name(c)
		add_fx({"k": "ring", "pos": e.position, "t": 0.5, "r": 60.0, "c": Color("ffb050")})
		shake = maxf(shake, 0.15)
		note("%s %s %d/%d" % [c.n, on, total - left, total])
		if kind == "cage":
			# 감옥(2026-10-14): 의용병이 풀려나 본진으로
			for j in int(Stage1.OBJ.cage.free):
				var a := ally_spawn("captive", e.position + Vector2(randf_range(-16, 16), randf_range(6, 20)), "escort", "")
				a.arena_side = 0
				captive_freed += 1
		elif kind == "granary" and float(c.burn_t) < 0 and left > 0:
			c.burn_t = float(Stage1.OBJ.granary.limit)
		if left == 0:
			c.burn_t = -1.0
			# 마지막 목표: 진영장 보호막이 풀림(D-205)
			if Unit.alive(c.lead):
				c.lead.shield = false
				add_fx({"k": "ring", "pos": c.lead.position, "t": 0.5, "r": 70.0, "c": Color("6ac0e0")})
			banner("%s%s 다 %s" % [on, jo(on, "을", "를"), "불태웠어요" if kind == "granary" else "부쉈어요"], "%s — %s의 보호막이 풀렸어요" % [c.n, c.ln])
		elif kind == "cage":
			banner("감옥을 부쉈어요 (%d/%d)" % [total - left, total], "의용병이 본진으로 가요 — 지켜 줘요")
		elif kind == "granary":
			banner("군량 더미를 불태웠어요 (%d/%d)" % [total - left, total], "%d초 안에 남은 더미를 모두 태워요" % ceili(float(c.burn_t)))
		else:
			banner("수비탑을 부쉈어요 (%d/%d)" % [total - left, total], "%s — 남은 탑을 부수면 %s의 보호막이 풀려요" % [c.n, c.ln])
		return
	if e.camp_lead != "":
		var c := camp_by_id(e.camp_lead)
		c.cap = true
		cap_n += 1
		if cur_camp == c.id:
			cur_camp = ""
		for o in enemies:
			if not o.dead and o.camp_id == c.id:
				o.dead = true
				kills += 1
				add_fx({"k": "burst", "pos": o.position, "t": 0.3, "r": o.r * 0.6, "c": Color("f6e2a0")})
		hero.heal(hero.max_hp * 0.15)
		# 보급 상자(D-205): 진영장이 쓰러진 자리
		drops.append({"k": "chest", "pos": e.position})
		note("%s 점령" % c.n)
		var R := camp_rect(c)
		anchors["camp_" + c.id] = {"pos": Vector2(R.get_center().x, R.end.y + 40), "r": 260.0}
		c.al_t = 0.0
		for i in MARCH_ON_CAPTURE:
			ally_spawn("sol", Vector2(R.get_center().x + randf_range(-24, 24), R.end.y + 30 + randf_range(0, 14)), "march", "")
		add_fx({"k": "ring", "pos": c.pos, "t": 0.6, "r": 150.0, "c": Color("4a7ab8")})
		Sound.play("win", 0.35)
		if cap_n >= 3:
			# 곧바로 정원지의 대군이 출진(D-214 — _army_tick)
			cap3_t = t
		else:
			banner("%s 점령! (%d/3)" % [c.n, cap_n], "보급 상자를 주워요 — 진군 부대 %d명이 다음 진영으로 먼저 가요" % MARCH_ON_CAPTURE)
		return
	if e == deng:
		if vil_st == "raid":
			# 탁현 마을을 구함(D-208): 남은 습격대는 흩어지고 회복 + 보급 상자
			vil_st = "saved"
			vil_end_t = t
			if companion_on():
				companion.leave("saved")
			for o in enemies:
				if not o.dead and o.raid:
					o.dead = true
					kills += 1
					add_fx({"k": "burst", "pos": o.position, "t": 0.3, "r": o.r * 0.6, "c": Color("f6e2a0")})
			var V: Dictionary = Stage1.VILLAGE
			# 마을 상자(D-209): 회복 + 경험(진화 없음)
			drops.append({"k": "chest", "kind": "village", "pos": e.position})
			note("탁현 마을 구함")
			banner("%s을 구했어요!" % V.n, "마을 사람들이 보급 상자를 내줬어요(회복 + 경험)")
			Sound.play("win", 0.35)
		else:
			banner("%s%s 쓰러뜨렸어요" % [e.ename, eul(e.ename)], "")
		return
	if e.army_lead:
		# 부장 격파(D-214): 그 부대는 흩어지고 보급 상자
		var U: Dictionary = Stage1.ARMY.units[e.army_unit]
		for o in enemies:
			if not o.dead and o.army_unit == e.army_unit and o != cyz:
				o.dead = true
				kills += 1
				add_fx({"k": "burst", "pos": o.position, "t": 0.3, "r": o.r * 0.6, "c": Color("f6e2a0")})
		var au: Dictionary = army[e.army_unit]
		au.kill_t = t
		au.kill_d = e.position.distance_to(home_pos)
		drops.append({"k": "chest", "pos": e.position})
		# 부장마다 고기만두 확정(2026-10-13 — 긴 대군전의 회복)
		for j in int(Stage1.ARMY.bun):
			drops.append({"k": "bun", "pos": e.position + Vector2(28, 0).rotated(j * 2.4 + 0.6), "src": "부장"})
		note("%s 격파" % U.n)
		banner("%s 격파! %s%s 흩어져요" % [e.ename, U.n, jo(U.n, "이", "가")], "보급 상자를 주워요" if not U.get("boss", false) else "보급 상자를 줍고 정원지를 쓰러뜨려요")
		hit_stop = 0.08
		shake = maxf(shake, 0.3)
		Sound.play("win", 0.35)
		return
	if e == cyz:
		note("정원지 격파")
		cyz_dead = true
		if siege != null:
			# 2 · 3장: 성문이 열리기 시작(D-206)
			siege.start_gate()
			return
		# 1장 최종 보스(D-210 · D-211): 남은 황건이 흩어지고 이김
		won = true
		for o in enemies:
			if not o.dead:
				o.dead = true
				add_fx({"k": "burst", "pos": o.position, "t": 0.3, "r": o.r * 0.6, "c": Color("f6e2a0")})
		banner("정원지를 쓰러뜨렸어요!", "탁현 싸움에서 이겼어요")
		hit_stop = 0.15
		shake = 0.5
		Sound.play("win", 0.5)
		later(1.8, finish.bind(true, ""))
		return
	if e.elite:
		return
	var r := randf()
	if r < 0.006:
		drops.append({"k": "bun", "pos": e.position, "src": "처치"})
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


## 적 탄(2026-10-13): 풀에서 꺼내 씀(다 쓴 것은 _shot_free로 돌려놓음). 동시에 SHOT_CAP개 · 궁수 화살(arrow)은 ARROW_CAP개까지 — 넘으면 쏘지 않음
const SHOT_CAP := 120
const ARROW_CAP := 40
var _shot_free: Array[Dictionary] = []
var _arrow_n := 0


func shoot(at: Vector2, vel: Vector2, dmg: float, rad: float, col: Color, src := "장수 화살", arrow := false) -> void:
	if shots.size() >= SHOT_CAP or (arrow and _arrow_n >= ARROW_CAP):
		return
	var s: Dictionary = _shot_free.pop_back() if not _shot_free.is_empty() else {}
	s.pos = at
	s.vel = vel
	s.dmg = dmg
	s.r = rad
	s.c = col
	s.life = 0.0
	s.src = src
	s.arrow = arrow
	if arrow:
		_arrow_n += 1
	shots.append(s)


func _tick_shots(dt: float) -> void:
	# 제자리에서 앞으로 당겨 담음(새 배열을 만들지 않음) — 빠진 것은 풀로
	var j := 0
	for i in shots.size():
		var s: Dictionary = shots[i]
		var p0: Vector2 = s.pos
		var p: Vector2 = s.pos + s.vel * dt
		s.pos = p
		s.life += dt
		var gone := false
		if p.x < -10 or p.y < -10 or p.x > W + 10 or p.y > H + 10 or p.distance_to(hero.position) > 700:
			gone = true
		elif in_wall(p, s.r * 0.5):
			add_fx({"k": "puff", "pos": p, "t": 0.2})
			gone = true
		elif not arena.is_empty() and arena.st == "on" and p0.distance_to(arena.c) >= float(arena.r) and p.distance_to(arena.c) < float(arena.r):
			# 보스 울타리(사람 손맛 2026-10-13 "울타리 안에 화살이 막 들어와 못 깸"): 밖에서 날아온 탄은 울타리에 막힘
			add_fx({"k": "puff", "pos": p, "t": 0.2})
			gone = true
		elif p.distance_to(hero.position) < s.r + hero.r - 2:
			hero.hurt(s.dmg, s.src)
			gone = true
		if gone:
			if s.arrow:
				_arrow_n -= 1
			_shot_free.append(s)
		else:
			shots[j] = s
			j += 1
	shots.resize(j)


## 쓰러진 것 치우기. 장수급(진영장 · 정원지 · 장각)과 건물(요술 제단 — altars가 붙잡음, D-207)은 다른 곳이 붙잡고 있어 숨기기만 한다.
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
			elif e.is_lead() or e.building:
				e.visible = false
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
		elif dr.k == "chest" and dr.get("kind", "") == "village":
			# 마을 상자(D-209): 회복 + 경험
			var V: Dictionary = Stage1.VILLAGE
			hero.heal(hero.max_hp * float(V.heal))
			heal_log["마을"] = int(heal_log.get("마을", 0)) + 1
			gain_xp(float(V.xp))
			banner("마을 사람들의 보급!", "체력 %d%% 회복 · 경험 +%d" % [roundi(float(V.heal) * 100), int(V.xp)])
			note("마을 상자")
			Sound.play("heal", 0.4)
			add_fx({"k": "ring", "pos": hero.position, "t": 0.6, "r": 90.0, "c": Color("8fe08a")})
		elif dr.k == "chest":
			# 진영 상자(D-205 · D-209): 진화(조건이 맞으면) 또는 책략 1개 레벨 업
			banner("보급 상자!", tactics.open_chest())
			note("보급 상자")
			Sound.play("win", 0.4)
			add_fx({"k": "ring", "pos": hero.position, "t": 0.6, "r": 90.0, "c": Color("f0c040")})
		elif dr.k == "bomb":
			_bomb_go()
		else:
			hero.heal(hero.max_hp * 0.3)
			var src: String = dr.get("src", "처치")
			heal_log[src] = int(heal_log.get(src, 0)) + 1
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


## 움직이지 않는 지형(terrain.gd): 지도를 세로로 나눈 조각마다 한 번 그림. 바닥(ground)보다 먼저 그려지게 맨 앞에
var _terrain: Array[Terrain] = []
var _terrain_sig := -1


func _make_terrain() -> void:
	var y := 0.0
	var i := 0
	while y < H:
		var tr := Terrain.new()
		tr.setup(self, y)
		add_child(tr)
		move_child(tr, i)
		_terrain.append(tr)
		y += Terrain.CHUNK
		i += 1


## 지형이 바뀌었으면(진영 점령 · 수비탑 파괴 · 마을 상태 · 장각 본진 열림) 조각들을 다시 그림
func _terrain_check() -> void:
	var sig := cap_n * 1000 + ["wait", "raid", "saved", "lost"].find(vil_st) * 100
	for c in camps:
		sig += towers_left(c) * 7 + (1 if c.cap else 0)
	if siege != null and siege.keep_open:
		sig += 50000
	if sig != _terrain_sig:
		_terrain_sig = sig
		for tr in _terrain:
			tr.queue_redraw()


## 부서지는 물체(D-216 2단계): 길가 · 진영 네 귀퉁이 바깥 · 마을 곁에 군량 수레 · 깃발 더미. 판마다 PROPS.skip 비율만큼 비움(--seed로 재현).
## 벽 · 물 위 자리는 건너뜀. 움직이지 않는 적(Enemy.prop)이라 공격이 그대로 맞고, 자동 조준 · 아군 · 접촉에서는 빠짐
func _spawn_props() -> void:
	var P: Dictionary = Stage1.PROPS
	var spots: Array[Vector2] = []
	for v in P.road:
		spots.append(v)
	for c in camps:
		var R := camp_rect(c).grow(float(P.camp_out))
		for q in [R.position, Vector2(R.end.x, R.position.y), Vector2(R.position.x, R.end.y), R.end]:
			spots.append(q)
	for v in P.village:
		spots.append(v)
	var i := 0
	for at in spots:
		i += 1
		if randf() < float(P.skip) or hit_obs(at, 16) or at.x < 24 or at.x > W - 24:
			continue
		var e := spawn("cart" if i % 2 == 0 else "flags", at, 1.0)
		e.max_hp = float(P.hp)
		e.hp = e.max_hp
		e.xp_mul = 0.0


## 부서진 물체가 떨어뜨리는 것(PROPS 확률): 고기만두 · 폭탄 · 자석 · 경험 구슬
func _prop_loot(e: Enemy) -> void:
	var P: Dictionary = Stage1.PROPS
	var r := randf()
	if r < float(P.bun):
		drops.append({"k": "bun", "pos": e.position, "src": "물체"})
	elif r < float(P.bun) + float(P.bomb):
		drops.append({"k": "bomb", "pos": e.position})
	elif r < float(P.bun) + float(P.bomb) + float(P.magnet):
		drops.append({"k": "magnet", "pos": e.position})
	else:
		drop_orb(e.position, float(P.xp_v))
	add_fx({"k": "puff", "pos": e.position, "t": 0.3})


## 폭탄(D-216 2단계): 화면 안 졸병은 모두 쓰러지고, 장수급 · 건물은 최대 체력 × bomb_elite 피해(물체 · 보호막은 그대로)
func _bomb_go() -> void:
	var P: Dictionary = Stage1.PROPS
	var V := view.grow(20)
	var n := 0
	var i := 0
	while i < enemies.size():
		var e := enemies[i]
		i += 1
		if e.dead or e.shield or e.prop or not V.has_point(e.position):
			continue
		if e.is_lead() or e.building or e.boss:
			hurt_enemy(e, e.max_hp * float(P.bomb_elite))
		else:
			hurt_enemy(e, e.hp + 1.0)
			n += 1
	add_fx({"k": "ring", "pos": hero.position, "t": 0.6, "r": 260.0, "c": Color("ff9a4a")})
	shake = maxf(shake, 0.4)
	hit_stop = maxf(hit_stop, 0.08)
	Sound.play("slam", 0.5)
	banner("폭탄!", "화면 안 황건 %d명을 쓸어버렸어요" % n)


## 보스 울타리(D-216 1단계, Survivor.io 방식). 대군 부장 · 정원지가 장수 ARENA.trigger 안에 오면 warn초 예고 → 울타리 → 부장이 쓰러지면 사라짐
func _arena_tick(dt: float) -> void:
	var A: Dictionary = Stage1.ARENA
	if arena.is_empty():
		if won or state != "play":
			return
		for L in _arena_cands():
			if L.arena_done or hero.position.distance_to(L.position) > float(A.trigger):
				continue
			# 장수와 적장 사이가 벽 · 물로 막혀 있으면 아직 열지 않음(담을 사이에 두고 갇히면 서로 못 닿음)
			if flow.ver != obs_ver:
				flow.build(obs, W, H, obs_ver)
			if not flow.clear(hero.position, L.position):
				continue
			L.arena_done = true
			note("일기토 예고 · %s" % L.ename)
			arena = {"st": "warn", "t": float(A.warn), "lead": L, "c": hero.position, "r": float(A.r), "t0": t, "beat": 0.0}
			banner("%s%s 일기토를 청해요!" % [L.ename, jo(L.ename, "이", "가")], "곧 울타리가 쳐져요 — 1:1로 쓰러뜨려야 나갈 수 있어요")
			Sound.play("alert", 0.5)
			break
		return
	var L: Enemy = arena.lead
	if not Unit.alive(L):
		_arena_off()
		return
	if arena.st == "warn":
		arena.t = float(arena.t) - dt
		arena.c = _arena_center(L)
		# 북소리(북 소리 파일이 없어 내려찍기 소리를 낮게): 0.5초마다 둥
		arena.beat = float(arena.beat) - dt
		if float(arena.beat) <= 0:
			arena.beat = 0.5
			Sound.play("slam", 0.3, 0.0)
		if float(arena.t) <= 0:
			_arena_on()
		return
	_arena_hold()


## 일기토 중인가(울타리가 서 있음): 밖의 적 · 아군은 멈춰 지켜보고(움직임 · 공격 · 피해 없음), 판의 시간표 · 생성도 멈춤
func duel() -> bool:
	return not arena.is_empty() and arena.st == "on"


## 울타리 후보: 살아 있는 대군 부장 · 정원지
func _arena_cands() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for u in army:
		if u.spawned and Unit.alive(u.lead):
			out.append(u.lead)
	if Unit.alive(cyz):
		out.append(cyz)
	return out


## 울타리 중심: 장수 자리(부장이 멀면 둘의 가운데 — 둘 다 안에 들게). 벽 · 물이면 걸을 수 있는 가까운 곳, 원이 지도 밖으로 크게 나가지 않게
func _arena_center(L: Enemy) -> Vector2:
	var R := float(Stage1.ARENA.r)
	var c := hero.position
	if hero.position.distance_to(L.position) > R - 50:
		c = hero.position.lerp(L.position, 0.5)
	if hit_obs(c, 30):
		var found := false
		for rr in range(20, 220, 20):
			for k in 12:
				var q := c + Vector2.from_angle(k * TAU / 12) * rr
				if not hit_obs(q, 30):
					c = q
					found = true
					break
			if found:
				break
	return Vector2(clampf(c.x, R * 0.55, W - R * 0.55), clampf(c.y, R + 10, H - R - 10))


## 울타리가 섬: 안의 졸병은 부장 호위 ARENA.keep명만 남기고 cull 비율만큼 사라지고 나머지는 밖으로. 그 부대의 밖 병사는 부장을 떠나 본진으로 진군
func _arena_on() -> void:
	var A: Dictionary = Stage1.ARENA
	var L: Enemy = arena.lead
	var c: Vector2 = arena.c
	var R: float = arena.r
	arena.st = "on"
	arena.t0 = t
	# 울타리 안에선 부장이 진군하지 않고 장수에게 덤빔(전엔 본진 쪽 울타리에 붙어 서 있었음)
	L.aggro = 99999.0
	# 장수가 원 밖이면 안으로(예고 동안 원이 장수를 따라다녀서 거의 없음)
	if hero.position.distance_to(c) > R - hero.r:
		hero.position = c + (hero.position - c).normalized() * (R - hero.r - 4)
	var kept := 0
	for e in enemies:
		if e.dead or e.building:
			continue
		var d := e.position.distance_to(c)
		if e == L:
			e.arena_side = 1
			if d > R - e.r:
				e.position = c + (e.position - c).normalized() * (R - e.r - 4)
			continue
		if e.guard_of == L:
			# 부장 곁을 따르던 병사: 부장을 두고(일기토가 끝나면) 본진으로 진군
			e.guard_of = null
			e.has_post = false
			e.goal_home = true
			e.aggro = 200
		if d >= R + e.r:
			e.arena_side = -1
			continue
		if e.army_unit == L.army_unit and not e.elite and kept < int(A.keep):
			kept += 1
			e.arena_side = 1
			continue
		e.arena_side = -1
		# 지우는 건 보통 졸병만 — 진영장 · 다른 장수급 · 습격대 장수는 지우지 않고 밖으로(전엔 진영장도 지워져 그 진영을 영영 점령 못 했음)
		if not e.elite and not e.boss and randf() < float(A.cull):
			e.dead = true
			add_fx({"k": "puff", "pos": e.position, "t": 0.25})
		else:
			e.position = _arena_out_spot(c, R + e.r + 10, e.position)
	# 일기토: 아군도 모두 울타리 밖에서 지켜봄
	for a in allies:
		a.arena_side = -1
		var ad := a.position - c
		if ad.length() < R + a.r:
			a.position = c + (ad.normalized() if ad.length() > 0.01 else Vector2(0, 1)) * (R + a.r + 10)
	note("일기토 · %s" % L.ename)
	banner("일기토!", "%s%s 쓰러뜨려야 울타리가 걷혀요" % [L.ename, eul(L.ename)])
	add_fx({"k": "ring", "pos": c, "t": 0.5, "r": R, "c": Color("e8c060")})
	shake = maxf(shake, 0.25)
	Sound.play("slam", 0.5)


## 울타리 밖으로 밀 자리: 원 둘레(반지름 rr)에서 원래 방향에 가까운 걸을 수 있는 곳(벽 · 물 너머 금지). 없으면 그대로
func _arena_out_spot(c: Vector2, rr: float, from: Vector2) -> Vector2:
	var a0 := (from - c).angle() if from != c else 0.0
	for k in 13:
		var a := a0 + (k + 1) / 2 * 0.24 * (1.0 if k % 2 == 0 else -1.0)
		var q := c + Vector2.from_angle(a) * rr
		if q.x > 20 and q.x < W - 20 and q.y > 20 and q.y < H - 20 and not hit_obs(q, 14) and flow.clear(c, q):
			return q
	return from


## 울타리가 서 있는 동안: 안(1)은 못 나가고, 밖(-1) · 새로 나온 것(0)은 못 들어옴. 장수는 늘 안
func _arena_hold() -> void:
	var c: Vector2 = arena.c
	var R: float = arena.r
	var dh := hero.position - c
	if dh.length() > R - hero.r:
		hero.position = c + dh.normalized() * (R - hero.r)
	for e in enemies:
		if e.dead or e.building:
			continue
		_arena_keep(e, c, R)
	for a in allies:
		if not a.dead:
			_arena_keep(a, c, R)


func _arena_keep(u: Unit, c: Vector2, R: float) -> void:
	var d := u.position - c
	var dl := d.length()
	if u.arena_side > 0:
		if dl > R - u.r:
			u.position = c + d / maxf(dl, 0.01) * (R - u.r)
	elif dl < R + u.r:
		u.arena_side = -1
		u.position = c + (d / dl if dl > 0.01 else Vector2(0, 1)) * (R + u.r)


func _arena_off() -> void:
	var L: Enemy = arena.lead
	if arena.st == "on":
		var unit := "정원지"
		if L != null and is_instance_valid(L) and L.army_unit >= 0 and L != cyz:
			unit = String(Stage1.ARMY.units[L.army_unit].n)
		var ln: String = L.ename if L != null and is_instance_valid(L) else "?"
		arena_log.append({"n": unit, "ln": ln, "t0": arena.t0, "t1": t, "d": (arena.c as Vector2).distance_to(home_pos)})
		note("일기토 끝")
	arena = {}
	for e in enemies:
		e.arena_side = 0
	for a in allies:
		a.arena_side = 0


## 길목의 황건 부대(가까이 가면 덤빔) · 진영 병력
func _spawn_squads() -> void:
	for s in Stage1.SQUADS:
		var n := roundi(float(s[2]) * 1.5)
		var y: float = s[1]
		for i in n:
			var k := "ytb"
			if i == 0 and n >= 10:
				k = "ytdash"
			elif y < 2300 and i % 8 == 3:
				k = "ytarch"
			elif y < 1400 and i % 6 == 1:
				k = "ytbig"
			var at := Vector2(clampf(float(s[0]) + randf_range(-55, 55), 30, W - 30), y + randf_range(-45, 45))
			var e := spawn(k, at, s[3])
			e.set_post(at)
			e.aggro = 230
	# 진영(D-205): 부술 목표(수비탑 · 감옥 · 군량 더미 — 2026-10-14) · 진영장(처음부터 진영 안, 목표가 남아 있는 동안 보호막) · 처음 호위병
	var L: Dictionary = Stage1.LEAD
	for c in camps:
		var i := 0
		for tp in c.towers:
			var tw := {"id": "%s:%d" % [c.id, i], "pos": tp, "alive": true}
			c.tws.append(tw)
			_spawn_obj(c, tw)
			i += 1
		var ld := spawn(c.lk, c.pos, float(c.mul) * float(c.lm))
		ld.make_lead(c, camp_rect(c))
		ld.shield = not c.tws.is_empty()
		c.lead = ld
		c.call_t = randf_range(0.5, 2.0)
		for j in int(L.start):
			_guard(c, float(c.mul))


## 진영의 부술 목표 하나(수비탑 · 감옥 · 군량 더미 — Stage1.CAMPS[].obj)
func _spawn_obj(c: Dictionary, tw: Dictionary) -> void:
	var kind: String = c.get("obj", "tower")
	var u: Enemy
	if kind == "tower":
		var T: Dictionary = Stage1.TOWER
		u = spawn("tower", tw.pos, float(T.hp) * float(c.mul))
		u.r = float(T.r)
	else:
		var O: Dictionary = Stage1.OBJ[kind]
		u = spawn(kind, tw.pos, float(O.hp) * float(c.mul))
		u.r = float(O.r)
	u.camp_id = c.id
	u.tower_id = tw.id


## 진영 목표 이름(알림 · 목표 글): 수비탑 · 감옥 · 군량 더미
static func obj_name(c: Dictionary) -> String:
	return String(Stage1.OBJ[c.get("obj", "tower")].n)


## 감옥에서 풀려난 의용병이 본진에 닿음: 본진 수비대가 되고 유비 체력 회복
func captive_home(a: Ally) -> void:
	captive_safe += 1
	if Unit.alive(liubei):
		liubei.hp = minf(liubei.max_hp, liubei.hp + liubei.max_hp * float(Stage1.OBJ.cage.heal))
	add_fx({"k": "ring", "pos": a.position, "t": 0.4, "r": 24.0, "c": Color("8fe08a")})
	if captive_safe == 1 or captive_safe % 3 == 0:
		banner("의용병이 본진에 닿았어요", "본진 수비대가 늘고 유비가 기운을 차려요")


## 군량 더미(2026-10-14): 첫 더미를 부순 뒤 limit초가 지나도 남아 있으면 부순 더미가 다시 쌓임
func _granary_tick(dt: float) -> void:
	for c in camps:
		if c.cap or float(c.burn_t) < 0:
			continue
		c.burn_t = float(c.burn_t) - dt
		if float(c.burn_t) > 0:
			continue
		c.burn_t = -1.0
		for tw in c.tws:
			if not tw.alive:
				tw.alive = true
				_spawn_obj(c, tw)
		if Unit.alive(c.lead):
			c.lead.shield = true
		note("%s 군량 다시 쌓임" % c.n)
		banner("군량이 다시 쌓였어요!", "%s — 첫 더미를 부순 뒤 %d초 안에 모두 불태워야 해요" % [c.n, int(Stage1.OBJ.granary.limit)])
		Sound.play("alert", 0.4)


## 화면 바로 바깥 둘레에서 a 방향의 빈 곳(안 되면 조금씩 돌려 봄). 장수에게 걸어올 수 없는 곳(닫힌 장각 본진 안 · 닫힌 관문 너머)은 뺀다
## — 웹판은 거기에도 생겨 벽에 줄지어 붙어 있었음. 못 찾으면 Vector2.INF.
func ring_pos(a: float) -> Vector2:
	var p := hero.position
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var f := flow.field("p", p, t, 0.2)
	for da in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05]:
		var rr := view.size.length() / 2 + randf_range(20, 70)
		var at := Vector2(clampf(p.x + cos(a + da) * rr, 24, W - 24), clampf(p.y + sin(a + da) * rr, 24, H - 24))
		if not hit_obs(at, 16) and at.distance_to(p) > 200 and flow.reach(f, flow.cell_of(at)):
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
	# 사각형들의 세로 범위를 겹치는 것끼리 합친 띠
	var ys: Array = []
	for rc in obs_rects:
		ys.append([rc.position.y, rc.end.y])
	ys.sort_custom(func(a, c): return a[0] < c[0])
	obs_bands.clear()
	for y in ys:
		var n := obs_bands.size()
		if n > 0 and float(y[0]) <= obs_bands[n - 1]:
			obs_bands[n - 1] = maxf(obs_bands[n - 1], y[1])
		else:
			obs_bands.append(y[0])
			obs_bands.append(y[1])
	obs_ver += 1


## 벽·물에서 밀어내고 지도 밖으로 못 나가게.
## 벽 · 물 띠(obs_bands)에 걸칠 때만 사각형을 하나씩 봄 — 안 걸치면 사각형마다 건너뛰어 그대로였음(D-198, 결과는 같음)
func push_out(u: Unit) -> void:
	Perf.begin(&"충돌")
	_push_out_impl(u)
	Perf.end()


func _push_out_impl(u: Unit) -> void:
	var r := u.r
	var p := u.position
	var i := 0
	while i < obs_bands.size():
		if p.y + r >= obs_bands[i] and p.y - r <= obs_bands[i + 1]:
			_push_out_rects(u)
			p = u.position
			break
		i += 2
	var q := p.clamp(Vector2(r + 4, r + 4), Vector2(W - r - 4, H - r - 4))
	if q != p:
		u.position = q


func _push_out_rects(u: Unit) -> void:
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
	Perf.begin(&"길찾기")
	var p := _path_for_impl(u, key, aim)
	Perf.end()
	return p


func _path_for_impl(u: Unit, key: String, aim: Vector2) -> Vector2:
	if key == "" or u.position.distance_to(aim) < 40:
		return aim
	if u.pth_t > t and u.pth_k == key:
		return u.pth if u.has_pth else aim
	u.pth_t = t + 0.18 + randf() * 0.08
	u.pth_k = key
	if flow.ver != obs_ver:
		flow.build(obs, W, H, obs_ver)
	var f := flow.field(key, aim, t, 0.2 if key == "p" else (0.5 if key == "lb" else 0.0))
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
	# 보스 울타리(D-216): 예고 · 울타리 중엔 그 부장(울타리 밖으로는 못 나감)
	if not arena.is_empty() and Unit.alive(arena.lead):
		var AL: Enemy = arena.lead
		return {"pos": AL.position, "n": "일기토 — %s 격파%s" % [AL.ename, " (곧 울타리)" if arena.st == "warn" else ""], "warn": true}
	# 유비가 절반 아래로 다쳤고 둘레에 적이 있으면(D-208 — 쓰러지면 짐)
	if Unit.alive(liubei) and liubei.hp < liubei.max_hp * 0.5:
		for e in enemies:
			if not e.dead and not e.building and e.position.distance_to(liubei.position) < 200:
				return {"pos": liubei.position, "n": "유비를 지켜요 (유비 %d%%)" % ceili(liubei.hp / liubei.max_hp * 100), "warn": true}
	if home_hp < home_max * 0.4:
		for e in enemies:
			if not e.dead and e.goal_home and e.position.distance_to(home_pos) < 400:
				return {"pos": home_pos, "n": "본진 지키기 (본진 %d%%)" % ceili(home_hp / home_max * 100), "warn": true}
	if vil_st == "raid":
		var V: Dictionary = Stage1.VILLAGE
		var dp: Vector2 = deng.position if Unit.alive(deng) else V.pos
		var who := String(V.ln).get_slice(" ", String(V.ln).get_slice_count(" ") - 1)
		return {"pos": dp, "n": "%s 구하기 — %s 격파 (남은 %d초)" % [V.n, who, ceili(vil_t)], "warn": true}
	var best := focus_camp()
	if not best.is_empty():
		var total: int = best.tws.size()
		var left := towers_left(best)
		if left == 0:
			var lp: Vector2 = best.lead.position if Unit.alive(best.lead) else best.pos
			return {"pos": lp, "n": "%s · %s 격파" % [best.n, best.ln]}
		# 수비탑이 남았으면 가까운 탑부터(진영장은 보호 중, D-205)
		var tp: Vector2 = best.pos
		var bd2 := INF
		for tw in best.tws:
			if tw.alive and hero.position.distance_to(tw.pos) < bd2:
				bd2 = hero.position.distance_to(tw.pos)
				tp = tw.pos
		var O: Dictionary = Stage1.OBJ[best.get("obj", "tower")]
		var tm := " (남은 %d초)" % ceili(float(best.burn_t)) if float(best.burn_t) >= 0 else ""
		return {"pos": tp, "n": "%s · %s %s %d/%d%s" % [best.n, O.n, O.verb, total - left, total, tm], "warn": tm != ""}
	# 정원지의 대군(D-214): 본진에 가장 가까운 부대의 대장 — 아직 아무 부대도 안 나왔으면 관문 앞
	var A: Dictionary = Stage1.ARMY
	var gp := Vector2(float(A.road_x), float(A.y0))
	if not cyz_dead:
		var F := army_front()
		# 부대가 본진에서 ARMY.engage px 밖이고 장수가 곁(400px)에 없으면 아직 가리키지 않음(2026-10-13 — 관문에서 갓 나온 부대를 곧바로 쫓지 않게)
		var far := not F.is_empty() and float(F.d) > float(A.engage) and hero.position.distance_to(F.head.position) > 400
		if not F.is_empty() and not far:
			var U: Dictionary = A.units[F.u.i]
			var head: Enemy = F.head
			var who := "정원지" if head == cyz else String(U.ln).get_slice(" ", String(U.ln).get_slice_count(" ") - 1)
			return {"pos": head.position, "n": "%s · %s 격파%s (본진까지 %d)" % [U.n, who, " (분노)" if head == cyz and cyz_phase == 2 else "", int(F.d)],
				"warn": float(F.d) < float(A.danger)}
		# 부대와 부대 사이 · 부대가 아직 멀 때(2026-10-13): 관문 앞을 가리키지 않음(전엔 관문 앞을 가리켜 갓 나온 부대를 늘 그 자리에서 잡았음).
		# 가리킬 곳 없이(between) 장수가 고른 곳에서 싸우다, 부대가 내려와 engage 안에 들거나 장수 곁에 오면 그 부대를 가리킴.
		# (본진 쪽 · 본진으로 가는 황건을 가리켜 봤더니 장수를 쫓는 들판 무리가 본진까지 따라와 유비가 쓰러짐 — 봇 각 20판)
		for u in army:
			if far or not u.spawned:
				var eta := "대군 %s%s 내려와요 (본진까지 %d)" % [A.units[F.u.i].n, jo(A.units[F.u.i].n, "이", "가"), int(F.d)] if far \
					else "대군 %s 출진까지 %s" % [A.units[u.i].n, mmss(_unit_eta(u))]
				return {"pos": hero.position, "n": eta, "between": true}
		return {"pos": gp, "n": "정원지 대군"}
	if siege != null:
		return siege.target()
	return {"pos": cyz.position if cyz != null else gp, "n": "탁현 싸움 승리"}


## 진군 부대(D-180)가 갈 곳과 길찾기 키
func march_goal(from: Vector2) -> Dictionary:
	if vil_st == "raid" and Unit.alive(deng):
		return {"key": "m_deng", "pos": deng.position}
	var c := focus_camp()
	if not c.is_empty():
		var best := {}
		var bd := INF
		for tw in c.tws:
			if tw.alive and from.distance_to(tw.pos) < bd:
				bd = from.distance_to(tw.pos)
				best = tw
		if not best.is_empty():
			return {"key": "m_" + String(best.id), "pos": best.pos}
		return {"key": "m_lead_" + c.id, "pos": c.lead.position if Unit.alive(c.lead) else c.pos}
	if not cyz_dead or siege == null:
		# 정원지의 대군(D-214): 본진에 가장 가까운 부대의 대장
		var F := army_front()
		if not F.is_empty():
			return {"key": "m_army_%d" % F.u.i, "pos": F.head.position}
		return {"key": "m_gate", "pos": Vector2(float(Stage1.ARMY.road_x), float(Stage1.ARMY.y0))}
	return siege.march()


# ─────────── 화면 ───────────

func _place_camera() -> void:
	var vs := get_viewport_rect().size
	# 장수를 화면 위에서 60% 자리에(앞쪽이 더 보이게)
	var c := hero.position + Vector2(0, -vs.y * 0.1)
	# 보스 울타리(D-216): 울타리가 서 있는 동안 카메라가 울타리 중심으로 옮겨 원 전체가 보이게(부드럽게)
	var want := 1.0 if not arena.is_empty() and arena.st == "on" else 0.0
	cam_k = move_toward(cam_k, want, get_process_delta_time() * 2.5)
	if cam_k > 0 and not arena.is_empty():
		c = c.lerp(arena.c, cam_k)
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
