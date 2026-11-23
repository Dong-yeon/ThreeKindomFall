class_name Neigong
extends RefCounted
## 내공(D-285): 공격 · 처치로 차고 절기에 씀. 가득 찬 채로 계속 차면 넘쳐서 주화입마(data/martial.gd).

var value := 0.0
var overflow := 0.0
var zhuhuo_t := 0.0
var zhuhuo_count := 0
var just_entered := false     # 이번 프레임에 주화입마에 들어감(알림용)

var pending := 0.0            # 아직 안 채운 내공(한 프레임에 몰려 들어온 몫 — 초당 상한 속도로 흘려 넣음)

func gain(amount: float, delta: float) -> void:
	if zhuhuo_t > 0.0:
		pending = 0.0
		return
	pending = minf(pending + maxf(amount, 0.0), MartialRules.NEIGONG_MAX)   # 너무 많이 쌓이진 않게
	var add := minf(pending, MartialRules.MAX_GAIN_PER_SEC * delta)
	pending -= add
	if add <= 0.0:
		return
	value += add
	if value > MartialRules.NEIGONG_MAX:
		overflow += value - MartialRules.NEIGONG_MAX
		value = MartialRules.NEIGONG_MAX
		if overflow >= MartialRules.OVERFLOW_LIMIT:
			zhuhuo_t = MartialRules.ZHUHUO_TIME
			zhuhuo_count += 1
			overflow = 0.0
			just_entered = true

func tick(delta: float) -> float:
	## 돌려주는 값 = 이번 프레임 체력 감소량(주화입마 중).
	overflow = maxf(overflow - MartialRules.OVERFLOW_DECAY * delta, 0.0)
	if zhuhuo_t > 0.0:
		zhuhuo_t -= delta
		if zhuhuo_t <= 0.0:
			value = MartialRules.AFTER
		return MartialRules.ZHUHUO_DRAIN * delta
	return 0.0

func atk_mul() -> float:
	return MartialRules.ZHUHUO_ATK if zhuhuo_t > 0.0 else 1.0

func can_spend(cost: float) -> bool:
	return value >= cost

func spend(cost: float) -> void:
	value -= cost
	overflow = 0.0
	zhuhuo_t = 0.0            # 절기를 쓰면 주화입마가 풀림
