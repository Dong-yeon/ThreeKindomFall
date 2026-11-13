# '함께 하는 느낌' 조사 보고서 — ThreeKingdomFall (2025~2026)

> 2026-11-12 하위 세션에서 웹 조사로 만든 보고서(코드 변경 없음). 사용자 말: "요즘 포켓몬 팬게임 · 클래식 같은 게 뜨고, 사람들끼리 소통하고 함께하는 형태가 유행하고 오래가는 것 같다. 나도 가장 오래 한 게임이 삼국지 전략판." 수치는 출처 기사 기준이고, 확인 못 한 것은 그렇게 적음. 다른 게임의 이름 · 용어 · IP는 우리 게임에 넣지 않고 **구조만** 빌림(CLAUDE.md 규칙).

## 요약 5줄
1. **결론:** 서버를 갖추기 전에는 "같은 조건에서 겨루는 기록"과 "결과 공유"만으로도 함께 하는 느낌을 상당히 낼 수 있음. 실시간 멀티는 지금 단계에서는 맞지 않음.
2. 클래식 열풍(WoW Classic 기념 서버, OSRS 최고 기록, 메이플랜드, 리니지 클래식)의 공통 원인은 이미 검증된 재미와 향수, 그리고 사람을 한곳에 모으는 구조(서버를 일부러 적게 연 사례 등)로 보임.
3. 전략판(SLG)류가 오래 가는 핵심은 **동맹**이라는 근거가 가장 많음. 반대로 성장까지 통째로 지우는 시즌 초기화는 이탈 위험으로 지적됨.
4. 서바이버류는 판 밖 성장으로 오래 가고, 소셜 요소는 나중에 붙이는 편. Vampire Survivors는 출시 약 3년 뒤인 2025년 10월에야 온라인 협동을 넣음. 탕탕특공대류는 클랜과 로컬 협동 정도.
5. 1인 개발 순서 제안: ① 결과 카드 공유와 디스코드 운영 → ② 일일 · 주간 공유 시드 판 → ③ 빌드 코드로 '원군' 부르기 → ④ 아주 가벼운 서버로 천하 정세(공동 목표) → ⑤ 비동기 협동 보스는 보류.

## 1. 최근 뜨는 흐름: 크리처 수집 · 팬게임 · 클래식

**크리처 수집**
- Palworld 누적 3,200만 명(2025-02, [Shacknews](https://shacknews.com/article/143190/palworld-32-million-players)) → 2026 정식판 직전 누적 4,000만 명([GamesRadar](https://www.gamesradar.com/games/survival/over-2-years-since-launch-palworld-hits-40-million-players-right-before-its-1-0-release-and-now-has-over-8-million-more-players-than-pokemon-red-blue-and-green/)).
- 정식판 출시 때 Steam 동시접속 약 85.5만까지 다시 오름([GadgetReview](https://www.gadgetreview.com/?p=396186)), 2025년 한 해 동안은 꾸준히 줄었음([GameCharts](https://gamecharts.org/steam/palworld)) — 큰 업데이트가 사람을 다시 불러오는 패턴.
- 원작사 소송 진행 중 보도([MyNintendoNews](https://mynintendonews.com/2025/02/20/palworld-reaches-32-million-players-as-pokemon-lawsuit-looms/), 현재 상태 확인 못 함) — 구조만 빌려야 한다는 근거.
- Aniimo Steam 동시접속 16만 이상 보도([PC Gamer](https://www.pcgamer.com/games/rpg/yet-another-pokemon-inspired-game-is-popping-off-on-steam-with-over-160-000-concurrent-players-for-aniimo/), 기사 날짜 확인 못 함).
- PokeMMO · 포켓몬 팬게임 접속자 수치는 확인 못 함(공개 집계 없음).

**클래식 재현**
- WoW Classic 20주년: 규칙마다 서버를 하나씩만 열어 사람을 모음([warcraft.wiki.gg](https://warcraft.wiki.gg/wiki/World_of_Warcraft:_Classic_20th_Anniversary_Edition)), 하드코어 서버는 커뮤니티 이벤트 때 붐빔([gamer.org](https://www.gamer.org/how-popular-is-each-world-of-warcraft-classic-mode-in-2025/)).
- OSRS: 2025-08-03 동시접속 약 24만 최고 기록(수치는 제3자 집계, 경신은 Jagex 확인 — [GamesRadar](https://www.gamesradar.com/games/mmo/with-a-new-record-240-000-players-online-old-school-runescape-is-roughly-8x-bigger-than-its-sister-mmo-and-would-be-the-fourth-biggest-game-on-all-of-steam-if-not-for-a-technicality), [PCGamesN](https://www.pcgamesn.com/old-school-runescape/player-record-august-2025)).
- 리니지 클래식(2026 초): 사전 서버 15개 40분 안 마감, 월정액인데 PC방 상위권([게임메카](https://www.gamemeca.com/view.php?gid=494413), [다음/IT돋보기](https://v.daum.net/v/20260506114854877)), 누적 매출 200억 원 보도([MTN](https://news.mtn.co.kr/news-detail/2026021522444640621/share-modal)).
- 메이플랜드: 옛 메이플스토리 향수([바이라인네트워크](https://byline.network/2026/01/28-570/)).
- 업계 해석: 검증된 재미는 위험이 적고 기존 팬층을 바로 확보([다음/IT돋보기](https://v.daum.net/v/20260703101031563)).

## 2. '함께 하는' 형태가 오래 가는 이유
- SLG · 4X: 동맹 · 협력이 장르를 지탱, 친구 관계망이 생기면 돌아옴([Google Play 개발자 블로그](https://medium.com/googleplaydev/succeeding-in-4x-strategy-games-e90dcf6db3f9)), 동맹 가입 여부가 잔존율을 가장 크게 가름([GameRefinery](https://www.gamerefinery.com/what-drives-success-in-4x-strategy-slg-games-part-2)).
- 시즌 초기화 위험: 진행을 통째로 지우는 짧은 시즌은 복귀율을 떨어뜨렸다는 사례([Game Developer](https://gamedeveloper.com/business/10-lessons-from-the-history-of-mobile-4x-strategy)).
- 삼국지 전략판: 공식 소개 기준 시즌마다 새 시나리오 · 최대 200명 동맹전 · VIP · 자원 판매 없음([앱스토어](https://apps.apple.com/kr/app/%EC%82%BC%EA%B5%AD%EC%A7%80-%EC%A0%84%EB%9E%B5%ED%8C%90/id1524791715)). 이용자 인터뷰 "약자도 중요한 역할", "매 시즌 맹원들과 어울리다 보니 일상"([에스콰이어 코리아](https://www.esquirekorea.co.kr/article/1877610)). 매출 · 접속 수치는 확인 못 함.
- 전체 공동 목표: Helldivers 2 — 기한 있는 공동 목표, 실패하면 이야기가 바뀜. 열심히 반응하는 쪽은 레딧 · 디스코드의 소수, 실패가 이어지면 사기 저하([GamesRadar](https://www.gamesradar.com/helldivers-2-major-orders), [PC Gamer](https://pcgamer.com/games/third-person-shooter/arrowheads-latest-major-order-is-exploiting-the-helldiver-2-communitys-greatest-weakness-communication)).

## 3. 서버 없이(또는 아주 가볍게) 넣을 수 있는 방식

| 방식 | 실제 예 | 서버 | 난이도 | 비고 |
|---|---|---|---|---|
| 남이 남긴 흔적(메시지 · 마지막 순간 기록) | Elden Ring | 필요 | 중간 | 동시 접속 없이 남의 존재를 느끼게 함([arXiv](https://arxiv.org/pdf/2204.10949.pdf), [The Ringer](https://www.theringer.com/2024/06/21/video-games/ambient-multiplayer-video-games-elden-ring-dragons-dogma-journey)) |
| 일일 공유 시드 판 | Spelunky, Slay the Spire | 없음(로컬) / 랭킹만 가볍게 | 작음 | 같은 조건이라 운 탓을 못 함([Game Developer](https://gamedeveloper.com/design/the-24-hour-ticket-examining-daily-runs-), [정리](https://saschb2b.github.io/game-mechanics/games/slay-the-spire/daily-climb)). 잔존율 효과 수치는 확인 못 함 |
| 친구 코드 고스트(시드+기록을 코드로 공유) | itch.io 인디 사례 | 없음 | 작음~중간 | [itch.io](https://itch.io/post/16659616), [Ghost Pro Racing](https://forum.playcanvas.com/t/ghost-pro-racing-async-multiplayer-racer/40733) |
| 온라인 랭킹 | Talo(오픈소스, Godot 플러그인) | 가벼움(외부 서비스) | 작음 | SilentWolf 2025년 말 종료 · LootLocker 무료 등급 폐지 보도([Crux](https://crux.supercraft.host/blog/best-godot-backend-2026/), [Talo Godot](https://github.com/TaloDev/godot)). 기기에서 올리는 점수는 조작 가능 |
| 랭킹 + 리플레이 첨부 | Steam 리더보드(GodotSteam) | 플랫폼 제공 | 중간 | [GodotSteam](https://godotsteam.pages.dev/tutorials/godotsteamkit/leaderboards/). PC용 — 모바일은 Google Play 게임즈 리더보드 등(Godot 4.7 플러그인 상태 확인 못 함) |
| 전체 공동 목표 · 시즌 | Helldivers 2 | 필요(카운터 정도) | 중간 | 처음엔 개발자가 정적 JSON을 직접 갱신하는 식으로 대신 가능 |
| 디스코드 중심 운영 | (일반적) | 없음 | 작음 | 공동 목표도 실제 조율은 게임 밖 디스코드 · 위키에서 일어남 |

## 4. 모바일 액션 · 서바이버류 동향
- Vampire Survivors: 로컬 협동 2023(1.6), 4인 온라인 협동 2025-10(1.14), 크로스플레이 없음([Gematsu](https://www.gematsu.com/2025/10/vampire-survivors-version-1-14-update-announced-adds-online-co-op-and-more), [PC Gamer](https://www.pcgamer.com/games/roguelike/the-vampire-survivors-online-co-op-update-just-arrived-with-a-bonus-balatro-collab-expansion)) — 솔로 · 성장으로 먼저 버틴 뒤 소셜.
- Survivor.io: 출시 3년 뒤 월 500만 달러 분석, 이유로 클랜보다 판 밖 성장을 꼽음([Global Games Forum](https://www.globalgamesforum.com/news/how-survivor.io-continues-to-pull-in-5-million-a-month-three-years-later)). 2인 로컬 협동 · 클랜 최대 20명 · 원정([The Nerd Stash](https://xk29r8zq-origin.thenerdstash.com/how-to-play-coop-on-survivor-io), [App Store](https://apps.apple.com/gb/app/survivor-io/id1528941310)). 클랜의 잔존율 효과 확인 못 함.
- 무쌍류 모바일: 장기 유지 · 소셜 자료는 확인 못 함.

## 5. ThreeKingdomFall 제안 (구조만 빌림, 아직 정하지 않음)

| # | 무엇을 | 왜 | 서버 | 난이도 | 붙는 곳 |
|---|---|---|---|---|---|
| 1 | **전과 카드 공유 + 디스코드:** 판이 끝나면 장수 · 책략 빌드 · 점령 수 · 일기토 결과를 세로 이미지 한 장으로 내보냄 | 실제 소통은 게임 밖에서 일어남. 비용이 가장 적고 홍보도 겸함 | 없음 | 작음 | 판 결과 화면 |
| 2 | **일일 · 주간 군령 판:** 같은 시드 · 장수 · 제약(예: "장비 없이 3장")으로 겨룸. 처음엔 날짜로 시드, 기록은 기기에, 나중에 랭킹 | 같은 조건이라 공정하고 매일 열 이유. 전략판의 '같은 판에서 겨룬다'를 1인용으로 | 없음 → 나중에 가벼운 랭킹 | 작음 | 천하 지도 허브에 게시판. 기존 장 단위 판 재사용 |
| 3 | **원군 코드:** 내 장수 · 장비 · 책략 빌드를 짧은 코드로, 친구가 입력하면 친구 판에 AI 원군(또는 일기토 상대) | 동시 접속 없이 '친구와 함께 싸운다' | 없음(복사 · 붙여넣기) | 중간 | 판 밖 성장 데이터 직렬화. 출진 전 원군 칸 |
| 4 | **천하 정세(시즌):** 모든 플레이어 공동 주간 목표 달성 → 천하 지도 영토 색 변화 · 보상. 시즌이 바뀌어도 판 밖 성장은 유지, 영토 · 순위만 초기화 | 동맹 · 영토 감각은 살리고 전부 초기화의 이탈 위험은 피함 | 아주 가벼움(카운터 하나, 처음엔 정적 JSON 수동 갱신) | 중간 | 천하 지도 허브 자체 |
| 5 | **(보류) 비동기 협동 토벌:** 거대 적장 체력을 모든 플레이어가 공유 · 피해 합산 | 동맹전에 가장 가까운 형태 | 필요 + 점수 조작 대응 | 큼 | 4번이 안정된 뒤 |

권장 순서 1 → 2 → 3 → 4 → 5. 1~3은 서버 없이 끝나 1인 개발 일정에 부담이 없음. 4부터 운영 부담이 생기니 디스코드에 사람이 어느 정도 모인 뒤.
