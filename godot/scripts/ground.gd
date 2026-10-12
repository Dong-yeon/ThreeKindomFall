extends Node2D
## 바닥 · 강 · 다리 · 본진 · 진영 · 장각 본진 담 · 관문 · 주울 것. 바닥은 일단 단색(B.B.Bits 타일셋을 사면 바꿈, D-169).

const GRASS := Color("5b7a3e")
const INK := Color(0.11, 0.09, 0.07, 0.85)

@onready var b: Battle = get_parent()


func _draw() -> void:
	Perf.begin(&"그리기:바닥")
	_draw_impl()
	Perf.end()


func _draw_impl() -> void:
	var V := b.view.grow(40)
	draw_rect(Rect2(0, 0, Stage1.W, Stage1.H), GRASS)
	_river(V)
	_home(V)
	_camps(V)
	for o in b.obs:
		var rc: Rect2 = o.rect
		if o.k == "water" or not V.intersects(rc):
			continue
		_stone(rc, o.door != "")
	var K := b.keep_rect()
	if V.intersects(K.grow(30)):
		draw_rect(K.grow(-12), Color(0.85, 0.44, 0.37, 0.12))
		_label("장각 본진" if b.keep_open else "장각 본진(닫힘)", Vector2(K.get_center().x, K.position.y - 14), Color("ffb0a0"))
	_tactics_ground(V)
	for dr in b.drops:
		var p: Vector2 = dr.pos
		if dr.get("k", "bun") == "magnet":
			# 자석: 빨강 말굽 + 은빛 끝
			var bob := sin(b.t * 5) * 2
			draw_arc(p + Vector2(0, bob), 7, PI, TAU, 12, Color("d03a2a"), 4)
			draw_line(p + Vector2(-7, bob), p + Vector2(-7, bob + 6), Color("d03a2a"), 4)
			draw_line(p + Vector2(7, bob), p + Vector2(7, bob + 6), Color("d03a2a"), 4)
			draw_rect(Rect2(p + Vector2(-9, bob + 5), Vector2(4, 3)), Color("e8e8f0"))
			draw_rect(Rect2(p + Vector2(5, bob + 5), Vector2(4, 3)), Color("e8e8f0"))
			continue
		draw_circle(p, 6, Color("f4ecd8"))
		draw_circle(p, 6, Color("8a6a3a"), false, 1.5)
		draw_line(p + Vector2(-3, -1), p + Vector2(3, -1), Color("c8a874"), 1.0)
	# 경험 구슬: 값이 클수록 크고 색이 바뀜(1 파랑 · 2~4 초록 · 10 이상 금)
	for o in b.orbs:
		var p: Vector2 = o.pos
		if not V.has_point(p):
			continue
		var v: float = o.v
		var s := 3.0 if v < 2 else (4.0 if v < 10 else 6.0)
		var c := Color("6ac0e0") if v < 2 else (Color("7ad870") if v < 10 else Color("f0c040"))
		var dia := PackedVector2Array([p + Vector2(0, -s - 1), p + Vector2(s, 0), p + Vector2(0, s), p + Vector2(-s, 0)])
		draw_colored_polygon(dia, c)
		dia.append(dia[0])
		draw_polyline(dia, Color(0.11, 0.09, 0.07, 0.7), 1.0)


func _river(V: Rect2) -> void:
	var R: Dictionary = Stage1.RIVER
	var y0: float = R.y0
	var y1: float = R.y1
	if y1 < V.position.y or y0 > V.end.y:
		return
	draw_rect(Rect2(0, y0, Stage1.W, y1 - y0), Color("4a7ab8"))
	for i in 40:
		var x := fmod(i * 97 + b.t * 18, Stage1.W)
		var y := y0 + 10 + (i * 37) % int(y1 - y0 - 20)
		draw_line(Vector2(x, y), Vector2(x + 14, y), Color(0.81, 0.89, 0.96, 0.6), 1.5)
	draw_rect(Rect2(0, y0, Stage1.W, 3), Color("3a5a90"))
	for br in R.bridges:
		var a: float = br.x
		var c: float = br.y
		draw_rect(Rect2(a, y0 - 6, c - a, y1 - y0 + 12), Color("8a6a3a"))
		var y := y0 - 4
		while y < y1 + 4:
			draw_rect(Rect2(a + 3, y, c - a - 6, 5), Color("a8845a"))
			y += 8
		draw_rect(Rect2(a, y0 - 6, 4, y1 - y0 + 12), Color("5a3a1a"))
		draw_rect(Rect2(c - 4, y0 - 6, 4, y1 - y0 + 12), Color("5a3a1a"))


func _home(V: Rect2) -> void:
	var H := b.home_pos
	if H.y - 120 > V.end.y:
		return
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(H + Vector2(cos(a) * (b.home_r + 30), sin(a) * (b.home_r + 6)))
	draw_colored_polygon(pts, Color(0.78, 0.66, 0.45, 0.55))
	for d in [Vector2(-48, -6), Vector2(0, -20), Vector2(48, -6)]:
		_tent(H + d, Color("e8e0d0"), Color("4a7ab8"))
	_flag(H + Vector2(-70, -30), Color("4a7ab8"), "劉")
	_flag(H + Vector2(70, -30), Color("4a7ab8"), b.hero_data.flag_glyph)
	_label(Stage1.HOME.n, H + Vector2(0, 30), Color("cfe2f4"))
	if b.home_hp < b.home_max:
		_bar(H + Vector2(0, -50), 80, b.home_hp / b.home_max, Color("4a7ab8"))


func _camps(V: Rect2) -> void:
	for c in b.camps:
		var R := b.camp_rect(c)
		if not V.intersects(R.grow(40)):
			continue
		var cap: bool = c.cap
		draw_rect(R, Color(0.63, 0.75, 0.86, 0.25) if cap else Color(0.59, 0.43, 0.24, 0.3))
		var p: Vector2 = c.pos
		for d in [Vector2(-70, -40), Vector2(60, -45), Vector2(-60, 30), Vector2(70, 25)]:
			_tent(p + d, Color("e8e0d0") if cap else Color("d8b860"), Color("4a7ab8") if cap else Color("a8782a"))
		_flag(p + Vector2(0, -10), Color("4a7ab8") if cap else Color("d8b040"), b.hero_data.flag_glyph if cap else "黃")
		var total: int = c.bks.size()
		var what: String = String(c.ln) if c.lead != null else ("막사·탑 %d/%d" % [total - b.buildings_left(c), total])
		var txt: String = ("%s — 점령" % c.n) if cap else ("%s · %s" % [c.n, what])
		_label(txt, Vector2(p.x, R.position.y - 14), Color("cfe2f4") if cap else Color("ffd8a0"))


func _tent(p: Vector2, cl: Color, rf: Color) -> void:
	draw_rect(Rect2(p.x - 15, p.y + 10, 30, 4), Color(0, 0, 0, 0.2))
	var tri := PackedVector2Array([p + Vector2(0, -16), p + Vector2(16, 10), p + Vector2(-16, 10)])
	draw_colored_polygon(tri, cl)
	tri.append(tri[0])
	draw_polyline(tri, rf, 2)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -2), p + Vector2(5, 10), p + Vector2(-5, 10)]), Color("3a2a1a"))


func _flag(p: Vector2, col: Color, glyph: String) -> void:
	draw_rect(Rect2(p.x - 1.5, p.y - 34, 3, 40), Color("5a3a1a"))
	var wv := sin(b.t * 4 + p.x) * 2
	draw_colored_polygon(PackedVector2Array([p + Vector2(1.5, -34), p + Vector2(24, -31 + wv), p + Vector2(24, -15 + wv), p + Vector2(1.5, -18)]), col)
	draw_string(Fonts.small(), p + Vector2(2, -21 + wv * 0.5), glyph, HORIZONTAL_ALIGNMENT_CENTER, 20, 10, Color("fffaf0"))


func _stone(o: Rect2, door: bool) -> void:
	draw_rect(o, Color("7a4a24") if door else Color("8a8478"))
	draw_rect(o, Color("3a2410") if door else Color("5a564c"), false, 1.5)
	if door:
		draw_rect(Rect2(o.get_center().x - 2, o.position.y + 2, 4, o.size.y - 4), Color("c8a050"))
		return
	var horiz := o.size.x >= o.size.y
	var s := 14.0
	while s < (o.size.x if horiz else o.size.y):
		if horiz:
			draw_line(Vector2(o.position.x + s, o.position.y), Vector2(o.position.x + s, o.end.y), Color(0.24, 0.22, 0.19, 0.6), 1)
		else:
			draw_line(Vector2(o.position.x, o.position.y + s), Vector2(o.end.x, o.position.y + s), Color(0.24, 0.22, 0.19, 0.6), 1)
		s += 14


func _label(s: String, at: Vector2, col: Color) -> void:
	var font := Fonts.small()
	var pos := at + Vector2(-150, 4)
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, 300, 10, 3, INK)
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, 300, 10, col)


func _bar(at: Vector2, w: float, frac: float, col: Color) -> void:
	draw_rect(Rect2(at.x - w / 2, at.y, w, 5), Color("3a3024"))
	draw_rect(Rect2(at.x - w / 2, at.y, w * clampf(frac, 0, 1), 5), col)


## 책략의 바닥 그림: 화계 불길(일렁임) · 화살비 떨어질 자리(좁아지는 고리)
func _tactics_ground(V: Rect2) -> void:
	var T := b.tactics
	if T == null:
		return
	for f in T.fires:
		var p: Vector2 = f.pos
		var r: float = f.r
		if not V.grow(r).has_point(p):
			continue
		var al := clampf(float(f.t) / 0.4, 0, 1)
		draw_circle(p, r, Color(0.88, 0.4, 0.15, 0.28 * al))
		for i in 5:
			var a := b.t * 3.0 + i * 1.3
			var q := p + Vector2(cos(a) * r * 0.5, sin(a * 1.3) * r * 0.35)
			draw_circle(q, r * (0.22 + 0.06 * sin(b.t * 9 + i)), Color(1.0, 0.62, 0.2, 0.45 * al))
		draw_arc(p, r, 0, TAU, 28, Color(0.9, 0.35, 0.1, 0.6 * al), 1.5)
	for w in T.warns:
		var p: Vector2 = w.pos
		var r: float = w.r
		if not V.grow(r).has_point(p):
			continue
		var k := 1.0 - clampf(float(w.t) / float(w.T), 0, 1)
		draw_circle(p, r, Color(0.85, 0.35, 0.25, 0.12 + 0.12 * k))
		draw_arc(p, r * (1.0 - 0.6 * k) + 4, 0, TAU, 28, Color(0.9, 0.4, 0.3, 0.7), 1.5)
