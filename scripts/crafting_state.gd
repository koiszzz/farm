class_name CraftingState
extends RefCounted

const PLACEABLES := {
	"sprinkler": {"name": "铜制洒水器", "description": "每天自动浇灌上下左右四格。"},
	"mayo_machine": {"name": "蛋黄酱机", "description": "放入鸡蛋，隔夜制成蛋黄酱。"},
	"preserves_jar": {"name": "腌制罐", "description": "放入作物，隔夜制成高价值腌菜。"},
	"cheese_press": {"name": "奶酪机", "description": "放入一桶牛奶，隔夜制成高价值奶酪。"},
}

const RECIPES := {
	"trail_mix": {"name": "林间什锦", "energy": 45, "ingredients": [["resource", "berry", 1], ["resource", "mushroom", 1]], "unlock": ["default"]},
	"fish_stew": {"name": "番茄鱼汤", "energy": 70, "ingredients": [["fish", "creek_fish", 1], ["crop", "tomato", 1]], "unlock": ["milestone", "fisherman", 1]},
	"pumpkin_soup": {"name": "南瓜蘑菇汤", "energy": 80, "ingredients": [["crop", "pumpkin", 1], ["resource", "mushroom", 1]], "unlock": ["milestone", "cook", 1]},
	"miner_lunch": {"name": "矿工便当", "energy": 90, "ingredients": [["crop", "potato", 1], ["fish", "sardine", 1]], "unlock": ["mine", 2]},
	"field_salad": {"name": "田园沙拉", "energy": 55, "ingredients": [["crop", "parsnip", 1], ["crop", "turnip", 1]], "unlock": ["skill", "farming", 2]},
	"sea_skewer": {"name": "海风烤串", "energy": 60, "ingredients": [["fish", "sardine", 1], ["resource", "mushroom", 1]], "unlock": ["skill", "fishing", 2]},
	"miner_rice": {"name": "矿工饭团", "energy": 70, "ingredients": [["crop", "potato", 1], ["resource", "coal", 1]], "unlock": ["skill", "mining", 2]},
	"berry_tart": {"name": "野莓挞", "energy": 50, "ingredients": [["resource", "berry", 2]], "unlock": ["skill", "foraging", 2]},
	"sprinkler": {"name": "铜制洒水器", "ingredients": [["resource", "copper_ore", 2], ["resource", "iron_ore", 1]], "unlock": ["skill", "farming", 2], "output": ["placeable", "sprinkler", 1]},
	"mayo_machine": {"name": "蛋黄酱机", "ingredients": [["resource", "wood", 8], ["resource", "stone", 5], ["resource", "copper_ore", 2]], "unlock": ["skill", "farming", 2], "output": ["placeable", "mayo_machine", 1]},
	"preserves_jar": {"name": "腌制罐", "ingredients": [["resource", "wood", 12], ["resource", "stone", 8], ["resource", "coal", 1]], "unlock": ["skill", "farming", 4], "output": ["placeable", "preserves_jar", 1]},
	"cheese_press": {"name": "奶酪机", "ingredients": [["resource", "wood", 10], ["resource", "stone", 6], ["resource", "copper_ore", 3]], "unlock": ["skill", "farming", 3], "output": ["placeable", "cheese_press", 1]},
}

var meals: Dictionary = {}
var crafted_items: Dictionary = {}

func is_unlocked(id: String, village, mining, skills = null) -> bool:
	if not RECIPES.has(id): return false
	var unlock: Array = RECIPES[id].unlock
	match str(unlock[0]):
		"default": return true
		"milestone": return village.has_milestone(str(unlock[1]), int(unlock[2]))
		"mine": return int(mining.deepest) >= int(unlock[1])
		"skill": return skills != null and skills.level(str(unlock[1])) >= int(unlock[2])
	return false

func count_ingredient(item: Array, farm, homestead, fishing) -> int:
	match str(item[0]):
		"crop": return farm.get_harvest_count(str(item[1]))
		"resource": return int(homestead.resources.get(str(item[1]), 0))
		"fish": return int(fishing.inventory.get(str(item[1]), 0))
	return 0

func can_craft(id: String, farm, homestead, fishing, village, mining, skills = null) -> bool:
	if not is_unlocked(id, village, mining, skills): return false
	for item in RECIPES[id].ingredients:
		if count_ingredient(item, farm, homestead, fishing) < int(item[2]): return false
	return true

func craft(id: String, farm, homestead, fishing, village, mining, skills = null) -> Dictionary:
	if not RECIPES.has(id): return {"ok": false, "message": "没有这份配方。"}
	if not is_unlocked(id, village, mining, skills): return {"ok": false, "message": "这份配方还没有解锁。"}
	if not can_craft(id, farm, homestead, fishing, village, mining, skills): return {"ok": false, "message": "材料不足，没有扣除任何物品。"}
	for item in RECIPES[id].ingredients:
		var kind := str(item[0])
		var item_id := str(item[1])
		var amount := int(item[2])
		match kind:
			"crop": farm.harvest_inventory[item_id] -= amount
			"resource": homestead.resources[item_id] -= amount
			"fish": fishing.inventory[item_id] -= amount
	var output: Array = RECIPES[id].get("output", ["meal", id, 1])
	if str(output[0]) == "placeable": crafted_items[str(output[1])] = int(crafted_items.get(str(output[1]), 0)) + int(output[2])
	else: meals[id] = int(meals.get(id, 0)) + 1
	return {"ok": true, "id": id, "name": RECIPES[id].name}

func consume(id: String) -> bool:
	if int(meals.get(id, 0)) <= 0: return false
	meals[id] -= 1
	return true


func consume_item(id: String) -> bool:
	if int(crafted_items.get(id, 0)) <= 0: return false
	crafted_items[id] -= 1
	return true


func add_item(id: String, amount := 1) -> bool:
	if not PLACEABLES.has(id) or amount <= 0: return false
	crafted_items[id] = int(crafted_items.get(id, 0)) + amount
	return true

func ingredient_label(item: Array, farm, homestead, fishing) -> String:
	var id := str(item[1])
	var name := id
	match str(item[0]):
		"crop": name = str(farm.get_crop_definition(id).label)
		"resource": name = str(homestead.RESOURCE_NAMES[id])
		"fish": name = str(fishing.DEFINITIONS[id].name)
	return "%s %d/%d" % [name, count_ingredient(item, farm, homestead, fishing), int(item[2])]

func snapshot() -> Dictionary:
	return {"meals": meals.duplicate(), "items": crafted_items.duplicate()}

func restore(data: Dictionary) -> void:
	meals.clear()
	crafted_items.clear()
	for id in data.get("meals", {}):
		if RECIPES.has(id): meals[id] = maxi(0, int(data.meals[id]))
	for id in data.get("items", {}):
		if PLACEABLES.has(id): crafted_items[id] = maxi(0, int(data.items[id]))

static func valid(data) -> bool:
	if not data is Dictionary or not data.get("meals", {}) is Dictionary or not data.get("items", {}) is Dictionary: return false
	for field in ["meals", "items"]:
		for id in data.get(field, {}):
			var amount = data[field][id]
			if (field == "meals" and (not RECIPES.has(id) or RECIPES[id].has("output"))) or (field == "items" and not PLACEABLES.has(id)): return false
			if (not amount is int and not amount is float) or not is_finite(float(amount)) or float(amount) < 0: return false
	return true
