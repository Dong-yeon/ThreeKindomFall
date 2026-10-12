class_name Hud
extends CanvasLayer
## 화면 위 겹쳐 그리기(웹판 fieldHud · fieldOverlay): 위 목표 글 · 장수급 체력 · 작은 지도 · 화면 밖 목표 화살표 · 연격 수 ·
## 끌기 표시 · 무쌍 버튼 · 알림 · 결과 · 공적 레벨 · 책략 칸 · 레벨업 카드(D-172).

const INK := Color(0.11, 0.09, 0.07)
const TOP_H := 80.0
const MM_W := 44.0
const CARD_INK := Color("3a2a1a")
const CARD_GOLD := Color("e2a83a")

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
var pause_btn: PauseButton
var pause_panel: PanelContainer
var pause_info: Label
var end_title: Label
var end_stats: Label
var vignette: GradientTexture2D
var slots_ctl: Control
var pick_panel: PanelContainer
var pick_title: Label
var pick_sub: Label
## 카드 3장: {btn, box(StyleBoxFlat), icon(StyleBoxFlat), glyph, name, desc, pair, glow: ""|ready|evo}
var cards: Array[Dictionary] = []


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
	# 책략 칸(공격 6 + 보조 6) · 공적 경험 막대
	slots_ctl = Control.new()
	slots_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	slots_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_ctl.draw.connect(_draw_slots)
	top.add_child(slots_ctl)
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
	_build_pause()
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
	_build_pick()


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
func pause_hit(p: Vector2) -> bool:
	return pause_btn.visible and pause_btn.get_global_rect().grow(6).has_point(p)


func blocks(p: Vector2) -> bool:
	return musou_hit(p) or pause_hit(p) or end_panel.visible or pick_panel.visible or pause_panel.visible


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
	var title := "%s · %s · 공적 Lv %d" % [Stage1.NAME, _fmt_t(b.t), b.lvl]
	if title_lbl.text != title:
		title_lbl.text = title
	var goal := "목표  " + String(T.n)
	if goal_lbl.text != goal:
		goal_lbl.text = goal
	var tags := "%s %d/%d · 진영 %d/3 · 처치 %d · 본진 %d%% · 아군 %d" % [b.hero_data.display_name, ceili(h.hp), roundi(h.max_hp), b.cap_n, b.kills, ceili(b.home_hp / b.home_max * 100), b.allies.size()]
	if tags_lbl.text != tags:
		tags_lbl.text = tags
	if banner_t > 0:
		banner_t -= get_process_delta_time()
		banner_box.modulate.a = clampf(banner_t / 0.5, 0, 1)
	musou_btn.visible = b.state == "play"
	pause_btn.visible = b.state == "play" or b.state == "pause"
	if pick_panel.visible:
		_pulse_cards()
	overlay.queue_redraw()
	slots_ctl.queue_redraw()


func show_end() -> void:
	var win := b.state == "end"
	var hn := b.hero_data.display_name
	if win:
		end_title.text = "%s 평정!" % Stage1.NAME
	elif b.end_why == "home":
		end_title.text = "아군 본진이 함락됐어요"
	else:
		end_title.text = "%s가 쓰러졌어요" % hn if Battle.eul(hn) == "를" else "%s이 쓰러졌어요" % hn
	var T := b.tactics
	var evos: Array[String] = []
	for k in T.evo:
		evos.append(T.evo_name(k))
	end_stats.text = "걸린 시간   %s\n점령한 진영   %d / 3\n쓰러뜨린 적   %d\n최대 연격   %d\n공적 레벨   %d (공격 %d/%d · 보조 %d/%d)\n진화   %s" % [
		_fmt_t(b.t), b.cap_n, b.kills, b.hero.cb_max, b.lvl, T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS,
		", ".join(evos) if not evos.is_empty() else "없음"]
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
	var font := Fonts.main()
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
		# 남은 막사(D-180)
		for bk in cp.bks:
			if bk.alive:
				var q: Vector2 = P.call(bk.pos)
				c.draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color("ff8a3a"))
				c.draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), INK, false, 1.0)
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


# ─────────── 책략 칸 · 공적 경험 ───────────

## 위 패널 맨 아래 줄: 공격 6칸 · 보조 6칸(빈 칸은 테두리만, 진화하면 금테 + '진') + 공적 경험 막대
func _draw_slots() -> void:
	var c := slots_ctl
	var T := b.tactics
	var font := Fonts.main()
	var y := 55.0
	var x := 10.0
	for side in 2:
		var keys: Array[String] = T.act_order if side == 0 else T.pas_order
		var cap := TacticsData.ACT_SLOTS if side == 0 else TacticsData.PAS_SLOTS
		for i in cap:
			var r := Rect2(x, y, 18, 18)
			if i < keys.size():
				var k: String = keys[i]
				var ev := T.evolved(k)
				c.draw_rect(r, T.color_of(k))
				c.draw_rect(r, Color("fff2b0") if ev else INK, false, 2.0 if ev else 1.0)
				c.draw_string(font, Vector2(x, y + 14), T.glyph_of(k), HORIZONTAL_ALIGNMENT_CENTER, 18, 12, Color("fffaf0"))
				var lvt := "진" if ev else str(T.level(k))
				c.draw_string_outline(Fonts.small(), Vector2(x + 11, y + 20), lvt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, INK)
				c.draw_string(Fonts.small(), Vector2(x + 11, y + 20), lvt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fff2c0"))
			else:
				c.draw_rect(r, Color(1, 1, 1, 0.06))
				c.draw_rect(r, Color(0.8, 0.72, 0.56, 0.35), false, 1.0)
			x += 21
		x += 12
	var need := float(TacticsData.xp_need(b.lvl))
	c.draw_rect(Rect2(0, TOP_H - 3, c.size.x, 3), Color(0.23, 0.19, 0.14))
	c.draw_rect(Rect2(0, TOP_H - 3, c.size.x * clampf(b.xp / need, 0, 1), 3), Color("6ac0e0"))


# ─────────── 레벨업 카드(3개 중 1개) ───────────

func _build_pick() -> void:
	pick_panel = PanelContainer.new()
	pick_panel.set_anchors_preset(Control.PRESET_CENTER)
	pick_panel.custom_minimum_size = Vector2(340, 0)
	pick_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pick_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.09, 0.07, 0.92)
	sb.border_color = CARD_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	pick_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pick_panel.add_child(vb)
	pick_title = _label(17, Color("fff2c0"), 3)
	pick_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(pick_title)
	pick_sub = _label(10, Color("c8b890"), 2)
	pick_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(pick_sub)
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320, 86)
		btn.focus_mode = Control.FOCUS_NONE
		var box := StyleBoxFlat.new()
		box.bg_color = Color("f4ecd8")
		box.border_color = CARD_INK
		box.set_border_width_all(2)
		box.set_corner_radius_all(8)
		for st in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(st, box)
		btn.pressed.connect(b.choose.bind(i))
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -8
		row.offset_top = 5
		row.offset_bottom = -5
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(row)
		var icon := Panel.new()
		icon.custom_minimum_size = Vector2(42, 42)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var isb := StyleBoxFlat.new()
		isb.set_corner_radius_all(6)
		isb.border_color = CARD_INK
		isb.set_border_width_all(2)
		icon.add_theme_stylebox_override("panel", isb)
		row.add_child(icon)
		var glyph := _label(20, Color("fffaf0"), 3)
		glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_child(glyph)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 1)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(col)
		var nm := _label(14, Color("3a2a1a"), 0)
		var ds := _label(11, Color("5a4a36"), 0)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var pr := _label(10, Color("8a5a1a"), 0)
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for l in [nm, ds, pr]:
			col.add_child(l)
		vb.add_child(btn)
		cards.append({"btn": btn, "box": box, "icon": isb, "glyph": glyph, "name": nm, "desc": ds, "pair": pr, "glow": ""})
	pick_panel.visible = false
	add_child(pick_panel)


static func _stars(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(TacticsData.MAX_LV - n)


func show_pick(opts: Array[Dictionary]) -> void:
	var T := b.tactics
	pick_title.text = "공적 Lv %d — 책략 고르기" % b.lvl
	pick_sub.text = "공격 %d/%d · 보조 %d/%d · 진화 %d  ·  공격 Lv5 + 짝 보조 = 진화" % [T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS, T.evo_count()]
	for i in cards.size():
		var c: Dictionary = cards[i]
		var btn: Button = c.btn
		btn.visible = i < opts.size()
		if i >= opts.size():
			continue
		var o: Dictionary = opts[i]
		var k: String = o.k
		var isb: StyleBoxFlat = c.icon
		c.glow = "evo" if o.get("evo", false) else ("ready" if o.get("ready", false) else "")
		if k == "bun":
			isb.bg_color = Color("c8a874")
			c.glyph.text = "饅"
			c.name.text = "고기만두"
			c.desc.text = "체력 30% 회복"
			c.pair.text = "책략이 모두 가득 찼어요"
			continue
		isb.bg_color = T.color_of(k)
		c.glyph.text = T.glyph_of(k)
		if o.get("evo", false):
			if k == "basic":
				c.glyph.text = b.hero_data.basic_evo.glyph
			c.name.text = "진화 · %s" % T.evo_name(k)
			c.desc.text = T.evo_desc(k)
			c.pair.text = "%s Lv5 + %s" % [T.name_of(k), String(TacticsData.DEFS[T.pair_of(k)].n)]
			continue
		var nl := T.level(k) + 1
		var nm := T.name_of(k)
		if k == "basic":
			nm += "(%s 기본 공격)" % b.hero_data.display_name
		c.name.text = "%s  %s%s" % [nm, _stars(nl), "  · 새 책략" if o.get("new", false) else ""]
		c.desc.text = T.level_desc(k, nl) if T.is_act(k) else "%s (Lv%d)" % [T.level_desc(k, nl), nl]
		c.pair.text = _pair_text(k) + ("  — 고르면 다음 레벨업에 진화!" if o.get("ready", false) else "")
	_pulse_cards()
	pick_panel.visible = true


## 카드 아래 줄: 짝(가졌으면 ✓)과 진화 이름
func _pair_text(k: String) -> String:
	var T := b.tactics
	if T.is_act(k):
		var p := T.pair_of(k)
		if p == "":
			return ""
		return "짝: %s%s → %s" % [String(TacticsData.DEFS[p].n), " ✓" if T.level(p) > 0 else "", T.evo_name(k)]
	var parts: Array[String] = []
	for a in T.pairs_for(k):
		var an: String = b.hero_data.basic.display_name if a == "basic" else String(TacticsData.DEFS[a].n)
		parts.append("%s%s → %s" % [an, " ✓" if T.level(a) > 0 else "", T.evo_name(a)])
	return "짝: " + " · ".join(parts)


func hide_pick() -> void:
	pick_panel.visible = false


## 진화 카드는 금빛으로 크게, '고르면 다음에 진화' 카드는 약하게 깜빡임
func _pulse_cards() -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)
	for c in cards:
		var box: StyleBoxFlat = c.box
		match String(c.glow):
			"evo":
				box.bg_color = Color("fff4c8")
				box.border_color = CARD_GOLD.lerp(Color("fff2b0"), k)
				box.set_border_width_all(4)
				box.shadow_color = Color(1.0, 0.8, 0.3, 0.35 + 0.4 * k)
				box.shadow_size = 10
			"ready":
				box.bg_color = Color("f8efd8")
				box.border_color = CARD_GOLD.lerp(CARD_INK, 0.6 * k)
				box.set_border_width_all(3)
				box.shadow_color = Color(1.0, 0.8, 0.3, 0.15 + 0.25 * k)
				box.shadow_size = 6
			_:
				box.bg_color = Color("f4ecd8")
				box.border_color = CARD_INK
				box.set_border_width_all(2)
				box.shadow_size = 0


# ─────────── 일시정지(D-197) ───────────

func _build_pause() -> void:
	pause_btn = PauseButton.new()
	pause_btn.b = b
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.offset_left = -38
	pause_btn.offset_right = -6
	pause_btn.offset_top = 4
	pause_btn.offset_bottom = 32
	add_child(pause_btn)
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(260, 0)
	pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ecd8")
	sb.border_color = Color("3a2a1a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	pause_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pause_panel.add_child(vb)
	var title := _label(18, Color("3a2a1a"), 0)
	title.text = "잠깐 멈춤"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	pause_info = _label(12, Color("5a4a36"), 0)
	pause_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(pause_info)
	var go := Button.new()
	go.text = "계속하기"
	go.custom_minimum_size = Vector2(0, 44)
	go.pressed.connect(b.resume)
	vb.add_child(go)
	var again := Button.new()
	again.text = "처음부터 다시"
	again.custom_minimum_size = Vector2(0, 40)
	again.pressed.connect(func():
		Sound.set_paused(false)
		b.get_tree().reload_current_scene())
	vb.add_child(again)
	pause_panel.visible = false
	add_child(pause_panel)


func show_pause() -> void:
	pause_info.text = "%s · %s · 공적 Lv %d · 진영 %d/3" % [Stage1.NAME, _fmt_t(b.t), b.lvl, b.cap_n]
	pause_panel.visible = true


func hide_pause() -> void:
	pause_panel.visible = false
