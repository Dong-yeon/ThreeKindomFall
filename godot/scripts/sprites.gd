class_name Sprites
## 캐릭터 시트 읽기. assets/bb/<키>.png = 16×32 칸, 가로 3프레임 × 세로 4방향(아래·왼·오·위).
## B.B.Bits 구매 에셋이라 저장소에 없다 — tools/bb_export.py로 만든다. 없으면 null(동그라미로 대신 그림).

const DIR := "res://assets/bb/"
const ROW := {"down": 0, "left": 1, "right": 2, "up": 3}
## 걷기 순서: 가운데(선 자세) → 왼발 → 가운데 → 오른발.
const WALK := [1, 0, 1, 2]

static var _cache := {}


static func sheet(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var path := DIR + key + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[key] = tex
	return tex


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
