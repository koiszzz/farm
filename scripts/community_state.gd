class_name CommunityState
extends RefCounted

const BUNDLES := {
	"pantry": {"name": "四季农产", "items": [["crop", "parsnip", 1], ["crop", "tomato", 1], ["crop", "pumpkin", 1], ["crop", "powdermelon", 1]], "reward": ["gold", 500]},
	"angler": {"name": "山谷鱼获", "items": [["fish", "creek_fish", 1], ["fish", "sardine", 1], ["fish", "catfish", 1], ["fish", "squid", 1]], "reward": ["gold", 400]},
	"crafts": {"name": "林海采集", "items": [["resource", "wood", 10], ["resource", "stone", 10], ["resource", "shell", 3], ["resource", "mushroom", 2]], "reward": ["backpack", 5]},
	"boiler": {"name": "矿洞修复", "items": [["resource", "copper_ore", 5], ["resource", "iron_ore", 5], ["resource", "coal", 5], ["resource", "quartz", 1]], "reward": ["gold", 600]},
}

var completed: Dictionary = {}
var donated: Dictionary = {}
var grand_reward := false

func count_item(item: Array, farm, homestead, fishing) -> int:
	match str(item[0]):
		"crop": return farm.get_harvest_count(str(item[1]))
		"resource": return int(homestead.resources.get(str(item[1]), 0))
		"fish": return int(fishing.inventory.get(str(item[1]), 0))
	return 0

func can_complete(id: String, farm, homestead, fishing) -> bool:
	if not BUNDLES.has(id) or completed.has(id): return false
	for index in BUNDLES[id].items.size():
		var item: Array = BUNDLES[id].items[index]
		if count_item(item, farm, homestead, fishing) < remaining_count(id, index): return false
	return true

func donate(id: String, farm, homestead, fishing) -> Dictionary:
	if not BUNDLES.has(id): return {"ok": false, "message": "没有这项修复计划。"}
	if completed.has(id): return {"ok": false, "message": "这组物资已经完成。"}
	if not can_complete(id, farm, homestead, fishing): return {"ok": false, "message": "背包中的物资还不齐全，没有扣除任何物品。"}
	for index in BUNDLES[id].items.size():
		var item: Array = BUNDLES[id].items[index]
		var kind := str(item[0])
		var item_id := str(item[1])
		var amount := remaining_count(id, index)
		_consume(item, amount, farm, homestead, fishing)
		_set_donated(id, index, int(item[2]))
	return _complete_bundle(id)


func donate_item(id: String, item_index: int, farm, homestead, fishing) -> Dictionary:
	if not BUNDLES.has(id): return {"ok": false, "message": "没有这项修复计划。"}
	if completed.has(id): return {"ok": false, "message": "这组物资已经完成。"}
	var items: Array = BUNDLES[id].items
	if item_index < 0 or item_index >= items.size(): return {"ok": false, "message": "这项物资不在修复清单中。"}
	var item: Array = items[item_index]
	var remaining := remaining_count(id, item_index)
	var available := count_item(item, farm, homestead, fishing)
	if available <= 0: return {"ok": false, "message": "背包里还没有%s。" % item_name(item, farm, homestead, fishing)}
	var amount := mini(remaining, available)
	_consume(item, amount, farm, homestead, fishing)
	_set_donated(id, item_index, donated_count(id, item_index) + amount)
	if is_bundle_ready(id): return _complete_bundle(id, amount, item_index)
	var donated_now := donated_count(id, item_index)
	return {"ok": true, "partial": true, "amount": amount, "bundle": id, "item_index": item_index, "message": "已捐献%s ×%d，进度 %d / %d。" % [item_name(item, farm, homestead, fishing), amount, donated_now, int(item[2])]}


func donated_count(id: String, item_index: int) -> int:
	var bundle_progress = donated.get(id, {})
	if not bundle_progress is Dictionary: return 0
	return maxi(0, int(bundle_progress.get(str(item_index), 0)))


func remaining_count(id: String, item_index: int) -> int:
	if not BUNDLES.has(id): return 0
	var items: Array = BUNDLES[id].items
	if item_index < 0 or item_index >= items.size(): return 0
	return maxi(0, int(items[item_index][2]) - donated_count(id, item_index))


func is_bundle_ready(id: String) -> bool:
	if not BUNDLES.has(id): return false
	for index in BUNDLES[id].items.size():
		if remaining_count(id, index) > 0: return false
	return true


func item_name(item: Array, farm, homestead, fishing) -> String:
	var id := str(item[1])
	match str(item[0]):
		"crop": return str(farm.get_crop_definition(id).label)
		"resource": return str(homestead.RESOURCE_NAMES.get(id, id))
		"fish": return str(fishing.DEFINITIONS.get(id, {}).get("name", id))
	return id


func _complete_bundle(id: String, amount := 0, item_index := -1) -> Dictionary:
	completed[id] = true
	var all_complete: bool = completed.size() == BUNDLES.size()
	var grant_grand: bool = all_complete and not grand_reward
	if grant_grand: grand_reward = true
	return {"ok": true, "name": BUNDLES[id].name, "reward": BUNDLES[id].reward.duplicate(), "grand": grant_grand, "bundle_complete": true, "partial": false, "amount": amount, "item_index": item_index}


func _set_donated(id: String, item_index: int, amount: int) -> void:
	if not donated.has(id): donated[id] = {}
	var bundle_progress: Dictionary = donated[id]
	bundle_progress[str(item_index)] = amount


func _consume(item: Array, amount: int, farm, homestead, fishing) -> void:
	var item_id := str(item[1])
	match str(item[0]):
		"crop":
			farm.harvest_inventory[item_id] = int(farm.harvest_inventory.get(item_id, 0)) - amount
			farm.inventory_changed.emit("harvest", item_id, farm.get_harvest_count(item_id))
		"resource": homestead.resources[item_id] = int(homestead.resources.get(item_id, 0)) - amount
		"fish": fishing.inventory[item_id] = int(fishing.inventory.get(item_id, 0)) - amount

func item_label(item: Array, farm, homestead, fishing) -> String:
	return "%s %d/%d" % [item_name(item, farm, homestead, fishing), count_item(item, farm, homestead, fishing), int(item[2])]

func snapshot() -> Dictionary:
	return {"completed": completed.duplicate(), "donated": donated.duplicate(true), "grand_reward": grand_reward}

func restore(data: Dictionary) -> void:
	completed.clear()
	for id in data.get("completed", {}):
		if BUNDLES.has(id) and bool(data.completed[id]): completed[id] = true
	donated.clear()
	for id in data.get("donated", {}):
		if not BUNDLES.has(id) or not data.donated[id] is Dictionary: continue
		for index_key in data.donated[id]:
			var index := int(index_key)
			if str(index) != str(index_key) or index < 0 or index >= BUNDLES[id].items.size(): continue
			var requirement := int(BUNDLES[id].items[index][2])
			_set_donated(id, index, clampi(int(data.donated[id][index_key]), 0, requirement))
	for id in completed:
		for index in BUNDLES[id].items.size(): _set_donated(id, index, int(BUNDLES[id].items[index][2]))
	grand_reward = bool(data.get("grand_reward", false)) and completed.size() == BUNDLES.size()

static func valid(data) -> bool:
	if not data is Dictionary or not data.get("completed", {}) is Dictionary: return false
	if data.has("donated") and not data.donated is Dictionary: return false
	if data.has("grand_reward") and not data.grand_reward is bool: return false
	for id in data.completed:
		if not BUNDLES.has(id) or not data.completed[id] is bool: return false
	for id in data.get("donated", {}):
		if not BUNDLES.has(id) or not data.donated[id] is Dictionary: return false
		for index_key in data.donated[id]:
			var index_text := str(index_key)
			if not index_text.is_valid_int(): return false
			var index := int(index_text)
			if index < 0 or index >= BUNDLES[id].items.size(): return false
			var value = data.donated[id][index_key]
			var required := int(BUNDLES[id].items[index][2])
			if not _valid_count(value) or float(value) < 0 or float(value) > required or floorf(float(value)) != float(value): return false
	if bool(data.get("grand_reward", false)):
		for id in BUNDLES:
			if not bool(data.completed.get(id, false)): return false
	return true


static func _valid_count(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
