class_name Unit
extends Node2D
## 전장에서 움직이는 것(장수 · 적 · 아군)의 공통. position = 발밑(그림 정렬 · 충돌의 기준).

var battle: Battle
var r := 10.0
var hp := 1.0
var max_hp := 1.0
var dead := false
var flash := 0.0
var tex: Texture2D
var face_dir := "down"
var last_pos := Vector2.ZERO
var tint := Color("888888")
## 길찾기 캐시(Battle.path_for)
var pth := Vector2.ZERO
var has_pth := false
var pth_t := -1.0
var pth_k := ""


var _anim_last := Vector2.INF


static func alive(u: Unit) -> bool:
	return u != null and is_instance_valid(u) and not u.dead


## 지난 그리기 뒤로 움직인 만큼(걷기 그림 · 바라보는 쪽).
func anim_moved() -> Vector2:
	if _anim_last == Vector2.INF:
		_anim_last = position
	var d := position - _anim_last
	_anim_last = position
	return d


## 16×32 캐릭터 그림. 웹판 sprAt(키 큰 그림): 가로 0.8·세로 1.6배, 발밑이 position + 0.52·size.
func draw_body(dir: String, step: int, size: float, alpha := 1.0, lift := 0.0, glyph := "") -> void:
	if tex == null:
		draw_circle(Vector2(0, -lift), r, Color(Color.WHITE if flash > 0 else tint, alpha))
		draw_circle(Vector2(0, -lift), r, Color(0.11, 0.09, 0.07, alpha), false, 1.5)
		if glyph != "":
			var font := Fonts.main()
			draw_string(font, Vector2(-r, -lift + r * 0.4), glyph, HORIZONTAL_ALIGNMENT_CENTER, r * 2, int(r * 1.1), Color(0.11, 0.09, 0.07, alpha))
		return
	var w := size * 0.8
	var h := size * 1.6
	var rect := Rect2(-w / 2, size * 0.52 - h - lift, w, h)
	var mod := Color(1, 1, 1, alpha)
	if flash > 0:
		mod = Color(2.4, 2.4, 2.4, alpha)
	draw_texture_rect_region(tex, rect, Sprites.region(dir, step), mod)


func draw_oval(center: Vector2, rx: float, ry: float, col: Color, filled := true, width := 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	if filled:
		draw_colored_polygon(pts.slice(0, 32), col)
	else:
		draw_polyline(pts, col, width)


func draw_bar(center_x: float, y: float, w: float, h: float, frac: float, col: Color) -> void:
	draw_rect(Rect2(center_x - w / 2, y, w, h), Color("3a3024"))
	draw_rect(Rect2(center_x - w / 2, y, w * clampf(frac, 0, 1), h), col)


func draw_label(text: String, at: Vector2, col: Color, size := 10) -> void:
	var font := Fonts.at(size)
	var pos := at + Vector2(-100, size * 0.35)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 200, size, 3, Color(0.11, 0.09, 0.07, 0.85))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 200, size, col)
