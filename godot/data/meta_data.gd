class_name MetaData
## 판 밖 성장 1단계(D-232, D-209 · D-213): 모든 장수가 공유하는 장수 레벨 · 전공(재화) · 재능 포인트. 저장은 `Save`(scripts/save.gd).
## 1장은 레벨 1로도 깰 수 있게 — 레벨당 보정은 작게(웹판 체력 +6% · 공격 +5%보다 작음). 재능 포인트를 쓰는 곳(재능 트리)은 다음 단계.

## 장수 레벨 Lv → Lv+1에 필요한 경험 = a + b·(Lv − 1)
const LV_NEED := {"a": 100.0, "b": 50.0}
## 장수 레벨 1당 출진 때 최대 체력 · 공격 배율(Lv1 = × 1), 재능 포인트
const PER_LV := {"hp": 0.03, "atk": 0.025, "pts": 1}
## 판 끝 보상: 경험 = 공적 Lv × xp_lv + 클리어 xp_clear / 전공 = 처치 × kill + 진영 · 부장 · 정원지 · 클리어. 진 판은 전공 × lose
## (경험은 공적 Lv에 비례해 진 판이 자연히 적음 — D-213 '진 판에서도 일부')
const REWARD := {"xp_lv": 4.0, "xp_clear": 60.0, "kill": 0.02, "camp": 20.0, "lead": 30.0, "cyz": 60.0, "clear": 100.0, "lose": 0.5}


## 출진할 수 있는 장수(D-236 장수 교체 — 군영 '장수 막사'에서 고름). 해금은 나중(지금은 둘 다 처음부터)
const HEROES := ["res://data/heroes/guan_yu.tres", "res://data/heroes/zhang_fei.tres"]


static func hero_path(id: String) -> String:
	for p in HEROES:
		if String(p).get_file().get_basename() == id:
			return p
	return String(HEROES[0])


## 대표 무기 강화(D-233, D-213 — 장수마다 따로, 전공): 강화 Lv 1당 그 장수 기본 공격 피해 + per(곱), 최대 max.
## 값(Lv → Lv+1) = cost_a + cost_b · Lv. 등급 이름은 grades의 [이 Lv부터, 이름] (모양은 그림 에셋 때 — 지금 날아가는 무기 색은 연격 단계를 보여 줌)
const WEAPON := {"per": 0.08, "max": 9, "cost_a": 300, "cost_b": 200, "grades": [[0, "쇠"], [3, "옥"], [6, "금"]]}


static func weapon_cost(lv: int) -> int:
	return int(WEAPON.cost_a) + int(WEAPON.cost_b) * lv


static func weapon_grade(lv: int) -> String:
	var g := ""
	for e in WEAPON.grades:
		if lv >= int(e[0]):
			g = String(e[1])
	return g


## 재능 트리(D-234, D-213 — 가지 넷 · 무료 되돌리기): 재능 포인트 1 = 1단계. 칸마다 tier(0 · 1 · 2) — tier 칸은 같은 가지의 더 낮은 tier 칸에
## TIER_NEED[tier]점 넘게 찍혀 있어야 열림. v = 1단계 값(효과 키 k로 Battle이 씀). 효과는 다음 출진부터.
const TIER_NEED := [0, 2, 4]
const TALENTS := [
	{"n": "무력", "nodes": [
		{"k": "atk", "n": "날카로운 날", "d": "공격 +%d%%", "v": 0.04, "max": 3, "tier": 0},
		{"k": "lead", "n": "장수 베기", "d": "장수급에게 기본 공격 피해 +%d%%", "v": 0.10, "max": 3, "tier": 1},
		{"k": "gauge", "n": "무쌍 기세", "d": "무쌍 게이지 +%d%%", "v": 0.10, "max": 3, "tier": 2}]},
	{"n": "생존", "nodes": [
		{"k": "hp", "n": "강골", "d": "최대 체력 +%d%%", "v": 0.06, "max": 3, "tier": 0},
		{"k": "heal", "n": "약초", "d": "받는 회복 +%d%%", "v": 0.15, "max": 3, "tier": 1},
		{"k": "grit", "n": "투지", "d": "체력 30%% 아래일 때 받는 피해 −%d%%", "v": 0.10, "max": 2, "tier": 2}]},
	{"n": "책략", "nodes": [
		{"k": "reroll", "n": "다시 생각", "d": "판마다 책략 다시 뽑기 %d번", "v": 1.0, "max": 3, "tier": 0, "int": true},
		{"k": "xp", "n": "학문", "d": "판 안 경험 +%d%%", "v": 0.05, "max": 3, "tier": 1},
		{"k": "plan", "n": "출진 전 계책", "d": "시작할 때 책략 고르기 %d번", "v": 1.0, "max": 1, "tier": 2, "int": true}]},
	{"n": "군세", "nodes": [
		{"k": "march", "n": "의용병", "d": "시작 진군 부대 +%d명", "v": 1.0, "max": 3, "tier": 0, "int": true},
		{"k": "ally", "n": "훈련", "d": "아군 공격 +%d%%", "v": 0.10, "max": 3, "tier": 1},
		{"k": "home", "n": "본진 성벽", "d": "본진 체력 +%d%%", "v": 0.15, "max": 2, "tier": 2}]},
]


## 재능 칸 하나의 설명(단계 r일 때 값)
static func talent_desc(node: Dictionary, r: int) -> String:
	var v := float(node.v) * r
	return String(node.d) % (roundi(v) if node.get("int", false) else roundi(v * 100))


static func need(lv: int) -> int:
	return roundi(float(LV_NEED.a) + float(LV_NEED.b) * (lv - 1))
