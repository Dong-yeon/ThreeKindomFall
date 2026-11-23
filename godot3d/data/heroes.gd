class_name HeroTable
## 장수 표(D-281 · D-285): 장수는 모델 + 무공 데이터만 바꿔 끼운다(CLAUDE.md "특정 장수 전용으로 짜지 않는다").
## weapon = 시작 초식(대표 무기) — 장수 고유(공용 추가 초식 풀에 없음). type: sweep 휘두르기(부채꼴) · thrust 찌르기(긴 직사각형, 꿰뚫음) · fly 날아가는 것(여럿, 꿰뚫음)
##   · boomerang 돌아오는 칼(scripts/weapon.gd).
##   공통: cd 재사용(초) · dmg 한 번 피해 · knock 밀려나는 거리 · seek 이 거리 안 가장 가까운 적을 노림(없으면 가는 쪽).
## D-285 무공 킷:
##   role 역할 태그 · stars 난이도(★) · star_label · passive 고유 심법(id로 main이 적용) · ult 절기 id(data/ults.gd)
##   qinggong 경공 — type dash(돌진: dist 거리 · time 걸리는 시간) | leap(도약: + height 높이) | blink(순간이동: dist, D-295)
##             · iframe 무적(초) · cd 한 번 충전 시간 · charges 최대 충전 · impact(돌진 중 부딪힌 적: r · dmg · knock, 없으면 안 밀침)
## stars(D-292): D-291 봇 측정 반영 — 장비 ★ · 관우 ★★ · 유비 ★★(다시 설계 뒤 다시 잼)
##   neigong 내공이 차는 배율(data/martial.gd의 기본값에 곱함) · hp 시작 최대 체력(없으면 100, D-291)

const ORDER := ["guan_yu", "zhuge_liang", "zhang_fei", "liu_bei"]   # 선택 화면 순서 — 처음 열린 장수가 앞(D-292, 잠금은 data/unlocks.gd)

const HEROES := {
	"guan_yu": {
		"name": "관우", "glb": "res://assets/models/guan_yu.glb",
		"role": "광역 · 묵직", "stars": 2, "star_label": "기본", "hp": 160.0,   # D-291: 버티는 수단(기절 · 의용군)이 없어 체력으로(140 → 160)
		"weapon": {"name": "청룡언월도 휩쓸기", "type": "sweep", "cd": 0.8, "dmg": 3.0, "knock": 1.3, "seek": 6.0,
			"range": 3.4, "arc": 200.0, "color": Color(0.85, 1.0, 0.9)},
		"passive": {"id": "wipung", "name": "위풍", "desc": "휩쓸기 범위 +15% · 밀어내기 +30%", "area": 1.15, "knock": 1.3},
		"ult": "crescent",
		"qinggong": {"type": "dash", "name": "돌진(짧고 무거움)", "dist": 3.0, "time": 0.18, "iframe": 0.25, "cd": 3.0, "charges": 1,
			"impact": {"r": 1.4, "dmg": 3.0, "knock": 2.2}},
		"neigong": 1.0,
	},
	"zhuge_liang": {   # D-295 — 원거리 마법사(시작 장수). 모델은 설정화 전 임시(tools/blender/zhuge_liang.py)
		"name": "제갈량", "glb": "res://assets/models/zhuge_liang.glb",
		"role": "원거리 · 책략", "stars": 2, "star_label": "붙으면 약함", "hp": 100.0,   # D-296: 80은 3:40~6:00에 쓰러짐
		"weapon": {"name": "학우선 바람날", "type": "fan", "cd": 0.9, "dmg": 2.4, "knock": 0.5, "seek": 11.0,
			"count": 3, "spread": 0.22, "speed": 16.0, "range": 9.0, "pierce": 4, "radius": 0.6, "falloff": 0.5,
			"color": Color(0.75, 0.9, 1.0)},
		"passive": {"id": "wolong", "name": "와룡", "desc": "추가 초식 칸 +1 · 책략 계열 초식 피해 +25%", "slots": 1, "strat": 1.25},
		"ult": "bagua",
		"qinggong": {"type": "blink", "name": "축지", "dist": 5.0, "iframe": 0.3, "cd": 3.0, "charges": 2},
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
		"role": "쌍검 · 난전", "stars": 2, "star_label": "대기만성",   # D-293: 의용군 누적형 → 쌍고검을 직접 쓰는 장수
		"weapon": {"name": "쌍고검 회선", "type": "boomerang", "cd": 1.1, "dmg": 2.0, "knock": 0.5, "seek": 9.0,
			"count": 2, "speed": 13.0, "range": 6.5, "radius": 0.75, "spread": 0.35, "color": Color(1.0, 0.92, 0.6)},
		"passive": {"id": "indeok", "name": "인덕", "desc": "둘레 4m 적이 많을수록 공격 속도 ↑(최대 +40%) · 근검: 초당 회복 +0.6",
			"r": 4.0, "full": 20, "haste": 0.4, "regen": 0.6},
		"ult": "militia",
		"qinggong": {"type": "leap", "name": "이단 도약", "dist": 4.0, "time": 0.45, "height": 1.6, "iframe": 0.45, "cd": 3.5, "charges": 2},
		"neigong": 1.0,
	},
}

static var chosen := ""   # 선택 화면에서 고른 장수(scenes/select.tscn → main.tscn, 자동 로드 없이 넘김)

static func get_hero(id: String) -> Dictionary:
	return HEROES.get(id, HEROES["guan_yu"])
