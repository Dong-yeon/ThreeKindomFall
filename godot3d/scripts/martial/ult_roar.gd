extends Ult
## 사자후(장비 절기): 둘레 반지름 r 안의 적을 크게 밀치고 기절시킴(stun초). 퍼지는 고리.
## 오의 '장판교 호령'은 반지름 · 기절 · 피해가 커짐.

var ring: MeshInstance3D

func _start() -> void:
	var o: Vector2 = ctx.origin
	ctx.horde.stun_circle(o, p.r, p.stun)   # 기절이 먼저 — 밀친 뒤면 반지름 밖이라 안 걸림
	hits = ctx.horde.hit_circle(o, p.r, p.dmg * ctx.atk_mul, 0.0, Vector2.ZERO, 9999, o, ctx.horde.CH_ULT)
	ctx.horde.push_from(o, p.r, p.knock)
	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	tm.rings = 24
	tm.ring_segments = 6
	ring.mesh = tm
	ring.material_override = _glow(Color(1.0, 0.85, 0.4, 0.8))
	ring.position = Vector3(o.x, 0.3, o.y)
	add_child(ring)
	_burst(Vector3(o.x, 1.2, o.y), Color(1.0, 0.8, 0.3, 0.9), 50, 6.0)

func tick(delta: float) -> bool:
	t += delta
	var f := clampf(t / p.time, 0.0, 1.0)
	var s: float = lerpf(0.5, p.r, f)
	ring.scale = Vector3(s, 1.0, s)
	(ring.material_override as StandardMaterial3D).albedo_color.a = 0.8 * (1.0 - f)
	return t >= p.time + 0.3
