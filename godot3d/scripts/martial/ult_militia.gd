extends Ult
## 의용군 소환(유비 절기): 쓸 때마다 의용군 add명을 더함 — 판 끝까지 남고 최대 max명까지 누적(allies.gd).
## 오의 '도원의 맹세'는 한 번에 더 많이 · 최대 수 · 피해가 커짐.

var flag: MeshInstance3D
var added := 0

func _start() -> void:
	var o: Vector2 = ctx.origin
	if ctx.allies:
		added = ctx.allies.add(o, int(p.add), p)
	flag = MeshInstance3D.new()   # 깃발 기둥(잠깐)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08, 2.6, 0.08)
	flag.mesh = bm
	flag.material_override = _glow(Color(0.4, 0.85, 0.4, 0.9))
	flag.position = Vector3(o.x + 0.8, 1.3, o.y)
	add_child(flag)
	_burst(Vector3(o.x, 0.8, o.y), Color(0.5, 1.0, 0.5, 0.9), 40, 4.0)

func tick(delta: float) -> bool:
	t += delta
	(flag.material_override as StandardMaterial3D).albedo_color.a = 0.9 * clampf(1.0 - t / 1.2, 0.0, 1.0)
	return t >= 1.2
