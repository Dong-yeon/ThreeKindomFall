class_name Sprites
## 캐릭터 시트 읽기. assets/bb/<키>.png = 16×32 칸, 가로 3프레임 × 세로 4방향(아래·왼·오·위).
## B.B.Bits 구매 에셋이라 저장소에 없다 — tools/bb_export.py로 만든다. 없으면 null(동그라미로 대신 그림).
## 아틀라스(2026-10-13 — 웹 · 모바일 성능): 처음 부를 때 모든 시트를 한 장의 텍스처로 합치고 키마다 AtlasTexture를 돌려줌.
## 적 종류마다 텍스처가 달라 위아래로 섞인 인물을 엔진이 한 번에 묶어 그리지 못했음(그리기 호출이 인물 수만큼).
## 아틀라스 끝엔 흰 타원(채움 · 고리)도 넣어, 발밑 고리를 다각형 대신 같은 텍스처로 그림(oval_tex · disc_tex)

const DIR := "res://assets/bb/"
const ROW := {"down": 0, "left": 1, "right": 2, "up": 3}
## 걷기 순서: 가운데(선 자세) → 왼발 → 가운데 → 오른발.
const WALK := [1, 0, 1, 2]
## 아틀라스 한 줄에 놓는 시트 수 · 시트 크기
const PER_ROW := 16
const CELL := Vector2i(48, 128)
## 흰 타원 그림 크기(가로 2 : 세로 1)
const OVAL := Vector2i(64, 32)

static var _cache := {}
static var _built := false
static var _atlas: Texture2D = null
static var oval_tex: Texture2D = null
static var disc_tex: Texture2D = null


static func sheet(key: String) -> Texture2D:
	if not _built:
		_build()
	return _cache.get(key, null)


static func _build() -> void:
	_built = true
	var keys: Array[String] = []
	if DirAccess.dir_exists_absolute(DIR):
		for f in ResourceLoader.list_directory(DIR):
			if f.ends_with(".png"):
				keys.append(f.get_basename())
	keys.sort()
	var imgs := {}
	for k in keys:
		var t: Texture2D = load(DIR + k + ".png")
		if t == null:
			continue
		var img := t.get_image()
		if img == null:
			continue
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		imgs[k] = img
	var n := imgs.size()
	var rows := int(ceil(float(n) / PER_ROW)) if n > 0 else 0
	var w := CELL.x * PER_ROW
	var h := CELL.y * rows + OVAL.y * 2
	var atlas := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var offs := {}
	var i := 0
	for k in imgs:
		var at := Vector2i((i % PER_ROW) * CELL.x, (i / PER_ROW) * CELL.y)
		var img: Image = imgs[k]
		atlas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
		offs[k] = Rect2(at, img.get_size())
		i += 1
	# 흰 타원: 채움(그림자 · 고리 안) · 고리(두께 3px)
	var oy := CELL.y * rows
	for y in OVAL.y:
		for x in OVAL.x:
			var dx := (x + 0.5 - OVAL.x / 2.0) / (OVAL.x / 2.0)
			var dy := (y + 0.5 - OVAL.y / 2.0) / (OVAL.y / 2.0)
			var d := sqrt(dx * dx + dy * dy)
			if d <= 1.0:
				atlas.set_pixel(x, oy + y, Color(1, 1, 1, 1))
			if d <= 1.0 and d >= 1.0 - 3.0 / (OVAL.y / 2.0):
				atlas.set_pixel(OVAL.x + x, oy + y, Color(1, 1, 1, 1))
	_atlas = ImageTexture.create_from_image(atlas)
	for k in offs:
		var at := AtlasTexture.new()
		at.atlas = _atlas
		at.region = offs[k]
		_cache[k] = at
	disc_tex = _sub(Rect2(0, oy, OVAL.x, OVAL.y))
	oval_tex = _sub(Rect2(OVAL.x, oy, OVAL.x, OVAL.y))


## 끄기 전에 놓음(정적 변수가 쥔 텍스처가 남으면 종료 때 "resources still in use")
static func release() -> void:
	_cache.clear()
	_atlas = null
	oval_tex = null
	disc_tex = null
	_built = false


static func _sub(r: Rect2) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = _atlas
	at.region = r
	return at


static func dir_of(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0 else "left"
	return "up" if v.y < 0 else "down"


## 시트 안 칸(16×32). step = 걷기 단계(멈춰 있으면 0).
static func region(dir: String, step: int) -> Rect2:
	var col: int = WALK[posmod(step, 4)]
	var row: int = ROW[dir]
	return Rect2(col * 16, row * 32, 16, 32)


## 걷기 단계(웹판 animF): 움직이면 초당 sp걸음.
static func walk_step(moving: bool, t: float, sp: float) -> int:
	return int(floor(t * sp)) % 4 if moving else 0
