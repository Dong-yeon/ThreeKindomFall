extends Control
## 레벨업 카드(D-298): 화면을 어둡게 하고 카드 3장을 가로로. main이 open(choices, main)으로 띄우고 고르면 main._choose(k).
## 카드: 종류 띠(새 초식 금 · 초식 강화 붉은 · 심법 푸른 · 고기만두 초록) · 이름 · Lv 점(지금 → 다음) · 설명 · 수치 변화 · 오의 재료.
## 고르는 법은 그대로(숫자 키 — main._pick_input) + 마우스 올리면 살짝 커짐 · 클릭. 카드 내용만 만들고 고르기 규칙(_offers 등)은 안 건드림.

const CW := 300.0
const CH := 360.0
const GAP := 30.0

var main
var cards: Array = []         # [{btn, band, kind, name, lv, desc, extra}]

func setup(m) -> void:
	main = m
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := UiKit.rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := UiKit.label("레벨 업!  —  하나를 고르세요", 28, UiKit.GOLD, 6)
	title.position = Vector2(0, 100)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var x0 := 640.0 - (3 * CW + 2 * GAP) * 0.5
	for k in 3:
		var b := Button.new()
		b.position = Vector2(x0 + k * (CW + GAP), 170)
		b.size = Vector2(CW, CH)
		b.pivot_offset = b.size * 0.5
		b.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, UiKit.style(UiKit.INK_SOLID if st == "normal" else Color(0.12, 0.13, 0.12, 1.0), UiKit.GOLD_DIM if st == "normal" else UiKit.GOLD, 2, 6))
		b.pressed.connect(func(): main._choose(k))
		b.mouse_entered.connect(func(): b.scale = Vector2(1.04, 1.04))
		b.mouse_exited.connect(func(): b.scale = Vector2.ONE)
		add_child(b)
		var band := UiKit.rect(Rect2(2, 2, CW - 4, 34), UiKit.KIND.new)
		b.add_child(band)
		var kind := UiKit.label("", 16, Color.WHITE, 3)
		kind.position = Vector2(12, 7)
		b.add_child(kind)
		var num := UiKit.label("%d" % (k + 1), 16, Color.WHITE, 3)
		num.position = Vector2(CW - 34, 7)
		b.add_child(num)
		var nm := UiKit.label("", 24, UiKit.TEXT, 4)
		nm.position = Vector2(14, 52)
		nm.size = Vector2(CW - 28, 34)
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_child(nm)
		var lv := UiKit.label("", 18, UiKit.GOLD, 3)
		lv.position = Vector2(14, 92)
		b.add_child(lv)
		var desc := UiKit.label("", 18, UiKit.TEXT, 2)
		desc.position = Vector2(14, 132)
		desc.size = Vector2(CW - 28, 110)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_child(desc)
		var extra := UiKit.label("", 16, UiKit.TEXT_DIM, 2)
		extra.position = Vector2(14, 250)
		extra.size = Vector2(CW - 28, 100)
		extra.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_child(extra)
		cards.append({"btn": b, "band": band, "kind": kind, "name": nm, "lv": lv, "desc": desc, "extra": extra})

func open(choices: Array) -> void:
	for k in 3:
		var c: Dictionary = cards[k]
		var b: Button = c.btn
		b.visible = k < choices.size()
		b.scale = Vector2.ONE
		if k < choices.size():
			_fill(c, choices[k])
	visible = true

func close() -> void:
	visible = false

func _fill(c: Dictionary, key: String) -> void:
	var kind := ""
	var nm := ""
	var lv := ""
	var desc := ""
	var extra := ""
	if key == "heal":
		kind = "heal"
		nm = UpgradeTable.HEAL.name
		desc = UpgradeTable.HEAL.desc
	elif key.begins_with("t:"):
		var tid := key.substr(2)
		var tt: Dictionary = TacticTable.LIST[tid]
		nm = tt.name
		desc = tt.desc
		if main.tactics.has(tid):
			kind = "chosik"
			var cur: int = main.tactics[tid].lv
			lv = "%s  →  %s" % [UiKit.dots(cur, TacticTable.MAX_LV), UiKit.dots(cur + 1, TacticTable.MAX_LV)]
			extra = _tactic_delta(tid, cur)
		else:
			kind = "new"
			lv = UiKit.dots(1, TacticTable.MAX_LV)
			extra = "추가 초식 칸 %d / %d 사용" % [main.tactics.size() + 1, main.max_slots()]
			if tt.get("strat", false) and main.hero.passive.has("strat"):
				extra += "\n책략 계열 — %s 피해 ×%.2f" % [main.hero.passive.name, main.hero.passive.strat]
	else:
		var u: Dictionary = UpgradeTable.LIST[key]
		kind = "chosik" if u.kind == "weapon" else "simbeop"
		nm = String(u.name).replace("{w}", main.hero.weapon.name)
		var cur: int = main.ups.get(key, 0)
		lv = "%s  →  %s" % [UiKit.dots(cur, u.max), UiKit.dots(cur + 1, u.max)]
		desc = u.desc
	var ev_name := _evolve_for(key)
	if ev_name != "":
		extra = (extra + "\n" if extra != "" else "") + "✦ 오의 재료: " + ev_name
	var label: String = {"new": "새 초식", "chosik": "초식 강화", "simbeop": "심법", "heal": "회복"}[kind]
	(c.band as ColorRect).color = UiKit.KIND[kind]
	(c.kind as Label).text = label
	(c.name as Label).text = nm
	(c.lv as Label).text = lv
	(c.desc as Label).text = desc
	(c.extra as Label).text = extra

func _tactic_delta(tid: String, cur: int) -> String:
	## 레벨이 오르면 바뀌는 수치(피해 · 수 · 재사용 등) 앞뒤.
	var a: Dictionary = TacticTable.params(tid, cur)
	var b: Dictionary = TacticTable.params(tid, cur + 1)
	var names := {"dmg": "피해", "count": "수", "blades": "칼날", "cd": "재사용", "r": "범위", "pierce": "꿰뚫음", "chain": "연쇄", "dur": "지속", "push": "밀침"}
	var out := []
	for k in names:
		if a.has(k) and absf(float(b[k]) - float(a[k])) > 0.001:
			out.append("%s %s → %s" % [names[k], _fmt(a[k]), _fmt(b[k])])
	return "\n".join(out.slice(0, 3))

func _fmt(v) -> String:
	var f := float(v)
	return str(int(f)) if absf(f - roundf(f)) < 0.001 else "%.1f" % f

func _evolve_for(key: String) -> String:
	## 이 카드가 지금 장수 절기의 오의 재료이고 아직 다 안 채웠으면 오의 이름.
	if main.evolved:
		return ""
	var ev: Dictionary = UltTable.LIST[main.ult_id].evolve
	for n in ev.chosik + [ev.simbeop]:
		if n[0] == key and main._have(key) < int(n[1]):
			return ev.name
	return ""
