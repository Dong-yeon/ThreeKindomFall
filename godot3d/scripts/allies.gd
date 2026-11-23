extends Node3D
## 의용군(D-285, 유비 절기 '의용군 소환'이 add로 더함 — 판 끝까지 누적, 최대 수까지).
## 적 떼처럼 노드 없이 배열 + MultiMesh 4개(walk 4프레임, militia_poses.glb).
## 행동: 장수 둘레 LEASH 안에서 가까운 적에게 가서 짧게 벰(hit_arc). 적이 붙어 있으면 체력이 깎이고 0이면 사라짐.

const POSES_GLB := "res://assets/models/militia_poses.glb"
const FRAMES := 4
const CAP := 64
const LEASH := 9.0            # 장수에게서 이보다 멀어지면 돌아옴(D-286: 7은 움직이는 장수를 쫓기만 하고 못 싸움)
const SEEK := 6.0             # 이 거리 안 적을 노림
const CONTACT_R := 0.9        # 이 안의 적 수만큼 피해
const REGEN := 0.05           # 붙은 적이 없으면 초당 최대 체력의 이만큼 회복(D-286)
const CONTACT_DPS := 0.12     # 붙은 적 하나가 초당 주는 피해 = 적 찌르기 피해 × 이 값(0.5 · 0.3은 후반에 다 쓰러져 누적이 의미 없었음)

var count := 0
var pos := PackedVector2Array()
var hp := PackedFloat32Array()   # 남은 체력 비율 0~1(D-286 — 최대 체력은 spec.hp × 인덕 배율이라 레벨이 오르면 이미 있는 병사도 단단해짐)
var cd := PackedFloat32Array()
var face := PackedFloat32Array()
var phase := PackedFloat32Array()
var spec: Dictionary = {}     # 마지막 소환의 수치(UltTable.params) — dmg · cd · reach · arc · speed · hp · max
var mul := 1.0                # 인덕 배율(공격 · 체력) — main이 넣음
var atk_mul := 1.0            # 장수 공격 배율(무력 등)
var enemy_dmg := 6.0          # 적 찌르기 피해(시간표) — main이 넣음
var horde: Node3D
var mm: Array[MultiMesh] = []
var bufs: Array[PackedFloat32Array] = []
var summoned := 0
var lost := 0
var hits := 0                # 의용군이 맞힌 적 수(--stats)
var swings := 0              # 휘두른 횟수
var level := 1               # 장수 레벨(최대 수가 레벨 따라 늚 — main이 넣음)

func setup(h: Node3D) -> void:
	horde = h
	pos.resize(CAP); hp.resize(CAP); cd.resize(CAP); face.resize(CAP); phase.resize(CAP)
	var src: Node = load(POSES_GLB).instantiate()
	for i in FRAMES:
		var mi := src.find_child("pose_%d" % i, true, false) as MeshInstance3D
		var m := MultiMesh.new()
		m.transform_format = MultiMesh.TRANSFORM_3D
		m.mesh = mi.mesh
		m.instance_count = CAP
		m.visible_instance_count = 0
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = m
		add_child(inst)
		mm.append(m)
		var b := PackedFloat32Array()
		b.resize(CAP * 12)
		bufs.append(b)
	src.free()

func add(at: Vector2, n: int, s: Dictionary) -> int:
	## n명 더함(최대 limit()). 돌려주는 값 = 실제로 더한 수.
	spec = s
	var lim := limit()
	var added := 0
	for k in n:
		if count >= lim:
			break
		pos[count] = at + Vector2.from_angle(randf() * TAU) * randf_range(0.8, 2.0)
		hp[count] = 1.0
		cd[count] = randf() * s.cd
		phase[count] = randf()
		count += 1
		added += 1
	summoned += added
	return added

func limit() -> int:
	## 최대 수 = max + 레벨 × max_per_lv(D-286: 후반에 군대가 더 커지게).
	if spec.is_empty():
		return 0
	return mini(int(spec.max + spec.get("max_per_lv", 0.0) * level), CAP)

func update(delta: float, player: Vector2) -> void:
	if count == 0:
		_draw()
		return
	var dmg: float = spec.dmg * mul * atk_mul
	var i := 0
	while i < count:
		var p := pos[i]
		var to_pl := player - p
		var goal := player
		var tg: PackedVector2Array = horde.nearest(p, SEEK, 1)
		if to_pl.length() > LEASH or tg.is_empty():
			goal = player + Vector2(cos(i * 2.4), sin(i * 2.4)) * 2.0   # 장수 둘레에 흩어져 섬
		else:
			goal = tg[0]
		var d := goal - p
		var dl := d.length()
		if dl > 0.01:
			face[i] = atan2(d.x, d.y)
		if dl > (spec.reach * 0.8 if not tg.is_empty() and goal == tg[0] else 0.3):
			pos[i] = p + d / dl * minf(spec.speed * delta, dl)
			phase[i] = fmod(phase[i] + delta * 2.0, 1.0)
		cd[i] -= delta
		if cd[i] <= 0.0 and not tg.is_empty() and p.distance_to(tg[0]) <= spec.reach:
			cd[i] = spec.cd
			var dir := (tg[0] - p).normalized()
			hits += horde.hit_arc(p, atan2(dir.y, dir.x), deg_to_rad(spec.arc) * 0.5, spec.reach, dmg, 0.4, true)
			swings += 1
		# 붙어 있는 적에게 깎임
		var near: int = horde.count_within(p, CONTACT_R)
		if near > 0:
			hp[i] -= near * enemy_dmg * CONTACT_DPS * delta / (spec.hp * mul)
			if hp[i] <= 0.0:
				count -= 1
				lost += 1
				pos[i] = pos[count]; hp[i] = hp[count]; cd[i] = cd[count]; face[i] = face[count]; phase[i] = phase[count]
				continue
		else:
			hp[i] = minf(hp[i] + REGEN * delta, 1.0)
		i += 1
	_draw()

func _draw() -> void:
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
