class_name Hero
extends Unit
## 장수(플레이어). 끌어서 이동만 하면 대표 무기가 자동으로 날아가고(D-171: 손에는 무기를 그리지 않음),
## 맞힌 수만큼 연격 수가 쌓이며, 게이지가 차면 무쌍(웹판 musouGo · fieldHurt).
## 그림 · 능력치 · 기본 공격 · 특성 · 무쌍은 HeroData에서 온다.

## 연격 단계(1: 흰 → 2: 초록(50) → 3: 금(150))의 색 [바깥, 안]과 피해 배율
const CB_COL := [[], [Color("fffaf0"), Color("a89a80")], [Color("d8ffe0"), Color("4a8a5a")], [Color("fff2b0"), Color("e2a83a")]]
const CB_MUL := [1.0, 1.0, 1.15, 1.3]
const CB_MILES := [50, 100, 150, 300, 500, 1000, 2000]
const GOLD := [Color("fff2b0"), Color("e2a83a")]

var data: HeroData
var atk := 10.0
var spd := 150.0
var inv := 0.0
var stun := 0.0
var face := Vector2(0, -1)
var vel := Vector2.ZERO
var still := 0.0
# 기본 공격 · 연격 수
var cb_t := 0.3
var cb_idle := 9.0
var cb_n := 0
var cb_max := 0
var cb_mile := 0
var cb_pop_t := 0.0
var cb_pop_text := ""
var cb_pop_col := Color.WHITE
# 무쌍
var mg := 0.0
var musou_t := 0.0
var musou_k := 0.0
var orb_a := 0.0

var _over: Node2D


func setup(b: Battle, d: HeroData, at: Vector2) -> void:
	battle = b
	data = d
	position = at
	last_pos = at
	r = d.radius
	max_hp = d.max_hp
	hp = max_hp
	atk = d.attack
	spd = d.move_speed
	tex = Sprites.sheet(d.sprite_key)
	tint = Color("3f7a3a")
	face_dir = "up"
	# 체력 막대는 모든 인물 위에 그린다(웹판 fieldOver).
	_over = Node2D.new()
	_over.z_index = 1
	add_child(_over)
	_over.draw.connect(_draw_over)


func cb_stage() -> int:
	return 3 if cb_n >= 150 else (2 if cb_n >= 50 else 1)


## 연격 수: 맞히면 쌓이고, 2.2초 못 맞히면 끊김, 맞으면 절반. gauge = 한 대당 무쌍 게이지.
func cb_add(n: int, gauge: float) -> void:
	if n <= 0:
		return
	cb_n += n
	cb_idle = 0.0
	if gauge > 0:
		mg = minf(100.0, mg + n * gauge)
	cb_max = maxi(cb_max, cb_n)
	var mil := _mile_of(cb_n)
	if mil > cb_mile:
		cb_mile = mil
		cb_pop_t = 1.3
		cb_pop_text = "%d 연격!" % mil
		cb_pop_col = CB_COL[cb_stage()][1]


func _mile_of(n: int) -> int:
	var m := 0
	for v in CB_MILES:
		if n >= v:
			m = v
	return m


## 기본 공격(D-171): 가장 가까운 적 쪽으로 대표 무기를 날림. 연격 단계마다 세지고 · 빨라지고 · 커짐.
## 맞힌 것은 Battle._tick_blades가 처리(피해 · 밀침 · 멈칫 · 연격 수).
func attack_tick(dt: float) -> void:
	cb_t -= dt
	cb_idle += dt
	if cb_idle > 2.2 and cb_n > 0:
		cb_n = 0
		cb_mile = 0
	var A := data.basic
	if cb_t > 0 or A == null:
		return
	var tg := battle.nearest_enemy(position, A.seek)
	if tg == null:
		cb_t = 0.06
		return
	var st := cb_stage()
	var a := (tg.position - position).angle()
	face = Vector2.from_angle(a)
	var dmg: float = atk * A.mult * CB_MUL[st]
	for i in A.count:
		battle.launch_blade(position, a + (i - (A.count - 1) / 2.0) * A.spread, A, dmg, 1.0 + 0.06 * (st - 1), CB_COL[st])
	cb_t = A.cooldown / (1.0 + 0.1 * (st - 1))


func musou_go() -> void:
	if battle.state != "play" or mg < 100 or musou_t > 0 or stun > 0:
		return
	mg = 0.0
	musou_t = data.musou_time
	musou_k = 0.0
	battle.shake = 0.2
	battle.banner(data.musou_name + "!", "")


## 무쌍: 무적으로 돌며 베기 → 끝에 큰 폭발
func musou_tick(dt: float) -> void:
	musou_t -= dt
	musou_k -= dt
	inv = maxf(inv, 0.15)
	if musou_k <= 0 and musou_t > 0.3:
		musou_k = data.musou_tick
		orb_a += 1.3
		var n := battle.swing(position, orb_a, TAU + 0.1, data.musou_radius, atk * data.musou_mult, GOLD, false, 0)
		cb_add(n, 0)
		battle.push_away(position, 130, 8)
		battle.shake = maxf(battle.shake, 0.08)
	if musou_t <= 0:
		var n := battle.blast(position, data.musou_blast_radius, atk * data.musou_blast_mult)
		cb_add(n, 0)
		battle.add_fx({"k": "ring", "pos": position, "t": 0.5, "r": 220.0, "c": Color("ffd34a")})
		battle.add_fx({"k": "ring", "pos": position, "t": 0.35, "r": 140.0, "c": Color("fff2b0")})
		battle.shake = 0.4
		battle.hit_stop = 0.08


## 맞음: 무쌍 중엔 무적, 맞으면 무쌍 게이지가 차고 연격 수는 절반.
func hurt(d: float) -> void:
	if inv > 0 or battle.state != "play":
		return
	if musou_t > 0:
		return
	d *= 1.0 - data.damage_reduction
	mg = minf(100.0, mg + d * 0.35)
	if cb_n > 0:
		cb_n = cb_n / 2
		cb_mile = _mile_of(cb_n)
	hp -= d
	inv = 0.6
	battle.shake = 0.22
	battle.add_fx({"k": "num", "pos": position + Vector2(0, -20), "t": 0.7, "v": "-%d" % roundi(d), "c": Color("ff9a8a")})
	if hp <= 0:
		hp = 0
		battle.finish(false, "hero")


func heal(v: float) -> void:
	var b0 := hp
	hp = minf(max_hp, hp + v)
	if hp > b0:
		battle.add_fx({"k": "num", "pos": position + Vector2(0, -18), "t": 0.7, "v": "+%d" % roundi(hp - b0), "c": Color("8fe08a")})


func tick_timers(dt: float) -> void:
	inv = maxf(0.0, inv - dt)
	stun = maxf(0.0, stun - dt)
	cb_pop_t = maxf(0.0, cb_pop_t - dt)


func _process(_dt: float) -> void:
	queue_redraw()
	_over.queue_redraw()


func _draw() -> void:
	if musou_t > 0:
		draw_circle(Vector2.ZERO, 30, Color(1.0, 0.82, 0.35, 0.25 + 0.15 * sin(battle.t * 30)))
	var blink := inv > 0 and musou_t <= 0 and int(floor(inv * 20)) % 2 == 1
	face_dir = Sprites.dir_of(face)
	draw_body(face_dir, Sprites.walk_step(still == 0.0, battle.t, 10), data.sprite_size, 0.35 if blink else 1.0, 0.0, data.display_name.left(1))


func _draw_over() -> void:
	var bw := 30.0
	var frac := hp / max_hp
	_over.draw_rect(Rect2(-bw / 2, 18, bw, 4), Color("3a3024"))
	_over.draw_rect(Rect2(-bw / 2, 18, bw * frac, 4), Color("d9705e") if frac < 0.3 else Color("6fae6a"))
