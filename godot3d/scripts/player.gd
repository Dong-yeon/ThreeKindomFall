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
var final := false            # 판 끝 개그 동작 중(D-313)
var blinked := false          # 이번 프레임에 축지했는가(main이 효과를 그리고 끔)
var landed := false           # 이번 프레임에 도약이 내려앉았는가(용약 충격파 — main이 쓰고 끔, D-333)
var _dash_key_was := false
var _move_dir := Vector3.ZERO
var has_goal := false          # 봇(D-289): 목표 자리로 가서 그 둘레를 돎(진영 정예와 싸우기)
var goal := Vector3.ZERO
var orbit_r := 4.0             # 목표 둘레를 도는 반지름(보스전은 main이 키움)
var goal_direct := false       # 목표 위로 곧장(상자 줍기) — 아니면 둘레를 돎

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
	if qg.type == "blink":   # 축지(D-295): 순간이동 — 경공 시간 없이 곧바로 그 자리로
		position += dash_dir * qg.dist
		iframe_t = maxf(iframe_t, qg.iframe)
		rotation.y = atan2(dash_dir.x, dash_dir.z)
		dash_count += 1
		blinked = true
		return true
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
	if final:   # 쓰러짐 · 승리 동작 뒤엔 걷기 · 서기로 안 바꿈
		return
	if anim and anim.has_animation(n) and anim.current_animation != n:
		anim.play(n, 0.15)

func play_final(n: String) -> void:
	## 판 끝 개그 동작(D-313): 쓰러질 때 down(마지막 모습 유지) · 승리할 때 cheer(반복). 모델에 없으면 아무 일 없음.
	if anim == null or not anim.has_animation(n):
		return
	final = true
	anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR if n == "cheer" else Animation.LOOP_NONE
	anim.play(n, 0.1)

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
		if dash_t <= 0.0:
			if model:
				model.position.y = 0.0
			if qg.type == "leap":
				landed = true
	var dir := Vector3.ZERO
	if auto_walk:
		# 스크린샷용: 처음 0.6초는 서 있고, 그 뒤 원을 그리며 걷는다
		if has_goal:
			var to := goal - Vector3(position.x, 0, position.z)
			var d := to.length()
			if d > 6.0 or (goal_direct and d > 0.3):
				dir = to / d
			elif d > 0.01:   # 목표 둘레를 반지름 4쯤으로 돎
				dir = (Vector3(-to.z, 0, to.x) / d + to / d * (d - orbit_r) * 0.4).normalized()
		elif _t > 0.6:
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
