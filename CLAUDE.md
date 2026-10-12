# ThreeKingdomFall

장수를 바꿔 가며 하는 삼국지 액션 게임(세로 화면 모바일). 천하 지도를 걸어 다니며 출진하고(Thronefall식 허브), 전장에서는 지도 위 목표를 점령하며 적 무리를 베어 나간다(무쌍 액션식).

- 지금 상태: 웹 프로토타입 v0.18(`prototype/web`)에서 손맛과 큰 구조를 검증함. Godot 4.7 이식 1단계 = 1장 전장(말 없이 · 기본 공격은 날아가는 대표 무기, `godot/`, D-171 · D-173~175).
- 다음: PC에서 웹판과 손맛 비교 → 천하 지도·장비 → 장수 교체.
- 현재 기획 요약: `docs/current-design.md` / 결정 기록: `docs/decision-log.md`(D-1~, 이전 저장소 Happy-Unhappy에서 이어짐)

## 작업 규칙
- 사용자와는 한국어로 대화한다. 결론을 먼저 말하고, 확실하지 않으면 모른다고 말한다.
- 한 번에 한 단계씩 진행한다. 요청하지 않은 기능 추가나 리팩터링은 하지 않는다.
- 레퍼런스 게임(무쌍 액션, Thronefall, 서바이버류 등)은 **구조만** 빌린다. 게임 안에 그 게임들의 이름·고유 용어·IP를 넣지 않는다. 삼국지 인물·지명(역사)은 써도 된다.
- 특정 장수 전용으로 짜지 않는다. 장수(그림·무기·능력치·무쌍)는 데이터로 바꿔 끼울 수 있어야 한다. 웹판은 관우 고정(`gy_` 키)이라 이식할 때 일반화한다.
- 세로 화면 모바일이 기준이다(터치: 끌어서 이동, 공격은 대표 무기가 자동으로 날아감(D-171), 버튼은 무쌍 — 말은 D-170으로 뺌).
- 결정은 `docs/decision-log.md`에 다음 D-번호로 남기고 커밋한다. 형식은 기존 항목을 따른다(요청 → 판단/구성 → 확인).

## 에셋과 라이선스 (중요)
- `assets/three-kingdom/` = B.B.Bits Three Kingdoms 구매 에셋(Hero Characters part 5, NPC Characters part 1).
  - 게임에 포함해 배포하는 것만 허용. 파일 단독 공유·업로드·재판매·AI 학습 금지.
  - **절대 커밋하지 않는다.** 이 에셋으로 만든 결과물(`prototype/web/src/c3b_bb_data.js`, `prototype/web/dist/`, `godot/assets/bb/`, `godot/build/`)도 커밋하지 않는다(.gitignore에 있음).
- Ninja Adventure(CC0)는 웹판의 타일·말·소리에 쓰였다. `prototype/web/src/c3_na_data.js`(생성 결과)만 커밋돼 있다.
- 그림체 원칙: 캐릭터와 같은 화면에 나오는 것(바닥·나무·건물·말)은 B.B.Bits 그림체로 맞춘다. 웹판은 섞여 있어 이식할 때 바로잡는다.

## 웹 프로토타입 (`prototype/web`)
- 구조: `src/`의 JS 조각들이 한 스코프를 공유하고, `build.py`가 순서대로 이어 `dist/index.html` 한 파일을 만든다.
  - `n_field.js` 1장 전장(지도·진영·연격·말·무쌍·아군), `p_world.js` 천하 지도·장비 화면, `m_musou.js` 책략(스킬)·레벨업, `e_arena.js` 전투 공통, `h_boot.js` 그리기 루프, `c3_ninja.js` 그림 로딩.
  - `d_town.js`·`i_story.js`·`j_rope.js`·`k_army.js` 등은 이전 시안(책 세계) 코드다. 쓰이지 않지만 같은 스코프라 남겨 둔다.
- 빌드: `python prototype/web/build.py` (Python 3 + Pillow). 캐릭터 데이터가 없으면 `tools/bb_pack.py`로 `assets/three-kingdom/`에서 만든다.
- 봇 테스트(Node + Playwright): `node prototype/web/bots/bwWorld2.js`(천하 지도·장비·안개·나루), `node prototype/web/bots/bwField.js t1 smart`(1장 전투 클리어), `node prototype/web/bots/bwErr.js`(콘솔 오류). 스크린샷은 `prototype/web/out/`.
- 웹판은 실험용 스케치북으로 남긴다. 확정된 것만 Godot으로 옮긴다.

## Godot (`godot/`, Godot 4.7.2 · GDScript)
- 실행 파일: `C:\Tools\Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe`(콘솔판). 렌더러 Compatibility, 화면 360×640 기준 세로(`keep_width`라 긴 화면은 아래위가 더 보임).
- 처음 받으면: `python godot/tools/bb_export.py`(B.B.Bits 캐릭터 시트 → `godot/assets/bb/`, 구매 에셋 `assets/three-kingdom/`이 그 PC에 있어야 함) → `Godot… --path godot --headless --import`. 그림이 없어도 돌아감(인물이 동그라미).
- 소리: `godot/assets/sfx/`(Ninja Adventure CC0, 커밋돼 있음). 다시 만들 땐 `python godot/tools/na_sounds.py`(웹판 `c3_na_data.js`에서 꺼냄). 창 없는 실행(봇)에서는 소리를 끔.
- 구조: `data/`(장수 `HeroData`·기본 공격 `BasicAttack`·`heroes/*.tres`, 책략 `tactics_data.gd`, 적·아군 수치 `units.gd`, 1장 지도 `stage_1.gd`), `scripts/`(`battle.gd` 판 진행·목표·생성·충돌, `hero.gd` 기본 공격·연격 수·무쌍, `tactics.gd` 레벨업·책략·진화, `sound.gd` 자동 로드 `Sound`(효과음·배경음), `enemy.gd`·`ally.gd`, `flow_field.gd` 길찾기, `ground.gd`·`fx_layer.gd`·`hud.gd` 그리기, `bot.gd` 테스트 봇), `scenes/battle.tscn`.
- 조작(PC): 마우스 끌기 = 터치 끌기, 방향키·WASD 이동, 스페이스·K 무쌍.
- 자동 전투 테스트: `python godot/tools/run_bot_test.py`(headless로 일반·무적 두 판 → 클리어 여부·판 길이·처치·공적 Lv·채운 칸·진화·오류 표와 사건마다 시각·고른 기록, 오류가 있거나 무적이 못 깨면 실패). 스크린샷: `Godot… --path godot --fixed-fps 60 -- --bot --shots=<폴더>`(진영장 보호막 · 공격 예고 · 상자도 처음 한 장씩). 성능: `… -- --bot --god --perf`(창 모드, D-204). 일시정지 점검: `… --headless -- --bot --selftest-pause`.
- 내보내기: `export_presets.cfg`에 Android(arm64, APK) · Web(스레드 끔) 프리셋. 결과는 `godot/build/`(커밋 안 함). 내보내기 템플릿 4.7.2는 에디터에서 따로 설치(이 PC엔 JDK 17 · Android SDK · 디버그 키스토어는 있음, D-204).
- 글꼴: `godot/assets/fonts/` Galmuri11 · Galmuri9(OFL 1.1, D-196). 이 PC 셸에서는 `python` 대신 `py -3 -X utf8`.

## 커밋
- 메시지는 한국어 한 줄 요약 + 필요하면 본문. 예: `docs: D-169 …`, `feat(web): …`, `chore: …`
