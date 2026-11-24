class_name FoeTable
## 적장(D-289 정예 · D-290 보스) — scripts/foe/foe.gd가 씀. 장수의 모든 공격은 horde.targets를 거쳐 적장도 맞힘.
##   hp 기본 체력(처음 맞을 때 시각에 따라 × (1 + t / hp_time)) · speed · radius 맞는 반지름 · scale 모델 크기
##   knock 밀려남 배율 · stun 기절 시간 배율(0이면 면역) · leash 지키는 자리에서 이 거리 밖으로는 안 쫓음(0이면 끝까지)
##   aggro 이 거리 안에 장수가 오면 싸움 · color 체력 막대 색
## patterns: 쓸 수 있는 공격(재사용 cd · 예고 wind초 동안 붉은 표시 → 실행). 피해 dmg는 시간표 찌르기 피해 비율(dmg_mul)이 곱해짐.
##   sweep  부채꼴(range · arc°)              charge 돌진(dist · speed · width)
##   circles 장수 발밑 근처 원 n개(r · spread)  ring 퍼지는 고리(r 최대 · speed · width)
##   summon 둘레로 잡병 n명 불러옴
## phase2: 체력이 at 비율 아래면 speed_mul · cd_mul · patterns 추가(보스).
## D-290 여포 맞춤: 체력 9000 · 휩쓸기 22 → 7500 · 12(시간표 피해 배율 ×2.7이 곱해져 한 번 58이던 것) — `--boss`로 잼.

const LIST := {
	"zhangbao": {"name": "장보", "glb": "res://assets/models/elite_zhangbao.glb", "hp": 700.0, "hp_time": 120.0,
		"speed": 2.6, "radius": 0.8, "scale": 1.4, "knock": 0.15, "stun": 0.4, "leash": 16.0, "aggro": 13.0, "color": Color("d84a3a"),
		"patterns": [
			{"type": "charge", "cd": 5.0, "wind": 0.8, "dmg": 18.0, "dist": 10.0, "speed": 16.0, "width": 1.4},
			{"type": "sweep", "cd": 3.0, "wind": 0.6, "dmg": 14.0, "range": 3.2, "arc": 150.0},
		]},
	"zhangliang": {"name": "장량", "glb": "res://assets/models/elite_zhangliang.glb", "hp": 850.0, "hp_time": 120.0,
		"speed": 2.3, "radius": 0.8, "scale": 1.4, "knock": 0.15, "stun": 0.4, "leash": 16.0, "aggro": 13.0, "color": Color("d8a83a"),
		"patterns": [
			{"type": "sweep", "cd": 3.5, "wind": 0.9, "dmg": 16.0, "range": 4.2, "arc": 220.0},
			{"type": "summon", "cd": 9.0, "wind": 0.6, "n": 10},
		]},
	"daoshi": {"name": "장각",   # D-329: 설정화(elite_zhangjiao.webp)대로 장각 — id는 그대로
		 "glb": "res://assets/models/elite_daoshi.glb", "hp": 600.0, "hp_time": 120.0,
		"speed": 2.0, "radius": 0.8, "scale": 1.4, "knock": 0.2, "stun": 0.5, "leash": 16.0, "aggro": 14.0, "color": Color("e8d080"),
		"patterns": [
			{"type": "circles", "cd": 3.2, "wind": 1.0, "dmg": 12.0, "n": 3, "r": 1.7, "spread": 2.5},
			{"type": "ring", "cd": 6.0, "wind": 0.8, "dmg": 10.0, "r": 9.0, "speed": 9.0, "width": 0.9},
		]},
	"lubu": {"name": "여포", "glb": "res://assets/models/lu_bu.glb", "hp": 7500.0, "hp_time": 0.0,   # D-310: scale 1.35 → 2.0(큰 머리 그림체에서 보스 느낌 — 맞는 반지름은 그대로)
		"speed": 3.2, "radius": 1.0, "scale": 2.0, "knock": 0.03, "stun": 0.0, "leash": 0.0, "aggro": 99.0, "color": Color("c82a2a"),
		"boss": true,
		"patterns": [
			{"type": "sweep", "cd": 2.8, "wind": 0.7, "dmg": 12.0, "range": 4.5, "arc": 200.0},
			{"type": "charge", "cd": 5.5, "wind": 0.9, "dmg": 13.5, "dist": 14.0, "speed": 20.0, "width": 1.8},
		],
		"phase2": {"at": 0.5, "speed_mul": 1.25, "cd_mul": 0.75,
			"patterns": [{"type": "ring", "cd": 7.0, "wind": 1.0, "dmg": 10.5, "r": 11.0, "speed": 10.0, "width": 1.0, "name": "패왕 진각"}]}},
}
