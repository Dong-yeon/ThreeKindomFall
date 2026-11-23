extends Node3D
## 3D 시제품 시험 판(D-274): 관우 모델을 불러와 들판을 걷는다.
## 명령줄(`--` 뒤): --shots=<폴더>  자동으로 원을 그리며 걷고 스크린샷 몇 장 찍은 뒤 끝냄
##                  --test          모델 · 동작 이름만 확인하고 끝냄(headless 가능)

const CAM_OFFSET := Vector3(0, 4.2, 6.0)
const HERO_GLB := "res://assets/models/guan_yu.glb"

var player: Node3D
var cam: Camera3D
var shots_dir := ""
var shot_times := [0.4, 1.0, 1.6, 2.2, 3.0]
var t := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shots_dir = a.substr(8)
	_build_world()
	player = preload("res://scripts/player.gd").new()
	player.name = "Player"
	add_child(player)
	player.setup(load(HERO_GLB))
	player.auto_walk = shots_dir != ""
	if "--test" in OS.get_cmdline_user_args():
		print("TEST anims=", player.anim_names(), " walk_loop=", player.walk_loops())
		get_tree().quit()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("9fb3c8")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d0d8")
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	add_child(sun)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("8a9a6a")
	ground.material_override = gm
	add_child(ground)

	# 움직임이 보이도록 바위 · 나무를 흩어 둠(저폴리 기본 도형, 시험용)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rock_m := StandardMaterial3D.new(); rock_m.albedo_color = Color("7a7468")
	var trunk_m := StandardMaterial3D.new(); trunk_m.albedo_color = Color("6a4a30")
	var leaf_m := StandardMaterial3D.new(); leaf_m.albedo_color = Color("3f6a3a")
	for i in 70:
		var p := Vector3(rng.randf_range(-50, 50), 0, rng.randf_range(-50, 50))
		if p.length() < 4.0:
			continue
		if rng.randf() < 0.5:
			var r := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radial_segments = 6; sm.rings = 3
			var s := rng.randf_range(0.4, 1.1)
			sm.radius = s; sm.height = s * 1.4
			r.mesh = sm; r.material_override = rock_m
			r.position = p + Vector3(0, s * 0.3, 0)
			add_child(r)
		else:
			var trunk := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.radial_segments = 6; cm.top_radius = 0.12; cm.bottom_radius = 0.18; cm.height = 1.2
			trunk.mesh = cm; trunk.material_override = trunk_m
			trunk.position = p + Vector3(0, 0.6, 0)
			add_child(trunk)
			var leaf := MeshInstance3D.new()
			var lm := CylinderMesh.new()
			lm.radial_segments = 6; lm.top_radius = 0.0; lm.bottom_radius = 1.0; lm.height = 2.2
			leaf.mesh = lm; leaf.material_override = leaf_m
			leaf.position = p + Vector3(0, 2.2, 0)
			add_child(leaf)

	cam = Camera3D.new()
	cam.fov = 55
	add_child(cam)

func _process(delta: float) -> void:
	t += delta
	# 3인칭 고정 각도로 뒤 · 위에서 따라감(마우스 시점은 다음 단계)
	var target := player.position + Vector3(0, 1.0, 0)
	cam.position = cam.position.lerp(target + CAM_OFFSET, clampf(delta * 6.0, 0, 1)) if t > 0.05 else target + CAM_OFFSET
	cam.look_at(target)
	if shots_dir != "" and not shot_times.is_empty() and t >= shot_times[0]:
		shot_times.pop_front()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots_dir)
		var path := shots_dir.path_join("shot_%d.png" % (5 - shot_times.size()))
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if shot_times.is_empty():
			get_tree().quit()
