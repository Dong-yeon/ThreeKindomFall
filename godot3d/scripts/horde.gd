extends Node3D
## 적 떼(황건적): 노드 없이 배열로 들고, MultiMesh 4개(walk 4프레임 정지 메시)로 한 번에 그린다(D-275).
## 뼈 있는 모델은 MultiMesh로 못 그리므로, 걸음 위상에 따라 프레임 메시를 바꿔 끼운다.
## D-276: 적 체력 · 맞으면 밀려남 · 장수에게 붙으면 창 찌르기(앞으로 튀어나옴 → 맞으면 피해).
## D-281: 맞히는 모양은 무기마다(휘두르기 hit_arc · 찌르기 hit_line · 날아가는 것 hit_circle).

const POSES_GLB := "res://assets/models/yellow_turban_poses.glb"
const FRAMES := 4
const SPEED := 2.3
const RADIUS := 0.38          # 서로 밀어내는 반지름
const CELL := 1.0             # 공간 격자 칸(밀어내기 이웃 찾기)
const GRID := 96              # 장수 둘레 96×96칸만 격자에 넣음(밖은 밀어내기 생략)
const STEP_HZ := 2.0          # 걸음 주기 0.5초
const HP := 3.0               # 칼날 세 번
const HIT_CD := 0.3           # 같은 적이 다시 맞기까지(무기 둘 이상 · 꿰뚫는 칼이 같은 적을 연달아 못 때리게)
const STOP_D := 0.9           # 장수 앞에서 멈추는 거리
const ATK_RANGE := 1.25       # 이 안에 들면 찌를 준비
const ATK_WIND := 0.9         # 준비(초) — 이만큼 붙어 있어야 찌름
const LUNGE_T := 0.18         # 찌르기 동작(초)
const LUNGE_D := 0.35         # 찌를 때 앞으로 튀어나오는 거리
const HIT_RANGE := 1.4        # 찌르는 순간 이 안이면 맞음

var cap := 0
var count := 0
var target := 300
var pos := PackedVector2Array()     # XZ
var phase := PackedFloat32Array()
var face := PackedFloat32Array()
var hp := PackedFloat32Array()
var hit_cd := PackedFloat32Array()
var atk := PackedFloat32Array()     # 찌르기 준비 시간
var lunge := PackedFloat32Array()   # 남은 찌르기 동작 시간(0이면 안 찌름)
var mm: Array[MultiMesh] = []
var bufs: Array[PackedFloat32Array] = []
var head := PackedInt32Array()      # 격자 칸마다 첫 적(-1 없음)
var next := PackedInt32Array()      # 같은 칸의 다음 적
var rng := RandomNumberGenerator.new()
var kills := 0
var dead_pos := PackedVector2Array()   # 이번 프레임에 쓰러진 자리
var spawn_hp := HP          # 새로 나오는 적의 체력(D-282 시간표가 올림)
var speed := SPEED           # 적 걷는 속도(시간표가 올림)
var last_update_us := 0
var hit_count := 0          # 지금까지 맞힌 수(D-285 — main이 늘어난 만큼 내공으로)
var ally_cd := PackedFloat32Array()   # 의용군 전용 맞음 대기(D-286 — 장수 공격과 따로: 같이 쓰면 화계 등에 막혀 의용군 휘두름의 43%가 헛침)
var stun := PackedFloat32Array()   # 남은 기절 시간(사자후) — 기절하면 안 움직이고 안 찌름
var stun_total := 0         # 기절시킨 수(점검용)

func setup(max_count: int) -> void:
	cap = max_count
	rng.seed = 11
	pos.resize(cap); phase.resize(cap); face.resize(cap); next.resize(cap)
	hp.resize(cap); hit_cd.resize(cap); atk.resize(cap); lunge.resize(cap); stun.resize(cap); ally_cd.resize(cap)
	head.resize(GRID * GRID)
	var src: Node = load(POSES_GLB).instantiate()
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

func _spawn_pos(center: Vector2, near := 22.0) -> Vector2:
	var a := rng.randf() * TAU
	return center + Vector2(cos(a), sin(a)) * rng.randf_range(near, 32.0)

func _respawn(i: int, center: Vector2, near := 22.0) -> void:
	pos[i] = _spawn_pos(center, near)   # 죽은 자리 대신 먼 고리에서 다시 나옴(수를 유지)
	hp[i] = spawn_hp
	hit_cd[i] = 0.0
	atk[i] = rng.randf() * ATK_WIND * 0.5   # 처음 찌르는 때를 흩어 둠
	lunge[i] = 0.0
	stun[i] = 0.0
	ally_cd[i] = 0.0

# ── 맞히기(D-281: 장수 무기마다 모양이 달라 판정을 나눔) ──
func _damage(i: int, push: Vector2, dmg: float, knock: float, center: Vector2, ally := false) -> bool:
	## 피해 · 밀려남. 죽으면 먼 고리에서 다시 나오고 true. ally면 의용군 전용 맞음 대기를 씀.
	hp[i] -= dmg
	if ally:
		ally_cd[i] = HIT_CD
	else:
		hit_cd[i] = HIT_CD
	hit_count += 1
	atk[i] = 0.0
	lunge[i] = 0.0
	if hp[i] <= 0.0:
		dead_pos.append(pos[i])   # 경험치 구슬 떨어질 자리(D-283 — main이 매 프레임 가져감)
		_respawn(i, center)
		kills += 1
		return true
	pos[i] += push * knock
	return false

func nearest(center: Vector2, max_r: float, n := 1) -> PackedVector2Array:
	## 가까운 적 n명의 자리(가까운 순). 없으면 빈 배열.
	var best_i := PackedInt32Array()
	var best_d := PackedFloat32Array()
	var mr2 := max_r * max_r
	for i in count:
		var d2 := pos[i].distance_squared_to(center)
		if d2 > mr2:
			continue
		var k := best_d.size()
		while k > 0 and best_d[k - 1] > d2:
			k -= 1
		if k < n:
			best_d.insert(k, d2); best_i.insert(k, i)
			if best_d.size() > n:
				best_d.resize(n); best_i.resize(n)
	var out := PackedVector2Array()
	for i in best_i:
		out.append(pos[i])
	return out

func count_within(center: Vector2, r: float) -> int:
	## 이 반지름 안의 적 수(자동 봇 경공 · 의용군이 받는 피해).
	var n := 0
	var r2 := r * r
	for i in count:
		if pos[i].distance_squared_to(center) <= r2:
			n += 1
	return n

func stun_circle(center: Vector2, r: float, t: float) -> int:
	## 반지름 안의 적을 t초 기절(D-285 사자후).
	var n := 0
	var r2 := r * r
	for i in count:
		if pos[i].distance_squared_to(center) <= r2:
			stun[i] = maxf(stun[i], t)
			atk[i] = 0.0
			lunge[i] = 0.0
			n += 1
	stun_total += n
	return n

func push_from(center: Vector2, r: float, dist: float) -> void:
	## 반지름 안의 적을 바깥으로 밀침 — 가까울수록 멀리(맞음 대기와 상관없이).
	var r2 := r * r
	for i in count:
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 <= r2 and d2 > 0.0001:
			var dl := sqrt(d2)
			pos[i] += d / dl * dist * (1.0 - dl / r * 0.5)

func random_in(center: Vector2, max_r: float, n: int) -> PackedVector2Array:
	## 이 거리 안 아무 적 n명의 자리(낙뢰). 몇 번 뽑아 보고 안 되면 덜 돌려줌.
	var out := PackedVector2Array()
	if count == 0:
		return out
	var mr2 := max_r * max_r
	for tries in n * 8:
		var i := rng.randi() % count
		if pos[i].distance_squared_to(center) <= mr2:
			out.append(pos[i])
			if out.size() >= n:
				break
	return out

func hit_arc(center: Vector2, dir: float, half: float, r_out: float, dmg: float, knock: float, ally := false) -> int:
	## 휘두르기: center에서 dir(rad, XZ 평면 atan2(z, x)) ±half, 반지름 r_out 안. 밀려남은 바깥쪽으로.
	## ally = 의용군(전용 맞음 대기).
	var n := 0
	var ro2 := r_out * r_out
	for i in count:
		if (ally_cd[i] if ally else hit_cd[i]) > 0.0:
			continue
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 > ro2 or d2 < 0.0001:
			continue
		if absf(angle_difference(atan2(d.y, d.x), dir)) > half:
			continue
		n += 1
		_damage(i, d / sqrt(d2), dmg, knock, center, ally)
	return n

func hit_line(origin: Vector2, dir: Vector2, length: float, half_w: float, dmg: float, knock: float) -> int:
	## 찌르기: origin에서 dir(단위) 방향 길이 length, 폭 ±half_w 직사각형. 밀려남은 찌른 방향으로.
	var n := 0
	for i in count:
		if hit_cd[i] > 0.0:
			continue
		var d := pos[i] - origin
		var along := d.dot(dir)
		if along < 0.0 or along > length:
			continue
		if absf(d.cross(dir)) > half_w:
			continue
		n += 1
		_damage(i, dir, dmg, knock, origin)
	return n

func hit_circle(center: Vector2, r: float, dmg: float, knock: float, push_dir: Vector2, max_hits: int, respawn_center: Vector2) -> int:
	## 날아가는 것: center 반지름 r 안, 최대 max_hits명. 밀려남은 push_dir(날아가는 방향)으로.
	var n := 0
	var r2 := r * r
	for i in count:
		if n >= max_hits:
			break
		if hit_cd[i] > 0.0:
			continue
		if pos[i].distance_squared_to(center) > r2:
			continue
		n += 1
		_damage(i, push_dir, dmg, knock, respawn_center)
	return n

func update(delta: float, player: Vector2) -> int:
	## 적 이동 · 밀어내기 · 찌르기 · 그리기 버퍼. 돌려주는 값 = 이번 프레임에 장수를 찌른 수.
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

	var hits := 0
	var min_d := RADIUS * 2.0
	var min_d2 := min_d * min_d
	for i in count:
		var p := pos[i]
		var to := player - p
		var dist := to.length()
		var v := Vector2.ZERO
		var stunned := stun[i] > 0.0
		if stunned:
			stun[i] -= delta
		if dist > STOP_D and lunge[i] <= 0.0 and not stunned:
			v = to / dist * speed
		# 찌르기: 붙어 있으면 준비 → 찌름(동작 중 맞으면 피해 한 번)
		if hit_cd[i] > 0.0:
			hit_cd[i] -= delta
		if ally_cd[i] > 0.0:
			ally_cd[i] -= delta
		if stunned:
			pass
		elif lunge[i] > 0.0:
			lunge[i] -= delta
		elif dist < ATK_RANGE:
			atk[i] += delta
			if atk[i] >= ATK_WIND:
				atk[i] = 0.0
				lunge[i] = LUNGE_T
				if dist < HIT_RANGE:
					hits += 1
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
		pos[i] = p + v * delta
		if dist > 0.01:
			face[i] = atan2(to.x, to.y)
		phase[i] = fmod(phase[i] + delta * STEP_HZ, 1.0)

	# 프레임별로 나눠 버퍼에 씀(행 우선 3×4: 기저 행 + 위치).
	# Packed 배열은 값 복사(쓰기 시 복사)라, 멤버에서 떼어 낸 뒤 써야 매번 통째 복사가 안 일어남.
	for f in FRAMES:
		var b := bufs[f]
		bufs[f] = PackedFloat32Array()
		var k := 0
		for i in count:
			if int(phase[i] * FRAMES) % FRAMES != f:
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
		mm[f].buffer = b
		mm[f].visible_instance_count = k / 12
		bufs[f] = b
	last_update_us = Time.get_ticks_usec() - t0
	return hits
