class_name FlowField
extends RefCounted
## 길찾기(웹판 fdGridBuild · fdField · fdClear · fdPath): 20px 칸. 벽·물 칸은 막고,
## 목표까지의 칸 거리를 BFS로 채운 흐름장을 목표마다 하나씩 둔다.
## 가는 길이 트였으면 곧장, 막혔으면 흐름을 따라 문·다리로 돌아간다. 문이 열리면(ver가 바뀌면) 다시 계산.

const CELL := 20.0

var gw := 0
var gh := 0
var blk := PackedByteArray()
var ver := -1
## 키 → {"src": 목표 칸, "d": 칸 거리(-1 = 못 감), "at": 계산한 때}
var fields := {}


func build(obs: Array, w: float, h: float, version: int) -> void:
	gw = ceili(w / CELL)
	gh = ceili(h / CELL)
	blk = PackedByteArray()
	blk.resize(gw * gh)
	blk.fill(0)
	for o in obs:
		if o.k != "wall" and o.k != "water":
			continue
		var rc: Rect2 = o.rect
		var x0 := maxi(0, floori((rc.position.x - 4) / CELL))
		var x1 := mini(gw - 1, floori((rc.end.x + 3) / CELL))
		var y0 := maxi(0, floori((rc.position.y - 4) / CELL))
		var y1 := mini(gh - 1, floori((rc.end.y + 3) / CELL))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				blk[y * gw + x] = 1
	ver = version
	fields.clear()


func cell_of(p: Vector2) -> int:
	var cx := clampi(floori(p.x / CELL), 0, gw - 1)
	var cy := clampi(floori(p.y / CELL), 0, gh - 1)
	return cy * gw + cx


## 목표 칸에서 퍼져 나가는 칸 거리. 같은 칸이면 그대로 쓰고, 'p'(장수)는 0.2초에 한 번만 다시 계산.
func field(key: String, target: Vector2, now: float, throttle := 0.0) -> Dictionary:
	var src := cell_of(target)
	var f: Dictionary = fields.get(key, {})
	if not f.is_empty():
		if f.src == src:
			return f
		if throttle > 0.0 and now - float(f.at) < throttle:
			return f
	var n := gw * gh
	var d := PackedInt32Array()
	d.resize(n)
	d.fill(-1)
	var q := PackedInt32Array()
	q.resize(n)
	var head := 0
	var tail := 0
	d[src] = 0
	q[tail] = src
	tail += 1
	while head < tail:
		var c := q[head]
		head += 1
		var x := c % gw
		var dc := d[c] + 1
		if x > 0 and d[c - 1] < 0 and blk[c - 1] == 0:
			d[c - 1] = dc
			q[tail] = c - 1
			tail += 1
		if x < gw - 1 and d[c + 1] < 0 and blk[c + 1] == 0:
			d[c + 1] = dc
			q[tail] = c + 1
			tail += 1
		if c >= gw and d[c - gw] < 0 and blk[c - gw] == 0:
			d[c - gw] = dc
			q[tail] = c - gw
			tail += 1
		if c < n - gw and d[c + gw] < 0 and blk[c + gw] == 0:
			d[c + gw] = dc
			q[tail] = c + gw
			tail += 1
	f = {"src": src, "d": d, "at": now}
	fields[key] = f
	return f


## 두 점 사이가 막힌 칸 없이 트였는지(반 칸 간격 표본). 출발 칸은 안 봄(벽에 붙어 막힌 칸에 서 있어도 됨).
func clear(a: Vector2, b: Vector2) -> bool:
	var start := cell_of(a)
	var n := ceili(a.distance_to(b) / (CELL * 0.5))
	for i in range(1, n):
		var p := a.lerp(b, float(i) / n)
		var x := floori(p.x / CELL)
		var y := floori(p.y / CELL)
		if x >= 0 and y >= 0 and x < gw and y < gh and blk[y * gw + x] == 1 and y * gw + x != start:
			return false
	return true


## 흐름을 따라 최대 3칸 내려간 칸의 가운데. 흐름장 밖이면 null.
## 경유점까지 곧게 갈 수 있는 가장 먼 칸을 고름 — 멀리 잡으면 모서리에서 벽 너머를 가리켜 벽에 붙어 버림.
## 벽에 붙어 '막힌 칸'(벽을 4px 넓혀 막으므로 벽 옆 칸도 막힘)에 서 있으면 둘레 8칸 중 가장 가까운 칸에서 이어 감
## — 웹판은 여기서 곧장 가려다 벽 앞에서 오락가락했음.
func descend(from: Vector2, f: Dictionary) -> Variant:
	var d: PackedInt32Array = f.d
	var c := cell_of(from)
	if d[c] < 0:
		var cx := c % gw
		var cy := c / gw
		var best := -1
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				var x := cx + ox
				var y := cy + oy
				if x < 0 or y < 0 or x >= gw or y >= gh:
					continue
				var nc := y * gw + x
				if d[nc] >= 0 and (best < 0 or d[nc] < d[best]):
					best = nc
		if best < 0:
			return null
		c = best
	var path: Array[int] = [c]
	for _s in 3:
		var x := c % gw
		var best := c
		for o in [-1, 1, -gw, gw]:
			var nc: int = c + o
			if (o == -1 and x == 0) or (o == 1 and x == gw - 1) or nc < 0 or nc >= d.size():
				continue
			if d[nc] >= 0 and d[nc] < d[best]:
				best = nc
		if best == c:
			break
		c = best
		path.append(c)
	for k in range(path.size() - 1, 0, -1):
		var p := _center(path[k])
		if clear(from, p):
			return p
	# 곧게 갈 수 있는 칸이 없으면 바로 다음 칸(막힌 칸에 서 있었으면 빠져나갈 이웃 칸)
	return _center(path[1] if path.size() > 1 and d[cell_of(from)] >= 0 else path[0])


func _center(c: int) -> Vector2:
	return Vector2((c % gw + 0.5) * CELL, (c / gw + 0.5) * CELL)
