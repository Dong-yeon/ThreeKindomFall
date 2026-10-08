class_name Units
## 적·아군 기본 수치(웹판 b_core.js EN · n_field.js AL). spr = assets/bb/<키>.png, c = 그림이 없을 때 동그라미 색.
## ai: chase(쫓아옴) · shooter(거리 두고 쏨) · dash(멈칫 → 돌진) · boss(장각: 탄막·소환·돌진)

const ENEMY := {
	"ytb": {"n": "황건 졸개", "c": "d8b040", "r": 10.0, "hp": 26.0, "spd": 74.0, "touch": 9.0, "ai": "chase", "spr": "ytb"},
	"ytarch": {"n": "황건 궁수", "c": "c89a30", "r": 11.0, "hp": 30.0, "spd": 40.0, "touch": 8.0, "ai": "shooter", "spr": "ytarch"},
	# 웹판 황건 기병(말 탄 적) 자리. D-170으로 말이 빠져 걸어서 돌진하는 병사로 바꿈 — 수치는 기병 그대로
	"ytdash": {"n": "황건 돌격병", "c": "a8782a", "r": 12.0, "hp": 30.0, "spd": 60.0, "touch": 11.0, "ai": "dash", "spr": "ytdash"},
	"ytbig": {"n": "황건 역사", "c": "e2b85a", "r": 15.0, "hp": 90.0, "spd": 34.0, "touch": 14.0, "ai": "chase", "spr": "ytbig"},
	"cyz": {"n": "황건 장수 정원지", "c": "d89a3a", "r": 18.0, "hp": 420.0, "spd": 46.0, "touch": 16.0, "ai": "shooter", "spr": "cyz"},
	"zj": {"n": "천공장군 장각", "c": "e2c060", "r": 30.0, "hp": 1500.0, "spd": 28.0, "touch": 18.0, "ai": "boss", "spr": "zj"},
	# 막사(D-180): 움직이지 않고 밀리지 않는 '적'. 공격 · 아군이 그대로 노림. 체력은 장마다 Stage의 BARRACKS.hp × 진영 mul(여기 hp는 1)
	"barracks": {"n": "황건 막사", "c": "c8a050", "r": 22.0, "hp": 1.0, "spd": 0.0, "touch": 0.0, "ai": "building", "spr": ""},
}

const ALLY := {
	"sol": {"n": "아군 창병", "c": "6a9ad8", "r": 10.0, "hp": 60.0, "atk": 9.0, "spd": 84.0, "cd": 0.8, "spr": "mil", "size": 24.0},
	"liubei": {"n": "유비", "c": "6a9ad8", "r": 12.0, "hp": 420.0, "atk": 20.0, "spd": 90.0, "cd": 0.6, "spr": "lb", "size": 28.0},
}
