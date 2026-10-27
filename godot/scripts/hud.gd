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
## 웹 첫 화면 '화면을 눌러 시작'(Battle.state == tap)
var tap_panel: ColorRect
## 프레임 표시(--fps, 웹은 fps.html): 0.5초마다 FPS · 프레임 간격 평균/최대 · 판 처리 시간 · 1/30초 넘은 프레임 수
var fps_lbl: Label
var _fps_last := 0
var _fps_acc := []
var _fps_t := 0.0
var _fps_slow := 0
var pause_info: Label
## 사람 플레이 기록(D-221, Battle.playtest가 있을 때만): 왼쪽 위 '지루' 버튼(누르면 잠깐 반짝) · 결과 창 요약 · 기록 복사
var bored_btn: ColorRect
var _bored_flash := 0.0
var end_vb: VBoxContainer
var pt_lbl: Label
var pt_msg: Label
var pt_edit: TextEdit
## 웹 복사 결과를 기다리는 남은 초(navigator.clipboard는 비동기 — 실패하면 고를 수 있는 글 창을 띄움)
var _pt_wait := 0.0
var end_title: Label
var end_stats: Label
var end_retry: Button
var vignette: GradientTexture2D
var slots_ctl: Control
var pick_panel: PanelContainer
var pick_title: Label
var pick_sub: Label
## 고르기 화면의 '지금 가진 것'(2026-10-13): 공격 · 보조마다 이름 · Lv · 짝을 가졌는지
var pick_have: Label
## 카드 3장: {btn, box(StyleBoxFlat), icon(StyleBoxFlat), glyph, name, desc, pair, glow: ""|ready|evo}
var cards: Array[Dictionary] = []
## 적장 거래(D-230): 고르기 화면 아래 '거래하지 않음'(거래일 때만 보임)
var deal_no: Button
## 책략 다시 뽑기(D-234, 재능) — 남은 수가 있을 때만
var pick_reroll: Button


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
	# 오른쪽 가장자리, 화면 높이 68% 자리(장수는 60% 자리라 그 아래, 2026-10-13 — 전엔 오른쪽 아래 구석이라 엄지로 끌기 시작하는 자리와 겹쳤음).
	# 끌기는 아래쪽에서 자유롭게, 무쌍은 엄지를 조금 올려 누름. 크기 80 → 70
	musou_btn.anchor_left = 1.0
	musou_btn.anchor_right = 1.0
	musou_btn.anchor_top = 0.68
	musou_btn.anchor_bottom = 0.68
	musou_btn.offset_left = -82
	musou_btn.offset_right = -12
	musou_btn.offset_top = -35
	musou_btn.offset_bottom = 35
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
	end_vb = vb
	end_title = _label(18, Color("3a2a1a"), 0)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(end_title)
	end_stats = _label(13, Color("3a2a1a"), 0)
	# 진화가 여럿이면 한 줄이 길어 패널이 화면 밖으로 넓어졌음(D-232) — 폭을 정하고 줄바꿈
	end_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_stats.custom_minimum_size = Vector2(300, 0)
	vb.add_child(end_stats)
	# 천하 지도로(D-235): 대장간 · 재능은 군영에서
	var world := Button.new()
	world.text = "천하 지도로"
	world.custom_minimum_size = Vector2(0, 44)
	world.pressed.connect(func(): b.get_tree().change_scene_to_file(Battle.WORLD_SCENE))
	vb.add_child(world)
	var retry := Button.new()
	retry.text = "다시 하기"
	retry.custom_minimum_size = Vector2(0, 44)
	retry.pressed.connect(func(): b.get_tree().reload_current_scene())
	vb.add_child(retry)
	end_retry = retry
	end_panel.visible = false
	add_child(end_panel)
	_build_pause()
	if b.playtest != null:
		_build_playtest()
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


func bored_hit(p: Vector2) -> bool:
	return bored_btn != null and bored_btn.visible and bored_btn.get_global_rect().grow(4).has_point(p)


func blocks(p: Vector2) -> bool:
	return musou_hit(p) or pause_hit(p) or bored_hit(p) or end_panel.visible or pick_panel.visible or pause_panel.visible or (tap_panel != null and tap_panel.visible)


## '화면을 눌러 시작'(웹): 화면 전체를 어둡게 덮고 장 이름 · 안내. 누르기는 Battle._unhandled_input이 받음(여긴 입력을 막지 않음)
func show_tap() -> void:
	if tap_panel == null:
		tap_panel = ColorRect.new()
		tap_panel.color = Color(0.08, 0.07, 0.05, 0.82)
		tap_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		tap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var vb := VBoxContainer.new()
		vb.set_anchors_preset(Control.PRESET_CENTER)
		vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
		vb.grow_vertical = Control.GROW_DIRECTION_BOTH
		vb.add_theme_constant_override("separation", 14)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tap_panel.add_child(vb)
		var t1 := _label(22, Color("fff2c0"), 0)
		t1.text = Stage1.NAME
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t1)
		var t2 := _label(14, Color("e8c060"), 0)
		t2.text = "화면을 눌러 시작"
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t2)
		var t3 := _label(11, Color("c8b890"), 0)
		t3.text = "끌어서 이동 · 오른쪽 아래 무쌍"
		t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(t3)
		add_child(tap_panel)
	tap_panel.visible = true


func hide_tap() -> void:
	if tap_panel != null:
		tap_panel.visible = false


func banner(title: String, sub: String) -> void:
	if banner_title == null:
		return
	banner_title.text = title
	banner_sub.text = sub
	banner_sub.visible = sub != ""
	banner_t = 2.6


func refresh() -> void:
	Perf.begin(&"HUD 갱신")
	_refresh_impl()
	Perf.end()


func _fps_tick() -> void:
	var now := Time.get_ticks_usec()
	if _fps_last > 0:
		var ms := (now - _fps_last) / 1000.0
		_fps_acc.append(ms)
		if ms > 34.0:
			_fps_slow += 1
	_fps_last = now
	_fps_t += get_process_delta_time()
	if _fps_t < 0.5 or _fps_acc.is_empty():
		return
	_fps_t = 0.0
	var sum := 0.0
	var mx := 0.0
	for v in _fps_acc:
		sum += v
		mx = maxf(mx, v)
	fps_lbl.text = "FPS %d · 간격 %.1f/최대 %.1fms · 처리 %.1fms · 끊김 %d · 적 %d" % [Engine.get_frames_per_second(), sum / _fps_acc.size(), mx,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, _fps_slow, b.enemies.size()]
	_fps_acc.clear()


func _refresh_impl() -> void:
	if fps_lbl == null and ("--fps" in OS.get_cmdline_user_args() or b.playtest != null):
		fps_lbl = _label(10, Color("ffffff"), 3)
		# 기록 중이면 '지루' 버튼 오른쪽
		fps_lbl.position = Vector2(56 if bored_btn != null else 4, TOP_H + 2)
		add_child(fps_lbl)
	if fps_lbl != null:
		_fps_tick()
	if bored_btn != null:
		_playtest_tick()
	var h := b.hero
	var T := b.field_target()
	var title := "%s · %s · 공적 Lv %d" % [Stage1.NAME, _fmt_t(b.t), b.lvl]
	if title_lbl.text != title:
		title_lbl.text = title
	var goal := "목표  " + String(T.n)
	if goal_lbl.text != goal:
		goal_lbl.text = goal
	# 아군 수 자리에 유비 체력(D-208 — 유비가 쓰러지면 짐)
	var lb := ceili(b.liubei.hp / b.liubei.max_hp * 100) if Unit.alive(b.liubei) else 0
	var tags := "%s %d/%d · 진영 %d/3 · 처치 %d · 본진 %d%% · 유비 %d%%" % [b.hero_data.display_name, ceili(h.hp), roundi(h.max_hp), b.cap_n, b.kills, ceili(b.home_hp / b.home_max * 100), lb]
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
	elif b.end_why == "liubei":
		end_title.text = "유비가 쓰러졌어요"
	elif b.end_why == "army":
		end_title.text = "정원지의 대군이 본진에 닿았어요"
	else:
		end_title.text = "%s가 쓰러졌어요" % hn if Battle.eul(hn) == "를" else "%s이 쓰러졌어요" % hn
	var T := b.tactics
	var evos: Array[String] = []
	for k in T.evo:
		evos.append(T.evo_name(k))
	end_stats.text = "걸린 시간   %s\n점령한 진영   %d / 3\n쓰러뜨린 적   %d\n최대 연격   %d\n공적 레벨   %d (공격 %d/%d · 보조 %d/%d)\n진화   %s" % [
		_fmt_t(b.t), b.cap_n, b.kills, b.hero.cb_max, b.lvl, T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS,
		", ".join(evos) if not evos.is_empty() else "없음"]
	var vil := {"saved": "구함", "lost": "불탐", "raid": "습격 중"}
	end_stats.text += "\n탁현 마을   %s" % vil.get(b.vil_st, "—")
	if win and b.siege != null and b.siege.beast_t >= 0:
		# 첫 사신수 해방(D-207 — 3장)
		end_stats.text += "\n사신수   %s 해방" % SiegeData.BEAST.n
	# 판 밖 보상(D-232)
	var M: Dictionary = b.meta_got
	if not M.is_empty():
		end_stats.text += "\n\n장수 Lv %d   경험 +%d (%d/%d)" % [int(M.lv), int(M.xp), int(M.xp_now), int(M.need)]
		if int(M.lv) > int(M.lv0):
			end_stats.text += "\n레벨 업!   재능 포인트 +%d" % int(M.pts)
		end_stats.text += "\n전공 +%d   (가진 전공 %d)" % [int(M.merit), int(Save.d.merit)]
	if pt_lbl != null:
		pt_lbl.text = b.playtest.summary()
	end_panel.visible = true


static func _fmt_t(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


# ─────────── 겹쳐 그리기 ───────────

func _w2s(p: Vector2) -> Vector2:
	return p - b.view.position


func _draw_overlay() -> void:
	Perf.begin(&"그리기:HUD")
	_draw_overlay_impl()
	Perf.end()


## 몰려오는 무리 예고(Stage1.SURGE): 그 방향 화면 가장자리에 깜빡이는 붉은 삼각형 + '!'
func _draw_surge(c: Control, font: Font, sz: Vector2) -> void:
	var W: Dictionary = b.surge_warn
	if W.is_empty():
		return
	var hc := _w2s(b.hero.position)
	var a: float = W.a
	var x0 := 22.0
	var x1 := sz.x - 22
	var y0 := TOP_H + 22
	var y1 := sz.y - 22
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
	var al := 0.55 + 0.45 * sin(b.t * 16)
	var tri := PackedVector2Array([ap + Vector2(16, 0).rotated(a), ap + Vector2(-10, -13).rotated(a), ap + Vector2(-10, 13).rotated(a)])
	c.draw_colored_polygon(tri, Color(0.9, 0.25, 0.2, al))
	tri.append(tri[0])
	c.draw_polyline(tri, INK, 2)
	_text(c, font, "!", ap - Vector2.from_angle(a) * 24, 18, Color(1, 0.85, 0.8, al))


func _draw_overlay_impl() -> void:
	var c := overlay
	var sz := overlay.size
	var h := b.hero
	var font := Fonts.main()
	if h.musou_t > 0:
		c.draw_texture_rect(vignette, Rect2(Vector2.ZERO, sz), false)
	_draw_lead_bar(c, font, sz)
	_draw_surge(c, font, sz)
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
	c.draw_rect(Rect2(x0, y, w * clampf(L.hp / L.max_hp, 0, 1), 8), Color("6a9ad8") if L.shield else (Color("d9705e") if L.boss else Color("d89a3a")))
	var name: String = L.ename if L.ename != "" else String(L.def.n)
	if L.shield:
		name += " (보호막)"
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
	c.draw_rect(Rect2(mx, my + (float(Stage1.GATE.y) - 10) * s, mw, 2), Color(0.54, 0.52, 0.47, 0.6) if b.siege != null and b.siege.gate_open else Color("8a8478"))
	var K := b.keep_rect()
	c.draw_rect(Rect2(P.call(K.position), K.size * s), Color("ff6a4a") if b.boss != null else Color("d9705e"), false, 1.5)
	# 요술 제단(D-207, 노란 네모)
	for al in (b.siege.altars if b.siege != null else []):
		if not al.dead:
			var aq: Vector2 = P.call(al.position)
			c.draw_rect(Rect2(aq - Vector2(2, 2), Vector2(4, 4)), Color("f0c040"))
			c.draw_rect(Rect2(aq - Vector2(2, 2), Vector2(4, 4)), INK, false, 1.0)
	for cp in b.camps:
		var CR := b.camp_rect(cp)
		c.draw_rect(Rect2(P.call(CR.position), CR.size * s), Color("6a9ad8") if cp.cap else Color("e2b040"))
		# 남은 수비탑(D-202, 빨간 세모) · 진영장(D-205, 주황 점 — 보호막이면 푸른 테)
		for tw in cp.tws:
			if tw.alive:
				var q: Vector2 = P.call(tw.pos)
				var tri := PackedVector2Array([q + Vector2(0, -3), q + Vector2(3, 2), q + Vector2(-3, 2)])
				c.draw_colored_polygon(tri, Color("e04a3a"))
				tri.append(tri[0])
				c.draw_polyline(tri, INK, 1.0)
		if not cp.cap and Unit.alive(cp.lead):
			var lq: Vector2 = P.call(cp.lead.position)
			c.draw_circle(lq, 2.5, Color("ff9a3a"))
			c.draw_arc(lq, 3.2, 0, TAU, 12, Color("8ac8f0") if cp.lead.shield else INK, 1.0)
	# 탁현 마을(D-208): 습격 중이면 깜빡임, 불타면 회색
	var vq: Vector2 = P.call(Stage1.VILLAGE.pos)
	var vc := Color("e8d8a8")
	if b.vil_st == "raid":
		vc = Color("ff6a4a") if int(b.t * 4) % 2 == 1 else Color("ffd34a")
	elif b.vil_st == "lost":
		vc = Color("555555")
	c.draw_rect(Rect2(vq - Vector2(2.5, 2.5), Vector2(5, 5)), vc)
	var hp: Vector2 = P.call(b.home_pos)
	var blink := b.home_hp < b.home_max * 0.5 and int(b.t * 4) % 2 == 1
	c.draw_rect(Rect2(hp - Vector2(3, 3), Vector2(6, 6)), Color("ff6a4a") if blink else Color("6a9ad8"))
	# 정원지의 대군(D-214): 길(점선) · 부대마다 부장(빨간 마름모, 본진에 가까우면 깜빡) · 정원지(빨간 원)
	var A: Dictionary = Stage1.ARMY
	var ry := float(Stage1.GATE.y) + 10
	while ry < Stage1.HOME.pos.y:
		c.draw_line(P.call(Vector2(float(A.road_x), ry)), P.call(Vector2(float(A.road_x), ry + 40)), Color(0.75, 0.62, 0.42, 0.7), 1)
		ry += 80
	for u in b.army:
		if u.spawned and Unit.alive(u.lead):
			var q: Vector2 = P.call(u.lead.position)
			var near: bool = u.lead.position.distance_to(b.home_pos) < float(A.danger)
			var col := Color("ffd34a") if near and int(b.t * 4) % 2 == 1 else Color("ff4a3a")
			var dia := PackedVector2Array([q + Vector2(0, -4), q + Vector2(4, 0), q + Vector2(0, 4), q + Vector2(-4, 0)])
			c.draw_colored_polygon(dia, col)
			dia.append(dia[0])
			c.draw_polyline(dia, INK, 1.0)
	if Unit.alive(b.cyz):
		c.draw_circle(P.call(b.cyz.position), 3.5, Color("ff6a4a"))
		c.draw_arc(P.call(b.cyz.position), 3.5, 0, TAU, 12, INK, 1.0)
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
	Perf.begin(&"그리기:HUD")
	_draw_slots_impl()
	Perf.end()


func _draw_slots_impl() -> void:
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
	# 지금 가진 것: 밝은 바탕 띠에 두 줄(공격 / 보조)
	var have_box := PanelContainer.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.23, 0.19, 0.14, 0.95)
	hsb.set_corner_radius_all(6)
	hsb.set_content_margin_all(6)
	have_box.add_theme_stylebox_override("panel", hsb)
	pick_have = _label(10, Color("f4ecd8"), 0)
	pick_have.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick_have.custom_minimum_size = Vector2(316, 0)
	have_box.add_child(pick_have)
	vb.add_child(have_box)
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
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		var ds := _label(11, Color("5a4a36"), 0)
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var pr := _label(10, Color("8a5a1a"), 0)
		pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# 첫 줄: 이름 + 이유 딱지(진화! · 짝 완성 · 레벨 업 · 새 책략 — 왜 이 카드가 좋은지 한눈에)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(nm)
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bsb := StyleBoxFlat.new()
		bsb.set_corner_radius_all(5)
		bsb.content_margin_left = 5
		bsb.content_margin_right = 5
		bsb.content_margin_top = 1
		bsb.content_margin_bottom = 1
		badge.add_theme_stylebox_override("panel", bsb)
		var blbl := _label(10, Color("fffaf0"), 0)
		badge.add_child(blbl)
		top.add_child(badge)
		for l in [top, ds, pr]:
			col.add_child(l)
		vb.add_child(btn)
		cards.append({"btn": btn, "box": box, "icon": isb, "glyph": glyph, "name": nm, "desc": ds, "pair": pr, "glow": "", "badge": bsb, "badge_lbl": blbl})
	pick_reroll = Button.new()
	pick_reroll.custom_minimum_size = Vector2(0, 36)
	pick_reroll.focus_mode = Control.FOCUS_NONE
	pick_reroll.pressed.connect(b.reroll)
	pick_reroll.visible = false
	vb.add_child(pick_reroll)
	deal_no = Button.new()
	deal_no.text = "거래하지 않음"
	deal_no.custom_minimum_size = Vector2(0, 40)
	deal_no.focus_mode = Control.FOCUS_NONE
	deal_no.pressed.connect(b.decline_deal)
	deal_no.visible = false
	vb.add_child(deal_no)
	pick_panel.visible = false
	add_child(pick_panel)


static func _stars(n: int) -> String:
	return "★".repeat(n) + "☆".repeat(TacticsData.MAX_LV - n)


## deal = 적장 거래(D-230)의 적장 이름(""이면 보통 레벨업 고르기) — 카드는 DEAL.levels단계, '거래하지 않음' 버튼
func show_pick(opts: Array[Dictionary], deal := "") -> void:
	var T := b.tactics
	var D: Dictionary = Stage1.DEAL
	var step := int(D.levels) if deal != "" else 1
	if deal != "":
		pick_title.text = "적장의 병법서 — %s" % deal
		pick_sub.text = "피해 없이 이겼어요! 최대 체력 %d%%를 내주면 책략 하나를 %d단계 올려요" % [roundi(float(D.cost) * 100), step]
	else:
		pick_title.text = "공적 Lv %d — 책략 고르기" % b.lvl
		pick_sub.text = "공격 %d/%d · 보조 %d/%d · 진화 %d  ·  공격 Lv5 + 짝 보조 = 진화" % [T.act_order.size(), TacticsData.ACT_SLOTS, T.pas_order.size(), TacticsData.PAS_SLOTS, T.evo_count()]
	deal_no.visible = deal != ""
	pick_reroll.visible = b.rerolls > 0
	pick_reroll.text = "다시 뽑기 (%d번 남음)" % b.rerolls
	pick_have.text = _have_text()
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
		_set_badge(c, _reason(o))
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
		var nl := mini(TacticsData.MAX_LV, T.level(k) + step)
		var nm := T.name_of(k)
		if k == "basic":
			nm += "(%s 기본 공격)" % b.hero_data.display_name
		c.name.text = "%s  %s" % [nm, _stars(nl)]
		c.desc.text = T.level_desc(k, nl) if T.is_act(k) else "%s (Lv%d)" % [T.level_desc(k, nl), nl]
		c.pair.text = _pair_text(k) + ("  — 고르면 다음 레벨업에 진화!" if o.get("ready", false) else "")
	_pulse_cards()
	pick_panel.visible = true


## 지금 가진 것(고르기 화면 위): 공격은 이름 · Lv · 짝(가졌으면 ✓, 진화했으면 '진화'), 보조는 이름 · Lv
func _have_text() -> String:
	var T := b.tactics
	var acts: Array[String] = []
	for k in T.act_order:
		var nm := T.evo_name(k) if T.evolved(k) else T.name_of(k)
		if T.evolved(k):
			acts.append("%s(진화)" % nm)
			continue
		var p := T.pair_of(k)
		var ps := ""
		if p != "":
			ps = " 짝 %s%s" % [String(TacticsData.DEFS[p].n), "✓" if T.level(p) > 0 else ""]
		acts.append("%s Lv%d%s" % [nm, T.level(k), ps])
	var pas: Array[String] = []
	for k in T.pas_order:
		pas.append("%s Lv%d" % [T.name_of(k), T.level(k)])
	return "가진 공격  %s\n가진 보조  %s" % [" · ".join(acts) if not acts.is_empty() else "없음", " · ".join(pas) if not pas.is_empty() else "없음"]


## 카드를 고를 이유(딱지): [글, 색]. 진화 > 진화 준비 > 짝 완성 > 레벨 업 > 새 책략
func _reason(o: Dictionary) -> Array:
	var T := b.tactics
	var k: String = o.k
	if k == "bun":
		return ["회복", Color("8a7a5a")]
	if o.get("evo", false):
		return ["진화!", Color("d8902a")]
	if o.get("ready", false):
		return ["진화 준비", Color("d8902a")]
	if T.is_act(k):
		var p := T.pair_of(k)
		if o.get("new", false) and p != "" and T.level(p) > 0:
			return ["짝 있음", Color("c06a2a")]
	elif o.get("new", false):
		for a in T.pairs_for(k):
			if T.level(a) > 0 and not T.evolved(a):
				return ["짝 완성", Color("c06a2a")]
	if o.get("new", false):
		return ["새 책략", Color("4a7ab8")]
	return ["레벨 업", Color("4a8a5a")]


func _set_badge(c: Dictionary, r: Array) -> void:
	(c.badge as StyleBoxFlat).bg_color = r[1]
	(c.badge_lbl as Label).text = r[0]


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
	deal_no.visible = false


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

# ─────────── 사람 플레이 기록(D-221) ───────────

func _build_playtest() -> void:
	bored_btn = ColorRect.new()
	bored_btn.color = Color(0.11, 0.09, 0.07, 0.6)
	bored_btn.position = Vector2(6, TOP_H + 4)
	bored_btn.size = Vector2(44, 26)
	bored_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := _label(12, Color("fff2c0"), 2)
	l.text = "지루"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bored_btn.add_child(l)
	add_child(bored_btn)
	pt_lbl = _label(11, Color("5a4a36"), 0)
	end_vb.add_child(pt_lbl)
	var copy := Button.new()
	copy.text = "기록 복사"
	copy.custom_minimum_size = Vector2(0, 40)
	copy.pressed.connect(_pt_copy)
	end_vb.add_child(copy)
	pt_msg = _label(11, Color("5a4a36"), 0)
	pt_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pt_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pt_msg.visible = false
	end_vb.add_child(pt_msg)
	pt_edit = TextEdit.new()
	pt_edit.editable = false
	pt_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	pt_edit.custom_minimum_size = Vector2(0, 140)
	pt_edit.add_theme_font_size_override("font_size", 9)
	pt_edit.visible = false
	end_vb.add_child(pt_edit)
	# '다시 하기'는 맨 아래에
	end_vb.move_child(end_retry, end_vb.get_child_count() - 1)


func flash_bored() -> void:
	_bored_flash = 0.35


func _playtest_tick() -> void:
	var dt := get_process_delta_time()
	bored_btn.visible = b.state == "play"
	_bored_flash = maxf(0.0, _bored_flash - dt)
	bored_btn.color = Color(0.11, 0.09, 0.07, 0.6).lerp(Color(0.95, 0.75, 0.25, 0.95), _bored_flash / 0.35)
	if _pt_wait > 0:
		_pt_wait -= dt
		var r = JavaScriptBridge.eval("window._tkfClip", true)
		var st := int(r) if r != null else 0
		if st == 1:
			_pt_wait = 0.0
			_pt_note("복사했어요 (%d자)" % b.playtest.text.length())
		elif st == 2 or _pt_wait <= 0:
			_pt_wait = 0.0
			_pt_fallback()


## 기록 복사: PC는 DisplayServer.clipboard_set. 웹은 navigator.clipboard를 직접 불러 성공 · 실패를 받음
## (iOS Safari는 터치 처리 안에서 부르지 않으면 막을 수 있음 — 막히면 _pt_fallback)
const JS_COPY := "window._tkfClip=0;window._tkfText=%s;try{navigator.clipboard.writeText(window._tkfText).then(function(){window._tkfClip=1},function(){window._tkfClip=2})}catch(e){window._tkfClip=2}"
## 웹 대신 창: 게임 화면(캔버스) 위의 HTML 글 상자 — iOS에서 길게 눌러 고르고 복사할 수 있음(Godot TextEdit는 웹에서 OS 클립보드로 못 꺼냄)
const JS_SHOW := "(function(){var d=document.getElementById('tkfPt');if(!d){d=document.createElement('div');d.id='tkfPt';d.style.cssText='position:fixed;left:4vw;right:4vw;top:8vh;bottom:8vh;z-index:99;background:#f4ecd8;border:3px solid #3a2a1a;border-radius:10px;padding:8px;display:flex;flex-direction:column;gap:6px;touch-action:auto';var p=document.createElement('div');p.textContent='복사가 막혔어요 — 글을 길게 눌러 전체 선택 → 복사';p.style.cssText='font:14px sans-serif;color:#3a2a1a';var ta=document.createElement('textarea');ta.id='tkfPtTa';ta.readOnly=true;ta.style.cssText='flex:1;font:11px monospace;touch-action:auto;-webkit-user-select:text;user-select:text';var c=document.createElement('button');c.textContent='닫기';c.style.cssText='font:16px sans-serif;padding:8px';c.onclick=function(){d.style.display=\'none\'};d.appendChild(p);d.appendChild(ta);d.appendChild(c);document.body.appendChild(d);}d.style.display='flex';var t=document.getElementById('tkfPtTa');t.value=window._tkfText;t.focus();t.setSelectionRange(0,t.value.length);})()"


func _pt_copy() -> void:
	var s: String = b.playtest.text
	if s == "":
		return
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_COPY % JSON.stringify(s), true)
		_pt_wait = 1.5
		_pt_note("복사 중…")
		return
	DisplayServer.clipboard_set(s)
	if DisplayServer.clipboard_get() == s:
		_pt_note("복사했어요 (%d자)" % s.length())
	else:
		_pt_fallback()


func _pt_fallback() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(JS_SHOW, true)
		_pt_note("복사가 막혀 기록 글 창을 띄웠어요 — 길게 눌러 복사")
		return
	pt_edit.text = b.playtest.text
	pt_edit.visible = true
	pt_edit.select_all()
	_pt_note("복사가 안 돼요 — 아래 글을 골라 복사")


func _pt_note(s: String) -> void:
	pt_msg.text = s
	pt_msg.visible = true


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
