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

const CAM_OFFSET := Vector3(0, 13.0, 12.0)   # D-306: 7 · 8.5 · 55° → 13 · 12 · 50°(둘레 무리 · 예고가 보이게)
var cam_offset := CAM_OFFSET   # 점검 --cam=높이,뒤,화각(D-301 카메라 비교)
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
var hud: Control              # scripts/ui/hud.gd(D-297)
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
var pick_log: Array[String] = []
var tactics := {}             # 책략 id → 노드(D-284, 최대 TacticTable.MAX_SLOTS)
var atk_mul := 1.0            # 무력 — 책략 피해에 곱함(대표 무기는 weapon.mods.dmg)
var pick_open_ms := 0         # 키를 누른 채로 다음 고르기까지 넘어가지 않게(0.3초)
var invuln := 0.0
# 무공(D-285)
var neigong: Neigong
var ult_id := ""
var evolved := false
var active_ults: Array = []
var ult_casts := 0
var ult_hits := 0
var ult_key_was := false
var last_hits := 0
var last_kills := 0
var dyn := 1.0                # 이번 프레임 공격 배율(주화입마 × 광폭)
var passive_mod: Node3D       # 고유 심법 모듈(D-333 — 청룡의 피 · 천기: scripts/martial/passive_*.gd, 없으면 null)
const PASSIVE_MODS := {"dragon": "res://scripts/martial/passive_dragon.gd", "weather": "res://scripts/martial/passive_weather.gd"}
var curve_marks := [60.0, 180.0, 360.0, 540.0]
var stage: Node3D             # 황건적 스테이지(D-289 — 진영 · 정예 · 상자)
var foe_dmg_total := 0.0
# 여포 보스전(D-290)
const ARENA_R := 14.0
const BOSS_GUARDS := 20
var boss_active := false
var boss: Node3D
var boss_t0 := 0.0
var arena_c := Vector2.ZERO
var boss_result := ""
var bot_react := 0.0          # 봇 경공 반응 지연 누적
var bot_rest := 0.0           # 봇이 경공을 놓친 뒤 쉬는 시간
# 메타 진행(D-292): 판 기록 → Meta.end_run(과제 · 해금)
var nohit_t := 0.0            # 지금 안 맞고 버틴 시간
var best_nohit := 0.0
var lowhp_t := 0.0            # 체력 30% 아래로 버틴 시간(누적)
var gems_got := 0
var run_ended := false
var cam_ready := false
var paused := false           # 일시정지(D-300)
var pause_key_was := false
var pause_shot_t := 0.0
var result_ui: Control        # scripts/ui/result.gd(결과 창 · 일시정지)
var god := false
var dead := false
var cleared := false
var waves := true
var final_shown := false
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
	if opts.has("cam"):
		var cv := String(opts["cam"]).split(",")
		cam_offset = Vector3(0, float(cv[0]), float(cv[1]))
		if cv.size() > 2:
			cam.fov = float(cv[2])
	player = preload("res://scripts/player.gd").new()
	player.name = "Player"
	add_child(player)
	hero_id = opts.get("hero", HeroTable.chosen if HeroTable.chosen != "" else "guan_yu")
	hero = HeroTable.get_hero(hero_id)
	max_hp = hero.get("hp", HERO_HP)   # 장수마다 시작 체력(D-291)
	hero_hp = max_hp
	if opts.has("select-test"):   # 선택 화면 → 판 진입 점검: 넘어온 장수만 출력
		print("MAIN hero=%s (선택 화면에서 고름=%s)" % [hero_id, HeroTable.chosen])
		get_tree().quit()
		return
	player.setup(load(hero.glb))
	if player.model:   # 장수 모델 크기(데이터 — 큰 머리 그림체에서 잡병보다 돋보이게 기본 1.2배, D-307)
		player.model.scale = Vector3.ONE * float(hero.get("scale", HeroTable.MODEL_SCALE))
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
	if PASSIVE_MODS.has(hero.passive.id):
		passive_mod = load(PASSIVE_MODS[hero.passive.id]).new()
		add_child(passive_mod)
		passive_mod.setup(self)
	match hero.passive.id:
		"wipung":   # (예전 관우 — D-333에서 청룡의 피로 바뀜)
			weapon.mods.area *= hero.passive.area
			weapon.mods.knock *= hero.passive.knock
			weapon.refresh_fx()
		"indeok":
			regen += hero.passive.regen
		"wolong":   # 와룡(D-295): 추가 초식 칸 +1(max_slots) · 책략 계열 피해 ↑(tactic.strat_mul)
			pass
	neigong = Neigong.new()
	ult_id = hero.ult
	if opts.has("force-evolve"):
		evolved = true
		print("EVOLVE forced %s -> %s" % [UltTable.LIST[ult_id].name, UltTable.display_name(ult_id, true)])
	if opts.has("neigong"):   # --neigong=100: 처음 내공(점검용)
		neigong.value = float(opts["neigong"])
	if opts.has("boss"):   # --boss: 9분대 평균쯤으로 키워서 곧바로 보스전(점검용)
		t = WaveTable.RUN_TIME - 0.02
		_apply_wave()
		var keep := auto_pick
		auto_pick = true
		for k in int(opts.get("boss-lv", "45")) - 1:
			level += 1
			choices = _offers()
			_apply_upgrade(choices[_auto_choice()])
		auto_pick = keep
		print("BOSSTEST lv=%d evolved=%s picks=%s" % [level, evolved, str(ups)])
	if opts.has("tactic"):   # --tactic=orbit,rain … (쉼표로 여럿)
		for tid in String(opts["tactic"]).split(","):
			_apply_upgrade("t:" + tid)
	auto_pick = opts.get("pick", "") == "auto" or ((opts.has("auto") or bench or shots_dir != "") and opts.get("pick", "") != "manual")
	var layer := CanvasLayer.new()
	hud = preload("res://scripts/ui/hud.gd").new()   # 전투 HUD(D-297 — scripts/ui/hud.gd)
	layer.add_child(hud)
	hud.setup(self)
	flash = hud.flash
	msg = hud.msg
	_build_pick(layer)
	result_ui = preload("res://scripts/ui/result.gd").new()
	layer.add_child(result_ui)
	result_ui.setup(self)
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
	cam.fov = 50
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
	# 일시정지(D-300): P · 판 중 Esc(봇은 안 읽음) · 점검 --pause-test는 1초에 염
	var pk := Input.is_physical_key_pressed(KEY_P) or (Input.is_physical_key_pressed(KEY_ESCAPE) and not dead and not cleared)
	if (pk and not pause_key_was and not player.auto_walk) or (opts.has("pause-test") and t >= 1.0 and not paused and not ("pause_done" in opts)):
		opts["pause_done"] = "1"
		if paused:
			resume()
		elif not dead and not cleared and not choosing:
			paused = true
			player.set_process(false)
			result_ui.show_pause(build_text(), hero)
	pause_key_was = pk
	if paused:
		t -= delta   # 판 시간은 멈춤(맨 위에서 더한 것을 되돌림)
		if opts.has("pause-test"):
			_pause_test_tick()
		return
	if choosing:
		_pick_input()
		return
	if horde and not dead and not cleared:
		if waves:
			if not boss_active:
				_apply_wave()
			if t >= WaveTable.RUN_TIME and not boss_active:
				if stage:
					_start_boss()   # D-290: 10분을 버티면 호뢰관 여포
				else:
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
		var got: int = gems.update(delta, p2)
		xp += got
		gems_got += got
		nohit_t += delta
		best_nohit = maxf(best_nohit, nohit_t)
		if hero_hp < max_hp * 0.3:
			lowhp_t += delta
		if xp >= UpgradeTable.need(level):
			xp -= UpgradeTable.need(level)
			level += 1
			_open_pick()
		hero_hp = minf(hero_hp + regen * delta, max_hp)
		invuln = maxf(invuln - delta, 0.0)
		if hits > 0.0 and invuln <= 0.0 and player.iframe_t <= 0.0 and not god:
			hero_hp -= enemy_dmg * armor * minf(hits, 1.0)
			invuln = IFRAME
			nohit_t = 0.0
			flash.color.a = 0.35
			if hero_hp <= 0.0:
				_die()
	if (dead or cleared) and Input.is_physical_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		return
	if (dead or cleared) and Input.is_physical_key_pressed(KEY_ESCAPE) and not pause_key_was:   # 장수 선택으로(새로 연 장수를 고르게, D-292)
		get_tree().change_scene_to_file("res://scenes/select.tscn")
		return
	# 3인칭 고정 각도로 뒤 · 위에서 따라감(마우스 시점은 다음 단계)
	var target := player.position + Vector3(0, 1.0, 0)
	cam.position = cam.position.lerp(target + cam_offset, clampf(delta * 6.0, 0, 1)) if cam_ready else target + cam_offset   # 첫 프레임은 바로 맞춤(--start여도, D-297)
	cam_ready = true
	cam.look_at(target)
	if hud:
		fps_acc += delta; fps_n += 1
		if fps_acc >= 0.5:
			fps_show = fps_n / fps_acc; fps_acc = 0.0; fps_n = 0
		hud.refresh(self, delta)
	if bench:
		_bench_tick(delta)

# ── 레벨업 고르기 ──
func _build_pick(layer: CanvasLayer) -> void:
	pick_box = preload("res://scripts/ui/levelup.gd").new()   # 레벨업 카드(D-298 — scripts/ui/levelup.gd)
	layer.add_child(pick_box)
	pick_box.setup(self)

func _offers() -> Array:
	var pool := []
	for key in UpgradeTable.LIST:
		var u: Dictionary = UpgradeTable.LIST[key]
		if ups.get(key, 0) >= u.max:
			continue
		if u.has("only") and not (hero.weapon.type in u.only):
			continue
		if u.kind == "stat" and not Meta.is_unlocked("simbeop", key):   # 잠긴 심법은 카드에 안 나옴(D-292)
			continue
		pool.append(key)
	for tid in TacticTable.LIST:   # 책략: 가진 것은 강화(최대 레벨까지), 없는 것은 자리가 남았을 때 새로(잠긴 것은 빼고)
		if tactics.has(tid):
			if tactics[tid].lv < TacticTable.MAX_LV:
				pool.append("t:" + tid)
		elif tactics.size() < max_slots() and Meta.is_unlocked("tactic", tid):
			pool.append("t:" + tid)
	pool.shuffle()
	pool = pool.slice(0, 3)
	if pool.is_empty():
		pool = ["heal"]
	return pool

func max_slots() -> int:
	## 추가 초식 칸: 기본 + 과제 해금(D-292).
	return TacticTable.MAX_SLOTS + Meta.extra_slots() + int(hero.passive.get("slots", 0))

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
	pick_box.open(choices)

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
			if TacticTable.LIST[tid].get("strat", false):
				tac.strat_mul = hero.passive.get("strat", 1.0)
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
	if boss_active:   # 목책 고리 안에 묶음 · 보스 막대
		var off := Vector2(player.position.x, player.position.z) - arena_c
		if off.length() > ARENA_R - 0.6:
			off = off.normalized() * (ARENA_R - 0.6)
			player.position.x = arena_c.x + off.x
			player.position.z = arena_c.y + off.y
	var fd: float = stage.tick(delta, p2, enemy_dmg / 7.8, t)
	if fd > 0.0 and invuln <= 0.0 and player.iframe_t <= 0.0 and not god:
		hero_hp -= fd * armor
		foe_dmg_total += fd * armor
		invuln = IFRAME
		nohit_t = 0.0
		flash.color.a = 0.45
		if hero_hp <= 0.0:
			_die()
			return
	# 봇: 체력이 넉넉하고 1분이 지났으면 가장 가까운 진영으로(진영 진행을 재려고)
	if player.auto_walk and boss_active:   # 보스전 봇: 여포 둘레를 조금 멀리 돎
		player.has_goal = boss != null and boss.alive
		player.goal_direct = false
		player.orbit_r = 6.5
		if player.has_goal:
			player.goal = boss.position
		return
	if player.auto_walk:
		player.has_goal = false
		player.goal_direct = false
		for c in stage.camps:   # 상자가 있으면 먼저 주우러
			if c.chest and is_instance_valid(c.chest):
				player.goal = c.chest.position
				player.has_goal = true
				player.goal_direct = true
		if not player.has_goal and hero_hp > max_hp * 0.7 and t > 120.0:
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
	if hud and not dead and not cleared:
		hud.banner(text, sec)   # 위쪽 알림 띠(D-297)

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
	if passive_mod:   # 고유 심법 모듈이 무기 배율(dyn · haste · dyn_area)을 더 손봄
		passive_mod.tick(delta)
	for tac in tactics.values():
		tac.atk_mul = atk_mul * dyn
	# 인덕(D-293): 둘레 적이 많을수록 공격 속도 ↑
	if hero.passive.id == "indeok":
		var near: int = horde.count_within(p2, hero.passive.r)
		weapon.haste = 1.0 + hero.passive.haste * clampf(float(near) / hero.passive.full, 0.0, 1.0)
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
		var threat := Vector2.ZERO   # 적장 예고 범위 안이면 옆으로 피함(D-290)
		if stage:
			for fo in stage.foes:
				if fo.alive and fo.threatens(p2):
					threat = (p2 - fo.pos2()).normalized()
		if threat != Vector2.ZERO:
			bot_react += delta
			if bot_react >= MartialRules.BOT_REACT and bot_rest <= 0.0:
				bot_react = 0.0
				if randf() < MartialRules.BOT_MISS:
					bot_rest = MartialRules.BOT_MISS_REST
				else:
					var side := Vector2(-threat.y, threat.x) if randf() < 0.5 else Vector2(threat.y, -threat.x)
					var dd := (side + threat).normalized()
					player.try_dash(Vector3(dd.x, 0, dd.y))
		elif horde.count_within(p2, MartialRules.BOT_DASH_R) >= MartialRules.BOT_DASH_N:
			bot_react += delta
			if bot_react >= MartialRules.BOT_REACT and bot_rest <= 0.0:
				bot_react = 0.0
				if randf() < MartialRules.BOT_MISS:
					bot_rest = MartialRules.BOT_MISS_REST
				else:
					player.try_dash()
		else:
			bot_react = 0.0
	if player.blinked:   # 축지: 닿은 자리에 잠깐 빛
		player.blinked = false
		_blink_fx(p2)
	if player.landed:   # 도약이 내려앉음: 용약 충격파(D-333)
		player.landed = false
		if hero.qinggong.has("land"):
			var ld: Dictionary = hero.qinggong.land
			horde.hit_circle(p2, ld.r, ld.dmg * atk_mul * dyn, ld.knock, Vector2.ZERO, 99, p2, horde.CH_ULT)
			_land_fx(p2, ld.r)
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
		print("CURVE hero=%s t=%d lv=%d kills=%d hp=%d ults=%d" % [hero_id, int(t), level, horde.kills, maxf(hero_hp, 0.0), ult_casts])

func _blink_fx(at: Vector2) -> void:
	var ps := CPUParticles3D.new()
	ps.one_shot = true; ps.amount = 24; ps.lifetime = 0.4; ps.explosiveness = 1.0
	ps.direction = Vector3.UP; ps.spread = 60.0; ps.initial_velocity_min = 1.5; ps.initial_velocity_max = 3.0
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 0.1)
	ps.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.7, 0.9, 1.0)
	ps.material_override = m
	ps.position = Vector3(at.x, 0.8, at.y)
	add_child(ps)
	ps.emitting = true
	get_tree().create_timer(1.0).timeout.connect(ps.queue_free)

func _land_fx(at: Vector2, r: float) -> void:
	## 용약 내려앉는 자리: 바닥에 퍼지는 고리 + 흙먼지.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.4, 1.0, 0.8, 0.7)
	ring.material_override = m
	ring.position = Vector3(at.x, 0.1, at.y)
	ring.scale = Vector3(0.3, 0.3, 0.3)
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3(r, 1.0, r), 0.25)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(ring.queue_free)
	_blink_fx(at)

func cast_ult(id: String, origin: Vector2, facing: Vector2, is_evolved: bool) -> Ult:
	## 절기 시전 — 독립 모듈에 시전 맥락만 넘김(나중에 어시스트 호출도 이 함수를 다른 origin · facing으로 부르면 됨).
	var u: Ult = UltTable.make(id)
	add_child(u)
	u.cast({"origin": origin, "facing": facing.normalized() if facing.length() > 0.01 else Vector2(0, 1),
		"horde": horde, "atk_mul": atk_mul * dyn, "evolved": is_evolved, "level": level, "anchor": player,
		"weather": passive_mod.weather() if passive_mod and passive_mod.has_method("weather") else "",
		"spec": UltTable.params(id, is_evolved)})
	active_ults.append(u)
	ult_casts += 1
	if passive_mod and passive_mod.has_method("on_ult"):
		passive_mod.on_ult()
	if is_evolved and passive_mod and passive_mod.has_method("force_wind") and u.p.has("gale_r"):   # 동남풍: 진 시간 동안 바람에 묶음
		passive_mod.force_wind(float(u.p.dur))
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
		_banner("마지막 대군!\n1분만 버티면 된다", 3.0)
		print("FINAL t=%.1f" % t)

func _start_boss() -> void:
	## 호뢰관: 남은 잡병을 흩고 장수 둘레에 목책 고리 → 여포 등장, 호위 잡병만 조금(D-290).
	boss_active = true
	boss_t0 = t
	var p2 := Vector2(player.position.x, player.position.z)
	var b: Rect2 = StageYellow.BOUNDS
	arena_c = Vector2(clampf(p2.x, b.position.x + ARENA_R + 2, b.end.x - ARENA_R - 2), clampf(p2.y, b.position.y + ARENA_R + 2, b.end.y - ARENA_R - 2))
	horde.scatter(p2)
	horde.target = BOSS_GUARDS
	horde.spawn_points = PackedVector2Array()
	stage.boss_mode = true
	stage.build_arena(arena_c, ARENA_R)
	boss = preload("res://scripts/foe/foe.gd").new()
	stage.add_child(boss)
	boss.setup("lubu", arena_c + Vector2(0, -ARENA_R * 0.6), horde, load("res://assets/fonts/Galmuri11.ttf"))
	boss.engaged = true
	boss.died.connect(_on_boss_dead)
	stage.add_foe(boss)
	hud.show_boss(true)
	_banner("호뢰관\n여포가 나타났다!", 3.0)
	print("BOSS start t=%.1f lv=%d hp=%d" % [t, level, hero_hp])

func _on_boss_dead(_fo) -> void:
	boss_result = "win"
	print("BOSS defeated t=%.1f dur=%.1f hp=%d" % [t, t - boss_t0, hero_hp])
	_win()

func _win() -> void:
	cleared = true
	player.set_process(false)
	player.play_final("cheer")   # 개그 동작(D-313): 승리하면 깡충깡충
	_end_run("호뢰관 승리!" if boss_active else "버텼습니다!")
	print("CLEAR t=%.1f kills=%d hp=%d" % [t, horde.kills, hero_hp])

func _exit_tree() -> void:
	if opts.has("stats") and horde:
		print("STATS hero=%s t=%.1f kills=%d hp=%d attacks=%d dead=%s cleared=%s enemies=%d enemy_hp=%.1f level=%d" % [hero_id, t, horde.kills, maxf(hero_hp, 0.0), weapon.attacks, dead, cleared, horde.count, horde.spawn_hp, level])
		print("PICKS ", " ".join(pick_log))
		for tid in tactics:
			print("TACTIC %s lv=%d fired=%d hits=%d chains=%d" % [tid, tactics[tid].lv, tactics[tid].fired, tactics[tid].hits, tactics[tid].chains])
		if hero.weapon.type == "boomerang":
			print("BOOMERANG out_hits=%d return_hits=%d" % [weapon.outs, weapon.returns])
		if boss_active:
			print("BOSS result=%s dur=%.1f boss_hp=%d/%d casts=%s" % [boss_result if boss_result != "" else ("lose" if dead else "timeout"),
				t - boss_t0, int(boss.hp) if boss else 0, int(boss.hp_max) if boss else 0, str(boss.casts) if boss else ""])
		if stage:
			print("STAGE camps_broken=%s foe_dmg=%.0f foes=%s" % [",".join(stage.broken_log), foe_dmg_total,
				",".join(stage.foes.map(func(f): return "%s:%d/%d:%s" % [f.id, int(f.hp), int(f.hp_max), str(f.casts)]))])
		print("ENEMY spawned soldier=%d archer=%d rusher=%d shield=%d arrows_shot=%d arrows_hit=%d" % [
			horde.spawned_kind[0], horde.spawned_kind[1], horde.spawned_kind[2], horde.spawned_kind[3], horde.arrows_shot, horde.arrows_hit])
		if passive_mod:
			print(passive_mod.stats())
		if neigong:
			print("MARTIAL hero=%s attacks=%d dashes=%d ults=%d ult_hits=%d zhuhuo=%d evolved=%s stunned=%d neigong=%.0f" % [
				hero_id, weapon.attacks, player.dash_count, ult_casts, ult_hits, neigong.zhuhuo_count, evolved,
				horde.stun_total, neigong.value])

func _die() -> void:
	dead = true
	player.set_process(false)
	player.play_final("down")   # 개그 동작(D-313): 쓰러지면 벌러덩
	_end_run("쓰러졌습니다")
	print("DEAD t=%.1f kills=%d" % [t, horde.kills])

func _end_run(head: String) -> void:
	## 판 결과를 메타 진행에 넘기고 결과 창(D-300 — scripts/ui/result.gd)을 띄움. 새로 깬 과제는 '새로 해금!'(D-292).
	if run_ended:
		return
	run_ended = true
	if opts.has("auto") and shots_dir == "":   # 자동 판(밸런스 측정)은 끝나면 1초 뒤 닫음 — --stats 줄이 찍히게(D-334)
		get_tree().create_timer(1.0).timeout.connect(get_tree().quit)
	var elites := 0
	if stage:
		for fo in stage.foes:
			if not fo.alive and fo.id != "lubu":
				elites += 1
	var run := {"hero": hero_id, "kills": horde.kills, "elite_kills": elites, "gems": gems_got,
		"lubu": 1 if boss_result == "win" else 0, "cleared": cleared, "nohit": best_nohit,
		"camps": stage.broken_log.size() if stage else 0, "lowhp": lowhp_t}
	var fresh: Array = Meta.end_run(run)
	print("META run=%s new=%s done=%d saving=%s" % [JSON.stringify(run), ",".join(fresh.map(func(q): return q.id)), Meta.data.done.size(), Meta.saving])
	if result_ui:
		var rows := [["장수", "%s  ·  %s" % [hero.name, hero.role]], ["버틴 시간", "%d:%02d" % [int(t) / 60, int(t) % 60]],
			["처치", str(horde.kills)], ["레벨", str(level)], ["깬 진영", "%d / %d" % [run.camps, StageYellow.CAMPS.size()] if stage else "—"],
			["여포", "%d초 만에 처치" % int(t - boss_t0) if boss_result == "win" else ("싸우다 쓰러짐" if boss_active else "—")],
			["절기", "%d번 · %s" % [ult_casts, UltTable.display_name(ult_id, evolved)]]]
		result_ui.show_result(head, rows, build_text(), fresh)

func build_text() -> String:
	## 결과 창 · 일시정지에 보일 빌드 한 줄.
	var parts := [hero.weapon.name]
	for tid in tactics:
		parts.append("%s %d" % [TacticTable.LIST[tid].name, tactics[tid].lv])
	for key in UpgradeTable.LIST:
		if UpgradeTable.LIST[key].kind == "stat" and ups.get(key, 0) > 0:
			parts.append("%s %d" % [UpgradeTable.LIST[key].name, ups[key]])
	return " · ".join(parts)

func resume() -> void:
	paused = false
	result_ui.hide_all()
	if not dead and not cleared:
		player.set_process(true)

func _pause_test_tick() -> void:
	## --pause-test --shots=<폴더>: 일시정지 창을 찍고 끝냄.
	pause_shot_t += get_process_delta_time()
	if pause_shot_t > 0.3 and pause_shot_t < 1.0 and shots_dir != "":
		pause_shot_t = 2.0
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(shots_dir)
		var path := shots_dir.path_join("pause.png")
		get_viewport().get_texture().get_image().save_png(path)
		print("SHOT ", path)
		get_tree().quit()

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
