extends Control
## 장수 선택 화면(D-285 · D-292 · D-299) — 시작 장면.
## 카드: 위쪽 장수 미리보기(SubViewport — glb idle으로 천천히 돎, 잠긴 장수는 검은 실루엣) · 아래 이름 · 역할 · 난이도(★) ·
##   고유 무기 · 고유 심법 · 경공 · 절기(???로 가림). 잠긴 장수는 해금 과제 · 조건 · 진행 막대(data/unlocks.gd · Meta).
## 고르기(D-299): 숫자 키 · 카드 클릭 → 카드가 금테로 빛나고 '출진 [Enter]' → Enter 또는 같은 카드를 한 번 더 클릭하면 main.tscn으로.
## Q 키 또는 '과제' 단추로 과제 창(줄마다 진행 막대).
## 명령줄(`--` 뒤)이나 웹 주소에 판 옵션(--hero · --auto · --bench · --test · --shots …)이 있으면 곧바로 판으로(봇 · 점검 유지).
##   메타 옵션(--save · --unlock-all)만 있으면 선택 화면을 그대로 띄움.
## 점검: --select-test --shots=<폴더> [--select-key=2] [--select-quests] — 카드(· 과제 창) 스크린샷 → 그 번호로 곧바로 출진 → main이 장수를 출력하고 끝냄.

const MAIN := "res://scenes/main.tscn"
const META_OPTS := ["save", "unlock-all"]
const CARD_W := 290.0
const CARD_H := 500.0
const CARD_GAP := 16.0
const VIEW_H := 210.0
var opts := {}
var cards: Array = []         # [{btn, style, pivot}]
var selected := -1
var go_lbl: Label
var quest_box: Panel
var t := 0.0
var shot_done := false
var q_was := false
var enter_was := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if typeof(q) == TYPE_STRING and q.length() > 1:
			for pair in (q as String).substr(1).split("&"):
				var kv := pair.split("=", true, 1)
				opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var run_opts := opts.keys().filter(func(k): return not (k in META_OPTS))
	if not opts.has("select-test") and not run_opts.is_empty():
		get_tree().change_scene_to_file.call_deferred(MAIN)   # 판 옵션이 있으면 선택 화면을 건너뜀
		return
	_build()

func _unlocked(id: String) -> bool:
	return Meta.is_unlocked("hero", id)

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := UiKit.rect(Rect2(0, 0, 1280, 720), Color("16201b"))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := UiKit.label("장수를 고르세요", 36, UiKit.GOLD, 6)
	title.position = Vector2(0, 34)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var hint := UiKit.label("숫자 키 · 클릭으로 고르고 Enter(또는 한 번 더 클릭)로 출진   ·   Q 과제   ·   이동 WASD · 경공 Shift · 절기 Space", 16, UiKit.TEXT_DIM, 3)
	hint.position = Vector2(0, 682)
	hint.size = Vector2(1280, 26)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	go_lbl = UiKit.label("", 22, UiKit.GOLD, 5)
	go_lbl.size = Vector2(CARD_W, 30)
	go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_lbl.visible = false
	add_child(go_lbl)
	var n := HeroTable.ORDER.size()
	var x0 := 640.0 - (n * CARD_W + (n - 1) * CARD_GAP) * 0.5
	for k in n:
		_card(k, Vector2(x0 + k * (CARD_W + CARD_GAP), 104))
	var qb := Button.new()
	qb.text = "과제 (Q)   %d / %d" % [Meta.data.done.size(), UnlockTable.QUESTS.size()]
	qb.position = Vector2(1280 - 230, 36)
	qb.size = Vector2(200, 44)
	qb.focus_mode = Control.FOCUS_NONE
	qb.add_theme_font_size_override("font_size", 18)
	qb.add_theme_stylebox_override("normal", UiKit.style(UiKit.INK_SOLID, UiKit.GOLD_DIM))
	qb.add_theme_stylebox_override("hover", UiKit.style(UiKit.INK_SOLID, UiKit.GOLD))
	qb.pressed.connect(_toggle_quests)
	add_child(qb)
	_build_quests()

func _card(k: int, pos: Vector2) -> void:
	var id: String = HeroTable.ORDER[k]
	var h: Dictionary = HeroTable.HEROES[id]
	var open := _unlocked(id)
	var b := Button.new()
	b.position = pos
	b.size = Vector2(CARD_W, CARD_H)
	b.focus_mode = Control.FOCUS_NONE
	var st := UiKit.style(UiKit.INK_SOLID, UiKit.GOLD_DIM, 2, 6)
	for s in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(s, st)
	b.pressed.connect(_click.bind(k))
	b.mouse_entered.connect(func(): if open and selected != k: st.border_color = UiKit.GOLD)
	b.mouse_exited.connect(func(): if selected != k: st.border_color = UiKit.GOLD_DIM)
	add_child(b)
	# 미리보기
	var vc := SubViewportContainer.new()
	vc.position = Vector2(8, 8)
	vc.size = Vector2(CARD_W - 16, VIEW_H)
	vc.stretch = true
	vc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vc)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(int(CARD_W - 16), int(VIEW_H))
	vc.add_child(vp)
	var pivot := Node3D.new()
	vp.add_child(pivot)
	var model: Node3D = load(h.glb).instantiate()
	pivot.add_child(model)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")
	if not open:
		_silhouette(model)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.45, 4.6)
	cam.fov = 38
	vp.add_child(cam)
	cam.look_at(Vector3(0, 1.15, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 25, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("c8d0d8")
	e.ambient_light_energy = 0.5
	env.environment = e
	vp.add_child(env)
	# 글
	var y := VIEW_H + 18
	var num := UiKit.label("%d" % (k + 1), 16, UiKit.TEXT_DIM, 3)
	num.position = Vector2(14, 12)
	b.add_child(num)
	var nm := UiKit.label(h.name, 28, UiKit.GOLD if open else UiKit.TEXT_DIM, 4)
	nm.position = Vector2(16, y)
	b.add_child(nm)
	var stars := "★".repeat(int(h.stars)) + "☆".repeat(3 - int(h.stars))
	var role := UiKit.label("%s   %s %s" % [h.role, stars, h.star_label], 16, UiKit.TEXT_DIM, 2)
	role.position = Vector2(16, y + 38)
	b.add_child(role)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = Vector2(16, y + 68)
	body.size = Vector2(CARD_W - 32, CARD_H - y - 76)
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("default_color", UiKit.TEXT)
	b.add_child(body)
	if open:
		body.text = "[color=#d8b860]무기[/color]  %s\n[color=#d8b860]심법[/color]  %s — %s\n[color=#d8b860]경공[/color]  %s\n[color=#d8b860]절기[/color]  ???" % [
			h.weapon.name, h.passive.name, h.passive.desc, h.qinggong.name]
	else:
		var q := Meta.quest_for("hero", id)
		var p := Meta.progress(q)
		body.text = "[color=#c8483a][ 잠김 ][/color]\n\n해금 — [color=#d8b860]%s[/color]\n%s" % [q.name, q.desc]
		var bar := UiKit.Bar.new(b, Rect2(16, CARD_H - 40, CARD_W - 32, 22), UiKit.GOLD_DIM, 14)
		bar.set_value(p.x / maxf(p.y, 1.0), "%d / %d" % [int(p.x), int(p.y)])
	cards.append({"btn": b, "style": st, "pivot": pivot, "open": open})

func _silhouette(n: Node) -> void:
	## 잠긴 장수: 모든 메시를 검은 실루엣으로.
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.03, 0.03, 0.04)
	for c in n.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = m

func _build_quests() -> void:
	quest_box = UiKit.panel(Rect2(190, 96, 900, 560), UiKit.INK_SOLID, UiKit.GOLD)
	quest_box.visible = false
	add_child(quest_box)
	var head := UiKit.label("과제  (깬 것 %d / %d)   —   Q 닫기" % [Meta.data.done.size(), UnlockTable.QUESTS.size()], 20, UiKit.GOLD, 0)
	head.position = Vector2(24, 14)
	quest_box.add_child(head)
	var y := 54.0
	for q in UnlockTable.QUESTS:
		var p := Meta.progress(q)
		var done: bool = q.id in Meta.data.done
		var col: Color = UiKit.GOLD if done else UiKit.TEXT
		var l := UiKit.label("%s  %s — %s" % ["✔" if done else "□", q.name, q.desc], 17, col, 0)
		l.position = Vector2(24, y)
		quest_box.add_child(l)
		var r := UiKit.label("보상: " + Meta.reward_name(q), 15, UiKit.GOLD if done else UiKit.TEXT_DIM, 0)
		r.position = Vector2(560, y + 24)
		quest_box.add_child(r)
		var bar := UiKit.Bar.new(quest_box, Rect2(48, y + 26, 480, 16), UiKit.GOLD if done else UiKit.GOLD_DIM, 12)
		bar.set_value(1.0 if done else p.x / maxf(p.y, 1.0), "완료" if done else "%d / %d" % [int(p.x), int(p.y)])
		y += 54.0

func _toggle_quests() -> void:
	quest_box.visible = not quest_box.visible

func _select(k: int) -> void:
	if k < 0 or k >= cards.size() or not cards[k].open:
		return
	selected = k
	for j in cards.size():
		(cards[j].style as StyleBoxFlat).border_color = UiKit.GOLD if j == k else UiKit.GOLD_DIM
		(cards[j].style as StyleBoxFlat).set_border_width_all(4 if j == k else 2)
	var b: Button = cards[k].btn
	go_lbl.position = Vector2(b.position.x, b.position.y + CARD_H + 6)
	go_lbl.text = "▶ 출진 [Enter]"
	go_lbl.visible = true

func _click(k: int) -> void:
	if selected == k:
		_choose(k)
	else:
		_select(k)

func _process(delta: float) -> void:
	t += delta
	for c in cards:
		(c.pivot as Node3D).rotation.y = sin(t * 0.6) * 0.6
	var qk := Input.is_physical_key_pressed(KEY_Q)
	if qk and not q_was:
		_toggle_quests()
	q_was = qk
	if not quest_box.visible:
		for k in cards.size():
			if Input.is_physical_key_pressed(KEY_1 + k):
				_select(k)
		var ek := Input.is_physical_key_pressed(KEY_ENTER) or Input.is_physical_key_pressed(KEY_KP_ENTER)
		if ek and not enter_was and selected >= 0:
			_choose(selected)
			return
		enter_was = ek
	if opts.has("select-test") and t > 0.8 and not shot_done:
		shot_done = true
		var key := int(opts.get("select-key", "1")) - 1
		_select(key)
		if opts.has("shots"):
			DirAccess.make_dir_recursive_absolute(opts["shots"])
			await RenderingServer.frame_post_draw
			_save_shot("select.png")
			if opts.has("select-quests"):
				quest_box.visible = true
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				_save_shot("select_quests.png")
				quest_box.visible = false
		print("SELECT locked=", ",".join(HeroTable.ORDER.filter(func(id): return not _unlocked(id))))
		if not _choose(key):   # 점검은 곧바로 출진(잠긴 장수면 안 넘어감)
			print("SELECT refused key=%d (잠김)" % (key + 1))
			get_tree().quit()

func _save_shot(name: String) -> void:
	var path := String(opts["shots"]).path_join(name)
	get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", path)

func _choose(k: int) -> bool:
	if k < 0 or k >= HeroTable.ORDER.size() or not _unlocked(HeroTable.ORDER[k]):
		return false
	HeroTable.chosen = HeroTable.ORDER[k]
	print("SELECT chosen=", HeroTable.chosen)
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(MAIN)
	return true
