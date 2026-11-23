extends Node3D
## 장수: 불러온 glb 모델을 키보드로 움직이고, 움직이면 walk · 멈추면 idle.
## 모델 앞쪽 = +Z(블렌더 -Y 앞 → glTF 변환). 조작: WASD · 방향키 · 경공 Shift(D-285).

const SPEED := 4.0

var speed_mul := 1.0           # 레벨업 '신속'(D-283)

var model: Node3D
var anim: AnimationPlayer
var auto_walk := false
var _t := 0.0
# 경공(D-285) — 장수 데이터의 qinggong. dash 돌진 · leap 도약(공중에서 한 번 더 = 이단 도약)
var qg: Dictionary = {}
var charges := 0
var charge_t := 0.0           # 다음 충전까지 남은 시간
var dash_t := 0.0             # 남은 경공 시간(0이면 경공 아님)
var dash_dir := Vector3.ZERO
var dash_speed := 0.0
var iframe_t := 0.0           # 경공 무적 남은 시간(main이 피해 계산 때 봄)
var dash_count := 0
var _dash_key_was := false
var _move_dir := Vector3.ZERO

func setup_qinggong(spec: Dictionary) -> void:
	qg = spec
	charges = int(spec.get("charges", 1))

func is_dashing() -> bool:
	return dash_t > 0.0

func facing() -> Vector3:
	return Vector3(sin(rotation.y), 0, cos(rotation.y))

func try_dash(dir: Vector3 = Vector3.ZERO) -> bool:
	## 경공: 충전이 있으면 dir(없으면 가는 쪽 · 보는 쪽)으로. 도약은 공중에서도 한 번 더(이단).
	if qg.is_empty() or charges <= 0:
		return false
	if dash_t > 0.0 and qg.type != "leap":
		return false
	if dir.length() < 0.01:
		dir = _move_dir if _move_dir.length() > 0.01 else facing()
	charges -= 1
	if charge_t <= 0.0:
		charge_t = qg.cd
	dash_dir = dir.normalized()
	dash_t = qg.time
	dash_speed = qg.dist / qg.time
	iframe_t = maxf(iframe_t, qg.iframe)
	rotation.y = atan2(dash_dir.x, dash_dir.z)
	dash_count += 1
	return true

func setup(scene: PackedScene) -> void:
	model = scene.instantiate()
	add_child(model)
	anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		for n in ["idle", "walk"]:
			if anim.has_animation(n):
				anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_play("idle")

func anim_names() -> PackedStringArray:
	return anim.get_animation_list() if anim else PackedStringArray()

func walk_loops() -> bool:
	return anim != null and anim.has_animation("walk") and anim.get_animation("walk").loop_mode == Animation.LOOP_LINEAR

func _play(n: String) -> void:
	if anim and anim.has_animation(n) and anim.current_animation != n:
		anim.play(n, 0.15)

func _process(delta: float) -> void:
	_t += delta
	# 경공 충전 · 무적
	if not qg.is_empty() and charges < int(qg.charges):
		charge_t -= delta
		if charge_t <= 0.0:
			charges += 1
			charge_t = qg.cd if charges < int(qg.charges) else 0.0
	iframe_t = maxf(iframe_t - delta, 0.0)
	if dash_t > 0.0:
		dash_t -= delta
		position += dash_dir * dash_speed * delta
		if qg.type == "leap" and model:   # 도약: 모델을 포물선으로 띄움
			var f: float = 1.0 - maxf(dash_t, 0.0) / qg.time
			model.position.y = qg.height * sin(PI * f)
		if dash_t <= 0.0 and model:
			model.position.y = 0.0
	var dir := Vector3.ZERO
	if auto_walk:
		# 스크린샷용: 처음 0.6초는 서 있고, 그 뒤 원을 그리며 걷는다
		if _t > 0.6:
			var a := (_t - 0.6) * 0.9
			dir = Vector3(cos(a), 0, -sin(a))
	else:
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): dir.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): dir.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): dir.z -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): dir.z += 1
		var dk := Input.is_physical_key_pressed(MartialRules.KEY_DASH)
		if dk and not _dash_key_was:
			try_dash(dir)
		_dash_key_was = dk
	_move_dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	if dash_t > 0.0:
		_play("walk")
		return
	if dir.length() > 0.01:
		dir = dir.normalized()
		position += dir * SPEED * speed_mul * delta
		# 가는 쪽으로 몸을 돌림(부드럽게)
		var want := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(delta * 12.0, 0, 1))
		_play("walk")
	else:
		_play("idle")
