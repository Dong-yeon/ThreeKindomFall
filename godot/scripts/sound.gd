extends Node
## 효과음 · 배경음(자동 로드 'Sound'). 소리는 assets/sfx/<키>.mp3(Ninja Adventure, CC0 — tools/na_sounds.py).
## 같은 소리가 한꺼번에 많이 나면 시끄럽고 뭉개져서: 키마다 동시에 LIMIT개까지, 같은 키는 GAP초 안에 다시 안 냄,
## 전체 동시 소리도 MAX_ALL개까지. 볼륨은 웹판 sfx(키, 0~1)와 같은 크기.

const DIR := "res://assets/sfx/"
## 키별 동시 상한(없으면 DEFAULT_LIMIT)
const LIMIT := {"hit": 3, "kill": 4, "shoot": 2, "slam": 2, "hurt": 1}
const DEFAULT_LIMIT := 2
const GAP := 0.045
const MAX_ALL := 12
const MASTER := 1.0

var muted := false
var _streams := {}
var _pools := {}
var _last := {}
var _music: AudioStreamPlayer
var _music_key := ""
## 높이 흔들기는 따로 된 난수로(전역 난수를 쓰면 소리가 났는지에 따라 판이 달라져 --seed로 재현이 안 됨)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	# 창 없이(봇 테스트) 돌 땐 소리를 내지 않음 — 가짜 소리 장치라 재생한 소리가 안 풀려 종료 때 경고가 남
	if DisplayServer.get_name() == "headless":
		muted = true


func _stream(key: String) -> AudioStream:
	if not _streams.has(key):
		var path := DIR + key + ".mp3"
		_streams[key] = load(path) if ResourceLoader.exists(path) else null
	return _streams[key]


## 효과음 하나. vol = 0~1(웹판과 같은 크기), 높이를 조금씩 흔들어 같은 소리가 덜 단조롭게
func play(key: String, vol := 0.4, pitch_jitter := 0.06) -> void:
	if muted:
		return
	var st := _stream(key)
	if st == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(key, -10.0)) < GAP:
		return
	var pool: Array = _pools.get(key, [])
	_pools[key] = pool
	var free: AudioStreamPlayer = null
	var busy := 0
	for p in pool:
		if p.playing:
			busy += 1
		elif free == null:
			free = p
	if busy >= int(LIMIT.get(key, DEFAULT_LIMIT)) or _playing_all() >= MAX_ALL:
		return
	if free == null:
		free = AudioStreamPlayer.new()
		free.stream = st
		add_child(free)
		pool.append(free)
	_last[key] = now
	free.volume_db = linear_to_db(clampf(vol * MASTER, 0.001, 1.0))
	free.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	free.play()


func _playing_all() -> int:
	var n := 0
	for k in _pools:
		for p in _pools[k]:
			if p.playing:
				n += 1
	return n


## 배경음(반복). key = "" 이면 멈춤
func music(key: String, vol := 0.3) -> void:
	if key == _music_key and _music.playing:
		return
	_music_key = key
	_music.stop()
	if key == "" or muted:
		return
	var st := _stream(key)
	if st == null:
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = true
	_music.stream = st
	_music.volume_db = linear_to_db(vol * MASTER)
	_music.play()


## 일시정지 동안 배경음을 멈췄다가 이어서(D-197)
func set_paused(p: bool) -> void:
	_music.stream_paused = p


## 모두 멈추고 놓음. 끄기 전에 부르고 두어 프레임 기다리면 종료 때 "resources still in use" 경고가 안 남
func stop_all() -> void:
	for k in _pools:
		for p in _pools[k]:
			p.stop()
			p.stream = null
	_pools.clear()
	_music.stop()
	_music.stream = null
	_streams.clear()
