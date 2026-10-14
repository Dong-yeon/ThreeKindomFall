class_name Terrain
extends Node2D
## 움직이지 않는 지형(풀 · 길 · 강 · 다리 · 본진 · 진영 · 담 · 마을 집 · 이름표) — 지도를 세로 CHUNK px씩 나눈 조각 하나.
## 한 번 그려 두고, 진영 점령 · 수비탑 파괴 · 마을 상태가 바뀔 때만 다시 그림(Battle._terrain_sig).
## 전엔 바닥 전체를 매 프레임 다시 그려서, 웹(Compatibility)에서 다각형 · 원 · 굵은 선마다 GPU 버퍼를 새로 만들고 지웠음
## (태블릿 Chrome 프로파일: WebGL getParameter 35% · createVertexArray · deleteBuffer …). 화면 밖 조각은 엔진이 그리지 않음.
## 움직이는 것(물결 · 마을 불길 · 체력 막대 · 주울 것 · 책략 바닥 · 울타리)은 ground.gd가 매 프레임 그림.

const CHUNK := 640.0
const GRASS := Color("5b7a3e")
const INK := Color(0.11, 0.09, 0.07, 0.85)

var b: Battle
var area := Rect2()


func setup(battle: Battle, y0: float) -> void:
	b = battle
	area = Rect2(0, y0, Stage1.W, minf(CHUNK, Stage1.H - y0))


## 이 조각이 그릴 것인가: 기준점 y가 이 조각 안(두 조각에 걸친 것을 두 번 그리면 반투명이 진해져서 한 조각에서만)
func _mine(y: float) -> bool:
	return y >= area.position.y and y < area.end.y


func _draw() -> void:
	Perf.begin(&"그리기:바닥")
	var V := area
	draw_rect(area, GRASS)
	_road(V)
	_river(V)
	_home(V)
	_village(V)
	_camps(V)
	for o in b.obs:
		var rc: Rect2 = o.rect
		if o.k == "water" or not _mine(rc.get_center().y):
			continue
		# 성문이 열리는 연출(2 · 3장, siege.gd)은 ground.gd가 매 프레임 그림
		if o.door == "gate" and b.siege != null:
			continue
		_stone(rc, o.door != "")
	var K := b.keep_rect()
	if _mine(K.get_center().y):
		draw_rect(K.grow(-12), Color(0.85, 0.44, 0.37, 0.12))
		_label("장각 본진" if b.siege != null and b.siege.keep_open else "장각 본진(닫힘)", Vector2(K.get_center().x, K.position.y - 14), Color("ffb0a0"))
	Perf.end()


## 관문 → 가운데 다리 → 본진 흙길(D-214 — 정원지의 대군이 이 길로 진군). 강은 다리가 덮음
func _road(V: Rect2) -> void:
	var x := float(Stage1.ARMY.road_x)
	var R := Rect2(x - 18, float(Stage1.GATE.y) + 10, 36, Stage1.HOME.pos.y - float(Stage1.GATE.y) - 10)
	var top := maxf(R.position.y, maxf(V.position.y, area.position.y))
	var bot := minf(R.end.y, minf(V.end.y, area.end.y))
	if bot <= top:
		return
	draw_rect(Rect2(R.position.x, top, R.size.x, bot - top), Color(0.55, 0.45, 0.3, 0.55))
	var y := floorf(top / 40.0) * 40.0
	while y < bot:
		draw_line(Vector2(x - 12, y), Vector2(x - 12, y + 14), Color(0.42, 0.33, 0.2, 0.5), 2)
		draw_line(Vector2(x + 12, y + 20), Vector2(x + 12, y + 34), Color(0.42, 0.33, 0.2, 0.5), 2)
		y += 40.0


## 강 · 다리(물결은 ground.gd)
func _river(V: Rect2) -> void:
	var R: Dictionary = Stage1.RIVER
	var y0: float = R.y0
	var y1: float = R.y1
	if not _mine(y0):
		return
	draw_rect(Rect2(0, y0, Stage1.W, y1 - y0), Color("4a7ab8"))
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


## 본진 바닥 · 천막 · 깃발 · 이름(체력 막대는 ground.gd)
func _home(V: Rect2) -> void:
	var H := b.home_pos
	if not _mine(H.y):
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


func _camps(V: Rect2) -> void:
	for c in b.camps:
		var R := b.camp_rect(c)
		if not _mine(R.get_center().y):
			continue
		var cap: bool = c.cap
		draw_rect(R, Color(0.63, 0.75, 0.86, 0.25) if cap else Color(0.59, 0.43, 0.24, 0.3))
		var p: Vector2 = c.pos
		for d in [Vector2(-70, -40), Vector2(60, -45), Vector2(-60, 30), Vector2(70, 25)]:
			_tent(p + d, Color("e8e0d0") if cap else Color("d8b860"), Color("4a7ab8") if cap else Color("a8782a"))
		_flag(p + Vector2(0, -10), Color("4a7ab8") if cap else Color("d8b040"), b.hero_data.flag_glyph if cap else "黃")
		var total: int = c.tws.size()
		var left := b.towers_left(c)
		var what: String = String(c.ln) if left == 0 else ("%s %d/%d" % [Battle.obj_name(c), total - left, total])
		var txt: String = ("%s — 점령" % c.n) if cap else ("%s · %s" % [c.n, what])
		_label(txt, Vector2(p.x, R.position.y - 14), Color("cfe2f4") if cap else Color("ffd8a0"))


## 탁현 마을 집(D-208) · 이름. 습격 중 불길 · 빨간 고리 · 남은 시간 막대는 ground.gd
func _village(V: Rect2) -> void:
	var VL: Dictionary = Stage1.VILLAGE
	var p: Vector2 = VL.pos
	if not _mine(p.y):
		return
	var raid := b.vil_st == "raid"
	var lost := b.vil_st == "lost"
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


## 깃발(펄럭임 없이 — 다시 그리지 않는 지형이라)
func _flag(p: Vector2, col: Color, glyph: String) -> void:
	draw_rect(Rect2(p.x - 1.5, p.y - 34, 3, 40), Color("5a3a1a"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(1.5, -34), p + Vector2(24, -31), p + Vector2(24, -15), p + Vector2(1.5, -18)]), col)
	draw_string(Fonts.small(), p + Vector2(2, -21), glyph, HORIZONTAL_ALIGNMENT_CENTER, 20, 10, Color("fffaf0"))


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
