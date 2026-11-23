class_name MartialRules
## 무공 공통 규칙(D-285). 용어: 초식 = 공격 무공(시작 초식 + data/tactics.gd 추가 초식) · 심법 = 패시브(data/upgrades.gd 능력치 + 장수 고유 심법)
## · 내공 = 공격 · 처치로 차고 절기에 씀 · 절기 = 장수 고유 필살기(data/ults.gd) · 오의 = 진화한 절기 · 경공 = 이동기 · 주화입마 = 내공 과다 상태.

const NEIGONG_MAX := 100.0
const PER_HIT := 0.12         # 적을 한 번 맞힐 때(장수 neigong 배율이 곱해짐 — 초식 · 의용군이 맞혀도 참)
const PER_KILL := 1.0         # 적을 쓰러뜨릴 때
const MAX_GAIN_PER_SEC := 5.0  # 내공이 차는 최대 속도(초당) — 후반에 맞힘 · 처치가 폭증해도 절기는 약 20초에 한 번(1단계 첫 9판: 판마다 절기 220~340번)
# 주화입마: 내공이 가득 찬 채로 계속 차면 넘친 양이 쌓임 → OVERFLOW_LIMIT에 이르면 ZHUHUO_TIME초 동안
#           공격 × ZHUHUO_ATK, 체력 초당 −ZHUHUO_DRAIN. 끝나면 내공 AFTER. 그 사이 절기를 쓰면 바로 풀림(빠져나오는 길).
const OVERFLOW_LIMIT := 60.0
const OVERFLOW_DECAY := 2.0   # 넘친 양이 초당 줄어드는 양(잠깐 넘친 건 괜찮게)
const ZHUHUO_TIME := 8.0
const ZHUHUO_ATK := 1.6
const ZHUHUO_DRAIN := 4.0
const AFTER := 30.0

# 조작(PC) — 경공 Shift, 절기 Space · K
const KEY_DASH := KEY_SHIFT
const KEYS_ULT := [KEY_SPACE, KEY_K]

# 자동 봇(--auto): 이 반지름 안에 적이 이만큼 있으면 경공
const BOT_DASH_R := 1.2
const BOT_DASH_N := 3
const BOT_REACT := 0.25        # 둘러싸이고 이만큼 지나야 경공(D-287: 사람처럼 반응이 늦음)
const BOT_MISS := 0.25         # 이 확률로 놓침 → BOT_MISS_REST초 동안 안 씀
const BOT_MISS_REST := 1.0
