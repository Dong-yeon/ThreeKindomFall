extends Ult
## 팔진도(제갈량 절기, D-295): 시전 자리에 반지름 r의 진을 dur초 펼침 — 진 안의 잡병은 느려지고(slow배, horde.slow_zones)
## 맞음 대기(0.3초)마다 피해. 진은 움직이지 않음(장수가 들어가 싸우는 자리).
## 날씨 덧씌움(D-334, ctx.weather — 천기가 없으면 ""): 바람 진 안 적을 가운데로 끎 · 비 더 느려짐 · 번개 진 안에 벼락.
## 오의 '동남풍': 진 안이 불바다(피해 ↑ · 색이 불빛) + 펼칠 때 큰 바람이 둘레 gale_r를 쓸어냄(천기는 main이 바람에 묶음).

var disc: MeshInstance3D
var lines: Array[MeshInstance3D] = []
var o: Vector2
var wx := ""
var bolt_t := 0.0
var flashes: Array = []       # [{node, t}]

func _start() -> void:
	o = ctx.origin
	wx = "wind" if ctx.evolved and float(p.gale_r) > 0.0 else String(ctx.get("weather", ""))
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
	if float(p.gale_r) > 0.0:   # 동남풍: 큰 바람이 둘레를 쓸어냄
		ctx.horde.push_from(o, p.gale_r, p.gale_push)
		_burst(Vector3(o.x, 1.2, o.y), Color(0.8, 1.0, 0.85, 0.9), 70, 12.0)

func tick(delta: float) -> bool:
	t += delta
	var slow: float = p.rain_slow if wx == "rain" else p.slow
	ctx.horde.slow_zones.append({"c": o, "r2": p.r * p.r, "f": slow})
	hits += ctx.horde.hit_circle(o, p.r, p.dmg * ctx.atk_mul, 0.0, Vector2.ZERO, 9999, o, ctx.horde.CH_ULT)
	match wx:
		"wind":   # 가운데로 끎(밀침을 거꾸로)
			ctx.horde.push_from(o, p.r, -p.pull * delta)
		"bolt":
			bolt_t -= delta
			if bolt_t <= 0.0:
				bolt_t = p.bolt_cd
				for tp in ctx.horde.random_in(o, p.r, int(p.bolt_n)):
					hits += ctx.horde.hit_circle(tp, 1.2, p.bolt_dmg * ctx.atk_mul, 0.3, Vector2.ZERO, 999, o, ctx.horde.CH_PASSIVE)
					_bolt(tp)
	for k in range(flashes.size() - 1, -1, -1):
		flashes[k].t -= delta
		if flashes[k].t <= 0.0:
			flashes[k].node.queue_free()
			flashes.remove_at(k)
	var fade := clampf((p.dur - t) / 0.5, 0.0, 1.0)
	(disc.material_override as StandardMaterial3D).albedo_color.a = (0.32 if ctx.evolved else 0.28) * fade * (0.85 + 0.15 * sin(t * 8.0))
	for mi in lines:
		(mi.material_override as StandardMaterial3D).albedo_color.a = 0.7 * fade
	return t >= p.dur

func _bolt(tp: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 6.0, 0.15)
	mi.mesh = bm
	mi.material_override = _glow(Color(1.0, 0.95, 0.55, 0.9))
	mi.position = Vector3(tp.x, 3.0, tp.y)
	add_child(mi)
	flashes.append({"node": mi, "t": 0.15})
