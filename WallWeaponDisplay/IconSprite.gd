extends Sprite2D
# Inventory / catalog sprite. The texture is a PNG with the same pixel size as vanilla icons
# (2 x grid size), drawn at scale 0.5, so it fills exactly the item's grid slot.

const IconLoader = preload("res://WallWeaponDisplay/IconLoader.gd")
const FALLBACK := "res://Assets/Weapon_Display/Files/Icon_Weapon_Display.png"

@export var icon_path: String = "":
	set(value):
		icon_path = value
		_apply_icon()

func _apply_icon() -> void:
	var tex = IconLoader.get_texture(icon_path)
	if tex != null:
		region_enabled = false
		texture = tex
	else:
		texture = load(FALLBACK)
		region_enabled = true
		region_rect = Rect2(44, 11, 937, 703)
