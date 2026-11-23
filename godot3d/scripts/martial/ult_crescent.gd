extends Ult
## 언월참(관우 절기): 바라보는 쪽으로 넓은 초승달 참격파가 날아가며 지나는 적을 모두 벰.
## 오의 '청룡파천'은 참격파 셋을 부채꼴로(count · fan).

var waves: Array = []         # [{pos: Vector2, dir: Vector2, left: float, node}]

func _start() -> void:
	var n := int(p.count)
	for k in n:
		var off: float = (k - (n - 1) * 0.5) * p.fan
		var d: Vector2 = (ctx.facing as Vector2).rotated(off)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(p.width, 0.08, 0.9)
		mi.mesh = bm
		mi.material_override = _glow(Color(0.7, 1.0, 0.85, 0.8))
		add_child(mi)
		waves.append({"pos": ctx.origin, "dir": d, "left": float(p.length), "node": mi})
	_burst(Vector3(ctx.origin.x, 1.0, ctx.origin.y), Color(0.7, 1.0, 0.85, 0.9), 30, 4.0)

func tick(delta: float) -> bool:
	t += delta
	for k in range(waves.size() - 1, -1, -1):
		var w: Dictionary = waves[k]
		var step: float = p.speed * delta
		# 이번 프레임에 지나간 구간(step 길이)을 직사각형으로 벰 — 맞음 대기(0.3초) 덕에 같은 적은 한 번
		hits += ctx.horde.hit_line(w.pos, w.dir, step + 0.6, p.width * 0.5, p.dmg * ctx.atk_mul, p.knock)
		w.pos += w.dir * step
		w.left -= step
		var node: MeshInstance3D = w.node
		node.position = Vector3(w.pos.x, 0.6, w.pos.y)
		node.rotation.y = atan2(w.dir.x, w.dir.y)
		(node.material_override as StandardMaterial3D).albedo_color.a = clampf(w.left / p.length, 0.2, 0.8)
		if w.left <= 0.0:
			node.queue_free()
			waves.remove_at(k)
	return waves.is_empty() and t > 0.7
