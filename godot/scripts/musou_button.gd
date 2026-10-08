class_name MusouButton
extends Control
## 무쌍 버튼(오른쪽 아래). 때리거나 맞으면 게이지가 차고, 다 차면 빛남.
## 누르기는 Battle._unhandled_input이 터치로 직접 받는다 — Godot GUI는 첫 손가락만 마우스로 바꿔 넘겨서,
## 끌어서 이동하는 중에 다른 손가락으로 누르면 버튼이 못 받음.

var b: Battle


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if b == null:
		return
	var h := b.hero
	var c := size / 2
	var rad := minf(size.x, size.y) / 2 - 4
	var full := h.mg >= 100 and h.musou_t <= 0
	if full:
		draw_circle(c, rad + 3 + 2 * sin(b.t * 8), Color(1.0, 0.83, 0.29, 0.45))
	draw_circle(c, rad, Color(0.11, 0.09, 0.07, 0.78))
	if h.mg > 0:
		draw_arc(c, rad - 4, -PI / 2, -PI / 2 + TAU * h.mg / 100.0, 48, Color("e2a83a") if full else Color("b8862a"), 6)
	draw_arc(c, rad, 0, TAU, 48, Color("fff2b0") if full else Color("8a7a5a"), 2)
	var font := ThemeDB.fallback_font
	var col := Color("fff2b0") if full else Color("c8b890")
	draw_string(font, Vector2(0, c.y + 4), "無雙", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, col)
	draw_string(font, Vector2(0, c.y + 22), "무쌍" if h.musou_t <= 0 else "", HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, col)
