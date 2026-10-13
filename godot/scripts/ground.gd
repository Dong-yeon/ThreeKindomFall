extends Node2D
## 매 프레임 바뀌는 바닥 그림: 강 물결 · 본진 체력 · 마을 습격 불길 · 책략 바닥 · 보스 울타리 · 주울 것 · 경험 구슬.
## 움직이지 않는 지형(풀 · 길 · 강 · 다리 · 본진 · 진영 · 담 · 마을 집)은 terrain.gd. 바닥은 일단 단색(B.B.Bits 타일셋을 사면 바꿈, D-169).

const GRASS := Color("5b7a3e")
const INK := Color(0.11, 0.09, 0.07, 0.85)

@onready var b: Battle = get_parent()


func _draw() -> void:
	Perf.begin(&"그리기:바닥")
	_draw_impl()
	Perf.end()


func _draw_impl() -> void:
	# 움직이지 않는 지형은 terrain.gd(조각마다 한 번 그림) — 여긴 매 프레임 바뀌는 것만
	var V := b.view.grow(40)
	_river_waves(V)
	_home_bar(V)
	_village_fx(V)
	# 2 · 3장: 성문(열리는 연출은 siege.gd)
	if b.siege != null:
		for o in b.obs:
			var rc: Rect2 = o.rect
			if o.door == "gate" and V.intersects(rc) and not b.siege.draw_gate(self, rc):
				_stone(rc, true)
	_tactics_ground(V)
	# 2 · 3장: 요술 제단 빛줄기 · 장각의 요술 · 봉인된 사신수(D-211 — siege.gd)
	if b.siege != null:
		b.siege.draw_ground(self, V)
	_arena(V)
	for dr in b.drops:
		var p: Vector2 = dr.pos
		if dr.get("k", "bun") == "bomb":
			# 폭탄(D-216): 검은 공 + 타는 심지
			var bob := sin(b.t * 5) * 2
			draw_circle(p + Vector2(0, 8), 7, Color(0, 0, 0, 0.2))
			draw_circle(p + Vector2(0, bob), 8, Color("2a2a30"))
			draw_circle(p + Vector2(-3, bob - 3), 2.5, Color("6a6a78"))
			draw_line(p + Vector2(4, bob - 6), p + Vector2(8, bob - 11), Color("c8a874"), 2)
			draw_circle(p + Vector2(8, bob - 12), 2.5 + sin(b.t * 20), Color("ffb040"))
			continue
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
			# 마을 상자(회복 + 경험, D-209)는 초록 띠
			draw_rect(Rect2(q + Vector2(-2, -10), Vector2(4, 18)), Color("7ad870") if dr.get("kind", "") == "village" else Color("f0c040"))
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
		# 45° 돌린 사각형 = 마름모(다각형은 그릴 때마다 GPU 버퍼를 만들어 웹에서 비쌈 — 사각형은 묶어서 그림)
		draw_set_transform(p, PI / 4)
		var h := s * 0.75
		draw_rect(Rect2(-h - 1, -h - 1, h * 2 + 2, h * 2 + 2), Color(0.11, 0.09, 0.07, 0.7))
		draw_rect(Rect2(-h, -h, h * 2, h * 2), c)
	draw_set_transform(Vector2.ZERO)


## 강 물결(흐름): 얇은 선이라 버퍼를 만들지 않음
func _river_waves(V: Rect2) -> void:
	var R: Dictionary = Stage1.RIVER
	var y0: float = R.y0
	var y1: float = R.y1
	if y1 < V.position.y or y0 > V.end.y:
		return
	for i in 40:
		var x := fmod(i * 97 + b.t * 18, Stage1.W)
		var y := y0 + 10 + (i * 37) % int(y1 - y0 - 20)
		var inb := false
		for br in R.bridges:
			if x + 14 > br.x and x < br.y:
				inb = true
		if not inb:
			draw_line(Vector2(x, y), Vector2(x + 14, y), Color(0.81, 0.89, 0.96, 0.6), -1)


func _home_bar(V: Rect2) -> void:
	var H := b.home_pos
	if H.y - 120 > V.end.y or b.home_hp >= b.home_max:
		return
	_bar(H + Vector2(0, -50), 80, b.home_hp / b.home_max, Color("4a7ab8"))


## 탁현 마을 습격 중(D-208): 지붕 불길 · 빨간 고리 깜빡임 · 남은 시간 막대(집은 terrain.gd)
func _village_fx(V: Rect2) -> void:
	if b.vil_st != "raid":
		return
	var VL: Dictionary = Stage1.VILLAGE
	var p: Vector2 = VL.pos
	if not V.intersects(Rect2(p - Vector2(90, 90), Vector2(180, 180))):
		return
	var i := 0
	for d in [Vector2(-26, -14), Vector2(22, -20), Vector2(0, 18)]:
		var q: Vector2 = p + d
		var fl := sin(b.t * 9 + i * 2.1) * 2
		draw_colored_polygon(PackedVector2Array([q + Vector2(-6, -12), q + Vector2(6, -12), q + Vector2(fl, -26)]), Color(0.95, 0.5, 0.15, 0.85))
		draw_colored_polygon(PackedVector2Array([q + Vector2(-3, -12), q + Vector2(3, -12), q + Vector2(fl * 0.5, -19)]), Color(1, 0.9, 0.45))
		i += 1
	if int(b.t * 3) % 2 == 1:
		draw_arc(p, float(VL.r) + 10, 0, TAU, 40, Color(0.85, 0.31, 0.24, 0.8), 2)
	_bar(p + Vector2(0, -48), 70, b.vil_t / float(VL.limit), Color("d9705e"))


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


## 보스 울타리(D-216): 예고 = 붉은 점선 원(깜빡임, 안쪽이 차오름) · 울타리 = 나무 말뚝 둘레 + 밧줄
func _arena(V: Rect2) -> void:
	var A: Dictionary = b.arena
	if A.is_empty():
		return
	var c: Vector2 = A.c
	var R: float = A.r
	if A.st == "warn":
		var k := 1.0 - clampf(float(A.t) / float(Stage1.ARENA.warn), 0.0, 1.0)
		var al := 0.75 + 0.25 * sin(b.t * 12)
		draw_circle(c, R, Color(0.9, 0.3, 0.22, 0.08))
		draw_circle(c, R * k, Color(0.9, 0.3, 0.22, 0.14))
		var n := 48
		for i in n:
			if i % 2 == 0:
				draw_arc(c, R, TAU * i / n, TAU * (i + 1) / n, 4, Color(1, 0.3, 0.25, al), 6)
		return
	draw_arc(c, R + 2, 0, TAU, 96, Color(0, 0, 0, 0.18), 6)
	draw_arc(c, R - 6, 0, TAU, 96, Color("c8a874"), 2)
	var n := int(TAU * R / 18)
	for i in n:
		var q := c + Vector2.from_angle(TAU * i / n) * R
		if not V.grow(20).has_point(q):
			continue
		draw_rect(Rect2(q + Vector2(-2.5, -12), Vector2(5, 14)), Color("6a4a20"))
		draw_rect(Rect2(q + Vector2(-2.5, -12), Vector2(5, 3)), Color("a8743a"))
