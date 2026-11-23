class_name WaveTable
## 한 판 시간표(D-282): 시각(초)마다 적 수 · 새로 나오는 적의 체력 · 속도. 사이는 선형으로 이음.
## 판 길이 RUN_TIME을 버티면 승리. FINAL_AT부터 '마지막 대군'(수 · 속도를 크게).
## 장수 무기 기본 피해는 3(data/heroes.gd) — 체력 3까지는 한 번, 4~6은 두 번, 7은 세 번.

const RUN_TIME := 600.0
const FINAL_AT := 540.0
# [초, 적 수, 체력, 속도(m/s)]
const ROWS := [
	[0.0,   20,  3.0, 2.1],
	[60.0,  80,  3.0, 2.2],
	[180.0, 200, 4.0, 2.35],
	[300.0, 320, 5.0, 2.5],
	[420.0, 450, 6.0, 2.6],
	[540.0, 600, 7.0, 2.7],
	[541.0, 800, 7.0, 3.0],
	[600.0, 900, 7.0, 3.1],
]

static func at(t: float) -> Array:
	## [적 수, 체력, 속도] — t초의 값.
	var rows := ROWS
	if t <= rows[0][0]:
		return [rows[0][1], rows[0][2], rows[0][3]]
	for k in range(1, rows.size()):
		if t <= rows[k][0]:
			var a: Array = rows[k - 1]
			var b: Array = rows[k]
			var f: float = (t - a[0]) / (b[0] - a[0])
			return [int(lerpf(a[1], b[1], f)), lerpf(a[2], b[2], f), lerpf(a[3], b[3], f)]
	var last: Array = rows[-1]
	return [last[1], last[2], last[3]]
