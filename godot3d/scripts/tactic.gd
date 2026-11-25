extends Node3D
## 책략 하나(D-284): data/tactics.gd의 type마다 동작. 레벨이 오르면 set_level로 수치를 다시 받음.
## 판정은 horde.gd(hit_circle), 여기는 때 · 노리기 · 보이는 것.

var id := ""
var lv := 1
var p: Dictionary
var player: Node3D
var horde: Node3D
var atk_mul := 1.0            # 무력(main이 넣음)
var strat_mul := 1.0          # 책략 계열 배율(예전 제갈량 와룡 — main이 넣음, D-295 · 지금은 쓰는 장수 없음)
var weather_mul := 1.0        # 날씨 피해 배율(천기 — 번개 때 낙뢰 · 동남풍 때 불, D-334)
var knock_mul := 1.0          # 날씨 밀침 배율(천기 바람)
var ch := 3                   # 맞음 대기 채널(D-287 — main이 슬롯마다 다르게)
var cd := 0.5
var fired := 0                # 발동 횟수(--stats)
var hits := 0                 # 맞힌 적 수(--stats)
var spin_a := 0.0
var blades: Array[MeshInstance3D] = []
var pending: Array = []       # rain: [{pos, t, node}] · fire: [{pos, t, node}] · bolt 효과: [{node, t}]
var fires: Array = []
var flashes: Array = []
var mat_blade: StandardMaterial3D
var mat_mark: StandardMaterial3D
var mat_fire: StandardMaterial3D
var mat_bolt: StandardMaterial3D
var shots: Array = []         # xbow · knives: [{node, pos, dir, left, pierce}]
var shot_mesh: Mesh
var ring: MeshInstance3D      # drum 북 고리
var ring_t := 0.0
var walked := 0.0             # flamestep: 지난 불 뒤로 걸은 거리
var last_c := Vector2.INF
var chains := 0               # 낙뢰가 튄 수(--stats)

func setup(tactic_id: String, pl: Node3D, h: Node3D) -> void:
	id = tactic_id
	player = pl
	horde = h
	mat_blade = _mat(Color("d8dce0"), false)
	mat_blade.metallic = 0.6
	mat_mark = _mat(Color(0.9, 0.25, 0.2, 0.5), true)
	mat_fire = _mat(Color(1.0, 0.72, 0.15, 0.45), true)   # 노란 주황 — 적장 예고(붉은색)와 구분(D-290)
	mat_bolt = _mat(Color(1.0, 0.95, 0.5, 0.9), true)
	match TacticTable.LIST[id].type:
		"xbow", "knives":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.1, 0.1, 1.1) if TacticTable.LIST[id].type == "xbow" else Vector3(0.18, 0.06, 0.75)   # D-308: 보이는 크기 ×1.4
			shot_mesh = bm
		"drum":
			ring = _disc(1.0, _mat(Color(0.95, 0.75, 0.35, 0.0), true))
	set_level(1)

func _mat(c: Color, glow: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func set_level(n: int) -> void:
	lv = n
	p = TacticTable.params(id, lv)
	if TacticTable.LIST[id].type == "orbit":
		for b in blades:
			b.queue_free()
		blades.clear()
		for k in int(p.blades):
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.95 * p.size / 0.5, 0.06, 0.24)
			mi.mesh = bm
			mi.material_override = mat_blade
			add_child(mi)
			blades.append(mi)

func _disc(r: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r; cm.bottom_radius = r; cm.height = 0.04; cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = mat.duplicate()
	add_child(mi)
	return mi

func tick(delta: float) -> void:
	var c := Vector2(player.position.x, player.position.z)
	var dmg: float = p.dmg * atk_mul * strat_mul * weather_mul
	var kn: float = p.knock * knock_mul
	match TacticTable.LIST[id].type:
		"orbit":
			spin_a += delta * p.spin
			var n := blades.size()
			for k in n:
				var a := spin_a + TAU * k / n
				var bp: Vector2 = c + Vector2(cos(a), sin(a)) * p.r
				blades[k].position = Vector3(bp.x, 0.8, bp.y)
				blades[k].rotation.y = -a
				hits += horde.hit_circle(bp, p.size, dmg, kn, (bp - c).normalized(), 99, c, ch)
		"rain":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				for tp in _targets(c, int(p.count)):
					pending.append({"pos": tp, "t": p.delay, "node": _mark(tp, p.r)})
			for k in range(pending.size() - 1, -1, -1):
				var e: Dictionary = pending[k]
				e.t -= delta
				var node: MeshInstance3D = e.node
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.25 + 0.5 * (1.0 - e.t / p.delay)
				if e.t <= 0.0:
					hits += horde.hit_circle(e.pos, p.r, dmg, kn, Vector2.ZERO, 999, c, ch)
					node.queue_free()
					pending.remove_at(k)
					_flash(e.pos, 2.5, Color(0.9, 0.85, 0.6, 0.8), 0.12)
		"fire":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				for tp in _targets(c, int(p.count)):
					var d := _disc(p.r, mat_fire)
					d.position = Vector3(tp.x, 0.05, tp.y)
					fires.append({"pos": tp, "t": p.dur, "node": d})
			for k in range(fires.size() - 1, -1, -1):
				var e: Dictionary = fires[k]
				e.t -= delta
				hits += horde.hit_circle(e.pos, p.r, dmg, kn, Vector2.ZERO, 999, c, ch)   # 맞음 대기(0.3초)마다 한 번씩
				var node: MeshInstance3D = e.node
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.35 + 0.2 * sin(e.t * 12.0)
				if e.t <= 0.0:
					node.queue_free()
					fires.remove_at(k)
		"bolt":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				for tp in horde.random_in(c, p.seek, int(p.count)):
					hits += horde.hit_circle(tp, p.r, dmg, kn, Vector2.ZERO, 999, c, ch)
					_flash(tp, 6.0, Color(1.0, 0.95, 0.5, 0.9), 0.15)
					var at: Vector2 = tp
					for j in int(p.get("chain", 0)):   # 연쇄(D-294): 맞은 자리에서 가장 가까운 아직 안 맞은 적에게(맞음 대기로 같은 적은 빠짐)
						var nx: PackedVector2Array = horde.nearest(at, 4.5, 3)
						var to := Vector2.INF
						for q in nx:
							if q.distance_to(at) > p.r:
								to = q
								break
						if to == Vector2.INF:
							break
						hits += horde.hit_circle(to, p.r, dmg * 0.7, kn, Vector2.ZERO, 999, c, ch)
						_flash(to, 4.0, Color(0.8, 0.9, 1.0, 0.9), 0.15)
						chains += 1
						at = to
		"xbow":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				var d0 := _aim_dir(c)
				var n := int(p.count)
				for k in n:
					_shoot(c, d0.rotated(p.spread * (k - (n - 1) * 0.5)))
		"knives":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				var n := int(p.count)
				var tg: PackedVector2Array = horde.nearest(c, p.seek, n)
				for k in n:
					var d := (tg[k] - c).normalized() if k < tg.size() and tg[k].distance_to(c) > 0.01 else Vector2.from_angle(TAU * k / n + randf())
					_shoot(c, d)
		"drum":
			cd -= delta
			if cd <= 0.0:
				cd = p.cd
				fired += 1
				hits += horde.hit_circle(c, p.r, dmg, 0.0, Vector2.ZERO, 999, c, ch)
				horde.push_from(c, p.r, p.push)
				ring_t = 0.35
			ring_t = maxf(ring_t - delta, 0.0)
			var k := 1.0 - ring_t / 0.35
			ring.position = Vector3(c.x, 0.06, c.y)
			ring.scale = Vector3(p.r * (0.4 + 0.6 * k), 1.0, p.r * (0.4 + 0.6 * k))
			(ring.material_override as StandardMaterial3D).albedo_color.a = 0.45 * (ring_t / 0.35)
		"flamestep":
			if last_c != Vector2.INF:
				walked += c.distance_to(last_c)
			last_c = c
			if walked >= p.step:
				walked = 0.0
				fired += 1
				var d := _disc(p.r, mat_fire)
				d.position = Vector3(c.x, 0.05, c.y)
				fires.append({"pos": c, "t": p.dur, "node": d})
			for k in range(fires.size() - 1, -1, -1):
				var e: Dictionary = fires[k]
				e.t -= delta
				hits += horde.hit_circle(e.pos, p.r, dmg, 0.0, Vector2.ZERO, 999, c, ch)
				var node: MeshInstance3D = e.node
				(node.material_override as StandardMaterial3D).albedo_color.a = 0.25 + 0.2 * clampf(e.t / p.dur, 0.0, 1.0)
				if e.t <= 0.0:
					node.queue_free()
					fires.remove_at(k)
	# 날아가는 화살 · 칼(연노 · 비도)
	for k in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[k]
		var step: float = p.speed * delta
		s.pos += s.dir * step
		s.left -= step
		var hn: int = horde.hit_circle(s.pos, p.r, dmg, kn, s.dir, s.pierce, c, ch)
		s.pierce -= hn
		hits += hn
		var node: MeshInstance3D = s.node
		node.position = Vector3(s.pos.x, 0.9, s.pos.y)
		node.rotation.y = atan2(s.dir.x, s.dir.y)
		if s.left <= 0.0 or s.pierce <= 0:
			node.queue_free()
			shots.remove_at(k)
	for k in range(flashes.size() - 1, -1, -1):
		var f: Dictionary = flashes[k]
		f.t -= delta
		var node: MeshInstance3D = f.node
		(node.material_override as StandardMaterial3D).albedo_color.a = maxf(f.t / f.t0, 0.0) * f.a
		if f.t <= 0.0:
			node.queue_free()
			flashes.remove_at(k)

func _aim_dir(c: Vector2) -> Vector2:
	## 가장 가까운 적 쪽(없으면 장수가 보는 쪽).
	var tg: PackedVector2Array = horde.nearest(c, p.seek, 1)
	if not tg.is_empty() and tg[0].distance_to(c) > 0.01:
		return (tg[0] - c).normalized()
	return Vector2(sin(player.rotation.y), cos(player.rotation.y))

func _shoot(c: Vector2, d: Vector2) -> void:
	var n := MeshInstance3D.new()
	n.mesh = shot_mesh
	n.material_override = mat_blade
	add_child(n)
	shots.append({"node": n, "pos": c, "dir": d, "left": p.range, "pierce": int(p.pierce)})

func _targets(c: Vector2, n: int) -> PackedVector2Array:
	## 가까운 적 쪽(없으면 장수 둘레 아무 데나).
	var out: PackedVector2Array = horde.nearest(c, p.seek, n)
	while out.size() < n:
		out.append(c + Vector2.from_angle(randf() * TAU) * randf_range(2.0, 5.0))
	return out

func _mark(tp: Vector2, r: float) -> MeshInstance3D:
	var d := _disc(r, mat_mark)
	d.position = Vector3(tp.x, 0.05, tp.y)
	return d

func _flash(tp: Vector2, h: float, col: Color, life: float) -> void:
	## 세로 기둥 번쩍임(화살 비 떨어짐 · 벼락).
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.25, h, 0.25)
	mi.mesh = bm
	var m := mat_bolt.duplicate() as StandardMaterial3D
	m.albedo_color = col
	mi.material_override = m
	mi.position = Vector3(tp.x, h * 0.5, tp.y)
	add_child(mi)
	flashes.append({"node": mi, "t": life, "t0": life, "a": col.a})
