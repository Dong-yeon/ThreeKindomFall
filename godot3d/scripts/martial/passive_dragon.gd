extends Node3D
## 청룡의 피(관우 고유 심법, D-333): 휩쓸기로 맞힌 적 수만큼 용기(gauge)가 참 — 한 번 휘두름에 cap까지.
## 가득 차면 dur초 청룡 상태: 휩쓸기 범위 area배 · 피해 dmg배 · 공격 속도 haste배, 휘두를 때마다 청룡 기운(wave)이 앞으로 날아가 줄에 선 적을 벰.
## 모델에 청록 빛(덧입힌 재질 · 둘레 불빛 · 오르는 불씨). 끝나면 용기는 0(그 상태에서 절기를 썼으면 refund)부터.
## main이 setup(main) → 매 프레임 tick(delta) (weapon.dyn을 넣은 뒤) · 절기 쓸 때 on_ult() · HUD는 hud_info() · --stats는 stats().

const TEAL := Color(0.3, 0.95, 0.78)

var main
var sp: Dictionary            # 장수 데이터 passive
var gauge := 0.0
var active_t := 0.0           # 남은 청룡 상태 시간
var refund := 0.0             # 끝난 뒤 용기 시작값
var last_attacks := 0
var count := 0                # 청룡 상태 들어간 횟수(--stats)
var active_total := 0.0       # 청룡 상태로 지낸 시간(--stats)
var wave_hits := 0
var waves: Array = []         # [{pos, dir, left, node}]
var wave_mesh: ArrayMesh
var wave_mat: StandardMaterial3D
var overlay: StandardMaterial3D
var meshes: Array = []        # 장수 모델의 MeshInstance3D(빛을 덧입힘)
var light: OmniLight3D
var sparks: CPUParticles3D

func setup(m) -> void:
	main = m
	sp = m.hero.passive
	m.weapon.mods.knock *= float(sp.get("knock", 1.0))
	last_attacks = m.weapon.attacks
	wave_mat = StandardMaterial3D.new()
	wave_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wave_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	wave_mat.albedo_color = Color(TEAL, 0.75)
	wave_mesh = m.weapon._arc_mesh(0.2, sp.wave.width * 0.5, deg_to_rad(120.0))   # 짧은 초승달
	overlay = StandardMaterial3D.new()
	overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	overlay.albedo_color = Color(TEAL, 0.0)
	if m.player.model:
		for mi in m.player.model.find_children("*", "MeshInstance3D", true, false):
			meshes.append(mi)
	light = OmniLight3D.new()
	light.light_color = TEAL
	light.omni_range = 5.0
	light.light_energy = 0.0
	light.position = Vector3(0, 1.4, 0)
	m.player.add_child(light)
	sparks = CPUParticles3D.new()
	sparks.amount = 28
	sparks.lifetime = 0.7
	sparks.emitting = false
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.9
	sparks.direction = Vector3.UP
	sparks.spread = 25.0
	sparks.gravity = Vector3(0, 2.0, 0)
	sparks.initial_velocity_min = 0.8
	sparks.initial_velocity_max = 1.8
	var bm := BoxMesh.new()
	bm.size = Vector3(0.09, 0.09, 0.09)
	sparks.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = TEAL
	sparks.material_override = sm
	sparks.position = Vector3(0, 1.0, 0)
	m.player.add_child(sparks)

func is_active() -> bool:
	return active_t > 0.0

func tick(delta: float) -> void:
	var w = main.weapon
	# 이번 프레임 휘두름에서 맞힌 수 → 용기
	if w.attacks != last_attacks:
		last_attacks = w.attacks
		if not is_active():
			gauge += minf(w.swing_hits * sp.per_hit, sp.cap)
			if gauge >= sp.gauge:
				_enter()
		else:
			_spawn_wave(w.swing_dir)
	if is_active():
		active_t -= delta
		active_total += delta
		if active_t <= 0.0:
			_exit()
	var on := is_active()
	w.dyn *= float(sp.dmg) if on else 1.0
	w.haste = float(sp.haste) if on else 1.0
	var want_area: float = float(sp.area) if on else 1.0
	if absf(w.dyn_area - want_area) > 0.001:
		w.dyn_area = want_area
		w.refresh_fx()
	# 빛: 켜질 때 번쩍 → 은은히 일렁임, 끝나기 1초 전부터 깜빡임
	var a := 0.0
	if on:
		a = 0.12 + 0.06 * sin(main.t * 9.0)
		if active_t < 1.0 and fmod(main.t, 0.2) < 0.1:
			a = 0.05
	overlay.albedo_color.a = a
	light.light_energy = a * 12.0
	sparks.emitting = on
	_waves_tick(delta)

func _enter() -> void:
	gauge = sp.gauge
	active_t = sp.dur
	count += 1
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = overlay
	main._banner("청룡의 피가 끓는다!\n범위 · 피해 · 속도 ↑", 1.6)
	print("DRAGON on t=%.1f n=%d" % [main.t, count])

func _exit() -> void:
	active_t = 0.0
	gauge = refund
	refund = 0.0
	for mi in meshes:
		(mi as MeshInstance3D).material_overlay = null

func on_ult() -> void:
	## 청룡 상태에서 절기를 쓰면 끝난 뒤 용기가 refund부터 참.
	if is_active():
		refund = sp.refund

func _spawn_wave(d: Vector2) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = wave_mesh
	mi.material_override = wave_mat.duplicate()
	add_child(mi)
	var c := Vector2(main.player.position.x, main.player.position.z)
	waves.append({"pos": c + d * 0.8, "dir": d, "left": float(sp.wave.length), "node": mi})

func _waves_tick(delta: float) -> void:
	var w = main.weapon
	for k in range(waves.size() - 1, -1, -1):
		var e: Dictionary = waves[k]
		var step: float = sp.wave.speed * delta
		wave_hits += main.horde.hit_line(e.pos, e.dir, step + 0.5, sp.wave.width * 0.5, w.dmg() * sp.wave.dmg, w.knock() * 0.5, main.horde.CH_PASSIVE)
		e.pos += e.dir * step
		e.left -= step
		var node: MeshInstance3D = e.node
		node.position = Vector3(e.pos.x, 0.5, e.pos.y)
		node.rotation.y = atan2(e.dir.x, e.dir.y)
		(node.material_override as StandardMaterial3D).albedo_color.a = clampf(e.left / sp.wave.length, 0.0, 1.0) * 0.75
		if e.left <= 0.0:
			node.queue_free()
			waves.remove_at(k)

func hud_info() -> Dictionary:
	## HUD 장수 칸 막대: 글 · 채움 · 색 · 깜빡임.
	if is_active():
		return {"text": "청룡 %.1f초" % active_t, "f": active_t / sp.dur, "color": TEAL, "pulse": true}
	return {"text": "용기 %d / %d" % [int(gauge), int(sp.gauge)], "f": gauge / sp.gauge, "color": Color(0.2, 0.6, 0.52), "pulse": false}

func stats() -> String:
	return "DRAGON count=%d active=%.0fs wave_hits=%d" % [count, active_total, wave_hits]
