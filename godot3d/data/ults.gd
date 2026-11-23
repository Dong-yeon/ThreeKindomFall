class_name UltTable
## 절기(D-285): 장수 고유 필살기. 각 절기는 scripts/martial/ult_*.gd 독립 모듈 — 시전 맥락(ctx)만 받으므로
## 나중에 다른 장수 판에서 '어시스트 호출'로 같은 절기를 부를 수 있음(ult_base.gd 참고).
## cost 내공 소모 · 나머지는 절기마다. evolve = 오의 진화: 재료 초식 2개(chosik) + 심법 1개(simbeop)를 갖추면
## 이름이 바뀌고 mul의 배율이 곱해짐. 재료 key는 레벨업 카드 key(data/upgrades.gd · "t:<책략 id>")와 필요한 횟수/레벨.

const LIST := {
	"crescent": {"name": "언월참", "script": "res://scripts/martial/ult_crescent.gd", "cost": 100.0,
		"base": {"dmg": 30.0, "knock": 2.5, "width": 2.6, "length": 15.0, "speed": 24.0, "count": 1, "fan": 0.35},
		"evolve": {"name": "청룡파천", "chosik": [["w_dmg", 3], ["t:orbit", 3]], "simbeop": ["mu", 2],
			"mul": {"dmg": 2.0, "width": 1.5, "count": 3}}},
	"roar": {"name": "사자후", "script": "res://scripts/martial/ult_roar.gd", "cost": 100.0,
		"base": {"dmg": 8.0, "knock": 5.0, "r": 6.0, "stun": 2.0, "time": 0.4},
		"evolve": {"name": "장판교 호령", "chosik": [["w_spd", 3], ["t:fire", 2]], "simbeop": ["gap", 2],
			"mul": {"dmg": 3.0, "r": 1.5, "stun": 1.5}}},
	"militia": {"name": "도원의 기치", "script": "res://scripts/martial/ult_militia.gd", "cost": 100.0,   # D-293: 누적 없이 기한부(life초)
		"base": {"add": 8, "max": 8, "life": 15.0, "hp": 60.0, "dmg": 2.0, "cd": 0.6, "reach": 1.7, "arc": 120.0, "speed": 4.8},
		"evolve": {"name": "도원의 맹세", "chosik": [["w_count", 2], ["t:rain", 2]], "simbeop": ["hp", 2],
			"mul": {"add": 1.5, "max": 1.5, "life": 1.334, "dmg": 2.0}}},
}

static func params(id: String, evolved: bool) -> Dictionary:
	var u: Dictionary = LIST[id]
	var p: Dictionary = u.base.duplicate()
	if evolved:
		for k in u.evolve.mul:
			p[k] = p[k] * u.evolve.mul[k]
	return p

static func display_name(id: String, evolved: bool) -> String:
	return LIST[id].evolve.name if evolved else LIST[id].name

static func make(id: String) -> Node3D:
	return load(LIST[id].script).new()
