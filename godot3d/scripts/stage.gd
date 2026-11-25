extends Node3D
## 황건적 스테이지(D-289): 맵 경계 목책 · 진영 3곳(목책 고리 · 천막 · 깃발 · 제단) · 흙길 · 진영 정예(foe.gd) ·
## 보상 상자 · 화면 가장자리의 진영 방향 표시. 수치는 data/stage_yellow.gd.

signal chest_opened

var horde: Node3D
var player: Node3D
var cam: Camera3D
var camps: Array = []         # [{spec, foe, alive, broken_t, marker: Label, chest: Node3D}]
var font: Font
var foes: Array = []          # 판에 있는 적장(진영 정예 + 보스)
var broken_log: Array[String] = []
var boss_mode := false        # 보스전 중엔 진영 표시를 끔

func setup(h: Node3D, pl: Node3D, camera: Camera3D, layer: CanvasLayer, f: Font) -> void:
	horde = h
	player = pl
	cam = camera
	font = f
	horde.bounds = StageYellow.BOUNDS
	horde.camp_share = StageYellow.CAMP_SHARE
	_build_ground()
	for cs in StageYellow.CAMPS:
		var c := {"spec": cs, "alive": true, "broken_t": -1.0, "chest": null}
		_build_camp(cs)
		var fo = preload("res://scripts/foe/foe.gd").new()
		add_child(fo)
		fo.setup(cs.foe, cs.pos, horde, font)
		fo.died.connect(_on_foe_died)
		horde.targets.append(fo)
		foes.append(fo)
		c["foe"] = fo
		var lb := Label.new()   # 진영 방향 표시
		lb.add_theme_font_size_override("font_size", 18)
		lb.add_theme_color_override("font_color", Color("ffd860"))
		lb.add_theme_color_override("font_outline_color", Color.BLACK)
		lb.add_theme_constant_override("outline_size", 5)
		layer.add_child(lb)
		c["marker"] = lb
		camps.append(c)
	_update_spawn_points()

func _mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	return m

func _multimesh(mesh: Mesh, xforms: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	add_child(inst)

func _build_ground() -> void:
	# 맵 가장자리 목책(말뚝) — 장수 · 적은 경계 안에 묶임
	var post := BoxMesh.new()
	post.size = Vector3(0.35, 2.2, 0.35)
	post.material = _mat(Color("6a4a30"))
	var xs: Array[Transform3D] = []
	var b: Rect2 = StageYellow.BOUNDS
	var step := 2.0
	var x := b.position.x
	while x <= b.end.x:
		for zz in [b.position.y, b.end.y]:
			xs.append(Transform3D(Basis(Vector3.UP, randf() * 0.3), Vector3(x, 1.1, zz)))
		x += step
	var z := b.position.y
	while z <= b.end.y:
		for xx in [b.position.x, b.end.x]:
			xs.append(Transform3D(Basis(Vector3.UP, randf() * 0.3), Vector3(xx, 1.1, z)))
		z += step
	_multimesh(post, xs)
	# 가운데에서 진영으로 가는 흙길
	var path_m := _mat(Color("a8925e"))
	for cs in StageYellow.CAMPS:
		var to: Vector2 = cs.pos
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3.0, 0.02, to.length())
		bm.material = path_m
		mi.mesh = bm
		mi.position = Vector3(to.x * 0.5, 0.01, to.y * 0.5)
		mi.rotation.y = atan2(to.x, to.y)
		add_child(mi)

func _build_camp(cs: Dictionary) -> void:
	var c: Vector2 = cs.pos
	var r: float = cs.r
	# 흙바닥
	var floor_mi := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = r + 1.0; fm.bottom_radius = r + 1.0; fm.height = 0.02; fm.radial_segments = 24
	fm.material = _mat(Color("9a8456"))
	floor_mi.mesh = fm
	floor_mi.position = Vector3(c.x, 0.015, c.y)
	add_child(floor_mi)
	# 목책 고리(드나들 틈 두 곳)
	var post := BoxMesh.new()
	post.size = Vector3(0.3, 1.6, 0.3)
	post.material = _mat(Color("7a5a38"))
	var xs: Array[Transform3D] = []
	for k in 40:
		var a := TAU * k / 40.0
		if absf(angle_difference(a, 0.3)) < 0.35 or absf(angle_difference(a, PI + 0.3)) < 0.35:
			continue
		xs.append(Transform3D(Basis(), Vector3(c.x + cos(a) * r, 0.8, c.y + sin(a) * r)))
	_multimesh(post, xs)
	# 천막 셋 · 누런 깃발 둘
	var tent_m := _mat(Color("c8b48a"))
	for k in 3:
		var a := TAU * k / 3.0 + 0.6
		var tm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0; cm.bottom_radius = 1.6; cm.height = 2.2; cm.radial_segments = 6
		cm.material = tent_m
		tm.mesh = cm
		tm.position = Vector3(c.x + cos(a) * r * 0.55, 1.1, c.y + sin(a) * r * 0.55)
		add_child(tm)
	var flag_m := _mat(Color("c9a03a"))
	for k in 2:
		var a := PI * k + 1.2
		var pole := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.1, 4.0, 0.1)
		pm.material = _mat(Color("4a3424"))
		pole.mesh = pm
		var at := Vector3(c.x + cos(a) * (r - 1.0), 2.0, c.y + sin(a) * (r - 1.0))
		pole.position = at
		add_child(pole)
		var fl := MeshInstance3D.new()
		var fbm := BoxMesh.new()
		fbm.size = Vector3(1.2, 0.8, 0.04)
		fbm.material = flag_m
		fl.mesh = fbm
		fl.position = at + Vector3(0.6, 1.5, 0)
		add_child(fl)
	if cs.id == "daoshi":   # 제단(돌 + 불)
		var alt := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(2.0, 0.8, 2.0)
		am.material = _mat(Color("8a8478"))
		alt.mesh = am
		alt.position = Vector3(c.x, 0.4, c.y - 2.5)
		add_child(alt)

func _on_foe_died(fo) -> void:
	for c in camps:
		if c.foe == fo and c.alive:
			c.alive = false
			c.broken_t = fo.now
			broken_log.append("%s@%.1f" % [c.spec.id, fo.now])
			_update_spawn_points()
			var chest := _make_chest(c.spec.pos)
			c.chest = chest
			get_parent()._banner("%s을(를) 깨뜨렸다!\n보상 상자가 떨어졌다" % c.spec.name, 2.5)
			print("CAMP broken %s t=%.1f" % [c.spec.id, fo.now])

func _make_chest(at: Vector2) -> Node3D:
	var n := Node3D.new()
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.7, 0.7)
	bm.material = _mat(Color("7a4a24"))
	box.mesh = bm
	box.position.y = 0.35
	n.add_child(box)
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.05, 0.12, 0.75)
	var gm := _mat(Color("e8c040"))
	gm.emission_enabled = true
	gm.emission = Color("a88020")
	bb.material = gm
	band.mesh = bb
	band.position.y = 0.55
	n.add_child(band)
	n.position = Vector3(at.x, 0, at.y)
	add_child(n)
	return n

func _update_spawn_points() -> void:
	var pts := PackedVector2Array()
	for c in camps:
		if c.alive:
			pts.append(c.spec.pos)
	horde.spawn_points = pts

func alive_camps() -> Array:
	var out := []
	for c in camps:
		if c.alive:
			out.append(c)
	return out

func build_arena(c: Vector2, r: float) -> void:
	## 호뢰관 목책 고리(D-290 — 2D판 일기토 울타리처럼). 장수는 main이 고리 안에 묶음.
	var post := BoxMesh.new()
	post.size = Vector3(0.4, 2.0, 0.4)
	post.material = _mat(Color("5a3a24"))
	var xs: Array[Transform3D] = []
	for k in 56:
		var a := TAU * k / 56.0
		xs.append(Transform3D(Basis(), Vector3(c.x + cos(a) * r, 1.0, c.y + sin(a) * r)))
	_multimesh(post, xs)
	var fl := MeshInstance3D.new()   # 붉은 바닥 테
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.3; tm.outer_radius = r + 0.3; tm.rings = 48; tm.ring_segments = 4
	tm.material = _mat(Color("8a2a22"))
	fl.mesh = tm
	fl.position = Vector3(c.x, 0.02, c.y)
	fl.scale = Vector3(1, 0.05, 1)
	add_child(fl)

func add_foe(fo) -> void:
	## 보스 등 진영 밖 적장(D-290).
	foes.append(fo)
	horde.targets.append(fo)

func tick(delta: float, p2: Vector2, dmg_mul: float, now: float) -> float:
	## 적장 · 상자 · 진영 표시. 돌려주는 값 = 적장이 장수에게 준 피해 합.
	var dmg := 0.0
	for fo in foes:
		if fo.alive:
			fo.now = now
			dmg += fo.tick(delta, p2, dmg_mul)
	var vs := get_viewport().get_visible_rect().size
	for c in camps:
		if c.chest and is_instance_valid(c.chest):
			c.chest.rotation.y += delta
			if Vector2(c.chest.position.x, c.chest.position.z).distance_to(p2) < 1.6:
				c.chest.queue_free()
				c.chest = null
				chest_opened.emit()
		var lb: Label = c.marker
		lb.visible = c.alive and not boss_mode
		if not c.alive or boss_mode:
			continue
		var cp: Vector2 = c.spec.pos
		var w := Vector3(cp.x, 2.0, cp.y)
		var dist := cp.distance_to(p2)
		lb.text = "◆ %s %dm" % [c.spec.name, int(dist)]
		var sp := cam.unproject_position(w)
		var behind := cam.is_position_behind(w)
		var margin := 60.0
		if behind or sp.x < margin or sp.y < margin or sp.x > vs.x - margin or sp.y > vs.y - margin:
			# 화면 밖: 장수 → 진영 방향으로 화면 가장자리에
			var dir := (cp - p2).normalized()
			var center := vs * 0.5
			var sd := Vector2(dir.x, dir.y)
			var k := minf((vs.x * 0.5 - margin) / maxf(absf(sd.x), 0.001), (vs.y * 0.5 - margin) / maxf(absf(sd.y), 0.001))
			sp = center + sd * k
		lb.position = sp - Vector2(60, 12)
	return dmg
