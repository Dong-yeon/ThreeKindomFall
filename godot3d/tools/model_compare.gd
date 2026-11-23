extends SceneTree
## 모델 비교 사진(D-301 시험): 지금 관우 · 큰 머리 관우(서기 · 휘두르기 · 휘청 · 엉덩방아)와 황건적을 게임 조명 · 카메라로 나란히 찍음.
## 실행(창 모드): Godot --path godot3d --script res://tools/model_compare.gd -- --out=<폴더> [--cam=높이,뒤,화각]

var out := "."
var cam_off := Vector3(0, 16, 12)
var fov := 50.0
var frames := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--cam="):
			var v := a.substr(6).split(",")
			cam_off = Vector3(0, float(v[0]), float(v[1]))
			if v.size() > 2:
				fov = float(v[2])
	var root3 := Node3D.new()
	root.add_child(root3)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("9fb3c8")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d0d8")
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	root3.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	root3.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("8a9a6a")
	g.material_override = gm
	root3.add_child(g)
	# 줄: 지금 관우 | 큰 머리 관우 서기 · 휘두르기 · 휘청 · 엉덩방아
	_put(root3, "res://assets/models/guan_yu.glb", Vector3(-6, 0, 0), "idle", 0.0)
	_put(root3, "res://assets/models/guan_yu_chibi.glb", Vector3(-3, 0, 0), "idle", 0.0)
	_put(root3, "res://assets/models/guan_yu_chibi.glb", Vector3(0, 0, 0), "swing", 0.36)
	_put(root3, "res://assets/models/guan_yu_chibi.glb", Vector3(3, 0, 0), "stagger", 0.35)
	_put(root3, "res://assets/models/guan_yu_chibi.glb", Vector3(6, 0, 0), "flop", 0.6)
	# 크기 비교용 황건적(뒷줄)
	for k in 6:
		var y := load("res://assets/models/yellow_turban.glb").instantiate() as Node3D
		y.position = Vector3(-7.5 + k * 3.0, 0, -3.5)
		root3.add_child(y)
	var cam := Camera3D.new()
	cam.fov = fov
	root3.add_child(cam)
	var cp := Vector3(0, 1, 0) + cam_off
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 1, 0) - cp), cp)   # _initialize에선 아직 트리 밖이라 look_at 대신

func _put(parent: Node3D, path: String, pos: Vector3, anim: String, at: float) -> void:
	var m := load(path).instantiate() as Node3D
	m.position = pos
	parent.add_child(m)
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(anim):
		ap.play(anim)
		ap.seek(at, true)
		ap.pause()

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 10:
		DirAccess.make_dir_recursive_absolute(out)
		var img := root.get_viewport().get_texture().get_image()
		var p := out.path_join("compare.png")
		img.save_png(p)
		print("SHOT ", p)
		return true
	return false
