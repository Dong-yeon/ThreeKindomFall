extends Ult
## 청룡강림(관우 절기, D-332): 장수 뒤 하늘에서 청룡이 내리꽂혀(내려앉는 자리 둥근 충격) 보는 쪽 직선으로 땅을 훑고 하늘로 올라감.
## 오의 '청룡파천'(orbit_dur > 0): 훑은 뒤 장수 둘레를 orbit_dur초 감아 돌며 닿는 적을 벰 — 장수를 따라가야 하므로 ctx.anchor(Node3D, 없으면 origin)를 봄.
## 용 모양은 코드로: 마디 구슬(머리에서 꼬리로 가늘어짐) + 머리 · 뿔 · 등지느러미. 마디는 머리가 지나온 길을 시간차로 따라감.

const SEG := 24               # 몸 마디 수(서로 겹쳐 굵은 몸통으로 보이게)
const LAG := 0.022            # 마디 사이 시간차(초)
const DIVE := 0.38            # 하늘에서 땅까지(초)
const RISE := 0.55            # 하늘로 올라가는 시간(초)
const BLEND := 0.3            # 훑기 → 감아 돌기로 넘어가는 시간(초)
const TEAL := Color(0.12, 0.62, 0.52)
const GOLD := Color(1.0, 0.82, 0.35)

var f := Vector2(0, 1)        # 보는 쪽
var o := Vector2.ZERO         # 시전 자리
var p_sky := Vector3.ZERO     # 내려오기 시작하는 자리
var p_land := Vector3.ZERO    # 내려앉는 자리
var run_t := 0.0              # 훑는 시간
var orbit_from := 0.0         # 감아 돌기 시작 시각
var rise_from := 0.0          # 올라가기 시작 시각
var landed := false
var prev_head := Vector3.ZERO
var segs: Array[MeshInstance3D] = []
var head: Node3D
var rise_start := Vector3.ZERO
var rise_dir := Vector3.ZERO

func _start() -> void:
	f = ctx.facing
	o = ctx.origin
	p_sky = Vector3(o.x - f.x * 3.0, 11.0, o.y - f.y * 3.0)
	p_land = Vector3(o.x + f.x * 1.5, 0.7, o.y + f.y * 1.5)
	run_t = p.length / p.speed
	orbit_from = DIVE + run_t
	rise_from = orbit_from + float(p.orbit_dur)
	_build_body()
	prev_head = p_sky

func _anchor() -> Vector2:
	var a = ctx.get("anchor")
	if a is Node3D and is_instance_valid(a):
		return Vector2(a.position.x, a.position.z)
	return o

func _head_at(tt: float) -> Vector3:
	## tt 시각 머리 자리(마디는 tt - k·LAG로 부름).
	if tt <= DIVE:
		var s := clampf(tt / DIVE, 0.0, 1.0)
		return p_sky.lerp(p_land, s * s)   # 처음엔 느리고 땅에 가까울수록 빠르게
	if tt <= orbit_from:
		var along: float = p.speed * (tt - DIVE)
		var side := Vector2(-f.y, f.x) * sin(along * 0.55) * 0.6   # 몸을 좌우로 굽이치며
		var g := Vector2(p_land.x, p_land.z) + f * along + side
		return Vector3(g.x, 0.7 + 0.2 * sin(along * 0.9), g.y)
	if tt <= rise_from:
		var a := _anchor()
		var ang: float = atan2(f.y, f.x) + TAU * p.orbit_spin * (tt - orbit_from)
		var c := Vector3(a.x + cos(ang) * p.orbit_r, 1.0 + 0.25 * sin(tt * 5.0), a.y + sin(ang) * p.orbit_r)
		var bl := clampf((tt - orbit_from) / BLEND, 0.0, 1.0)
		return _head_at_run_end().lerp(c, bl)
	if rise_dir == Vector3.ZERO:
		rise_start = _head_at(rise_from - 0.0001)
		var fwd := Vector3(f.x, 0, f.y)
		rise_dir = (fwd * 0.5 + Vector3.UP).normalized()
	return rise_start + rise_dir * 22.0 * (tt - rise_from)

func _head_at_run_end() -> Vector3:
	var along: float = p.length
	var side := Vector2(-f.y, f.x) * sin(along * 0.55) * 0.6
	var g := Vector2(p_land.x, p_land.z) + f * along + side
	return Vector3(g.x, 0.7 + 0.2 * sin(along * 0.9), g.y)

func tick(delta: float) -> bool:
	t += delta
	var hp3 := _head_at(t)
	var hp2 := Vector2(hp3.x, hp3.z)
	# 내려앉음: 둥근 충격
	if not landed and t >= DIVE:
		landed = true
		var l2 := Vector2(p_land.x, p_land.z)
		hits += ctx.horde.hit_circle(l2, p.land_r, p.land_dmg * ctx.atk_mul, p.knock, Vector2.ZERO, 9999, l2, ctx.horde.CH_ULT)
		_burst(p_land + Vector3(0, 0.3, 0), Color(0.4, 1.0, 0.85), 50, 6.0)
		_burst(p_land + Vector3(0, 0.3, 0), GOLD, 24, 4.0)
	# 훑기: 이번 프레임에 머리가 지나간 구간을 직사각형으로
	if t > DIVE and t <= orbit_from:
		var pv := Vector2(prev_head.x, prev_head.z)
		var d := hp2 - pv
		if d.length() > 0.001:
			hits += ctx.horde.hit_line(pv, d.normalized(), d.length() + 0.8, p.width * 0.5, p.dmg * ctx.atk_mul, p.knock, ctx.horde.CH_ULT)
	# 감아 돌기(오의): 머리 둘레를 벰, 장수 바깥쪽으로 밀어냄
	elif t > orbit_from + BLEND * 0.5 and t <= rise_from:
		var a := _anchor()
		var out := (hp2 - a).normalized()
		hits += ctx.horde.hit_circle(hp2, 1.8, p.orbit_dmg * ctx.atk_mul, 1.2, out, 99, a, ctx.horde.CH_ULT)
	prev_head = hp3
	_pose()
	return t >= rise_from + RISE + SEG * LAG

func _pose() -> void:
	## 마디는 머리가 지나온 길을 시간차로 따라감. 아직 하늘에 안 나온 마디는 숨김.
	var fade := clampf(1.0 - (t - rise_from - RISE * 0.6) / (RISE * 0.6 + SEG * LAG), 0.0, 1.0)
	var hp3 := _head_at(t)
	var nxt := _head_at(maxf(t - LAG, 0.0))
	head.position = hp3
	if hp3.distance_to(nxt) > 0.001:
		head.look_at(hp3 + (hp3 - nxt), Vector3.UP)
	head.scale = Vector3.ONE * maxf(fade, 0.01)
	for k in segs.size():
		var tk := t - (k + 1) * LAG
		var mi := segs[k]
		mi.visible = tk >= 0.0 and fade > 0.01
		if mi.visible:
			mi.position = _head_at(tk)
			var ahead := _head_at(tk + LAG * 0.5)
			if mi.position.distance_to(ahead) > 0.001:
				mi.look_at(ahead, Vector3.UP)
			mi.scale = Vector3.ONE * fade

func _mat(col: Color, glow := 0.3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col * glow
	m.roughness = 0.5
	return m

func _build_body() -> void:
	var m_body := _mat(TEAL)
	var m_gold := _mat(GOLD, 0.8)
	var m_belly := _mat(Color(0.85, 0.95, 0.75), 0.4)
	for k in SEG:
		var mi := MeshInstance3D.new()
		var r := lerpf(0.6, 0.14, pow(float(k) / (SEG - 1), 0.8))
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		mi.mesh = sm
		mi.material_override = m_body
		var belly := MeshInstance3D.new()   # 배 비늘(밝은 띠)
		var bs := SphereMesh.new()
		bs.radius = r * 0.8
		bs.height = r * 1.6
		bs.radial_segments = 8
		bs.rings = 4
		belly.mesh = bs
		belly.material_override = m_belly
		belly.position = Vector3(0, -r * 0.35, 0)
		mi.add_child(belly)
		if k % 3 == 1:   # 등지느러미(금)
			var fin := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.08, r * 1.3, r * 1.4)
			fin.mesh = pm
			fin.material_override = m_gold
			fin.position = Vector3(0, r * 0.9, 0)
			mi.add_child(fin)
		mi.visible = false
		add_child(mi)
		segs.append(mi)
	head = Node3D.new()
	add_child(head)
	# 머리(-Z가 앞: look_at 기준)
	var skull := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.75, 0.55, 0.8)
	skull.mesh = bm
	skull.material_override = m_body
	head.add_child(skull)
	var snout := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.55, 0.32, 0.6)
	snout.mesh = sb
	snout.material_override = m_body
	snout.position = Vector3(0, -0.08, -0.62)
	head.add_child(snout)
	var jaw := MeshInstance3D.new()
	var jb := BoxMesh.new()
	jb.size = Vector3(0.5, 0.12, 0.55)
	jaw.mesh = jb
	jaw.material_override = m_belly
	jaw.position = Vector3(0, -0.3, -0.55)
	head.add_child(jaw)
	for sx in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.09
		cm.height = 0.75
		horn.mesh = cm
		horn.material_override = m_gold
		horn.position = Vector3(sx * 0.22, 0.45, 0.25)
		horn.rotation = Vector3(deg_to_rad(55), 0, sx * deg_to_rad(-20))
		head.add_child(horn)
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.08
		em.height = 0.16
		eye.mesh = em
		eye.material_override = m_gold
		eye.position = Vector3(sx * 0.3, 0.12, -0.3)
		head.add_child(eye)
		var whisker := MeshInstance3D.new()   # 수염(금 가는 막대 — 뒤로 휘날림)
		var wb := BoxMesh.new()
		wb.size = Vector3(0.04, 0.04, 0.9)
		whisker.mesh = wb
		whisker.material_override = m_gold
		whisker.position = Vector3(sx * 0.3, -0.12, -0.2)
		whisker.rotation = Vector3(deg_to_rad(-15), sx * deg_to_rad(35), 0)
		head.add_child(whisker)
	head.position = p_sky
