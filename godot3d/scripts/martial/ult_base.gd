class_name Ult
extends Node3D
## 절기 공통(D-285) — 독립 모듈. 장수 노드나 main에 직접 기대지 않고 '시전 맥락' ctx 하나만 받음:
##   origin Vector2(XZ) · facing Vector2(단위) · horde(적 떼) · allies(의용군, 없으면 null) · atk_mul(공격 배율)
##   · evolved(오의인가) · spec(UltTable.params 결과) · level(시전자 레벨 — 레벨 따라 커지는 절기용, D-286)
## 그래서 나중에 '어시스트 호출'(다른 장수 판에서 이 절기를 부름)도 같은 모듈에 ctx만 만들어 넘기면 됨.
## 쓰는 쪽: var u := UltTable.make(id); parent.add_child(u); u.cast(ctx) → 매 프레임 u.tick(delta)가 true면 u.queue_free().

var ctx: Dictionary
var p: Dictionary
var t := 0.0
var hits := 0                 # 맞힌 적 수(점검용)

func cast(c: Dictionary) -> void:
	ctx = c
	p = c.spec
	_start()

func _start() -> void:
	pass

func tick(_delta: float) -> bool:
	return true

func _glow(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	return m

func _burst(at: Vector3, col: Color, amount := 40, spread := 3.0) -> void:
	## 한 번 터지는 파티클(기본 도형 효과 — Compatibility 렌더러라 CPUParticles3D).
	var ps := CPUParticles3D.new()
	ps.one_shot = true
	ps.amount = amount
	ps.lifetime = 0.6
	ps.explosiveness = 1.0
	ps.direction = Vector3.UP
	ps.spread = 80.0
	ps.initial_velocity_min = spread * 0.5
	ps.initial_velocity_max = spread
	ps.gravity = Vector3(0, -6, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.12)
	ps.mesh = bm
	ps.material_override = _glow(col)
	ps.position = at
	add_child(ps)
	ps.emitting = true
