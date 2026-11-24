class_name Toon
## 툰 재질(귀여움 실험): 불러온 모델의 모든 재질을 복사해 diffuse · specular를 Toon으로, 가장자리 빛(rim)을 켬.
## 원래 재질(glb에서 온 것)은 건드리지 않고 표면마다 덮어쓰기 재질로 씌움.

static func apply(node: Node, rim := 0.4) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i)
			if src is StandardMaterial3D:
				var m := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
				m.specular_mode = BaseMaterial3D.SPECULAR_TOON
				m.rim_enabled = true
				m.rim = rim
				mi.set_surface_override_material(i, m)
	for c in node.get_children():
		apply(c, rim)
