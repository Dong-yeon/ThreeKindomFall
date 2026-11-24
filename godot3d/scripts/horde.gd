extends Node3D
## 적 떼(황건적): 노드 없이 배열로 들고, 종류 × walk 4프레임 정지 메시를 MultiMesh로 한 번에 그린다(D-275).
## 뼈 있는 모델은 MultiMesh로 못 그리므로, 걸음 위상에 따라 프레임 메시를 바꿔 끼운다.
## D-276: 적 체력 · 맞으면 밀려남 · 장수에게 붙으면 창 찌르기(앞으로 튀어나옴 → 맞으면 피해).
## D-281: 맞히는 모양은 무기마다(휘두르기 hit_arc · 찌르기 hit_line · 날아가는 것 hit_circle).
## D-287: 맞음 대기는 출처(채널)마다 따로.
## D-288: 잡병 4종(data/enemies.gd — 졸병 · 궁병 · 돌격병 · 방패병), 궁병 화살, 진영에서 나옴(spawn_points), 맵 경계(bounds).
## D-289: 적장(정예 · 보스, scripts/foe/foe.gd)도 targets에 넣으면 장수의 모든 공격 · nearest가 함께 봄.

const FRAMES := 4
const SPEED := 2.3
const RADIUS := 0.38          # 서로 밀어내는 반지름
const CELL := 1.0             # 공간 격자 칸(밀어내기 이웃 찾기)
const GRID := 96              # 장수 둘레 96×96칸만 격자에 넣음(밖은 밀어내기 생략)
const STEP_HZ := 2.0          # 걸음 주기 0.5초
const HP := 3.0               # 칼날 세 번
const HIT_CD := 0.3           # 같은 출처에 다시 맞기까지
const STOP_D := 0.9           # 장수 앞에서 멈추는 거리
const ATK_RANGE := 1.25       # 이 안에 들면 찌를 준비
const LUNGE_T := 0.18         # 찌르기 동작(초)
const LUNGE_D := 0.35         # 찌를 때 앞으로 튀어나오는 거리
const HIT_RANGE := 1.4        # 찌르는 순간 이 안이면 맞음
const ARROW_CAP := 256
# 맞음 대기 채널(D-287) — 한 배열에 [적 i × N_CH + ch]
const CH_WEAPON := 0          # 대표 무기(시작 초식)
const CH_ULT := 1             # 절기 · 경공 부딪힘
const CH_PASSIVE := 2         # 고유 심법이 내는 공격(청룡 기운 · 부적, D-333 — 예전 의용군 CH_ALLY 자리)
const CH_TACTIC := 3          # 추가 초식 — 슬롯마다 3~7(기본 3칸 + 과제 칸 + 와룡 칸, D-292)
const CH_RETURN := 8          # 돌아오는 무기(쌍고검 회선 — 가는 길과 같은 적을 또 맞힘, D-293)
const N_CH := 9
var slow_zones: Array = []    # 느려지는 자리 [{c: Vector2, r2, f}] — 절기(팔진도, D-295)가 매 프레임 넣고 update가 쓰고 비움

var cap := 0
var count := 0
var target := 300
var pos := PackedVector2Array()     # XZ
var phase := PackedFloat32Array()
var face := PackedFloat32Array()
var hp := PackedFloat32Array()
var cd := PackedFloat32Array()
var atk := PackedFloat32Array()     # 찌르기 준비 시간(궁병은 쏘기 준비)
var lunge := PackedFloat32Array()   # 남은 찌르기 동작 시간(0이면 안 찌름)
var kind := PackedByteArray()       # EnemyTable.KINDS 번호
var stun := PackedFloat32Array()    # 남은 기절 시간(사자후) — 기절하면 안 움직이고 안 찌름
var conf := PackedFloat32Array()    # 남은 혼란 시간(팔진도, D-338) — 이리저리 헤매고 안 찌름 · 안 쏨, 머리 위 물음표
var conf_dir := PackedVector2Array()
var conf_turn := PackedFloat32Array()
const CONF_CAP := 400                # 물음표를 그리는 최대 수
var conf_mm: MultiMesh
var conf_buf := PackedFloat32Array()
var confused_total := 0              # 혼란시킨 수(점검용)
var mm: Array[MultiMesh] = []       # [kind × FRAMES + f]
var bufs: Array[PackedFloat32Array] = []
var head := PackedInt32Array()      # 격자 칸마다 첫 적(-1 없음)
var next := PackedInt32Array()      # 같은 칸의 다음 적
var rng := RandomNumberGenerator.new()
var kills := 0
var dead_pos := PackedVector2Array()   # 이번 프레임에 쓰러진 자리
var spawn_hp := HP          # 새로 나오는 적의 체력(시간표)
var speed := SPEED           # 적 걷는 속도(시간표)
var weather_slow := 1.0       # 모든 잡병 속도 배율(천기 비 — 고유 심법이 매 프레임 넣음, D-334)
var mix: Array = [1.0, 0.0, 0.0, 0.0]   # 종류 비율(EnemyTable.mix_at — main이 넣음)
var spawn_points := PackedVector2Array()   # 살아 있는 진영 자리(stage.gd) — 생성의 camp_share를 여기서
var camp_share := 0.3
var bounds := Rect2(-1e6, -1e6, 2e6, 2e6)  # 맵 경계(stage.gd)
var last_update_us := 0
var hit_count := 0          # 지금까지 맞힌 수(main이 늘어난 만큼 내공으로)
var stun_total := 0         # 기절시킨 수(점검용)
var targets: Array = []     # 적장(foe.gd) — pos2() · radius · alive · hurt(dmg, push, knock, ch) · stun_for(t) · push_by(v)
var spawned_kind := PackedInt32Array([0, 0, 0, 0])
# 궁병 화살
const ARROW_GLB := "res://assets/models/yt_arrow.glb"
var arrow_pos := PackedVector2Array()
var arrow_dir := PackedVector2Array()
var arrow_life := PackedFloat32Array()
var arrow_n := 0
var arrow_mm: MultiMesh
var arrow_buf := PackedFloat32Array()
var arrows_shot := 0
var arrows_hit := 0

func setup(max_count: int) -> void:
	cap = max_count
	rng.seed = 11
	pos.resize(cap); phase.resize(cap); face.resize(cap); next.resize(cap); kind.resize(cap)
	hp.resize(cap); atk.resize(cap); lunge.resize(cap); stun.resize(cap); cd.resize(cap * N_CH)
	conf.resize(cap); conf_dir.resize(cap); conf_turn.resize(cap)
	_setup_conf_marks()
	head.resize(GRID * GRID)
	for kd in EnemyTable.KINDS:
		var src: Node = load(kd.glb).instantiate()
		for i in FRAMES:
			var mi := src.find_child("pose_%d" % i, true, false) as MeshInstance3D
			var m := MultiMesh.new()
			m.transform_format = MultiMesh.TRANSFORM_3D
			m.mesh = mi.mesh
			m.instance_count = cap
			m.visible_instance_count = 0
			var inst := MultiMeshInstance3D.new()
			inst.multimesh = m
			add_child(inst)
			mm.append(m)
			var b := PackedFloat32Array()
			b.resize(cap * 12)
			bufs.append(b)
		src.free()
	# 화살(가는 막대)
	arrow_pos.resize(ARROW_CAP); arrow_dir.resize(ARROW_CAP); arrow_life.resize(ARROW_CAP)
	var am: Mesh = null
	if ResourceLoader.exists(ARROW_GLB):   # 화살 모델(D-328 — 돌 촉 · 노란 깃, tools/blender/yt_arrow.py), 없으면 막대
		var asrc: Node = load(ARROW_GLB).instantiate()
		for c in asrc.find_children("*", "MeshInstance3D", true, false):
			am = (c as MeshInstance3D).mesh
			break
		asrc.free()
	if am == null:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, 0.7)
		var amat := StandardMaterial3D.new()
		amat.albedo_color = Color("3a2a1e")
		bm.material = amat
		am = bm
	arrow_mm = MultiMesh.new()
	arrow_mm.transform_format = MultiMesh.TRANSFORM_3D
	arrow_mm.mesh = am
	arrow_mm.instance_count = ARROW_CAP
	arrow_mm.visible_instance_count = 0
	var ai := MultiMeshInstance3D.new()
	ai.multimesh = arrow_mm
	add_child(ai)
	arrow_buf.resize(ARROW_CAP * 12)

func _clamp(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, bounds.position.x, bounds.end.x), clampf(p.y, bounds.position.y, bounds.end.y))

func _spawn_pos(center: Vector2, near := 22.0) -> Vector2:
	if not spawn_points.is_empty() and rng.randf() < camp_share:   # 진영에서 나옴
		var sp := spawn_points[rng.randi() % spawn_points.size()]
		return _clamp(sp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 5.0))
	var a := rng.randf() * TAU
	return _clamp(center + Vector2(cos(a), sin(a)) * rng.randf_range(near, 32.0))

func _pick_kind() -> int:
	var total := 0.0
	for w in mix:
		total += w
	var r := rng.randf() * total
	for k in mix.size():
		r -= mix[k]
		if r <= 0.0:
			return k
	return 0

func _respawn(i: int, center: Vector2, near := 22.0) -> void:
	pos[i] = _spawn_pos(center, near)   # 죽은 자리 대신 먼 고리(또는 진영)에서 다시 나옴(수를 유지)
	var k := _pick_kind()
	kind[i] = k
	spawned_kind[k] += 1
	hp[i] = spawn_hp * EnemyTable.KINDS[k].hp
	for c in N_CH:
		cd[i * N_CH + c] = 0.0
	atk[i] = rng.randf() * EnemyTable.KINDS[k].wind * 0.5   # 처음 찌르는 때를 흩어 둠
	lunge[i] = 0.0
	stun[i] = 0.0
	conf[i] = 0.0

# ── 맞히기 ──
func _damage(i: int, push: Vector2, dmg: float, knock: float, center: Vector2, ch := CH_WEAPON) -> bool:
	## 피해 · 밀려남. 죽으면 먼 고리에서 다시 나오고 true. ch = 맞힌 출처(그 출처의 맞음 대기만 걺).
	hp[i] -= dmg
	cd[i * N_CH + ch] = HIT_CD
	hit_count += 1
	atk[i] = 0.0
	lunge[i] = 0.0
	if hp[i] <= 0.0:
		dead_pos.append(pos[i])   # 경험치 구슬 떨어질 자리(main이 매 프레임 가져감)
		_respawn(i, center)
		kills += 1
		return true
	pos[i] += push * knock * EnemyTable.KINDS[kind[i]].knock
	return false

func _hurt_targets_circle(center: Vector2, r: float, dmg: float, knock: float, push_dir: Vector2, ch: int) -> int:
	var n := 0
	for tg in targets:
		if tg.alive and tg.pos2().distance_to(center) <= r + tg.radius:
			var pd: Vector2 = push_dir if push_dir.length() > 0.01 else (tg.pos2() - center).normalized()
			if tg.hurt(dmg, pd, knock, ch):
				hit_count += 1
				n += 1
	return n

func nearest(center: Vector2, max_r: float, n := 1) -> PackedVector2Array:
	## 가까운 적 n명의 자리(가까운 순, 적장 포함). 없으면 빈 배열.
	var best_p := PackedVector2Array()
	var best_d := PackedFloat32Array()
	var mr2 := max_r * max_r
	for i in count + targets.size():
		var p: Vector2
		if i < count:
			p = pos[i]
		else:
			var tg = targets[i - count]
			if not tg.alive:
				continue
			p = tg.pos2()
		var d2 := p.distance_squared_to(center)
		if d2 > mr2:
			continue
		var k := best_d.size()
		while k > 0 and best_d[k - 1] > d2:
			k -= 1
		if k < n:
			best_d.insert(k, d2); best_p.insert(k, p)
			if best_d.size() > n:
				best_d.resize(n); best_p.resize(n)
	return best_p

func count_within(center: Vector2, r: float) -> int:
	## 이 반지름 안의 잡병 수(자동 봇 경공 · 의용군이 받는 피해).
	var n := 0
	var r2 := r * r
	for i in count:
		if pos[i].distance_squared_to(center) <= r2:
			n += 1
	return n

func stun_circle(center: Vector2, r: float, t: float) -> int:
	## 반지름 안의 적을 t초 기절(사자후). 적장은 저항에 따라 짧게.
	var n := 0
	var r2 := r * r
	for i in count:
		if pos[i].distance_squared_to(center) <= r2:
			stun[i] = maxf(stun[i], t)
			atk[i] = 0.0
			lunge[i] = 0.0
			n += 1
	for tg in targets:
		if tg.alive and tg.pos2().distance_to(center) <= r + tg.radius:
			tg.stun_for(t)
	stun_total += n
	return n

func _setup_conf_marks() -> void:
	## 혼란 물음표(D-338): 노란 "?" 글자 메시 하나를 MultiMesh로(카메라를 보게 매 프레임 기저를 넣음).
	var tm := TextMesh.new()
	tm.text = "?"
	tm.font = load("res://assets/fonts/Galmuri11.ttf")
	tm.font_size = 32
	tm.pixel_size = 0.022
	tm.depth = 0.04
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.95, 0.75)
	tm.material = m
	conf_mm = MultiMesh.new()
	conf_mm.transform_format = MultiMesh.TRANSFORM_3D
	conf_mm.mesh = tm
	conf_mm.instance_count = CONF_CAP
	conf_mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = conf_mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	conf_buf.resize(CONF_CAP * 12)

func confuse_circle(center: Vector2, r: float, t: float) -> int:
	## 반지름 안 잡병을 t초 혼란(이미 혼란이면 늘리기만). 새로 혼란에 빠진 수를 돌려줌.
	var n := 0
	var r2 := r * r
	for i in count:
		if pos[i].distance_squared_to(center) <= r2:
			if conf[i] <= 0.0:
				n += 1
				conf_turn[i] = 0.0
			conf[i] = maxf(conf[i], t)
	confused_total += n
	return n

func push_from(center: Vector2, r: float, dist: float) -> void:
	## 반지름 안의 적을 바깥으로 밀침 — 가까울수록 멀리(맞음 대기와 상관없이).
	var r2 := r * r
	for i in count:
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 <= r2 and d2 > 0.0001:
			var dl := sqrt(d2)
			pos[i] += d / dl * dist * (1.0 - dl / r * 0.5) * EnemyTable.KINDS[kind[i]].knock
	for tg in targets:
		if tg.alive:
			var d: Vector2 = tg.pos2() - center
			if d.length() <= r + tg.radius and d.length() > 0.01:
				tg.push_by(d.normalized() * dist * 0.5)

func random_in(center: Vector2, max_r: float, n: int) -> PackedVector2Array:
	## 이 거리 안 아무 적 n명의 자리(낙뢰). 적장이 있으면 하나는 적장.
	var out := PackedVector2Array()
	for tg in targets:
		if tg.alive and tg.pos2().distance_to(center) <= max_r and out.size() < n:
			out.append(tg.pos2())
	if count == 0:
		return out
	var mr2 := max_r * max_r
	for tries in n * 8:
		if out.size() >= n:
			break
		var i := rng.randi() % count
		if pos[i].distance_squared_to(center) <= mr2:
			out.append(pos[i])
	return out

func hit_arc(center: Vector2, dir: float, half: float, r_out: float, dmg: float, knock: float, ch := CH_WEAPON) -> int:
	## 휘두르기: center에서 dir(rad, XZ 평면 atan2(z, x)) ±half, 반지름 r_out 안. 밀려남은 바깥쪽으로.
	var n := 0
	var ro2 := r_out * r_out
	for i in count:
		if cd[i * N_CH + ch] > 0.0:
			continue
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 > ro2 or d2 < 0.0001:
			continue
		if absf(angle_difference(atan2(d.y, d.x), dir)) > half:
			continue
		n += 1
		_damage(i, d / sqrt(d2), dmg, knock, center, ch)
	for tg in targets:
		if not tg.alive:
			continue
		var d: Vector2 = tg.pos2() - center
		if d.length() <= r_out + tg.radius and absf(angle_difference(atan2(d.y, d.x), dir)) <= half + 0.3:
			if tg.hurt(dmg, d.normalized(), knock, ch):
				hit_count += 1
				n += 1
	return n

func hit_swirl(center: Vector2, dir: float, half: float, r_out: float, dmg: float, knock: float, swirl: float, ch := CH_ULT) -> int:
	## 소용돌이 휩쓸기(청룡파천, D-335): hit_arc와 같은 부채꼴인데 밀려남이 바깥 + 도는 쪽(swirl — 부호가 도는 방향).
	var n := 0
	var ro2 := r_out * r_out
	for i in count:
		if cd[i * N_CH + ch] > 0.0:
			continue
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 > ro2 or d2 < 0.0001:
			continue
		if absf(angle_difference(atan2(d.y, d.x), dir)) > half:
			continue
		var out := d / sqrt(d2)
		n += 1
		_damage(i, (out + Vector2(-out.y, out.x) * swirl).normalized(), dmg, knock, center, ch)
	for tg in targets:
		if not tg.alive:
			continue
		var d: Vector2 = tg.pos2() - center
		if d.length() <= r_out + tg.radius and absf(angle_difference(atan2(d.y, d.x), dir)) <= half + 0.3:
			var out := d.normalized()
			if tg.hurt(dmg, (out + Vector2(-out.y, out.x) * swirl).normalized(), knock, ch):
				hit_count += 1
				n += 1
	return n

func hit_line(origin: Vector2, dir: Vector2, length: float, half_w: float, dmg: float, knock: float, ch := CH_WEAPON) -> int:
	## 찌르기: origin에서 dir(단위) 방향 길이 length, 폭 ±half_w 직사각형. 밀려남은 찌른 방향으로.
	var n := 0
	for i in count:
		if cd[i * N_CH + ch] > 0.0:
			continue
		var d := pos[i] - origin
		var along := d.dot(dir)
		if along < 0.0 or along > length:
			continue
		if absf(d.cross(dir)) > half_w:
			continue
		n += 1
		_damage(i, dir, dmg, knock, origin, ch)
	for tg in targets:
		if not tg.alive:
			continue
		var d: Vector2 = tg.pos2() - origin
		var along := d.dot(dir)
		if along >= -tg.radius and along <= length + tg.radius and absf(d.cross(dir)) <= half_w + tg.radius:
			if tg.hurt(dmg, dir, knock, ch):
				hit_count += 1
				n += 1
	return n

func hit_circle(center: Vector2, r: float, dmg: float, knock: float, push_dir: Vector2, max_hits: int, respawn_center: Vector2, ch := CH_WEAPON) -> int:
	## 날아가는 것 · 범위: center 반지름 r 안, 최대 max_hits명. 밀려남은 push_dir(날아가는 방향)으로.
	var n := 0
	var r2 := r * r
	for i in count:
		if n >= max_hits:
			break
		if cd[i * N_CH + ch] > 0.0:
			continue
		if pos[i].distance_squared_to(center) > r2:
			continue
		n += 1
		_damage(i, push_dir, dmg, knock, respawn_center, ch)
	if n < max_hits:
		n += _hurt_targets_circle(center, r, dmg, knock, push_dir, ch)
	return n

func pull_near(center: Vector2, n: int) -> int:
	## 적장의 '부르기': 멀리 있는 잡병 n명을 center 둘레로 옮김(수는 그대로).
	var moved := 0
	for tries in n * 4:
		if moved >= n or count == 0:
			break
		var i := rng.randi() % count
		if pos[i].distance_to(center) > 12.0:
			pos[i] = _clamp(center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.8, 3.5))
			moved += 1
	return moved

func scatter(player: Vector2) -> void:
	## 남은 잡병을 모두 흩어 버림(보스전 시작) — 먼 고리로 옮김.
	for i in count:
		pos[i] = _spawn_pos(player, 40.0)
	arrow_n = 0

func update(delta: float, player: Vector2) -> float:
	## 적 이동 · 밀어내기 · 찌르기 · 화살 · 그리기 버퍼. 돌려주는 값 = 이번 프레임에 장수가 맞은 피해 배율 합
	## (찌르기 1 · 화살은 궁병 배율 — main이 찌르기 피해에 곱하고 맞은 뒤 무적을 적용).
	var t0 := Time.get_ticks_usec()
	while count < mini(target, cap):
		_respawn(count, player, 12.0 if kills == 0 else 22.0)   # 처음 무리는 조금 가까이서 시작
		phase[count] = rng.randf()
		count += 1
	count = mini(count, target)

	# 공간 격자(연결 리스트)
	head.fill(-1)
	var ox := player.x - GRID * CELL * 0.5
	var oz := player.y - GRID * CELL * 0.5
	for i in count:
		var cx := int((pos[i].x - ox) / CELL)
		var cz := int((pos[i].y - oz) / CELL)
		if cx < 0 or cz < 0 or cx >= GRID or cz >= GRID:
			next[i] = -2
			continue
		var c := cz * GRID + cx
		next[i] = head[c]
		head[c] = i

	var hits := 0.0
	var min_d := RADIUS * 2.0
	var min_d2 := min_d * min_d
	for i in count:
		var kd: Dictionary = EnemyTable.KINDS[kind[i]]
		var p := pos[i]
		var to := player - p
		var dist := to.length()
		var v := Vector2.ZERO
		var stunned := stun[i] > 0.0
		if stunned:
			stun[i] -= delta
		var confused := conf[i] > 0.0
		if confused:   # 혼란: 0.35~0.8초마다 아무 쪽으로 방향을 바꿈
			conf[i] -= delta
			conf_turn[i] -= delta
			if conf_turn[i] <= 0.0:
				conf_turn[i] = rng.randf_range(0.35, 0.8)
				conf_dir[i] = Vector2.from_angle(rng.randf() * TAU)
		for c in N_CH:
			var k := i * N_CH + c
			if cd[k] > 0.0:
				cd[k] -= delta
		var spd: float = speed * kd.speed * weather_slow
		for z in slow_zones:
			if p.distance_squared_to(z.c) <= z.r2:
				spd *= z.f
		if confused and not stunned:   # 헤맴(찌르기 · 쏘기 없음)
			v = conf_dir[i] * spd * 0.8
			atk[i] = 0.0
			if lunge[i] > 0.0:
				lunge[i] -= delta
		elif kd.has("ranged"):
			# 궁병: keep 거리 근처를 유지하며 쏨
			var rg: Dictionary = kd.ranged
			if lunge[i] > 0.0:
				lunge[i] -= delta
			if not stunned and dist > 0.01:
				if dist > rg.keep + 1.5:
					v = to / dist * spd
				elif dist < rg.keep - 1.5:
					v = -to / dist * spd * 0.7
				if dist < rg.keep + 3.0:
					atk[i] += delta
					if atk[i] >= rg.shoot:
						atk[i] = 0.0
						lunge[i] = LUNGE_T
						_shoot(p, to / dist, rg)
		else:
			if dist > STOP_D and lunge[i] <= 0.0 and not stunned:
				v = to / dist * spd
			# 찌르기: 붙어 있으면 준비 → 찌름(동작 중 맞으면 피해 한 번)
			if stunned:
				pass
			elif lunge[i] > 0.0:
				lunge[i] -= delta
			elif dist < ATK_RANGE:
				atk[i] += delta
				if atk[i] >= kd.wind:
					atk[i] = 0.0
					lunge[i] = LUNGE_T
					if dist < HIT_RANGE:
						hits += 1.0
			else:
				atk[i] = maxf(atk[i] - delta, 0.0)
		# 이웃 밀어내기(3×3칸)
		if next[i] != -2:
			var cx := int((p.x - ox) / CELL)
			var cz := int((p.y - oz) / CELL)
			var push := Vector2.ZERO
			for dz in range(-1, 2):
				var zz := cz + dz
				if zz < 0 or zz >= GRID: continue
				for dx in range(-1, 2):
					var xx := cx + dx
					if xx < 0 or xx >= GRID: continue
					var j := head[zz * GRID + xx]
					while j >= 0:
						if j != i:
							var d := p - pos[j]
							var d2 := d.length_squared()
							if d2 < min_d2 and d2 > 0.000001:
								var dl := sqrt(d2)
								push += d / dl * (min_d - dl)
						j = next[j]
			v += push * 6.0
		pos[i] = _clamp(p + v * delta)
		if confused:
			face[i] = atan2(conf_dir[i].x, conf_dir[i].y)
		elif dist > 0.01:
			face[i] = atan2(to.x, to.y)
		phase[i] = fmod(phase[i] + delta * STEP_HZ, 1.0)

	hits += _arrows_tick(delta, player)

	# 종류 × 프레임별로 나눠 버퍼에 씀(행 우선 3×4: 기저 행 + 위치).
	# Packed 배열은 값 복사(쓰기 시 복사)라, 멤버에서 떼어 낸 뒤 써야 매번 통째 복사가 안 일어남.
	var nk := EnemyTable.KINDS.size()
	for g in nk * FRAMES:
		var kk := g / FRAMES
		var f := g % FRAMES
		var b := bufs[g]
		bufs[g] = PackedFloat32Array()
		var k := 0
		for i in count:
			if kind[i] != kk or int(phase[i] * FRAMES) % FRAMES != f:
				continue
			var c := cos(face[i])
			var s := sin(face[i])
			var px := pos[i].x
			var pz := pos[i].y
			if lunge[i] > 0.0:   # 찌르는 동안 앞으로 튀어나옴(그리기만 — 실제 자리는 그대로)
				var o := LUNGE_D * sin(PI * (1.0 - lunge[i] / LUNGE_T))
				px += s * o
				pz += c * o
			b[k] = c;    b[k + 1] = 0.0; b[k + 2] = s;   b[k + 3] = px
			b[k + 4] = 0.0; b[k + 5] = 1.0; b[k + 6] = 0.0; b[k + 7] = 0.0
			b[k + 8] = -s; b[k + 9] = 0.0; b[k + 10] = c; b[k + 11] = pz
			k += 12
		mm[g].buffer = b
		mm[g].visible_instance_count = k / 12
		bufs[g] = b
	_conf_marks()
	last_update_us = Time.get_ticks_usec() - t0
	slow_zones.clear()
	return hits

func _conf_marks() -> void:
	## 혼란한 잡병 머리 위 물음표(카메라를 봄 · 살짝 까딱).
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var bs := cam.global_transform.basis if cam else Basis()
	var k := 0
	var tsec := Time.get_ticks_msec() * 0.001
	for i in count:
		if conf[i] <= 0.0 or k >= CONF_CAP * 12:
			continue
		var bob := 0.12 * sin(tsec * 6.0 + i)
		var x := bs.x
		conf_buf[k] = x.x;     conf_buf[k + 1] = bs.y.x; conf_buf[k + 2] = bs.z.x;  conf_buf[k + 3] = pos[i].x
		conf_buf[k + 4] = x.y; conf_buf[k + 5] = bs.y.y; conf_buf[k + 6] = bs.z.y;  conf_buf[k + 7] = 2.1 + bob
		conf_buf[k + 8] = x.z; conf_buf[k + 9] = bs.y.z; conf_buf[k + 10] = bs.z.z; conf_buf[k + 11] = pos[i].y
		k += 12
	conf_mm.buffer = conf_buf
	conf_mm.visible_instance_count = k / 12

func _shoot(from: Vector2, dir: Vector2, rg: Dictionary) -> void:
	if arrow_n >= ARROW_CAP:
		return
	arrow_pos[arrow_n] = from + dir * 0.5
	arrow_dir[arrow_n] = dir * rg.arrow_speed
	arrow_life[arrow_n] = rg.arrow_life
	arrow_n += 1
	arrows_shot += 1

func _arrows_tick(delta: float, player: Vector2) -> float:
	## 화살 이동 · 장수에게 맞으면 사라짐. 돌려주는 값 = 맞은 피해 배율 합.
	var hits := 0.0
	var rg: Dictionary = EnemyTable.KINDS[1].ranged
	var r2: float = rg.arrow_r * rg.arrow_r
	var i := 0
	while i < arrow_n:
		arrow_pos[i] += arrow_dir[i] * delta
		arrow_life[i] -= delta
		var hit := arrow_pos[i].distance_squared_to(player) < r2
		if hit:
			hits += rg.arrow_dmg
			arrows_hit += 1
		if hit or arrow_life[i] <= 0.0:
			arrow_n -= 1
			arrow_pos[i] = arrow_pos[arrow_n]; arrow_dir[i] = arrow_dir[arrow_n]; arrow_life[i] = arrow_life[arrow_n]
			continue
		i += 1
	var b := arrow_buf
	arrow_buf = PackedFloat32Array()
	for k in arrow_n:
		var d := arrow_dir[k].normalized()
		var c := d.y   # 막대 +Z를 날아가는 쪽으로(θ = atan2(d.x, d.y) → cosθ = d.y, sinθ = d.x)
		var s := d.x
		var o := k * 12
		b[o] = c;    b[o + 1] = 0.0; b[o + 2] = s;   b[o + 3] = arrow_pos[k].x
		b[o + 4] = 0.0; b[o + 5] = 1.0; b[o + 6] = 0.0; b[o + 7] = 1.0
		b[o + 8] = -s; b[o + 9] = 0.0; b[o + 10] = c; b[o + 11] = arrow_pos[k].y
	arrow_mm.buffer = b
	arrow_mm.visible_instance_count = arrow_n
	arrow_buf = b
	return hits
