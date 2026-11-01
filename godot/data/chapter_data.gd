class_name ChapterData
## 장(章)마다 켜고 끄는 것(D-239). 지도 · 진영 · 작은 사건 · 몰려오는 무리 등 나머지는 1장(Stage1) 것을 그대로 씀 — 장마다 지도가 생기면 옮김.
## army = 정원지의 대군 · 선발대(D-214 · D-229), village = 탁현 마을 습격 · 스토리 동료(D-208 · D-215),
## siege = 성문 → 본진 · 요술 제단 · 요술(Siege, SiegeData) — gate_caps곳 점령하면 관문이 열림, boss = 본진 보스(종류 · 체력 배율 · 이름 · 짧은 이름),
## sorc_at = 본진 · 요술이 열리는 판 시각(없으면 SiegeData.SORCERY.at 7:30), beast = 보스를 쓰러뜨리면 첫 사신수 해방(3장) / 아니면 곧바로 이김. altars_done = 요술 제단을 다 부쉈을 때 알림(2장 — 유비가 요술을 깸, D-210)

const CH := {
	1: {"name": "1장 탁현 싸움", "intro": "황건 진영 3곳: 수비탑을 부숴야 진영장을 칠 수 있어요", "army": true, "village": true, "siege": false},
	2: {"name": "2장 장보의 요술", "intro": "황건 진영 3곳을 점령하면 관문이 열려요 — 장보의 요술 제단을 부숴요", "army": false, "village": false, "siege": true,
		"gate_caps": 3, "sorc_at": 360.0, "boss": {"k": "zj", "m": 8.0, "n": "지공장군 장보", "short": "장보"}, "beast": false,
		"altars_done": ["유비가 짐승 피를 뿌려 요술을 깼어요!", "장보의 보호막이 풀렸어요 — 이제 장보를 쳐요"]},
}


static func get_ch(n: int) -> Dictionary:
	return CH.get(n, CH[1])
