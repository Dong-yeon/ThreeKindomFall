# ThreeKingdomFall

장수를 바꿔 가며 하는 삼국지 액션 게임(세로 화면 모바일). 지금은 웹 프로토타입 v0.18 단계이고, Godot 4로 옮길 예정이다.

## 처음 받았을 때
1. 구매 에셋을 `assets/three-kingdom/`에 그대로 넣는다(압축 풀 필요 없음, 커밋 안 됨).
   - `[Resource]A005-Hero Characters for Three Kingdoms.zip`
   - `NPC Characters-1.png`
2. 웹 프로토타입 빌드: `pip install pillow` 후 `python prototype/web/build.py` → `prototype/web/dist/index.html`을 브라우저로 연다.
3. 봇 테스트(선택): `npm i -D playwright` 후 `node prototype/web/bots/bwErr.js`

## 문서
- `CLAUDE.md` 작업 규칙 · 에셋 라이선스 · 구조
- `docs/current-design.md` 지금까지 정해진 게임 구성(v0.18)
- `docs/decision-log.md` 결정 기록(D-번호)
