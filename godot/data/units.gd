class_name Units
## 적·아군 기본 수치(웹판 b_core.js EN · n_field.js AL). 적 빠르기(spd)는 웹판 × 1.3(D-184 — 웨이브 최대 +35%여도 장수 150보다 느림).
## spr = assets/bb/<키>.png, c = 그림이 없을 때 동그라미 색.
## ai: chase(쫓아옴) · shooter(거리 두고 쏨) · dash(멈칫 → 돌진) · boss(장각: 탄막·소환·돌진) · tower(수비탑) · altar(요술 제단).
## 진영장은 이 종류(ytbig · ytarch)로 낸 뒤 Enemy.make_lead가 lead(진영 안을 돌며 공격 하나)로 바꿈(D-205)

## 적이 장수에게 주는 피해 배율(닿기 · 탄 모두, D-188 — 더 어렵게)
const HURT_MUL := 1.5

const ENEMY := {
	"ytb": {"n": "황건 졸개", "c": "d8b040", "r": 10.0, "hp": 26.0, "spd": 96.0, "touch": 9.0, "ai": "chase", "spr": "ytb"},
	"ytarch": {"n": "황건 궁수", "c": "c89a30", "r": 11.0, "hp": 30.0, "spd": 52.0, "touch": 8.0, "ai": "shooter", "spr": "ytarch"},
	# 웹판 황건 기병(말 탄 적) 자리. D-170으로 말이 빠져 걸어서 돌진하는 병사로 바꿈 — 수치는 기병 그대로
	"ytdash": {"n": "황건 돌격병", "c": "a8782a", "r": 12.0, "hp": 30.0, "spd": 78.0, "touch": 11.0, "ai": "dash", "spr": "ytdash"},
	"ytbig": {"n": "황건 역사", "c": "e2b85a", "r": 15.0, "hp": 90.0, "spd": 44.0, "touch": 14.0, "ai": "chase", "spr": "ytbig"},
	"cyz": {"n": "황건 장수 정원지", "c": "d89a3a", "r": 18.0, "hp": 420.0, "spd": 60.0, "touch": 16.0, "ai": "shooter", "spr": "cyz"},
	"zj": {"n": "천공장군 장각", "c": "e2c060", "r": 30.0, "hp": 1500.0, "spd": 36.0, "touch": 18.0, "ai": "boss", "spr": "zj"},
	# 늑대 · 들개(D-209 — 동물 적, 그림은 에셋 전까지 동그라미): 늑대는 멈칫했다 덮치고, 들개는 빠르게 쫓음(장수 150보다는 느림)
	"wolf": {"n": "늑대", "c": "7a7a84", "r": 12.0, "hp": 55.0, "spd": 104.0, "touch": 11.0, "ai": "dash", "spr": ""},
	"dog": {"n": "들개", "c": "9a7448", "r": 9.0, "hp": 22.0, "spd": 128.0, "touch": 7.0, "ai": "chase", "spr": ""},
	# 수비탑(D-202): 움직이지 않고 밀리지 않는 '적'(건물)이고 장수에게 화살을 쏨. 체력은 장마다 Stage의 TOWER.hp × 진영 mul(여기 hp는 1)
	"tower": {"n": "황건 수비탑", "c": "a8743a", "r": 20.0, "hp": 1.0, "spd": 0.0, "touch": 0.0, "ai": "tower", "spr": ""},
	# 요술 제단(D-207): 움직이지 않고 공격하지 않는 건물. 남아 있는 동안 장각이 무적. 체력은 Stage의 ALTAR.hp(여기 hp는 1)
	"altar": {"n": "요술 제단", "c": "8a8478", "r": 18.0, "hp": 1.0, "spd": 0.0, "touch": 0.0, "ai": "altar", "spr": ""},
}

const ALLY := {
	"sol": {"n": "아군 창병", "c": "6a9ad8", "r": 10.0, "hp": 60.0, "atk": 9.0, "spd": 84.0, "cd": 0.8, "spr": "mil", "size": 24.0},
	"liubei": {"n": "유비", "c": "6a9ad8", "r": 12.0, "hp": 420.0, "atk": 20.0, "spd": 90.0, "cd": 0.6, "spr": "lb", "size": 28.0},
}
