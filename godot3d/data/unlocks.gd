class_name UnlockTable
## 과제 · 해금 표(D-292): 메타 진행. 과제를 깨면 보상(장수 · 초식 · 심법 · 칸)이 열림. 저장 · 판정은 scripts/meta.gd(자동 로드 Meta).
## 보상으로 걸린 것만 잠김 — 어느 과제의 보상에도 없는 장수 · 초식 · 심법은 처음부터 열려 있음(관우 · 제갈량 · 회전 언월 · 화살 비 · 화계 · 연노 …).
## 조건 kind:
##   total  여러 판 누적 Meta.data.total[key] ≥ goal   (kills 처치 · elite_kills 정예 처치 · gems 구슬 · lubu 여포 처치)
##   best   한 판 최고 Meta.data.best[key] ≥ goal      (nohit 안 맞고 버틴 초 · camps 깬 진영 수 · lowhp 체력 30% 아래로 버틴 초)
##   clears heroes의 장수로 각각 한 번 이상 클리어(여포 처치)
##   quests 다른 과제를 goal개 깸
## reward: [종류, id] — hero 장수 · tactic 추가 초식(data/tactics.gd) · simbeop 심법(data/upgrades.gd key) · slot 추가 초식 칸 +1

const QUESTS := [
	{"id": "lubu", "name": "호뢰관의 맹장", "desc": "여포를 한 번 물리치기", "kind": "total", "key": "lubu", "goal": 1, "reward": ["hero", "zhang_fei"]},
	{"id": "taoyuan", "name": "도원결의", "desc": "관우와 장비로 각각 한 번씩 클리어", "kind": "clears", "heroes": ["guan_yu", "zhang_fei"], "reward": ["hero", "liu_bei"]},
	{"id": "elite5", "name": "장수 사냥", "desc": "정예 장수 누적 5명 처치", "kind": "total", "key": "elite_kills", "goal": 5, "reward": ["tactic", "bolt"]},
	{"id": "kill7500", "name": "만인적", "desc": "누적 7,500명 처치", "kind": "total", "key": "kills", "goal": 7500, "reward": ["tactic", "knives"]},
	{"id": "nohit120", "name": "무상", "desc": "한 판에서 2분 동안 안 맞기", "kind": "best", "key": "nohit", "goal": 120, "reward": ["tactic", "drum"]},
	{"id": "camps3", "name": "소탕", "desc": "한 판에서 진영 3곳을 모두 깨기", "kind": "best", "key": "camps", "goal": 3, "reward": ["tactic", "flamestep"]},
	{"id": "lowhp60", "name": "배수진", "desc": "한 판에서 체력 30% 아래로 60초 버티기", "kind": "best", "key": "lowhp", "goal": 60, "reward": ["simbeop", "sin"]},
	{"id": "gems10000", "name": "군수", "desc": "구슬 누적 10,000개 줍기", "kind": "total", "key": "gems", "goal": 10000, "reward": ["simbeop", "magnet"]},
	{"id": "quests5", "name": "백전노장", "desc": "과제 5개 깨기", "kind": "quests", "goal": 5, "reward": ["slot", "1"]},
]
