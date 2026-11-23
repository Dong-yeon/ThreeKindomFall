extends Node
## 메타 진행(D-292, 자동 로드 Meta): 여러 판 누적 통계 · 깬 과제 · 해금을 user://save3d.json에 저장. 과제 표는 data/unlocks.gd.
## 봇 · 점검(--auto · --bench · --test · --shots · --select-test)은 저장 파일을 읽지도 쓰지도 않음(빈 상태로 시작 — 판이 사람 저장에 안 휘둘림).
## 점검: --save=<경로> 그 파일을 읽고 씀(봇이어도) · --unlock-all 모두 열린 것으로(저장은 안 바꿈).

const PATH := "user://save3d.json"
const VERSION := 1

var path := PATH
var saving := true
var unlock_all := false
var data := {}

func _ready() -> void:
	var o := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			o[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if o.has("save"):
		path = o["save"]
	saving = o.has("save") or not (o.has("auto") or o.has("bench") or o.has("test") or o.has("shots") or o.has("select-test"))
	unlock_all = o.has("unlock-all")
	data = _fresh()
	if saving and FileAccess.file_exists(path):
		var txt := FileAccess.get_file_as_string(path)
		var d = JSON.parse_string(txt)
		if typeof(d) == TYPE_DICTIONARY:
			for k in ["total", "best", "clears"]:
				if typeof(d.get(k)) == TYPE_DICTIONARY:
					for kk in d[k]:
						data[k][kk] = float(d[k][kk])
			if typeof(d.get("done")) == TYPE_ARRAY:
				for q in d["done"]:
					data.done.append(String(q))

func _fresh() -> Dictionary:
	return {"version": VERSION, "total": {"kills": 0.0, "elite_kills": 0.0, "gems": 0.0, "lubu": 0.0, "runs": 0.0},
		"best": {"nohit": 0.0, "camps": 0.0, "lowhp": 0.0}, "clears": {}, "done": []}

func save() -> void:
	if not saving:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

# ── 해금 ──
func quest_for(kind: String, id: String) -> Dictionary:
	## 이 장수 · 초식 · 심법을 보상으로 주는 과제(없으면 빈 것 = 처음부터 열림).
	for q in UnlockTable.QUESTS:
		if q.reward[0] == kind and q.reward[1] == id:
			return q
	return {}

func is_unlocked(kind: String, id: String) -> bool:
	if unlock_all:
		return true
	var q := quest_for(kind, id)
	return q.is_empty() or q.id in data.done

func extra_slots() -> int:
	var n := 0
	for q in UnlockTable.QUESTS:
		if q.reward[0] == "slot" and (unlock_all or q.id in data.done):
			n += int(q.reward[1])
	return n

func progress(q: Dictionary) -> Vector2:
	## (지금, 목표)
	match q.kind:
		"total": return Vector2(minf(data.total.get(q.key, 0.0), q.goal), q.goal)
		"best": return Vector2(minf(data.best.get(q.key, 0.0), q.goal), q.goal)
		"clears":
			var n := 0
			for h in q.heroes:
				if data.clears.get(h, 0.0) > 0.0:
					n += 1
			return Vector2(n, q.heroes.size())
		"quests":
			var n := 0
			for d in data.done:
				if d != q.id:
					n += 1
			return Vector2(mini(n, q.goal), q.goal)
	return Vector2(0, 1)

func reward_name(q: Dictionary) -> String:
	var r: Array = q.reward
	match r[0]:
		"hero": return "장수 " + String(HeroTable.HEROES[r[1]].name) if HeroTable.HEROES.has(r[1]) else "장수 " + r[1]
		"tactic": return "초식 " + String(TacticTable.LIST[r[1]].name) if TacticTable.LIST.has(r[1]) else "초식 " + r[1]
		"simbeop": return "심법 " + String(UpgradeTable.LIST[r[1]].name) if UpgradeTable.LIST.has(r[1]) else "심법 " + r[1]
		"slot": return "추가 초식 칸 +" + r[1]
	return "?"

func end_run(run: Dictionary) -> Array:
	## 판 결과를 누적하고 새로 깬 과제를 돌려줌. run: hero · kills · elite_kills · gems · lubu · cleared · nohit · camps · lowhp
	var t: Dictionary = data.total
	for k in ["kills", "elite_kills", "gems", "lubu"]:
		t[k] = t.get(k, 0.0) + float(run.get(k, 0))
	t.runs = t.get("runs", 0.0) + 1.0
	for k in ["nohit", "camps", "lowhp"]:
		data.best[k] = maxf(data.best.get(k, 0.0), float(run.get(k, 0)))
	if run.get("cleared", false):
		data.clears[run.hero] = data.clears.get(run.hero, 0.0) + 1.0
	var fresh := []
	var changed := true
	while changed:   # 과제 수 조건(백전노장)이 이어서 깨질 수 있어 다시 봄
		changed = false
		for q in UnlockTable.QUESTS:
			if q.id in data.done:
				continue
			var p := progress(q)
			if p.x >= p.y:
				data.done.append(q.id)
				fresh.append(q)
				changed = true
	save()
	return fresh
