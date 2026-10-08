class_name HeroData
extends Resource
## 장수 데이터. 그림 · 능력치 · 기본 공격 · 특성 · 무쌍을 여기서 바꿔 끼운다(특정 장수 전용으로 짜지 않음).
## 장수별 특징 = 기본 공격 모양 + 특성 + 무쌍(D-171).

@export var id := "guan_yu"
@export var display_name := "관우"
## 깃발 글자(본진·점령한 진영).
@export var flag_glyph := "關"

@export_group("그림")
## assets/bb/<키>.png (tools/bb_export.py가 만듦).
@export var sprite_key := "gy"
## 그림 크기(웹판 sprAt size). 16×32 칸이 가로 0.8배 · 세로 1.6배로 그려진다.
@export var sprite_size := 30.0

@export_group("능력치")
@export var max_hp := 150.0
@export var attack := 10.0
## 걷는 속도(px/초). D-170: 말이 빠져 넓은 전장 이동을 어떻게 메울지는 검토 중 — 일단 웹판 걸음 그대로.
@export var move_speed := 150.0
@export var radius := 12.0
## 받는 피해 감소(0~1).
@export var damage_reduction := 0.0

@export_group("기본 공격(D-171: 대표 무기가 날아감)")
## 손에는 무기를 그리지 않는다. 날아가는 모양 · 빠르기 · 피해는 BasicAttack에.
@export var basic: BasicAttack
## 특성: 장수급(진영장 · 정원지 · 장각)에게 더 주는 피해(0.5 = +50%)
@export var lead_bonus := 0.0

@export_group("무쌍")
@export var musou_name := "무쌍 난무"
@export var musou_time := 2.3
@export var musou_tick := 0.16
@export var musou_radius := 120.0
@export var musou_mult := 2.2
@export var musou_blast_radius := 190.0
@export var musou_blast_mult := 7.0
## 무쌍 중 이동 속도 배율.
@export var musou_move_mul := 0.6
