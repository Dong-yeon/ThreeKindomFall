extends Control
## 전투 HUD(D-297) — main이 만들고 매 프레임 refresh(main, delta)를 부름. 판 로직은 안 바꾸고 main의 값을 읽어 보여 주기만 함.
## 배치(기준 1280×720): 맨 위 경험치 막대 + Lv · 위 가운데 남은 시간 · 처치 · 그 아래 보스 막대 · 알림 띠 /
##   왼쪽 위 빌드 목록 · 왼쪽 아래 장수 칸(이름 · 체력 · 내공) · 오른쪽 아래 기술 칸(절기 Space · 경공 Shift) /
##   점검용 글(FPS · 적 갱신)은 F3 또는 --debug일 때만 오른쪽 위.

const W := 1280.0
const H := 720.0
const SKILL := 84.0

var flash: ColorRect          # 맞으면 화면이 잠깐 붉어짐(main이 a를 올림)
var msg: Label                # 결과 글(U4에서 결과 창으로 바뀜)
var xp: UiKit.Bar
var lv_top: Label
var timer: Label
var sub: Label
var boss_bar: UiKit.Bar
var boss_name: Label
var banner_box: Panel
var banner_lbl: Label
var banner_t := 0.0
var banner_len := 1.0
var name_lbl: Label
var hp: UiKit.Bar
var hp_flash := 0.0
var last_hp := -1.0
var nei: UiKit.Bar
var gauge: UiKit.Bar          # 고유 심법 막대(D-333 — 관우 용기 · 제갈량 날씨, passive_mod.hud_info()가 있을 때만)
var zhuhuo_lbl: Label
var build_box: Panel
var build_lbl: RichTextLabel
var dbg: Label
var debug_on := false
var f3_was := false
var skills: Array = []        # [{box, fill, title, mid, key}] 0 절기 · 1 경공

func setup(m) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_on = m.opts.has("debug") or m.bench
	flash = UiKit.rect(Rect2(0, 0, W, H), Color(0.8, 0.05, 0.05, 0.0))
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	# 맨 위 경험치
	xp = UiKit.Bar.new(self, Rect2(0, 0, W, 10), UiKit.XP, 1)
	xp.text.visible = false
	lv_top = UiKit.label("Lv 1", 16, UiKit.TEXT, 4)
	lv_top.position = Vector2(W - 90, 10)
	lv_top.size = Vector2(80, 24)
	lv_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(lv_top)
	# 위 가운데 시간 · 처치
	timer = UiKit.label("10:00", 34, UiKit.TEXT, 7)
	timer.position = Vector2(W * 0.5 - 120, 14)
	timer.size = Vector2(240, 44)
	timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer.visible = m.waves
	add_child(timer)
	sub = UiKit.label("", 16, UiKit.TEXT_DIM, 4)
	sub.position = Vector2(W * 0.5 - 160, 56)
	sub.size = Vector2(320, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	# 보스 막대
	boss_bar = UiKit.Bar.new(self, Rect2(W * 0.5 - 300, 86, 600, 20), Color("c82a2a"), 14)
	boss_name = UiKit.label("", 18, UiKit.GOLD, 5)
	boss_name.position = Vector2(W * 0.5 - 300, 106)
	boss_name.size = Vector2(600, 26)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(boss_name)
	show_boss(false)
	# 알림 띠
	banner_box = UiKit.panel(Rect2(W * 0.5 - 330, -90, 660, 76), UiKit.INK, UiKit.GOLD)
	add_child(banner_box)
	banner_lbl = UiKit.label("", 22, UiKit.TEXT, 4)
	banner_lbl.position = Vector2(0, 0)
	banner_lbl.size = Vector2(660, 76)
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_box.add_child(banner_lbl)
	# 왼쪽 위 빌드 목록
	build_box = UiKit.panel(Rect2(10, 18, 260, 40), Color(0.05, 0.06, 0.06, 0.55), UiKit.GOLD_DIM, 1)
	add_child(build_box)
	build_lbl = RichTextLabel.new()
	build_lbl.bbcode_enabled = true
	build_lbl.fit_content = true
	build_lbl.scroll_active = false
	build_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_lbl.position = Vector2(8, 6)
	build_lbl.size = Vector2(246, 30)
	build_lbl.add_theme_font_size_override("normal_font_size", 14)
	build_lbl.add_theme_color_override("default_color", UiKit.TEXT)
	build_box.add_child(build_lbl)
	# 왼쪽 아래 장수 칸
	var has_g: bool = m.passive_mod != null and m.passive_mod.has_method("hud_info")
	var top := 128.0 if has_g else 104.0
	add_child(UiKit.panel(Rect2(10, H - top, 340, top - 10)))
	name_lbl = UiKit.label("%s  ·  %s" % [m.hero.name, m.hero.role], 18, UiKit.GOLD, 3)
	name_lbl.position = Vector2(22, H - top + 6)
	add_child(name_lbl)
	if has_g:
		gauge = UiKit.Bar.new(self, Rect2(22, H - 94, 316, 18), UiKit.NEIGONG, 13)
	hp = UiKit.Bar.new(self, Rect2(22, H - 70, 316, 22), UiKit.HP, 15)
	nei = UiKit.Bar.new(self, Rect2(22, H - 42, 316, 16), UiKit.NEIGONG, 12)
	zhuhuo_lbl = UiKit.label("", 15, UiKit.RED, 4)
	zhuhuo_lbl.position = Vector2(22, H - top - 28)
	add_child(zhuhuo_lbl)
	# 오른쪽 아래 기술 칸
	for k in 2:
		var x := W - 14 - SKILL * (2 - k) - 14 * (1 - k)
		var y := H - 14 - SKILL - 26
		var box := UiKit.panel(Rect2(x, y, SKILL, SKILL), UiKit.INK, UiKit.GOLD_DIM, 2)
		add_child(box)
		var fill := UiKit.rect(Rect2(2, SKILL - 2, SKILL - 4, 0), Color(UiKit.NEIGONG if k == 0 else UiKit.XP, 0.45))
		box.add_child(fill)
		var mid := UiKit.label("", 20, UiKit.TEXT, 4)
		mid.size = Vector2(SKILL, SKILL)
		mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mid.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(mid)
		var key := UiKit.key_badge("Space" if k == 0 else "Shift")
		key.position = Vector2(4, 4)
		box.add_child(key)
		var title := UiKit.label("", 14, UiKit.TEXT, 3)
		title.position = Vector2(x - 30, y + SKILL + 2)
		title.size = Vector2(SKILL + 60, 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)
		skills.append({"box": box, "fill": fill, "mid": mid, "title": title})
	# 결과 글(가운데)
	msg = UiKit.label("", 32, UiKit.TEXT, 6)
	msg.position = Vector2(0, 220)
	msg.size = Vector2(W, 280)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.visible = false
	add_child(msg)
	# 점검용 글
	dbg = UiKit.label("", 14, UiKit.TEXT_DIM, 3)
	dbg.position = Vector2(W - 520, 34)
	dbg.size = Vector2(510, 200)
	dbg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(dbg)

func show_boss(v: bool) -> void:
	boss_bar.set_visible(v)
	boss_name.visible = v

func banner(text: String, sec: float) -> void:
	banner_lbl.text = text
	banner_t = sec
	banner_len = sec

func refresh(m, delta: float) -> void:
	# 점검용 글 F3
	var f3 := Input.is_physical_key_pressed(KEY_F3)
	if f3 and not f3_was:
		debug_on = not debug_on
	f3_was = f3
	flash.color.a = maxf(flash.color.a - delta * 1.5, 0.0)
	var need: int = UpgradeTable.need(m.level)
	xp.set_value(float(m.xp) / need)
	lv_top.text = "Lv %d" % m.level
	# 시간 · 처치
	if m.waves:
		var left := maxf(WaveTable.RUN_TIME - m.t, 0.0)
		timer.text = "호뢰관" if m.boss_active else "%d:%02d" % [int(left) / 60, int(left) % 60]
		timer.add_theme_color_override("font_color", UiKit.RED if m.t >= WaveTable.FINAL_AT else UiKit.TEXT)
	sub.text = "처치 %s   ·   Lv %d" % [_num(m.horde.kills), m.level]
	if m.boss_active and m.boss and m.boss.alive:
		boss_bar.set_value(m.boss.hp / m.boss.hp_max, "%d / %d" % [int(m.boss.hp), int(m.boss.hp_max)])
		boss_name.text = "여포" + ("  —  패왕 진각!" if m.boss.phase2 else "")
	# 알림 띠: 0.25초 내려오고 · 머물고 · 0.25초 올라감
	if banner_t > 0.0:
		banner_t -= delta
		var shown := minf(banner_len - banner_t, banner_t)
		banner_box.position.y = lerpf(-90.0, 136.0, clampf(shown / 0.25, 0.0, 1.0))
	else:
		banner_box.position.y = -90.0
	# 장수 칸
	var hpv: float = maxf(m.hero_hp, 0.0)
	if last_hp >= 0.0 and hpv < last_hp - 0.5:
		hp_flash = 0.15
	last_hp = hpv
	hp_flash = maxf(hp_flash - delta, 0.0)
	hp.fill.color = Color.WHITE if hp_flash > 0.0 else UiKit.HP
	hp.set_value(hpv / m.max_hp, "%d / %d" % [int(ceil(hpv)), int(m.max_hp)])
	var nz: bool = m.neigong.zhuhuo_t > 0.0
	nei.fill.color = (Color("e84a3a") if fmod(m.t, 0.3) < 0.15 else Color("ffb040")) if nz else UiKit.NEIGONG
	nei.set_value(m.neigong.value / MartialRules.NEIGONG_MAX, "내공 %d" % int(m.neigong.value))
	zhuhuo_lbl.text = "주화입마 %.0f초 — 절기를 쓰면 풀림" % m.neigong.zhuhuo_t if nz else ""
	if gauge:
		var gi: Dictionary = m.passive_mod.hud_info()
		var gc: Color = gi.color
		if gi.get("pulse", false):
			gc = gc.lerp(Color.WHITE, 0.25 + 0.25 * sin(m.t * 10.0))
		gauge.fill.color = gc
		gauge.set_value(gi.f, gi.text)
	# 기술 칸: 절기
	var cost: float = UltTable.LIST[m.ult_id].cost
	var uf: float = clampf(m.neigong.value / cost, 0.0, 1.0)
	var ready: bool = m.neigong.can_spend(cost)
	_skill(0, uf, "준비" if ready else "%d%%" % int(uf * 100.0), UltTable.display_name(m.ult_id, m.evolved),
		ready, UiKit.GOLD if m.evolved else UiKit.NEIGONG)
	# 경공
	var qg: Dictionary = m.player.qg
	var mx := int(qg.get("charges", 1))
	var ch: int = m.player.charges
	var cf: float = 1.0 if ch >= mx else 1.0 - m.player.charge_t / maxf(float(qg.get("cd", 1.0)), 0.01)
	_skill(1, cf, "●".repeat(ch) + "○".repeat(mx - ch), m.hero.qinggong.name, ch > 0, UiKit.XP)
	_build(m)
	# 점검용
	dbg.visible = debug_on
	if debug_on:
		dbg.text = "FPS %d · 적 %d · 적 갱신 %.2fms%s%s" % [m.fps_show, m.horde.count, m.horde.last_update_us / 1000.0,
			" · 무적" if m.god else "", ("\n" + "\n".join(m.b_rows)) if m.bench else ""]

func _skill(k: int, f: float, mid: String, title: String, ready: bool, col: Color) -> void:
	var s: Dictionary = skills[k]
	var fill: ColorRect = s.fill
	var h := (SKILL - 4) * f
	fill.position.y = SKILL - 2 - h
	fill.size.y = h
	fill.color = Color(col, 0.45)
	(s.mid as Label).text = mid
	(s.title as Label).text = title
	var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
	var sb: StyleBoxFlat = (s.box as Panel).get_theme_stylebox("panel")
	sb.border_color = UiKit.GOLD * pulse if ready and k == 0 else (UiKit.GOLD if ready else UiKit.GOLD_DIM)
	sb.border_color.a = 1.0

func _build(m) -> void:
	## 왼쪽 위: 고유 무기 · 추가 초식(Lv 점) · 빈 칸 · 심법. 오의 재료를 다 채운 줄은 금색.
	var ev: Dictionary = UltTable.LIST[m.ult_id].evolve
	var need := {}
	for n in ev.chosik + [ev.simbeop]:
		need[n[0]] = int(n[1])
	var lines := []
	lines.append("[color=#d8b860]%s[/color]" % m.hero.weapon.name)
	for key in ["w_dmg", "w_spd", "w_area", "w_count", "w_pierce"]:
		if m.ups.get(key, 0) > 0:
			lines.append(_line("  " + String(UpgradeTable.LIST[key].name).replace("{w} ", "").replace("{w}", ""), int(m.ups[key]), int(UpgradeTable.LIST[key].max), need.get(key, 0)))
	for tid in m.tactics:
		lines.append(_line(TacticTable.LIST[tid].name, m.tactics[tid].lv, TacticTable.MAX_LV, need.get("t:" + tid, 0)))
	for k in maxi(m.max_slots() - m.tactics.size(), 0):
		lines.append("[color=#a0a098]— 빈 칸 —[/color]")
	var sims := []
	for key in UpgradeTable.LIST:
		if UpgradeTable.LIST[key].kind == "stat" and m.ups.get(key, 0) > 0:
			var s := "%s %d" % [UpgradeTable.LIST[key].name, m.ups[key]]
			if need.get(key, 0) > 0 and m.ups[key] >= need[key]:
				s = "[color=#d8b860]%s[/color]" % s
			sims.append(s)
	if not sims.is_empty():
		lines.append("[color=#8ab4e8]심법[/color] " + " · ".join(sims))
	if m.evolved:
		lines.append("[color=#d8b860]오의 %s[/color]" % ev.name)
	build_lbl.text = "\n".join(lines)
	build_box.size.y = 14 + 20 * lines.size()

func _line(name: String, lv: int, mx: int, need_lv: int) -> String:
	var s := "%s  %s" % [name, UiKit.dots(lv, mx)]
	if need_lv > 0 and lv >= need_lv:
		return "[color=#d8b860]%s ✦[/color]" % s
	return s

func _num(n: int) -> String:
	return "%d,%03d" % [n / 1000, n % 1000] if n >= 1000 else str(n)
