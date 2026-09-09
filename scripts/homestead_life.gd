extends RefCounted

const WATER_CAPACITY := 24
const RESOURCE_NAMES := {"wood": "木材", "stone": "石料", "berry": "野莓", "mushroom": "蘑菇"}
const RESOURCE_PRICES := {"wood": 2, "stone": 2, "berry": 12, "mushroom": 18}
const PICKUPS := {
	"farm_outdoor": [[20, 12, "wood"], [22, 15, "stone"], [18, 20, "berry"], [29, 12, "wood"], [22, 24, "mushroom"]],
	"town_square": [[18, 13, "berry"], [30, 14, "mushroom"], [32, 20, "wood"]],
	"riverside": [[12, 15, "berry"], [16, 20, "mushroom"], [20, 13, "stone"]],
}
var resources := {"wood": 0, "stone": 0, "berry": 0, "mushroom": 0}
var gathered: Dictionary = {}
var water := WATER_CAPACITY
var pet_points := 0
var pet_day := 0
var fed_day := 0
var following := true

func available(map_id: String, day: int, navigation) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source_maps: Array = PICKUPS.keys() if map_id == "valley_world" else [map_id]
	for source_map in source_maps:
		for index in PICKUPS.get(source_map, []).size():
			var item: Array = PICKUPS[source_map][index]
			var cell := Vector2i(item[0], item[1])
			if map_id == "valley_world": cell = navigation.to_contiguous_world(source_map, cell)
			var key := str(source_map) + ":" + str(index)
			if int(gathered.get(key, 0)) == day: continue
			if not navigation.is_walkable(map_id, cell): continue
			if not navigation.interaction_at(map_id, cell).is_empty(): continue
			result.append({"cell": cell, "kind": item[2], "key": key})
	return result

func collect(item: Dictionary, day: int) -> bool:
	if int(gathered.get(item.key, 0)) == day: return false
	if not resources.has(item.kind): return false
	gathered[item.key] = day
	resources[item.kind] += 1
	return true

func pet(day: int) -> String:
	if pet_day == day: return "麦麦摇着尾巴蹭了蹭你，今天已经摸过它啦。"
	pet_day = day
	pet_points = mini(1000, pet_points + 20)
	return "麦麦开心地摇尾巴！亲密度 +20。"

func feed(day: int) -> String:
	if fed_day == day: return "麦麦今天已经吃饱了。"
	if resources.berry < 1: return "需要一份野莓做点心，可以在农场或河畔拾取。"
	resources.berry -= 1
	fed_day = day
	pet_points = mini(1000, pet_points + 30)
	return "麦麦吃完点心，满足地舔舔鼻子。亲密度 +30。"

func ship() -> int:
	var earned := 0
	for kind in resources:
		earned += int(resources[kind]) * int(RESOURCE_PRICES[kind])
		resources[kind] = 0
	return earned

func snapshot() -> Dictionary:
	return {"resources": resources.duplicate(), "gathered": gathered.duplicate(), "water": water, "pet_points": pet_points, "pet_day": pet_day, "fed_day": fed_day, "following": following}

func restore(data: Dictionary) -> void:
	water = clampi(int(data.get("water", WATER_CAPACITY)), 0, WATER_CAPACITY)
	pet_points = clampi(int(data.get("pet_points", 0)), 0, 1000)
	pet_day = maxi(0, int(data.get("pet_day", 0)))
	fed_day = maxi(0, int(data.get("fed_day", 0)))
	following = bool(data.get("following", true))
	for kind in resources: resources[kind] = maxi(0, int(data.get("resources", {}).get(kind, 0)))
	gathered = data.get("gathered", {}).duplicate()

static func valid(data) -> bool:
	if not data is Dictionary: return false
	for key in ["water", "pet_points", "pet_day", "fed_day"]:
		if data.has(key) and (not (data[key] is int or data[key] is float) or not is_finite(float(data[key])) or float(data[key]) < 0): return false
	if data.has("following") and not data.following is bool: return false
	for key in ["resources", "gathered"]:
		if not data.get(key, {}) is Dictionary: return false
		for amount in data.get(key, {}).values():
			if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount) < 0: return false
	return true
