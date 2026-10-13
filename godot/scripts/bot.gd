extends Node
## 테스트 봇(웹판 bots/bwField.js smart 대응): 지금 목표로 길을 따라 걷고, 적과 거리를 두며 싸우고, 무쌍이 차면 씀.
## 레벨업 카드는 진화 > 고르면 진화 > 기본 공격 > 가진 공격 > 짝 맞는 보조 > … 차례로 고른다(웹판 smart: 진화 · 가진 것 먼저).
## 진행을 출력하고 판이 끝나면 결과 한 줄([result] …)을 남기고 종료(이김 0 · 짐 1 · 시간 초과 2).
## 판 도중 엔진·스크립트 오류는 Logger로 모아 [error] 줄과 errors= 수로 남긴다.
## 보통은 tools/run_bot_test.py로 돌린다(여러 모드를 돌려 표로 보여 줌).
## 실행(창 없이 빠르게): Godot --path godot --headless --fixed-fps 60 -- --bot [--seed=1]
## 스크린샷(창 모드): Godot --path godot --fixed-fps 60 -- --bot --shots=<폴더> [--shot-at=3,60,120]
## 그 밖: --max-time=<초>(기본 900) · --god(장수 무적: 목표 흐름이 끝까지 이어지는지)
## 성능(D-198): --perf → 구간별 프레임 시간을 모아 '적이 가장 많던 순간'과 판 전체를 출력. 그리기 · 렌더 시간은 창 모드에서만 잡힘
##   예) Godot --path godot --fixed-fps 60 -- --bot --god --perf

const FIGHT_R := 58.0


## 판 도중의 오류·경고를 모음(어느 스레드에서든 불릴 수 있어 잠금)
class ErrorLog extends Logger:
	var lines: Array[String] = []
	var warnings := 0
	var _mx := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		_mx.lock()
		if error_type == ERROR_TYPE_WARNING:
			warnings += 1
		else:
			lines.append("%s:%d %s() %s" % [file, line, function, rationale if rationale != "" else code])
		_mx.unlock()

	func _log_message(message: String, error: bool) -> void:
		if error:
			_mx.lock()
			lines.append(message.strip_edges())
			_mx.unlock()


var b: Battle
var max_t := 900.0
## --god: 장수가 안 죽음(목표 흐름 끝까지 확인용)
var god := false
var shot_dir := ""
var shot_at: Array[float] = [3.0, 40.0, 120.0, 240.0]
var _log_t := 0.0
var _errs := ErrorLog.new()
var _done := false
## 성능 측정: 지난 봇 프레임 시각(실제 경과 = 프레임 시간, 수직 동기화 끔)
var _last_us := 0
# 버티기 · 난이도 확인(D-180): 장수 이동 거리 · 멈춘 시간 · 최저 체력 · 구간(진영 · 정원지 · 장각)별 시간과 이동 · 30초마다 아군 수
var _last_pos := Vector2.INF
var _dist := 0.0
var _still := 0.0
var _min_hp := INF
## 유비 최저 체력 비율(D-208 — 쓰러지면 짐)
var _lb_min := 1.0
## 1분마다(D-209): 공적 Lv · 그 1분 동안 둘레 120px 평균 적 · 적 수
var _tl_t := 60.0
var _tl_near := 0.0
var _tl_dt := 0.0
## 그 1분 동안 장수가 움직인 거리(D-214)
var _tl_dist := 0.0
var _timeline: Array[String] = []
var _phase_t0 := 0.0
var _phase_d0 := 0.0
var _phase_s0 := 0.0
var _phases: Array[String] = []
var _capped := {}
var _cyz_seen := false
var _boss_seen := false
var _ally_t := 30.0
var _ally_log: Array[String] = []
## 둘레 120px 안 적 수(프레임 평균) · 표본 시간
var _near_sum := 0.0
var _near_t := 0.0
## 스크린샷 모드: 첫 레벨업 카드 · 첫 진화 카드에서 몇 프레임 기다렸다 찍고 고름
var _pick_wait := 0
var _shot_pick := false
var _shot_evo := false
var _lead_shots := {}
## 줍으러 가는 구슬 자리 · 그만둘 때(D-209 — 정한 구슬은 닿거나 시간이 지날 때까지 쫓음. 안 그러면 목표와 구슬 사이를 오락가락)
var _orb_pos := Vector2.INF
var _orb_until := 0.0


func _ready() -> void:
	b = get_parent()
	OS.add_logger(_errs)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="):
			shot_dir = a.substr(8)
		elif a.begins_with("--shot-at="):
			shot_at.clear()
			for v in a.substr(10).split(","):
				shot_at.append(float(v))
		elif a.begins_with("--max-time="):
			max_t = float(a.substr(11))
		elif a == "--god":
			god = true
	if shot_dir != "":
		# 화면을 찍을 땐 수직 동기화를 꺼서 빨리 돌림(--fixed-fps로 판 시간은 그대로)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	b.bot_on = true
	if "--perf" in OS.get_cmdline_user_args():
		Perf.on = true
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if "--selftest-pause" in OS.get_cmdline_user_args():
		_selftest_pause()
		return
	b.finished.connect(_on_finished)
	print("[bot] start  hero=%s  enemies=%d  allies=%d" % [b.hero_data.display_name, b.enemies.size(), b.allies.size()])


## 일시정지 자체 점검(D-197): 버튼 터치 · 다시 눌러 풀기 · Esc · 앱이 뒤로 감 · 봇 중 포커스 잃음
func _selftest_pause() -> void:
	set_process(false)
	for i in 5:
		await get_tree().process_frame
	var vp := get_viewport()
	var c := b.hud.pause_btn.get_global_rect().get_center()
	var touch := func(pressed: bool):
		var e := InputEventScreenTouch.new()
		e.index = 1
		e.position = c
		e.pressed = pressed
		vp.push_input(e, true)
	var key := func():
		var e := InputEventKey.new()
		e.physical_keycode = KEY_ESCAPE
		e.pressed = true
		vp.push_input(e, true)
	var ok := true
	touch.call(true)
	await get_tree().process_frame
	touch.call(false)
	var tp := b.t
	for i in 10:
		await get_tree().process_frame
	ok = ok and _check("버튼 → 멈춤", b.state == "pause" and b.hud.pause_panel.visible)
	ok = ok and _check("멈춘 동안 판 시간 그대로", b.t == tp)
	_shot("pause")
	touch.call(true)
	await get_tree().process_frame
	touch.call(false)
	await get_tree().process_frame
	ok = ok and _check("다시 누름 → 계속", b.state == "play" and not b.hud.pause_panel.visible)
	key.call()
	await get_tree().process_frame
	ok = ok and _check("Esc → 멈춤", b.state == "pause")
	key.call()
	await get_tree().process_frame
	ok = ok and _check("Esc → 계속", b.state == "play")
	b.bot_on = false
	b.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ok = ok and _check("앱이 뒤로 감 → 멈춤", b.state == "pause")
	b.resume()
	b.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ok = ok and _check("포커스 잃음 → 멈춤", b.state == "pause")
	b.resume()
	b.bot_on = true
	b.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ok = ok and _check("봇 중 포커스 잃음 → 그대로", b.state == "play")
	print("[selftest] pause ", "통과" if ok else "실패")
	_quit(0 if ok else 1)


func _check(name: String, cond: bool) -> bool:
	print("[selftest] %s %s" % ["OK " if cond else "실패", name])
	return cond


func _process(_dt: float) -> void:
	Perf.begin(&"봇(측정용)")
	_bot_process()
	Perf.end()


func _bot_process() -> void:
	if b.state == "pick":
		if shot_dir != "":
			var has_evo := b.pick_opts.any(func(o): return o.get("evo", false))
			if (not _shot_pick or (has_evo and not _shot_evo)) and _pick_wait < 4:
				_pick_wait += 1
				return
			if _pick_wait >= 4:
				_shot("pick_evo" if has_evo and not _shot_evo else "pick_first")
				if has_evo:
					_shot_evo = true
				_shot_pick = true
			_pick_wait = 0
		b.choose(_pick(b.pick_opts))
		return
	if b.state != "play":
		return
	if Perf.on:
		var rid := get_viewport().get_viewport_rid()
		var now_us := Time.get_ticks_usec()
		Perf.frame({"en": b.enemies.size(), "al": b.allies.size(), "t": b.t, "ev": "Lv%d · 진영 %d/3%s" % [b.lvl, b.cap_n, " · 정원지 %d단계" % b.cyz_phase if b.cyz_on else ""],
			"proc": float(Time.get_ticks_usec() - _last_us) / 1000.0 if _last_us > 0 else 0.0,
			"rcpu": RenderingServer.viewport_get_measured_render_time_cpu(rid),
			"rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid)})
		_last_us = now_us
	_measure()
	var h := b.hero
	var T := b.field_target()
	var goal: Vector2 = T.pos
	# 보호막이 풀린 진영장이 목표 근처면 진영장을 쫓음(궁대장은 물러나며 쏨)
	for c in b.camps:
		if not c.cap and Unit.alive(c.lead) and not c.lead.shield and c.lead.position.distance_to(goal) < 220:
			goal = c.lead.position
	# 보급 상자(D-205)가 가까우면 먼저 주움
	var cd := 600.0
	var chest := false
	for dr in b.drops:
		if dr.k == "chest" and h.position.distance_to(dr.pos) < cd:
			cd = h.position.distance_to(dr.pos)
			goal = dr.pos
			chest = true
	# 고기만두(D-214): 체력이 60% 아래면 400px 안 고기만두를 주우러 감 — 사람처럼(판이 길어져 깎인 체력이 쌓임)
	if not chest and h.hp < h.max_hp * 0.6:
		var bd := 400.0
		for dr in b.drops:
			if dr.k == "bun" and h.position.distance_to(dr.pos) < bd:
				bd = h.position.distance_to(dr.pos)
				goal = dr.pos
				chest = true
	# 구슬 줍기(D-209): 목표 가까이(150px 안)에 와 있으면 둘레 300px 안 가장 가까운 구슬로 — 사람처럼
	# (전엔 목표에 서 있기만 해서 멀리서 쓰러뜨린 적의 구슬을 못 주웠음, 기다리는 시간이 생기며 레벨이 멈춤).
	# 정한 구슬은 닿거나 2.5초가 지날 때까지 쫓고, 상자 · 사신수가 있으면 줍지 않음
	if chest or (b.siege != null and b.siege.beast_pos != Vector2.INF):
		_orb_pos = Vector2.INF
	elif _orb_pos != Vector2.INF and (b.t > _orb_until or h.position.distance_to(_orb_pos) < 16):
		_orb_pos = Vector2.INF
	elif _orb_pos == Vector2.INF and h.position.distance_to(goal) < 150:
		var od := 300.0
		for o in b.orbs:
			var d: float = h.position.distance_to(o.pos)
			if d < od:
				od = d
				_orb_pos = o.pos
				_orb_until = b.t + 2.5
	if _orb_pos != Vector2.INF:
		goal = _orb_pos
	var to := goal
	if h.position.distance_to(goal) > 30:
		if b.flow.ver != b.obs_ver:
			b.flow.build(b.obs, Battle.W, Battle.H, b.obs_ver)
		if not b.flow.clear(h.position, goal):
			var n = b.flow.descend(h.position, b.flow.field("bot", goal, b.t, 0.3))
			if n != null:
				to = n
	# 웹판 smart 봇처럼 싸울 거리 유지: 가까운 적(장수급은 더 세게) · 탄에서 밀려남
	var v := (to - h.position).normalized() if h.position.distance_to(to) > 8 else Vector2.ZERO
	var near := 0
	for e in b.enemies:
		if e.dead:
			continue
		var dv := h.position - e.position
		var d := maxf(dv.length(), 1.0)
		if d < 150:
			near += 1
		# 무적이면 피하지 않고 곧장(적이 몰린 장각 본진 문 앞에서 맴돌지 않게)
		if d < FIGHT_R + e.r and not god:
			v += dv / d * (FIGHT_R + e.r - d) / FIGHT_R * 2.2 * (2.5 if e.is_lead() else 1.0)
	for s in b.shots:
		var dv: Vector2 = h.position - s.pos
		var d := maxf(dv.length(), 1.0)
		if d < 60:
			v += dv / d / d * 70
	b.bot_move = v.normalized() if v.length() > 0.15 else Vector2.ZERO
	if h.mg >= 100 and (near >= 12 or _lead_near(h.position)):
		h.musou_go()
	if god:
		h.hp = h.max_hp
	if b.t - _log_t >= 15.0:
		_log_t = b.t
		_log("")
	if not shot_at.is_empty() and b.t >= shot_at[0]:
		_shot("t%03d" % int(shot_at.pop_front()))
	if shot_dir != "":
		_shot_events()
	if b.t > max_t and not _done:
		_done = true
		_log("TIMEOUT")
		_result("timeout")
		_quit(2)


## 카드 점수: 진화 100 · 고르면 진화 60 · 기본 공격 40 · 가진 공격 30 · 가진 공격의 짝 보조 25 · 가진 보조 20 ·
## 새 보조(가진 공격의 짝) 18 · 새 공격(짝 보조를 가짐) 17 · 새 공격 15 · 새 보조 10.
## 공격을 셋(기본 공격 포함) 가졌으면 새 공격은 5(D-209 — 진화를 노리는 사람처럼 가진 것을 올림. 전엔 5~6개로 퍼져 진화가 늦었음)
func _pick(opts: Array[Dictionary]) -> int:
	var T := b.tactics
	var best := 0
	var bs := -1.0
	for i in opts.size():
		var o: Dictionary = opts[i]
		var k: String = o.k
		var sc := 1.0
		if o.get("evo", false):
			sc = 100
		elif o.get("ready", false):
			sc = 60
		elif k == "bun":
			sc = 1
		elif k == "basic":
			sc = 40
		elif T.is_act(k):
			if T.level(k) > 0:
				sc = 30
			else:
				sc = 17 if T.level(T.pair_of(k)) > 0 else 15
				if T.act_order.size() >= 3:
					sc = 5
		else:
			var paired := false
			for a in T.pairs_for(k):
				if T.level(a) > 0:
					paired = true
			if T.level(k) > 0:
				sc = 25 if paired else 20
			else:
				sc = 18 if paired else 10
		if sc > bs:
			bs = sc
			best = i
	return best


func _lead_near(p: Vector2) -> bool:
	for e in b.enemies:
		if e.is_lead() and not e.dead and not e.shield and e.position.distance_to(p) < 110:
			return true
	return false


func _log(tag: String) -> void:
	var h := b.hero
	print("[bot] %s t=%4d %4.1fms Lv%2d (%d,%d) hp %3d/%d cap %d/3 kills %4d en %3d al %2d home %3d%% mg %3d cb %3d max %4d | %s" % [
		tag, int(b.t), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, b.lvl, int(h.position.x), int(h.position.y), ceili(h.hp), int(h.max_hp), b.cap_n, b.kills, b.enemies.size(), b.allies.size(),
		ceili(b.home_hp / b.home_max * 100), int(h.mg), h.cb_n, h.cb_max, b.field_target().n])


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	var tex := get_viewport().get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	if not FileAccess.file_exists(shot_dir.path_join(".gdignore")):
		FileAccess.open(shot_dir.path_join(".gdignore"), FileAccess.WRITE)
	img.save_png(shot_dir.path_join(name + ".png"))
	print("[bot] shot ", name)


## 스크린샷 모드(D-205 · D-206): 보호막 진영장이 처음 화면에 들어올 때 · 진영장 공격마다 첫 예고가 거의 끝날 때 · 첫 보급 상자 ·
## 성문이 반쯤 열렸을 때 · 장각 보호막(장수가 본진에 들어가 제단 빛줄기가 보일 때) · 사신수가 풀려나는 중 한 장씩.
## 찍히는 건 지난 프레임에 그린 화면이라, 막 생긴 것은 조금 지나서 찍음
func _shot_events() -> void:
	# 정원지 2단계 첫 예고(D-211)
	if b.cyz_phase == 2 and Unit.alive(b.cyz) and b.cyz.st == 1 and b.cyz.t >= float(Stage1.LEAD.warn) * 0.7 and not _lead_shots.has("cyz2"):
		_lead_shots["cyz2"] = true
		_shot("cyz_phase2")
	if b.siege != null:
		var sg := b.siege
		if Unit.alive(b.boss) and b.boss.shield and b.keep_rect().grow(-20).has_point(b.hero.position) and not _lead_shots.has("altar"):
			_lead_shots["altar"] = true
			_shot("boss_altars")
		if sg.beast_t >= float(SiegeData.BEAST.release) * 0.3 and not _lead_shots.has("beast"):
			_lead_shots["beast"] = true
			_shot("beast_release")
		if sg.gate_t >= SiegeData.GATE_OPEN * 0.5 and not _lead_shots.has("gate"):
			_lead_shots["gate"] = true
			_shot("gate_open")
	if not _lead_shots.has("chest") and b.drops.any(func(dr): return dr.k == "chest" and b.in_view(dr.pos, -20)):
		_lead_shots["chest"] = true
		_shot("chest")
	for c in b.camps:
		var L: Enemy = c.lead
		if c.cap or not Unit.alive(L) or not b.in_view(L.position, -20):
			continue
		if L.shield and not _lead_shots.has("shield"):
			_lead_shots["shield"] = true
			_shot("lead_shield")
		if L.st == 1 and L.t >= float(Stage1.LEAD.warn) * 0.7 and not _lead_shots.has(L.skill):
			_lead_shots[L.skill] = true
			_shot("lead_" + L.skill)


## 매 프레임 측정. 구간이 끝나면(진영 점령 · 정원지 · 장각) 걸린 시간 · 이동 · 멈춘 비율을 한 줄로
func _measure() -> void:
	var h := b.hero
	if _last_pos != Vector2.INF:
		var d := h.position.distance_to(_last_pos)
		_dist += d
		_tl_dist += d
		if d < 0.5:
			_still += get_process_delta_time() if b.hit_stop <= 0 else 0.0
	_last_pos = h.position
	_min_hp = minf(_min_hp, h.hp)
	if Unit.alive(b.liubei):
		_lb_min = minf(_lb_min, b.liubei.hp / b.liubei.max_hp)
	elif b.liubei != null:
		_lb_min = 0.0
	var dt := get_process_delta_time()
	var near := 0
	for e in b.enemies:
		if not e.dead and not e.building and e.position.distance_to(h.position) < 120:
			near += 1
	_near_sum += near * dt
	_near_t += dt
	_tl_near += near * dt
	_tl_dt += dt
	if b.t >= _tl_t:
		_timeline.append("%s Lv%d(이동 %d · 둘레 %.1f · 적 %d)" % [_fmt(_tl_t), b.lvl, int(_tl_dist), _tl_near / maxf(_tl_dt, 0.01), b.enemies.size()])
		_tl_dist = 0.0
		_tl_near = 0.0
		_tl_dt = 0.0
		_tl_t += 60.0
	for c in b.camps:
		if c.cap and not _capped.has(c.id):
			_capped[c.id] = true
			_phase_end(String(c.n))
	if b.cyz_dead and not _cyz_seen:
		_cyz_seen = true
		_phase_end("정원지")
	if b.boss != null and b.boss.dead and not _boss_seen:
		_boss_seen = true
		_phase_end("장각")
	if b.t >= _ally_t:
		var march := 0
		for a in b.allies:
			if not a.dead and a.mode != "guard":
				march += 1
		_ally_log.append("%s %d(진군 %d)" % [_fmt(_ally_t), b.allies.size(), march])
		_ally_t += 30.0


func _phase_end(name: String) -> void:
	var dt := b.t - _phase_t0
	var still := (_still - _phase_s0) / maxf(dt, 0.01) * 100.0
	_phases.append("%s %s(+%s, 이동 %dpx, 멈춤 %d%%)" % [name, _fmt(b.t), _fmt(dt), int(_dist - _phase_d0), int(still)])
	_phase_t0 = b.t
	_phase_d0 = _dist
	_phase_s0 = _still


static func _fmt(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _on_finished(win: bool) -> void:
	_done = true
	if win and b.siege != null:
		_phase_end("사신수")
	_log("WIN" if win else "LOSE(%s)" % b.end_why)
	await get_tree().create_timer(1.2).timeout
	_shot("end")
	_result("clear" if win else "lose_" + b.end_why)
	_quit(0 if win else 1)


## 소리를 멈추고 두 프레임 뒤에 끔(재생 중인 소리가 남으면 종료 경고)
func _quit(code: int) -> void:
	Sound.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(code)


## 마지막 한 줄: 클리어 여부 · 시간 · 처치 · 오류(run_bot_test.py가 읽음)
func _result(status: String) -> void:
	OS.remove_logger(_errs)
	for l in _errs.lines.slice(0, 20):
		print("[error] ", l)
	var h := b.hero
	var T := b.tactics
	var evos: Array[String] = []
	for k in T.evo:
		evos.append(T.evo_name(k))
	var slots: Array[String] = []
	for k in T.act_order + T.pas_order:
		slots.append("%s%s" % [T.name_of(k), "(진화)" if T.evolved(k) else " %d" % T.level(k)])
	if Perf.on:
		_perf_report()
	print("[phases] " + (" · ".join(_phases) if not _phases.is_empty() else "-"))
	# 사건(D-205): 판 시각 · 사건 · 앞 사건부터 걸린 시간
	var evs: Array[String] = []
	var t0 := 0.0
	for e in b.events:
		evs.append("%s %s(+%s)" % [_fmt(e.t), e.n, _fmt(e.t - t0)])
		t0 = e.t
	print("[events] " + (" · ".join(evs) if not evs.is_empty() else "-") + " | 유비 최저 체력 %d%%" % roundi(_lb_min * 100))
	# 시각별 레벨 · 진화 시각(D-209)
	print("[timeline] " + (" · ".join(_timeline) if not _timeline.is_empty() else "-") + " · 끝 %s Lv%d" % [_fmt(b.t), b.lvl])
	var ev_t: Array[String] = []
	for e in b.events:
		if String(e.n).begins_with("진화 "):
			ev_t.append("%s %s" % [_fmt(e.t), String(e.n).substr(3)])
	print("[evo_t] " + (" · ".join(ev_t) if not ev_t.is_empty() else "-"))
	# 정원지의 대군(D-214): 진영 셋 점령 시각 · 부대마다 처음 만난 시각과 그때 본진까지 거리(직선)
	var am: Array[String] = ["진영 셋 점령 %s" % (_fmt(b.cap3_t) if b.cap3_t >= 0 else "-")]
	for u in b.army:
		var U: Dictionary = Stage1.ARMY.units[u.i]
		if u.met_t >= 0:
			am.append("%s %s 만남(본진까지 %dpx)" % [U.n, _fmt(u.met_t), int(u.met_d)])
		elif u.spawned:
			am.append("%s 못 만남" % U.n)
	print("[army] " + " · ".join(am))
	print("[allies] " + (" · ".join(_ally_log) if not _ally_log.is_empty() else "-"))
	print("[move] 이동 %dpx · 평균 %dpx/초 · 멈춤 %d%% · 둘레 120px 적 평균 %.1f · 분당 피격 %.1f · 최저 체력 %d/%d · 구슬 주운 경험 %d%%" % [int(_dist), int(_dist / maxf(b.t, 1.0)), int(_still / maxf(b.t, 1.0) * 100.0),
		_near_sum / maxf(_near_t, 0.01), h.hits_taken / maxf(b.t / 60.0, 0.01), int(_min_hp), int(h.max_hp), int(b.xp_picked / maxf(b.xp_dropped, 1.0) * 100.0)])
	print("[slots] " + " · ".join(slots))
	print("[evos] " + (", ".join(evos) if not evos.is_empty() else "-"))
	print("[picks] " + " · ".join(T.history))
	print("[result] status=%s time=%.1f kills=%d max_combo=%d cap=%d hero_hp=%d home=%d allies=%d level=%d act=%d/%d pas=%d/%d evos=%d picks=%d dist=%d still=%d min_hp=%d near=%.1f hits_pm=%.1f orbs=%d errors=%d warnings=%d" % [
		status, b.t, b.kills, h.cb_max, b.cap_n, ceili(h.hp), ceili(b.home_hp / b.home_max * 100), b.allies.size(), b.lvl,
		T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS, T.evo_count(), T.history.size(), int(_dist), int(_still / maxf(b.t, 1.0) * 100.0), int(_min_hp), _near_sum / maxf(_near_t, 0.01), h.hits_taken / maxf(b.t / 60.0, 0.01), int(b.xp_picked / maxf(b.xp_dropped, 1.0) * 100.0), _errs.lines.size(), _errs.warnings])


## 성능 정리: 적이 가장 많던 순간(앞뒤 0.5초 평균) · 판 전체 평균 · 가장 무거운 프레임
const PERF_KEYS := ["적 움직임", "길찾기", "충돌", "아군", "책략", "기본 공격", "생성", "판:기타", "HUD 갱신", "그리기 요청", "그리기:적", "그리기:아군", "그리기:바닥", "그리기:효과", "그리기:HUD"]


func _perf_report() -> void:
	var fr := Perf.frames
	if fr.size() < 10:
		return
	var peak := 0
	var worst := 0
	for i in fr.size():
		if int(fr[i].en) > int(fr[peak].en):
			peak = i
		if float(fr[i].proc) > float(fr[worst].proc):
			worst = i
	var t0: float = fr[peak].t
	var win: Array[Dictionary] = []
	for f in fr:
		if absf(float(f.t) - t0) <= 0.5:
			win.append(f)
	print("[perf] 적이 가장 많던 순간 %s · 적 %d · 아군 %d (앞뒤 0.5초 %d프레임 평균)" % [_fmt(t0), int(fr[peak].en), int(fr[peak].al), win.size()])
	print("[perf]   " + _perf_line(win))
	print("[perf] 판 전체 평균(%d프레임) · 적 평균 %d" % [fr.size(), int(_avg(fr, "en"))])
	print("[perf]   " + _perf_line(fr))
	# 무거운 프레임(처음 2초 빼고) 위 5개: 그 프레임에서 큰 구간 셋 · 그때 판 상태
	var idx: Array = []
	for i in fr.size():
		if float(fr[i].t) > 2.0:
			idx.append(i)
	idx.sort_custom(func(x, y): return float(fr[x].proc) > float(fr[y].proc))
	for j in mini(5, idx.size()):
		var f: Dictionary = fr[idx[j]]
		var cs: Array = []
		for k in PERF_KEYS:
			cs.append([float(f.get(k, 0)) / 1000.0, k])
		cs.sort_custom(func(x, y): return x[0] > y[0])
		print("[perf] 무거운 프레임 %s · 프레임 %.1fms · 렌더 CPU %.1f · 적 %d · 큰 구간 %s %.1f · %s %.1f · %s %.1f%s" % [_fmt(float(f.t)), float(f.proc), float(f.rcpu), int(f.en),
			cs[0][1], cs[0][0], cs[1][1], cs[1][0], cs[2][1], cs[2][0], " · " + String(f.get("ev", "")) if f.get("ev", "") != "" else ""])


func _perf_line(fr: Array) -> String:
	var parts: Array[String] = []
	parts.append("프레임 %.2fms(실제 경과) · 렌더 CPU %.2f · GPU %.2f" % [_avg(fr, "proc"), _avg(fr, "rcpu"), _avg(fr, "rgpu")])
	var logic := 0.0
	var draw := 0.0
	var cats: Array[String] = []
	for k in PERF_KEYS:
		var ms := _avg(fr, k) / 1000.0
		if k.begins_with("그리기"):
			draw += ms
		else:
			logic += ms
		cats.append("%s %.2f" % [k, ms])
	var bot := _avg(fr, "봇(측정용)") / 1000.0
	var rest := _avg(fr, "proc") - logic - draw - bot - _avg(fr, "rcpu")
	parts.append("판 로직 %.2fms · 그리기(GDScript) %.2fms · 봇(측정용) %.2fms · 그 밖(엔진: 노드 위치 · 정렬 · 글자 등) %.2fms" % [logic, draw, bot, rest])
	return " | ".join(parts) + "
[perf]   " + " · ".join(cats)


func _avg(fr: Array, k: String) -> float:
	var sum := 0.0
	for f in fr:
		sum += float(f.get(k, 0.0))
	return sum / maxf(fr.size(), 1)
