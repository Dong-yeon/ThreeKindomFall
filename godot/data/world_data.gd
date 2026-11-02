class_name WorldData
## 천하 지도 최소판(D-235, current-design 2장): 걸어 다니는 허브. 아래 유비군 군영(대장간 · 군막 · 장수 막사 D-236) → 가운데 1장 모형 → 강 건너 2장(안개).
## 그림은 임시(코드로 그림) — 바닥 · 건물은 B.B.Bits 타일셋이 들어오면 바꿈. 웹판 p_world.js의 13주 지도는 장이 늘어날 때.

const SIZE := Vector2(720, 1400)
const START := Vector2(360, 1315)
## 강(황하) — 띠 y0~y1, 나루(다리)는 x 가운데 bridge 폭
const RIVER := {"y0": 560.0, "y1": 620.0, "bridge": 90.0}
## 안개: 1장을 clears번 깨기 전엔 강 건너(y < fog_y)로 못 감
const FOG := {"y": 640.0, "clears": 1}
## 장소: k(하는 일) · 이름 · 아랫줄 · 자리 · 닿는 거리 r · 표지 글자. need_ch = 그 장을 깨야 열림(D-241)
const PLACES := [
	{"k": "forge", "n": "대장간", "sub": "대표 무기 강화 — 전공", "pos": Vector2(210, 1170), "r": 70.0, "glyph": "대"},
	{"k": "tent", "n": "군막", "sub": "재능 — 재능 포인트", "pos": Vector2(510, 1170), "r": 70.0, "glyph": "막"},
	{"k": "hero", "n": "장수 막사", "sub": "출진할 장수 고르기", "pos": Vector2(360, 1245), "r": 50.0, "glyph": "장"},
	{"k": "gear", "n": "창고", "sub": "장비 끼우기 — 우물에 맡긴 장비", "pos": Vector2(540, 1290), "r": 45.0, "glyph": "창"},
	{"k": "stage1", "n": "1장 탁현 싸움", "sub": "황건적의 난 — 출진", "pos": Vector2(360, 820), "r": 80.0, "glyph": "1"},
	{"k": "stage2", "n": "2장 장보의 요술", "sub": "요술 제단 · 장보 — 출진", "pos": Vector2(360, 340), "r": 80.0, "glyph": "2", "need_ch": 1},
	{"k": "stage3", "n": "3장 광종 결전", "sub": "장량 · 장각 · 청룡 — 출진", "pos": Vector2(360, 110), "r": 80.0, "glyph": "3", "need_ch": 2},
]
