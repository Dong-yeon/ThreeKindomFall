extends Ult
## 쌍룡 회선(유비 절기, D-330): 시전 자리에서 사방으로 쌍고검 count자루를 한꺼번에 던짐 — 거리 range까지 날아가며
## 닿는 적을 모두 베고 시전 자리로 돌아오며 또 벰(기본 무기 '쌍고검 회선'의 큰 판). 칼 모양은 유비 쌍검 glb(없으면 막대).
## 오의 '쌍룡 난무': 칼 수 · 피해 · 크기 ↑. 의용군 소환(D-293 도원의 기치)을 대신함.

const SWORD_GLB := "res://assets/models/liu_bei_sword.glb"
var blades: Array = []        # [{node, pos, dir, left, back}]
var o: Vector2

func _start() -> void:
	o = ctx.origin
	var mesh: Mesh = null
	if ResourceLoader.exists(SWORD_GLB):
		var src: Node = load(SWORD_GLB).instantiate()
		for c in src.find_children("*", "MeshInstance3D", true, false):
			mesh = (c as MeshInstance3D).mesh
			break
		src.free()
	if mesh == null:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.26, 0.08, 1.7)
		mesh = bm
	var n := int(p.count)
	for k in n:
		var d := Vector2.from_angle(TAU * k / n)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.scale = Vector3.ONE * float(p.size)
		add_child(mi)
		blades.append({"node": mi, "pos": o, "dir": d, "left": float(p.range), "back": false})
	_burst(Vector3(o.x, 1.0, o.y), Color(1.0, 0.85, 0.4, 0.9), 40, 5.0)

func tick(delta: float) -> bool:
	t += delta
	for k in range(blades.size() - 1, -1, -1):
		var b: Dictionary = blades[k]
		var node: MeshInstance3D = b.node
		if not b.back:
			var step: float = p.speed * delta * lerpf(0.45, 1.0, clampf(b.left / p.range, 0.0, 1.0))
			b.pos += b.dir * step
			b.left -= step
			if b.left <= 0.0:
				b.back = true
		else:
			var to: Vector2 = o - b.pos
			var dl := to.length()
			var step2: float = p.speed * 1.25 * delta
			if dl <= maxf(step2, 0.5):
				node.queue_free()
				blades.remove_at(k)
				continue
			b.pos += to / dl * step2
		hits += ctx.horde.hit_circle(b.pos, p.radius, p.dmg * ctx.atk_mul, p.knock if not b.back else 0.0, b.dir, 99, o, ctx.horde.CH_ULT)
		node.position = Vector3(b.pos.x, 0.9, b.pos.y)
		node.rotation.y += delta * 18.0
	return blades.is_empty() and t > 0.3
