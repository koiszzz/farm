class_name FishingState
extends RefCounted

const Calendar = preload("res://scripts/life_calendar.gd")
const DEFINITIONS := {
	"creek_fish": {"name": "溪鱼", "habitat": "river", "seasons": [0, 1, 2, 3], "hours": [6, 24], "weather": "any", "price": 30, "energy": 30, "wait": 1.8, "difficulty": 0.18, "treasure_chance": 0.18},
	"catfish": {"name": "鲶鱼", "habitat": "river", "seasons": [0, 1, 2], "hours": [6, 24], "weather": "雨", "price": 85, "energy": 38, "wait": 1.5, "difficulty": 0.52, "treasure_chance": 0.28},
	"night_eel": {"name": "夜鳗", "habitat": "river", "seasons": [1, 2], "hours": [18, 24], "weather": "any", "price": 95, "energy": 40, "wait": 2.2, "difficulty": 0.68, "treasure_chance": 0.30},
	"sardine": {"name": "沙丁鱼", "habitat": "ocean", "seasons": [0, 1, 2, 3], "hours": [6, 19], "weather": "any", "price": 40, "energy": 28, "wait": 1.7, "difficulty": 0.28, "treasure_chance": 0.20},
	"flounder": {"name": "比目鱼", "habitat": "ocean", "seasons": [0, 1], "hours": [6, 20], "weather": "晴", "price": 65, "energy": 34, "wait": 2.0, "difficulty": 0.38, "treasure_chance": 0.23},
	"red_snapper": {"name": "红鲷", "habitat": "ocean", "seasons": [1, 2], "hours": [6, 19], "weather": "雨", "price": 100, "energy": 42, "wait": 1.4, "difficulty": 0.68, "treasure_chance": 0.32},
	"squid": {"name": "鱿鱼", "habitat": "ocean", "seasons": [3], "hours": [18, 24], "weather": "any", "price": 110, "energy": 45, "wait": 2.4, "difficulty": 0.78, "treasure_chance": 0.34},
	"tuna": {"name": "金枪鱼", "habitat": "ocean", "seasons": [1, 3], "hours": [6, 19], "weather": "晴", "price": 120, "energy": 45, "wait": 2.1, "difficulty": 0.88, "treasure_chance": 0.38},
}
const TREASURE_LOOT := [
	{"material": "copper_ore", "amount": 2}, {"material": "iron_ore", "amount": 1},
	{"material": "coal", "amount": 2}, {"material": "quartz", "amount": 1},
	{"material": "earth_crystal", "amount": 1}, {"material": "amethyst", "amount": 1},
	{"material": "frozen_tear", "amount": 1}, {"material": "fire_quartz", "amount": 1},
]
const RODS := [
	{"id": "bamboo", "name": "竹竿", "price": 0, "skill_level": 0, "bait_slot": false, "tackle_slots": 0},
	{"id": "fiberglass", "name": "玻璃纤维鱼竿", "price": 1800, "skill_level": 2, "bait_slot": true, "tackle_slots": 0},
	{"id": "iridium", "name": "铱金鱼竿", "price": 7500, "skill_level": 6, "bait_slot": true, "tackle_slots": 1},
]
const TACKLES := {"cork_bobber": {"name": "软木浮标", "price": 750, "skill_level": 7, "bar_bonus": 0.05}}

var inventory: Dictionary = {}
var caught: Dictionary = {}
var cast_serial := 0
var treasure_chests := 0
var rod_level := 0
var bait_count := 0
var cork_bobber_owned := false
var cork_bobber_equipped := false

func rod() -> Dictionary:
	return RODS[clampi(rod_level, 0, RODS.size() - 1)]

func next_rod() -> Dictionary:
	var next_level := rod_level + 1
	return RODS[next_level] if next_level < RODS.size() else {}

func upgrade_rod(farm, fishing_level: int) -> Dictionary:
	var next := next_rod()
	if next.is_empty(): return {"ok": false, "reason": "max", "message": "鱼竿已经是最高级。"}
	if fishing_level < int(next.skill_level):
		return {"ok": false, "reason": "skill", "message": "钓鱼达到%d级后才能购买%s。" % [int(next.skill_level), str(next.name)]}
	if farm.gold < int(next.price):
		return {"ok": false, "reason": "gold", "message": "金币不足，鱼竿没有购买成功。"}
	farm.gold -= int(next.price)
	rod_level += 1
	return {"ok": true, "rod": rod(), "message": "已换上%s，解锁%s。" % [str(next.name), "鱼饵槽和浮标槽" if int(next.tackle_slots) > 0 else "鱼饵槽" if bool(next.bait_slot) else "基础钓鱼" ]}

func buy_bait(farm, amount: int = 10) -> Dictionary:
	if not bool(rod().bait_slot): return {"ok": false, "message": "需要玻璃纤维鱼竿或更高级鱼竿才能装鱼饵。"}
	if amount <= 0: return {"ok": false, "message": "鱼饵数量无效。"}
	var cost := amount * 5
	if farm.gold < cost: return {"ok": false, "message": "金币不足，鱼饵没有购买成功。"}
	farm.gold -= cost
	bait_count += amount
	return {"ok": true, "amount": amount, "message": "购买了鱼饵 ×%d。每次抛竿会消耗1份并缩短等待时间。" % amount}

func use_bait() -> bool:
	if not bool(rod().bait_slot) or bait_count <= 0: return false
	bait_count -= 1
	return true

func buy_cork_bobber(farm, fishing_level: int) -> Dictionary:
	if int(rod().tackle_slots) <= 0: return {"ok": false, "message": "需要铱金鱼竿才能安装浮标。"}
	if fishing_level < int(TACKLES.cork_bobber.skill_level): return {"ok": false, "message": "钓鱼达到%d级后才能购买软木浮标。" % int(TACKLES.cork_bobber.skill_level)}
	if cork_bobber_owned:
		cork_bobber_equipped = true
		return {"ok": true, "message": "软木浮标已装到铱金鱼竿上。"}
	if farm.gold < int(TACKLES.cork_bobber.price): return {"ok": false, "message": "金币不足，软木浮标没有购买成功。"}
	farm.gold -= int(TACKLES.cork_bobber.price)
	cork_bobber_owned = true
	cork_bobber_equipped = true
	return {"ok": true, "message": "购买并安装了软木浮标，追鱼操作条加宽5%。"}

func eligible(map_id: String, day: int, minutes: int, weather: String) -> Array[String]:
	var habitat := "ocean" if map_id == "beach" else "river"
	var season := int(Calendar.date(day).season)
	var hour := minutes / 60
	var result: Array[String] = []
	for id in DEFINITIONS:
		var fish: Dictionary = DEFINITIONS[id]
		if fish.habitat != habitat or season not in fish.seasons: continue
		if hour < int(fish.hours[0]) or hour >= int(fish.hours[1]): continue
		if fish.weather != "any" and fish.weather != weather: continue
		result.append(id)
	if result.is_empty(): result.append("sardine" if habitat == "ocean" else "creek_fish")
	result.sort()
	return result

func prepare(map_id: String, day: int, minutes: int, weather: String) -> Dictionary:
	var choices := eligible(map_id, day, minutes, weather)
	var id: String = choices[posmod(day * 13 + minutes / 10 + cast_serial * 7, choices.size())]
	cast_serial += 1
	var result: Dictionary = DEFINITIONS[id].duplicate(true)
	result["id"] = id
	result["cast_id"] = cast_serial
	return result

func claim_treasure(cast_id: int, fish_id: String) -> Dictionary:
	if not DEFINITIONS.has(fish_id) or cast_id <= 0: return {}
	var loot_index := posmod(cast_id * 7 + fish_id.hash(), TREASURE_LOOT.size())
	var reward: Dictionary = TREASURE_LOOT[loot_index].duplicate(true)
	treasure_chests += 1
	reward["chests_opened"] = treasure_chests
	return reward

func catch_fish(id: String) -> bool:
	if not DEFINITIONS.has(id): return false
	inventory[id] = int(inventory.get(id, 0)) + 1
	caught[id] = int(caught.get(id, 0)) + 1
	return true

func consume(id: String) -> bool:
	if int(inventory.get(id, 0)) <= 0: return false
	inventory[id] -= 1
	return true

func total_count() -> int:
	var total := 0
	for amount in inventory.values(): total += int(amount)
	return total

func total_caught() -> int:
	var total := 0
	for amount in caught.values(): total += int(amount)
	return total

func set_legacy_count(amount: int) -> void:
	inventory.clear()
	if amount > 0: inventory["creek_fish"] = amount

func ship() -> int:
	var earned := 0
	for id in inventory:
		earned += int(inventory[id]) * int(DEFINITIONS[id].price)
		inventory[id] = 0
	return earned

func snapshot() -> Dictionary:
	return {"inventory": inventory.duplicate(), "caught": caught.duplicate(), "cast_serial": cast_serial, "treasure_chests": treasure_chests, "rod_level": rod_level, "bait_count": bait_count, "cork_bobber_owned": cork_bobber_owned, "cork_bobber_equipped": cork_bobber_equipped}

func restore(data: Dictionary) -> void:
	inventory.clear()
	caught.clear()
	for id in DEFINITIONS:
		var amount := maxi(0, int(data.get("inventory", {}).get(id, 0)))
		if amount > 0: inventory[id] = amount
		var record := maxi(0, int(data.get("caught", {}).get(id, 0)))
		if record > 0: caught[id] = record
	cast_serial = maxi(0, int(data.get("cast_serial", 0)))
	treasure_chests = maxi(0, int(data.get("treasure_chests", 0)))
	rod_level = clampi(int(data.get("rod_level", 0)), 0, RODS.size() - 1)
	bait_count = maxi(0, int(data.get("bait_count", 0)))
	cork_bobber_owned = bool(data.get("cork_bobber_owned", false))
	cork_bobber_equipped = bool(data.get("cork_bobber_equipped", false)) and cork_bobber_owned and int(rod().tackle_slots) > 0

static func valid(data) -> bool:
	if not data is Dictionary: return false
	if data.has("cast_serial") and ((not data.cast_serial is int and not data.cast_serial is float) or not is_finite(float(data.cast_serial)) or float(data.cast_serial) < 0): return false
	if data.has("treasure_chests") and ((not data.treasure_chests is int and not data.treasure_chests is float) or not is_finite(float(data.treasure_chests)) or float(data.treasure_chests) < 0 or floorf(float(data.treasure_chests)) != float(data.treasure_chests)): return false
	if data.has("rod_level") and ((not data.rod_level is int and not data.rod_level is float) or not is_finite(float(data.rod_level)) or float(data.rod_level) < 0 or floorf(float(data.rod_level)) != float(data.rod_level) or int(data.rod_level) >= RODS.size()): return false
	if data.has("bait_count") and ((not data.bait_count is int and not data.bait_count is float) or not is_finite(float(data.bait_count)) or float(data.bait_count) < 0 or floorf(float(data.bait_count)) != float(data.bait_count)): return false
	if data.has("cork_bobber_owned") and not data.cork_bobber_owned is bool: return false
	if data.has("cork_bobber_equipped") and not data.cork_bobber_equipped is bool: return false
	if bool(data.get("cork_bobber_equipped", false)) and not bool(data.get("cork_bobber_owned", false)): return false
	for field in ["inventory", "caught"]:
		if not data.get(field, {}) is Dictionary: return false
		for id in data.get(field, {}):
			var amount = data[field][id]
			if not DEFINITIONS.has(id) or (not amount is int and not amount is float) or not is_finite(float(amount)) or float(amount) < 0: return false
	return true
