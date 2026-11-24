extends Ult
## 팔진도(제갈량 절기, D-295 · 연출 명세 D-336 — 설정화 art/concept/bagua_skill.webp · bagua_parts.webp):
##   1. 시전: 장수가 학우선을 치켜듦(ctx.anchor.play_once("cast")) · 바닥에 하늘색 팔각 진이 가운데에서 바깥으로 unfold초 동안 펼쳐짐
##      (무늬는 설정화에서 잘라 낸 assets/textures/bagua_glow.png — 정확한 팔괘 여덟 + 가운데 태극)
##   2. 돌기둥: 바깥 팔각 꼭짓점 여덟 곳에서 차례로(pillar_gap초 간격) 솟음 — 기둥마다 자기 쪽 괘가 빛남(복희 팔괘 차례)
##   3. 반지름 r(제갈량 키 × 5) · 안쪽 고리(inner × r)는 피해 2배
##   4. 진 안 잡병은 혼란(이리저리 헤맴 · 안 찌름 · 머리 위 물음표 — horde.confuse_circle) + 맞음 대기(0.3초)마다 피해
##   5. 진 안에 옅은 흰 안개가 천천히 돎
##   6. dur초 뒤 돌기둥이 무너지며 진이 바깥에서 안으로 사라짐
## 날씨 덧씌움(D-334, ctx.weather — 천기가 없으면 ""): 바람 진 안 적을 가운데로 끎 · 비 진 안 느려짐 · 번개 진 안에 벼락.
## 오의 '동남풍': 불빛판(bagua_fire.png) · 피해 ↑ + 펼칠 때 큰 바람이 둘레 gale_r를 쓸어냄(천기는 main이 바람에 묶음).

const PILLAR_GLB := "res://assets/models/bagua_pillar.glb"
const PILLAR_SCALE := 1.2     # 기둥 높이 1.5 × 1.2 = 1.8(제갈량 키 2.4의 3/4)
const PILLAR_RISE := 0.25     # 기둥 하나가 솟는 시간
const END_T := 0.6            # 무너지며 사라지는 시간
const OCT_R := 0.955          # 무늬 그림에서 바깥 팔각 꼭짓점 반지름(그림 반 폭 대비)
# 복희 팔괘(위 → 아래 효, 1 = 이은 줄 · 0 = 끊긴 줄): 남(위) 건 · 남서 손 · 서 감 · 북서 간 · 북 곤 · 북동 진 · 동 리 · 남동 태
const TRIGRAMS := [[1, 1, 1], [1, 1, 0], [0, 1, 0], [1, 0, 0], [0, 0, 0], [0, 0, 1], [1, 0, 1], [0, 1, 1]]

var disc: MeshInstance3D
var disc_mat: StandardMaterial3D
var pillars: Array = []       # [{node, base_y, ang, tilt}]
var mist: CPUParticles3D
var o := Vector2.ZERO
var wx := ""
var bolt_t := 0.0
var flashes: Array = []       # [{node, t}]
var col := Color(0.55, 0.95, 1.0)
var confused := 0             # 혼란에 빠뜨린 수(--stats는 horde.confused_total)

func _start() -> void:
	o = ctx.origin
	wx = "wind" if ctx.evolved and float(p.gale_r) > 0.0 else String(ctx.get("weather", ""))
	var fire: bool = ctx.evolved
	col = Color(1.0, 0.62, 0.25) if fire else Color(0.55, 0.95, 1.0)
	var a = ctx.get("anchor")
	if a is Node3D and is_instance_valid(a) and a.has_method("play_once"):
		a.play_once("cast", 0.7)   # 학우선을 치켜듦
	# 바닥 진(무늬 그림의 투명도로 섞음 — 밝은 풀밭에서 하얗게 날아가지 않게)
	disc = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(p.r * 2.0 / OCT_R, p.r * 2.0 / OCT_R)   # 바깥 팔각 꼭짓점이 반지름 r에 오게
	disc.mesh = pm
	disc_mat = StandardMaterial3D.new()
	disc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc_mat.albedo_texture = load("res://assets/textures/bagua_fire.png" if fire else "res://assets/textures/bagua_glow.png")
	disc_mat.albedo_color = Color(1, 1, 1, 0.95)
	disc.material_override = disc_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position = Vector3(o.x, 0.04, o.y)
	disc.scale = Vector3(0.01, 1, 0.01)
	add_child(disc)
	_make_pillars()
	_make_mist()
	if float(p.gale_r) > 0.0:   # 동남풍: 큰 바람이 둘레를 쓸어냄
		ctx.horde.push_from(o, p.gale_r, p.gale_push)
		_burst(Vector3(o.x, 1.2, o.y), Color(0.8, 1.0, 0.85, 0.9), 70, 12.0)

func _make_pillars() -> void:
	var mesh: Mesh = null
	if ResourceLoader.exists(PILLAR_GLB):
		var src: Node = load(PILLAR_GLB).instantiate()
		for c in src.find_children("*", "MeshInstance3D", true, false):
			mesh = (c as MeshInstance3D).mesh
			break
		src.free()
	var glyph := StandardMaterial3D.new()
	glyph.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glyph.albedo_color = col.lerp(Color.WHITE, 0.25)
	for k in 8:
		var ang := deg_to_rad(22.5 + 45.0 * k) + PI * 0.5   # 꼭짓점(무늬의 변 가운데 사이) — 위(남, -Z가 화면 위)부터
		var at := Vector3(o.x + cos(ang) * p.r, 0.0, o.y - sin(ang) * p.r)
		var pl := Node3D.new()
		add_child(pl)
		pl.position = at
		pl.look_at(Vector3(o.x, 0.0, o.y) + (at - Vector3(o.x, 0, o.y)) * 2.0, Vector3.UP)   # +Z가 가운데를 봄
		pl.scale = Vector3.ONE * PILLAR_SCALE
		if mesh:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			pl.add_child(mi)
		# 자기 쪽 괘: 앞뒤 두 면(위에서 보는 카메라라 안쪽 · 바깥쪽 다 보이게)
		var tg: Array = TRIGRAMS[k]
		for face in [1.0, -1.0]:
			for line in 3:
				var y := 1.08 - line * 0.17
				var bits: int = tg[line]
				var pieces := [[0.0, 0.4]] if bits == 1 else [[-0.12, 0.16], [0.12, 0.16]]
				for pc in pieces:
					var bm := BoxMesh.new()
					bm.size = Vector3(pc[1], 0.08, 0.03)
					var g := MeshInstance3D.new()
					g.mesh = bm
					g.material_override = glyph
					g.position = Vector3(pc[0] * face, y, 0.3 * face)
					pl.add_child(g)
		pl.visible = false
		pillars.append({"node": pl, "at": at, "tilt": Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()})

func _make_mist() -> void:
	mist = CPUParticles3D.new()
	mist.amount = 30
	mist.lifetime = 3.0
	mist.preprocess = 1.5
	mist.local_coords = true
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(p.r * 0.7, 0.2, p.r * 0.7)
	mist.direction = Vector3(1, 0.1, 0)
	mist.spread = 180.0
	mist.gravity = Vector3.ZERO
	mist.initial_velocity_min = 0.2
	mist.initial_velocity_max = 0.6
	mist.scale_amount_min = 2.5
	mist.scale_amount_max = 4.5
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	mist.mesh = qm
	var gt := GradientTexture2D.new()   # 둥글게 흐려지는 흰 점
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	gt.gradient = gr
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.albedo_texture = gt
	mm.albedo_color = Color(1, 1, 1, 0.07)
	mm.vertex_color_use_as_albedo = true
	mist.material_override = mm
	mist.position = Vector3(o.x, 0.6, o.y)
	add_child(mist)
	mist.emitting = true

func tick(delta: float) -> bool:
	t += delta
	var alive: bool = t < p.dur
	# 1. 진이 가운데에서 바깥으로 펼쳐짐 / 6. 끝나면 바깥에서 안으로 줄어듦
	var s := 1.0
	if t < p.unfold:
		var k: float = t / p.unfold
		s = 1.0 - pow(1.0 - k, 3.0)
	elif not alive:
		s = clampf(1.0 - (t - p.dur) / END_T, 0.0, 1.0)
		s = s * s
	disc.scale = Vector3(maxf(s, 0.01), 1, maxf(s, 0.01))
	disc_mat.albedo_color.a = 0.95 * (0.88 + 0.12 * sin(t * 6.0)) * (1.0 if alive else s)
	# 2. 돌기둥: 차례로 솟고 · 끝나면 기울며 가라앉음
	for k in pillars.size():
		var pl: Dictionary = pillars[k]
		var n: Node3D = pl.node
		var t0: float = p.unfold * 0.6 + k * p.pillar_gap
		if t < t0:
			continue
		if not n.visible:
			n.visible = true
			_burst(pl.at + Vector3(0, 0.2, 0), Color(0.75, 0.72, 0.68), 14, 2.5)   # 흙먼지
		var up := clampf((t - t0) / PILLAR_RISE, 0.0, 1.0)
		var y := -1.9 * (1.0 - up * up * (3.0 - 2.0 * up))
		if not alive:   # 무너짐: 기울고 가라앉음
			var c := clampf((t - p.dur) / END_T, 0.0, 1.0)
			y -= 1.9 * c * c
			n.rotation = Vector3(pl.tilt.x * 0.9 * c, n.rotation.y, pl.tilt.z * 0.9 * c)
			if c > 0.0 and not pl.has("dust"):
				pl["dust"] = true
				_burst(pl.at + Vector3(0, 0.6, 0), Color(0.7, 0.7, 0.72), 22, 3.5)
		n.position.y = y
	# 5. 안개가 천천히 돎
	mist.rotation.y += delta * 0.35
	if not alive:
		mist.emitting = false
	# 3 · 4. 피해 · 혼란(펼쳐진 만큼)
	if alive and t >= p.unfold * 0.5:
		var r: float = p.r * s
		hits += ctx.horde.hit_circle(o, r * p.inner, p.dmg * 2.0 * ctx.atk_mul, 0.0, Vector2.ZERO, 9999, o, ctx.horde.CH_ULT)   # 안쪽 고리 먼저(맞음 대기가 걸려 바깥 판정에 안 겹침)
		hits += ctx.horde.hit_circle(o, r, p.dmg * ctx.atk_mul, 0.0, Vector2.ZERO, 9999, o, ctx.horde.CH_ULT)
		confused += ctx.horde.confuse_circle(o, r, p.confuse)
		match wx:
			"wind":   # 가운데로 끎(밀침을 거꾸로)
				ctx.horde.push_from(o, r, -p.pull * delta)
			"rain":
				ctx.horde.slow_zones.append({"c": o, "r2": r * r, "f": p.rain_slow})
			"bolt":
				bolt_t -= delta
				if bolt_t <= 0.0:
					bolt_t = p.bolt_cd
					for tp in ctx.horde.random_in(o, r, int(p.bolt_n)):
						hits += ctx.horde.hit_circle(tp, 1.2, p.bolt_dmg * ctx.atk_mul, 0.3, Vector2.ZERO, 999, o, ctx.horde.CH_PASSIVE)
						_bolt(tp)
	for k in range(flashes.size() - 1, -1, -1):
		flashes[k].t -= delta
		if flashes[k].t <= 0.0:
			flashes[k].node.queue_free()
			flashes.remove_at(k)
	return t >= p.dur + END_T

func _bolt(tp: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 6.0, 0.15)
	mi.mesh = bm
	mi.material_override = _glow(Color(1.0, 0.95, 0.55, 0.9))
	mi.position = Vector3(tp.x, 3.0, tp.y)
	add_child(mi)
	flashes.append({"node": mi, "t": 0.15})
