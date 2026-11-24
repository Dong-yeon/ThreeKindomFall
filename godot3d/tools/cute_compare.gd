extends SceneTree
## 관우 귀여움 실험 비교 사진: 왼쪽 지금 관우(guan_yu.glb, 원래 재질) · 오른쪽 실험(guan_yu_cute.glb + 툰 재질 Toon.apply)을
## 같은 조명 · 같은 각도로 나란히(판 크기 1.2배, idle 첫 장면).
## 실행(창 모드): Godot --path godot3d --script res://tools/cute_compare.gd -- --out=<폴더> [--cam=높이,뒤,화각]

var out := "."
var cam_off := Vector3(0, 2.6, 9.0)
var fov := 32.0
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
	var env := WorldEnvironment.new()   # 조명은 model_compare.gd와 같게
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
	_put(root3, "res://assets/models/guan_yu.glb", Vector3(-1.4, 0, 0), false)
	_put(root3, "res://assets/models/guan_yu_cute.glb", Vector3(1.4, 0, 0), true)
	var cam := Camera3D.new()
	cam.fov = fov
	root3.add_child(cam)
	var look := Vector3(0, 1.35, 0)
	var cp := look + cam_off
	cam.transform = Transform3D(Basis.looking_at(look - cp), cp)

func _put(parent: Node3D, path: String, pos: Vector3, toon: bool) -> void:
	var m := load(path).instantiate() as Node3D
	m.position = pos
	m.scale = Vector3.ONE * 1.2
	parent.add_child(m)
	if toon:
		Toon.apply(m, 0.4)
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.play("idle")
		ap.seek(0.0, true)
		ap.pause()

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 10:
		DirAccess.make_dir_recursive_absolute(out)
		var img := root.get_viewport().get_texture().get_image()
		var p := out.path_join("cute_compare.png")
		img.save_png(p)
		print("SHOT ", p)
		return true
	return false
