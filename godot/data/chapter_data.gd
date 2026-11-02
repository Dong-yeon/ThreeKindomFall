class_name ChapterData
## 장(章)마다 켜고 끄는 것(D-239). 지도 · 진영 · 작은 사건 · 몰려오는 무리 등 나머지는 1장(Stage1) 것을 그대로 씀 — 장마다 지도가 생기면 옮김.
## army = 정원지의 대군 · 선발대(D-214 · D-229), village = 탁현 마을 습격 · 스토리 동료(D-208 · D-215),
## siege = 성문 → 본진 · 요술 제단 · 요술(Siege, SiegeData) — gate_caps곳 점령하면 관문이 열림, boss = 본진 보스(종류 · 체력 배율 · 이름 · 짧은 이름 · 수 moves / 체력 절반 아래 moves2 — D-243, 없으면 장각 것),
## guard = 관문이 열리면 관문 앞을 지키는 장수(3장 장량 — 종류 · 체력 배율 · 이름 · 패턴 ARMY.slam/charge · 닿기 피해 배율, 장수급이라 일기토 — 판 초반(공적 Lv 10 안팎)에 만나 대군 부장보다 약하게) — 쓰러뜨려야 본진이 열림,
## story = 장마다 하나인 이야기 사건(Story, D-242 — 2장 청주 구원 매복 · 3장 동탁 구출),
## sorc_at = 본진 · 요술이 열리는 판 시각(없으면 SiegeData.SORCERY.at 7:30), beast = 보스를 쓰러뜨리면 첫 사신수 해방(3장) / 아니면 곧바로 이김. altars_done = 요술 제단을 다 부쉈을 때 알림(2장 — 유비가 요술을 깸, D-210)

const CH := {
	1: {"name": "1장 탁현 싸움", "intro": "황건 진영 3곳: 수비탑을 부숴야 진영장을 칠 수 있어요", "army": true, "village": true, "siege": false},
	2: {"name": "2장 장보의 요술", "intro": "황건 진영 3곳을 점령하면 관문이 열려요 — 장보의 요술 제단을 부숴요", "army": false, "village": false, "siege": true,
		"gate_caps": 3, "sorc_at": 360.0, "boss": {"k": "zj", "m": 8.0, "n": "지공장군 장보", "short": "장보",
			"moves": ["paper", "thunder", "ring"], "moves2": ["paper", "thunder", "volley", "thunder"]}, "beast": false,
		"altars_done": ["유비가 짐승 피를 뿌려 요술을 깼어요!", "장보의 보호막이 풀렸어요 — 이제 장보를 쳐요"],
		"story": {"k": "ambush", "n": "청주 구원", "at": 150.0, "cnt": 36, "hp": 1.5, "march": 32.0, "from": Vector2(420, 840), "y0": 1500.0, "y1": 2400.0, "r": 110.0, "trigger": 300.0, "limit": 120.0,
			"allies": 5, "slow": 4.0, "xp": 120.0}},
	3: {"name": "3장 광종 결전", "intro": "황건 진영 3곳을 점령하면 광종성 관문이 열려요 — 장량을 넘어 장각에게", "army": false, "village": false, "siege": true,
		"gate_caps": 3, "sorc_at": 360.0, "guard": {"k": "ytbig", "m": 50.0, "n": "인공장군 장량", "pat": "slam", "touch": 0.7}, "beast": true,
		"story": {"k": "rescue", "n": "동탁 구출", "at": 150.0, "npc": "dongzhuo", "cnt": 10, "gap": 9.0, "waves": 3, "xp": 60.0}},
}


static func get_ch(n: int) -> Dictionary:
	return CH.get(n, CH[1])
