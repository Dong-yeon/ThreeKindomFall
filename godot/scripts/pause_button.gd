class_name PauseButton
extends Control
## 일시정지 버튼(위 패널 오른쪽 위, D-197). 누르기는 무쌍 버튼처럼 Battle._unhandled_input이 터치로 직접 받음
## (끌어서 이동하는 중에 다른 손가락으로 눌러도 되게). 멈춰 있으면 ▶로 바뀜.

var b: Battle


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	if b == null:
		return
	var c := size / 2
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.11, 0.09, 0.07, 0.6))
	draw_rect(Rect2(Vector2.ZERO, size), Color("8a7a5a"), false, 1.5)
	var col := Color("fff2c0")
	if b.state == "pause":
		draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -8), c + Vector2(8, 0), c + Vector2(-5, 8)]), col)
	else:
		draw_rect(Rect2(c + Vector2(-7, -8), Vector2(5, 16)), col)
		draw_rect(Rect2(c + Vector2(2, -8), Vector2(5, 16)), col)
