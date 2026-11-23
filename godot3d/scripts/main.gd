extends Node3D
## 3D 시제품 시험 판(D-274~281): 장수(관우 · 장비 · 유비)가 들판을 걷고, 황건적 떼가 몰려온다.
## 옵션 — 명령줄(`--` 뒤) 또는 웹 주소(?n=500&bench=1):
##   (기본) 한 판 10분: 시간이 갈수록 적 수 · 체력 · 속도가 오르고 9분부터 마지막 대군, 10분 버티면 승리(data/waves.gd)
##   --n=<수>        적 수를 고정(시간표 끔 — 무기 비교용)
##   --start=<초>    판을 이 시각부터 시작(뒤쪽 시간대 점검)
##   (기본) 레벨업: 처치 → 구슬 → 레벨이 오르면 멈추고 3장 중 고름(1 · 2 · 3 키 또는 클릭, data/upgrades.gd)
##   --seed=<N>      레벨업 카드가 같은 순서로 나옴(밸런스 비교용)
##   --pick=auto     고르기를 자동으로(--auto · --bench · --shots는 기본 자동, --pick=manual이면 카드를 띄움)
##   --hero=<id>     장수(guan_yu 기본 · zhang_fei · liu_bei — 모델 · 무기는 data/heroes.gd)
##   --auto          자동으로 원을 그리며 걸음(창 없이 밸런스 볼 때) · --stats 끝날 때 버틴 시간 · 처치 · 체력 출력
##   --god           장수가 피해를 안 받음(--bench · --shots도 무적, --shots에 --hurt를 붙이면 피해 받음)
##   --bench         성능 시험: 자동으로 걷고 적 수를 200→1000으로 올리며 단계마다 FPS · 갱신 시간을 잼, 끝나면 표를 출력
##   --shots=<폴더>  자동으로 원을 그리며 걷고 스크린샷 몇 장 찍은 뒤 끝냄(--shot-at=초,초…로 시각 지정)
##   --test          모델 · 동작 이름만 확인하고 끝냄(headless 가능)

const CAM_OFFSET := Vector3(0, 7.0, 8.5)
const HERO_HP := 100.0          # 시작 최대 체력(레벨업 '강건'이 늘림)
const HIT_DMG := 6.0           # 창 한 번(시간표가 없을 때 — 있으면 data/waves.gd의 찌르기 피해)
const IFRAME := 0.35           # 맞은 뒤 무적 시간 — 여럿이 한꺼번에 찔러도 이 간격으로만 맞음
const PROPS := 300            # 바위 · 나무 수(묶어 그리므로 늘려도 그리기 호출은 그대로)
const BENCH_LEVELS := [200, 400, 600, 800, 1000]
const BENCH_SETTLE := 2.0      # 단계마다 처음 2초는 버리고
const BENCH_MEASURE := 5.0     # 다음 5초를 잼

var player: Node3D
var horde: Node3D
var cam: Camera3D
var hud: Label
var weapon: Node3D
var hero_id := "guan_yu"
var hero: Dictionary
var shots_dir := ""
var shot_times := [0.4, 1.0, 1.6, 2.2, 3.0]
var t := 0.0
var shot_total := 5
var hero_hp := HERO_HP
var max_hp := HERO_HP
# 레벨업(D-283)
var gems: Node3D
var level := 1
var xp := 0
var ups := {}                 # 고른 횟수 key → 수
var armor := 1.0              # 받는 피해 배율
var enemy_dmg := HIT_DMG
var regen := 0.0              # 초당 회복
var choosing := false
var choices: Array = []
var auto_pick := false
var pick_box: Control
var pick_btns: Array[Button] = []
var xp_bar: ColorRect
var lv_lbl: Label
var pick_log: Array[String] = []
var pick_open_ms := 0         # 키를 누른 채로 다음 고르기까지 넘어가지 않게(0.3초)
var invuln := 0.0
var god := false
var dead := false
var cleared := false
var waves := true
var final_shown := false
var timer_lbl: Label
var banner_t := 0.0
var hp_bar: ColorRect
var hp_back: ColorRect
var flash: ColorRect
var msg: Label
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
	if opts.has("seed"):   # --seed=N: 레벨업 카드 · 고르기를 같은 순서로(밸런스 비교용)
		seed(int(opts["seed"]))
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
	hero_id = opts.get("hero", "guan_yu")
	hero = HeroTable.get_hero(hero_id)
	player.setup(load(hero.glb))
	player.auto_walk = (shots_dir != "" or bench or opts.has("auto")) and not opts.has("stand")   # --stand: 자동 걷기 없이 서 있음
	if opts.has("test"):
		print("TEST hero=", hero_id, " weapon=", hero.weapon.name, "(", hero.weapon.type, ") anims=", player.anim_names(), " walk_loop=", player.walk_loops())
		get_tree().quit()
		return
	horde = preload("res://scripts/horde.gd").new()
	add_child(horde)
	horde.setup(BENCH_LEVELS[-1])
	waves = not bench and not opts.has("n")
	if waves:
		t = float(opts.get("start", "0"))
		_apply_wave()
	else:
		horde.target = BENCH_LEVELS[0] if bench else int(opts.get("n", "300"))
	weapon = preload("res://scripts/weapon.gd").new()
	add_child(weapon)
	weapon.setup(hero.weapon, player, horde)
	gems = preload("res://scripts/gems.gd").new()
	add_child(gems)
	auto_pick = opts.get("pick", "") == "auto" or ((opts.has("auto") or bench or shots_dir != "") and opts.get("pick", "") != "manual")
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
	timer_lbl = Label.new()   # 위쪽 가운데 남은 시간(기준 화면 1280×720 — 앵커를 쓰면 위치가 두 번 밀림)
	timer_lbl.position = Vector2(640 - 60, 36)   # 맨 윗줄 HUD 글 아래
	timer_lbl.size = Vector2(120, 40)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 30)
	timer_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	timer_lbl.add_theme_constant_override("outline_size", 6)
	timer_lbl.visible = waves
	layer.add_child(timer_lbl)
	var xb := ColorRect.new()   # 맨 위 경험치 막대
	xb.color = Color(0, 0, 0, 0.5); xb.position = Vector2(0, 0); xb.size = Vector2(1280, 6)
	layer.add_child(xb)
	xp_bar = ColorRect.new()
	xp_bar.color = Color("5ad0e8"); xp_bar.position = Vector2(0, 0); xp_bar.size = Vector2(0, 6)
	layer.add_child(xp_bar)
	lv_lbl = Label.new()        # 체력 막대 위 레벨
	lv_lbl.position = Vector2(12, 720 - 58)
	lv_lbl.add_theme_font_size_override("font_size", 20)
	lv_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lv_lbl.add_theme_constant_override("outline_size", 4)
	layer.add_child(lv_lbl)
	_build_pick(layer)
	add_child(layer)
	if bench:
		print("BENCH start levels=", BENCH_LEVELS, " web=", OS.has_feature("web"),
			" renderer=", RenderingServer.get_video_adapter_name())

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
	_shots_tick()   # 레벨업 고르기로 멈춘 동안에도 찍음
	if choosing:
		_pick_input()
		return
	if horde and not dead and not cleared:
		if waves:
			_apply_wave()
			if t >= WaveTable.RUN_TIME:
				_win()
		var hits: int = horde.update(delta, p2)
		weapon.tick(delta)
		for dp in horde.dead_pos:
			gems.drop(dp)
		horde.dead_pos.clear()
		xp += gems.update(delta, p2)
		if xp >= UpgradeTable.need(level):
			xp -= UpgradeTable.need(level)
			level += 1
			_open_pick()
		hero_hp = minf(hero_hp + regen * delta, max_hp)
		invuln = maxf(invuln - delta, 0.0)
		if hits > 0 and invuln <= 0.0 and not god:
			hero_hp -= enemy_dmg * armor
			invuln = IFRAME
			flash.color.a = 0.35
			if hero_hp <= 0.0:
				_die()
	if flash:
		flash.color.a = maxf(flash.color.a - delta * 1.5, 0.0)
		hp_bar.size.x = 236.0 * maxf(hero_hp, 0.0) / max_hp
		xp_bar.size.x = 1280.0 * xp / UpgradeTable.need(level)
		lv_lbl.text = "Lv %d" % level
	if timer_lbl and waves:
		var left := maxf(WaveTable.RUN_TIME - t, 0.0)
		timer_lbl.text = "%d:%02d" % [int(left) / 60, int(left) % 60]
		timer_lbl.add_theme_color_override("font_color", Color("ff6a50") if t >= WaveTable.FINAL_AT else Color.WHITE)
	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0 and not dead and not cleared:
			msg.visible = false
	if (dead or cleared) and Input.is_physical_key_pressed(KEY_R):
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
		hud.text = "%s · %s   Lv %d   FPS %d  적 %d  처치 %d  체력 %d%s  적 갱신 %.2fms%s" % [hero.name, hero.weapon.name, level, fps_show, horde.count, horde.kills, maxf(hero_hp, 0.0), " (무적)" if god else "",
			horde.last_update_us / 1000.0, ("\n" + "\n".join(b_rows)) if bench else ""]
	if bench:
		_bench_tick(delta)

# ── 레벨업 고르기 ──
func _build_pick(layer: CanvasLayer) -> void:
	pick_box = VBoxContainer.new()
	pick_box.position = Vector2(640 - 210, 200)
	pick_box.size = Vector2(420, 0)
	pick_box.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.text = "레벨 업! — 하나를 고르세요 (1 · 2 · 3)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 5)
	pick_box.add_child(title)
	for k in 3:
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 70)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_choose.bind(k))
		pick_box.add_child(b)
		pick_btns.append(b)
	pick_box.visible = false
	layer.add_child(pick_box)

func _offers() -> Array:
	var pool := []
	for key in UpgradeTable.LIST:
		var u: Dictionary = UpgradeTable.LIST[key]
		if ups.get(key, 0) >= u.max:
			continue
		if u.has("only") and not (hero.weapon.type in u.only):
			continue
		pool.append(key)
	pool.shuffle()
	pool = pool.slice(0, 3)
	if pool.is_empty():
		pool = ["heal"]
	return pool

func _label(key: String) -> String:
	if key == "heal":
		return "%s — %s" % [UpgradeTable.HEAL.name, UpgradeTable.HEAL.desc]
	var u: Dictionary = UpgradeTable.LIST[key]
	return "%s  Lv %d\n%s" % [String(u.name).replace("{w}", hero.weapon.name), ups.get(key, 0) + 1, u.desc]

func _open_pick() -> void:
	choices = _offers()
	if auto_pick:
		_choose(_auto_choice())
		return
	choosing = true
	pick_open_ms = Time.get_ticks_msec()
	player.set_process(false)
	for k in 3:
		pick_btns[k].visible = k < choices.size()
		if k < choices.size():
			pick_btns[k].text = "%d.  %s" % [k + 1, _label(choices[k])]
	pick_box.visible = true

func _auto_choice() -> int:
	## 자동(봇 · 시험): 무기 피해 → 속도 → 갑옷 → 강건 → 범위 → 나머지 순으로 좋아함.
	var pref := ["w_dmg", "w_spd", "w_count", "gap", "hp", "w_area", "w_pierce", "mu", "gun", "sin", "magnet", "heal"]
	var best := 0
	for k in choices.size():
		if pref.find(choices[k]) < pref.find(choices[best]):
			best = k
	return best

func _pick_input() -> void:
	if Time.get_ticks_msec() - pick_open_ms < 300:
		return
	for k in 3:
		if k < choices.size() and Input.is_physical_key_pressed(KEY_1 + k):
			_choose(k)
			return

func _choose(k: int) -> void:
	if k >= choices.size():
		return
	var key: String = choices[k]
	_apply_upgrade(key)
	pick_log.append("%d:%s" % [level, key])
	choosing = false
	pick_box.visible = false
	if not dead:
		player.set_process(true)

func _apply_upgrade(key: String) -> void:
	if key != "heal":
		ups[key] = ups.get(key, 0) + 1
	match key:
		"w_dmg": weapon.mods.dmg *= 1.25
		"w_spd": weapon.mods.cd *= 0.87
		"w_area":
			weapon.mods.area *= 1.15
			weapon.refresh_fx()
		"w_count": weapon.mods.count += 1
		"w_pierce": weapon.mods.pierce += 2
		"mu": weapon.mods.dmg *= 1.10
		"gap": armor *= 0.92
		"sin": player.speed_mul *= 1.08
		"gun": regen += 0.5
		"magnet": gems.magnet *= 1.35
		"hp":
			max_hp += 20.0
			hero_hp = minf(hero_hp + 20.0, max_hp)
		"heal": hero_hp = minf(hero_hp + 30.0, max_hp)

func _apply_wave() -> void:
	var w := WaveTable.at(t)
	horde.target = w[0]
	horde.spawn_hp = w[1]
	horde.speed = w[2]
	enemy_dmg = w[3]
	if t >= WaveTable.FINAL_AT and not final_shown and msg:   # msg는 _ready 뒤쪽에서 만듦(--start로 9분 뒤 시작할 때)
		final_shown = true
		msg.text = "마지막 대군!\n1분만 버티면 된다"
		msg.visible = true
		banner_t = 3.0
		print("FINAL t=%.1f" % t)

func _win() -> void:
	cleared = true
	player.set_process(false)
	msg.text = "버텼습니다!\n10분 · 처치 %d\nR — 다시" % horde.kills
	msg.visible = true
	print("CLEAR t=%.1f kills=%d hp=%d" % [t, horde.kills, hero_hp])

func _exit_tree() -> void:
	if opts.has("stats") and horde:
		print("STATS hero=%s t=%.1f kills=%d hp=%d attacks=%d dead=%s cleared=%s enemies=%d enemy_hp=%.1f level=%d" % [hero_id, t, horde.kills, maxf(hero_hp, 0.0), weapon.attacks, dead, cleared, horde.count, horde.spawn_hp, level])
		print("PICKS ", " ".join(pick_log))

func _die() -> void:
	dead = true
	player.set_process(false)
	msg.text = "쓰러졌습니다\n%d초 버팀 · 처치 %d\nR — 다시" % [int(t), horde.kills]
	msg.visible = true
	print("DEAD t=%.1f kills=%d" % [t, horde.kills])

func _shots_tick() -> void:
	if shots_dir != "" and not shot_times.is_empty() and t >= shot_times[0]:
		shot_times.pop_front()
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots_dir)
		var path := shots_dir.path_join("shot_%d.png" % (shot_total - shot_times.size()))
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
