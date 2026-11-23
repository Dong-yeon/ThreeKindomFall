extends Node3D
## 3D 시제품 시험 판(D-274~281): 장수(관우 · 장비 · 유비)가 들판을 걷고, 황건적 떼가 몰려온다.
## 옵션 — 명령줄(`--` 뒤) 또는 웹 주소(?n=500&bench=1):
##   (기본) 한 판 10분: 시간이 갈수록 적 수 · 체력 · 속도가 오르고 9분부터 마지막 대군, 10분 버티면 승리(data/waves.gd)
##   --n=<수>        적 수를 고정(시간표 끔 — 무기 비교용)
##   --start=<초>    판을 이 시각부터 시작(뒤쪽 시간대 점검)
##   (기본) 레벨업: 처치 → 구슬 → 레벨이 오르면 멈추고 3장 중 고름(1 · 2 · 3 키 또는 클릭, data/upgrades.gd)
##   --tactic=<id,…> 처음부터 책략을 가짐(orbit · rain · fire · bolt, 쉼표로 여럿 — 점검용)
##   (D-285) 무공: 내공 · 절기 Space/K · 경공 Shift · 고유 심법 · 주화입마 · 오의 진화(data/martial.gd · ults.gd · heroes.gd)
##   --dash-at=<초,…> 그 시각에 경공(점검) · --neigong=<값> 처음 내공
##   --ult-hold      자동 봇이 절기를 안 씀(주화입마 점검) · --force-evolve 처음부터 오의 · --select-test 선택 화면에서 넘어온 장수만 찍고 끝냄
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
var tactics := {}             # 책략 id → 노드(D-284, 최대 TacticTable.MAX_SLOTS)
var atk_mul := 1.0            # 무력 — 책략 피해에 곱함(대표 무기는 weapon.mods.dmg)
var pick_open_ms := 0         # 키를 누른 채로 다음 고르기까지 넘어가지 않게(0.3초)
var invuln := 0.0
# 무공(D-285)
var neigong: Neigong
var allies: Node3D
var ult_id := ""
var evolved := false
var active_ults: Array = []
var ult_casts := 0
var ult_hits := 0
var ult_key_was := false
var last_hits := 0
var last_kills := 0
var dyn := 1.0                # 이번 프레임 공격 배율(주화입마 × 광폭)
var curve_marks := [60.0, 180.0, 360.0, 540.0]
var nei_bar: ColorRect
var nei_back: ColorRect
var kit_lbl: Label
var stage: Node3D             # 황건적 스테이지(D-289 — 진영 · 정예 · 상자)
var foe_dmg_total := 0.0
var bot_react := 0.0          # 봇 경공 반응 지연 누적
var bot_rest := 0.0           # 봇이 경공을 놓친 뒤 쉬는 시간
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
	hero_id = opts.get("hero", HeroTable.chosen if HeroTable.chosen != "" else "guan_yu")
	hero = HeroTable.get_hero(hero_id)
	if opts.has("select-test"):   # 선택 화면 → 판 진입 점검: 넘어온 장수만 출력
		print("MAIN hero=%s (선택 화면에서 고름=%s)" % [hero_id, HeroTable.chosen])
		get_tree().quit()
		return
	player.setup(load(hero.glb))
	player.auto_walk = (shots_dir != "" or bench or opts.has("auto")) and not opts.has("stand")   # --stand: 자동 걷기 없이 서 있음
	if opts.has("test"):
		print("TEST hero=", hero_id, " weapon=", hero.weapon.name, "(", hero.weapon.type, ") anims=", player.anim_names(), " walk_loop=", player.walk_loops(),
			" ult=", UltTable.display_name(hero.ult, false), " qinggong=", hero.qinggong.name, " passive=", hero.passive.name, " stars=", hero.stars)
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
	# 무공(D-285): 경공 · 고유 심법 · 내공 · 의용군 · 절기
	player.setup_qinggong(hero.qinggong)
	match hero.passive.id:
		"wipung":
			weapon.mods.area *= hero.passive.area
			weapon.mods.knock *= hero.passive.knock
			weapon.refresh_fx()
		"indeok":
			regen += hero.passive.regen
	neigong = Neigong.new()
	allies = preload("res://scripts/allies.gd").new()
	add_child(allies)
	allies.setup(horde)
	ult_id = hero.ult
	if opts.has("force-evolve"):
		evolved = true
		print("EVOLVE forced %s -> %s" % [UltTable.LIST[ult_id].name, UltTable.display_name(ult_id, true)])
	if opts.has("neigong"):   # --neigong=100: 처음 내공(점검용)
		neigong.value = float(opts["neigong"])
	if opts.has("tactic"):   # --tactic=orbit,rain … (쉼표로 여럿)
		for tid in String(opts["tactic"]).split(","):
			_apply_upgrade("t:" + tid)
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
	nei_back = ColorRect.new()   # 체력 막대 위 내공 막대(보라 — 주화입마 때 붉게 깜빡임)
	nei_back.color = Color(0, 0, 0, 0.6)
	nei_back.position = Vector2(12, 720 - 46); nei_back.size = Vector2(240, 10)
	layer.add_child(nei_back)
	nei_bar = ColorRect.new()
	nei_bar.color = Color("9a5ad8")
	nei_bar.position = Vector2(14, 720 - 44); nei_bar.size = Vector2(0, 6)
	layer.add_child(nei_bar)
	kit_lbl = Label.new()        # 막대 오른쪽: 절기 · 경공 상태
	kit_lbl.position = Vector2(262, 720 - 56)
	kit_lbl.add_theme_font_size_override("font_size", 18)
	kit_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	kit_lbl.add_theme_constant_override("outline_size", 4)
	layer.add_child(kit_lbl)
	lv_lbl = Label.new()        # 내공 막대 위 레벨
	lv_lbl.position = Vector2(12, 720 - 74)
	lv_lbl.add_theme_font_size_override("font_size", 20)
	lv_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lv_lbl.add_theme_constant_override("outline_size", 4)
	layer.add_child(lv_lbl)
	_build_pick(layer)
	add_child(layer)
	if not bench and not opts.has("no-stage"):   # --no-stage: 빈 들판(예전 시험)
		stage = preload("res://scripts/stage.gd").new()
		add_child(stage)
		stage.setup(horde, player, cam, layer, load("res://assets/fonts/Galmuri11.ttf"))
		stage.chest_opened.connect(_on_chest)
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
	pm.size = Vector2(170, 170)   # 맵 경계 140(D-289) 밖까지 바닥
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
		var p := Vector3(rng.randf_range(-66, 66), 0, rng.randf_range(-66, 66))
		var near_camp := false   # 진영 · 흙길 자리는 비움(D-289)
		for cs in StageYellow.CAMPS:
			if Vector2(p.x, p.z).distance_to(cs.pos) < cs.r + 3.0:
				near_camp = true
		if p.length() < 4.0 or near_camp:
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
		var hits: float = horde.update(delta, p2)   # 찌르기 1 · 화살은 궁병 배율(D-288)
		weapon.tick(delta)
		for tac in tactics.values():
			tac.tick(delta)
		_martial_tick(delta, p2)
		_stage_tick(delta, p2)
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
		if hits > 0.0 and invuln <= 0.0 and player.iframe_t <= 0.0 and not god:
			hero_hp -= enemy_dmg * armor * minf(hits, 1.0)
			invuln = IFRAME
			flash.color.a = 0.35
			if hero_hp <= 0.0:
				_die()
	if flash:
		flash.color.a = maxf(flash.color.a - delta * 1.5, 0.0)
		hp_bar.size.x = 236.0 * maxf(hero_hp, 0.0) / max_hp
		xp_bar.size.x = 1280.0 * xp / UpgradeTable.need(level)
		lv_lbl.text = "Lv %d" % level
		nei_bar.size.x = 236.0 * neigong.value / MartialRules.NEIGONG_MAX
		nei_bar.color = (Color("e84a3a") if fmod(t, 0.3) < 0.15 else Color("ffb040")) if neigong.zhuhuo_t > 0.0 else Color("9a5ad8")
		var cost: float = UltTable.LIST[ult_id].cost
		var ult_txt := "%s %s" % [UltTable.display_name(ult_id, evolved), "준비! [Space]" if neigong.can_spend(cost) else "%d%%" % int(100.0 * neigong.value / cost)]
		var dots := ""
		for k in int(player.qg.charges):
			dots += "●" if k < player.charges else "○"
		kit_lbl.text = "절기 %s%s\n경공 %s %s [Shift]" % [ult_txt, "  · 주화입마 %.0f초" % neigong.zhuhuo_t if neigong.zhuhuo_t > 0.0 else "", hero.qinggong.name, dots]
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
	for tid in TacticTable.LIST:   # 책략: 가진 것은 강화(최대 레벨까지), 없는 것은 자리가 남았을 때 새로
		if tactics.has(tid):
			if tactics[tid].lv < TacticTable.MAX_LV:
				pool.append("t:" + tid)
		elif tactics.size() < TacticTable.MAX_SLOTS:
			pool.append("t:" + tid)
	pool.shuffle()
	pool = pool.slice(0, 3)
	if pool.is_empty():
		pool = ["heal"]
	return pool

func _label(key: String) -> String:
	if key == "heal":
		return "%s — %s" % [UpgradeTable.HEAL.name, UpgradeTable.HEAL.desc]
	if key.begins_with("t:"):
		var tid := key.substr(2)
		var tt: Dictionary = TacticTable.LIST[tid]
		if tactics.has(tid):
			return "초식 · %s  Lv %d\n더 세게" % [tt.name, tactics[tid].lv + 1]
		return "초식 · %s  (새로)\n%s" % [tt.name, tt.desc]
	var u: Dictionary = UpgradeTable.LIST[key]
	var kind := "초식" if u.kind == "weapon" else "심법"   # D-285: 무기 강화 = 초식, 능력치 = 심법
	return "%s · %s  Lv %d\n%s" % [kind, String(u.name).replace("{w}", hero.weapon.name), ups.get(key, 0) + 1, u.desc]

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
	var pref := ["w_dmg", "t", "w_spd", "w_count", "gap", "hp", "w_area", "w_pierce", "mu", "gun", "sin", "magnet", "heal"]
	var best := 0
	for k in choices.size():
		if pref.find(_pref_key(choices[k])) < pref.find(_pref_key(choices[best])):
			best = k
	return best

func _pref_key(key: String) -> String:
	return "t" if key.begins_with("t:") else key

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
	if key.begins_with("t:"):
		var tid := key.substr(2)
		if tactics.has(tid):
			tactics[tid].set_level(tactics[tid].lv + 1)
		else:
			var tac := preload("res://scripts/tactic.gd").new()
			add_child(tac)
			tac.ch = horde.CH_TACTIC + tactics.size()   # 추가 초식은 슬롯마다 자기 맞음 대기(D-287)
			tac.setup(tid, player, horde)
			tac.atk_mul = atk_mul
			tactics[tid] = tac
		return
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
		"mu":
			weapon.mods.dmg *= 1.10
			atk_mul *= 1.10
			for tac in tactics.values():
				tac.atk_mul = atk_mul
		"gap": armor *= 0.92
		"sin": player.speed_mul *= 1.08
		"gun": regen += 0.5
		"magnet": gems.magnet *= 1.35
		"hp":
			max_hp += 20.0
			hero_hp = minf(hero_hp + 20.0, max_hp)
		"heal": hero_hp = minf(hero_hp + 30.0, max_hp)
	_check_evolve()

func _stage_tick(delta: float, p2: Vector2) -> void:
	## 맵 경계 · 진영 정예 피해 · 봇 진영 가기(D-289).
	if stage == null:
		return
	var b: Rect2 = StageYellow.BOUNDS
	player.position.x = clampf(player.position.x, b.position.x + 0.5, b.end.x - 0.5)
	player.position.z = clampf(player.position.z, b.position.y + 0.5, b.end.y - 0.5)
	var fd: float = stage.tick(delta, p2, enemy_dmg / 7.8, t)
	if fd > 0.0 and invuln <= 0.0 and player.iframe_t <= 0.0 and not god:
		hero_hp -= fd * armor
		foe_dmg_total += fd * armor
		invuln = IFRAME
		flash.color.a = 0.45
		if hero_hp <= 0.0:
			_die()
			return
	# 봇: 체력이 넉넉하고 1분이 지났으면 가장 가까운 진영으로(진영 진행을 재려고)
	if player.auto_walk:
		player.has_goal = false
		player.goal_direct = false
		for c in stage.camps:   # 상자가 있으면 먼저 주우러
			if c.chest and is_instance_valid(c.chest):
				player.goal = c.chest.position
				player.has_goal = true
				player.goal_direct = true
		if not player.has_goal and hero_hp > max_hp * 0.55 and t > 60.0:
			var best := 1e9
			for c in stage.alive_camps():
				var d: float = c.spec.pos.distance_to(p2)
				if d < best:
					best = d
					player.goal = Vector3(c.spec.pos.x, 0, c.spec.pos.y)
					player.has_goal = true

func _on_chest() -> void:
	hero_hp = minf(hero_hp + StageYellow.CHEST_HEAL, max_hp)
	_banner("보상 상자!\n체력 회복 · 레벨업 카드", 1.5)
	print("CHEST t=%.1f" % t)
	_open_pick()

func _check_evolve() -> void:
	## 오의 진화: 재료 초식 2개 + 심법 1개를 갖추면 절기가 오의로(data/ults.gd evolve).
	if evolved or ult_id == "":
		return
	var ev: Dictionary = UltTable.LIST[ult_id].evolve
	for need in ev.chosik + [ev.simbeop]:
		if _have(need[0]) < int(need[1]):
			return
	evolved = true
	_banner("절기 진화!\n%s → 오의 %s" % [UltTable.LIST[ult_id].name, ev.name], 3.0)
	print("EVOLVE t=%.1f %s -> %s" % [t, UltTable.LIST[ult_id].name, ev.name])

func _have(key: String) -> int:
	if key.begins_with("t:"):
		var tid := key.substr(2)
		return tactics[tid].lv if tactics.has(tid) else 0
	return int(ups.get(key, 0))

func _banner(text: String, sec: float) -> void:
	if msg and not dead and not cleared:
		msg.text = text
		msg.visible = true
		banner_t = sec

# ── 무공(D-285): 내공 · 주화입마 · 고유 심법 · 절기 · 경공 ──
func _martial_tick(delta: float, p2: Vector2) -> void:
	# 내공: 늘어난 맞힘 · 처치만큼
	var dh: int = horde.hit_count - last_hits
	var dk: int = horde.kills - last_kills
	last_hits = horde.hit_count
	last_kills = horde.kills
	neigong.gain((dh * MartialRules.PER_HIT + dk * MartialRules.PER_KILL) * hero.neigong, delta)
	if neigong.just_entered:
		neigong.just_entered = false
		_banner("주화입마!\n공격 크게 ↑ · 체력이 계속 줄어든다 (절기를 쓰면 풀림)", 2.5)
		print("ZHUHUO t=%.1f" % t)
	var drain := neigong.tick(delta)
	if drain > 0.0 and not god:
		hero_hp -= drain
		if hero_hp <= 0.0:
			_die()
			return
	# 공격 배율: 주화입마 × 광폭(잃은 체력만큼)
	dyn = neigong.atk_mul()
	if hero.passive.id == "gwangpok":
		dyn *= 1.0 + hero.passive.max * clampf(1.0 - hero_hp / max_hp, 0.0, 1.0)
	weapon.dyn = dyn
	for tac in tactics.values():
		tac.atk_mul = atk_mul * dyn
	# 의용군(인덕 배율)
	allies.atk_mul = atk_mul * dyn
	allies.enemy_dmg = enemy_dmg
	if hero.passive.id == "indeok":
		allies.mul = hero.passive.ally_mul + hero.passive.ally_per_lv * (level - 1)
	allies.level = level
	allies.update(delta, p2)
	# 점검: --dash-at=초[,초…] 그 시각에 경공(이단 도약은 두 시각을 가깝게 주면 공중에서 한 번 더)
	if opts.has("dash-at"):
		var ts := String(opts["dash-at"]).split(",")
		for k in ts.size():
			if t >= float(ts[k]) and not ("dash_%d" % k) in opts:
				opts["dash_%d" % k] = "1"
				player.try_dash()
	# 경공: 자동 봇은 둘러싸이면 / 돌진 중 부딪힌 적 밀침(관우)
	if player.auto_walk:   # 봇 경공(D-287 인간화): 둘러싸인 뒤 반응 지연, 가끔 놓침
		bot_rest = maxf(bot_rest - delta, 0.0)
		if horde.count_within(p2, MartialRules.BOT_DASH_R) >= MartialRules.BOT_DASH_N:
			bot_react += delta
			if bot_react >= MartialRules.BOT_REACT and bot_rest <= 0.0:
				bot_react = 0.0
				if randf() < MartialRules.BOT_MISS:
					bot_rest = MartialRules.BOT_MISS_REST
				else:
					player.try_dash()
		else:
			bot_react = 0.0
	if player.is_dashing() and hero.qinggong.has("impact"):
		var im: Dictionary = hero.qinggong.impact
		var dd := Vector2(player.dash_dir.x, player.dash_dir.z)
		horde.hit_circle(p2, im.r, im.dmg * atk_mul * dyn, im.knock, dd, 99, p2, horde.CH_ULT)
	# 절기: Space · K(자동 봇은 내공이 차면 — --ult-hold면 안 씀)
	var cost: float = UltTable.LIST[ult_id].cost
	var want := false
	var uk := false
	for k in MartialRules.KEYS_ULT:
		uk = uk or Input.is_physical_key_pressed(k)
	if uk and not ult_key_was:
		want = true
	ult_key_was = uk
	if player.auto_walk and not opts.has("ult-hold"):
		want = true
	if want and neigong.can_spend(cost):
		neigong.spend(cost)
		cast_ult(ult_id, p2, Vector2(player.facing().x, player.facing().z), evolved)
	for k in range(active_ults.size() - 1, -1, -1):
		var u: Ult = active_ults[k]
		if u.tick(delta):
			ult_hits += u.hits
			u.queue_free()
			active_ults.remove_at(k)
	# 1 · 3 · 6 · 9분 곡선(밸런스)
	if opts.has("stats") and not curve_marks.is_empty() and t >= curve_marks[0]:
		curve_marks.pop_front()
		print("CURVE hero=%s t=%d lv=%d kills=%d hp=%d allies=%d ults=%d" % [hero_id, int(t), level, horde.kills, maxf(hero_hp, 0.0), allies.count, ult_casts])

func cast_ult(id: String, origin: Vector2, facing: Vector2, is_evolved: bool) -> Ult:
	## 절기 시전 — 독립 모듈에 시전 맥락만 넘김(나중에 어시스트 호출도 이 함수를 다른 origin · facing으로 부르면 됨).
	var u: Ult = UltTable.make(id)
	add_child(u)
	u.cast({"origin": origin, "facing": facing.normalized() if facing.length() > 0.01 else Vector2(0, 1),
		"horde": horde, "allies": allies, "atk_mul": atk_mul * dyn, "evolved": is_evolved, "level": level,
		"spec": UltTable.params(id, is_evolved)})
	active_ults.append(u)
	ult_casts += 1
	return u

func _apply_wave() -> void:
	var w := WaveTable.at(t)
	horde.target = w[0]
	horde.spawn_hp = w[1]
	horde.speed = w[2]
	enemy_dmg = w[3]
	horde.mix = EnemyTable.mix_at(t)   # 잡병 4종 비율(D-288)
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
		for tid in tactics:
			print("TACTIC %s lv=%d fired=%d hits=%d" % [tid, tactics[tid].lv, tactics[tid].fired, tactics[tid].hits])
		if stage:
			print("STAGE camps_broken=%s foe_dmg=%.0f foes=%s" % [",".join(stage.broken_log), foe_dmg_total,
				",".join(stage.foes.map(func(f): return "%s:%d/%d:%s" % [f.id, int(f.hp), int(f.hp_max), str(f.casts)]))])
		print("ENEMY spawned soldier=%d archer=%d rusher=%d shield=%d arrows_shot=%d arrows_hit=%d" % [
			horde.spawned_kind[0], horde.spawned_kind[1], horde.spawned_kind[2], horde.spawned_kind[3], horde.arrows_shot, horde.arrows_hit])
		if neigong:
			print("MARTIAL hero=%s attacks=%d dashes=%d ults=%d ult_hits=%d zhuhuo=%d evolved=%s stunned=%d allies=%d summoned=%d lost=%d ally_swings=%d ally_hits=%d neigong=%.0f" % [
				hero_id, weapon.attacks, player.dash_count, ult_casts, ult_hits, neigong.zhuhuo_count, evolved,
				horde.stun_total, allies.count, allies.summoned, allies.lost, allies.swings, allies.hits, neigong.value])

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
