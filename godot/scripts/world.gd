class_name World
extends Node2D
## 천하 지도 최소판(D-235, WorldData): 끌어서(방향키 · WASD) 걸어 다니다 장소에 가까이 가면 아래 안내판 → '들어가기'(E · Enter).
## 대장간 · 군막은 판 밖 성장 창(MetaUI), 1장 모형은 출진(battle.tscn). 강 건너는 1장을 깨기 전엔 안개로 막힘.
## 봇(--bot)은 곧바로 전장으로(봇 테스트 · 스크린샷 명령이 전처럼 돎). 점검: --world-test --shots=<폴더>(장소마다 찍고 끝냄).

const BATTLE_SCENE := "res://scenes/battle.tscn"
const STICK_DEAD := 8.0
const STICK_FULL := 50.0
const INK := Color(0.11, 0.09, 0.07)

@export var hero_data: HeroData

var pos := WorldData.START
var face := Vector2(0, 1)
var moving := false
var t := 0.0
var joy_on := false
var joy_id := -1
var joy_o := Vector2.ZERO
var joy_p := Vector2.ZERO
var near := {}
var tex: Texture2D
var cam: Camera2D
var ui: CanvasLayer
var meta: MetaUI
var top_lbl: Label
var sign_box: PanelContainer
var sign_lbl: Label
var sign_btn: Button
var msg_lbl: Label
var msg_t := 0.0
var shot_dir := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--bot" in args:
		get_tree().change_scene_to_file.call_deferred(BATTLE_SCENE)
		return
	for a in args:
		if a.begins_with("--shots="):
			shot_dir = a.substr(8)
	tex = Sprites.sheet(hero_data.sprite_key)
	cam = Camera2D.new()
	add_child(cam)
	_build_ui()
	_place_camera()
	if "--world-test" in args:
		_world_test()


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	top_lbl = _label(12, Color("f4ecd8"))
	top_lbl.position = Vector2(10, 8)
	ui.add_child(top_lbl)
	msg_lbl = _label(14, Color("fff2c0"))
	msg_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	msg_lbl.position = Vector2(-160, 60)
	msg_lbl.custom_minimum_size = Vector2(320, 0)
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(msg_lbl)
	# 아래 안내판(가까운 장소 이름 · 아랫줄 · 들어가기)
	sign_box = PanelContainer.new()
	sign_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sign_box.custom_minimum_size = Vector2(300, 0)
	sign_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sign_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sign_box.position.y -= 24
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ecd8")
	sb.border_color = Color("3a2a1a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	sign_box.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	sign_box.add_child(vb)
	sign_lbl = _label(13, Color("3a2a1a"), 0)
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sign_lbl)
	sign_btn = Button.new()
	sign_btn.custom_minimum_size = Vector2(0, 44)
	sign_btn.focus_mode = Control.FOCUS_NONE
	sign_btn.pressed.connect(_enter)
	vb.add_child(sign_btn)
	sign_box.visible = false
	ui.add_child(sign_box)
	meta = MetaUI.new()
	ui.add_child(meta)
	meta.setup(hero_data)
	meta.closed.connect(_refresh_top)
	_refresh_top()


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


func _refresh_top() -> void:
	top_lbl.text = "천하 지도 — %s · 장수 Lv %d · 전공 %d · 재능 포인트 %d" % [hero_data.display_name, Save.lv(), int(Save.d.merit), Save.tal_left()]


func fog_on() -> bool:
	return int(Save.d.clears) < int(WorldData.FOG.clears)


func _open(P: Dictionary) -> bool:
	return int(Save.d.clears) >= int(P.get("need_clear", 0))


func _process(dt: float) -> void:
	t += dt
	if msg_t > 0:
		msg_t -= dt
		msg_lbl.modulate.a = clampf(msg_t / 0.5, 0, 1)
	var v := Vector2.ZERO if meta.is_open() else _move_vec()
	moving = v.length() > 0.05
	if moving:
		face = v
		var np := pos + v * hero_data.move_speed * dt
		np = np.clamp(Vector2(20, 20), WorldData.SIZE - Vector2(20, 20))
		# 강은 나루(다리)로만 건넘, 안개 너머는 못 감
		var R: Dictionary = WorldData.RIVER
		var in_river := np.y > float(R.y0) and np.y < float(R.y1) and absf(np.x - WorldData.SIZE.x / 2) > float(R.bridge) / 2
		if fog_on() and np.y < float(WorldData.FOG.y):
			np.y = float(WorldData.FOG.y)
			if msg_t <= 0:
				_say("강 건너는 안개에 덮여 있어요 — 1장을 평정하면 걷혀요")
		if not in_river:
			pos = np
	# 가까운 장소
	var best := {}
	var bd := INF
	for P in WorldData.PLACES:
		var d := pos.distance_to(P.pos)
		if d < float(P.r) and d < bd:
			bd = d
			best = P
	if best != near:
		near = best
		_refresh_sign()
	_place_camera()
	queue_redraw()


func _refresh_sign() -> void:
	sign_box.visible = not near.is_empty()
	if near.is_empty():
		return
	var ok := _open(near)
	sign_lbl.text = "%s\n%s" % [near.n, near.sub if ok else "잠김 — 1장을 평정하면"]
	sign_btn.text = {"forge": "대장간 들어가기", "tent": "군막 들어가기", "stage1": "출진!"}.get(near.k, "살펴보기")
	sign_btn.disabled = not ok


func _enter() -> void:
	if near.is_empty() or not _open(near) or meta.is_open():
		return
	match String(near.k):
		"forge":
			meta.forge_open()
		"tent":
			meta.tal_open()
		"stage1":
			get_tree().change_scene_to_file(BATTLE_SCENE)
		_:
			_say("%s — 아직 준비 중이에요" % near.n)


func _say(s: String) -> void:
	msg_lbl.text = s
	msg_t = 2.5


func _move_vec() -> Vector2:
	var v := Vector2.ZERO
	if joy_on:
		var d := joy_p - joy_o
		if d.length() > STICK_DEAD:
			v = d.normalized() * minf(1.0, d.length() / STICK_FULL)
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		v.x = -1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		v.x = 1
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		v.y = -1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		v.y = 1
	return v.limit_length(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed and not joy_on and not meta.is_open():
			joy_on = true
			joy_id = ev.index
			joy_o = ev.position
			joy_p = ev.position
		elif not ev.pressed and ev.index == joy_id:
			joy_on = false
			joy_id = -1
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		if joy_on and ev.index == joy_id:
			joy_p = ev.position
	elif event is InputEventKey:
		var ev := event as InputEventKey
		if ev.pressed and not ev.echo and (ev.physical_keycode == KEY_E or ev.physical_keycode == KEY_ENTER):
			_enter()


func _place_camera() -> void:
	var vs := get_viewport_rect().size
	var c := pos + Vector2(0, -vs.y * 0.08)
	c.x = clampf(c.x, vs.x / 2, WorldData.SIZE.x - vs.x / 2)
	c.y = clampf(c.y, vs.y / 2, WorldData.SIZE.y - vs.y / 2)
	cam.position = c


# ─────────── 그리기(임시 — 코드로 그린 바닥 · 장소) ───────────

func _draw() -> void:
	var S := WorldData.SIZE
	draw_rect(Rect2(Vector2.ZERO, S), Color("5f8a3e"))
	# 길: 군영 → 1장 → 나루 → 2장
	draw_line(Vector2(S.x / 2, 1300), Vector2(S.x / 2, 300), Color("b89a62"), 26)
	draw_line(Vector2(210, 1170), Vector2(510, 1170), Color("b89a62"), 22)
	# 강(황하)과 나루
	var R: Dictionary = WorldData.RIVER
	draw_rect(Rect2(0, float(R.y0), S.x, float(R.y1) - float(R.y0)), Color("4a7ab8"))
	draw_rect(Rect2(S.x / 2 - float(R.bridge) / 2, float(R.y0) - 6, float(R.bridge), float(R.y1) - float(R.y0) + 12), Color("8a5a2a"))
	_text(Vector2(S.x / 2 + 70, float(R.y1) + 18), "황하 · 맹진 나루", 11, Color("e8f0f8"))
	# 군영 울타리
	draw_rect(Rect2(120, 1080, 480, 250), Color(0.3, 0.22, 0.12, 0.25))
	draw_rect(Rect2(120, 1080, 480, 250), Color("6a4a2a"), false, 4)
	_text(Vector2(S.x / 2, 1100), "관우의 군영", 13, Color("fff2c0"))
	for P in WorldData.PLACES:
		_draw_place(P)
	# 안개
	if fog_on():
		draw_rect(Rect2(0, 0, S.x, float(WorldData.FOG.y)), Color(0.85, 0.87, 0.9, 0.82))
		_text(Vector2(S.x / 2, float(WorldData.FOG.y) - 40), "안개 — 1장을 평정하면 걷혀요", 13, Color("3a3a44"))
	_draw_hero()


func _draw_place(P: Dictionary) -> void:
	var p: Vector2 = P.pos
	var ok := _open(P)
	var near_it: bool = not near.is_empty() and near.k == P.k
	if near_it:
		draw_circle(p, float(P.r), Color(1, 0.9, 0.5, 0.18))
	var col := Color("c8a874") if ok else Color("8a8a8a")
	if String(P.k).begins_with("stage"):
		# 장 모형: 작은 성 + 깃발
		draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 44)), col)
		draw_rect(Rect2(p - Vector2(34, 22), Vector2(68, 44)), INK, false, 2)
		for dx in [-34.0, -10.0, 14.0]:
			draw_rect(Rect2(p + Vector2(dx, -32), Vector2(20, 10)), col)
		draw_line(p + Vector2(0, -32), p + Vector2(0, -62), INK, 2)
		draw_rect(Rect2(p + Vector2(0, -62), Vector2(22, 14)), Color("d8b23a") if ok else Color("aaaaaa"))
	else:
		# 천막
		var pts := PackedVector2Array([p + Vector2(-34, 20), p + Vector2(0, -30), p + Vector2(34, 20)])
		draw_colored_polygon(pts, col)
		draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 2)
	_text(p + Vector2(0, 6), String(P.glyph), 18, INK)
	_text(p + Vector2(0, 44), String(P.n), 12, Color("fff2c0") if ok else Color("dddddd"))


func _draw_hero() -> void:
	draw_circle(pos + Vector2(0, 8), 12, Color(0, 0, 0, 0.25))
	if tex == null:
		draw_circle(pos, 12, Color("3f7a3a"))
		draw_circle(pos, 12, INK, false, 1.5)
		_text(pos + Vector2(0, 5), hero_data.display_name.left(1), 13, INK)
		return
	var size := hero_data.sprite_size
	var w := size * 0.8
	var h := size * 1.6
	draw_texture_rect_region(tex, Rect2(pos.x - w / 2, pos.y + size * 0.52 - h, w, h), Sprites.region(Sprites.dir_of(face), Sprites.walk_step(moving, t, 10)))


func _text(at: Vector2, s: String, size: int, col: Color) -> void:
	var f := Fonts.at(size)
	draw_string_outline(f, at - Vector2(150, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 300, size, 3, INK if col != INK else Color(1, 1, 1, 0.6))
	draw_string(f, at - Vector2(150, 0), s, HORIZONTAL_ALIGNMENT_CENTER, 300, size, col)


# ─────────── 점검(--world-test): 장소마다 가서 찍고 끝냄 ───────────

func _world_test() -> void:
	await get_tree().create_timer(0.3).timeout
	_shot("world_start")
	for k in ["forge", "tent", "stage1"]:
		for P in WorldData.PLACES:
			if P.k == k:
				pos = P.pos + Vector2(0, 30)
		await get_tree().create_timer(0.3).timeout
		_shot("world_" + k)
		if k != "stage1":
			_enter()
			await get_tree().create_timer(0.3).timeout
			_shot("world_" + k + "_open")
			meta.forge_panel.visible = false
			meta.tal_panel.visible = false
	# 안개에 막히는지: 북쪽으로 3초 걸어 봄(키 대신 joy)
	joy_on = true
	joy_o = Vector2(180, 400)
	joy_p = Vector2(180, 300)
	await get_tree().create_timer(4.0).timeout
	joy_on = false
	print("[world] 북쪽으로 걸은 뒤 y=%d (안개 %s · 깬 판 %d)" % [int(pos.y), "켬" if fog_on() else "걷힘", int(Save.d.clears)])
	_shot("world_north")
	get_tree().quit(0)


func _shot(name: String) -> void:
	if shot_dir == "":
		return
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(shot_dir)
	img.save_png(shot_dir.path_join(name + ".png"))
