extends SceneTree
## 관우 귀여움 실험 비교 사진: 왼쪽 지금 관우(guan_yu.glb, 원래 재질) · 오른쪽 실험(guan_yu_cute.glb + 툰 재질 Toon.apply)을
## 같은 조명 · 같은 각도로 나란히(판 크기 1.2배, idle 첫 장면).
## 실행(창 모드): Godot --path godot3d --script res://tools/cute_compare.gd -- --out=<폴더> [--cam=높이,뒤,화각]
## 2차(D-337): 환경광 · 해 = 판 0.35 · 0.55 → 0.4 · 0.2(3차, D-339) · 부드러운 그림자(shadow_blur · 부드러운 필터) — 판 조명은 그대로(이 비교 사진에만).
##   --no-ssao: SSAO 끄고(켠 것과 비교). SSAO는 Forward+에서만 — 보려면 --rendering-method forward_plus로 실행.
##   --solo: 실험 관우만 가운데 정면으로(설정화 정면과 맞대기용, cute_front.png) · 툰 적용 재질 수 · 값을 출력.

var out := "."
var cam_off := Vector3(0, 2.6, 9.0)
var fov := 32.0
var frames := 0
var solo := false
var ssao := true               # --no-ssao: SSAO 끄고 찍기(켠 것과 비교용)

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--cam="):
			var v := a.substr(6).split(",")
			cam_off = Vector3(0, float(v[0]), float(v[1]))
			if v.size() > 2:
				fov = float(v[2])
		elif a == "--solo":
			solo = true
		elif a == "--no-ssao":
			ssao = false
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	var root3 := Node3D.new()
	root.add_child(root3)
	var env := WorldEnvironment.new()   # 조명은 model_compare.gd와 같게
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("9fb3c8")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d0d8")
	e.ambient_light_energy = 0.4   # 2차: 해보다 환경광 비중을 높임(판은 0.35 · 해 0.55) — 3차: 전체 밝기를 설정화 색에 맞춰 낮춤
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.ssao_enabled = ssao          # 4차(D-340): 판과 같은 은은한 SSAO(Forward+에서만 그려짐)
	e.ssao_radius = 0.5
	e.ssao_intensity = 3.0
	e.ssao_power = 1.5
	e.ssao_light_affect = 0.25   # 직사광 쪽에도 조금(0이면 환경광에만 걸려 거의 안 보임)
	env.environment = e
	root3.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.2   # 2차 · 3차: 환경광 비중을 높이고 전체는 낮춤(0.6 · 0.35면 녹색이 형광처럼 뜸)
	sun.shadow_enabled = true
	sun.shadow_blur = 2.5          # 2차: 부드러운 그림자
	root3.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	g.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("8a9a6a")
	g.material_override = gm
	root3.add_child(g)
	if solo:
		_put(root3, "res://assets/models/guan_yu_cute.glb", Vector3.ZERO, true)
	else:
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
		print("TOON materials=%d" % Toon.apply(m, 0.4))
		for c in m.find_children("*", "MeshInstance3D", true, false):
			var mt := (c as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
			if mt:
				print("TOON check diffuse_mode=%d(toon=%d) specular_mode=%d(toon=%d) rim_enabled=%s rim=%.2f" % [
					mt.diffuse_mode, BaseMaterial3D.DIFFUSE_TOON, mt.specular_mode, BaseMaterial3D.SPECULAR_TOON, mt.rim_enabled, mt.rim])
				break
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
		var p := out.path_join("cute_front.png" if solo else "cute_compare.png")
		img.save_png(p)
		print("SHOT ", p)
		return true
	return false
