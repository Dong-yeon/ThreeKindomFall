extends Node2D
## 장수의 날아가는 기본 공격 · 적 탄 · 베기 궤적 · 불꽃 · 고리 · 숫자 등 잠깐 나오는 그림(웹판 muFx · h_boot fx). 인물들 위에 그린다.

@onready var b: Battle = get_parent()


func _draw() -> void:
	var V := b.view.grow(60)
	for s in b.shots:
		var p: Vector2 = s.pos
		if not V.has_point(p):
			continue
		draw_circle(p, s.r, s.c)
		draw_circle(p, s.r, Color("7a1a0a"), false, 1.5)
	for bl in b.blades:
		var p: Vector2 = bl.pos
		if V.has_point(p):
			_crescent(bl)
	_tactics(V)
	var font := ThemeDB.fallback_font
	for f in b.fx:
		var p: Vector2 = f.pos
		if not V.has_point(p):
			continue
		var t: float = f.t
		match f.k:
			"rain":
				# 화살비가 떨어진 자리: 짧은 화살 줄 + 고리
				var r: float = f.r
				var al := clampf(t / 0.3, 0, 1)
				for i in 7:
					var o := Vector2(cos(i * 2.4) * r * 0.7, sin(i * 1.7) * r * 0.5)
					draw_line(p + o + Vector2(-3, -14 * al - 4), p + o, Color(0.85, 0.78, 0.55, al), 1.5)
				draw_arc(p, r, 0, TAU, 28, Color(0.85, 0.78, 0.55, al * 0.8), 1.5)
			"sky":
				# 벼락: 위에서 지그재그로 내려꽂힘
				var al := clampf(t / 0.25, 0, 1)
				var pts := PackedVector2Array()
				for i in 7:
					pts.append(p + Vector2((7 if i % 2 else -7) * (1 - i / 6.0), -150 + i * 25))
				draw_polyline(pts, Color(1, 0.95, 0.55, al), 3)
				draw_circle(p, 16 * al + 4, Color(1, 0.95, 0.6, 0.45 * al))
			"chain":
				var al := clampf(t / 0.2, 0, 1)
				var q: Vector2 = f.pos2
				var mid := (p + q) / 2 + (q - p).orthogonal().normalized() * 8
				draw_polyline(PackedVector2Array([p, mid, q]), Color(1, 0.95, 0.55, al), 2)
			"slash":
				var c: Color = f.c
				var a: float = f.a
				var arc: float = minf(f.arc, TAU)
				var rad: float = f.r
				c.a = minf(1.0, t * 6)
				draw_arc(p, rad * 0.8, a - arc / 2, a + arc / 2, 24, c, 10.0 * t / 0.2 + 2)
				var c2: Color = f.c2
				c2.a = minf(1.0, t * 6) * 0.8
				draw_arc(p, rad, a - arc / 2, a + arc / 2, 24, c2, 3)
			"spark":
				var c: Color = f.c
				c.a = minf(1.0, t * 7)
				for i in range(-1, 2):
					var a: float = f.a + i * 0.6
					var r0 := 3 + (0.18 - t) * 40
					var d := Vector2.from_angle(a)
					draw_line(p + d * r0, p + d * (r0 + 7), c, 2)
			"ring":
				var c: Color = f.c
				c.a = clampf(t * 2.5, 0, 1)
				draw_arc(p, float(f.r) * (1.2 - t), 0, TAU, 40, c, 3)
			"burst":
				var c: Color = f.c
				c.a = clampf(t * 2, 0, 1)
				for i in 8:
					var a := i / 8.0 * TAU
					draw_circle(p + Vector2.from_angle(a) * (float(f.r) + (0.45 - t) * 70), 3, c)
			"puff":
				draw_circle(p, 4 + (0.2 - t) * 30, Color(0.35, 0.29, 0.21, clampf(t * 4, 0, 1)), false, 1.5)
			"shot":
				draw_line(p, f.pos2, Color(0.91, 0.88, 0.78, minf(1.0, t * 8)), 1.5)
			"num":
				var c: Color = f.c
				c.a = minf(1.0, t * 2)
				var at := p + Vector2(-40, -(0.7 - t) * 30)
				draw_string_outline(font, at, f.v, HORIZONTAL_ALIGNMENT_CENTER, 80, 12, 3, Color(0.11, 0.09, 0.07, c.a))
				draw_string(font, at, f.v, HORIZONTAL_ALIGNMENT_CENTER, 80, 12, c)


## 반달 참격(D-171): 날아가는 쪽으로 휜 반달. 가운데가 두껍고 끝이 뾰족함. 몸 높이(발밑 10px 위)에 그리고 끝에 가까울수록 흐려짐.
func _crescent(bl: Dictionary) -> void:
	var dir: Vector2 = bl.dir
	var side := dir.orthogonal()
	var at: Vector2 = bl.pos + Vector2(0, -10)
	var hw: float = bl.hw
	var bulge: float = bl.bulge
	var thick: float = bl.thick
	var fade := clampf((float(bl.reach) - float(bl.travel)) / (float(bl.reach) * 0.25), 0.0, 1.0)
	var pts := PackedVector2Array()
	var glow := PackedVector2Array()
	const N := 12
	for k in N + 1:
		var t := -1.0 + 2.0 * k / N
		var s := 1.0 - t * t
		pts.append(at + dir * (bulge * s) + side * (t * hw))
		glow.append(at + dir * ((bulge + 5) * s) + side * (t * (hw + 5)))
	for k in range(N - 1, 0, -1):
		var t := -1.0 + 2.0 * k / N
		var s := 1.0 - t * t
		pts.append(at + dir * ((bulge - thick) * s) + side * (t * hw))
		glow.append(at + dir * ((bulge - thick - 3) * s) + side * (t * (hw + 5)))
	var c: Color = bl.c
	var c2: Color = bl.c2
	draw_colored_polygon(glow, Color(c2, 0.35 * fade))
	draw_colored_polygon(pts, Color(c, 0.92 * fade))
	pts.append(pts[0])
	draw_polyline(pts, Color(c2, fade), 1.5)


## 책략: 회전 언월 칼날 · 연노 화살 · 비도 · 날아가는 진천뢰(바닥의 화살비 표시 · 불길은 ground.gd)
func _tactics(V: Rect2) -> void:
	var T := b.tactics
	if T == null:
		return
	var ev := T.evolved("orbit")
	var i := 0
	for p in T.orbit_blades():
		var dir := Vector2.from_angle(T.orb_a + i * 1.7 + PI / 2)
		_mini_crescent(p + Vector2(0, -8), dir, 11.0 if ev else 9.0, Color("d8f8e4") if ev else Color("bfe0cc"), Color("2a6a4a"))
		i += 1
	for s in T.darts:
		var p: Vector2 = s.pos
		if not V.has_point(p):
			continue
		var d: Vector2 = s.dir
		var at := p + Vector2(0, -8)
		if s.k == "xbow":
			draw_line(at - d * 12, at, Color("5a3a1a"), 2.0)
			draw_colored_polygon(PackedVector2Array([at + d * 4, at - d * 2 + d.orthogonal() * 3, at - d * 2 - d.orthogonal() * 3]), Color("e8e0c8"))
		else:
			var o := d.orthogonal()
			var pts := PackedVector2Array([at + d * 7, at + o * 2.5, at - d * 5, at - o * 2.5])
			draw_colored_polygon(pts, Color("d8e0e8"))
			pts.append(pts[0])
			draw_polyline(pts, Color("3a4450"), 1.0)
	for m in T.bombs:
		var k: float = clampf(m.t / m.T, 0, 1)
		var fr: Vector2 = m.from
		var g := fr.lerp(m.to, k)
		var at := g + Vector2(0, -sin(k * PI) * 60 - 8)
		draw_circle(g, 5, Color(0, 0, 0, 0.25))
		draw_circle(at, 6, Color("3a3028"))
		draw_circle(at, 6, Color("1d1813"), false, 1.5)
		draw_circle(at + Vector2(3, -6), 2.5 + randf(), Color("ffd060"))


func _mini_crescent(at: Vector2, dir: Vector2, hw: float, c: Color, c2: Color) -> void:
	var side := dir.orthogonal()
	var pts := PackedVector2Array()
	const N := 6
	for k in N + 1:
		var t := -1.0 + 2.0 * k / N
		pts.append(at + dir * (5.0 * (1 - t * t)) + side * (t * hw))
	for k in range(N - 1, 0, -1):
		var t := -1.0 + 2.0 * k / N
		pts.append(at + dir * (1.0 * (1 - t * t)) + side * (t * hw))
	draw_colored_polygon(pts, c)
	pts.append(pts[0])
	draw_polyline(pts, c2, 1.0)
