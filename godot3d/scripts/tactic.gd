extends Node3D
## 책략 하나(D-284): data/tactics.gd의 type마다 동작. 레벨이 오르면 set_level로 수치를 다시 받음.
## 판정은 horde.gd(hit_circle), 여기는 때 · 노리기 · 보이는 것.

var id := ""
var lv := 1
var p: Dictionary
var player: Node3D
var horde: Node3D
var atk_mul := 1.0            # 무력(main이 넣음)
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

func setup(tactic_id: String, pl: Node3D, h: Node3D) -> void:
	id = tactic_id
	player = pl
	horde = h
	mat_blade = _mat(Color("d8dce0"), false)
	mat_blade.metallic = 0.6
	mat_mark = _mat(Color(0.9, 0.25, 0.2, 0.5), true)
	mat_fire = _mat(Color(1.0, 0.45, 0.1, 0.55), true)
	mat_bolt = _mat(Color(1.0, 0.95, 0.5, 0.9), true)
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
	var dmg: float = p.dmg * atk_mul
	match TacticTable.LIST[id].type:
		"orbit":
			spin_a += delta * p.spin
			var n := blades.size()
			for k in n:
				var a := spin_a + TAU * k / n
				var bp: Vector2 = c + Vector2(cos(a), sin(a)) * p.r
				blades[k].position = Vector3(bp.x, 0.8, bp.y)
				blades[k].rotation.y = -a
				hits += horde.hit_circle(bp, p.size, dmg, p.knock, (bp - c).normalized(), 99, c)
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
					hits += horde.hit_circle(e.pos, p.r, dmg, p.knock, Vector2.ZERO, 999, c)
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
				hits += horde.hit_circle(e.pos, p.r, dmg, p.knock, Vector2.ZERO, 999, c)   # 맞음 대기(0.3초)마다 한 번씩
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
					hits += horde.hit_circle(tp, p.r, dmg, p.knock, Vector2.ZERO, 999, c)
					_flash(tp, 6.0, Color(1.0, 0.95, 0.5, 0.9), 0.15)
	for k in range(flashes.size() - 1, -1, -1):
		var f: Dictionary = flashes[k]
		f.t -= delta
		var node: MeshInstance3D = f.node
		(node.material_override as StandardMaterial3D).albedo_color.a = maxf(f.t / f.t0, 0.0) * f.a
		if f.t <= 0.0:
			node.queue_free()
			flashes.remove_at(k)

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
