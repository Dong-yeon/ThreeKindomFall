extends Control
## 장수 선택 화면(D-285) — 시작 장면. 카드 3장: 이름 · 역할 · 난이도(★) · 시작 초식 · 고유 심법 · 절기(???로 가림).
## 고르기: 1 · 2 · 3 키 또는 카드 클릭 → HeroTable.chosen에 넣고 main.tscn으로.
## 명령줄(`--` 뒤)이나 웹 주소에 판 옵션(--hero · --auto · --bench · --test · --shots …)이 있으면 곧바로 판으로(봇 · 점검 유지).
## 점검: --select-test --shots=<폴더> [--select-key=2] — 카드 스크린샷 → 그 번호를 고른 것처럼 판으로 → main이 장수를 출력하고 끝냄.

const MAIN := "res://scenes/main.tscn"
var opts := {}
var cards: Array[Button] = []
var t := 0.0
var shot_done := false

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
	if not opts.has("select-test") and not opts.is_empty():
		get_tree().change_scene_to_file.call_deferred(MAIN)   # 판 옵션이 있으면 선택 화면을 건너뜀
		return
	_build()

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1e2a24")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "장수를 고르세요"
	title.position = Vector2(0, 60)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)
	var hint := Label.new()
	hint.text = "1 · 2 · 3 키 또는 클릭   ·   이동 WASD · 경공 Shift · 절기 Space"
	hint.position = Vector2(0, 640)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.8))
	add_child(hint)
	var x := 640 - (3 * 360 + 2 * 30) / 2
	for k in HeroTable.ORDER.size():
		var id: String = HeroTable.ORDER[k]
		var h: Dictionary = HeroTable.HEROES[id]
		var b := Button.new()
		b.position = Vector2(x + k * 390, 150)
		b.size = Vector2(360, 460)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 20)
		var stars := "★".repeat(int(h.stars)) + "☆".repeat(3 - int(h.stars))
		b.text = "%d.\n\n%s\n%s\n난이도 %s %s\n\n시작 무공\n  %s\n\n고유 심법\n  %s\n  (%s)\n\n절기\n  ???" % [
			k + 1, h.name, h.role, stars, h.star_label, h.weapon.name, h.passive.name, h.passive.desc]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_choose.bind(k))
		add_child(b)
		cards.append(b)

func _process(delta: float) -> void:
	t += delta
	for k in cards.size():
		if Input.is_physical_key_pressed(KEY_1 + k):
			_choose(k)
			return
	if opts.has("select-test") and t > 0.5 and not shot_done:
		shot_done = true
		await RenderingServer.frame_post_draw
		if opts.has("shots"):
			DirAccess.make_dir_recursive_absolute(opts["shots"])
			var path := String(opts["shots"]).path_join("select.png")
			get_viewport().get_texture().get_image().save_png(path)
			print("SHOT ", path)
		_choose(int(opts.get("select-key", "1")) - 1)   # 키 입력을 흉내 냄

func _choose(k: int) -> void:
	if k < 0 or k >= HeroTable.ORDER.size():
		return
	HeroTable.chosen = HeroTable.ORDER[k]
	print("SELECT chosen=", HeroTable.chosen)
	set_process(false)
	get_tree().change_scene_to_file.call_deferred(MAIN)
