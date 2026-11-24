extends SceneTree
## 동작 프레임 찍기(D-313): 모델 하나에 동작을 틀고 프레임마다 PNG(GIF로 묶어 보기용).
## 실행(창 모드): Godot --path godot3d --script res://tools/anim_shots.gd -- --model=guan_yu --anim=down --frames=60 --out=<폴더>

var out := "."
var anim_name := "idle"
var frames := 48
var f := 0

func _initialize() -> void:
	var model_id := "guan_yu"
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv.size() < 2:
			continue
		match kv[0]:
			"out": out = kv[1]
			"model": model_id = kv[1]
			"anim": anim_name = kv[1]
			"frames": frames = int(kv[1])
	var r := Node3D.new()
	root.add_child(r)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("9fb3c8")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d0d8")
	e.ambient_light_energy = 0.4
	env.environment = e
	r.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	r.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("8a9a6a")
	g.material_override = gm
	r.add_child(g)
	var m := load("res://assets/models/%s.glb" % model_id).instantiate() as Node3D
	m.rotation.y = 0.5
	r.add_child(m)
	var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(anim_name):
		ap.play(anim_name)
	var cam := Camera3D.new()
	cam.fov = 40
	r.add_child(cam)
	var cp := Vector3(0, 3.2, 5.5)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.8, 0) - cp), cp)
	DirAccess.make_dir_recursive_absolute(out)

func _process(_d: float) -> bool:
	f += 1
	if f > 3 and f % 2 == 0:
		root.get_viewport().get_texture().get_image().save_png(out.path_join("f_%03d.png" % (f / 2)))
	return f > frames * 2 + 4
