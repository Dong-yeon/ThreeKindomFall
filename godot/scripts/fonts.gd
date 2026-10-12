class_name Fonts
## 한글 픽셀 글꼴(D-196): Galmuri(SIL OFL 1.1, © Lee Minseo — assets/fonts/OFL-Galmuri.txt).
## main = Galmuri11(12px 기준, 본문 · HUD) / small = Galmuri9(10px 기준, 작은 글자). UI(라벨 · 버튼)는 프로젝트 기본 글꼴로 Galmuri11.
## 시스템 글꼴에 기대면 Web 내보내기에서 한글이 깨져서 글꼴 파일을 넣음. 글꼴에 없는 글자(일부 한자)는 시스템 글꼴로 대신함.

const MAIN := "res://assets/fonts/Galmuri11.ttf"
const SMALL := "res://assets/fonts/Galmuri9.ttf"

static var _main: Font
static var _small: Font


static func main() -> Font:
	if _main == null:
		_main = load(MAIN) if ResourceLoader.exists(MAIN) else ThemeDB.fallback_font
	return _main


static func small() -> Font:
	if _small == null:
		_small = load(SMALL) if ResourceLoader.exists(SMALL) else main()
		# Galmuri9에 없는 글자(진영 깃발 '黃' 등)는 Galmuri11로
		if _small is FontFile and _small != main():
			(_small as FontFile).fallbacks = [main()]
	return _small


## 크기에 맞는 쪽(10px 이하는 small)
static func at(size: int) -> Font:
	return small() if size <= 10 else main()
