extends Node3D
## 천기(제갈량 고유 심법, D-334): 날씨가 바람 → 비 → 번개로 period초마다 저절로 바뀜. 판 시작은 바람.
##   바람 — 바람날 속도 · 사거리 · 밀침 ↑, 추가 초식 밀침 ↑(잎이 흩날림)
##   비   — 적 모두 느려짐, 바람날 꿰뚫음 +(빗줄기 · 푸른 잿빛)
##   번개 — 바람날이 맞히면 chance로 번개가 둘레 적 chain명에게 튐, 낙뢰 초식 피해 ↑(가끔 번쩍임)
## 부적: 처치 kills명마다 한 장이 장수 곁에 떠오르고, max장이 되면 가까운 적들에게 날아가 터짐.
## 오의(동남풍)를 쓰면 force_wind(초)로 그동안 바람에 묶임(불 계열 초식 피해 ↑).
## main이 setup(main) → 매 프레임 tick(delta) · HUD hud_info() · --stats stats(). 절기는 ctx.weather로 지금 날씨를 받음.

const NAMES := ["바람", "비", "번개"]
const KEYS := ["wind", "rain", "bolt"]
const COLORS := [Color(0.55, 0.9, 0.7), Color(0.5, 0.7, 1.0), Color(1.0, 0.92, 0.45)]
const TINTS := [Color(0, 0, 0, 0.0), Color(0.15, 0.22, 0.35, 0.16), Color(0.12, 0.08, 0.25, 0.2)]
const HINTS := ["바람 — 바람날이 멀리 · 세게", "비 — 적이 느려지고 바람날이 더 꿰뚫음", "번개 — 바람날에 번개가 튐 · 낙뢰 강화"]
const FIRE_GALE := 1.5        # 동남풍 동안 화계 · 적토 화보 피해 배율

var main
var sp: Dictionary
var w := 0                    # 지금 날씨(0 바람 · 1 비 · 2 번개)
var left := 0.0               # 다음 날씨까지
var gale_t := 0.0             # 동남풍으로 바람에 묶인 남은 시간
var seen := [false, false, false]
var changes := 0              # 날씨가 바뀐 횟수(--stats)
var chains := 0               # 번개가 튄 수
var volleys := 0              # 부적이 날아간 번
var tal_hits := 0
var last_kills := 0
var kill_acc := 0
var tals: Array[MeshInstance3D] = []      # 곁에 떠 있는 부적
var flying: Array = []        # [{node, pos: Vector3, to: Vector2}]
var tal_mesh: BoxMesh
var tal_mat: StandardMaterial3D
var bolt_mat: StandardMaterial3D
var zaps: Array = []          # [{node, t}]
var tint: ColorRect
var flash := 0.0
var flash_rect: ColorRect
var rain_fx: CPUParticles3D
var wind_fx: CPUParticles3D
var flash_cd := 2.0

func setup(m) -> void:
	main = m
	sp = m.hero.passive
	left = sp.period
	last_kills = m.horde.kills
	m.weapon.hit_hook = _on_fan_hit
	tal_mesh = BoxMesh.new()
	tal_mesh.size = Vector3(0.32, 0.5, 0.03)
	tal_mat = StandardMaterial3D.new()
	tal_mat.albedo_color = Color(1.0, 0.88, 0.45)
	tal_mat.emission_enabled = true
	tal_mat.emission = Color(1.0, 0.6, 0.2) * 0.5
	bolt_mat = StandardMaterial3D.new()
	bolt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolt_mat.albedo_color = Color(1.0, 0.97, 0.6, 0.95)
	# 화면 색조 · 번쩍임(HUD 아래 층)
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	tint = ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = TINTS[0]
	layer.add_child(tint)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	layer.add_child(flash_rect)
	# 빗줄기 · 잎(장수를 따라다님 — 수는 고정 상한)
	rain_fx = _particles(260, Vector3(0.03, 0.7, 0.03), Color(0.75, 0.85, 1.0, 0.55), 0.6)
	rain_fx.direction = Vector3(0.15, -1, 0)
	rain_fx.spread = 3.0
	rain_fx.initial_velocity_min = 22.0
	rain_fx.initial_velocity_max = 26.0
	rain_fx.position = Vector3(0, 12, 0)
	wind_fx = _particles(140, Vector3(0.4, 0.06, 0.25), Color(0.55, 0.85, 0.4, 0.95), 2.2)
	wind_fx.direction = Vector3(1, 0.15, 0.3)
	wind_fx.spread = 12.0
	wind_fx.initial_velocity_min = 7.0
	wind_fx.initial_velocity_max = 11.0
	wind_fx.angular_velocity_min = -360.0
	wind_fx.angular_velocity_max = 360.0
	wind_fx.position = Vector3(-10, 2.0, 0)
	_apply()

func _particles(n: int, size: Vector3, col: Color, life: float) -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.amount = n
	ps.lifetime = life
	ps.emitting = false
	ps.local_coords = false
	ps.gravity = Vector3.ZERO
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(16, 0.5, 14)
	var bm := BoxMesh.new()
	bm.size = size
	ps.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	ps.material_override = m
	add_child(ps)
	return ps

func weather() -> String:
	return KEYS[w]

func force_wind(sec: float) -> void:
	## 동남풍(오의 팔진도): sec초 동안 바람에 묶임 — 끝나면 원래 차례로.
	gale_t = maxf(gale_t, sec)
	if w != 0:
		w = 0
		_apply()

func tick(delta: float) -> void:
	if gale_t > 0.0:
		gale_t -= delta
	else:
		left -= delta
		if left <= 0.0:
			left = sp.period
			w = (w + 1) % 3
			changes += 1
			_apply()
	_mods()
	_talisman_tick(delta)
	_fx_tick(delta)

func _apply() -> void:
	## 날씨가 바뀔 때: 연출 켜고 끄기, 처음 보는 날씨면 알림.
	rain_fx.emitting = w == 1
	wind_fx.emitting = w == 0
	tint.color = TINTS[w]
	if not seen[w]:
		seen[w] = true
		if main.t > 1.0:
			main._banner("천기 — %s" % HINTS[w], 1.8)
	print("WEATHER t=%.1f %s" % [main.t, KEYS[w]])

func _mods() -> void:
	## 날씨 배율을 무기 · 초식 · 적 무리에 넣음(매 프레임 덮어씀).
	var wp = main.weapon
	var wind: bool = w == 0
	var rain: bool = w == 1
	var bolt: bool = w == 2
	wp.dyn_speed = sp.wind.speed if wind else 1.0
	var want_area: float = sp.wind.range if wind else 1.0
	if absf(wp.dyn_area - want_area) > 0.001:
		wp.dyn_area = want_area
	wp.dyn_knock = sp.wind.knock if wind else 1.0
	wp.dyn_pierce = int(sp.rain.pierce) if rain else 0
	main.horde.weather_slow = sp.rain.slow if rain else 1.0
	for tid in main.tactics:
		var tac = main.tactics[tid]
		tac.knock_mul = sp.wind.tac_knock if wind else 1.0
		var wm := 1.0
		if bolt and tid == "bolt":
			wm = sp.bolt.tac
		if gale_t > 0.0 and tid in ["fire", "flamestep"]:
			wm = FIRE_GALE
		tac.weather_mul = wm

func _on_fan_hit(at: Vector2, n: int) -> void:
	## 바람날이 맞힌 자리(번개일 때만): chance로 둘레 적에게 번개가 튐.
	if w != 2 or n <= 0 or randf() > sp.bolt.chance:
		return
	var src := at
	var dmg: float = main.weapon.dmg() * sp.bolt.dmg
	var c := Vector2(main.player.position.x, main.player.position.z)
	for to in main.horde.nearest(at, sp.bolt.r, int(sp.bolt.chain) + 1):
		if to.distance_to(at) < 0.5:
			continue
		main.horde.hit_circle(to, 0.8, dmg, 0.2, Vector2.ZERO, 3, c, main.horde.CH_PASSIVE)
		_zap(src, to)
		chains += 1
		src = to

func _zap(a: Vector2, b: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d := b - a
	bm.size = Vector3(0.08, 0.08, maxf(d.length(), 0.1))
	mi.mesh = bm
	mi.material_override = bolt_mat
	add_child(mi)
	var mid := (a + b) * 0.5
	mi.position = Vector3(mid.x, 0.9, mid.y)
	mi.rotation.y = atan2(d.x, d.y)
	zaps.append({"node": mi, "t": 0.12})

func _talisman_tick(delta: float) -> void:
	var dk: int = main.horde.kills - last_kills
	last_kills = main.horde.kills
	kill_acc += dk
	while kill_acc >= int(sp.talisman.kills) and tals.size() < int(sp.talisman.max):
		kill_acc -= int(sp.talisman.kills)
		var mi := MeshInstance3D.new()
		mi.mesh = tal_mesh
		mi.material_override = tal_mat
		add_child(mi)
		tals.append(mi)
	if tals.size() >= int(sp.talisman.max):
		kill_acc = 0
	var pc: Vector3 = main.player.position
	var c := Vector2(pc.x, pc.z)
	# 곁에 떠 있는 부적: 장수 둘레를 천천히 돎
	for k in tals.size():
		var a: float = main.t * 1.6 + TAU * k / maxf(tals.size(), 1)
		tals[k].position = pc + Vector3(cos(a) * 1.1, 1.7 + 0.1 * sin(main.t * 4.0 + k), sin(a) * 1.1)
		tals[k].rotation.y = -a
	# 다 모이면 가까운 적들에게 날림
	if tals.size() >= int(sp.talisman.max):
		var targets: PackedVector2Array = main.horde.nearest(c, sp.talisman.seek, tals.size())
		if not targets.is_empty():
			volleys += 1
			for k in tals.size():
				var to: Vector2 = targets[k % targets.size()]
				flying.append({"node": tals[k], "pos": tals[k].position, "to": to})
			tals.clear()
	for k in range(flying.size() - 1, -1, -1):
		var f: Dictionary = flying[k]
		var goal := Vector3(f.to.x, 0.5, f.to.y)
		var d: Vector3 = goal - f.pos
		var step: float = sp.talisman.speed * delta
		var node: MeshInstance3D = f.node
		if d.length() <= step:
			var dmg: float = main.weapon.dmg() * sp.talisman.dmg
			tal_hits += main.horde.hit_circle(f.to, sp.talisman.r, dmg, 1.0, Vector2.ZERO, 99, c, main.horde.CH_PASSIVE)
			_boom(goal)
			node.queue_free()
			flying.remove_at(k)
			continue
		f.pos += d.normalized() * step
		node.position = f.pos
		node.rotation.y += delta * 14.0

func _boom(at: Vector3) -> void:
	var ps := CPUParticles3D.new()
	ps.one_shot = true
	ps.amount = 22
	ps.lifetime = 0.45
	ps.explosiveness = 1.0
	ps.direction = Vector3.UP
	ps.spread = 90.0
	ps.initial_velocity_min = 2.0
	ps.initial_velocity_max = 4.5
	ps.gravity = Vector3(0, -5, 0)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.12, 0.12)
	ps.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.7, 0.3)
	ps.material_override = m
	ps.position = at
	add_child(ps)
	ps.emitting = true
	get_tree().create_timer(0.8).timeout.connect(ps.queue_free)

func _fx_tick(delta: float) -> void:
	var pc: Vector3 = main.player.position
	rain_fx.global_position = pc + Vector3(-2, 12, 0)
	wind_fx.global_position = pc + Vector3(-12, 1.5, 0)
	for k in range(zaps.size() - 1, -1, -1):
		zaps[k].t -= delta
		if zaps[k].t <= 0.0:
			zaps[k].node.queue_free()
			zaps.remove_at(k)
	# 번개: 가끔 화면이 번쩍
	if w == 2:
		flash_cd -= delta
		if flash_cd <= 0.0:
			flash_cd = randf_range(2.5, 5.0)
			flash = 0.35
	flash = maxf(flash - delta * 2.5, 0.0)
	flash_rect.color.a = flash

func hud_info() -> Dictionary:
	var txt := "%s  %d초" % [NAMES[w], int(ceil(left))] if gale_t <= 0.0 else "동남풍  %d초" % int(ceil(gale_t))
	txt += "   ·   부적 %d / %d" % [tals.size(), int(sp.talisman.max)]
	var f: float = left / sp.period if gale_t <= 0.0 else 1.0
	return {"text": txt, "f": f, "color": COLORS[w], "pulse": gale_t <= 0.0 and left <= sp.warn}

func stats() -> String:
	return "WEATHER changes=%d chains=%d volleys=%d talisman_hits=%d" % [changes, chains, volleys, tal_hits]
