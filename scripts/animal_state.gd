class_name AnimalState
extends RefCounted

const COOP_COST := {"gold": 300, "wood": 12, "stone": 6}
const CHICKEN_PRICE := 180
const DUCK_PRICE := 260
const HAY_PRICE := 8
const EGG_PRICE := 55
const DUCK_EGG_PRICE := 95
const DUCK_EGG_ENERGY := 18
const CAPACITY := 4
const COOP_RECT := Rect2i(Vector2i(48, 22), Vector2i(7, 4))
const PEN_RECT := Rect2i(Vector2i(47, 26), Vector2i(9, 7))
const COOP_INTERACTION_CELL := Vector2i(51, 26)
const GATE_CELLS := [Vector2i(50, 32), Vector2i(51, 32)]
const CHICKEN_NAMES := ["小满", "团子", "米粒", "栗子"]
const DUCK_NAMES := ["阿黄", "泡泡", "小浪", "麦芽"]
const BARN_COST := {"gold": 650, "wood": 20, "stone": 12}
const COW_PRICE := 560
const MILK_PRICE := 125
const MILK_ENERGY := 22
const BARN_CAPACITY := 2
const BARN_RECT := Rect2i(Vector2i(50, 34), Vector2i(8, 4))
const BARN_PEN_RECT := Rect2i(Vector2i(49, 38), Vector2i(10, 5))
const BARN_INTERACTION_CELL := Vector2i(53, 38)
const BARN_GATE_CELLS := [Vector2i(53, 42), Vector2i(54, 42)]
const COW_NAMES := ["花花", "奶糖"]

var coop_built := false
var barn_built := false
var chickens: Array[Dictionary] = []
var ducks: Array[Dictionary] = []
var cows: Array[Dictionary] = []
var hay := 0
var nest_eggs := 0
var eggs := 0
var duck_nest_eggs := 0
var duck_eggs := 0
var milk := 0
var next_id := 1
var _structure_cache: Array[Vector2i] = []
var _barn_structure_cache: Array[Vector2i] = []
var _roam_cache: Array[Vector2i] = []
var _barn_roam_cache: Array[Vector2i] = []
var _empty_cells: Array[Vector2i] = []


func build_coop(farm, resources: Dictionary) -> Dictionary:
	if coop_built: return _failure("鸡舍已经建好了。")
	if farm.gold < COOP_COST.gold or int(resources.get("wood", 0)) < COOP_COST.wood or int(resources.get("stone", 0)) < COOP_COST.stone:
		return _failure("需要%d金币、木材%d、石料%d；材料不足时不会扣除。" % [COOP_COST.gold, COOP_COST.wood, COOP_COST.stone])
	farm.gold -= COOP_COST.gold
	resources.wood -= COOP_COST.wood
	resources.stone -= COOP_COST.stone
	coop_built = true
	return {"ok": true, "message": "杉月完成了鸡舍和围栏，最多可饲养%d只鸡。" % CAPACITY}


func buy_chicken(farm) -> Dictionary:
	if not coop_built: return _failure("先建造鸡舍，才能领养小鸡。")
	if chickens.size() + ducks.size() >= CAPACITY: return _failure("鸡舍已经住满了。")
	if farm.gold < CHICKEN_PRICE: return _failure("购买小鸡需要%d金币。" % CHICKEN_PRICE)
	farm.gold -= CHICKEN_PRICE
	var index := chickens.size()
	var chicken := {"id": "chicken_%d" % next_id, "name": CHICKEN_NAMES[index], "age": 0, "affection": 0, "petted_day": 0, "fed_day": 0}
	next_id += 1
	chickens.append(chicken)
	return {"ok": true, "id": chicken.id, "name": chicken.name, "message": "%s搬进了鸡舍。每天喂食和抚摸，成年后会产蛋。" % chicken.name}


func buy_duck(farm) -> Dictionary:
	if not coop_built: return _failure("先建造鸡舍，才能领养小鸭。")
	if chickens.size() + ducks.size() >= CAPACITY: return _failure("鸡舍最多住四只家禽，请先扩建。")
	if farm.gold < DUCK_PRICE: return _failure("购买小鸭需要%d金币。" % DUCK_PRICE)
	farm.gold -= DUCK_PRICE
	var index := ducks.size()
	var duck := {"id": "duck_%d" % next_id, "name": DUCK_NAMES[index % DUCK_NAMES.size()], "age": 0, "affection": 0, "petted_day": 0, "fed_day": 0}
	next_id += 1
	ducks.append(duck)
	return {"ok": true, "id": duck.id, "name": duck.name, "message": "%s搬进了鸡舍。喂养长大后会在巢箱留下鸭蛋。" % duck.name}


func build_barn(farm, resources: Dictionary) -> Dictionary:
	if barn_built: return _failure("牛棚已经建好了。")
	if farm.gold < BARN_COST.gold or int(resources.get("wood", 0)) < BARN_COST.wood or int(resources.get("stone", 0)) < BARN_COST.stone:
		return _failure("需要%d金币、木材%d、石料%d；材料不足时不会扣除。" % [BARN_COST.gold, BARN_COST.wood, BARN_COST.stone])
	farm.gold -= BARN_COST.gold
	resources.wood -= BARN_COST.wood
	resources.stone -= BARN_COST.stone
	barn_built = true
	return {"ok": true, "message": "杉月完成了牛棚和围栏，最多可饲养%d头奶牛。" % BARN_CAPACITY}


func buy_cow(farm) -> Dictionary:
	if not barn_built: return _failure("先建造牛棚，才能领养奶牛。")
	if cows.size() >= BARN_CAPACITY: return _failure("牛棚已经住满了。")
	if farm.gold < COW_PRICE: return _failure("购买奶牛需要%d金币。" % COW_PRICE)
	farm.gold -= COW_PRICE
	var index := cows.size()
	var cow := {"id": "cow_%d" % next_id, "name": COW_NAMES[index], "age": 0, "affection": 0, "petted_day": 0, "fed_day": 0, "milked_day": 0}
	next_id += 1
	cows.append(cow)
	return {"ok": true, "id": cow.id, "name": cow.name, "message": "%s搬进了牛棚。每天喂食和抚摸，成年后可以挤奶。" % cow.name}


func cow(id: String) -> Dictionary:
	for entry in cows:
		if str(entry.id) == id: return entry.duplicate(true)
	return {}


func duck(id: String) -> Dictionary:
	for entry in ducks:
		if str(entry.id) == id: return entry.duplicate(true)
	return {}


func pet_duck(id: String, day: int) -> Dictionary:
	var index := _duck_index_of(id)
	if index < 0: return _failure("没有找到这只鸭子。")
	var entry: Dictionary = ducks[index]
	if int(entry.petted_day) == day: return _failure("%s今天已经被抚摸过了。" % entry.name)
	entry.petted_day = day
	entry.affection = mini(1000, int(entry.affection) + 20)
	ducks[index] = entry
	return {"ok": true, "message": "%s摇摇尾巴，亲密度 +20。" % entry.name}


func feed_duck(id: String, day: int) -> Dictionary:
	var index := _duck_index_of(id)
	if index < 0: return _failure("没有找到这只鸭子。")
	var entry: Dictionary = ducks[index]
	if int(entry.fed_day) == day: return _failure("%s今天已经吃饱了。" % entry.name)
	if hay <= 0: return _failure("干草用完了，可以在种子铺购买。")
	hay -= 1
	entry.fed_day = day
	ducks[index] = entry
	return {"ok": true, "message": "给%s添了一份干草，剩余%d份。" % [entry.name, hay]}


func feed_all_ducks(day: int) -> Dictionary:
	var hungry: Array[String] = []
	for entry in ducks:
		if int(entry.fed_day) != day: hungry.append(str(entry.id))
	if hungry.is_empty(): return _failure("鸡舍里的鸭子今天都已经吃饱了。")
	if hay < hungry.size(): return _failure("需要%d份干草，当前只有%d份；没有扣除。" % [hungry.size(), hay])
	for id in hungry: feed_duck(id, day)
	return {"ok": true, "amount": hungry.size(), "message": "给%d只鸭子添好了干草，剩余%d份。" % [hungry.size(), hay]}


func feed_cow(id: String, day: int) -> Dictionary:
	var index := _cow_index_of(id)
	if index < 0: return _failure("没有找到这头牛。")
	var entry: Dictionary = cows[index]
	if int(entry.fed_day) == day: return _failure("%s今天已经吃饱了。" % entry.name)
	if hay <= 0: return _failure("干草用完了，可以在种子铺购买。")
	hay -= 1
	entry.fed_day = day
	cows[index] = entry
	return {"ok": true, "message": "给%s添了一份干草，剩余%d份。" % [entry.name, hay]}


func pet_cow(id: String, day: int) -> Dictionary:
	var index := _cow_index_of(id)
	if index < 0: return _failure("没有找到这头牛。")
	var entry: Dictionary = cows[index]
	if int(entry.petted_day) == day: return _failure("%s今天已经被抚摸过了。" % entry.name)
	entry.petted_day = day
	entry.affection = mini(1000, int(entry.affection) + 20)
	cows[index] = entry
	return {"ok": true, "message": "%s满足地蹭了蹭你，亲密度 +20。" % entry.name}


func feed_all_cows(day: int) -> Dictionary:
	var hungry: Array[String] = []
	for entry in cows:
		if int(entry.fed_day) != day: hungry.append(str(entry.id))
	if hungry.is_empty(): return _failure("牛棚里的奶牛今天都已经吃饱了。")
	if hay < hungry.size(): return _failure("需要%d份干草，当前只有%d份；没有扣除。" % [hungry.size(), hay])
	for id in hungry: feed_cow(id, day)
	return {"ok": true, "amount": hungry.size(), "message": "给%d头奶牛添好了干草，剩余%d份。" % [hungry.size(), hay]}


func milk_cow(id: String, day: int) -> Dictionary:
	var index := _cow_index_of(id)
	if index < 0: return _failure("没有找到这头牛。")
	var entry: Dictionary = cows[index]
	if int(entry.age) < 1: return _failure("%s还是小牛，长大并吃饱后才会有奶。" % entry.name)
	if int(entry.milked_day) == day: return _failure("%s今天已经挤过奶了。" % entry.name)
	if int(entry.fed_day) != day - 1 and int(entry.fed_day) != day: return _failure("%s昨天没有吃饱，今天没有奶。" % entry.name)
	entry.milked_day = day
	milk += 1
	cows[index] = entry
	return {"ok": true, "message": "从%s挤到一桶新鲜牛奶，已放入背包。" % entry.name}


func consume_milk() -> bool:
	if milk <= 0: return false
	milk -= 1
	return true


func cow_advance_day(departing_day: int) -> Dictionary:
	for index in cows.size():
		var entry: Dictionary = cows[index]
		var fed: bool = int(entry.fed_day) == departing_day
		var petted: bool = int(entry.petted_day) == departing_day
		if fed and petted: entry.affection = mini(1000, int(entry.affection) + 10)
		elif not fed: entry.affection = maxi(0, int(entry.affection) - 15)
		entry.age = int(entry.age) + 1
		cows[index] = entry
	return {"cows": cows.size()}


func barn_structure_cells() -> Array[Vector2i]:
	if not barn_built: return _empty_cells
	if not _barn_structure_cache.is_empty(): return _barn_structure_cache
	for y in range(BARN_RECT.position.y, BARN_RECT.end.y):
		for x in range(BARN_RECT.position.x, BARN_RECT.end.x): _barn_structure_cache.append(Vector2i(x, y))
	for y in range(BARN_PEN_RECT.position.y, BARN_PEN_RECT.end.y):
		for x in range(BARN_PEN_RECT.position.x, BARN_PEN_RECT.end.x):
			var cell := Vector2i(x, y)
			var border := x == BARN_PEN_RECT.position.x or x == BARN_PEN_RECT.end.x - 1 or y == BARN_PEN_RECT.end.y - 1
			if border and cell not in BARN_GATE_CELLS and cell not in _barn_structure_cache: _barn_structure_cache.append(cell)
	return _barn_structure_cache


func barn_is_solid(cell: Vector2i) -> bool:
	if not barn_built: return false
	if BARN_RECT.has_point(cell): return true
	if not BARN_PEN_RECT.has_point(cell) or cell in BARN_GATE_CELLS: return false
	return cell.x == BARN_PEN_RECT.position.x or cell.x == BARN_PEN_RECT.end.x - 1 or cell.y == BARN_PEN_RECT.end.y - 1


func barn_roam_cells() -> Array[Vector2i]:
	if not barn_built: return _empty_cells
	if not _barn_roam_cache.is_empty(): return _barn_roam_cache
	for y in range(BARN_PEN_RECT.position.y + 1, BARN_PEN_RECT.end.y - 1):
		for x in range(BARN_PEN_RECT.position.x + 1, BARN_PEN_RECT.end.x - 1): _barn_roam_cache.append(Vector2i(x, y))
	return _barn_roam_cache


func _cow_index_of(id: String) -> int:
	for index in cows.size():
		if str(cows[index].id) == id: return index
	return -1


func buy_hay(farm, amount := 5) -> Dictionary:
	if amount <= 0: return _failure("购买数量无效。")
	var cost := amount * HAY_PRICE
	if farm.gold < cost: return _failure("购买干草需要%d金币。" % cost)
	farm.gold -= cost
	hay += amount
	return {"ok": true, "amount": amount, "cost": cost, "message": "购买干草×%d，现有%d份。" % [amount, hay]}


func chicken(id: String) -> Dictionary:
	for entry in chickens:
		if str(entry.id) == id: return entry.duplicate(true)
	return {}


func pet(id: String, day: int) -> Dictionary:
	var index := _index_of(id)
	if index < 0: return _failure("没有找到这只鸡。")
	var entry: Dictionary = chickens[index]
	if int(entry.petted_day) == day: return _failure("%s今天已经被抚摸过了。" % entry.name)
	entry.petted_day = day
	entry.affection = mini(1000, int(entry.affection) + 20)
	chickens[index] = entry
	return {"ok": true, "message": "%s开心地贴近你，亲密度 +20。" % entry.name}


func feed(id: String, day: int) -> Dictionary:
	var index := _index_of(id)
	if index < 0: return _failure("没有找到这只鸡。")
	var entry: Dictionary = chickens[index]
	if int(entry.fed_day) == day: return _failure("%s今天已经吃饱了。" % entry.name)
	if hay <= 0: return _failure("干草用完了，可以在种子铺购买。")
	hay -= 1
	entry.fed_day = day
	chickens[index] = entry
	return {"ok": true, "message": "给%s添了一份干草，剩余%d份。" % [entry.name, hay]}


func feed_all(day: int) -> Dictionary:
	var hungry: Array[String] = []
	for entry in chickens:
		if int(entry.fed_day) != day: hungry.append(str(entry.id))
	if hungry.is_empty(): return _failure("鸡舍里的鸡今天都已经吃饱了。")
	if hay < hungry.size(): return _failure("需要%d份干草，当前只有%d份；没有扣除。" % [hungry.size(), hay])
	for id in hungry: feed(id, day)
	return {"ok": true, "amount": hungry.size(), "message": "给%d只鸡添好了干草，剩余%d份。" % [hungry.size(), hay]}


func advance_day(departing_day: int) -> Dictionary:
	var produced := 0
	for index in chickens.size():
		var entry: Dictionary = chickens[index]
		var fed: bool = int(entry.fed_day) == departing_day
		var petted: bool = int(entry.petted_day) == departing_day
		if fed and int(entry.age) >= 1:
			produced += 1
		if fed and petted: entry.affection = mini(1000, int(entry.affection) + 10)
		elif not fed: entry.affection = maxi(0, int(entry.affection) - 15)
		entry.age = int(entry.age) + 1
		chickens[index] = entry
	var produced_duck_eggs := 0
	for index in ducks.size():
		var entry: Dictionary = ducks[index]
		var fed: bool = int(entry.fed_day) == departing_day
		var petted: bool = int(entry.petted_day) == departing_day
		if fed and int(entry.age) >= 1: produced_duck_eggs += 1
		if fed and petted: entry.affection = mini(1000, int(entry.affection) + 10)
		elif not fed: entry.affection = maxi(0, int(entry.affection) - 15)
		entry.age = int(entry.age) + 1
		ducks[index] = entry
	nest_eggs += produced
	duck_nest_eggs += produced_duck_eggs
	cow_advance_day(departing_day)
	return {"produced": produced, "duck_produced": produced_duck_eggs, "nest_eggs": nest_eggs, "duck_nest_eggs": duck_nest_eggs}


func collect_eggs() -> Dictionary:
	if nest_eggs <= 0: return _failure("巢箱里暂时没有鸡蛋。")
	var amount := nest_eggs
	nest_eggs = 0
	eggs += amount
	return {"ok": true, "amount": amount, "message": "从巢箱收取鸡蛋×%d，已放入背包。" % amount}


func consume_egg() -> bool:
	if eggs <= 0: return false
	eggs -= 1
	return true


func collect_duck_eggs() -> Dictionary:
	if duck_nest_eggs <= 0: return _failure("巢箱里暂时没有鸭蛋。")
	var amount := duck_nest_eggs
	duck_nest_eggs = 0
	duck_eggs += amount
	return {"ok": true, "amount": amount, "message": "从巢箱收取鸭蛋×%d，已放入背包。" % amount}


func consume_duck_egg() -> bool:
	if duck_eggs <= 0: return false
	duck_eggs -= 1
	return true


func ship(farm) -> int:
	var earned := eggs * EGG_PRICE + duck_eggs * DUCK_EGG_PRICE + milk * MILK_PRICE
	eggs = 0
	duck_eggs = 0
	milk = 0
	farm.gold += earned
	return earned


func structure_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	cells.append_array(_coop_structure_cells())
	cells.append_array(barn_structure_cells())
	return cells


func _coop_structure_cells() -> Array[Vector2i]:
	if not coop_built: return _empty_cells
	if not _structure_cache.is_empty(): return _structure_cache
	for y in range(COOP_RECT.position.y, COOP_RECT.end.y):
		for x in range(COOP_RECT.position.x, COOP_RECT.end.x): _structure_cache.append(Vector2i(x, y))
	for y in range(PEN_RECT.position.y, PEN_RECT.end.y):
		for x in range(PEN_RECT.position.x, PEN_RECT.end.x):
			var cell := Vector2i(x, y)
			var border := x == PEN_RECT.position.x or x == PEN_RECT.end.x - 1 or y == PEN_RECT.end.y - 1
			if border and cell not in GATE_CELLS and cell not in _structure_cache: _structure_cache.append(cell)
	return _structure_cache


func is_solid(cell: Vector2i) -> bool:
	return _coop_is_solid(cell) or barn_is_solid(cell)


func _coop_is_solid(cell: Vector2i) -> bool:
	if not coop_built: return false
	if COOP_RECT.has_point(cell): return true
	if not PEN_RECT.has_point(cell) or cell in GATE_CELLS: return false
	return cell.x == PEN_RECT.position.x or cell.x == PEN_RECT.end.x - 1 or cell.y == PEN_RECT.end.y - 1


func roam_cells() -> Array[Vector2i]:
	if not coop_built: return _empty_cells
	if not _roam_cache.is_empty(): return _roam_cache
	for y in range(PEN_RECT.position.y + 1, PEN_RECT.end.y - 1):
		for x in range(PEN_RECT.position.x + 1, PEN_RECT.end.x - 1): _roam_cache.append(Vector2i(x, y))
	return _roam_cache


func snapshot() -> Dictionary:
	return {"coop_built": coop_built, "barn_built": barn_built, "chickens": chickens.duplicate(true), "ducks": ducks.duplicate(true), "cows": cows.duplicate(true), "hay": hay, "nest_eggs": nest_eggs, "eggs": eggs, "duck_nest_eggs": duck_nest_eggs, "duck_eggs": duck_eggs, "milk": milk, "next_id": next_id}


func restore(data: Dictionary) -> void:
	coop_built = bool(data.get("coop_built", false))
	barn_built = bool(data.get("barn_built", false))
	hay = maxi(0, int(data.get("hay", 0)))
	nest_eggs = maxi(0, int(data.get("nest_eggs", 0)))
	eggs = maxi(0, int(data.get("eggs", 0)))
	duck_nest_eggs = maxi(0, int(data.get("duck_nest_eggs", 0)))
	duck_eggs = maxi(0, int(data.get("duck_eggs", 0)))
	milk = maxi(0, int(data.get("milk", 0)))
	next_id = maxi(1, int(data.get("next_id", 1)))
	chickens.clear()
	for value in data.get("chickens", []):
		if value is Dictionary and chickens.size() < CAPACITY: chickens.append(value.duplicate(true))
	ducks.clear()
	for value in data.get("ducks", []):
		if value is Dictionary and chickens.size() + ducks.size() < CAPACITY: ducks.append(value.duplicate(true))
	cows.clear()
	for value in data.get("cows", []):
		if value is Dictionary and cows.size() < BARN_CAPACITY: cows.append(value.duplicate(true))


static func valid(data) -> bool:
	if not data is Dictionary: return false
	for flag in ["coop_built", "barn_built"]:
		if data.has(flag) and not data[flag] is bool: return false
	for key in ["hay", "nest_eggs", "eggs", "duck_nest_eggs", "duck_eggs", "milk", "next_id"]:
		if data.has(key) and not _valid_number(data[key], 0): return false
	var saved_chickens = data.get("chickens", [])
	if not saved_chickens is Array or saved_chickens.size() > CAPACITY: return false
	var saved_ducks = data.get("ducks", [])
	if not saved_ducks is Array or saved_ducks.size() + saved_chickens.size() > CAPACITY: return false
	var ids := {}
	for entry in saved_chickens:
		if not entry is Dictionary or not entry.has_all(["id", "name", "age", "affection", "petted_day", "fed_day"]): return false
		if not entry.id is String or entry.id.is_empty() or ids.has(entry.id) or not entry.name is String: return false
		ids[entry.id] = true
		for key in ["age", "affection", "petted_day", "fed_day"]:
			if not _valid_number(entry[key], 0): return false
		if int(entry.affection) > 1000: return false
	for entry in saved_ducks:
		if not entry is Dictionary or not entry.has_all(["id", "name", "age", "affection", "petted_day", "fed_day"]): return false
		if not entry.id is String or entry.id.is_empty() or ids.has(entry.id) or not entry.name is String: return false
		ids[entry.id] = true
		for key in ["age", "affection", "petted_day", "fed_day"]:
			if not _valid_number(entry[key], 0): return false
		if int(entry.affection) > 1000: return false
	var saved_cows = data.get("cows", [])
	if not saved_cows is Array or saved_cows.size() > BARN_CAPACITY: return false
	for entry in saved_cows:
		if not entry is Dictionary or not entry.has_all(["id", "name", "age", "affection", "petted_day", "fed_day", "milked_day"]): return false
		if not entry.id is String or entry.id.is_empty() or ids.has(entry.id) or not entry.name is String: return false
		ids[entry.id] = true
		for key in ["age", "affection", "petted_day", "fed_day", "milked_day"]:
			if not _valid_number(entry[key], 0): return false
		if int(entry.affection) > 1000: return false
	if not bool(data.get("coop_built", false)) and not saved_chickens.is_empty(): return false
	if not bool(data.get("coop_built", false)) and not saved_ducks.is_empty(): return false
	if not bool(data.get("barn_built", false)) and not saved_cows.is_empty(): return false
	return true


func _index_of(id: String) -> int:
	for index in chickens.size():
		if str(chickens[index].id) == id: return index
	return -1


func _duck_index_of(id: String) -> int:
	for index in ducks.size():
		if str(ducks[index].id) == id: return index
	return -1


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}


static func _valid_number(value, minimum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum
