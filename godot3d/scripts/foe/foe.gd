extends Node3D
## 적장 하나(D-289 정예 · D-290 보스) — 수치 · 공격 패턴은 data/foes.gd.
## horde.targets에 넣으면 장수의 모든 공격(hit_arc · hit_line · hit_circle · 기절 · 밀침)이 이 적장도 맞힘:
##   pos2() · radius · alive · hurt(dmg, push, knock, ch) · stun_for(t) · push_by(v)
## 공격: 예고(붉은 표시, wind초) → 실행. tick()이 이번 프레임에 장수에게 준 피해(절대값)를 돌려줌 — main이 맞은 뒤 무적 · 경공 무적을 적용.

signal died(foe)

const HIT_CD := 0.3
const N_CH := 6

var id := ""
var spec: Dictionary
var hp := 1.0
var hp_max := 1.0
var radius := 0.8
var alive := true
var home := Vector2.ZERO
var horde: Node3D
var cds := PackedFloat32Array()
var stun_t := 0.0
var now := 0.0                # 판 시각(main이 넣음 — 처음 맞을 때 체력 배율)
var engaged := false
var phase2 := false
var patterns: Array = []
var pat_cd: Array = []        # 패턴마다 남은 재사용
var state := "idle"           # idle · chase · wind · act · recover
var cur: Dictionary = {}
var st_t := 0.0
var act_dir := Vector2.ZERO
var act_moved := 0.0
var act_hit := false
var ring_r := 0.0
var circle_pts := PackedVector2Array()
var speed_mul := 1.0
var cd_mul := 1.0
var model: Node3D
var anim: AnimationPlayer
var tele: MeshInstance3D      # 예고 표시(붉게)
var tele_mat: StandardMaterial3D
var bar_bg: MeshInstance3D
var bar_fg: MeshInstance3D
var label: Label3D
var dealt := 0.0              # 장수에게 준 피해 합(점검용)
var casts := {}               # 패턴 종류별 실행 수(점검용)

func setup(foe_id: String, at: Vector2, h: Node3D, font: Font = null) -> void:
	id = foe_id
	spec = FoeTable.LIST[foe_id]
	home = at
	horde = h
	hp_max = spec.hp
	hp = hp_max
	radius = spec.radius
	position = Vector3(at.x, 0, at.y)
	cds.resize(N_CH)
	patterns = spec.patterns.duplicate(true)
	for p in patterns:
		pat_cd.append(p.cd * randf_range(0.3, 0.8))
	if ResourceLoader.exists(spec.glb):
		model = load(spec.glb).instantiate()
		model.scale = Vector3.ONE * spec.scale
		add_child(model)
		anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim and anim.has_animation("walk"):
			anim.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
	tele_mat = StandardMaterial3D.new()
	tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tele_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tele_mat.albedo_color = Color(0.95, 0.15, 0.1, 0.35)
	tele = MeshInstance3D.new()
	tele.material_override = tele_mat
	tele.visible = false
	tele.top_level = true
	add_child(tele)
	if not spec.get("boss", false):   # 머리 위 체력 막대 · 이름(보스는 main이 화면 위에 크게)
		bar_bg = _bar(Color(0, 0, 0, 0.7), 1.6)
		bar_fg = _bar(spec.color, 1.55)
		label = Label3D.new()
		label.text = spec.name
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 48
		label.outline_size = 10
		label.pixel_size = 0.01
		if font:
			label.font = font
		label.position = Vector3(0, 3.6, 0)
		add_child(label)

func _bar(col: Color, w: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, 0.16)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	mi.material_override = m
	mi.position = Vector3(0, 3.2, 0)
	add_child(mi)
	return mi

func pos2() -> Vector2:
	return Vector2(position.x, position.z)

# ── 맞기(horde가 부름) ──
func hurt(dmg: float, push: Vector2, knock: float, ch: int) -> bool:
	if not alive or cds[ch] > 0.0:
		return false
	if not engaged:   # 처음 맞을 때 판 시각만큼 단단해짐(늦게 깨러 오면 더 셈)
		engaged = true
		if spec.hp_time > 0.0:
			hp_max = spec.hp * (1.0 + now / spec.hp_time)
			hp = hp_max
	cds[ch] = HIT_CD
	hp -= dmg
	push_by(push * knock)
	if hp <= 0.0:
		_die()
	return true

func stun_for(t: float) -> void:
	stun_t = maxf(stun_t, t * spec.stun)

func push_by(v: Vector2) -> void:
	if state == "act" and cur.get("type", "") == "charge":
		return
	position += Vector3(v.x, 0, v.y) * spec.knock   # 적장은 잘 안 밀림(knock 배율)

func _die() -> void:
	alive = false
	hp = 0.0
	tele.visible = false
	visible = false
	died.emit(self)

# ── 매 프레임 ──
func tick(delta: float, player: Vector2, dmg_mul: float) -> float:
	if not alive:
		return 0.0
	for c in N_CH:
		cds[c] = maxf(cds[c] - delta, 0.0)
	for k in pat_cd.size():
		pat_cd[k] -= delta
	if spec.has("phase2") and not phase2 and hp <= hp_max * spec.phase2.at:
		phase2 = true
		speed_mul = spec.phase2.speed_mul
		cd_mul = spec.phase2.cd_mul
		for p in spec.phase2.patterns:
			patterns.append(p)
			pat_cd.append(1.0)
	_update_bar()
	var me := pos2()
	var to := player - me
	var dist := to.length()
	var out := 0.0
	if stun_t > 0.0:
		stun_t -= delta
		tele.visible = false
		if state == "wind":
			state = "chase"
		_anim(false)
		return 0.0
	st_t += delta
	match state:
		"idle", "chase":
			var guard_ok: bool = spec.leash <= 0.0 or home.distance_to(player) < spec.leash + spec.aggro
			if dist < spec.aggro and guard_ok:
				state = "chase"
				var k := _ready_pattern(dist)
				if k >= 0:
					_begin(k, me, player)
				elif dist > radius + 1.2:
					_move(to / dist * spec.speed * speed_mul * delta)
					_face(to)
			else:
				state = "idle"
				var back := home - me
				if back.length() > 1.0:
					_move(back.normalized() * spec.speed * delta)
					_face(back)
				else:
					_anim(false)
		"wind":
			tele_mat.albedo_color.a = 0.25 + 0.3 * sin(st_t * 20.0) * 0.5 + 0.15
			if cur.type == "charge" or cur.type == "sweep":
				_face(act_dir)
			if st_t >= cur.wind:
				state = "act"
				st_t = 0.0
				act_hit = false
				act_moved = 0.0
				ring_r = 0.5
				casts[cur.type] = casts.get(cur.type, 0) + 1
				out += _act_start(me, player, dmg_mul)
		"act":
			out += _act_tick(delta, me, player, dmg_mul)
		"recover":
			_anim(false)
			if st_t >= 0.5:
				state = "chase"
	dealt += out
	return out

func threatens(p: Vector2) -> bool:
	## 지금 예고 중인 공격 범위 안에 p가 있나(봇이 피하기용, D-290).
	if state != "wind":
		return false
	var me := pos2()
	match cur.type:
		"sweep": return p.distance_to(me) <= cur.range + 0.6
		"charge":
			var d := p - me
			var along := d.dot(act_dir)
			return along > -1.0 and along < cur.dist + 1.0 and absf(d.cross(act_dir)) < cur.width * 0.5 + 0.8
		"circles":
			for cp in circle_pts:
				if p.distance_to(cp) <= cur.r + 0.3:
					return true
			return false
		"ring": return p.distance_to(me) <= cur.r
	return false

func _ready_pattern(dist: float) -> int:
	for k in patterns.size():
		var p: Dictionary = patterns[k]
		if pat_cd[k] > 0.0:
			continue
		var reach := 99.0
		match p.type:
			"sweep": reach = p.range + 0.5
			"charge": reach = p.dist
			"circles": reach = 14.0
			"ring": reach = p.r * 0.8
			"summon": reach = 16.0
		if dist <= reach:
			return k
	return -1

func _begin(k: int, me: Vector2, player: Vector2) -> void:
	cur = patterns[k]
	pat_cd[k] = cur.cd * cd_mul
	state = "wind"
	st_t = 0.0
	act_dir = (player - me).normalized() if player.distance_to(me) > 0.01 else Vector2(0, 1)
	tele.visible = true
	_anim(false)
	match cur.type:
		"sweep":
			tele.mesh = _arc_mesh(cur.range, deg_to_rad(cur.arc))
			tele.global_position = Vector3(me.x, 0.06, me.y)
			tele.rotation = Vector3(0, atan2(act_dir.x, act_dir.y), 0)
		"charge":
			var bm := BoxMesh.new()
			bm.size = Vector3(cur.width, 0.04, cur.dist)
			tele.mesh = bm
			var mid: Vector2 = me + act_dir * cur.dist * 0.5
			tele.global_position = Vector3(mid.x, 0.06, mid.y)
			tele.rotation = Vector3(0, atan2(act_dir.x, act_dir.y), 0)
		"circles":
			circle_pts = PackedVector2Array([player])
			for i in int(cur.n) - 1:
				circle_pts.append(player + Vector2.from_angle(randf() * TAU) * randf_range(1.0, cur.spread))
			tele.mesh = _discs_mesh(circle_pts, cur.r, me)
			tele.global_position = Vector3(me.x, 0.06, me.y)
			tele.rotation = Vector3.ZERO
		"ring":
			var cm := CylinderMesh.new()
			cm.top_radius = cur.r; cm.bottom_radius = cur.r; cm.height = 0.03; cm.radial_segments = 32
			tele.mesh = cm
			tele.global_position = Vector3(me.x, 0.05, me.y)
			tele.rotation = Vector3.ZERO
		"summon":
			var cm2 := CylinderMesh.new()
			cm2.top_radius = 2.5; cm2.bottom_radius = 2.5; cm2.height = 0.03; cm2.radial_segments = 16
			tele.mesh = cm2
			tele.global_position = Vector3(me.x, 0.05, me.y)
			tele.rotation = Vector3.ZERO

func _act_start(me: Vector2, player: Vector2, dmg_mul: float) -> float:
	var out := 0.0
	match cur.type:
		"sweep":
			var d := player - me
			if d.length() <= cur.range + 0.4 and absf(angle_difference(atan2(d.y, d.x), atan2(act_dir.y, act_dir.x))) <= deg_to_rad(cur.arc) * 0.5:
				out = cur.dmg * dmg_mul
			_flash_tele(0.15)
			state = "recover"
			st_t = 0.0
		"circles":
			for cp in circle_pts:
				if player.distance_to(cp) <= cur.r:
					out = cur.dmg * dmg_mul
					break
			_flash_tele(0.15)
			state = "recover"
			st_t = 0.0
		"summon":
			if horde:
				horde.pull_near(me, int(cur.n))
			tele.visible = false
			state = "recover"
			st_t = 0.0
		"charge", "ring":
			tele.visible = cur.type == "ring"
			if cur.type == "ring":
				tele.scale = Vector3(0.05, 1, 0.05)
	return out

func _act_tick(delta: float, me: Vector2, player: Vector2, dmg_mul: float) -> float:
	var out := 0.0
	match cur.type:
		"charge":
			tele.visible = false
			var step: float = cur.speed * delta
			_move(act_dir * step)
			act_moved += step
			_anim(true)
			if not act_hit and player.distance_to(pos2()) <= cur.width * 0.5 + 0.6:
				act_hit = true
				out = cur.dmg * dmg_mul
			if act_moved >= cur.dist:
				state = "recover"
				st_t = 0.0
		"ring":
			ring_r += cur.speed * delta
			tele.global_position = Vector3(me.x, 0.05, me.y)
			var f: float = ring_r / cur.r
			tele.scale = Vector3(f, 1, f)
			tele_mat.albedo_color.a = 0.45 * (1.0 - f) + 0.1
			var pd := player.distance_to(me)
			if not act_hit and absf(pd - ring_r) <= cur.width * 0.5:
				act_hit = true
				out = cur.dmg * dmg_mul
			if ring_r >= cur.r:
				tele.visible = false
				tele.scale = Vector3.ONE
				state = "recover"
				st_t = 0.0
		_:
			state = "recover"
			st_t = 0.0
	return out

func _flash_tele(_t: float) -> void:
	tele_mat.albedo_color.a = 0.7
	var tw := create_tween()
	tw.tween_property(tele_mat, "albedo_color:a", 0.0, 0.2)
	tw.tween_callback(func(): tele.visible = false)

func _move(v: Vector2) -> void:
	var np := pos2() + v
	if horde:
		np = horde._clamp(np)
	position = Vector3(np.x, 0, np.y)
	_anim(true)

func _face(d: Vector2) -> void:
	if d.length() > 0.01:
		rotation.y = atan2(d.x, d.y)

func _anim(walking: bool) -> void:
	if anim and anim.has_animation("walk"):
		if walking and anim.current_animation != "walk":
			anim.play("walk")
		elif not walking and anim.is_playing():
			anim.pause()

func _update_bar() -> void:
	if bar_fg:
		var f := clampf(hp / hp_max, 0.0, 1.0)
		bar_fg.scale = Vector3(f, 1, 1)
		bar_fg.visible = engaged
		bar_bg.visible = engaged

func _arc_mesh(r_out: float, arc: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 16
	for k in seg:
		var a0 := -arc * 0.5 + arc * k / seg
		var a1 := -arc * 0.5 + arc * (k + 1) / seg
		for v in [Vector3.ZERO, Vector3(sin(a0) * r_out, 0, cos(a0) * r_out), Vector3(sin(a1) * r_out, 0, cos(a1) * r_out)]:
			st.add_vertex(v)
	return st.commit()

func _discs_mesh(pts: PackedVector2Array, r: float, origin: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for cp in pts:
		var c := Vector3(cp.x - origin.x, 0, cp.y - origin.y)
		for k in 16:
			var a0 := TAU * k / 16.0
			var a1 := TAU * (k + 1) / 16.0
			for v in [c, c + Vector3(cos(a0) * r, 0, sin(a0) * r), c + Vector3(cos(a1) * r, 0, sin(a1) * r)]:
				st.add_vertex(v)
	return st.commit()
