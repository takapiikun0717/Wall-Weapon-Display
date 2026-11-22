extends MeshInstance3D
# Picture frame: same outline as the vanilla painting (1.0 x 0.6 x 0.03 m), back at z = 0,
# front towards +Z. Surface 0 = frame + canvas, surface 1 = the picture (user image).

const OUTER := Vector2(0.5, 0.3)
const MID := Vector2(0.464, 0.276)
const INNER := Vector2(0.429, 0.2514)
const ATLAS := Vector2(1536, 1024)

# Texture variants: every variant is an atlas PNG (front, back, two edge strips); subclasses
# override _cfg() with their file and regions (pixels).
var atlas_path := "res://WallWeaponDisplay/Frame_Texture.jpg"
var FRONT := Rect2(18, 174, 739, 556)
var BACK := Rect2(783, 174, 737, 556)
var STRIP_OUT := Rect2(18, 754, 1502, 58)
var STRIP_IN := Rect2(18, 829, 1502, 60)

static var _atlas_cache := {}

func _cfg() -> void:
	pass

static func _get_atlas(path: String) -> Texture2D:
	if _atlas_cache.has(path):
		return _atlas_cache[path]
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.size() > 0:
			var tmp := Image.new()
			if tmp.load_jpg_from_buffer(bytes) == OK or tmp.load_png_from_buffer(bytes) == OK:
				img = tmp
	if img == null or img.is_empty():
		push_warning("[WallWeaponDisplay] frame texture missing: " + path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_atlas_cache[path] = tex
	return tex

func _uv_front(p: Vector3) -> Vector2:
	return Vector2((FRONT.position.x + (p.x + OUTER.x) / (OUTER.x * 2.0) * FRONT.size.x) / ATLAS.x,
		(FRONT.position.y + (OUTER.y - p.y) / (OUTER.y * 2.0) * FRONT.size.y) / ATLAS.y)

func _uv_back(p: Vector3) -> Vector2:
	return Vector2((BACK.position.x + (OUTER.x - p.x) / (OUTER.x * 2.0) * BACK.size.x) / ATLAS.x,
		(BACK.position.y + (OUTER.y - p.y) / (OUTER.y * 2.0) * BACK.size.y) / ATLAS.y)

func _strip_uv(r: Rect2, u: float, v: float) -> Vector2:
	return Vector2((r.position.x + u * r.size.x) / ATLAS.x, (r.position.y + v * r.size.y) / ATLAS.y)
const MAX_SIZE := 2048

var image_path := ""
var _aspect := 0.0
var _tex: Texture2D = null
var _frame_mat: Material
var _pic_mat: Material

# The game's own shader (Standard.gdshader) so that lights / shadows / weather react like on
# every other furniture piece.
func _make_mat(tex: Texture2D) -> Material:
	var sh = load("res://Shaders/Standard.gdshader")
	if sh == null:
		var fb := StandardMaterial3D.new()
		fb.albedo_texture = tex
		fb.roughness = 1.0
		return fb
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("albedo", tex)
	mat.set_shader_parameter("tint", Color(1, 1, 1, 1))
	mat.set_shader_parameter("limiter", 0.1)
	mat.set_shader_parameter("dynamic", false)
	mat.set_shader_parameter("fractional", false)
	mat.set_shader_parameter("enableRain", false)
	mat.set_shader_parameter("enableSnow", false)
	mat.set_shader_parameter("snowTop", 0.0)
	mat.set_shader_parameter("snowSide", 0.0)
	mat.set_shader_parameter("snowBottom", 0.0)
	mat.set_shader_parameter("occlusion", false)
	mat.set_shader_parameter("noise", false)
	mat.set_shader_parameter("metal", false)
	mat.set_shader_parameter("glow", false)
	return mat

func _init() -> void:
	_cfg()
	_frame_mat = _make_mat(_get_atlas(atlas_path))
	_pic_mat = _make_mat(null)
	_build()

# set a picture from a file path on the PC; "" removes it. Returns true on success.
func set_image_path(path: String) -> bool:
	if path.strip_edges() == "":
		image_path = ""
		_tex = null
		_aspect = 0.0
		_build()
		return true
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return false
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var m := maxi(w, h)
	if m > MAX_SIZE:
		var s := float(MAX_SIZE) / float(m)
		img.resize(maxi(1, int(w * s)), maxi(1, int(h * s)), Image.INTERPOLATE_LANCZOS)
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	_tex = ImageTexture.create_from_image(img)
	image_path = path
	_aspect = float(img.get_width()) / float(img.get_height())
	_build()
	return true

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3, uvs: Array = []) -> void:
	# a,b,c,d go around the quad; hint = direction the visible side must face
	var n := (b - a).cross(c - a).normalized()
	var pts := [a, b, c, d]
	var uv: Array = uvs if uvs.size() == 4 else [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	if n.dot(hint) > 0.0:
		# Godot front faces are clockwise
		pts = [a, d, c, b]
		uv = [uv[0], uv[3], uv[2], uv[1]]
	else:
		n = -n
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(pts[i])

func _loop(sz: Vector2, z: float) -> Array:
	return [Vector3(-sz.x, -sz.y, z), Vector3(sz.x, -sz.y, z), Vector3(sz.x, sz.y, z), Vector3(-sz.x, sz.y, z)]

func _ring(st: SurfaceTool, la: Array, lb: Array, out_w: float, z_w: float, mode: int = 0) -> void:
	for i in 4:
		var j := (i + 1) % 4
		var mid: Vector3 = (la[i] + la[j]) * 0.5
		var o := Vector3.ZERO
		# edge normal in xy: the edge is axis-aligned
		if absf(la[i].x - la[j].x) < 0.0001:
			o = Vector3(signf(mid.x), 0, 0)
		else:
			o = Vector3(0, signf(mid.y), 0)
		var uvs: Array
		if mode == 0:
			uvs = [_uv_front(la[i]), _uv_front(la[j]), _uv_front(lb[j]), _uv_front(lb[i])]
		else:
			var r: Rect2 = STRIP_OUT if mode == 1 else STRIP_IN
			uvs = [_strip_uv(r, 0.0, 1.0), _strip_uv(r, 1.0, 1.0), _strip_uv(r, 1.0, 0.0), _strip_uv(r, 0.0, 0.0)]
		_quad(st, la[i], la[j], lb[j], lb[i], o * out_w + Vector3(0, 0, z_w), uvs)

func _build() -> void:
	var m := ArrayMesh.new()
	# --- surface 0: frame ---
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var l_back := _loop(OUTER, 0.0)
	var l0 := _loop(OUTER, 0.02)
	var l1 := _loop(MID, 0.03)
	var l2 := _loop(INNER, 0.02)
	var l3 := _loop(INNER, 0.01)
	_ring(st, l_back, l0, 1.0, 0.0, 1)
	_ring(st, l0, l1, 0.4, 1.0)
	_ring(st, l1, l2, -0.4, 1.0)
	_ring(st, l2, l3, -1.0, 0.0, 2)
	# canvas behind the picture
	var cz := 0.01
	var c0 := Vector3(-INNER.x, -INNER.y, cz)
	var c1 := Vector3(INNER.x, -INNER.y, cz)
	var c2 := Vector3(INNER.x, INNER.y, cz)
	var c3 := Vector3(-INNER.x, INNER.y, cz)
	_quad(st, c0, c1, c2, c3, Vector3(0, 0, 1), [_uv_front(c0), _uv_front(c1), _uv_front(c2), _uv_front(c3)])
	# back
	var b0 := Vector3(-OUTER.x, -OUTER.y, 0.0)
	var b1 := Vector3(OUTER.x, -OUTER.y, 0.0)
	var b2 := Vector3(OUTER.x, OUTER.y, 0.0)
	var b3 := Vector3(-OUTER.x, OUTER.y, 0.0)
	_quad(st, b0, b1, b2, b3, Vector3(0, 0, -1), [_uv_back(b0), _uv_back(b1), _uv_back(b2), _uv_back(b3)])
	var arr := st.commit_to_arrays()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	m.surface_set_material(0, _frame_mat)
	# --- surface 1: picture ---
	if _tex != null and _aspect > 0.0:
		var box_w := INNER.x * 2.0
		var box_h := INNER.y * 2.0
		var w := box_w
		var h := box_w / _aspect
		if h > box_h:
			h = box_h
			w = box_h * _aspect
		var hw := w * 0.5
		var hh := h * 0.5
		var z := 0.0115
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		_quad(st2, Vector3(-hw, -hh, z), Vector3(hw, -hh, z), Vector3(hw, hh, z), Vector3(-hw, hh, z), Vector3(0, 0, 1), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st2.commit_to_arrays())
		if _pic_mat is ShaderMaterial:
			_pic_mat.set_shader_parameter("albedo", _tex)
		else:
			_pic_mat.albedo_texture = _tex
		m.surface_set_material(1, _pic_mat)
	mesh = m
