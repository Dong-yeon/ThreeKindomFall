extends Node3D
## 적 떼(황건적): 노드 없이 배열로 들고, MultiMesh 4개(walk 4프레임 정지 메시)로 한 번에 그린다(D-275).
## 뼈 있는 모델은 MultiMesh로 못 그리므로, 걸음 위상에 따라 프레임 메시를 바꿔 끼운다.

const POSES_GLB := "res://assets/models/yellow_turban_poses.glb"
const FRAMES := 4
const SPEED := 2.3
const RADIUS := 0.38          # 서로 밀어내는 반지름
const CELL := 1.0             # 공간 격자 칸(밀어내기 이웃 찾기)
const GRID := 96              # 장수 둘레 96×96칸만 격자에 넣음(밖은 밀어내기 생략)
const STEP_HZ := 2.0          # 걸음 주기 0.5초

var cap := 0
var count := 0
var target := 300
var pos := PackedVector2Array()     # XZ
var phase := PackedFloat32Array()
var face := PackedFloat32Array()
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

func kill_within(center: Vector2, r: float) -> int:
	var r2 := r * r
	var n := 0
	for i in count:
		if pos[i].distance_squared_to(center) < r2:
			pos[i] = _spawn_pos(center)   # 죽은 자리 대신 먼 고리에서 다시 나옴(수를 유지)
			n += 1
	kills += n
	return n

func update(delta: float, player: Vector2) -> void:
	var t0 := Time.get_ticks_usec()
	# 수 맞추기(늘리기만 — 줄일 땐 뒤에서 잘라냄)
	while count < mini(target, cap):
		pos[count] = _spawn_pos(player, 7.0 if kills == 0 else 22.0)   # 처음 무리는 가까이서 시작
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

	var min_d := RADIUS * 2.0
	var min_d2 := min_d * min_d
	for i in count:
		var p := pos[i]
		var to := player - p
		var dist := to.length()
		var v := Vector2.ZERO
		if dist > 0.9:
			v = to / dist * SPEED
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
			b[k] = c;    b[k + 1] = 0.0; b[k + 2] = s;   b[k + 3] = pos[i].x
			b[k + 4] = 0.0; b[k + 5] = 1.0; b[k + 6] = 0.0; b[k + 7] = 0.0
			b[k + 8] = -s; b[k + 9] = 0.0; b[k + 10] = c; b[k + 11] = pos[i].y
			k += 12
		mm[f].buffer = b
		mm[f].visible_instance_count = k / 12
		bufs[f] = b
	last_update_us = Time.get_ticks_usec() - t0
