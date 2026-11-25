# 귀여운 큰 머리 모델 공통 도구(D-345) — docs/art/character-model-rules.md 의 규칙을 코드로.
# 관우(--cute, D-336 ~ 343)에서 확정한 방식을 다른 모델이 함께 쓰려고 뽑음: 얼굴 데칼 · 크리스 + 서브디비전 ·
# 한 덩어리 수염 껍데기 · 머리 1.2배 · 몸통 폭 1.25배 후처리. (guan_yu.py는 아직 자기 코드 그대로 — 결과는 같음)
import bpy, bmesh, math, os
import lowpoly as lp

R = math.radians


def tex_mat(name, png, rough=0.85, alpha=False):
    """이미지 재질(데칼은 alpha=True — 알파 블렌드)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.abspath(png))
    bsdf = nt.nodes["Principled BSDF"]
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = rough
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(m, attr):
                try:
                    setattr(m, attr, val)
                except Exception:
                    pass
    return m


def face_decal(b, png, face_ball, w, h, top, cx=0.0, offset=0.006, grid=(24, 18), subd=1):
    """머리 앞 격자 평면 → 얼굴 공(매끈하게 한 뒤) 곡면에 Shrinkwrap(정면 투영). 머리 뼈에 붙음."""
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=grid[0], y_subdivisions=grid[1], size=1, calc_uvs=True,
                                    location=(cx, -0.60, top - h / 2), rotation=(R(90), 0, 0))
    d = bpy.context.object
    d.scale = (w, h, 1)
    if subd:
        md = d.modifiers.new("subd", "SUBSURF")
        md.levels = md.render_levels = subd
    sw = d.modifiers.new("wrap", "SHRINKWRAP")
    sw.target = face_ball
    sw.wrap_method = "PROJECT"
    sw.use_project_z = True
    sw.use_negative_direction = sw.use_positive_direction = True
    sw.offset = offset
    d.data.materials.append(tex_mat("face_decal", png, 0.8, alpha=True))
    d["decal"] = True
    prev = b.bone
    b.bone = "head"
    b.parts.append((d, "head"))
    b.bone = prev
    return d


def beard_shell(b, mat, top_c, top_s, bot_c, bot_s, th_max=80.0, thick=0.12, bulge=0.04, side_from=45.0,
                face_z=1.27, face_r=0.34, chest_r=(0.31, 0.33), grid=(21, 10), fringe=None):
    """얼굴 둘레를 감는 수염 껍데기 한 장(D-342): θ(0 = 정면 · ±th_max = 귀 바로 앞)마다 세로 띠.
    위끝: 가운데 top_c(입 아래) → 옆 top_s(구레나룻, 두건 아래), 아래끝: 가운데 bot_c(V 끝) → 옆 bot_s.
    얼굴 높이에선 얼굴 공 + 0.03, 그 아래는 가슴 앞으로 둥글게."""
    def sstep(t):
        t = max(0.0, min(1.0, t))
        return t * t * (3 - 2 * t)
    NC, NR = grid
    bm = bmesh.new()
    grid = []
    for i in range(NC):
        th = -th_max + 2 * th_max * i / (NC - 1)
        a = abs(th)
        z_top = top_c + (top_s - top_c) * sstep((a - side_from) / (th_max - side_from))
        z_bot = bot_c + (bot_s - bot_c) * (a / th_max) ** 0.9
        col = []
        for j in range(NR):
            z = z_bot + (z_top - z_bot) * j / (NR - 1)
            dz = (z - face_z) / 0.98
            rf = math.sqrt(max(0.0, face_r ** 2 - dz * dz))
            k = sstep((z - (face_z - face_r + 0.01)) / 0.20)
            rx = chest_r[0] + (rf + 0.03 - chest_r[0]) * k
            ry = chest_r[1] + (0.95 * rf + 0.03 - chest_r[1]) * k
            yo = -0.05 * (1 - k)
            t = math.radians(th)
            bl = bulge * (1 - k) * math.cos(t) ** 2
            col.append(bm.verts.new((rx * math.sin(t), -(ry + bl) * math.cos(t) + yo, z)))
        grid.append(col)
    bottom = [tuple(col[0].co) for col in grid]   # 아래 가장자리(덥수룩한 끝 술용)
    for i in range(NC - 1):
        for j in range(NR - 1):
            bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
    bm.normal_update()
    bm.faces.ensure_lookup_table()
    if bm.faces[len(bm.faces) // 2].normal.y > 0:
        bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
    me = bpy.data.meshes.new("beardshell")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("beardshell", me)
    bpy.context.scene.collection.objects.link(o)
    o.modifiers.new("solid", "SOLIDIFY").thickness = thick
    o["soft_rim"] = True
    b._done(o, mat)
    if fringe:   # D-355: 아래 가장자리를 따라 아래 · 바깥으로 삐죽한 술(덥수룩한 끝) — fringe = (길이, 굵기)
        ln, rr = fringe
        import random
        rnd = random.Random(3)
        pts = bottom + [((a[0] + c[0]) / 2, (a[1] + c[1]) / 2, (a[2] + c[2]) / 2) for a, c in zip(bottom, bottom[1:])]
        for (x, y, z) in pts:
            out = math.atan2(x, -y)                       # 바깥쪽 방향(정면 0)
            l = ln * rnd.uniform(0.7, 1.15)
            c = b.cone(rr, 0.004, -l / 2, l / 2, mat, v=5)
            c.rotation_euler = (R(8), 0, -out)            # 거의 곧게 아래로(앞으로 튀어나오지 않게)
            c.location = (x + math.sin(out) * 0.04 * -1, y + math.cos(out) * 0.04, z - l * 0.35)   # 껍데기 두께 안쪽으로 조금
            c["crease"] = 0.0
    return o


def smooth_all(b, levels, cap=0.8, box=0.25, plate=0.6, soft_caps=0.3):
    """모든 조각: 크리스로 부피를 지킨 뒤 Subdivision Surface(levels). 원기둥은 옆 모서리 0(둥근 관) · 위아래 테 cap
    (soft_top이면 위 테 0, soft_caps면 양 끝 soft_caps), 상자 box, 두께 준 판 plate(수염 껍데기는 0.1), 공 0. 데칼은 건너뜀."""
    for o, _ in b.parts:
        if o.get("decal"):
            continue
        me = o.data
        if o.name.startswith("Cone"):
            ztop = max(v.co.z for v in me.vertices)
            caps = soft_caps if o.get("soft_caps", False) else cap
            soft = o.get("soft_top", False)
            vals = [0.0 if abs(me.vertices[e.vertices[0]].co.z - me.vertices[e.vertices[1]].co.z) > 1e-5
                    else (0.0 if soft and me.vertices[e.vertices[0]].co.z > ztop - 1e-5 else caps) for e in me.edges]
        elif o.name.startswith("Cube"):
            vals = [box] * len(me.edges)
        elif o.name.startswith("poly"):
            vals = [plate] * len(me.edges)
        else:
            vals = [0.0] * len(me.edges)
        if "crease" in o:   # 조각별 지정(비늘 · 나무 판처럼 각이 살아야 하는 것)
            vals = [float(o["crease"])] * len(me.edges)
        at = me.attributes.get("crease_edge") or me.attributes.new("crease_edge", "FLOAT", "EDGE")
        at.data.foreach_set("value", vals)
        for md in o.modifiers:
            if md.type == "SOLIDIFY":
                md.edge_crease_inner = md.edge_crease_outer = md.edge_crease_rim = 0.1 if o.get("soft_rim", False) else plate
        if levels > 0:   # 0이면 나누지 않음(크리스만)
            md = o.modifiers.new("subd", "SUBSURF")
            md.levels = md.render_levels = levels


def reshape(mesh, head_k=1.2, head_down=0.12, body_w=1.25, torso_r=0.33, face_mat="face"):
    """합친 메시 후처리(관우 D-339): 머리 뼈 조각을 턱 아래 축으로 head_k배 뒤 head_down 내림,
    몸통 뼈 조각 x를 body_w배, 팔 조각은 넓힌 만큼 바깥으로. 돌려줌: (턱, 머리 위끝, 머리 비율, 팔을 민 거리)."""
    names = {g.index: g.name for g in mesh.vertex_groups}
    V = mesh.data.vertices
    grp = [names[v.groups[0].group] if v.groups else "" for v in V]
    fi = [i for i, m in enumerate(mesh.data.materials) if m and m.name == face_mat][0]
    face_idx = {i for p in mesh.data.polygons if p.material_index == fi for i in p.vertices
                if grp[i] == "head" and abs(V[i].co.x) < 0.08}
    chin = min(V[i].co.z for i in face_idx)
    arm_out = torso_r * (body_w - 1.0)
    for v, g in zip(V, grp):
        if g == "head":
            x, y, z = v.co
            v.co = (x * head_k, y * head_k, chin + (z - chin) * head_k - head_down)
        elif g == "torso":
            v.co.x *= body_w
        elif g in ("arm_L", "arm_R"):
            v.co.x += arm_out * (1 if g == "arm_L" else -1)
    top = max(V[i].co.z for i in range(len(V)) if grp[i] == "head")
    chin2 = min(V[i].co.z for i in face_idx)
    return chin2, top, (top - chin2) / top, arm_out


def scale_mesh(mesh, k):
    for v in mesh.data.vertices:
        v.co = v.co * k
