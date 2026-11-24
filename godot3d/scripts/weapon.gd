extends Node3D
## 장수의 대표 무기(D-281): 자동으로 가장 가까운 적을 노려 공격. 모양 · 수치는 data/heroes.gd의 weapon.
##   sweep  휘두르기 — 부채꼴(반지름 range · 각도 arc°)을 한 번에 벰, 바깥으로 밀어냄
##   thrust 찌르기   — 길이 range · 폭 width 직사각형, 줄에 선 적 모두 꿰뚫음, 찌른 방향으로 밀어냄
##   fly    날아가기 — 가까운 적 count명에게 하나씩 날림(속도 speed · 거리 range · 꿰뚫음 pierce)
##   fan    바람 칼날(D-295 제갈량 학우선) — 가까운 적 쪽 부채꼴(spread rad)로 count개, 꿰뚫음 pierce, 멀어질수록 약해짐(falloff)
##   boomerang 돌아오는 칼(D-293 유비 쌍고검 회선) — 가까운 적 쪽으로 count자루를 부채꼴(spread rad)로 던짐,
##          거리 range까지 날아가며 닿는 적을 모두 베고(꿰뚫음 제한 없음) 장수에게 돌아오며 또 벰(돌아오는 길은 맞음 대기 채널이 따로)
## 판정은 horde.gd(hit_arc · hit_line · hit_circle), 여기는 노리기 · 때 · 보이는 것만.

const FX_T := 0.18            # 휘두르기 · 찌르기 효과가 보이는 시간

var spec: Dictionary
var player: Node3D
var horde: Node3D
var cd := 0.3
var fx: MeshInstance3D        # 휘두르기 · 찌르기 효과(하나를 다시 씀)
var fx_mat: StandardMaterial3D
var fx_t := 0.0
var shots: Array = []         # fly: [{node, pos: Vector2, dir: Vector2, left: float, pierce: int}]
var fly_mesh: Mesh
var fly_mat: StandardMaterial3D
var attacks := 0
# 레벨업으로 붙는 배율 · 더하기(D-283) — 실제 값은 아래 함수로 읽음
var mods := {"dmg": 1.0, "cd": 1.0, "area": 1.0, "count": 0, "pierce": 0, "knock": 1.0}
var dyn := 1.0               # 매 프레임 바뀌는 공격 배율(주화입마 · 광폭 — main이 넣음, D-285)
var haste := 1.0             # 매 프레임 바뀌는 공격 속도 배율(인덕 — main이 넣음, D-293)
var blades: Array = []       # boomerang: [{node, pos, dir, left, back}]
var fans: Array = []         # fan: [{node, pos, dir, left, pierce}] — 바람 칼날(D-295)
var returns := 0             # 돌아오는 길에 맞힌 수(--stats)
var outs := 0                # 가는 길에 맞힌 수

func dmg() -> float: return spec.dmg * mods.dmg * dyn
func knock() -> float: return spec.knock * mods.knock
func cooldown() -> float: return spec.cd * mods.cd / haste
func reach() -> float: return spec.range * mods.area
func width() -> float: return spec.get("width", 0.0) * sqrt(mods.area)   # 찌르기 폭은 범위 강화의 절반 비율(제곱근) — 길이는 그대로 다 늚(D-283: 폭까지 다 늘면 앞을 다 쓸어 너무 셈 · 고정하면 너무 약함)
func fly_radius() -> float: return spec.get("radius", 0.0) * mods.area
func fly_count() -> int: return int(spec.get("count", 1)) + int(mods.count)   # boomerang도 같음(칼 수)
func fly_pierce() -> int: return int(spec.get("pierce", 1)) + int(mods.pierce)

func refresh_fx() -> void:
	## 범위가 바뀌면 효과 모양도 다시.
	match spec.type:
		"sweep":
			fx.mesh = _arc_mesh(0.7, reach(), deg_to_rad(spec.arc))
		"thrust":
			(fx.mesh as BoxMesh).size = Vector3(width() * 0.6, 0.05, reach())

func setup(weapon_spec: Dictionary, p: Node3D, h: Node3D) -> void:
	spec = weapon_spec
	player = p
	horde = h
	var col: Color = spec.get("color", Color.WHITE)
	fx_mat = StandardMaterial3D.new()
	fx_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fx_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fx_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fx_mat.albedo_color = Color(col, 0.0)
	match spec.type:
		"sweep":
			fx = MeshInstance3D.new()
			fx.mesh = _arc_mesh(0.7, reach(), deg_to_rad(spec.arc))
		"thrust":
			fx = MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(width() * 0.6, 0.05, reach())
			fx.mesh = bm
		"fan":
			var fm := PrismMesh.new()        # 초승달 대신 납작한 세모 칼날(바람)
			fm.size = Vector3(1.7, 0.9, 0.1)   # D-308 큰 머리 그림체: 보이는 크기만 키움(판정 반지름은 그대로)
			fly_mesh = fm
			fly_mat = StandardMaterial3D.new()
			fly_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			fly_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			fly_mat.albedo_color = Color(col, 0.75)
		"fly", "boomerang":
			var sw := BoxMesh.new()          # 날아가는 칼(납작한 막대) · 돌아오는 칼은 눕혀서 빙빙 돎
			sw.size = Vector3(0.27, 0.08, 1.5) if spec.type == "fly" else Vector3(0.26, 0.08, 1.7)   # D-308: 보이는 크기 ×1.5
			fly_mesh = sw
			fly_mat = StandardMaterial3D.new()
			fly_mat.albedo_color = Color("d8dce0")
			fly_mat.metallic = 0.7
			fly_mat.emission_enabled = true
			fly_mat.emission = col * 0.4
	if fx:
		fx.material_override = fx_mat
		fx.visible = false
		add_child(fx)

func _arc_mesh(r_in: float, r_out: float, arc: float) -> ArrayMesh:
	## 바닥에 눕힌 부채꼴 띠(+Z 방향이 가운데). 휘두르기 효과용.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 14
	for k in seg:
		var a0 := -arc * 0.5 + arc * k / seg
		var a1 := -arc * 0.5 + arc * (k + 1) / seg
		var p0i := Vector3(sin(a0) * r_in, 0, cos(a0) * r_in)
		var p0o := Vector3(sin(a0) * r_out, 0, cos(a0) * r_out)
		var p1i := Vector3(sin(a1) * r_in, 0, cos(a1) * r_in)
		var p1o := Vector3(sin(a1) * r_out, 0, cos(a1) * r_out)
		for v in [p0i, p0o, p1o, p0i, p1o, p1i]:
			st.add_vertex(v)
	return st.commit()

func _aim(center: Vector2, n := 1) -> Array:
	## 노릴 방향(단위 Vector2) n개: 가까운 적 순, 모자라면 장수가 보는 쪽.
	var out := []
	for t in horde.nearest(center, spec.seek, n):
		var d: Vector2 = t - center
		if d.length() > 0.01:
			out.append(d.normalized())
	var facing := Vector2(sin(player.rotation.y), cos(player.rotation.y))
	while out.size() < n:
		out.append(facing.rotated(0.4 * out.size()))
	return out

func tick(delta: float) -> void:
	var c := Vector2(player.position.x, player.position.z)
	cd -= delta
	if cd <= 0.0:
		cd = cooldown()
		attacks += 1
		match spec.type:
			"sweep":
				var d: Vector2 = _aim(c)[0]
				horde.hit_arc(c, atan2(d.y, d.x), deg_to_rad(spec.arc) * 0.5, reach(), dmg(), knock())
				_show_fx(d, 0.0)
			"thrust":
				var d: Vector2 = _aim(c)[0]
				horde.hit_line(c, d, reach(), width() * 0.5, dmg(), knock())
				_show_fx(d, reach() * 0.5)
			"fly":
				for d in _aim(c, fly_count()):
					var n := MeshInstance3D.new()
					n.mesh = fly_mesh
					n.material_override = fly_mat
					add_child(n)
					shots.append({"node": n, "pos": c, "dir": d, "left": reach(), "pierce": fly_pierce()})
			"fan":
				var d0: Vector2 = _aim(c)[0]
				var n_f := fly_count()
				for k in n_f:
					var d := d0.rotated(spec.spread * (k - (n_f - 1) * 0.5))
					var n := MeshInstance3D.new()
					n.mesh = fly_mesh
					n.material_override = fly_mat
					add_child(n)
					fans.append({"node": n, "pos": c, "dir": d, "left": reach(), "pierce": fly_pierce()})
			"boomerang":
				var d0: Vector2 = _aim(c)[0]
				var n_b := fly_count()
				for k in n_b:   # 가장 가까운 적 쪽을 가운데로 부채꼴
					var d := d0.rotated(spec.spread * (k - (n_b - 1) * 0.5))
					var n := MeshInstance3D.new()
					n.mesh = fly_mesh
					n.material_override = fly_mat
					add_child(n)
					blades.append({"node": n, "pos": c, "dir": d, "left": reach(), "back": false, "life": 4.0})
	# 효과 흐려지기
	if fx and fx.visible:
		fx_t -= delta
		fx_mat.albedo_color.a = clampf(fx_t / FX_T, 0.0, 1.0) * 0.7
		if fx_t <= 0.0:
			fx.visible = false
	# 날아가는 칼
	for k in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[k]
		var step: float = spec.speed * delta
		s.pos += s.dir * step
		s.left -= step
		s.pierce -= horde.hit_circle(s.pos, fly_radius(), dmg(), knock(), s.dir, s.pierce, c)
		var node: MeshInstance3D = s.node
		node.position = Vector3(s.pos.x, 0.9, s.pos.y)
		node.rotation.y = atan2(s.dir.x, s.dir.y)
		if s.left <= 0.0 or s.pierce <= 0:
			node.queue_free()
			shots.remove_at(k)

	# 바람 칼날(D-295): 멀어질수록 약해짐(끝에서 falloff배)
	for k in range(fans.size() - 1, -1, -1):
		var s: Dictionary = fans[k]
		var step: float = spec.speed * delta
		s.pos += s.dir * step
		s.left -= step
		var f: float = lerpf(spec.falloff, 1.0, clampf(s.left / reach(), 0.0, 1.0))
		s.pierce -= horde.hit_circle(s.pos, fly_radius(), dmg() * f, knock(), s.dir, s.pierce, c)
		var node: MeshInstance3D = s.node
		node.position = Vector3(s.pos.x, 0.8, s.pos.y)
		node.rotation = Vector3(-PI * 0.5, atan2(s.dir.x, s.dir.y), 0)
		if s.left <= 0.0 or s.pierce <= 0:
			node.queue_free()
			fans.remove_at(k)
	# 돌아오는 칼(D-293): 나갈 땐 감속, 돌아올 땐 장수 쪽으로 가속
	for k in range(blades.size() - 1, -1, -1):
		var b: Dictionary = blades[k]
		b.life -= delta
		var node: MeshInstance3D = b.node
		if not b.back:
			var step: float = spec.speed * delta * lerpf(0.45, 1.0, clampf(b.left / reach(), 0.0, 1.0))
			b.pos += b.dir * step
			b.left -= step
			outs += horde.hit_circle(b.pos, fly_radius(), dmg(), knock(), b.dir, 99, c, horde.CH_WEAPON)
			if b.left <= 0.0:
				b.back = true
		else:
			var to: Vector2 = c - b.pos
			var dl := to.length()
			var step: float = spec.speed * 1.25 * delta
			if dl <= maxf(step, 0.6) or b.life <= 0.0:
				node.queue_free()
				blades.remove_at(k)
				continue
			b.dir = to / dl
			b.pos += b.dir * step
			returns += horde.hit_circle(b.pos, fly_radius(), dmg(), 0.0, b.dir, 99, c, horde.CH_RETURN)   # 돌아오는 길은 안 밀침(장수 쪽으로 끌어오지 않게)
		node.position = Vector3(b.pos.x, 0.9, b.pos.y)
		node.rotation.y += delta * 18.0

func _show_fx(d: Vector2, forward: float) -> void:
	fx.visible = true
	fx_t = FX_T
	fx.position = player.position + Vector3(d.x * forward, 0.25, d.y * forward)
	fx.rotation.y = atan2(d.x, d.y)
