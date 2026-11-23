extends Node3D
## 3D 시제품 시험 판(D-274 · D-275): 관우가 들판을 걷고, 황건적 떼가 몰려온다.
## 옵션 — 명령줄(`--` 뒤) 또는 웹 주소(?n=500&bench=1):
##   --n=<수>        적 수(기본 300)
##   --hero=<id>     장수(guan_yu 기본 · zhang_fei · liu_bei)
##   --god           장수가 피해를 안 받음(--bench · --shots도 무적, --shots에 --hurt를 붙이면 피해 받음)
##   --bench         성능 시험: 자동으로 걷고 적 수를 200→1000으로 올리며 단계마다 FPS · 갱신 시간을 잼, 끝나면 표를 출력
##   --shots=<폴더>  자동으로 원을 그리며 걷고 스크린샷 몇 장 찍은 뒤 끝냄(--shot-at=초,초…로 시각 지정)
##   --test          모델 · 동작 이름만 확인하고 끝냄(headless 가능)

const CAM_OFFSET := Vector3(0, 7.0, 8.5)
# 장수는 모델 파일만 바꿔 끼움(뼈 이름 · 동작이 같음) — --hero=<id> 또는 웹 ?hero=<id>, 기본 관우
const HEROES := {
	"guan_yu": "res://assets/models/guan_yu.glb",
	"zhang_fei": "res://assets/models/zhang_fei.glb",
	"liu_bei": "res://assets/models/liu_bei.glb",
}
const ATTACK_R := 2.4          # 회전 칼날 바깥 끝(시험용)
const BLADE_R := 2.0           # 칼날이 도는 반지름
const BLADE_SPIN := 5.0        # rad/초
const BLADE_HALF_W := 0.3      # 칼날 하나가 맞히는 각도 폭(±rad)
const HERO_HP := 100.0
const HIT_DMG := 6.0           # 창 한 번
const IFRAME := 0.35           # 맞은 뒤 무적 시간 — 여럿이 한꺼번에 찔러도 이 간격으로만 맞음
const PROPS := 300            # 바위 · 나무 수(묶어 그리므로 늘려도 그리기 호출은 그대로)
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
var shot_total := 5
var hero_hp := HERO_HP
var invuln := 0.0
var god := false
var dead := false
var hp_bar: ColorRect
var hp_back: ColorRect
var flash: ColorRect
var msg: Label
var blade_base := PackedFloat32Array()
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
	if opts.has("shot-at"):   # --shot-at=초,초… (기본 0.4 · 1 · 1.6 · 2.2 · 3초)
		shot_times = []
		for x in String(opts["shot-at"]).split(","):
			shot_times.append(float(x))
	shot_total = shot_times.size()
	bench = opts.has("bench")
	god = opts.has("god") or bench or (shots_dir != "" and not opts.has("hurt"))
	_build_world()
	player = preload("res://scripts/player.gd").new()
	player.name = "Player"
	add_child(player)
	player.setup(load(HEROES.get(opts.get("hero", "guan_yu"), HEROES["guan_yu"])))
	player.auto_walk = (shots_dir != "" or bench) and not opts.has("stand")   # --stand: 자동 걷기 없이 서 있음
	if opts.has("test"):
		print("TEST hero=", opts.get("hero", "guan_yu"), " anims=", player.anim_names(), " walk_loop=", player.walk_loops())
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
	flash = ColorRect.new()   # 맞으면 화면이 잠깐 붉어짐
	flash.color = Color(0.8, 0.05, 0.05, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	layer.add_child(hud)
	hp_back = ColorRect.new()
	hp_back.color = Color(0, 0, 0, 0.6)
	# 체력 막대는 왼쪽 아래(기준 화면 1280×720)
	hp_back.position = Vector2(12, 720 - 30); hp_back.size = Vector2(240, 14)
	layer.add_child(hp_back)
	hp_bar = ColorRect.new()
	hp_bar.color = Color("d83a2a")
	hp_bar.position = Vector2(14, 720 - 28); hp_bar.size = Vector2(236, 10)
	layer.add_child(hp_bar)
	msg = Label.new()
	msg.set_anchors_preset(Control.PRESET_CENTER)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 32)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 6)
	msg.visible = false
	layer.add_child(msg)
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
		mi.position = Vector3(cos(a) * BLADE_R, 0.8, sin(a) * BLADE_R)
		mi.rotation.y = -a
		blades.add_child(mi)
		blade_base.append(a)

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

	# 바위 · 나무(저폴리 기본 도형, 시험용) — 종류마다 MultiMesh 하나로 묶어 그림(D-276: 따로 그리면 그리기 호출이 수백)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var rock_mesh := SphereMesh.new()
	rock_mesh.radial_segments = 6; rock_mesh.rings = 3; rock_mesh.radius = 1.0; rock_mesh.height = 1.4
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.radial_segments = 6; trunk_mesh.top_radius = 0.12; trunk_mesh.bottom_radius = 0.18; trunk_mesh.height = 1.2
	var leaf_mesh := CylinderMesh.new()
	leaf_mesh.radial_segments = 6; leaf_mesh.top_radius = 0.0; leaf_mesh.bottom_radius = 1.0; leaf_mesh.height = 2.2
	var rocks: Array[Transform3D] = []
	var trees: Array[Vector3] = []
	for i in PROPS:
		var p := Vector3(rng.randf_range(-55, 55), 0, rng.randf_range(-55, 55))
		if p.length() < 4.0:
			continue
		if rng.randf() < 0.5:
			var s := rng.randf_range(0.4, 1.1)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
			rocks.append(Transform3D(b, p + Vector3(0, s * 0.3, 0)))
		else:
			trees.append(p)
	var trunks: Array[Transform3D] = []
	var leaves: Array[Transform3D] = []
	for p in trees:
		trunks.append(Transform3D(Basis(), p + Vector3(0, 0.6, 0)))
		leaves.append(Transform3D(Basis(), p + Vector3(0, 2.2, 0)))
	_add_multimesh(rock_mesh, Color("7a7468"), rocks)
	_add_multimesh(trunk_mesh, Color("6a4a30"), trunks)
	_add_multimesh(leaf_mesh, Color("3f6a3a"), leaves)

	cam = Camera3D.new()
	cam.fov = 55
	add_child(cam)

func _add_multimesh(mesh: Mesh, color: Color, xforms: Array[Transform3D]) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	(mesh as PrimitiveMesh).material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	add_child(inst)

func _process(delta: float) -> void:
	t += delta
	var p2 := Vector2(player.position.x, player.position.z)
	if horde and not dead:
		var hits: int = horde.update(delta, p2)
		blades.position = player.position
		blades.rotation.y += delta * BLADE_SPIN
		# 칼날 월드 각도(XZ 평면) = 처음 각도 − 부모 회전
		var ang := PackedFloat32Array()
		for a in blade_base:
			ang.append(a - blades.rotation.y)
		horde.blade_hits(p2, ang, BLADE_R - 0.8, ATTACK_R + 0.2, BLADE_HALF_W, 1.0)
		invuln = maxf(invuln - delta, 0.0)
		if hits > 0 and invuln <= 0.0 and not god:
			hero_hp -= HIT_DMG
			invuln = IFRAME
			flash.color.a = 0.35
			if hero_hp <= 0.0:
				_die()
	if flash:
		flash.color.a = maxf(flash.color.a - delta * 1.5, 0.0)
		hp_bar.size.x = 236.0 * maxf(hero_hp, 0.0) / HERO_HP
	if dead and Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		return
	# 3인칭 고정 각도로 뒤 · 위에서 따라감(마우스 시점은 다음 단계)
	var target := player.position + Vector3(0, 1.0, 0)
	cam.position = cam.position.lerp(target + CAM_OFFSET, clampf(delta * 6.0, 0, 1)) if t > 0.05 else target + CAM_OFFSET
	cam.look_at(target)
	if hud:
		fps_acc += delta; fps_n += 1
		if fps_acc >= 0.5:
			fps_show = fps_n / fps_acc; fps_acc = 0.0; fps_n = 0
		hud.text = "FPS %d  적 %d  처치 %d  체력 %d%s  적 갱신 %.2fms%s" % [fps_show, horde.count, horde.kills, maxf(hero_hp, 0.0), " (무적)" if god else "",
			horde.last_update_us / 1000.0, ("\n" + "\n".join(b_rows)) if bench else ""]
	if bench:
		_bench_tick(delta)
	if shots_dir != "" and not shot_times.is_empty() and t >= shot_times[0]:
		shot_times.pop_front()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots_dir)
		var path := shots_dir.path_join("shot_%d.png" % (shot_total - shot_times.size()))
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", path)
		if shot_times.is_empty():
			get_tree().quit()

func _die() -> void:
	dead = true
	player.set_process(false)
	msg.text = "쓰러졌습니다\n%d초 버팀 · 처치 %d\nR — 다시" % [int(t), horde.kills]
	msg.visible = true
	print("DEAD t=%.1f kills=%d" % [t, horde.kills])

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
