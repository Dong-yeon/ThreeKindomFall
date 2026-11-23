extends Node3D
## 적 떼(황건적): 노드 없이 배열로 들고, MultiMesh 4개(walk 4프레임 정지 메시)로 한 번에 그린다(D-275).
## 뼈 있는 모델은 MultiMesh로 못 그리므로, 걸음 위상에 따라 프레임 메시를 바꿔 끼운다.
## D-276: 적 체력 · 칼날에 맞기(밀려남) · 장수에게 붙으면 창 찌르기(앞으로 튀어나옴 → 맞으면 피해).

const POSES_GLB := "res://assets/models/yellow_turban_poses.glb"
const FRAMES := 4
const SPEED := 2.3
const RADIUS := 0.38          # 서로 밀어내는 반지름
const CELL := 1.0             # 공간 격자 칸(밀어내기 이웃 찾기)
const GRID := 96              # 장수 둘레 96×96칸만 격자에 넣음(밖은 밀어내기 생략)
const STEP_HZ := 2.0          # 걸음 주기 0.5초
const HP := 3.0               # 칼날 세 번
const HIT_CD := 0.3           # 같은 적이 칼날에 다시 맞기까지
const KNOCK := 0.7            # 칼날에 맞으면 밀려나는 거리
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
var last_update_us := 0

func setup(max_count: int) -> void:
	cap = max_count
	rng.seed = 11
	pos.resize(cap); phase.resize(cap); face.resize(cap); next.resize(cap)
	hp.resize(cap); hit_cd.resize(cap); atk.resize(cap); lunge.resize(cap)
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
	hp[i] = HP
	hit_cd[i] = 0.0
	atk[i] = rng.randf() * ATK_WIND * 0.5   # 처음 찌르는 때를 흩어 둠
	lunge[i] = 0.0

func blade_hits(center: Vector2, angles: PackedFloat32Array, r_in: float, r_out: float, half_w: float, dmg: float) -> int:
	## 회전 칼날: 장수 둘레 고리(r_in~r_out) 안에서 칼날 각도 ±half_w(rad)에 든 적이 맞음.
	var n := 0
	var ri2 := r_in * r_in
	var ro2 := r_out * r_out
	for i in count:
		if hit_cd[i] > 0.0:
			continue
		var d := pos[i] - center
		var d2 := d.length_squared()
		if d2 < ri2 or d2 > ro2:
			continue
		var a := atan2(d.y, d.x)
		var hit := false
		for ba in angles:
			if absf(angle_difference(a, ba)) < half_w:
				hit = true
				break
		if not hit:
			continue
		hp[i] -= dmg
		hit_cd[i] = HIT_CD
		atk[i] = 0.0
		lunge[i] = 0.0
		if hp[i] <= 0.0:
			_respawn(i, center)
			kills += 1
			n += 1
		else:
			pos[i] += d / sqrt(d2) * KNOCK
	return n

func update(delta: float, player: Vector2) -> int:
	## 적 이동 · 밀어내기 · 찌르기 · 그리기 버퍼. 돌려주는 값 = 이번 프레임에 장수를 찌른 수.
	var t0 := Time.get_ticks_usec()
	while count < mini(target, cap):
		_respawn(count, player, 7.0 if kills == 0 else 22.0)   # 처음 무리는 가까이서 시작
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
		if dist > STOP_D and lunge[i] <= 0.0:
			v = to / dist * SPEED
		# 찌르기: 붙어 있으면 준비 → 찌름(동작 중 맞으면 피해 한 번)
		if hit_cd[i] > 0.0:
			hit_cd[i] -= delta
		if lunge[i] > 0.0:
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
