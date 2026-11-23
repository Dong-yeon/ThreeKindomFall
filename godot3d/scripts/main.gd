extends Node3D
## 3D 시제품 시험 판(D-274 · D-275): 관우가 들판을 걷고, 황건적 떼가 몰려온다.
## 옵션 — 명령줄(`--` 뒤) 또는 웹 주소(?n=500&bench=1):
##   --n=<수>        적 수(기본 300)
##   --bench         성능 시험: 자동으로 걷고 적 수를 200→1000으로 올리며 단계마다 FPS · 갱신 시간을 잼, 끝나면 표를 출력
##   --shots=<폴더>  자동으로 원을 그리며 걷고 스크린샷 몇 장 찍은 뒤 끝냄
##   --test          모델 · 동작 이름만 확인하고 끝냄(headless 가능)

const CAM_OFFSET := Vector3(0, 7.0, 8.5)
const HERO_GLB := "res://assets/models/guan_yu.glb"
const ATTACK_R := 2.4          # 회전 칼날 닿는 거리(시험용 — 0.4초마다 둘레 적 처치)
const BENCH_LEVELS := [200, 400, 600, 800, 1000]
const BENCH_SETTLE := 2.0      # 단계마다 처음 2초는 버리고
const BENCH_MEASURE := 5.0     # 다음 5초를 잼

var player: Node3D
var horde: Node3D
var cam: Camera3D
var hud: Label
var blades: Node3D
var shots_dir := ""
var shot_times := [0.4, 1.0, 1.6, 2.2, 3.0]
var t := 0.0
var attack_t := 0.0
var opts := {}
# 성능 시험
var bench := false
var b_level := 0
var b_t := 0.0
var b_frames := PackedFloat32Array()
var b_upd := PackedFloat32Array()
var b_rows: Array[String] = []
var fps_acc := 0.0
var fps_n := 0
var fps_show := 0.0
var last_us := 0              # 실제 프레임 시간(엔진 delta는 느릴 때 133ms로 잘려서 FPS를 못 믿음)

func _read_opts() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if typeof(q) == TYPE_STRING and q.length() > 1:
			for pair in (q as String).substr(1).split("&"):
				var kv := pair.split("=", true, 1)
				opts[kv[0]] = kv[1] if kv.size() > 1 else "1"

func _ready() -> void:
	_read_opts()
	shots_dir = opts.get("shots", "")
	bench = opts.has("bench")
	_build_world()
	player = preload("res://scripts/player.gd").new()
	player.name = "Player"
	add_child(player)
	player.setup(load(HERO_GLB))
	player.auto_walk = shots_dir != "" or bench
	if opts.has("test"):
		print("TEST anims=", player.anim_names(), " walk_loop=", player.walk_loops())
		get_tree().quit()
		return
	horde = preload("res://scripts/horde.gd").new()
	add_child(horde)
	horde.setup(BENCH_LEVELS[-1])
	horde.target = BENCH_LEVELS[0] if bench else int(opts.get("n", "300"))
	_build_blades()
	hud = Label.new()
	hud.position = Vector2(12, 8)
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	hud.add_theme_constant_override("outline_size", 4)
	var layer := CanvasLayer.new()
	layer.add_child(hud)
	add_child(layer)
	if bench:
		print("BENCH start levels=", BENCH_LEVELS, " web=", OS.has_feature("web"),
			" renderer=", RenderingServer.get_video_adapter_name())

func _build_blades() -> void:
	# 관우 둘레를 도는 칼날 셋(회전 언월 흉내 — 처치가 눈에 보이게)
	blades = Node3D.new()
	add_child(blades)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c8d0d8")
	m.metallic = 0.6
	for i in 3:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 0.06, 0.22)
		mi.mesh = bm
		mi.material_override = m
		var a := TAU * i / 3.0
		mi.position = Vector3(cos(a), 0.8, sin(a)) * Vector3(ATTACK_R - 0.4, 1, ATTACK_R - 0.4)
		mi.rotation.y = -a
		blades.add_child(mi)

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
	var p2 := Vector2(player.position.x, player.position.z)
	if horde:
		horde.update(delta, p2)
		blades.position = player.position
		blades.rotation.y += delta * 5.0
		attack_t += delta
		if attack_t >= 0.4:
			attack_t = 0.0
			horde.kill_within(p2, ATTACK_R)
	# 3인칭 고정 각도로 뒤 · 위에서 따라감(마우스 시점은 다음 단계)
	var target := player.position + Vector3(0, 1.0, 0)
	cam.position = cam.position.lerp(target + CAM_OFFSET, clampf(delta * 6.0, 0, 1)) if t > 0.05 else target + CAM_OFFSET
	cam.look_at(target)
	if hud:
		fps_acc += delta; fps_n += 1
		if fps_acc >= 0.5:
			fps_show = fps_n / fps_acc; fps_acc = 0.0; fps_n = 0
		hud.text = "FPS %d  적 %d  처치 %d  적 갱신 %.2fms%s" % [fps_show, horde.count, horde.kills,
			horde.last_update_us / 1000.0, ("\n" + "\n".join(b_rows)) if bench else ""]
	if bench:
		_bench_tick(delta)
	if shots_dir != "" and not shot_times.is_empty() and t >= shot_times[0]:
		shot_times.pop_front()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots_dir)
		var path := shots_dir.path_join("shot_%d.png" % (5 - shot_times.size()))
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if shot_times.is_empty():
			get_tree().quit()

func _bench_tick(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_ms := (now - last_us) / 1000.0 if last_us > 0 else delta * 1000.0
	last_us = now
	if b_level >= BENCH_LEVELS.size():
		return
	b_t += delta
	if b_t > BENCH_SETTLE:
		b_frames.append(real_ms)
		b_upd.append(horde.last_update_us / 1000.0)
	if b_t >= BENCH_SETTLE + BENCH_MEASURE:
		var fr := b_frames.duplicate(); fr.sort()
		var avg := 0.0
		for v in fr: avg += v
		avg /= maxf(fr.size(), 1)
		var p99: float = fr[int(fr.size() * 0.99)] if fr.size() > 0 else 0.0
		var ua := 0.0
		var umax := 0.0
		for v in b_upd: ua += v; umax = maxf(umax, v)
		ua /= maxf(b_upd.size(), 1)
		var row := "적 %4d | 평균 %5.1f FPS (%.1fms) | 느린 1%% %.1fms | 적 갱신 평균 %.2fms · 최대 %.2fms | 그리기 호출 %d" % [
			BENCH_LEVELS[b_level], 1000.0 / maxf(avg, 0.001), avg, p99, ua, umax,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		print("BENCH ", row)
		b_rows.append(row)
		b_level += 1
		b_t = 0.0
		b_frames.clear(); b_upd.clear()
		if b_level < BENCH_LEVELS.size():
			horde.target = BENCH_LEVELS[b_level]
		else:
			print("BENCH done")
			if OS.has_feature("web"):
				JavaScriptBridge.eval("document.title = 'BENCH DONE'")
			elif not opts.has("stay"):
				get_tree().quit()
