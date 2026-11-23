extends Node3D
## 장수: 불러온 glb 모델을 키보드로 움직이고, 움직이면 walk · 멈추면 idle.
## 모델 앞쪽 = +Z(블렌더 -Y 앞 → glTF 변환). 조작: WASD · 방향키.

const SPEED := 4.0

var model: Node3D
var anim: AnimationPlayer
var auto_walk := false
var _t := 0.0

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
	if dir.length() > 0.01:
		dir = dir.normalized()
		position += dir * SPEED * delta
		# 가는 쪽으로 몸을 돌림(부드럽게)
		var want := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, want, clampf(delta * 12.0, 0, 1))
		_play("walk")
	else:
		_play("idle")
