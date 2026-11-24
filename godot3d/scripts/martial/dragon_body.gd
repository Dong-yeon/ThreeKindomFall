extends Node3D
## 청룡 몸(D-335): assets/models/qinglong.glb의 조각(머리 · 아래턱 · 몸 마디 · 꼬리 · 앞다리)을 머리가 지나온 길을 따라 늘어놓음.
## 쓰는 쪽(절기 모듈)은 매 프레임 push(머리 자리) → pose(). 길이 모자라면(막 나왔을 때) 처음 방향으로 늘여 놓음.
## 청록 반투명 리본 잔상 여러 겹(덧셈 섞기)이 몸을 따라감. roar(0~1) 아래턱 벌림 · fade(0~1) 사라짐.

const GLB := "res://assets/models/qinglong.glb"
const SEG_N := 22             # 몸 마디 수
const SPACING := 0.42         # 마디 사이(모델 단위 — 배율을 곱함)
const HEAD_GAP := 0.55        # 머리 중심 → 첫 마디
const RIBBONS := [            # 리본 잔상: [옆 거리, 높이, 폭, 출렁임 위상] (모델 단위)
	[0.95, 0.15, 0.22, 0.0], [-0.95, -0.1, 0.22, 2.1], [0.0, 0.95, 0.18, 4.2], [0.6, -0.7, 0.16, 1.0]]
const RIB_LEN := 1.6          # 리본 길이 = 몸 길이 × 이 배

var size := 1.4               # 모델 배율(관우 키 2.4 기준 — 머리 폭 약 1.5m)
var hist := PackedVector3Array()   # 머리가 지나온 자리(마지막이 지금)
var start_dir := Vector3.UP   # 길이 모자랄 때 늘여 놓을 쪽(머리 → 꼬리)
var roar := 0.0
var fade := 1.0
var head: Node3D
var jaw: Node3D
var segs: Array[Node3D] = []
var tail: Node3D
var legs: Array[Node3D] = []
var rib_mesh: ImmediateMesh
var rib_node: MeshInstance3D
var t := 0.0

func _ready() -> void:
	var src: Node = load(GLB).instantiate()
	var meshes := {}
	for mi in src.find_children("*", "MeshInstance3D", true, false):
		meshes[String(mi.name).get_slice("_", 0)] = (mi as MeshInstance3D).mesh
	src.free()
	head = _part(meshes.get("head"))
	jaw = _part(meshes.get("jaw"))
	remove_child(jaw)
	head.add_child(jaw)
	jaw.position = Vector3(0, -0.18, 0)
	for k in SEG_N:
		segs.append(_part(meshes.get("seg")))
	tail = _part(meshes.get("tail"))
	for sx in [1.0, -1.0]:   # 앞다리 둘(왼쪽은 x를 뒤집음) — 세 번째 마디에 붙음
		var lg := _part(meshes.get("leg"))
		remove_child(lg)
		segs[2].add_child(lg)
		lg.position = Vector3(sx * 0.32, -0.12, 0)
		lg.scale = Vector3(sx, 1, 1)
		legs.append(lg)
	rib_mesh = ImmediateMesh.new()
	rib_node = MeshInstance3D.new()
	rib_node.mesh = rib_mesh
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.cull_mode = BaseMaterial3D.CULL_DISABLED
	rm.vertex_color_use_as_albedo = true
	rib_node.material_override = rm
	rib_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rib_node.top_level = true
	add_child(rib_node)

func _part(m: Mesh) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	add_child(mi)
	return mi

func push(p: Vector3) -> void:
	if hist.is_empty() or hist[hist.size() - 1].distance_to(p) > 0.04:
		hist.append(p)
	# 리본 길이보다 오래된 것은 버림
	var need := (HEAD_GAP + SPACING * (SEG_N + 2)) * size * RIB_LEN + 1.0
	var acc := 0.0
	for i in range(hist.size() - 1, 0, -1):
		acc += hist[i].distance_to(hist[i - 1])
		if acc > need:
			hist = hist.slice(i - 1)
			break

func _sample(d: float) -> Vector3:
	## 머리에서 길을 따라 d만큼 뒤 자리. 길이 모자라면 가장 오래된 자리에서 start_dir로 늘임.
	if hist.is_empty():
		return Vector3.ZERO
	var acc := 0.0
	for i in range(hist.size() - 1, 0, -1):
		var seg := hist[i].distance_to(hist[i - 1])
		if acc + seg >= d:
			return hist[i].lerp(hist[i - 1], (d - acc) / maxf(seg, 0.0001))
		acc += seg
	return hist[0] + start_dir * (d - acc)

func _face(n: Node3D, at: Vector3, toward: Vector3) -> void:
	n.position = at
	var dir := toward - at
	if dir.length() < 0.0001:
		return
	var up := Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.FORWARD
	n.look_at(toward, up)

func pose(delta: float) -> void:
	t += delta
	if hist.is_empty():
		return
	var s := size * maxf(fade, 0.01)
	var hp := hist[hist.size() - 1]
	_face(head, hp, hp + (hp - _sample(0.3)))
	head.rotate_object_local(Vector3.RIGHT, roar * 0.45)   # 포효: 고개를 쳐듦
	head.scale = Vector3.ONE * s
	jaw.rotation.x = -roar * 0.75   # 아래턱 벌림
	for k in SEG_N:
		var d := (HEAD_GAP + SPACING * k) * size
		var p := _sample(d)
		_face(segs[k], p, _sample(maxf(d - SPACING * size, 0.0)))
		var taper := lerpf(1.0, 0.5, float(k) / SEG_N)
		segs[k].scale = Vector3(taper, taper, 1.15) * s   # 앞뒤로 늘여 겹침(구슬처럼 안 보이게)
	var td := (HEAD_GAP + SPACING * (SEG_N + 0.6)) * size
	_face(tail, _sample(td), _sample(td - SPACING * size))
	tail.scale = Vector3.ONE * 0.85 * s
	_ribbons()

func _ribbons() -> void:
	rib_mesh.clear_surfaces()
	if hist.size() < 2 or fade <= 0.01:
		return
	var body_len := (HEAD_GAP + SPACING * (SEG_N + 2)) * size
	var length := body_len * RIB_LEN
	var steps := 34
	rib_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for rb in RIBBONS:
		var pts := []
		for i in steps + 1:
			var d := length * i / steps
			var p := _sample(d)
			var fw := (p - _sample(d + 0.3)).normalized()
			var up := Vector3.UP if absf(fw.y) < 0.95 else Vector3.FORWARD
			var side := fw.cross(up).normalized()
			var up2 := side.cross(fw).normalized()
			var wob := sin(t * 6.0 + rb[3] + d * 0.8) * 0.25
			var off: Vector3 = side * (rb[0] + wob) * size + up2 * rb[1] * size
			var wv: Vector3 = (up2 if absf(rb[0]) > 0.1 else side) * rb[2] * size
			var a := (1.0 - float(i) / steps) * 0.42 * fade
			pts.append([p + off, wv, a])
		for i in steps:
			var p0: Array = pts[i]
			var p1: Array = pts[i + 1]
			var c0 := Color(0.2, 0.85, 0.7, p0[2])
			var c1 := Color(0.2, 0.85, 0.7, p1[2])
			var v := [p0[0] - p0[1], p0[0] + p0[1], p1[0] + p1[1], p1[0] - p1[1]]
			var cs := [c0, c0, c1, c1]
			for idx in [0, 1, 2, 0, 2, 3]:
				rib_mesh.surface_set_color(cs[idx])
				rib_mesh.surface_add_vertex(v[idx])
	rib_mesh.surface_end()
