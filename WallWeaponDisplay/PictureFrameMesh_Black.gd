extends "res://WallWeaponDisplay/PictureFrameMesh.gd"

func _cfg() -> void:
	atlas_path = "res://WallWeaponDisplay/Frame_Texture_Black.jpg"
	FRONT = Rect2(16, 173, 743, 565)
	BACK = Rect2(779, 173, 744, 565)
	STRIP_OUT = Rect2(16, 757, 1508, 59)
	STRIP_IN = Rect2(16, 833, 1508, 58)
