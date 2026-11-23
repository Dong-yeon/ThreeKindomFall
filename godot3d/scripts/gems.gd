extends Node3D
## 경험치 구슬(D-283): 적이 쓰러진 자리에 떨어짐 → 줍는 거리 안이면 장수에게 빨려 와 경험치.
## 적 떼처럼 노드 없이 배열 + MultiMesh 하나. 너무 많으면(CAP) 새 구슬 값을 가장 오래된 구슬에 얹음.

const CAP := 1500
const PICK_R := 0.7            # 이 안이면 먹음
const PULL_SPEED := 14.0       # 빨려 오는 속도

var pos := PackedVector2Array()
var val := PackedInt32Array()
var pulled := PackedByteArray()  # 한 번 빨려 오기 시작하면 끝까지
var count := 0
var magnet := 2.6               # 줍는 거리(레벨업 '자석'이 늘림)
var mm: MultiMesh
var buf := PackedFloat32Array()
var spin := 0.0
var oldest := 0

func _ready() -> void:
	pos.resize(CAP); val.resize(CAP); pulled.resize(CAP)
	var m := SphereMesh.new()     # 마름모(위아래 뾰족한 저폴리 구)
	m.radial_segments = 4; m.rings = 2; m.radius = 0.16; m.height = 0.42
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("5ad0e8")
	mat.emission_enabled = true
	mat.emission = Color("2a9ab8")
	m.material = mat
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m
	mm.instance_count = CAP
	mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	buf.resize(CAP * 12)

func drop(p: Vector2, v := 1) -> void:
	if count < CAP:
		pos[count] = p; val[count] = v; pulled[count] = 0
		count += 1
	else:
		val[oldest] += v
		oldest = (oldest + 1) % CAP

func update(delta: float, player: Vector2) -> int:
	## 돌려주는 값 = 이번 프레임에 먹은 경험치.
	var got := 0
	var m2 := magnet * magnet
	var i := 0
	while i < count:
		var d := player - pos[i]
		var d2 := d.length_squared()
		if d2 < PICK_R * PICK_R:
			got += val[i]
			count -= 1                 # 맨 뒤 것을 이 자리로(순서는 안 지킴)
			pos[i] = pos[count]; val[i] = val[count]; pulled[i] = pulled[count]
			continue
		if pulled[i] == 1 or d2 < m2:
			pulled[i] = 1
			pos[i] += d / sqrt(d2) * minf(PULL_SPEED * delta, sqrt(d2))
		i += 1
	spin += delta * 3.0
	var c := cos(spin)
	var s := sin(spin)
	var b := buf
	buf = PackedFloat32Array()
	for k in count:
		var o := k * 12
		b[o] = c;    b[o + 1] = 0.0; b[o + 2] = s;    b[o + 3] = pos[k].x
		b[o + 4] = 0.0; b[o + 5] = 1.0; b[o + 6] = 0.0; b[o + 7] = 0.35
		b[o + 8] = -s; b[o + 9] = 0.0; b[o + 10] = c; b[o + 11] = pos[k].y
	mm.buffer = b
	mm.visible_instance_count = count
	buf = b
	return got
