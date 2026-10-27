extends Node
## 저장(자동 로드 'Save', D-232): 판 밖 성장 — 공유 장수 레벨 · 경험 · 전공 · 재능 포인트 · 판 수 · 장수별 대표 무기 강화(D-233). user://save.json 한 파일(웹은 브라우저 저장소).
## 봇(--bot)은 읽지도 쓰지도 않음(판마다 같은 Lv1로 — 봇 지표가 저장에 따라 흔들리지 않게). 봇에 저장을 쓰려면 --save.

const PATH := "user://save.json"
const VER := 1

var on := true
var d := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	on = not ("--bot" in args) or "--save" in args
	d = _fresh()
	if on:
		_load()


func _fresh() -> Dictionary:
	return {"ver": VER, "lv": 1, "xp": 0, "merit": 0, "pts": 0, "runs": 0, "clears": 0, "weapon": {}}


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var got = JSON.parse_string(f.get_as_text())
	if got is Dictionary:
		for k in d:
			if not got.has(k):
				continue
			if d[k] is Dictionary:
				if got[k] is Dictionary:
					for h in got[k]:
						d[k][String(h)] = int(got[k][h])
			else:
				d[k] = int(got[k])


func write() -> void:
	if not on:
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("저장 실패: " + PATH)
		return
	f.store_string(JSON.stringify(d))


func lv() -> int:
	return int(d.lv)


## 출진 때 장수 최대 체력 · 공격 배율(MetaData.PER_LV)
func hp_mul() -> float:
	return 1.0 + float(MetaData.PER_LV.hp) * (lv() - 1)


func atk_mul() -> float:
	return 1.0 + float(MetaData.PER_LV.atk) * (lv() - 1)


## 대표 무기 강화(D-233): 장수 id별 강화 Lv · 기본 공격 피해 배율 · 강화(전공이 모자라거나 최대면 false)
func weapon_lv(id: String) -> int:
	return int(d.weapon.get(id, 0))


func weapon_mul(id: String) -> float:
	return 1.0 + float(MetaData.WEAPON.per) * weapon_lv(id)


func upgrade_weapon(id: String) -> bool:
	var lv := weapon_lv(id)
	if lv >= int(MetaData.WEAPON.max) or int(d.merit) < MetaData.weapon_cost(lv):
		return false
	d.merit = int(d.merit) - MetaData.weapon_cost(lv)
	d.weapon[id] = lv + 1
	write()
	return true


## 판 끝 보상을 더하고 저장. 돌려주는 것: {xp, merit, lv0, lv, pts(이번에 받은), xp_now, need}
func add_run(win: bool, plv: int, kills: int, camps: int, leads: int, cyz: bool) -> Dictionary:
	var R: Dictionary = MetaData.REWARD
	var xp := roundi(float(R.xp_lv) * plv + (float(R.xp_clear) if win else 0.0))
	var merit := float(R.kill) * kills + float(R.camp) * camps + float(R.lead) * leads + (float(R.cyz) if cyz else 0.0) + (float(R.clear) if win else 0.0)
	if not win:
		merit *= float(R.lose)
	var lv0 := lv()
	d.xp = int(d.xp) + xp
	d.merit = int(d.merit) + roundi(merit)
	var pts := 0
	while int(d.xp) >= MetaData.need(lv()):
		d.xp = int(d.xp) - MetaData.need(lv())
		d.lv = lv() + 1
		d.pts = int(d.pts) + int(MetaData.PER_LV.pts)
		pts += int(MetaData.PER_LV.pts)
	d.runs = int(d.runs) + 1
	if win:
		d.clears = int(d.clears) + 1
	write()
	return {"xp": xp, "merit": roundi(merit), "lv0": lv0, "lv": lv(), "pts": pts, "xp_now": int(d.xp), "need": MetaData.need(lv())}
