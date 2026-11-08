extends Node

# id -> [item .tres, icon .png]
# The PNGs have the same pixel size as vanilla icons (2 x grid size), so the furniture
# catalog (which draws icons at 0.5 x texture size) shows them exactly inside their grid slot.
const ITEMS := {
	"Weapon_Display_Wall": ["res://WallWeaponDisplay/Weapon_Display_Wall_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall.png"],
	"Weapon_Display_Wall_S": ["res://WallWeaponDisplay/Weapon_Display_Wall_S_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall_S.png"],
	"Weapon_Display_Wall_gray": ["res://WallWeaponDisplay/Weapon_Display_Wall_gray_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall_gray.png"],
	"Weapon_Display_Wall_black": ["res://WallWeaponDisplay/Weapon_Display_Wall_black_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall_black.png"],
	"Weapon_Display_Wall_S_gray": ["res://WallWeaponDisplay/Weapon_Display_Wall_S_gray_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall_S_gray.png"],
	"Weapon_Display_Wall_S_black": ["res://WallWeaponDisplay/Weapon_Display_Wall_S_black_F.tres", "res://WallWeaponDisplay/Icon_Weapon_Display_Wall_S_black.png"],
}

const IconLoader = preload("res://WallWeaponDisplay/IconLoader.gd")

# Trader stock: Trader.gd fills "traderBucket" once and every restock picks 40 random entries
# from it. The displays are added to the bucket of the traders below so that, per picked slot,
# all listed displays together have about `share` chance (Gunsmith 1%, Generalist 0.6%).
# Gunsmith sells all six displays, the Generalist only the small (S) ones, at a lower chance.
const TRADER_PLANS := {
	"Gunsmith": {
		"share": 0.01,
		"ids": ["Weapon_Display_Wall", "Weapon_Display_Wall_S", "Weapon_Display_Wall_gray", "Weapon_Display_Wall_black", "Weapon_Display_Wall_S_gray", "Weapon_Display_Wall_S_black"],
	},
	"Generalist": {
		"share": 0.006,
		"ids": ["Weapon_Display_Wall_S", "Weapon_Display_Wall_S_gray", "Weapon_Display_Wall_S_black"],
	},
}
var _seen_traders := {}

func _ready() -> void:
	var lib = Engine.get_meta("RTVModLib", null)
	if lib == null:
		push_warning("[WallWeaponDisplay] Metro Mod Loader (RTVModLib) not found - mod disabled.")
		return
	_apply_icons(lib)
	var result = lib.register_furniture({
		"Weapon_Display_Wall": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Weapon_Display_Wall_S": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Weapon_Display_Wall_gray": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_gray_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_gray_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Weapon_Display_Wall_black": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_black_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_black_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Weapon_Display_Wall_S_gray": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_gray_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_gray_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Weapon_Display_Wall_S_black": {
			"item_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_black_F.tres",
			"scene_path": "res://WallWeaponDisplay/Weapon_Display_Wall_S_black_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
	})
	print("[WallWeaponDisplay] register_furniture -> ", result)
	# the registry may hold its own copy of the item, so apply again on the registered entry
	_apply_icons(lib)
	get_tree().node_added.connect(_on_node_added)
	await get_tree().process_frame
	_apply_icons(lib)
	_scan_for_traders(get_tree().root)

func _apply_icons(lib) -> void:
	for id in ITEMS:
		var tex = _get_tex(id)
		if tex == null:
			continue
		var item = load(ITEMS[id][0])
		if item != null:
			item.icon = tex
		if lib.has_method("get_entry"):
			var entry = lib.get_entry(lib.Registry.ITEMS, id)
			if entry != null and entry != item:
				entry.icon = tex
			print("[WallWeaponDisplay] icon applied: ", id, " ", tex.get_size(), " registry entry: ", entry != null)

func _get_tex(id: String):
	return IconLoader.get_texture(ITEMS[id][1])


func _on_node_added(node: Node) -> void:
	if node is Node3D:
		call_deferred("_try_trader", node)

func _scan_for_traders(node: Node) -> void:
	_try_trader(node)
	for c in node.get_children():
		_scan_for_traders(c)

func _try_trader(node: Node) -> void:
	if not is_instance_valid(node) or _seen_traders.has(node.get_instance_id()):
		return
	if node.get_script() == null or not ("traderBucket" in node) or not ("traderData" in node):
		return
	var td = node.get("traderData")
	if td == null or not TRADER_PLANS.has(str(td.name)):
		return
	_seen_traders[node.get_instance_id()] = true
	var bucket = node.get("traderBucket")
	if bucket == null:
		return
	var plan = TRADER_PLANS[str(td.name)]
	var items := []
	for id in plan["ids"]:
		var item = load(ITEMS[id][0])
		if item != null:
			items.append(item)
	if items.is_empty():
		return
	# drop entries that may already be there, so the chance is exactly the planned one
	var natural := 0
	for item in items:
		while bucket.has(item):
			bucket.erase(item)
			natural += 1
	var base: int = bucket.size()
	var total: int = maxi(items.size(), int(round(float(plan["share"]) * base / (1.0 - float(plan["share"])))))
	var copies: int = maxi(1, int(round(float(total) / items.size())))
	for item in items:
		for i in copies:
			bucket.append(item)
	print("[WallWeaponDisplay] ", td.name, " bucket: ", natural, " entries were already in it; base size ", base, ", added ", copies, " x ", items.size(), " displays")
