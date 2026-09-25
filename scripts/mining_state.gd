extends RefCounted

const CELLS := [Vector2i(14, 11), Vector2i(18, 12), Vector2i(22, 12), Vector2i(14, 18), Vector2i(21, 21), Vector2i(17, 6), Vector2i(9, 13), Vector2i(27, 13)]
const FLOOR_CELLS := {
	"cave": CELLS,
	"mine_2": [Vector2i(8, 10), Vector2i(17, 12), Vector2i(26, 11), Vector2i(13, 15), Vector2i(20, 18), Vector2i(30, 15), Vector2i(10, 23), Vector2i(26, 23)],
	"mine_3": [Vector2i(8, 8), Vector2i(18, 10), Vector2i(27, 10), Vector2i(13, 14), Vector2i(23, 16), Vector2i(9, 22), Vector2i(18, 20), Vector2i(30, 21)],
}
const GEM_VEINS := {
	"cave": {Vector2i(17, 6): "earth_crystal"},
	"mine_2": {Vector2i(30, 15): "amethyst", Vector2i(26, 23): "frozen_tear"},
	"mine_3": {Vector2i(30, 21): "fire_quartz"},
}
var tools := {"pickaxe": 0, "water": 0, "hoe": 0}
var day := 0
var damage: Dictionary = {}
var broken: Dictionary = {}
var deepest := 1

static func is_mine(map_id: String) -> bool:
	return map_id in ["cave", "mine_2", "mine_3"]

static func cells_for_floor(map_id: String) -> Array:
	return FLOOR_CELLS.get(map_id, [])

func sync_day(value: int) -> void:
	if day == value: return
	day = value
	damage.clear()
	broken.clear()

func vein(map_id: String, cell: Vector2i, current_day: int) -> Dictionary:
	var floor_cells: Array = cells_for_floor(map_id)
	if not is_mine(map_id) or cell not in floor_cells: return {}
	sync_day(current_day)
	var key := map_id + ":" + str(cell)
	if broken.has(key): return {}
	var index := floor_cells.find(cell)
	var gem_id := str(GEM_VEINS.get(map_id, {}).get(cell, ""))
	var material := gem_id if not gem_id.is_empty() else "coal" if index % 3 == 0 else "copper_ore" if map_id == "cave" else "iron_ore" if map_id == "mine_2" else "quartz"
	return {"key": key, "cell": cell, "material": material, "is_gem": not gem_id.is_empty(), "amount": 1 if not gem_id.is_empty() else 2, "required": 0 if map_id == "cave" else 1 if map_id == "mine_2" else 2, "hits": 2 if map_id == "cave" else 3}

func strike(map_id: String, cell: Vector2i, current_day: int) -> Dictionary:
	var node := vein(map_id, cell, current_day)
	if node.is_empty(): return {"ok": false, "message": "面前没有可开采的矿石。"}
	if int(tools.pickaxe) < int(node.required): return {"ok": false, "message": "岩石太硬，需要先升级镐子。"}
	var hits := int(damage.get(node.key, 0)) + 1 + int(tools.pickaxe)
	damage[node.key] = hits
	var complete: bool = hits >= int(node.hits)
	if complete: broken[node.key] = true
	return {"ok": true, "complete": complete, "material": node.material, "amount": int(node.amount) if complete else 0}

func upgrade_cost(tool: String) -> Dictionary:
	if not tools.has(tool) or int(tools[tool]) >= 2: return {}
	var level := int(tools[tool])
	return {"gold": 150 if level == 0 else 400, "ore": "copper_ore" if level == 0 else "iron_ore", "amount": 5, "coal": 2 if level == 0 else 3}

func upgrade(tool: String, farm, resources: Dictionary) -> bool:
	var cost := upgrade_cost(tool)
	if cost.is_empty() or farm.gold < int(cost.gold) or int(resources.get(cost.ore, 0)) < int(cost.amount) or int(resources.get("coal", 0)) < int(cost.coal): return false
	farm.gold -= int(cost.gold)
	resources[cost.ore] -= int(cost.amount)
	resources.coal -= int(cost.coal)
	tools[tool] += 1
	return true

func snapshot() -> Dictionary:
	return {"tools": tools.duplicate(), "day": day, "damage": damage.duplicate(), "broken": broken.duplicate(), "deepest": deepest}

func restore(data: Dictionary) -> void:
	for tool in tools: tools[tool] = clampi(int(data.get("tools", {}).get(tool, 0)), 0, 2)
	day = int(data.get("day", 0))
	damage = data.get("damage", {}).duplicate()
	broken = data.get("broken", {}).duplicate()
	deepest = clampi(int(data.get("deepest", 1)), 1, 3)

static func valid(data) -> bool:
	if not data is Dictionary: return false
	for key in ["day", "deepest"]:
		if data.has(key) and (not data[key] is float and not data[key] is int or not is_finite(float(data[key])) or float(data[key]) < 0): return false
	for field in ["tools", "damage", "broken"]:
		if not data.get(field, {}) is Dictionary: return false
		for value in data.get(field, {}).values():
			if field == "broken":
				if not value is bool: return false
			elif (not value is int and not value is float) or not is_finite(float(value)) or float(value) < 0: return false
	return true
