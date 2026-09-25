class_name OrchardState
extends RefCounted

const Calendar = preload("res://scripts/life_calendar.gd")

const TREE_TYPES := {
	"apple": {"name": "苹果", "sapling_name": "苹果树苗", "season": 2, "sapling_price": 400, "fruit_price": 100, "energy": 20, "grow_days": 28},
	"orange": {"name": "橙子", "sapling_name": "橙子树苗", "season": 1, "sapling_price": 400, "fruit_price": 100, "energy": 20, "grow_days": 28},
	"peach": {"name": "桃子", "sapling_name": "桃树苗", "season": 1, "sapling_price": 600, "fruit_price": 140, "energy": 24, "grow_days": 28},
	"pomegranate": {"name": "石榴", "sapling_name": "石榴树苗", "season": 2, "sapling_price": 600, "fruit_price": 140, "energy": 24, "grow_days": 28},
}

var saplings: Dictionary = {}
var trees: Array[Dictionary] = []
var fruits: Dictionary = {}


static func is_fruit(id: String) -> bool:
	return TREE_TYPES.has(id)


func buy_sapling(tree_id: String, farm, price := -1) -> Dictionary:
	if not TREE_TYPES.has(tree_id): return _failure("没有这种树苗。")
	var cost: int = int(TREE_TYPES[tree_id].sapling_price) if int(price) < 0 else int(price)
	if farm.gold < cost: return _failure("购买%s需要%d金币。" % [TREE_TYPES[tree_id].sapling_name, cost])
	farm.gold -= cost
	saplings[tree_id] = int(saplings.get(tree_id, 0)) + 1
	return {"ok": true, "message": "购买了%s，可在农场空草地种植。" % TREE_TYPES[tree_id].sapling_name}


func plant(cell: Vector2i, tree_id: String, map_id: String, current_day: int, navigation, farm, animals) -> Dictionary:
	if not TREE_TYPES.has(tree_id): return _failure("未知果树。")
	if int(saplings.get(tree_id, 0)) <= 0: return _failure("背包里没有%s。" % TREE_TYPES[tree_id].sapling_name)
	if map_id not in ["farm_outdoor", "valley_world"]: return _failure("果树只能种在农场。")
	var local_cell := cell
	var world_cell := cell
	if map_id == "valley_world":
		var offset: Vector2i = navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO)
		local_cell -= offset
		world_cell = cell
	if tree_at(local_cell) != -1: return _failure("这里已经有一棵果树了。")
	if not navigation.is_in_bounds(map_id, world_cell): return _failure("这里超出农场边界。")
	if str(navigation.get_cell_class(map_id, world_cell)) != "grass": return _failure("果树要种在未开垦的空草地上。")
	if not navigation.interaction_at(map_id, world_cell).is_empty(): return _failure("这里太靠近设施，换个位置种树。")
	if farm.is_field_occupied(world_cell): return _failure("这格已有作物或设施。")
	if animals.is_solid(local_cell): return _failure("不能种在畜栏里。")
	saplings[tree_id] -= 1
	trees.append({"x": local_cell.x, "y": local_cell.y, "type": tree_id, "plant_day": current_day, "fruit_day": 0})
	return {"ok": true, "message": "种下了%s，%d天后长成。" % [TREE_TYPES[tree_id].sapling_name, int(TREE_TYPES[tree_id].grow_days)]}


func tree_at(cell: Vector2i) -> int:
	for index in trees.size():
		var tree: Dictionary = trees[index]
		if int(tree.x) == cell.x and int(tree.y) == cell.y: return index
	return -1


func is_solid(cell: Vector2i) -> bool:
	return tree_at(cell) >= 0


func tree(cell: Vector2i) -> Dictionary:
	var index := tree_at(cell)
	if index < 0: return {}
	return trees[index].duplicate(true)


func growth_stage(tree: Dictionary, current_day: int) -> int:
	var age := maxi(0, current_day - int(tree.plant_day))
	var grow := int(TREE_TYPES[str(tree.type)].grow_days)
	if age >= grow: return 3
	return clampi(int(age * 3 / grow), 0, 2)


func has_fruit(tree: Dictionary, current_day: int) -> bool:
	if growth_stage(tree, current_day) < 3: return false
	if int(tree.fruit_day) >= current_day: return false
	return Calendar.date(current_day).season == int(TREE_TYPES[str(tree.type)].season)


func collect(cell: Vector2i, current_day: int) -> Dictionary:
	var index := tree_at(cell)
	if index < 0: return _failure("这里没有果树。")
	var tree: Dictionary = trees[index]
	if growth_stage(tree, current_day) < 3: return _failure("这棵树还没长成，继续等待。")
	if Calendar.date(current_day).season != int(TREE_TYPES[str(tree.type)].season): return _failure("%s在%s结果，现在不是它的季节。" % [TREE_TYPES[str(tree.type)].name, Calendar.SEASONS[int(TREE_TYPES[str(tree.type)].season)]])
	if int(tree.fruit_day) >= current_day: return _failure("今天已经摘过了，明天再来。")
	tree.fruit_day = current_day
	trees[index] = tree
	var type := str(tree.type)
	fruits[type] = int(fruits.get(type, 0)) + 1
	return {"ok": true, "fruit": type, "message": "摘下了一个%s，已放入背包。" % TREE_TYPES[type].name}


func consume(type: String) -> bool:
	if int(fruits.get(type, 0)) <= 0: return false
	fruits[type] -= 1
	return true


func ship(farm) -> int:
	var earned := 0
	for type in fruits:
		earned += int(fruits[type]) * int(TREE_TYPES[str(type)].fruit_price)
		fruits[type] = 0
	farm.gold += earned
	return earned


func snapshot() -> Dictionary:
	var rows: Array = []
	for tree in trees: rows.append(tree.duplicate(true))
	return {"saplings": saplings.duplicate(true), "trees": rows, "fruits": fruits.duplicate(true)}


func restore(data: Dictionary) -> void:
	saplings.clear()
	for id in data.get("saplings", {}):
		if TREE_TYPES.has(str(id)): saplings[str(id)] = maxi(0, int(data.saplings[id]))
	trees.clear()
	for value in data.get("trees", []):
		if value is Dictionary: trees.append(value.duplicate(true))
	fruits.clear()
	for id in data.get("fruits", {}):
		if TREE_TYPES.has(str(id)): fruits[str(id)] = maxi(0, int(data.fruits[id]))


static func valid(data) -> bool:
	if not data is Dictionary: return false
	for field in ["saplings", "fruits"]:
		if not data.get(field, {}) is Dictionary: return false
		for id in data.get(field, {}):
			if not TREE_TYPES.has(str(id)) or not _number(data[field][id]) or float(data[field][id]) < 0: return false
	var saved_trees = data.get("trees", [])
	if not saved_trees is Array: return false
	var cells := {}
	for tree in saved_trees:
		if not tree is Dictionary or not tree.has_all(["x", "y", "type", "plant_day", "fruit_day"]): return false
		if not TREE_TYPES.has(str(tree.type)): return false
		for key in ["x", "y", "plant_day", "fruit_day"]:
			if not _number(tree[key]) or float(tree[key]) < 0: return false
		if int(tree.x) >= 64 or int(tree.y) >= 48: return false
		var key := "%d,%d" % [int(tree.x), int(tree.y)]
		if cells.has(key): return false
		cells[key] = true
	return true


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}


static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
