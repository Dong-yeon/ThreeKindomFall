class_name UltTable
## 절기(D-285): 장수 고유 필살기. 각 절기는 scripts/martial/ult_*.gd 독립 모듈 — 시전 맥락(ctx)만 받으므로
## 나중에 다른 장수 판에서 '어시스트 호출'로 같은 절기를 부를 수 있음(ult_base.gd 참고).
## cost 내공 소모 · 나머지는 절기마다. evolve = 오의 진화: 재료 초식 2개(chosik) + 심법 1개(simbeop)를 갖추면
## 이름이 바뀌고 add를 더한 뒤 mul의 배율이 곱해짐. 재료 key는 레벨업 카드 key(data/upgrades.gd · "t:<책략 id>")와 필요한 횟수/레벨.

const LIST := {
	"crescent": {"name": "언월참", "script": "res://scripts/martial/ult_crescent.gd", "cost": 100.0,
		"base": {"dmg": 30.0, "knock": 2.5, "width": 2.6, "length": 15.0, "speed": 24.0, "count": 1, "fan": 0.35},
		"evolve": {"name": "청룡파천", "chosik": [["w_dmg", 3], ["t:orbit", 3]], "simbeop": ["mu", 2],
			"mul": {"dmg": 2.0, "width": 1.5, "count": 3}}},
	"dragon": {"name": "청룡강림", "script": "res://scripts/martial/ult_dragon.gd", "cost": 100.0,   # D-332 관우: 하늘에서 청룡이 앞 직선으로 내리꽂혀 땅을 훑음
		"base": {"dmg": 34.0, "knock": 2.8, "width": 3.4, "length": 16.0, "speed": 26.0, "land_r": 3.4, "land_dmg": 20.0,
			"orbit_dur": 0.0, "orbit_r": 3.6, "orbit_dmg": 10.0, "orbit_spin": 1.6},
		# 오의 청룡파천: 내리꽂힌 청룡이 장수 둘레를 orbit_dur초 감아 돌며 닿는 적을 벰(재료는 언월참 때와 같음)
		"evolve": {"name": "청룡파천", "chosik": [["w_dmg", 3], ["t:orbit", 3]], "simbeop": ["mu", 2],
			"mul": {"dmg": 1.5, "land_dmg": 1.5}, "add": {"orbit_dur": 5.0}}},
	"roar": {"name": "사자후", "script": "res://scripts/martial/ult_roar.gd", "cost": 100.0,
		"base": {"dmg": 8.0, "knock": 5.0, "r": 6.0, "stun": 2.0, "time": 0.4},
		"evolve": {"name": "장판교 호령", "chosik": [["w_spd", 3], ["t:fire", 2]], "simbeop": ["gap", 2],
			"mul": {"dmg": 3.0, "r": 1.5, "stun": 1.5}}},
	"twin": {"name": "쌍룡 회선", "script": "res://scripts/martial/ult_twin.gd", "cost": 100.0,   # D-330: 의용군 소환(도원의 기치)을 대신 — 사방으로 쌍고검을 던져 갔다 돌아옴
		"base": {"count": 12, "dmg": 6.0, "knock": 1.2, "range": 7.0, "speed": 14.0, "radius": 0.9, "size": 1.3},
		"evolve": {"name": "쌍룡 난무", "chosik": [["w_count", 2], ["t:rain", 2]], "simbeop": ["hp", 2],
			"mul": {"count": 1.5, "dmg": 2.0, "radius": 1.3, "size": 1.25}}},
	"bagua": {"name": "팔진도", "script": "res://scripts/martial/ult_bagua.gd", "cost": 100.0,   # D-295 제갈량
		# D-333 날씨 덧씌움(ctx.weather): wind 진 안 적을 가운데로 pull(초당) · rain 감속 rain_slow배 · bolt 진 안에 bolt_cd초마다 bolt_n번 벼락(bolt_dmg)
		#   오의 동남풍: 천기를 진 시간 동안 바람에 묶고(불 계열 초식 피해 ↑) 펼칠 때 큰 바람이 둘레를 쓸어냄(gale_r · gale_push)
		"base": {"dmg": 3.0, "r": 6.0, "dur": 6.0, "slow": 0.4, "pull": 2.5, "rain_slow": 0.25, "bolt_cd": 0.5, "bolt_n": 2, "bolt_dmg": 8.0,
			"gale_r": 0.0, "gale_push": 4.0},
		"evolve": {"name": "동남풍", "add": {"gale_r": 14.0}, "chosik": [["w_count", 2], ["t:fire", 2]], "simbeop": ["mu", 2],
			"mul": {"dmg": 2.5, "r": 1.2, "dur": 1.3}}},
}

static func params(id: String, evolved: bool) -> Dictionary:
	var u: Dictionary = LIST[id]
	var p: Dictionary = u.base.duplicate()
	if evolved:
		for k in u.evolve.get("add", {}):   # 더하기(D-332 — 기본 0인 값을 오의에서만 켬)
			p[k] = p[k] + u.evolve.add[k]
		for k in u.evolve.mul:
			p[k] = p[k] * u.evolve.mul[k]
	return p

static func display_name(id: String, evolved: bool) -> String:
	return LIST[id].evolve.name if evolved else LIST[id].name

static func make(id: String) -> Node3D:
	return load(LIST[id].script).new()
