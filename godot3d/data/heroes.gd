class_name HeroTable
## 장수 표(D-281): 장수는 모델 + 무기 데이터만 바꿔 끼운다(CLAUDE.md "특정 장수 전용으로 짜지 않는다").
## 무기 type: sweep 휘두르기(부채꼴) · thrust 찌르기(긴 직사각형, 꿰뚫음) · fly 날아가는 것(여럿, 꿰뚫음).
## 공통: cd 재사용(초) · dmg 한 번 피해(적 체력 3 — 기본 무기는 졸병을 한 번에 벰) · knock 밀려나는 거리 · seek 이 거리 안 가장 가까운 적을 노림
##       (없으면 가는 쪽). 그 밖은 type마다.

const HEROES := {
	"guan_yu": {
		"name": "관우", "glb": "res://assets/models/guan_yu.glb",
		"weapon": {"name": "청룡언월도", "type": "sweep", "cd": 0.9, "dmg": 3.0, "knock": 1.3, "seek": 6.0,
			"range": 3.4, "arc": 160.0, "color": Color(0.85, 1.0, 0.9)},
	},
	"zhang_fei": {
		"name": "장비", "glb": "res://assets/models/zhang_fei.glb",
		"weapon": {"name": "장팔사모", "type": "thrust", "cd": 0.5, "dmg": 3.0, "knock": 1.1, "seek": 7.0,
			"range": 5.2, "width": 1.4, "color": Color(0.85, 0.9, 1.0)},
	},
	"liu_bei": {
		"name": "유비", "glb": "res://assets/models/liu_bei.glb",
		"weapon": {"name": "쌍고검", "type": "fly", "cd": 0.6, "dmg": 3.0, "knock": 0.5, "seek": 12.0,
			"count": 2, "speed": 15.0, "range": 11.0, "pierce": 4, "radius": 0.6, "color": Color(1.0, 0.92, 0.6)},
	},
}

static func get_hero(id: String) -> Dictionary:
	return HEROES.get(id, HEROES["guan_yu"])
