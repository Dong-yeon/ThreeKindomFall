class_name BasicAttack
extends Resource
## 장수의 기본 공격(D-171): 무기를 손에 그리지 않고, 대표 무기가 날아가는 것이 기본 공격(자동).
## 가장 가까운 적 쪽으로 날리고, 맞힌 수만큼 연격 수가 쌓인다. 처음 맞힐 때 멈칫 · 흔들림, 맞은 졸개는 밀림.
## 모양: crescent(관우 · 반달 참격 관통) · spear(장비 · 일직선 창 관통, D-215). 유비 쌍검 부메랑은 모양을 더해 같은 틀로 만든다.

## 책략 카드에 보이는 이름 · 글자(기본 공격도 공격 칸 1칸을 차지하고 레벨업으로 올림, D-172)
@export var display_name := "반달 참격"
@export var glyph := "월"
## 날아가는 것의 모양. crescent = 앞으로 휜 반달(가운데가 두껍고 끝이 뾰족함) /
## spear = 날아가는 쪽으로 곧게 뻗은 창(좁고 길게 꿰뚫음 — width = 창 길이, thickness = 굵기, bulge는 안 씀)
@export_enum("crescent", "spear") var shape := "crescent"
## 다음 공격까지(초). 연격 단계마다 빨라짐(÷1.1 · ÷1.2)
@export var cooldown := 0.75
## 이 거리 안에 적이 있으면 날림(px)
@export var seek := 240.0
## 피해 = 장수 공격 × mult × 연격 단계 배율
@export var mult := 6.0
## 날아가는 빠르기(px/초) · 거리(px)
@export var speed := 330.0
@export var reach := 300.0
## 크기(px): 끝에서 끝 폭 · 가운데 두께 · 앞으로 휜 정도. 연격 단계마다 6%씩 커짐
@export var width := 104.0
@export var thickness := 18.0
@export var bulge := 26.0
## 꿰뚫는 수(-1 = 모두 꿰뚫음)
@export var pierce := -1
## 한 번에 날리는 수 · 사이 각(라디안)
@export var count := 1
@export var spread := 0.0
## 맞은 졸개를 날아가는 쪽으로 미는 거리(px). 장수급은 안 밀림
@export var push := 12.0
## 처음 맞힐 때 멈칫(초) · 흔들림
@export var hit_stop := 0.035
@export var shake := 0.05
## 색 [날, 테두리]. 투명이면 연격 단계 색(흰 → 초록 → 금)
@export var tint := Color(0, 0, 0, 0)
@export var tint2 := Color(0, 0, 0, 0)

@export_group("레벨(Lv1~5)")
## Lv2~5로 올릴 때 카드 설명
@export var level_desc: PackedStringArray = []
## 레벨별 피해 · 크기 · 재사용 배율, 더 날리는 수
@export var level_mult: PackedFloat32Array = []
@export var level_size: PackedFloat32Array = []
@export var level_cd: PackedFloat32Array = []
@export var level_extra: PackedInt32Array = []


func at_level(arr, lv: int, fallback):
	return arr[lv - 1] if lv >= 1 and lv <= arr.size() else fallback
