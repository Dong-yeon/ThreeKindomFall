extends Control
## 장수 선택 화면(D-285 · D-292) — 시작 장면. 카드: 이름 · 역할 · 난이도(★) · 시작 초식 · 고유 심법 · 절기(???로 가림).
## D-292: 잠긴 장수는 어둡게 + 해금 조건 · 진행도(data/unlocks.gd · Meta). Q 키 또는 '과제' 단추로 과제 목록.
## 고르기: 숫자 키 또는 카드 클릭(열린 장수만) → HeroTable.chosen에 넣고 main.tscn으로.
## 명령줄(`--` 뒤)이나 웹 주소에 판 옵션(--hero · --auto · --bench · --test · --shots …)이 있으면 곧바로 판으로(봇 · 점검 유지).
##   메타 옵션(--save · --unlock-all)만 있으면 선택 화면을 그대로 띄움.
## 점검: --select-test --shots=<폴더> [--select-key=2] [--select-quests] — 카드(· 과제 창) 스크린샷 → 그 번호를 고른 것처럼 판으로 → main이 장수를 출력하고 끝냄.

const MAIN := "res://scenes/main.tscn"
const META_OPTS := ["save", "unlock-all"]
const CARD_W := 290
const CARD_GAP := 16
var opts := {}
var cards: Array[Button] = []
var quest_box: Panel
var quest_lbl: Label
var t := 0.0
var shot_done := false
var q_was := false

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
	var bg := ColorRect.new()
	bg.color = Color("1e2a24")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "장수를 고르세요"
	title.position = Vector2(0, 50)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)
	var n := HeroTable.ORDER.size()
	var hint := Label.new()
	hint.text = "숫자 키 또는 클릭   ·   Q 과제   ·   이동 WASD · 경공 Shift · 절기 Space"
	hint.position = Vector2(0, 650)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.85, 0.8))
	add_child(hint)
	var x := 640 - (n * CARD_W + (n - 1) * CARD_GAP) / 2
	for k in n:
		var id: String = HeroTable.ORDER[k]
		var h: Dictionary = HeroTable.HEROES[id]
		var b := Button.new()
		b.position = Vector2(x + k * (CARD_W + CARD_GAP), 130)
		b.size = Vector2(CARD_W, 490)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 19)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var stars := "★".repeat(int(h.stars)) + "☆".repeat(3 - int(h.stars))
		if _unlocked(id):
			b.text = "%d.\n\n%s\n%s\n난이도 %s %s\n\n시작 무공\n  %s\n\n고유 심법\n  %s\n  (%s)\n\n절기\n  ???" % [
				k + 1, h.name, h.role, stars, h.star_label, h.weapon.name, h.passive.name, h.passive.desc]
		else:
			var q := Meta.quest_for("hero", id)
			var p := Meta.progress(q)
			b.text = "%d.\n\n%s\n%s\n\n[ 잠김 ]\n\n해금 — %s\n  %s\n\n진행 %d / %d" % [
				k + 1, h.name, h.role, q.name, q.desc, int(p.x), int(p.y)]
			b.disabled = true
			b.modulate = Color(0.55, 0.55, 0.55)
		b.pressed.connect(_choose.bind(k))
		add_child(b)
		cards.append(b)
	var qb := Button.new()
	qb.text = "과제 (Q)"
	qb.position = Vector2(1280 - 160, 40)
	qb.size = Vector2(130, 44)
	qb.add_theme_font_size_override("font_size", 20)
	qb.pressed.connect(_toggle_quests)
	add_child(qb)
	_build_quests()

func _build_quests() -> void:
	quest_box = Panel.new()
	quest_box.position = Vector2(190, 100)
	quest_box.size = Vector2(900, 545)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.09, 1.0)
	sb.border_color = Color("c8a858")
	sb.set_border_width_all(2)
	quest_box.add_theme_stylebox_override("panel", sb)
	quest_lbl = Label.new()
	quest_lbl.position = Vector2(24, 16)
	quest_lbl.size = Vector2(852, 515)
	quest_lbl.add_theme_font_size_override("font_size", 18)
	quest_box.add_child(quest_lbl)
	quest_box.visible = false
	add_child(quest_box)
	_fill_quests()

func _fill_quests() -> void:
	var lines := ["과제  (깬 것 %d / %d)  —  Q 닫기\n" % [Meta.data.done.size(), UnlockTable.QUESTS.size()]]
	for q in UnlockTable.QUESTS:
		var p := Meta.progress(q)
		var done: bool = q.id in Meta.data.done
		lines.append("%s %s — %s\n      %s   ·   보상: %s" % ["✔" if done else "□", q.name, q.desc,
			"완료" if done else "%s / %s" % [_num(p.x), _num(p.y)], Meta.reward_name(q)])
	quest_lbl.text = "\n".join(lines)

func _num(v: float) -> String:
	return str(int(v))

func _toggle_quests() -> void:
	quest_box.visible = not quest_box.visible

func _process(delta: float) -> void:
	t += delta
	var qk := Input.is_physical_key_pressed(KEY_Q)
	if qk and not q_was:
		_toggle_quests()
	q_was = qk
	if not quest_box.visible:
		for k in cards.size():
			if Input.is_physical_key_pressed(KEY_1 + k):
				_choose(k)
				return
	if opts.has("select-test") and t > 0.5 and not shot_done:
		shot_done = true
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
		var key := int(opts.get("select-key", "1")) - 1
		print("SELECT locked=", ",".join(HeroTable.ORDER.filter(func(id): return not _unlocked(id))))
		if not _choose(key):   # 키 입력을 흉내 냄(잠긴 장수면 안 넘어감)
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
