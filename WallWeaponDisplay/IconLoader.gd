extends RefCounted
# Loads a plain PNG shipped inside the mod (no editor import needed) as an ImageTexture.

static var cache := {}

static func get_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if cache.has(path):
		return cache[path]
	var img: Image = Image.load_from_file(path)
	if img == null or img.is_empty():
		var bytes := FileAccess.get_file_as_bytes(path)
		img = null
		if bytes.size() > 0:
			var tmp := Image.new()
			if tmp.load_png_from_buffer(bytes) == OK:
				img = tmp
	if img == null:
		push_warning("[WallWeaponDisplay] could not load icon " + path)
		return null
	var tex := ImageTexture.create_from_image(img)
	cache[path] = tex
	return tex
