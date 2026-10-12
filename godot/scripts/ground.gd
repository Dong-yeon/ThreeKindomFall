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
	_village(V)
	_camps(V)
	for o in b.obs:
		var rc: Rect2 = o.rect
		if o.k == "water" or not V.intersects(rc):
			continue
		if o.door == "gate" and b.gate_t >= 0:
			_gate_leaves(rc, b.gate_t / float(Stage1.GATE.open))
		else:
			_stone(rc, o.door != "")
	var K := b.keep_rect()
	if V.intersects(K.grow(30)):
		draw_rect(K.grow(-12), Color(0.85, 0.44, 0.37, 0.12))
		_label("장각 본진" if b.keep_open else "장각 본진(닫힘)", Vector2(K.get_center().x, K.position.y - 14), Color("ffb0a0"))
	_tactics_ground(V)
	_altar_beams(V)
	_beast(V)
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
		if dr.k == "chest":
			# 보급 상자(D-205): 나무 상자 + 금빛 띠, 둘레가 반짝임
			var bob := sin(b.t * 4) * 2
			var q := p + Vector2(0, bob)
			draw_circle(p + Vector2(0, 9), 11, Color(0, 0, 0, 0.2))
			draw_arc(q, 17 + sin(b.t * 6) * 2, 0, TAU, 32, Color(0.94, 0.75, 0.25, 0.55), 2)
			draw_rect(Rect2(q + Vector2(-11, -7), Vector2(22, 15)), Color("8a5a2a"))
			draw_rect(Rect2(q + Vector2(-11, -10), Vector2(22, 5)), Color("a8743a"))
			draw_rect(Rect2(q + Vector2(-11, -10), Vector2(22, 18)), Color("4a2a10"), false, 1.5)
			draw_rect(Rect2(q + Vector2(-2, -10), Vector2(4, 18)), Color("f0c040"))
			draw_rect(Rect2(q + Vector2(-3, -4), Vector2(6, 5)), Color("fff2c0"))
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
		var total: int = c.tws.size()
		var left := b.towers_left(c)
		var what: String = String(c.ln) if left == 0 else ("수비탑 %d/%d" % [total - left, total])
		var txt: String = ("%s — 점령" % c.n) if cap else ("%s · %s" % [c.n, what])
		_label(txt, Vector2(p.x, R.position.y - 14), Color("cfe2f4") if cap else Color("ffd8a0"))


## 탁현 마을(D-208): 초가집 셋. 습격 중엔 지붕에 불길 · 빨간 고리가 깜빡이고 남은 시간 막대, 불타면 검게 그을림
func _village(V: Rect2) -> void:
	var VL: Dictionary = Stage1.VILLAGE
	var p: Vector2 = VL.pos
	if not V.intersects(Rect2(p - Vector2(90, 90), Vector2(180, 180))):
		return
	var raid := b.vil_st == "raid"
	var lost := b.vil_st == "lost"
	var i := 0
	for d in [Vector2(-26, -14), Vector2(22, -20), Vector2(0, 18)]:
		var q: Vector2 = p + d
		draw_rect(Rect2(q.x - 13, q.y + 8, 26, 4), Color(0, 0, 0, 0.2))
		draw_rect(Rect2(q.x - 12, q.y - 4, 24, 13), Color("4a4038") if lost else Color("d8c8a0"))
		draw_rect(Rect2(q.x - 12, q.y - 4, 24, 13), INK, false, 1.0)
		draw_rect(Rect2(q.x - 3, q.y + 1, 6, 8), Color("3a2a1a"))
		var roof := PackedVector2Array([q + Vector2(-16, -3), q + Vector2(16, -3), q + Vector2(10, -14), q + Vector2(-10, -14)])
		draw_colored_polygon(roof, Color("2a2420") if lost else Color("c8a050"))
		roof.append(roof[0])
		draw_polyline(roof, INK, 1.0)
		if raid:
			var fl := sin(b.t * 9 + i * 2.1) * 2
			draw_colored_polygon(PackedVector2Array([q + Vector2(-6, -12), q + Vector2(6, -12), q + Vector2(fl, -26)]), Color(0.95, 0.5, 0.15, 0.85))
			draw_colored_polygon(PackedVector2Array([q + Vector2(-3, -12), q + Vector2(3, -12), q + Vector2(fl * 0.5, -19)]), Color(1, 0.9, 0.45))
		i += 1
	if raid:
		if int(b.t * 3) % 2 == 1:
			draw_arc(p, float(VL.r) + 10, 0, TAU, 40, Color(0.85, 0.31, 0.24, 0.8), 2)
		_bar(p + Vector2(0, -48), 70, b.vil_t / float(VL.limit), Color("d9705e"))
	var txt: String = VL.n
	if lost:
		txt += "(불탐)"
	elif b.vil_st == "saved":
		txt += " — 구함"
	_label(txt, p + Vector2(0, 40), Color("ffb0a0") if raid else (Color("a8a098") if lost else Color("fff2c0")))


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


## 요술 제단 → 장각 빛줄기(D-207): 장각이 보호막인 동안 남은 제단마다(제단 · 장각 노드는 화면 근처에서만 다시 그려서 여기서 그림)
func _altar_beams(V: Rect2) -> void:
	if not Unit.alive(b.boss) or not b.boss.shield:
		return
	var bp: Vector2 = b.boss.position + Vector2(0, -24)
	var a := 0.35 + 0.15 * sin(b.t * 8)
	for al in b.altars:
		if al.dead:
			continue
		var p: Vector2 = al.position + Vector2(0, -26)
		if not V.intersects(Rect2(p, Vector2.ZERO).expand(bp)):
			continue
		draw_line(p, bp, Color(0.95, 0.75, 0.3, a), 5)
		draw_line(p, bp, Color(1, 0.95, 0.7, a + 0.2), 1.5)


## 봉인된 사신수 빛 구슬(D-207, 그림은 에셋 전까지): 둥실거리며 빛남 → 풀려나는 동안 커지며 흐려짐
func _beast(V: Rect2) -> void:
	if b.beast_pos == Vector2.INF or not V.has_point(b.beast_pos):
		return
	var Bs: Dictionary = Stage1.BEAST
	var c := Color(Bs.c)
	var p: Vector2 = b.beast_pos + Vector2(0, sin(b.t * 3) * 3 - 6)
	if b.beast_t >= 0:
		var k := clampf(b.beast_t / float(Bs.release), 0, 1)
		draw_circle(p, 12 + 140 * k, Color(c, 0.35 * (1.0 - k)))
		draw_circle(p, 10 + 30 * k, Color(1, 1, 1, 0.9 * (1.0 - k)))
		return
	draw_circle(b.beast_pos + Vector2(0, 8), 10, Color(0, 0, 0, 0.2))
	draw_circle(p, 22 + sin(b.t * 5) * 3, Color(c, 0.25))
	draw_circle(p, 13, Color(c, 0.75))
	draw_circle(p, 8, Color(1, 1, 1, 0.95))
	for i in 3:
		var a := b.t * 2.0 + i * TAU / 3
		draw_circle(p + Vector2.from_angle(a) * 20, 2, Color(1, 1, 1, 0.8))
	_label("봉인된 %s" % Bs.n, p + Vector2(0, -34), Color("cfe8f8"))


## 성문이 열리는 중(D-206): 문짝 둘이 양쪽 경첩을 축으로 북쪽(장각 쪽)으로 돌아감. k = 0 닫힘 → 1 열림
func _gate_leaves(o: Rect2, k: float) -> void:
	var e := 1.0 - pow(1.0 - clampf(k, 0, 1), 2)
	var half := o.size.x / 2
	var y := o.get_center().y
	draw_rect(Rect2(o.position.x + 2, o.position.y + 3, o.size.x - 4, o.size.y - 6), Color(0.1, 0.07, 0.04, 0.5 * (1.0 - e)))
	for side in [-1.0, 1.0]:
		var hinge := Vector2(o.position.x if side < 0 else o.end.x, y)
		var tip := hinge + Vector2(-side, 0).rotated(side * e * 1.75) * half
		draw_line(hinge, tip, Color("3a2410"), 11)
		draw_line(hinge, tip, Color("7a4a24"), 8)
		draw_circle(hinge, 4, Color("5a3a1a"))


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
