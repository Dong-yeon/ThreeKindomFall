class_name StageYellow
## 황건적 토벌 스테이지(D-289): 맵 경계 · 진영 3곳 · 보상. scripts/stage.gd가 씀.
## 진영: 살아 있으면 잡병 생성의 CAMP_SHARE를 그 진영에서 내보냄. 지키는 정예(data/foes.gd)를 쓰러뜨리면 깨짐 →
##       그 진영 생성이 멈추고 보상 상자(밟으면 레벨업 카드 1번 + 체력 CHEST_HEAL).

const BOUNDS := Rect2(-70, -70, 140, 140)
const CAMP_SHARE := 0.3
const CHEST_HEAL := 30.0
const CAMPS := [
	{"id": "zhangbao",   "name": "장보의 진",  "pos": Vector2(-38, -30), "r": 7.0, "foe": "zhangbao"},
	{"id": "zhangliang", "name": "장량의 진",  "pos": Vector2(40, -18),  "r": 7.0, "foe": "zhangliang"},
	{"id": "daoshi",     "name": "황건 제단",  "pos": Vector2(-4, 46),   "r": 7.0, "foe": "daoshi"},
]
