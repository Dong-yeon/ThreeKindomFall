extends Node
## 테스트 봇(웹판 bots/bwField.js smart 대응): 지금 목표로 길을 따라 걷고, 적과 거리를 두며 싸우고, 무쌍이 차면 씀.
## 레벨업 카드는 진화 > 고르면 진화 > 기본 공격 > 가진 공격 > 짝 맞는 보조 > … 차례로 고른다(웹판 smart: 진화 · 가진 것 먼저).
## 진행을 출력하고 판이 끝나면 결과 한 줄([result] …)을 남기고 종료(이김 0 · 짐 1 · 시간 초과 2).
## 판 도중 엔진·스크립트 오류는 Logger로 모아 [error] 줄과 errors= 수로 남긴다.
## 보통은 tools/run_bot_test.py로 돌린다(여러 모드를 돌려 표로 보여 줌).
## 실행(창 없이 빠르게): Godot --path godot --headless --fixed-fps 60 -- --bot [--seed=1]
## 스크린샷(창 모드): Godot --path godot --fixed-fps 60 -- --bot --shots=<폴더> [--shot-at=3,60,120]
## 그 밖: --max-time=<초>(기본 900) · --god(장수 무적: 목표 흐름이 끝까지 이어지는지)

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
# 버티기 · 난이도 확인(D-180): 장수 이동 거리 · 멈춘 시간 · 최저 체력 · 구간(진영 · 정원지 · 장각)별 시간과 이동 · 30초마다 아군 수
var _last_pos := Vector2.INF
var _dist := 0.0
var _still := 0.0
var _min_hp := INF
var _phase_t0 := 0.0
var _phase_d0 := 0.0
var _phase_s0 := 0.0
var _phases: Array[String] = []
var _capped := {}
var _cyz_seen := false
var _ally_t := 30.0
var _ally_log: Array[String] = []
## 둘레 120px 안 적 수(프레임 평균) · 표본 시간
var _near_sum := 0.0
var _near_t := 0.0
## 스크린샷 모드: 첫 레벨업 카드 · 첫 진화 카드에서 몇 프레임 기다렸다 찍고 고름
var _pick_wait := 0
var _shot_pick := false
var _shot_evo := false


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
	b.finished.connect(_on_finished)
	print("[bot] start  hero=%s  enemies=%d  allies=%d" % [b.hero_data.display_name, b.enemies.size(), b.allies.size()])


func _process(_dt: float) -> void:
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
	_measure()
	var h := b.hero
	var T := b.field_target()
	var goal: Vector2 = T.pos
	# 진영장이 나왔으면 진영 가운데가 아니라 진영장을 쫓음(궁대장은 물러나며 쏨)
	for c in b.camps:
		if not c.cap and c.lead != null and Unit.alive(c.lead) and c.lead.position.distance_to(goal) < 220:
			goal = c.lead.position
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
	if b.t > max_t and not _done:
		_done = true
		_log("TIMEOUT")
		_result("timeout")
		_quit(2)


## 카드 점수: 진화 100 · 고르면 진화 60 · 기본 공격 40 · 가진 공격 30 · 가진 공격의 짝 보조 25 · 가진 보조 20 ·
## 새 보조(가진 공격의 짝) 18 · 새 공격(짝 보조를 가짐) 17 · 새 공격 15 · 새 보조 10
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
		if e.is_lead() and not e.dead and e.position.distance_to(p) < 110:
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


## 매 프레임 측정. 구간이 끝나면(진영 점령 · 정원지 · 장각) 걸린 시간 · 이동 · 멈춘 비율을 한 줄로
func _measure() -> void:
	var h := b.hero
	if _last_pos != Vector2.INF:
		var d := h.position.distance_to(_last_pos)
		_dist += d
		if d < 0.5:
			_still += get_process_delta_time() if b.hit_stop <= 0 else 0.0
	_last_pos = h.position
	_min_hp = minf(_min_hp, h.hp)
	var dt := get_process_delta_time()
	var near := 0
	for e in b.enemies:
		if not e.dead and not e.building and e.position.distance_to(h.position) < 120:
			near += 1
	_near_sum += near * dt
	_near_t += dt
	for c in b.camps:
		if c.cap and not _capped.has(c.id):
			_capped[c.id] = true
			_phase_end(String(c.n))
	if b.cyz_dead and not _cyz_seen:
		_cyz_seen = true
		_phase_end("정원지")
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
	if win:
		_phase_end("장각")
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
	print("[phases] " + (" · ".join(_phases) if not _phases.is_empty() else "-"))
	print("[allies] " + (" · ".join(_ally_log) if not _ally_log.is_empty() else "-"))
	print("[move] 이동 %dpx · 평균 %dpx/초 · 멈춤 %d%% · 둘레 120px 적 평균 %.1f · 분당 피격 %.1f · 최저 체력 %d/%d · 구슬 주운 경험 %d%%" % [int(_dist), int(_dist / maxf(b.t, 1.0)), int(_still / maxf(b.t, 1.0) * 100.0),
		_near_sum / maxf(_near_t, 0.01), h.hits_taken / maxf(b.t / 60.0, 0.01), int(_min_hp), int(h.max_hp), int(b.xp_picked / maxf(b.xp_dropped, 1.0) * 100.0)])
	print("[slots] " + " · ".join(slots))
	print("[evos] " + (", ".join(evos) if not evos.is_empty() else "-"))
	print("[picks] " + " · ".join(T.history))
	print("[result] status=%s time=%.1f kills=%d max_combo=%d cap=%d hero_hp=%d home=%d allies=%d level=%d act=%d/%d pas=%d/%d evos=%d picks=%d dist=%d still=%d min_hp=%d near=%.1f hits_pm=%.1f orbs=%d errors=%d warnings=%d" % [
		status, b.t, b.kills, h.cb_max, b.cap_n, ceili(h.hp), ceili(b.home_hp / b.home_max * 100), b.allies.size(), b.lvl,
		T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS, T.evo_count(), T.history.size(), int(_dist), int(_still / maxf(b.t, 1.0) * 100.0), int(_min_hp), _near_sum / maxf(_near_t, 0.01), h.hits_taken / maxf(b.t / 60.0, 0.01), int(b.xp_picked / maxf(b.xp_dropped, 1.0) * 100.0), _errs.lines.size(), _errs.warnings])
