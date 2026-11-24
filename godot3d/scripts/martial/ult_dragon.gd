extends Ult
## 청룡강림(관우 절기, D-333 · 모델 D-335): 장수 뒤 하늘에서 청룡이 내리꽂혀(내려앉는 자리 둥근 충격) 보는 쪽 직선으로 땅을 훑고 하늘로 올라감.
## 오의 '청룡파천'(spiral > 0, D-335 연출 명세 — 설정화 art/concept/qinglong_skill.webp):
##   1. 하늘에서 장수 자리로 수직 낙하(drop초) — 닿는 순간 포효(아래턱 · 고개) + 화면 흔들림 + 둥근 충격
##   2. 장수 둘레를 아래 → 위 나선으로 spiral_turns바퀴(spiral_time초) — 고리 반지름 spiral_r(관우 키 × 2)
##   3. 몸을 따라 청록 반투명 리본 잔상(dragon_body.gd)
##   4. 머리가 지나는 쪽 부채꼴(반지름 spiral_hit_r = 관우 키 × 3.5)의 잡병을 바깥 + 도는 쪽으로 밀침(horde.hit_swirl)
##   5. 위로 솟구치며 사라짐
## 장수를 따라가야 하므로 ctx.anchor(Node3D, 없으면 origin)를 봄. 화면 흔들림은 ctx.shake(세기, 초)가 있으면.

const DIVE := 0.38            # 청룡강림: 하늘에서 땅까지(초)
const RISE := 0.7             # 하늘로 솟구치는 시간(초)
const ROAR := 0.55            # 포효(아래턱 벌림) 시간
const LIGHT_TEAL := Color(0.4, 1.0, 0.85)
const GOLD := Color(1.0, 0.82, 0.35)

var body: Node3D
var f := Vector2(0, 1)
var o := Vector2.ZERO
var spiral := false
var p_sky := Vector3.ZERO
var p_land := Vector3.ZERO
var run_end := 0.0            # 훑기(또는 나선)가 끝나는 시각
var landed := false
var prev_head := Vector3.ZERO
var rise_from := Vector3.ZERO
var rise_dir := Vector3.UP
var rising := false
var ang0 := 0.0               # 나선 시작 각(XZ, atan2(z, x))
var swirl_sign := 1.0
var hp_now := Vector3.ZERO

func _start() -> void:
	f = ctx.facing
	o = ctx.origin
	spiral = float(p.get("spiral", 0.0)) > 0.0
	body = preload("res://scripts/martial/dragon_body.gd").new()
	add_child(body)
	if spiral:
		var a := _anchor()
		p_land = Vector3(a.x + f.x * 1.2, 1.0, a.y + f.y * 1.2)
		p_sky = p_land + Vector3(0, 16.0, 0)
		ang0 = atan2(f.y, f.x)
		run_end = p.drop + p.spiral_time
	else:
		p_sky = Vector3(o.x - f.x * 3.0, 11.0, o.y - f.y * 3.0)
		p_land = Vector3(o.x + f.x * 1.5, 0.9, o.y + f.y * 1.5)
		run_end = DIVE + p.length / p.speed
	body.start_dir = (p_sky - p_land).normalized()
	prev_head = p_sky
	body.push(p_sky)

func _anchor() -> Vector2:
	var a = ctx.get("anchor")
	if a is Node3D and is_instance_valid(a):
		return Vector2(a.position.x, a.position.z)
	return o

func _land_t() -> float:
	return p.drop if spiral else DIVE

func _head(tt: float) -> Vector3:
	if tt <= _land_t():
		var s := clampf(tt / _land_t(), 0.0, 1.0)
		return p_sky.lerp(p_land, s * s)   # 땅에 가까울수록 빠르게
	if tt <= run_end:
		if spiral:
			var s: float = (tt - p.drop) / p.spiral_time
			var a := _anchor()
			var ang: float = ang0 + TAU * p.spiral_turns * s * swirl_sign
			var r: float = p.spiral_r * clampf(s / 0.12, 0.0, 1.0)   # 내려앉은 자리에서 고리로 벌어짐
			var base := Vector2(p_land.x, p_land.z).lerp(a, clampf(s / 0.12, 0.0, 1.0))
			return Vector3(base.x + cos(ang) * r, lerpf(1.0, 4.2, s), base.y + sin(ang) * r)   # 아래 → 위 나선
		var along: float = p.speed * (tt - DIVE)
		var side := Vector2(-f.y, f.x) * sin(along * 0.55) * 0.8   # 좌우로 굽이치며
		var g := Vector2(p_land.x, p_land.z) + f * along + side
		return Vector3(g.x, 0.9 + 0.25 * sin(along * 0.9), g.y)
	if not rising:
		rising = true
		rise_from = hp_now
		var fw := (hp_now - prev_head)
		fw.y = 0.0
		rise_dir = (fw.normalized() * 0.35 + Vector3.UP).normalized()
	return rise_from + rise_dir * 26.0 * (tt - run_end)

func tick(delta: float) -> bool:
	t += delta
	hp_now = _head(t)
	var hp2 := Vector2(hp_now.x, hp_now.z)
	# 내려앉음: 둥근 충격(+ 오의는 포효 · 화면 흔들림)
	if not landed and t >= _land_t():
		landed = true
		var l2 := Vector2(p_land.x, p_land.z)
		hits += ctx.horde.hit_circle(l2, p.land_r, p.land_dmg * ctx.atk_mul, p.knock, Vector2.ZERO, 9999, l2, ctx.horde.CH_ULT)
		_burst(Vector3(p_land.x, 0.3, p_land.z), LIGHT_TEAL, 50, 6.0)
		_burst(Vector3(p_land.x, 0.3, p_land.z), GOLD, 24, 4.0)
		if spiral:
			var sh = ctx.get("shake")
			if sh is Callable and (sh as Callable).is_valid():
				sh.call(0.45, 0.45)
	if landed and t <= run_end:
		if spiral:   # 머리가 지나는 쪽 부채꼴: 바깥 + 도는 쪽으로
			var a := _anchor()
			var ang := atan2(hp2.y - a.y, hp2.x - a.x)
			hits += ctx.horde.hit_swirl(a, ang, 0.55, p.spiral_hit_r, p.spiral_dmg * ctx.atk_mul, p.knock, p.swirl * swirl_sign, ctx.horde.CH_ULT)
		else:   # 훑기: 이번 프레임에 머리가 지나간 구간
			var pv := Vector2(prev_head.x, prev_head.z)
			var d := hp2 - pv
			if d.length() > 0.001:
				hits += ctx.horde.hit_line(pv, d.normalized(), d.length() + 0.8, p.width * 0.5, p.dmg * ctx.atk_mul, p.knock, ctx.horde.CH_ULT)
	# 몸 · 포효 · 사라짐
	body.roar = clampf(1.0 - (t - p.drop) / ROAR, 0.0, 1.0) if spiral and landed else 0.0
	if t > run_end:
		body.fade = clampf(1.0 - (t - run_end - RISE * 0.35) / (RISE * 0.65), 0.0, 1.0)
	body.push(hp_now)
	body.pose(delta)
	prev_head = hp_now
	return t >= run_end + RISE
