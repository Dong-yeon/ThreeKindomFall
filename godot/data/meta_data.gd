class_name MetaData
## 판 밖 성장 1단계(D-232, D-209 · D-213): 모든 장수가 공유하는 장수 레벨 · 전공(재화) · 재능 포인트. 저장은 `Save`(scripts/save.gd).
## 1장은 레벨 1로도 깰 수 있게 — 레벨당 보정은 작게(웹판 체력 +6% · 공격 +5%보다 작음). 재능 포인트를 쓰는 곳(재능 트리)은 다음 단계.

## 장수 레벨 Lv → Lv+1에 필요한 경험 = a + b·(Lv − 1)
const LV_NEED := {"a": 100.0, "b": 50.0}
## 장수 레벨 1당 출진 때 최대 체력 · 공격 배율(Lv1 = × 1), 재능 포인트
const PER_LV := {"hp": 0.03, "atk": 0.025, "pts": 1}
## 판 끝 보상: 경험 = 공적 Lv × xp_lv + 클리어 xp_clear / 전공 = 처치 × kill + 진영 · 부장 · 정원지 · 클리어. 진 판은 전공 × lose
## (경험은 공적 Lv에 비례해 진 판이 자연히 적음 — D-213 '진 판에서도 일부')
const REWARD := {"xp_lv": 4.0, "xp_clear": 60.0, "kill": 0.02, "camp": 20.0, "lead": 30.0, "cyz": 60.0, "clear": 100.0, "lose": 0.5}


static func need(lv: int) -> int:
	return roundi(float(LV_NEED.a) + float(LV_NEED.b) * (lv - 1))
