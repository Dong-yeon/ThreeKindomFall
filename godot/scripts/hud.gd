class_name Hud
extends CanvasLayer
## 화면 위 겹쳐 그리기(웹판 fieldHud · fieldOverlay): 위 목표 글 · 장수급 체력 · 작은 지도 · 화면 밖 목표 화살표 · 연격 수 ·
## 끌기 표시 · 무쌍 버튼 · 알림 · 결과.

const INK := Color(0.11, 0.09, 0.07)
const TOP_H := 58.0
const MM_W := 44.0

var b: Battle
var overlay: Control
var title_lbl: Label
var goal_lbl: Label
var tags_lbl: Label
var banner_box: VBoxContainer
var banner_title: Label
var banner_sub: Label
var banner_t := 0.0
var musou_btn: MusouButton
var end_panel: PanelContainer
var end_title: Label
var end_stats: Label
var vignette: GradientTexture2D


func setup(battle: Battle) -> void:
	b = battle
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	# 위: 장 이름 · 목표 · 숫자
	var top := ColorRect.new()
	top.color = Color(0.11, 0.09, 0.07, 0.72)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_H
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	title_lbl = _label(11, Color("c8b890"))
	title_lbl.position = Vector2(10, 4)
	top.add_child(title_lbl)
	goal_lbl = _label(13, Color("fff2c0"))
	goal_lbl.position = Vector2(10, 20)
	top.add_child(goal_lbl)
	tags_lbl = _label(11, Color("cfe2f4"))
	tags_lbl.position = Vector2(10, 39)
	top.add_child(tags_lbl)
	# 알림(가운데 위)
	banner_box = VBoxContainer.new()
	banner_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner_box.offset_top = 150
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(banner_box)
	banner_title = _label(20, Color("fff2c0"), 5)
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(banner_title)
	banner_sub = _label(12, Color("f4ecd8"), 4)
	banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_box.add_child(banner_sub)
	banner_box.modulate.a = 0
	# 무쌍 버튼(오른쪽 아래)
	musou_btn = MusouButton.new()
	musou_btn.b = b
	musou_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	musou_btn.offset_left = -96
	musou_btn.offset_top = -108
	musou_btn.offset_right = -16
	musou_btn.offset_bottom = -28
	add_child(musou_btn)
	# 결과
	end_panel = PanelContainer.new()
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	end_panel.custom_minimum_size = Vector2(280, 0)
	end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ecd8")
	sb.border_color = Color("3a2a1a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	end_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	end_panel.add_child(vb)
	end_title = _label(18, Color("3a2a1a"), 0)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(end_title)
	end_stats = _label(13, Color("3a2a1a"), 0)
	vb.add_child(end_stats)
	var retry := Button.new()
	retry.text = "다시 하기"
	retry.custom_minimum_size = Vector2(0, 44)
	retry.pressed.connect(func(): b.get_tree().reload_current_scene())
	vb.add_child(retry)
	end_panel.visible = false
	add_child(end_panel)
	# 무쌍 중 화면 가장자리
	vignette = GradientTexture2D.new()
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(0.24, 0.12, 0, 0))
	g.set_color(1, Color(0.24, 0.12, 0, 0.45))
	g.add_point(0.55, Color(0.24, 0.12, 0, 0))
	vignette.gradient = g


func _label(size: int, col: Color, outline := 3) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = size
	ls.font_color = col
	ls.outline_size = outline
	ls.outline_color = INK
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func musou_hit(p: Vector2) -> bool:
	return musou_btn.visible and musou_btn.get_global_rect().grow(6).has_point(p)


## 이 자리를 누르면 끌어서 이동을 시작하지 않음(버튼 · 결과 창)
func blocks(p: Vector2) -> bool:
	return musou_hit(p) or end_panel.visible


func banner(title: String, sub: String) -> void:
	if banner_title == null:
		return
	banner_title.text = title
	banner_sub.text = sub
	banner_sub.visible = sub != ""
	banner_t = 2.6


func refresh() -> void:
	var h := b.hero
	var T := b.field_target()
	var title := "%s · %s" % [Stage1.NAME, _fmt_t(b.t)]
	if title_lbl.text != title:
		title_lbl.text = title
	var goal := "목표  " + String(T.n)
	if goal_lbl.text != goal:
		goal_lbl.text = goal
	var tags := "%s %d/%d · 처치 %d · 본진 %d%% · 아군 %d" % [b.hero_data.display_name, ceili(h.hp), roundi(h.max_hp), b.kills, ceili(b.home_hp / b.home_max * 100), b.allies.size()]
	if tags_lbl.text != tags:
		tags_lbl.text = tags
	if banner_t > 0:
		banner_t -= get_process_delta_time()
		banner_box.modulate.a = clampf(banner_t / 0.5, 0, 1)
	musou_btn.visible = b.state == "play"
	overlay.queue_redraw()


func show_end() -> void:
	var win := b.state == "end"
	var hn := b.hero_data.display_name
	if win:
		end_title.text = "%s 평정!" % Stage1.NAME
	elif b.end_why == "home":
		end_title.text = "아군 본진이 함락됐어요"
	else:
		end_title.text = "%s가 쓰러졌어요" % hn if Battle.eul(hn) == "를" else "%s이 쓰러졌어요" % hn
	end_stats.text = "걸린 시간   %s\n점령한 진영   %d / 3\n쓰러뜨린 적   %d\n최대 연격   %d" % [_fmt_t(b.t), b.cap_n, b.kills, b.hero.cb_max]
	end_panel.visible = true


static func _fmt_t(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


# ─────────── 겹쳐 그리기 ───────────

func _w2s(p: Vector2) -> Vector2:
	return p - b.view.position


func _draw_overlay() -> void:
	var c := overlay
	var sz := overlay.size
	var h := b.hero
	var font := ThemeDB.fallback_font
	if h.musou_t > 0:
		c.draw_texture_rect(vignette, Rect2(Vector2.ZERO, sz), false)
	_draw_lead_bar(c, font, sz)
	# 목표 화살표(화면 밖일 때)
	var T := b.field_target()
	var tp: Vector2 = T.pos
	var s := _w2s(tp)
	var x0 := 16.0
	var x1 := sz.x - 16
	var y0 := TOP_H + 16
	var y1 := sz.y - 16
	if s.x < x0 or s.x > x1 or s.y < y0 or s.y > y1:
		var hc := _w2s(h.position)
		var a := (s - hc).angle()
		var k := INF
		if cos(a) > 0.01:
			k = minf(k, (x1 - hc.x) / cos(a))
		if cos(a) < -0.01:
			k = minf(k, (x0 - hc.x) / cos(a))
		if sin(a) > 0.01:
			k = minf(k, (y1 - hc.y) / sin(a))
		if sin(a) < -0.01:
			k = minf(k, (y0 - hc.y) / sin(a))
		var ap := hc + Vector2.from_angle(a) * k
		var pul := 1.0 + 0.12 * sin(b.t * 8)
		var tri := PackedVector2Array([Vector2(12, 0), Vector2(-8, -9), Vector2(-4, 0), Vector2(-8, 9)])
		var pts := PackedVector2Array()
		for q in tri:
			pts.append(ap + (q * pul).rotated(a))
		c.draw_colored_polygon(pts, Color("ff8a6a") if T.get("warn", false) else Color("ffd34a"))
		pts.append(pts[0])
		c.draw_polyline(pts, INK, 2)
		var lp := Vector2(clampf(ap.x - cos(a) * 26, x0 + 22, x1 - 22), clampf(ap.y - sin(a) * 18, y0 + 6, y1 - 6))
		var tx := "%d보" % roundi(tp.distance_to(h.position) / 10)
		_text(c, font, tx, lp, 11, Color("fff2c0"))
	_draw_minimap(c, sz)
	# 연격 수
	var mh := MM_W * Stage1.H / Stage1.W
	if h.cb_n > 0:
		var st := h.cb_stage()
		var col: Array = Hero.CB_COL[st]
		var al := maxf(0.35, 1.0 - maxf(0.0, h.cb_idle - 1.2))
		var rx := sz.x - 8
		var ry := TOP_H + 8 + mh + 40
		var fs := 30 if st == 3 else (27 if st == 2 else 24)
		_text(c, font, str(h.cb_n), Vector2(rx, ry), fs, Color(col[0], al), HORIZONTAL_ALIGNMENT_RIGHT, 4)
		_text(c, font, "연격", Vector2(rx, ry + 16), 12, Color(col[1], al), HORIZONTAL_ALIGNMENT_RIGHT)
	if h.cb_pop_t > 0:
		var k := minf(1.0, (1.3 - h.cb_pop_t) * 6)
		var al := minf(1.0, h.cb_pop_t * 2)
		var yy := sz.y * 0.32 - (1.3 - h.cb_pop_t) * 14
		_text(c, font, h.cb_pop_text, Vector2(sz.x / 2, yy), roundi(26 + 10 * (1 - k)), Color(h.cb_pop_col, al), HORIZONTAL_ALIGNMENT_CENTER, 5)
	# 끌어서 이동
	if b.joy_on:
		var d := b.joy_p - b.joy_o
		var kk := 50.0 / d.length() if d.length() > 50 else 1.0
		c.draw_arc(b.joy_o, 50, 0, TAU, 40, Color(0.96, 0.93, 0.85, 0.45), 2)
		c.draw_circle(b.joy_o + d * kk, 20, Color(0.96, 0.93, 0.85, 0.45))


## 장각 · 지금 화면의 장수급 체력(위)
func _draw_lead_bar(c: Control, font: Font, sz: Vector2) -> void:
	var L: Enemy = b.boss if Unit.alive(b.boss) else null
	if L == null:
		var bd := INF
		for e in b.enemies:
			if e.elite and not e.dead and b.in_view(e.position, 0):
				var d := e.position.distance_to(b.hero.position)
				if d < bd:
					bd = d
					L = e
	if L == null:
		return
	var x0 := 14.0
	var w := sz.x - MM_W - 40 - x0
	var y := TOP_H + 8
	c.draw_rect(Rect2(x0, y, w, 8), Color("3a3024"))
	c.draw_rect(Rect2(x0, y, w * clampf(L.hp / L.max_hp, 0, 1), 8), Color("d9705e") if L.boss else Color("d89a3a"))
	var name: String = L.ename if L.ename != "" else String(L.def.n)
	_text(c, font, name, Vector2(x0 + w / 2, y + 20), 12, Color("fff2c0"))


func _draw_minimap(c: Control, sz: Vector2) -> void:
	var mw := MM_W
	var mh := mw * Stage1.H / Stage1.W
	var mx := sz.x - mw - 6
	var my := TOP_H + 8
	var s := mw / Stage1.W
	var P := func(p: Vector2) -> Vector2: return Vector2(mx, my) + p * s
	c.draw_rect(Rect2(mx - 2, my - 2, mw + 4, mh + 4), Color(0.11, 0.09, 0.07, 0.62))
	c.draw_rect(Rect2(mx, my, mw, mh), Color(0.35, 0.47, 0.24, 0.55))
	var R: Dictionary = Stage1.RIVER
	c.draw_rect(Rect2(mx, my + float(R.y0) * s, mw, (float(R.y1) - float(R.y0)) * s), Color("4a7ab8"))
	c.draw_rect(Rect2(mx, my + (float(Stage1.GATE.y) - 10) * s, mw, 2), Color(0.54, 0.52, 0.47, 0.6) if b.cap_n >= 3 else Color("8a8478"))
	var K := b.keep_rect()
	c.draw_rect(Rect2(P.call(K.position), K.size * s), Color("ff6a4a") if b.boss != null else Color("d9705e"), false, 1.5)
	for cp in b.camps:
		var CR := b.camp_rect(cp)
		c.draw_rect(Rect2(P.call(CR.position), CR.size * s), Color("6a9ad8") if cp.cap else Color("e2b040"))
	var hp: Vector2 = P.call(b.home_pos)
	var blink := b.home_hp < b.home_max * 0.5 and int(b.t * 4) % 2 == 1
	c.draw_rect(Rect2(hp - Vector2(3, 3), Vector2(6, 6)), Color("ff6a4a") if blink else Color("6a9ad8"))
	if Unit.alive(b.cyz):
		c.draw_circle(P.call(b.cyz.position), 2.5, Color("ff6a4a"))
	if Unit.alive(b.boss):
		c.draw_circle(P.call(b.boss.position), 3, Color("ff6a4a"))
	for e in b.enemies:
		if e.goal_home and not e.dead:
			c.draw_rect(Rect2(P.call(e.position) - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), Color("ff8a6a"))
	for a in b.allies:
		c.draw_rect(Rect2(P.call(a.position) - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), Color("9ac0f0"))
	c.draw_rect(Rect2(P.call(b.view.position), b.view.size * s), Color(1, 0.98, 0.94, 0.7), false, 1)
	c.draw_circle(P.call(b.hero.position), 2.5, Color("fffaf0"))


func _text(c: Control, font: Font, s: String, at: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER, outline := 3) -> void:
	var w := 200.0
	var x := at.x - w / 2
	if align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = at.x - w
	var pos := Vector2(x, at.y + size * 0.35)
	c.draw_string_outline(font, pos, s, align, w, size, outline, Color(INK, col.a))
	c.draw_string(font, pos, s, align, w, size, col)
