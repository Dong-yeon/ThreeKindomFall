class_name TacticTable
## 책략(D-284): 대표 무기 말고 레벨업으로 얻는 두 번째 무기들. 2D판 책략(godot/data/tactics_data.gd) 중 모양이 다른 넷부터.
## base = 1레벨 수치, up = 레벨이 하나 오를 때마다 더하는 값(최대 MAX_LV). 판정은 horde.gd, 동작은 scripts/tactic.gd.
##   orbit 회전 언월 — 장수 둘레를 도는 칼날(blades 개 · 반지름 r · 초당 spin rad · 칼날 크기 size)
##   rain  화살 비  — cd마다 가까운 적 count곳에 표시 → delay초 뒤 반지름 r 안 피해
##   fire  화계    — cd마다 가까운 적 count곳에 불(반지름 r · dur초 동안 맞음 대기 0.3초마다 피해)
##   bolt  낙뢰    — cd마다 이 거리 안 아무 적 count명에게 곧바로(반지름 r)
##   xbow  연노    — cd마다 가까운 적 쪽 부채꼴(spread rad)로 화살 count발(속도 speed · 거리 range · 꿰뚫음 pierce · 반지름 r) (D-294)
##   knives 비도   — cd마다 가까운 적 count명에게 칼 하나씩(모자라면 사방으로), 한 발 약함 · 꿰뚫음 pierce
##   drum  전고 오라 — cd마다 장수 둘레 반지름 r에 북 고리 피해 + push만큼 바깥으로 밀침
##   flamestep 적토 화보 — 걸은 거리 step마다 발밑에 불(반지름 r · dur초, 화계와 같은 판정)
## 공통: dmg 피해(무력 배율이 곱해짐) · knock 밀려남. chain(낙뢰, D-294) 맞은 자리에서 가까운 적에게 더 튀는 수(0이면 없음).
## strat = 책략 계열(제갈량 '와룡'이 피해를 올림, D-295). 해금 여부는 data/unlocks.gd(보상으로 걸린 것만 잠김).
## D-284 맞춤: 첫 수치(화살 비 5레벨 한 번 14 등)는 5분대 적 체력 22~26에 약해 책략을 많이 고른 판이 6분 전에 쓰러짐 → 피해를 올림.

const MAX_LV := 5
const MAX_SLOTS := 3

const LIST := {
	"orbit": {"name": "회전 언월", "desc": "장수 둘레를 칼날이 돈다", "type": "orbit",
		"base": {"dmg": 2.5, "knock": 0.6, "blades": 2, "r": 2.2, "spin": 3.5, "size": 0.5},
		"up":   {"dmg": 1.8, "blades": 1, "r": 0.15, "spin": 0.3}},
	"rain": {"name": "화살 비", "desc": "적 무리 위로 화살이 쏟아진다", "type": "rain", "strat": true,
		"base": {"dmg": 5.0, "knock": 0.3, "cd": 2.2, "count": 2, "r": 1.8, "delay": 0.45, "seek": 11.0},
		"up":   {"dmg": 4.0, "count": 1, "r": 0.15, "cd": -0.15}},
	"fire": {"name": "화계", "desc": "불을 놓아 몇 초 동안 태운다", "type": "fire", "strat": true,
		"base": {"dmg": 2.0, "knock": 0.0, "cd": 3.0, "count": 1, "r": 2.0, "dur": 3.0, "seek": 9.0},
		"up":   {"dmg": 1.4, "count": 1, "r": 0.2, "dur": 0.4}},
	"bolt": {"name": "낙뢰", "desc": "멀리 있는 적에게 벼락이 떨어진다", "type": "bolt",
		"base": {"dmg": 10.0, "knock": 0.5, "cd": 1.6, "count": 1, "r": 1.0, "seek": 13.0, "chain": 0},
		"up":   {"dmg": 8.0, "count": 1, "cd": -0.1}, "chain_from": 4, "strat": true},   # 4레벨부터 1번 · 5레벨 2번 튐
	"xbow": {"name": "연노", "desc": "보는 쪽으로 화살을 부채꼴로 쏜다", "type": "xbow",
		"base": {"dmg": 3.0, "knock": 0.4, "cd": 1.4, "count": 3, "spread": 0.18, "speed": 22.0, "range": 13.0, "pierce": 2, "r": 0.5, "seek": 12.0},
		"up":   {"dmg": 1.8, "count": 1, "pierce": 1, "cd": -0.08}},
	"knives": {"name": "비도", "desc": "가까운 적 여럿에게 칼을 던진다", "type": "knives",
		"base": {"dmg": 2.2, "knock": 0.2, "cd": 1.0, "count": 4, "speed": 18.0, "range": 10.0, "pierce": 1, "r": 0.45, "seek": 10.0},
		"up":   {"dmg": 1.2, "count": 2, "cd": -0.05}},
	"drum": {"name": "전고 오라", "desc": "북소리가 둘레의 적을 치고 밀어낸다", "type": "drum",
		"base": {"dmg": 3.0, "knock": 0.0, "cd": 1.2, "r": 2.6, "push": 0.6},
		"up":   {"dmg": 2.2, "r": 0.3, "cd": -0.1, "push": 0.1}},
	"flamestep": {"name": "적토 화보", "desc": "지나간 자리에 불길이 남는다", "type": "flamestep",
		"base": {"dmg": 2.0, "knock": 0.0, "step": 1.6, "r": 1.0, "dur": 2.0},
		"up":   {"dmg": 1.5, "r": 0.12, "dur": 0.4, "step": -0.15}, "strat": true},
}

static func params(id: String, lv: int) -> Dictionary:
	var t: Dictionary = LIST[id]
	var p: Dictionary = t.base.duplicate()
	for k in t.up:
		p[k] = p.get(k, 0) + t.up[k] * (lv - 1)
	if t.has("chain_from"):
		p.chain = maxi(lv - int(t.chain_from) + 1, 0)
	return p
