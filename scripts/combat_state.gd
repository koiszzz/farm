class_name CombatState
extends RefCounted

const MAX_HEALTH := 100
const DEFINITIONS := {
	"slime": {"name": "苔绿史莱姆", "health": 3, "damage": 8, "speed": 24.0, "xp": 18},
	"bat": {"name": "岩洞蝠", "health": 2, "damage": 6, "speed": 38.0, "xp": 22},
}
const SPAWN_CELLS := [Vector2i(3, 5), Vector2i(18, 9), Vector2i(31, 6), Vector2i(4, 20), Vector2i(18, 18), Vector2i(31, 20), Vector2i(12, 14), Vector2i(22, 23), Vector2i(33, 24), Vector2i(3, 24)]

var day := 0
var health := MAX_HEALTH
var monsters: Dictionary = {}
var defeated: Dictionary = {}
var generated_maps: Dictionary = {}


func sync_day(value: int) -> void:
	if day == value: return
	day = value
	monsters.clear()
	defeated.clear()
	generated_maps.clear()


func ensure_map(map_id: String, current_day: int) -> Array[Dictionary]:
	sync_day(current_day)
	if not generated_maps.has(map_id):
		generated_maps[map_id] = true
		var floor := 1 if map_id == "cave" else 2 if map_id == "mine_2" else 3
		var count := 2 + floor
		var used := {}
		for index in count:
			var seed := absi((map_id + ":" + str(day)).hash()) + index * 37
			var pool_index := posmod(seed, SPAWN_CELLS.size())
			while used.has(pool_index): pool_index = posmod(pool_index + 3, SPAWN_CELLS.size())
			used[pool_index] = true
			var cell: Vector2i = SPAWN_CELLS[pool_index]
			var type := "slime" if floor == 1 or (index + day) % 2 == 0 else "bat"
			var id := "%s:%d:%d" % [map_id, day, index]
			if defeated.has(id): continue
			monsters[id] = {"id": id, "map": map_id, "type": type, "x": cell.x, "y": cell.y, "health": int(DEFINITIONS[type].health), "max_health": int(DEFINITIONS[type].health)}
	var result: Array[Dictionary] = []
	for value in monsters.values():
		if str(value.map) == map_id: result.append(value.duplicate(true))
	return result


func monster(id: String) -> Dictionary:
	var value = monsters.get(id, {})
	return value.duplicate(true) if value is Dictionary else {}


func update_position(id: String, cell: Vector2i) -> void:
	if not monsters.has(id): return
	var value: Dictionary = monsters[id]
	value.x = cell.x
	value.y = cell.y
	monsters[id] = value


func strike(id: String, damage: int) -> Dictionary:
	if not monsters.has(id) or damage <= 0: return {"ok": false}
	var value: Dictionary = monsters[id]
	value.health = maxi(0, int(value.health) - damage)
	if int(value.health) > 0:
		monsters[id] = value
		return {"ok": true, "defeated": false, "health": value.health, "max_health": value.max_health, "type": value.type}
	monsters.erase(id)
	defeated[id] = true
	var drop := _drop_for(value)
	return {"ok": true, "defeated": true, "type": value.type, "xp": int(DEFINITIONS[str(value.type)].xp), "drop": drop.kind, "amount": drop.amount}


func take_damage(amount: int) -> Dictionary:
	var applied := mini(health, maxi(0, amount))
	health -= applied
	return {"damage": applied, "health": health, "fainted": health <= 0}


func heal_full() -> void:
	health = MAX_HEALTH


func snapshot() -> Dictionary:
	var rows: Array = []
	for value in monsters.values(): rows.append(value.duplicate(true))
	return {"day": day, "health": health, "monsters": rows, "defeated": defeated.duplicate(), "generated_maps": generated_maps.duplicate()}


func restore(data: Dictionary) -> void:
	day = maxi(0, int(data.get("day", 0)))
	health = clampi(int(data.get("health", MAX_HEALTH)), 0, MAX_HEALTH)
	defeated = data.get("defeated", {}).duplicate()
	generated_maps = data.get("generated_maps", {}).duplicate()
	monsters.clear()
	for value in data.get("monsters", []):
		if value is Dictionary: monsters[str(value.id)] = value.duplicate(true)


static func valid(data) -> bool:
	if not data is Dictionary: return false
	for key in ["day", "health"]:
		if data.has(key) and (not _number(data[key]) or float(data[key]) < 0): return false
	if data.has("health") and int(data.health) > MAX_HEALTH: return false
	var rows = data.get("monsters", [])
	if not rows is Array or not data.get("defeated", {}) is Dictionary or not data.get("generated_maps", {}) is Dictionary: return false
	var ids := {}
	for value in rows:
		if not value is Dictionary or not value.has_all(["id", "map", "type", "x", "y", "health", "max_health"]): return false
		if not value.id is String or value.id.is_empty() or ids.has(value.id) or str(value.map) not in ["cave", "mine_2", "mine_3"] or not DEFINITIONS.has(str(value.type)): return false
		ids[value.id] = true
		for key in ["x", "y", "health", "max_health"]:
			if not _number(value[key]) or float(value[key]) < 0: return false
		if int(value.health) > int(value.max_health) or int(value.max_health) != int(DEFINITIONS[str(value.type)].health): return false
	for id in data.get("defeated", {}):
		if not id is String or not data.defeated[id] is bool: return false
	for map_id in data.get("generated_maps", {}):
		if str(map_id) not in ["cave", "mine_2", "mine_3"] or not data.generated_maps[map_id] is bool: return false
	return true


func _drop_for(value: Dictionary) -> Dictionary:
	if str(value.type) == "slime": return {"kind": "stone", "amount": 2}
	if str(value.map) == "mine_3" and posmod(str(value.id).hash(), 2) == 0: return {"kind": "quartz", "amount": 1}
	return {"kind": "coal", "amount": 1}


static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
