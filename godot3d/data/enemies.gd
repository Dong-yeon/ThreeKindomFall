class_name EnemyTable
## 황건 잡병 4종(D-288). horde.gd가 kind 번호로 씀. 배율은 시간표(data/waves.gd)의 체력 · 속도에 곱함.
##   hp 체력 배율 · speed 속도 배율 · knock 밀려남 배율(작을수록 버팀) · wind 찌르기 준비(초)
##   ranged(궁병): keep 이 거리 안팎을 유지 · shoot 쏘는 간격 · arrow_speed · arrow_life · arrow_r 맞는 반지름 · arrow_dmg 찌르기 피해 배율
## MIX: 시각(초)마다 4종 비율(졸병 · 궁병 · 돌격병 · 방패병) — 사이는 선형.

const KINDS := [
	{"id": "soldier", "name": "졸병",  "glb": "res://assets/models/yellow_turban_poses.glb", "hp": 1.0, "speed": 1.0, "knock": 1.0, "wind": 0.9},
	{"id": "archer",  "name": "궁병",  "glb": "res://assets/models/yt_archer_poses.glb", "hp": 0.8, "speed": 0.9, "knock": 1.0, "wind": 0.9,
		"ranged": {"keep": 8.0, "shoot": 2.5, "arrow_speed": 9.0, "arrow_life": 1.6, "arrow_r": 0.55, "arrow_dmg": 0.6}},
	{"id": "rusher",  "name": "돌격병", "glb": "res://assets/models/yt_rusher_poses.glb", "hp": 0.6, "speed": 1.6, "knock": 1.2, "wind": 0.7},
	{"id": "shield",  "name": "방패병", "glb": "res://assets/models/yt_shield_poses.glb", "hp": 2.0, "speed": 0.7, "knock": 0.3, "wind": 1.1},
]

const MIX := [
	[0.0,   [1.0, 0.0, 0.0, 0.0]],
	[120.0, [1.0, 0.0, 0.0, 0.0]],
	[240.0, [0.75, 0.1, 0.1, 0.05]],
	[420.0, [0.6, 0.15, 0.15, 0.1]],
	[540.0, [0.55, 0.15, 0.18, 0.12]],
]

static func mix_at(t: float) -> Array:
	if t <= MIX[0][0]:
		return MIX[0][1]
	for k in range(1, MIX.size()):
		if t <= MIX[k][0]:
			var a: Array = MIX[k - 1]
			var b: Array = MIX[k]
			var f: float = (t - a[0]) / (b[0] - a[0])
			var out := []
			for j in 4:
				out.append(lerpf(a[1][j], b[1][j], f))
			return out
	return MIX[-1][1]
