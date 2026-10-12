class_name Perf
## 성능 측정(D-198): 봇 옵션 --perf일 때만 켜짐(꺼져 있으면 begin/end가 바로 돌아감).
## 구간은 겹치지 않게 잼 — 안쪽 구간(예: 적 움직임 안의 길찾기 · 충돌)은 바깥에서 빼고 따로 셈.
## 프레임마다 구간별 마이크로초를 모아 두고, 봇이 판이 끝날 때 '적이 가장 많던 순간'과 전체를 정리해 출력.

static var on := false
static var acc := {}
static var frames: Array[Dictionary] = []
static var _stack: Array = []


static func begin(name: StringName) -> void:
	if not on:
		return
	_stack.append([name, Time.get_ticks_usec(), 0])


static func end() -> void:
	if not on or _stack.is_empty():
		return
	var e: Array = _stack.pop_back()
	var el: int = Time.get_ticks_usec() - int(e[1])
	acc[e[0]] = int(acc.get(e[0], 0)) + el - int(e[2])
	if not _stack.is_empty():
		_stack[-1][2] = int(_stack[-1][2]) + el


## 한 프레임을 닫음(봇이 매 프레임 부름). extra = 적 수 · 시간 · 렌더 시간 등
static func frame(extra: Dictionary) -> void:
	if not on:
		return
	var f := acc.duplicate()
	f.merge(extra)
	frames.append(f)
	acc.clear()
