# ThreeKingdomFall

장수를 바꿔 가며 싸우는 **삼국지 액션 게임**(세로 화면 모바일).
천하 지도를 걸어 다니며 장비를 갖추고 출진하고, 전장에서는 세로로 긴 지도의 목표를 차례로 점령하며 진군해 적 총대장을 쓰러뜨린다.

- **지금**: 웹 프로토타입 v0.18 로 손맛과 큰 구조를 검증했고, **Godot 4.7** 로 이식 중(1장 전장).
- **이전 단계**: [Happy-Unhappy](https://github.com/Dong-yeon/Happy-Unhappy)(규칙 검증 프로토타입) — 결정 기록 D-번호가 이어진다.

## 한 판의 흐름

1. **천하 지도(허브)** — 걸어 다니며 군영 시설(대장간·군막 등)에서 장비를 고르고, 장(스테이지) 모형에 닿아 출진
2. **전장** — 목표를 점령하며 진군, 대표 무기가 자동으로 날아가고 버튼은 무쌍 하나
3. **결과** — 장수 경험·레벨 + 전공(재화) → 지도로 돌아오면 다음 장의 안개가 걷힘

설계 원칙(D-176): 레퍼런스마다 **하나씩만** 가져온다 — 무쌍 액션에서 전장 구조, 서바이버류에서 판 안 빌드(책략·진화), 걸어 다니는 허브. 다른 게임의 이름·고유 용어·IP 는 넣지 않는다.

## 구조

| 경로 | 내용 |
|---|---|
| `godot/` | 본 개발 (Godot 4.7 · GDScript, 360×640 세로). 장수·책략·적·아군 수치는 데이터(`data/`)로 바꿔 끼운다 |
| `godot/tools/` | 헤드리스 자동 전투 테스트(클리어 여부·판 길이·처치 수 표), 에셋 변환, 웹 내보내기 |
| `prototype/web/` | 실험용 웹 스케치북 — JS 조각을 `build.py` 가 한 파일로 묶음, Playwright 봇 테스트 |
| `docs/current-design.md` | 지금 확정된 게임 구성 (이식 기준 문서) |
| `docs/decision-log.md` | 결정 기록 (요청 → 판단/구성 → 확인) |

## 실행

```bash
# Godot 자동 전투 테스트 (Godot 4.7.2 필요)
py -3 godot/tools/run_bot_test.py

# 웹 프로토타입 빌드 (Python 3 + Pillow)
python prototype/web/build.py      # → prototype/web/dist/index.html
```

캐릭터 그림은 **구매 에셋이라 저장소에 없다**(아래). 받은 뒤 `assets/three-kingdom/` 에 넣고 `python godot/tools/bb_export.py` 로 변환해야 캐릭터가 보인다.

## 에셋 · 라이선스

| 에셋 | 라이선스 | 저장소에 |
|---|---|---|
| B.B.Bits Three Kingdoms (Hero Characters part 5, NPC Characters part 1) | 구매 — 게임에 포함한 배포만 허용, 파일 단독 공유·재배포·AI 학습 금지 | **없음** (원본·변환 결과 모두 `.gitignore`) |
| Ninja Adventure (타일·소리) | CC0 | 있음 |
| Galmuri 글꼴 | OFL 1.1 | 있음 |
