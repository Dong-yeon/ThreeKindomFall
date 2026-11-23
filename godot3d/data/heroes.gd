class_name HeroTable
## 장수 표(D-281 · D-285): 장수는 모델 + 무공 데이터만 바꿔 끼운다(CLAUDE.md "특정 장수 전용으로 짜지 않는다").
## weapon = 시작 초식(대표 무기). type: sweep 휘두르기(부채꼴) · thrust 찌르기(긴 직사각형, 꿰뚫음) · fly 날아가는 것(여럿, 꿰뚫음).
##   공통: cd 재사용(초) · dmg 한 번 피해 · knock 밀려나는 거리 · seek 이 거리 안 가장 가까운 적을 노림(없으면 가는 쪽).
## D-285 무공 킷:
##   role 역할 태그 · stars 난이도(★) · star_label · passive 고유 심법(id로 main이 적용) · ult 절기 id(data/ults.gd)
##   qinggong 경공 — type dash(돌진: dist 거리 · time 걸리는 시간) | leap(도약: + height 높이)
##             · iframe 무적(초) · cd 한 번 충전 시간 · charges 최대 충전 · impact(돌진 중 부딪힌 적: r · dmg · knock, 없으면 안 밀침)
##   neigong 내공이 차는 배율(data/martial.gd의 기본값에 곱함)

const ORDER := ["zhang_fei", "guan_yu", "liu_bei"]   # 선택 화면 순서(쉬운 순)

const HEROES := {
	"guan_yu": {
		"name": "관우", "glb": "res://assets/models/guan_yu.glb",
		"role": "광역 · 묵직", "stars": 2, "star_label": "",
		"weapon": {"name": "청룡언월도 휩쓸기", "type": "sweep", "cd": 0.9, "dmg": 3.0, "knock": 1.3, "seek": 6.0,
			"range": 3.4, "arc": 160.0, "color": Color(0.85, 1.0, 0.9)},
		"passive": {"id": "wipung", "name": "위풍", "desc": "휩쓸기 범위 +15% · 밀어내기 +30%", "area": 1.15, "knock": 1.3},
		"ult": "crescent",
		"qinggong": {"type": "dash", "name": "돌진(짧고 무거움)", "dist": 3.0, "time": 0.18, "iframe": 0.25, "cd": 3.0, "charges": 1,
			"impact": {"r": 1.4, "dmg": 3.0, "knock": 2.2}},
		"neigong": 1.0,
	},
	"zhang_fei": {
		"name": "장비", "glb": "res://assets/models/zhang_fei.glb",
		"role": "탱커 · 광폭", "stars": 1, "star_label": "입문",
		"weapon": {"name": "장팔사모", "type": "thrust", "cd": 0.5, "dmg": 3.0, "knock": 1.1, "seek": 7.0,
			"range": 5.2, "width": 1.4, "color": Color(0.85, 0.9, 1.0)},
		"passive": {"id": "gwangpok", "name": "광폭", "desc": "체력이 낮을수록 공격력 ↑(최대 +80%)", "max": 0.8},
		"ult": "roar",
		"qinggong": {"type": "dash", "name": "돌격", "dist": 4.5, "time": 0.2, "iframe": 0.35, "cd": 2.5, "charges": 1},
		"neigong": 1.0,
	},
	"liu_bei": {
		"name": "유비", "glb": "res://assets/models/liu_bei.glb",
		"role": "소환 · 지원", "stars": 3, "star_label": "대기만성",
		"weapon": {"name": "쌍고검", "type": "fly", "cd": 0.65, "dmg": 1.7, "knock": 0.5, "seek": 12.0,
			"count": 1, "speed": 15.0, "range": 11.0, "pierce": 3, "radius": 0.6, "color": Color(1.0, 0.92, 0.6)},
		"passive": {"id": "indeok", "name": "인덕", "desc": "의용군 공격·체력 +20%(레벨마다 +16%) · 근검: 초당 회복 +0.6",
			"ally_mul": 1.2, "ally_per_lv": 0.16, "regen": 0.6},
		"ult": "militia",
		"qinggong": {"type": "leap", "name": "이단 도약", "dist": 4.0, "time": 0.45, "height": 1.6, "iframe": 0.45, "cd": 3.5, "charges": 2},
		"neigong": 1.0,
	},
}

static var chosen := ""   # 선택 화면에서 고른 장수(scenes/select.tscn → main.tscn, 자동 로드 없이 넘김)

static func get_hero(id: String) -> Dictionary:
	return HEROES.get(id, HEROES["guan_yu"])
