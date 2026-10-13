class_name Companion
extends Ally
## 스토리 동료 장수(D-212 · D-215): 장마다 정해진 아군 장수. 장수를 호위하지 않고 자기 목표(goal — 사건 속 적 장수)로 가서 싸움.
## 기본 공격은 장수 데이터의 대표 무기(HeroData.basic)가 날아감 — 출진 장수와 같은 틀(Battle.launch_blade, 주인 = 이 동료).
## 장수급은 체력 C.floor 아래로 못 깎음(마무리는 출진 장수, Battle._tick_blades). 일이 끝나거나 체력이 C.retreat 아래면 물러남(걸어 나가 사라짐).

var hd: HeroData
var C: Dictionary
var goal: Enemy = null
var leaving := false
var why := ""
## 처치 수 · 목표에게 준 피해(봇 출력용)
var kills := 0
var dealt := 0.0
var bcd := 0.5


func setup_companion(b: Battle, data: HeroData, conf: Dictionary, at: Vector2, target: Enemy) -> void:
	battle = b
	hd = data
	C = conf
	k = data.id
	def = {"n": data.display_name, "c": "6a9ad8", "cd": data.basic.cooldown if data.basic != null else 1.0, "spr": data.sprite_key}
	mode = "companion"
	anchor = ""
	position = at
	last_pos = at
	r = data.radius
	max_hp = data.max_hp * float(conf.hp)
	hp = max_hp
	atk = data.attack * float(conf.atk)
	spd = data.move_speed
	size = data.sprite_size
	slot = randf() * TAU
	tint = Color(def.c)
	tex = Sprites.sheet(data.sprite_key)
	goal = target


## 물러남: 다시 싸우지 않고 C.exit 쪽으로 걸어가 사라짐
func leave(reason: String) -> void:
	if leaving or dead:
		return
	leaving = true
	why = reason
	tg = null
	battle.companion_left(self)


func tick(dt: float) -> void:
	var b := battle
	hit_cd -= dt
	bcd -= dt
	scan -= dt
	last_pos = position
	if leaving:
		var ex: Vector2 = C.exit
		var m := ex - position
		if m.length() < 24:
			dead = true
			return
		position += m.normalized() * minf(m.length(), spd * 1.2 * dt)
		b.push_out(self)
		return
	if goal != null and not Unit.alive(goal):
		goal = null
	# 노리는 적: 목표(장수급)가 우선, 없으면 가까운 적
	if scan <= 0:
		scan = 0.3
		tg = goal if goal != null else b.nearest_enemy(position, 200.0)
	if tg != null and not Unit.alive(tg):
		tg = null
	# 목표에 붙어 섬(목표 · 둘레 적이 이 동료와 싸우게 — Battle._engage_tick)
	if tg != null:
		var reach := r + tg.r + 8
		var d := tg.position.distance_to(position)
		if d > reach:
			var to := b.path_for(self, "cmp", tg.position) if d > 60 else tg.position
			var m := to - position
			if m.length() > 0.01:
				position += m.normalized() * minf(m.length(), spd * dt)
			b.push_out(self)
	# 기본 공격: 대표 무기를 날림(장수와 달리 연격 단계 · 레벨 없음)
	var A := hd.basic
	if A != null and bcd <= 0:
		var aim: Enemy = tg if tg != null and tg.position.distance_to(position) <= A.seek else b.nearest_enemy(position, A.seek)
		if aim != null:
			var a := (aim.position - position).angle()
			var col: Array = [A.tint, A.tint2] if A.tint.a > 0 else Hero.CB_COL[1]
			for i in A.count:
				b.launch_blade(position, a + (i - (A.count - 1) / 2.0) * A.spread, A, atk * A.mult, 1.0, col, self)
			bcd = A.cooldown
		else:
			bcd = 0.1
	# 붙은 황건에게 맞음(받는 피해 × C.take)
	if hit_cd <= 0:
		var hit := b.touching_enemy(position, r + 3)
		if hit != null:
			hp -= hit.touch * float(C.take)
			hit_cd = 0.6
			flash = 0.1
	flash = maxf(0.0, flash - dt)
	if hp <= max_hp * float(C.retreat):
		leave("hurt")


func _draw_impl() -> void:
	var b := battle
	if b == null:
		return
	draw_oval(Vector2(0, r * 0.9), r * 1.2, r * 0.5, Color(0.5, 0.75, 1.0, 0.95), false, 2)
	var moved := anim_moved()
	var mv := moved.length() > 0.2
	if mv:
		face_dir = Sprites.dir_of(moved)
	elif Unit.alive(tg):
		face_dir = Sprites.dir_of(tg.position - position)
	draw_body(face_dir, Sprites.walk_step(mv, b.t + slot, 7), size, 0.6 if leaving else 1.0, 0.0, hd.display_name.left(1))
	draw_bar(0, -r - 10, 30.0, 3, hp / max_hp, Color("6a9ad8"))
	draw_label(hd.display_name, Vector2(0, -r - 18), Color("cfe2f4"))
