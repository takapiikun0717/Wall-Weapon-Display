extends "res://WallWeaponDisplay/PictureFrameMesh.gd"

func _cfg() -> void:
	atlas_path = "res://WallWeaponDisplay/Frame_Texture_White.jpg"
	FRONT = Rect2(13, 159, 745, 594)
	BACK = Rect2(779, 159, 744, 594)
	STRIP_OUT = Rect2(14, 773, 1509, 58)
	STRIP_IN = Rect2(14, 844, 1509, 57)
