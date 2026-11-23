extends Ult
## 팔진도(제갈량 절기, D-295): 시전 자리에 반지름 r의 진을 dur초 펼침 — 진 안의 잡병은 느려지고(slow배, horde.slow_zones)
## 맞음 대기(0.3초)마다 피해. 진은 움직이지 않음(장수가 들어가 싸우는 자리).
## 오의 '동남풍 화공': 진 안이 불바다(피해 ×2.5 · 반지름 · 시간 ↑, 색이 불빛).

var disc: MeshInstance3D
var lines: Array[MeshInstance3D] = []
var o: Vector2

func _start() -> void:
	o = ctx.origin
	var col := Color(1.0, 0.55, 0.15, 0.32) if ctx.evolved else Color(0.45, 0.75, 1.0, 0.28)
	disc = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = p.r; cm.bottom_radius = p.r; cm.height = 0.04; cm.radial_segments = 8   # 팔각
	disc.mesh = cm
	disc.material_override = _glow(col)
	disc.position = Vector3(o.x, 0.04, o.y)
	add_child(disc)
	for k in 8:   # 팔괘 살(가운데에서 여덟 갈래)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.05, p.r)
		mi.mesh = bm
		mi.material_override = _glow(Color(col, 0.7))
		var a := TAU * k / 8.0
		mi.position = Vector3(o.x + sin(a) * p.r * 0.5, 0.06, o.y + cos(a) * p.r * 0.5)
		mi.rotation.y = a
		add_child(mi)
		lines.append(mi)
	_burst(Vector3(o.x, 0.8, o.y), Color(col, 0.9), 50, 5.0)

func tick(delta: float) -> bool:
	t += delta
	ctx.horde.slow_zones.append({"c": o, "r2": p.r * p.r, "f": p.slow})
	hits += ctx.horde.hit_circle(o, p.r, p.dmg * ctx.atk_mul, 0.0, Vector2.ZERO, 9999, o, ctx.horde.CH_ULT)
	var fade := clampf((p.dur - t) / 0.5, 0.0, 1.0)
	(disc.material_override as StandardMaterial3D).albedo_color.a = (0.32 if ctx.evolved else 0.28) * fade * (0.85 + 0.15 * sin(t * 8.0))
	for mi in lines:
		(mi.material_override as StandardMaterial3D).albedo_color.a = 0.7 * fade
	return t >= p.dur
