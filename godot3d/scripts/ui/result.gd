extends Control
## 결과 창 · 일시정지(D-300). main이 show_result(main, title, fresh) / show_pause(main) / hide_all()을 부름.
## 결과: 제목 · 장수 · 기록 표(버틴 시간 · 처치 · 레벨 · 깬 진영 · 여포 처치 시간 · 절기 사용) · 빌드 한 줄 · 새로 해금(있을 때) · [다시 R] [장수 선택 Esc].
## 일시정지(P · 판 중 Esc): [계속] [장수 선택으로(이번 판 기록 안 남김)] + 빌드 · 조작 안내.

var main
var dim: ColorRect
var box: Panel
var title: Label
var body: RichTextLabel
var btns: Array[Button] = []

func setup(m) -> void:
	main = m
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	dim = UiKit.rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.62))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	box = UiKit.panel(Rect2(320, 120, 640, 470), UiKit.INK_SOLID, UiKit.GOLD)
	add_child(box)
	title = UiKit.label("", 34, UiKit.GOLD, 6)
	title.position = Vector2(0, 18)
	title.size = Vector2(640, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.position = Vector2(40, 78)
	body.size = Vector2(560, 300)
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_color_override("default_color", UiKit.TEXT)
	box.add_child(body)
	for k in 2:
		var b := Button.new()
		b.position = Vector2(70 + k * 270, 400)
		b.size = Vector2(230, 48)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_stylebox_override("normal", UiKit.style(Color(0.12, 0.13, 0.12), UiKit.GOLD_DIM))
		b.add_theme_stylebox_override("hover", UiKit.style(Color(0.18, 0.17, 0.12), UiKit.GOLD))
		b.add_theme_stylebox_override("pressed", UiKit.style(Color(0.18, 0.17, 0.12), UiKit.GOLD))
		b.pressed.connect(_press.bind(k))
		box.add_child(b)
		btns.append(b)

var mode := ""

func _press(k: int) -> void:
	match mode:
		"result":
			if k == 0:
				get_tree().reload_current_scene()
			else:
				get_tree().change_scene_to_file("res://scenes/select.tscn")
		"pause":
			if k == 0:
				main.resume()
			else:
				get_tree().change_scene_to_file("res://scenes/select.tscn")

func show_result(head: String, rows: Array, build: String, fresh: Array) -> void:
	mode = "result"
	title.text = head
	var t := "[table=2]"
	for r in rows:
		t += "[cell][color=#a8a49a]%s[/color]   [/cell][cell]%s[/cell]" % [r[0], r[1]]
	t += "[/table]\n\n[color=#d8b860]빌드[/color]  " + build
	if not fresh.is_empty():
		t += "\n\n[color=#d8b860]✦ 새로 해금![/color]"
		for q in fresh:
			t += "\n   %s — [color=#d8b860]%s[/color]" % [q.name, Meta.reward_name(q)]
	body.text = t
	btns[0].text = "다시  [R]"
	btns[1].text = "장수 선택  [Esc]"
	visible = true

func show_pause(build: String, hero: Dictionary) -> void:
	mode = "pause"
	title.text = "일시정지"
	body.text = "[color=#d8b860]%s[/color]  ·  %s\n\n[color=#d8b860]빌드[/color]  %s\n\n[color=#a8a49a]이동 WASD · 경공 Shift · 절기 Space · 레벨업 1 · 2 · 3\n점검용 글 F3 · 계속 P / Esc[/color]" % [hero.name, hero.role, build]
	btns[0].text = "계속  [P]"
	btns[1].text = "장수 선택으로"
	btns[1].tooltip_text = "이번 판 기록은 남지 않음"
	visible = true

func hide_all() -> void:
	visible = false
