class_name UiKit
## 공통 UI 조각(D-297): 그림 에셋 없이 코드로 만든 패널 · 글 · 막대 · 키 딱지. 기준 화면 1280×720(가로).
## 모양: 먹색 바탕 + 금테(과제 창, D-292). 글꼴은 프로젝트 기본(Galmuri11).

const INK := Color(0.07, 0.08, 0.08, 0.86)
const INK_SOLID := Color(0.07, 0.09, 0.08, 1.0)
const GOLD := Color("d8b860")
const GOLD_DIM := Color("8a7440")
const HP := Color("d83a2a")
const NEIGONG := Color("9a5ad8")
const XP := Color("5ad0e8")
const TEXT := Color("f2eee4")
const TEXT_DIM := Color(0.75, 0.75, 0.7)
const RED := Color("ff6a50")
const KIND := {"new": Color("e0b040"), "chosik": Color("c8483a"), "simbeop": Color("4a8ad8"), "heal": Color("58b058")}

static func style(bg: Color, border: Color = GOLD, width := 2, radius := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	return sb

static func panel(rect: Rect2, bg: Color = INK, border: Color = GOLD, width := 2) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", style(bg, border, width))
	return p

static func label(text: String, size := 18, color: Color = TEXT, outline := 4) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", outline)
	return l

static func rect(r: Rect2, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.color = color
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func key_badge(key: String) -> Label:
	## 키 이름 딱지(작은 테두리 상자 안 글).
	var l := label(key, 13, TEXT, 0)
	l.add_theme_stylebox_override("normal", style(Color(0, 0, 0, 0.75), GOLD_DIM, 1, 3))
	return l

static func dots(lv: int, mx: int) -> String:
	return "●".repeat(clampi(lv, 0, mx)) + "○".repeat(maxi(mx - lv, 0))

class Bar:
	## 바탕 + 채움 + 숫자 막대. set_value(0~1, 글).
	var back: ColorRect
	var fill: ColorRect
	var text: Label
	var w := 0.0
	func _init(parent: Control, r: Rect2, color: Color, font := 14) -> void:
		back = UiKit.rect(r, Color(0, 0, 0, 0.65))
		parent.add_child(back)
		fill = UiKit.rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), color)
		parent.add_child(fill)
		w = r.size.x - 4
		text = UiKit.label("", font, UiKit.TEXT, 3)
		text.position = r.position
		text.size = r.size
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		parent.add_child(text)
	func set_value(f: float, s := "") -> void:
		fill.size.x = w * clampf(f, 0.0, 1.0)
		text.text = s
	func set_visible(v: bool) -> void:
		back.visible = v; fill.visible = v; text.visible = v
