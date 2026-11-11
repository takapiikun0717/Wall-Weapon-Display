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
	"Key_Hook": ["res://WallWeaponDisplay/Key_Hook_F.tres", "res://WallWeaponDisplay/Icon_Key_Hook.png"],
	"Key_Hook_Black": ["res://WallWeaponDisplay/Key_Hook_Black_F.tres", "res://WallWeaponDisplay/Icon_Key_Hook_Black.png"],
}

const IconLoader = preload("res://WallWeaponDisplay/IconLoader.gd")

# Trader stock: Trader.gd fills "traderBucket" once and every restock picks 40 random entries
# from it. The displays are added to the bucket of the traders below so that, per picked slot,
# all listed displays together have about `share` chance (Gunsmith 1%, Generalist 0.6%).
# Gunsmith sells all six displays, the Generalist only the small (S) ones, at a lower chance.
# Each trader has a list of groups; every group gets its own `share`.
const TRADER_PLANS := {
	"Gunsmith": [
		{"share": 0.01, "ids": ["Weapon_Display_Wall", "Weapon_Display_Wall_S", "Weapon_Display_Wall_gray", "Weapon_Display_Wall_black", "Weapon_Display_Wall_S_gray", "Weapon_Display_Wall_S_black"]},
	],
	"Generalist": [
		{"share": 0.006, "ids": ["Weapon_Display_Wall_S", "Weapon_Display_Wall_S_gray", "Weapon_Display_Wall_S_black"]},
		{"share": 0.005, "ids": ["Key_Hook", "Key_Hook_Black"]},
	],
}
var _seen_traders := {}
var _bucket_tries := {}

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
		"Key_Hook": {
			"item_path": "res://WallWeaponDisplay/Key_Hook_F.tres",
			"scene_path": "res://WallWeaponDisplay/Key_Hook_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Key_Hook_Black": {
			"item_path": "res://WallWeaponDisplay/Key_Hook_Black_F.tres",
			"scene_path": "res://WallWeaponDisplay/Key_Hook_Black_F.tscn",
			"trader_pools": ["Generalist"],
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
	var bucket = node.get("traderBucket")
	if bucket == null:
		return
	# the trader fills its bucket in _ready; if it is still empty, try again shortly (max ~15 s)
	var tries: int = _bucket_tries.get(node.get_instance_id(), 0)
	if bucket.is_empty() and tries < 15:
		_bucket_tries[node.get_instance_id()] = tries + 1
		get_tree().create_timer(1.0).timeout.connect(_try_trader.bind(node))
		return
	_seen_traders[node.get_instance_id()] = true
	for plan in TRADER_PLANS[str(td.name)]:
		_inject(bucket, td, plan)

func _inject(bucket, td, plan) -> void:
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

# ---- Key hanging on the Key Hook ----------------------------------------------------------
# Vanilla Placer.Collided only lets weapons/attachments/knives/grenades stick to "Display"
# bodies. While a key is held in placing mode and its ring comes close to a free hook of a
# Key Hook (group "KeyHook"), the key is snapped onto that hook with the ring around the peg
# (same steps as the vanilla display code). One key per hook.
const KEY_RING := Vector3(-0.0705, 0.0095, 0.0)   # ring centre in the key mesh (ring axis = key Y, blade = key +X)
const KEY_HANG_BASIS := Basis(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0))  # ring axis -> hook (+Z), blade -> down
const HOOK_SLOTS_6 := [Vector3(-0.25, -0.0389, 0.045), Vector3(-0.15, -0.0389, 0.045), Vector3(-0.05, -0.0389, 0.045), Vector3(0.05, -0.0389, 0.045), Vector3(0.15, -0.0389, 0.045), Vector3(0.25, -0.0389, 0.045)]
const HOOK_SLOTS := [Vector3(-0.1333, -0.052, 0.115), Vector3(-0.0458, -0.052, 0.115), Vector3(0.0458, -0.052, 0.115), Vector3(0.1333, -0.052, 0.115)]
const SNAP_RANGE := 0.2
var _gd = null
var _placer = null
var _hung := {}

func _physics_process(_delta: float) -> void:
	_follow_hooks()
	if _gd == null:
		_gd = load("res://Resources/GameData.tres")
	if _gd == null or _gd.decor or not _gd.isPlacing:
		return
	if _placer == null or not is_instance_valid(_placer):
		_placer = get_tree().root.find_child("Placer", true, false)
		if _placer == null:
			return
	var key = _placer.get("placable")
	if key == null or not is_instance_valid(key) or _placer.get("initialWait"):
		return
	if not _is_key(key):
		return
	var hooks := get_tree().get_nodes_in_group("KeyHook")
	if hooks.is_empty():
		return
	var ring_world: Vector3 = key.global_transform * KEY_RING
	var best_hook = null
	var best_i := -1
	var best_d := SNAP_RANGE
	for hook in hooks:
		if not (hook is Node3D) or not hook.is_inside_tree():
			continue
		var inv: Transform3D = hook.global_transform.affine_inverse()
		var local_ring: Vector3 = inv * ring_world
		if local_ring.z < 0.0:
			continue
		var slots: Array = _slots_of(hook)
		for i in slots.size():
			if _slot_taken(hook, i, key):
				continue
			var d: float = local_ring.distance_to(slots[i])
			if d < best_d:
				best_d = d
				best_hook = hook
				best_i = i
	if best_hook == null:
		return
	_hang(key, best_hook, best_i)

func _is_key(item) -> bool:
	var sd = item.get("slotData")
	if sd == null or sd.itemData == null:
		return false
	var idata = sd.itemData
	return str(idata.type) == "Key" or str(idata.file).begins_with("Key_")

func _slot_id(hook, i: int) -> String:
	return str(hook.get_instance_id()) + "_" + str(i)

func _slot_taken(hook, i: int, self_key) -> bool:
	var e = _hung.get(_slot_id(hook, i))
	if e == null:
		return false
	var k = e["key"]
	return is_instance_valid(k) and k.is_inside_tree() and k != self_key

# Hung keys follow their Key Hook while it is moved (vanilla parenting only catches some of them).
func _follow_hooks() -> void:
	if _hung.is_empty():
		return
	for id in _hung.keys():
		var e = _hung[id]
		var k = e["key"]
		var h = e["hook"]
		if not is_instance_valid(k) or not is_instance_valid(h) or not k.is_inside_tree() or not h.is_inside_tree():
			_hung.erase(id)
			continue
		if _placer != null and is_instance_valid(_placer) and _placer.get("placable") == k:
			_hung.erase(id)   # the player took it off the hook (placing mode)
			continue
		if k.get("freeze") == false:
			_hung.erase(id)
			continue
		var expected: Transform3D = h.global_transform * e["local"]
		var pos: Vector3 = k.global_transform.origin
		if pos.distance_to(expected.origin) < 0.02:
			e["last"] = expected.origin
		elif pos.distance_to(e["last"]) < 0.02:
			k.global_transform = expected
			e["last"] = expected.origin
		else:
			_hung.erase(id)   # moved by something else

func _slots_of(hook) -> Array:
	return HOOK_SLOTS_6 if hook.is_in_group("KeyHook6") else HOOK_SLOTS

func _hang(key, hook, i: int) -> void:
	var local := Transform3D(KEY_HANG_BASIS, _slots_of(hook)[i] - KEY_HANG_BASIS * KEY_RING)
	var xf: Transform3D = hook.global_transform * local
	if key.has_signal("body_entered") and key.body_entered.is_connected(_placer.Collided):
		key.body_entered.disconnect(_placer.Collided)
	key.global_transform = xf
	key.linear_velocity = Vector3.ZERO
	key.angular_velocity = Vector3.ZERO
	key.Freeze()
	_placer.placable = null
	_gd.isPlacing = false
	if _placer.has_method("AttachAudio"):
		_placer.AttachAudio()
	_hung[_slot_id(hook, i)] = {"key": key, "hook": hook, "local": local, "last": xf.origin}
	print("[WallWeaponDisplay] hung key on hook ", i)
