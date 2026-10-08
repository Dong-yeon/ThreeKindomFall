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
	var font := ThemeDB.fallback_font
	for f in b.fx:
		var p: Vector2 = f.pos
		if not V.has_point(p):
			continue
		var t: float = f.t
		match f.k:
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
