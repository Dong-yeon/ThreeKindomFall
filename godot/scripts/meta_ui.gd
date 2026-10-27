class_name MetaUI
extends Control
## 판 밖 성장 창(D-235 — D-233 대장간 · D-234 재능을 결과 창에서 떼어 냄): 천하 지도 군영에서 엶. 장수(hd)를 받아 그 장수의 무기를 강화.
## 창이 열려 있는 동안 천하 지도는 걷기를 받지 않음(is_open).

signal closed

const INK := Color(0.11, 0.09, 0.07)

var hd: HeroData
var forge_panel: PanelContainer
var forge_info: Label
var forge_go: Button
var tal_panel: PanelContainer
var tal_head: Label
var tal_tab := 0
var tal_tabs: Array[Button] = []
var tal_rows: Array[Dictionary] = []


func setup(hero: HeroData) -> void:
	hd = hero
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_forge()
	_build_tal()


func is_open() -> bool:
	return forge_panel.visible or tal_panel.visible


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


## 대장간(D-233): 대표 무기 강화 Lv · 등급 · 기본 공격 피해 보정 · 값(전공), '강화' · '닫기'
func _build_forge() -> void:
	forge_panel = PanelContainer.new()
	forge_panel.set_anchors_preset(Control.PRESET_CENTER)
	forge_panel.custom_minimum_size = Vector2(280, 0)
	forge_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	forge_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ecd8")
	sb.border_color = Color("3a2a1a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	forge_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	forge_panel.add_child(vb)
	var title := _label(18, Color("3a2a1a"), 0)
	title.text = "대장간"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	forge_info = _label(13, Color("3a2a1a"), 0)
	forge_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forge_info.custom_minimum_size = Vector2(244, 0)
	vb.add_child(forge_info)
	forge_go = Button.new()
	forge_go.custom_minimum_size = Vector2(0, 44)
	forge_go.pressed.connect(_forge_press)
	vb.add_child(forge_go)
	var close := Button.new()
	close.text = "닫기"
	close.custom_minimum_size = Vector2(0, 40)
	close.pressed.connect(func():
		forge_panel.visible = false
		closed.emit())
	vb.add_child(close)
	forge_panel.visible = false
	add_child(forge_panel)


func forge_open() -> void:
	_forge_refresh()
	forge_panel.visible = true


func _forge_refresh() -> void:
	var W: Dictionary = MetaData.WEAPON
	var id: String = hd.id
	var lv := Save.weapon_lv(id)
	var per := float(W.per) * 100.0
	var txt := "%s의 %s\n%s · 강화 Lv %d / %d\n기본 공격 피해 +%d%%" % [hd.display_name, hd.weapon_name, MetaData.weapon_grade(lv), lv, int(W.max), roundi(per * lv)]
	if lv < int(W.max):
		var up := MetaData.weapon_grade(lv + 1)
		txt += " → +%d%%%s" % [roundi(per * (lv + 1)), "  (%s 등급!)" % up if up != MetaData.weapon_grade(lv) else ""]
		forge_go.text = "강화 — 전공 %d" % MetaData.weapon_cost(lv)
		forge_go.disabled = int(Save.d.merit) < MetaData.weapon_cost(lv)
	else:
		forge_go.text = "더 강화할 수 없어요"
		forge_go.disabled = true
	txt += "\n\n가진 전공 %d" % int(Save.d.merit)
	forge_info.text = txt


func _forge_press() -> void:
	if Save.upgrade_weapon(hd.id):
		Sound.play("win", 0.4)
	_forge_refresh()


func _build_tal() -> void:
	tal_panel = PanelContainer.new()
	tal_panel.set_anchors_preset(Control.PRESET_CENTER)
	tal_panel.custom_minimum_size = Vector2(340, 0)
	tal_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tal_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f4ecd8")
	sb.border_color = Color("3a2a1a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	tal_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	tal_panel.add_child(vb)
	var title := _label(18, Color("3a2a1a"), 0)
	title.text = "재능"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	tal_head = _label(11, Color("5a4a36"), 0)
	tal_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tal_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tal_head.custom_minimum_size = Vector2(316, 0)
	vb.add_child(tal_head)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	vb.add_child(tabs)
	for i in MetaData.TALENTS.size():
		var tb := Button.new()
		tb.custom_minimum_size = Vector2(76, 34)
		tb.toggle_mode = true
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(func():
			tal_tab = i
			_tal_refresh())
		tabs.add_child(tb)
		tal_tabs.append(tb)
	for j in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var l := _label(12, Color("3a2a1a"), 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(228, 54)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var minus := Button.new()
		minus.text = "−"
		minus.custom_minimum_size = Vector2(40, 40)
		minus.focus_mode = Control.FOCUS_NONE
		row.add_child(minus)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(40, 40)
		plus.focus_mode = Control.FOCUS_NONE
		row.add_child(plus)
		minus.pressed.connect(func(): _tal_step(j, -1))
		plus.pressed.connect(func(): _tal_step(j, 1))
		vb.add_child(row)
		tal_rows.append({"l": l, "minus": minus, "plus": plus})
	var reset := Button.new()
	reset.text = "모두 되돌리기(무료)"
	reset.custom_minimum_size = Vector2(0, 38)
	reset.pressed.connect(func():
		Save.tal_reset()
		_tal_refresh())
	vb.add_child(reset)
	var close := Button.new()
	close.text = "닫기"
	close.custom_minimum_size = Vector2(0, 38)
	close.pressed.connect(func():
		tal_panel.visible = false
		closed.emit())
	vb.add_child(close)
	tal_panel.visible = false
	add_child(tal_panel)


func tal_open() -> void:
	_tal_refresh()
	tal_panel.visible = true


func _tal_step(j: int, dir: int) -> void:
	var nd: Dictionary = MetaData.TALENTS[tal_tab].nodes[j]
	var ok := Save.tal_add(nd.k) if dir > 0 else Save.tal_sub(nd.k)
	if ok:
		Sound.play("accept", 0.3)
	_tal_refresh()


func _tal_refresh() -> void:
	tal_head.text = "남은 포인트 %d  (받은 %d · 장수 Lv %d)\n2칸은 같은 가지 1칸에 %d점, 3칸은 1 · 2칸에 %d점 · 효과는 다음 출진부터" % [
		Save.tal_left(), int(Save.d.pts), Save.lv(), int(MetaData.TIER_NEED[1]), int(MetaData.TIER_NEED[2])]
	for i in tal_tabs.size():
		var br: Dictionary = MetaData.TALENTS[i]
		var n := 0
		for nd in br.nodes:
			n += Save.tal_rank(nd.k)
		tal_tabs[i].text = "%s %d" % [br.n, n] if n > 0 else String(br.n)
		tal_tabs[i].button_pressed = i == tal_tab
	var B: Dictionary = MetaData.TALENTS[tal_tab]
	for j in tal_rows.size():
		var R: Dictionary = tal_rows[j]
		var nd: Dictionary = B.nodes[j]
		var r := Save.tal_rank(nd.k)
		var open := Save.tal_open(nd.k)
		var now := MetaData.talent_desc(nd, maxi(r, 1))
		var txt := "%s  %d/%d\n%s" % [nd.n, r, int(nd.max), now if r > 0 else "다음: " + now]
		if r > 0 and r < int(nd.max):
			txt += "  (다음 " + MetaData.talent_desc(nd, r + 1) + ")"
		if not open:
			txt += "\n— 잠김: 아래 칸에 %d점" % int(MetaData.TIER_NEED[int(nd.tier)])
		R.l.text = txt
		R.l.modulate = Color(1, 1, 1, 1.0 if open else 0.5)
		R.plus.disabled = not open or r >= int(nd.max) or Save.tal_left() <= 0
		R.minus.disabled = r <= 0
