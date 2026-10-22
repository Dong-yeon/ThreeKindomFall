class_name Playtest
extends Node
## 사람 플레이 기록(D-221): 웹은 주소에 ?playtest=1, PC는 --playtest일 때만 Battle이 만듦(꺼져 있으면 이 노드가 없음 — 판은 전과 같음).
## 판 수치는 Battle이 이미 모으는 기록을 그대로 읽음(hurt_log · heal_log · arena_log · ev_rec · army · vil_* · lb_hurt_log 등 — 봇 출력과 같은 출처).
## 여기서 따로 재는 것: 프레임 시간(실제) · 빈 시간 · 시각별 레벨 · '지루' 누른 시각. 판이 끝나면 JSON을 user://playtest/에 저장(최근 KEEP판).
## 시각은 모두 판 시간(초, 레벨업 고르기 · 일시정지 동안은 멈춤). 실제 시간만 따로 적음.

const DIR := "user://playtest/"
const KEEP := 10
## 레벨을 적는 때(판 시간 초)
const LV_AT := [60, 180, 300, 420, 600]
## 빈 시간: 처치 없이 이 초가 지난 구간 · 화면에 적이 없는 구간(일기토 중은 뺌). 이보다 짧은 구간은 버림 · 이만큼 떨어진 구간은 합침
const GAP := 10.0
const MIN_EMPTY := 1.0
const JOIN := 0.5
const WHY := {"": "", "hero": "장수", "home": "본진", "army": "본진(대군 도착)", "liubei": "유비"}
const SMALL_N := {"spy": "첩자", "cart": "수레", "bounty": "두목"}

var b: Battle
## 판이 처음 'play'가 된 실제 시각(ms, -1 = 아직)
var wall0 := -1
## 'play' 프레임마다: 실제 간격(초) · 판 시각 · 화면에 적이 없나 · 일기토 중인가
var dts := PackedFloat32Array()
var fr_t := PackedFloat32Array()
var fr_none := PackedByteArray()
var fr_duel := PackedByteArray()
## 처치가 늘어난 판 시각
var kill_t := PackedFloat32Array()
var _kills := 0
var lv := {}
var bored_t: Array[float] = []
## 판이 끝나면 채움(결과 창 · 복사)
var data := {}
var text := ""
var saved_path := ""


static func wanted() -> bool:
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('playtest')", true)
		return q != null and str(q) == "1"
	return "--playtest" in OS.get_cmdline_user_args()


func _ready() -> void:
	b.finished.connect(_on_finished)


func _process(_dt: float) -> void:
	if b.state != "play":
		return
	if wall0 < 0:
		wall0 = Time.get_ticks_msec()
	dts.append(get_process_delta_time())
	fr_t.append(b.t)
	var none := 1
	for e in b.enemies:
		if not e.dead and not e.prop and not e.building and b.in_view(e.position, 0):
			none = 0
			break
	fr_none.append(none)
	fr_duel.append(1 if b.duel() or b.won else 0)
	if b.kills > _kills:
		_kills = b.kills
		kill_t.append(b.t)
	for m in LV_AT:
		if b.t >= m and not lv.has(m):
			lv[m] = b.lvl


## '지루' 버튼(Hud): 누른 판 시각
func bored() -> void:
	bored_t.append(snappedf(b.t, 0.1))


func _on_finished(win: bool) -> void:
	data = _build(win)
	text = JSON.stringify(data, "", false)
	saved_path = _save(text)
	print("[playtest] saved %s" % saved_path)
	print("[playtest] " + text)


# ─────────── 모으기 ───────────

func _build(win: bool) -> Dictionary:
	var h := b.hero
	var d := {
		"v": 1,
		"date": Time.get_datetime_string_from_system(false, true),
		"commit": commit(),
		"seed": b.run_seed,
		"ua": _ua(),
		"screen": "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"bot": b.bot_on,
		"result": "clear" if win else "lose",
		"why": WHY.get(b.end_why, b.end_why),
		"game_s": _r(b.t),
		"real_s": _r((Time.get_ticks_msec() - wall0) / 1000.0) if wall0 >= 0 else 0.0,
	}
	d.perf = _perf()
	d.flow = _flow()
	var duels: Array = []
	for a in b.arena_log:
		duels.append({"vs": a.ln, "unit": a.n, "t0": _r(a.t0), "dur": _r(float(a.t1) - float(a.t0)), "hurt": _r(a.hurt)})
	if not b.arena.is_empty() and b.arena.st == "on":
		duels.append({"vs": String(b.arena.lead.ename) if is_instance_valid(b.arena.lead) else "?", "unit": "", "t0": _r(b.arena.t0), "dur": _r(b.t - float(b.arena.t0)), "hurt": _r(b.arena.hurt), "open": true})
	d.duels = duels
	var hurt_all := _sum(b.hurt_log)
	d.surge = {"n": b.surge_n, "kills": b.surge_kills, "kills_all": b.kills, "kill_pct": _pct(b.surge_kills, b.kills),
		"hurt": _r(b.surge_hurt), "hurt_all": _r(hurt_all), "hurt_pct": _pct(b.surge_hurt, hurt_all)}
	var small: Array = []
	for r in b.ev_rec:
		var done := float(r.t1) >= 0
		small.append({"k": SMALL_N.get(r.k, r.k), "t0": _r(r.t0), "res": r.res if done else "진행 중", "dur": _r((float(r.t1) if done else b.t) - float(r.t0))})
	d.small = small
	d.village = {"t0": _r(b.vil_t0), "arrive_s": _r(b.vil_hero_t - b.vil_t0) if b.vil_hero_t >= 0 else -1,
		"res": {"wait": "없음", "raid": "진행 중", "saved": "구함", "lost": "불탐"}.get(b.vil_st, b.vil_st), "end_t": _r(b.vil_end_t)}
	d.liubei = {"min_pct": roundi(b.lb_min * 100), "hurt": _rd(b.lb_hurt_log)}
	var top: Array = []
	var ks: Array = b.hurt_log.keys()
	ks.sort_custom(func(x, y): return float(b.hurt_log[x]) > float(b.hurt_log[y]))
	for k in ks.slice(0, 3):
		top.append({"src": k, "dmg": _r(b.hurt_log[k]), "pct": _pct(b.hurt_log[k], hurt_all)})
	d.hero = {"min_hp": _r(b.hero_min), "max_hp": _r(h.max_hp), "hurt_top3": top, "hurt": _rd(b.hurt_log), "last": b.last_hurt}
	d.heals = b.heal_log.duplicate()
	var lvd := {}
	for m in LV_AT:
		lvd["%d분" % int(m / 60.0)] = lv.get(m, -1)
	d.lv = lvd
	d.lv_end = b.lvl
	d.picks = b.pick_n
	# 적장 거래(D-230): 시각 · 적장 · 받음 · 고른 것
	var deals: Array = []
	for D in b.deal_log:
		deals.append({"t": _r(D.t), "vs": D.vs, "took": D.took, "pick": D.pick})
	d.deals = deals
	d.musou = h.musou_n
	d.bored = bored_t.duplicate()
	d.empty = _empty()
	return d


## 성능: 'play' 프레임만(레벨업 고르기 · 일시정지 · 시작 화면 빼고). 하위 5% = 가장 느린 5% 프레임의 평균 FPS.
## 상한 비율 = 한 프레임이 Battle.DT_CAP(0.066초)을 넘은 프레임의 실제 시간 합 / 전체 — 그만큼 판이 느리게 흘렀음(잃은 판 시간 lost_s)
func _perf() -> Dictionary:
	var n := dts.size()
	if n == 0:
		return {}
	var tot := 0.0
	var cap := 0.0
	var lost := 0.0
	var s := Array(dts)
	for v in s:
		tot += v
		if v > Battle.DT_CAP:
			cap += v
			lost += v - Battle.DT_CAP
	s.sort()
	var k := maxi(1, int(n * 0.05))
	var slow := 0.0
	for i in range(n - k, n):
		slow += float(s[i])
	return {"frames": n, "play_real_s": _r(tot), "fps_avg": _r(n / maxf(tot, 0.001)), "fps_low5": _r(k / maxf(slow, 0.001)),
		"cap_pct": _r(cap / maxf(tot, 0.001) * 100.0), "cap_lost_s": _r(lost)}


func _flow() -> Dictionary:
	var camps: Array = []
	for c in b.camps:
		camps.append({"n": c.n, "t": _r(c.cap_t)})
	var army: Array = []
	var first_t := INF
	var first_d := -1.0
	for u in b.army:
		var U: Dictionary = Stage1.ARMY.units[u.i]
		army.append({"n": U.n, "met_t": _r(u.met_t), "met_d": roundi(u.met_d), "kill_t": _r(u.kill_t)})
		if float(u.met_t) >= 0 and float(u.met_t) < first_t:
			first_t = u.met_t
			first_d = u.met_d
	return {"camps": camps, "army_out": _r(b.army_t0), "army": army, "cyz2_t": _r(b.cyz2_t), "cyz_kill_t": _r(b.cyz_dead_t), "first_met_d": roundi(first_d)}


## 빈 시간: 일기토가 아닌 'play' 프레임 중 (화면에 적이 없음) 또는 (앞뒤 처치 사이가 GAP초 이상인 구간 안). 구간 목록은 MIN_EMPTY초 이상만
func _empty() -> Dictionary:
	var gaps: Array = []
	var prev := 0.0
	for kt in kill_t:
		if kt - prev >= GAP:
			gaps.append([prev, kt])
		prev = kt
	if b.t - prev >= GAP:
		gaps.append([prev, b.t])
	var list: Array = []
	var cur := []
	var gi := 0
	for i in fr_t.size():
		var t: float = fr_t[i]
		while gi < gaps.size() and t > float(gaps[gi][1]):
			gi += 1
		var in_gap: bool = gi < gaps.size() and t >= float(gaps[gi][0])
		var emp: bool = fr_duel[i] == 0 and (fr_none[i] == 1 or in_gap)
		if not emp:
			continue
		if not cur.is_empty() and t - float(cur[1]) <= JOIN:
			cur[1] = t
		else:
			if not cur.is_empty():
				list.append(cur)
			cur = [t, t]
	if not cur.is_empty():
		list.append(cur)
	var out: Array = []
	var tot := 0.0
	for c in list:
		if float(c[1]) - float(c[0]) >= MIN_EMPTY:
			out.append([_r(c[0]), _r(c[1])])
			tot += float(c[1]) - float(c[0])
	return {"total_s": _r(tot), "n": out.size(), "list": out}


# ─────────── 저장 · 보여 주기 ───────────

func _save(s: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var stamp := Time.get_datetime_string_from_system(false, false).replace(":", "").replace("-", "").replace("T", "-")
	# 같은 초에 두 판이 끝나도 덮어쓰지 않게 밀리초를 붙임
	var path := DIR + "%s-%03d.json" % [stamp, Time.get_ticks_msec() % 1000]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(s)
	f.close()
	var files: Array = []
	for fn in DirAccess.get_files_at(DIR):
		if fn.ends_with(".json"):
			files.append(fn)
	files.sort()
	while files.size() > KEEP:
		DirAccess.remove_absolute(DIR + String(files.pop_front()))
	return path


## 결과 창 요약 몇 줄
func summary() -> String:
	if data.is_empty():
		return ""
	var P: Dictionary = data.perf
	var S: Dictionary = data.surge
	var E: Dictionary = data.empty
	var L: Array = []
	L.append("── 플레이 기록 ──")
	if not P.is_empty():
		L.append("FPS 평균 %s · 하위 5%% %s · 상한 %s%%" % [P.fps_avg, P.fps_low5, P.cap_pct])
	L.append("실제 %s · 빈 시간 %d초(%d구간) · 지루 %d번" % [Hud._fmt_t(float(data.real_s)), int(E.total_s), int(E.n), data.bored.size()])
	L.append("일기토 %d번 · 무리 %d번(처치 %s%% · 피해 %s%%)" % [data.duels.size(), int(S.n), S.kill_pct, S.hurt_pct])
	L.append("유비 최저 %d%% · 장수 최저 %d · 무쌍 %d번" % [int(data.liubei.min_pct), int(data.hero.min_hp), int(data.musou)])
	return "\n".join(L)


## 커밋 해시: PC(에디터 · 명령줄 실행)는 git에 물어봄, 내보낸 빌드(웹 등)는 내보낼 때 적어 둔 res://build_info.txt(tools/export_web.py)
static func commit() -> String:
	if not OS.has_feature("web") and not OS.has_feature("template"):
		var dir := ProjectSettings.globalize_path("res://")
		var out := []
		if OS.execute("git", ["-C", dir, "rev-parse", "--short", "HEAD"], out) == 0 and not out.is_empty():
			var st := []
			OS.execute("git", ["-C", dir, "status", "--porcelain", "--untracked-files=no"], st)
			var dirty := not st.is_empty() and String(st[0]).strip_edges() != ""
			return String(out[0]).strip_edges() + ("-dirty" if dirty else "")
	if FileAccess.file_exists("res://build_info.txt"):
		return FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
	return "unknown"


static func _ua() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("navigator.userAgent", true))
	return "%s %s · %s · %s" % [OS.get_name(), OS.get_version(), OS.get_processor_name(), RenderingServer.get_video_adapter_name()]


static func _r(v) -> float:
	return snappedf(float(v), 0.1)


static func _pct(part, whole) -> float:
	return snappedf(float(part) / maxf(float(whole), 0.001) * 100.0, 0.1)


static func _sum(dict: Dictionary) -> float:
	var s := 0.0
	for k in dict:
		s += float(dict[k])
	return s


static func _rd(dict: Dictionary) -> Dictionary:
	var o := {}
	for k in dict:
		o[k] = _r(dict[k])
	return o
