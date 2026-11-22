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
	"Equipment_Rack": ["res://WallWeaponDisplay/Equipment_Rack_F.tres", "res://WallWeaponDisplay/Icon_Equipment_Rack.png"],
	"Equipment_Rack2": ["res://WallWeaponDisplay/Equipment_Rack2_F.tres", "res://WallWeaponDisplay/Icon_Equipment_Rack2.png"],
	"Key_Hook_Desk": ["res://WallWeaponDisplay/Key_Hook_Desk_F.tres", "res://WallWeaponDisplay/Icon_Key_Hook_Desk.png"],
	"Key_Hook_Desk2": ["res://WallWeaponDisplay/Key_Hook_Desk2_F.tres", "res://WallWeaponDisplay/Icon_Key_Hook_Desk2.png"],
	"Picture_Frame": ["res://WallWeaponDisplay/Picture_Frame_F.tres", "res://WallWeaponDisplay/Icon_Picture_Frame.png"],
	"Picture_Frame_White": ["res://WallWeaponDisplay/Picture_Frame_White_F.tres", "res://WallWeaponDisplay/Icon_Picture_Frame_White.png"],
	"Picture_Frame_Black": ["res://WallWeaponDisplay/Picture_Frame_Black_F.tres", "res://WallWeaponDisplay/Icon_Picture_Frame_Black.png"],
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
		{"share": 0.005, "ids": ["Equipment_Rack"]},
		{"share": 0.005, "ids": ["Equipment_Rack2"]},
	],
	"Generalist": [
		{"share": 0.006, "ids": ["Weapon_Display_Wall_S", "Weapon_Display_Wall_S_gray", "Weapon_Display_Wall_S_black"]},
		{"share": 0.005, "ids": ["Key_Hook", "Key_Hook_Black"]},
		{"share": 0.004, "ids": ["Picture_Frame", "Picture_Frame_White", "Picture_Frame_Black"]},
		{"share": 0.004, "ids": ["Key_Hook_Desk"]},
		{"share": 0.004, "ids": ["Key_Hook_Desk2"]},
	],
}
var _seen_traders := {}
var _bucket_tries := {}

func _ready() -> void:
	var lib = Engine.get_meta("RTVModLib", null)
	if lib == null:
		push_warning("[WallWeaponDisplay] Metro Mod Loader (RTVModLib) not found - mod disabled.")
		return
	_add_mipmaps()
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
		"Equipment_Rack": {
			"item_path": "res://WallWeaponDisplay/Equipment_Rack_F.tres",
			"scene_path": "res://WallWeaponDisplay/Equipment_Rack_F.tscn",
			"trader_pools": ["Gunsmith"],
		},
		"Picture_Frame_White": {
			"item_path": "res://WallWeaponDisplay/Picture_Frame_White_F.tres",
			"scene_path": "res://WallWeaponDisplay/Picture_Frame_White_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Picture_Frame_Black": {
			"item_path": "res://WallWeaponDisplay/Picture_Frame_Black_F.tres",
			"scene_path": "res://WallWeaponDisplay/Picture_Frame_Black_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Key_Hook_Desk2": {
			"item_path": "res://WallWeaponDisplay/Key_Hook_Desk2_F.tres",
			"scene_path": "res://WallWeaponDisplay/Key_Hook_Desk2_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Key_Hook_Desk": {
			"item_path": "res://WallWeaponDisplay/Key_Hook_Desk_F.tres",
			"scene_path": "res://WallWeaponDisplay/Key_Hook_Desk_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Picture_Frame": {
			"item_path": "res://WallWeaponDisplay/Picture_Frame_F.tres",
			"scene_path": "res://WallWeaponDisplay/Picture_Frame_F.tscn",
			"trader_pools": ["Generalist"],
		},
		"Equipment_Rack2": {
			"item_path": "res://WallWeaponDisplay/Equipment_Rack2_F.tres",
			"scene_path": "res://WallWeaponDisplay/Equipment_Rack2_F.tscn",
			"trader_pools": ["Gunsmith"],
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

# The key hook textures are imported lossless without mipmaps, which is slow to sample at a
# distance / at grazing angles. Rebuild them once with mipmaps at runtime.
const MIP_MATERIALS := ["res://WallWeaponDisplay/KeyHook.tres", "res://WallWeaponDisplay/KeyHook_Black.tres", "res://WallWeaponDisplay/equipment_rack.tres", "res://WallWeaponDisplay/equipment_rack2.tres", "res://WallWeaponDisplay/takujo_KeyHook.tres", "res://WallWeaponDisplay/takujo_KeyHook2.tres"]

func _add_mipmaps() -> void:
	for path in MIP_MATERIALS:
		var mat = load(path)
		if mat == null or not (mat is ShaderMaterial):
			continue
		var tex = mat.get_shader_parameter("albedo")
		if tex == null or not (tex is Texture2D) or tex is ImageTexture:
			continue
		var img: Image = tex.get_image()
		if img == null or img.is_empty():
			continue
		if img.has_mipmaps():
			continue
		if img.is_compressed():
			img.decompress()
		img.generate_mipmaps()
		mat.set_shader_parameter("albedo", ImageTexture.create_from_image(img))
		print("[WallWeaponDisplay] mipmaps generated for ", path)

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
	if node is Node3D and str(node.scene_file_path).begins_with("res://WallWeaponDisplay/Picture_Frame_"):
		call_deferred("_frame_spawned", node)
	if node is Node3D and str(node.scene_file_path).begins_with("res://WallWeaponDisplay/Equipment_Rack"):
		call_deferred("_log_rack", node)
	# only nodes that can be a trader are handled; everything else returns right away
	if not (node is Node3D) or node.get_script() == null or not ("traderBucket" in node):
		return
	call_deferred("_try_trader", node)

func _log_rack(node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var n := 0
	for r in get_tree().get_nodes_in_group("EquipmentRack"):
		n += 1
	print("[WallWeaponDisplay] rack spawned: ", node.scene_file_path.get_file(), " pos=", node.global_position, " parent=", node.get_parent().name if node.get_parent() else "none", " racks_in_tree=", n, " frame=", Engine.get_process_frames())

func _scan_for_traders(node: Node) -> void:
	_try_trader(node)
	for c in node.get_children():
		_scan_for_traders(c)

func _try_trader(node) -> void:
	# untyped on purpose: the node may already have been freed when this runs
	if node == null or not is_instance_valid(node) or _seen_traders.has(node.get_instance_id()):
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
# desk key hook: the ring sits on the tilted pegs, the key hangs straight down (same hang basis)
# desk key hook 2: three horizontal pegs (+Z) on the back board
const HOOK_SLOTS_DESK2 := [Vector3(-0.064, 0.192, -0.036), Vector3(0.0, 0.192, -0.036), Vector3(0.064, 0.192, -0.036)]
const HOOK_SLOTS_DESK := [Vector3(-0.0766, 0.2017, 0.0), Vector3(-0.0214, 0.2017, 0.0), Vector3(0.0326, 0.2017, 0.0), Vector3(0.0876, 0.2017, 0.0)]
const HOOK_SLOTS := [Vector3(-0.1333, -0.052, 0.115), Vector3(-0.0458, -0.052, 0.115), Vector3(0.0458, -0.052, 0.115), Vector3(0.1333, -0.052, 0.115)]
const SNAP_RANGE := 0.2
var _gd = null
var _placer = null
var _hung := {}

func _physics_process(_delta: float) -> void:
	_track_frames()
	_follow_hooks()
	_update_rack_spoof()
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
		if local_ring.z < 0.0 and not hook.is_in_group("KeyHookDesk"):
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
	if hook.is_in_group("KeyHookDesk2"):
		return HOOK_SLOTS_DESK2
	if hook.is_in_group("KeyHookDesk"):
		return HOOK_SLOTS_DESK
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

# ---- Rigs and armor plates on the Equipment Rack pegboard -----------------------------------
# Vanilla Placer.Collided only attaches Weapon/Attachment/Knife/Grenade items to "Display" bodies.
# While a rig or armor plate is held in placing mode near a rack, its type is switched to "Weapon"
# so the vanilla code hangs it (same pose logic, middle click still changes the orientation).
# The original type is restored as soon as the item leaves the rack area or placing ends.
var _spoof_data = null
var _spoof_type := ""
var _spoof_offset = null
const RIG_FORWARD := 0.04
const PLATE_FORWARD := 0.02

func _is_rack_item(item) -> bool:
	var path: String = str(item.scene_file_path)
	return path.begins_with("res://Items/Rigs/") or path.begins_with("res://Items/Armor/")

func _near_rack(item) -> bool:
	for rack in get_tree().get_nodes_in_group("EquipmentRack"):
		if not (rack is Node3D) or not rack.is_inside_tree():
			continue
		var p: Vector3 = rack.global_transform.affine_inverse() * item.global_position
		if absf(p.x) < 0.75 and p.y > -0.2 and p.y < 2.3 and p.z > -0.5 and p.z < 1.0:
			return true
	return false

func _restore_spoof() -> void:
	if _spoof_data != null and is_instance_valid(_spoof_data):
		_spoof_data.type = _spoof_type
		if _spoof_offset != null:
			_spoof_data.wallOffset = _spoof_offset
	_spoof_data = null
	_spoof_offset = null
	_spoof_type = ""

func _update_rack_spoof() -> void:
	var item = null
	if _gd != null and _gd.isPlacing and not _gd.decor and _placer != null and is_instance_valid(_placer):
		item = _placer.get("placable")
	if item == null or not is_instance_valid(item) or item.get("slotData") == null or item.slotData.itemData == null:
		if _spoof_data != null:
			_restore_spoof()
		return
	var idata = item.slotData.itemData
	if _spoof_data != null and _spoof_data != idata:
		_restore_spoof()
	if not _is_rack_item(item):
		return
	if _near_rack(item):
		if _spoof_data == null:
			_spoof_data = idata
			_spoof_type = str(idata.type)
			idata.type = "Weapon"
			_spoof_offset = idata.wallOffset
			var fwd: float = RIG_FORWARD if str(item.scene_file_path).begins_with("res://Items/Rigs/") else PLATE_FORWARD
			idata.wallOffset = _spoof_offset + fwd
	elif _spoof_data != null:
		_restore_spoof()


# ---------------------------------------------------------------------------------------------
# Picture frames: right click a hung frame -> small window with an image path + Browse button.
# The chosen image paths are remembered in user://wall_gear_frames.json (matched by position).
# ---------------------------------------------------------------------------------------------
const FRAME_FILE := "user://wall_gear_frames.json"
const FRAME_SCENE := "res://WallWeaponDisplay/Picture_Frame_F.tscn"
var _frame_entries: Array = []        # {p:[x,y,z], path:String}
var _frame_loaded := false
var _frame_nodes := {}                # instance id -> {node, entry}
var _frame_check := 0.0
var _ui_layer: CanvasLayer = null
var _ui_edit: LineEdit = null
var _ui_status: Label = null
var _ui_frame = null
var _ui_prev_mouse := Input.MOUSE_MODE_CAPTURED
var _ui_fd: FileDialog = null

func _load_frames() -> void:
	if _frame_loaded:
		return
	_frame_loaded = true
	if not FileAccess.file_exists(FRAME_FILE):
		return
	var f := FileAccess.open(FRAME_FILE, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		for e in data:
			if e is Dictionary and e.has("p") and e.has("path"):
				_frame_entries.append(e)

func _save_frames() -> void:
	var f := FileAccess.open(FRAME_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_frame_entries))

func _entry_pos(e: Dictionary) -> Vector3:
	var a = e["p"]
	return Vector3(float(a[0]), float(a[1]), float(a[2]))

func _frame_spawned(node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	_load_frames()
	var pos: Vector3 = node.global_position
	var best = null
	var best_d := 0.08
	for e in _frame_entries:
		var taken := false
		for v in _frame_nodes.values():
			if is_same(v["entry"], e) and is_instance_valid(v["node"]):
				taken = true
				break
		if taken:
			continue
		var d := pos.distance_to(_entry_pos(e))
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		best = {"p": [pos.x, pos.y, pos.z], "path": ""}
		_frame_entries.append(best)
	_frame_nodes[node.get_instance_id()] = {"node": node, "entry": best}
	if str(best["path"]) != "":
		var mesh = node.get_node_or_null("Mesh")
		if mesh != null and not mesh.set_image_path(str(best["path"])):
			print("[WallWeaponDisplay] frame image could not be loaded: ", best["path"])

# keep the saved position in sync when a frame is moved with the furniture placer
func _track_frames() -> void:
	if _frame_nodes.is_empty():
		return
	_frame_check += get_physics_process_delta_time()
	if _frame_check < 0.5:
		return
	_frame_check = 0.0
	if _gd == null:
		_gd = load("res://Resources/GameData.tres")
	if _gd != null and _gd.isPlacing:
		return
	var dirty := false
	for id in _frame_nodes.keys():
		var v = _frame_nodes[id]
		if not is_instance_valid(v["node"]) or not v["node"].is_inside_tree():
			_frame_nodes.erase(id)
			continue
		var pos: Vector3 = v["node"].global_position
		if pos.distance_to(_entry_pos(v["entry"])) > 0.02:
			v["entry"]["p"] = [pos.x, pos.y, pos.z]
			dirty = true
	if dirty:
		_save_frames()

func _input(event: InputEvent) -> void:
	if _ui_layer != null:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_frame_ui()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or _frame_nodes.is_empty():
		return
	if _gd == null:
		_gd = load("res://Resources/GameData.tres")
	if _gd == null or _gd.isPlacing or _gd.freeze or _gd.isInspecting:
		return
	var frame = _frame_under_crosshair()
	if frame != null:
		_open_frame_ui(frame)
		get_viewport().set_input_as_handled()

func _frame_under_crosshair():
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 3.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var col = hit["collider"]
	if col == null or not (col is Node) or not col.is_in_group("PictureFrame"):
		return null
	var root = col.get_parent().get_parent()
	if root == null or not _frame_nodes.has(root.get_instance_id()):
		return null
	return root

func _open_frame_ui(frame) -> void:
	_ui_frame = frame
	_ui_prev_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _gd != null:
		_gd.freeze = true
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 100
	add_child(_ui_layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(620, 0)
	panel.position = Vector2(-310, -80)
	_ui_layer.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	var title := Label.new()
	title.text = "Picture Frame - image file (png / jpg / webp / bmp)"
	vb.add_child(title)
	var row := HBoxContainer.new()
	vb.add_child(row)
	_ui_edit = LineEdit.new()
	_ui_edit.custom_minimum_size = Vector2(440, 0)
	_ui_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ui_edit.placeholder_text = "C:\\Users\\...\\picture.png"
	var cur = ""
	var entry = _frame_nodes[frame.get_instance_id()]["entry"]
	cur = str(entry["path"])
	_ui_edit.text = cur
	_ui_edit.text_submitted.connect(_on_frame_submit)
	row.add_child(_ui_edit)
	var browse := Button.new()
	browse.text = "Browse..."
	browse.pressed.connect(_browse_frame_image)
	row.add_child(browse)
	_ui_status = Label.new()
	_ui_status.text = ""
	vb.add_child(_ui_status)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 8)
	vb.add_child(btns)
	var ok := Button.new()
	ok.text = "Apply"
	ok.pressed.connect(_apply_frame_ui)
	btns.add_child(ok)
	var rm := Button.new()
	rm.text = "Remove image"
	rm.pressed.connect(_remove_frame_image)
	btns.add_child(rm)
	var cl := Button.new()
	cl.text = "Close"
	cl.pressed.connect(_close_frame_ui)
	btns.add_child(cl)
	_ui_edit.grab_focus()

func _close_frame_ui() -> void:
	if _ui_layer != null:
		_ui_layer.queue_free()
	_ui_layer = null
	_ui_edit = null
	_ui_status = null
	_ui_frame = null
	_ui_fd = null
	Input.mouse_mode = _ui_prev_mouse
	if _gd != null:
		_gd.freeze = false

func _on_frame_submit(_t: String) -> void:
	_apply_frame_ui()

func _remove_frame_image() -> void:
	if _ui_edit != null:
		_ui_edit.text = ""
	_apply_frame_ui()

func _apply_frame_ui() -> void:
	if _ui_frame == null or not is_instance_valid(_ui_frame) or _ui_edit == null:
		return
	var path := _ui_edit.text.strip_edges().trim_prefix("\"").trim_suffix("\"")
	var mesh = _ui_frame.get_node_or_null("Mesh")
	if mesh == null:
		return
	if path != "" and not FileAccess.file_exists(path):
		_ui_status.text = "File not found."
		return
	if not mesh.set_image_path(path):
		_ui_status.text = "Could not read that image."
		return
	var entry = _frame_nodes[_ui_frame.get_instance_id()]["entry"]
	entry["path"] = path
	var pos: Vector3 = _ui_frame.global_position
	entry["p"] = [pos.x, pos.y, pos.z]
	_save_frames()
	_ui_status.text = "Image removed." if path == "" else "Applied."

func _browse_frame_image() -> void:
	var filters := PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.bmp;Images"])
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show("Select image", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, filters, _on_native_file)
		return
	_ui_fd = FileDialog.new()
	_ui_fd.access = FileDialog.ACCESS_FILESYSTEM
	_ui_fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_ui_fd.use_native_dialog = false
	_ui_fd.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp,*.bmp ; Images"])
	_ui_fd.size = Vector2i(800, 500)
	_ui_fd.file_selected.connect(_on_picked)
	_ui_layer.add_child(_ui_fd)
	_ui_fd.popup_centered()

func _on_native_file(status: bool, paths: PackedStringArray, _idx: int) -> void:
	if status and paths.size() > 0:
		_on_picked(paths[0])

func _on_picked(path: String) -> void:
	if _ui_edit == null:
		return
	_ui_edit.text = path
	_apply_frame_ui()
