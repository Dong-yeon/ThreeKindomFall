class_name GearData
## 장비 · 우물(D-240, D-216 5 · 웹판 장비 화면의 갑옷 · 유물): 판에서 진영 · 장수급을 쓰러뜨리면 가끔 장비 꾸러미가 떨어짐 →
## 주우면 '짐'(판 안에선 효과 없음) → 본진 옆 우물에 닿으면 맡김 → 판이 끝나면 맡긴 것(이기면 짐도)을 군영 창고로. 지면 맡기지 않은 짐은 잃음.
## 창고에서 갑옷 1칸 · 유물 칸(장수 Lv에 따라 relic_slots)에 끼우면 다음 출진부터 효과. 모든 장수가 함께 씀. 이미 가진 걸 또 얻으면 전공 dup_merit.
## 효과 키는 재능(MetaData.TALENTS)과 같은 것(atk · hp · gauge · march · ally · xp)에 더해 dr(받는 피해 −) · spd(걸음 +) · cd(책략 재사용 −) · regen(초당 회복)

## 우물 자리(본진 오른쪽 위) · 닿는 거리
const WELL := {"pos": Vector2(540, 2830), "r": 50.0}
## 떨어질 확률: 진영 점령 · 대군 부장 · 현상금 두목 · 장 최종 보스(정원지 · 장보)
const DROP := {"camp": 0.25, "lead": 0.3, "bounty": 0.2, "boss": 1.0}
const DUP_MERIT := 150
## 유물 칸: [이 장수 Lv부터, 칸 수] (웹판 — Lv1 1칸 · Lv2 2칸 · Lv4 3칸)
const RELIC_SLOTS := [[1, 1], [2, 2], [4, 3]]

const ITEMS := {
	"iron": {"n": "철갑", "slot": "armor", "d": "최대 체력 +25% · 받는 피해 −10% · 걸음 −5%", "fx": {"hp": 0.25, "dr": 0.10, "spd": -0.05}},
	"dragon": {"n": "금룡포", "slot": "armor", "d": "공격 +10% · 무쌍 게이지 +20%", "fx": {"atk": 0.10, "gauge": 0.20}},
	"peach": {"n": "도원의 맹약", "slot": "relic", "d": "시작 진군 부대 +4명 · 아군 공격 +20%", "fx": {"march": 4.0, "ally": 0.20}},
	"sunzi": {"n": "손자병법", "slot": "relic", "d": "책략 재사용 −15%", "fx": {"cd": 0.15}},
	"tiger": {"n": "호랑이 부적", "slot": "relic", "d": "무쌍 게이지 +35%", "fx": {"gauge": 0.35}},
	"cart": {"n": "군량 수레", "slot": "relic", "d": "최대 체력 +20% · 초당 체력 +0.5", "fx": {"hp": 0.20, "regen": 0.5}},
	"saddle": {"n": "명마 안장", "slot": "relic", "d": "걸음 +12%", "fx": {"spd": 0.12}},
	"seal": {"n": "옥새 조각", "slot": "relic", "d": "판 안 경험 +25%", "fx": {"xp": 0.25}},
}


static func relic_slots(lv: int) -> int:
	var n := 0
	for e in RELIC_SLOTS:
		if lv >= int(e[0]):
			n = int(e[1])
	return n
