class_name UpgradeTable
## 레벨업 고르기(D-283): 레벨이 오르면 아래에서 아직 최대가 아닌 것 3개를 골라 보여 줌.
## kind: weapon(대표 무기 — {w}는 무기 이름) · stat(능력치). only: 이 무기 type에서만 나옴.
## 효과는 main.gd _apply_upgrade가 key로 처리.

const LIST := {
	"w_dmg":    {"kind": "weapon", "name": "{w} 단련",     "desc": "무기 피해 +25%",        "max": 6},
	"w_spd":    {"kind": "weapon", "name": "{w} 속공",     "desc": "공격 속도 +15%",        "max": 6},
	"w_area":   {"kind": "weapon", "name": "{w} 큰 기세",  "desc": "공격 범위 +15%",        "max": 4},
	"w_count":  {"kind": "weapon", "name": "칼 한 자루 더", "desc": "한 번에 날리는 칼 +1",  "max": 3, "only": ["fly", "boomerang"]},
	"w_pierce": {"kind": "weapon", "name": "꿰뚫는 칼",     "desc": "칼이 꿰뚫는 수 +2",     "max": 3, "only": ["fly"]},
	"mu":       {"kind": "stat", "name": "무력",  "desc": "모든 공격 +10%",          "max": 5},
	"gap":      {"kind": "stat", "name": "갑옷",  "desc": "받는 피해 −8%",           "max": 5},
	"sin":      {"kind": "stat", "name": "신속",  "desc": "이동 속도 +8%",           "max": 5},
	"gun":      {"kind": "stat", "name": "군량",  "desc": "초당 체력 회복 +0.5",      "max": 5},
	"magnet":   {"kind": "stat", "name": "자석",  "desc": "구슬 줍는 거리 +35%",      "max": 4},
	"hp":       {"kind": "stat", "name": "강건",  "desc": "최대 체력 +20 · 20 회복",  "max": 5},
}
const HEAL := {"name": "고기만두", "desc": "체력 30 회복"}   # 고를 게 없을 때

static func need(level: int) -> int:
	## level → level+1에 필요한 구슬 수. 10레벨 누적 약 260 · 20레벨 약 1140 · 30레벨 약 2940.
	return int(4 + 3 * level + 0.15 * level * level)
