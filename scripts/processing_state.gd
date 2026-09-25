class_name ProcessingState
extends RefCounted

const MACHINES := {
	"mayo_machine": {"name": "蛋黄酱机", "description": "放入鸡蛋，隔夜制成蛋黄酱。"},
	"preserves_jar": {"name": "腌制罐", "description": "放入作物，隔夜制成腌菜。"},
	"cheese_press": {"name": "奶酪机", "description": "放入一桶牛奶，隔夜制成奶酪。"},
}
const MAYONNAISE_PRICE := 190
const CHEESE_PRICE := 230
const CHEESE_ENERGY := 40

var jobs: Dictionary = {}
var products: Dictionary = {}


static func is_machine(id: String) -> bool:
	return MACHINES.has(id)


func start(cell: Vector2i, machine_id: String, input_id: String, day: int, farm, animals) -> Dictionary:
	if not MACHINES.has(machine_id): return _failure("未知加工机器。")
	var key := _key(cell)
	if jobs.has(key): return _failure("机器正在工作，请先等待或收取成品。")
	var output_id := ""
	match machine_id:
		"mayo_machine":
			if input_id == "egg" and animals.eggs > 0:
				animals.eggs -= 1
			elif input_id == "duck_egg" and animals.duck_eggs > 0:
				animals.duck_eggs -= 1
			else:
				return _failure("需要背包中的一枚鸡蛋或鸭蛋。")
			output_id = "mayonnaise"
		"cheese_press":
			if input_id != "milk" or animals.milk <= 0: return _failure("需要背包中的一桶牛奶。")
			animals.milk -= 1
			output_id = "cheese"
		"preserves_jar":
			if not farm.crop_definitions.has(input_id) or farm.get_harvest_count(input_id) <= 0: return _failure("需要背包中的一份作物。")
			farm.harvest_inventory[input_id] -= 1
			output_id = "pickles:" + input_id
	jobs[key] = {"x": cell.x, "y": cell.y, "machine": machine_id, "input": input_id, "output": output_id, "ready_day": day + 1, "ready": false}
	return {"ok": true, "message": "%s已经开始加工，明早可以收取。" % MACHINES[machine_id].name}


func advance_day(arriving_day: int) -> Dictionary:
	var completed := 0
	for key in jobs:
		var job: Dictionary = jobs[key]
		if not bool(job.ready) and arriving_day >= int(job.ready_day):
			job.ready = true
			jobs[key] = job
			completed += 1
	return {"completed": completed}


func job_at(cell: Vector2i) -> Dictionary:
	var job = jobs.get(_key(cell), {})
	return job.duplicate(true) if job is Dictionary else {}


func can_remove(cell: Vector2i) -> bool:
	return not jobs.has(_key(cell))


func collect(cell: Vector2i, farm = null) -> Dictionary:
	var key := _key(cell)
	var job: Dictionary = jobs.get(key, {})
	if job.is_empty(): return _failure("机器里没有成品。")
	if not bool(job.ready): return _failure("还在加工，明早再来看看。")
	var output_id := str(job.output)
	products[output_id] = int(products.get(output_id, 0)) + 1
	jobs.erase(key)
	return {"ok": true, "output": output_id, "message": "收取了%s。" % product_definition(output_id, farm).name}


func product_definition(id: String, farm) -> Dictionary:
	if id == "mayonnaise": return {"name": "农家蛋黄酱", "price": MAYONNAISE_PRICE, "energy": 35}
	if id == "cheese": return {"name": "手工奶酪", "price": CHEESE_PRICE, "energy": CHEESE_ENERGY}
	if id.begins_with("pickles:"):
		var crop_id := id.trim_prefix("pickles:")
		var crop: Dictionary = farm.get_crop_definition(crop_id) if farm != null else {}
		var label := str(crop.get("label", crop_id))
		var price := int(crop.get("sell_price", 0)) * 2 + 50
		return {"name": "腌%s" % label, "price": price, "energy": 30}
	return {"name": id, "price": 0, "energy": 0}


func consume(id: String) -> bool:
	if int(products.get(id, 0)) <= 0: return false
	products[id] -= 1
	return true


func ship(farm) -> int:
	var earned := 0
	for id in products:
		earned += int(products[id]) * int(product_definition(str(id), farm).price)
		products[id] = 0
	farm.gold += earned
	return earned


func snapshot() -> Dictionary:
	var rows: Array = []
	for job in jobs.values(): rows.append(job.duplicate(true))
	return {"jobs": rows, "products": products.duplicate()}


func restore(data: Dictionary) -> void:
	jobs.clear()
	products.clear()
	for value in data.get("jobs", []):
		if value is Dictionary:
			var job: Dictionary = value.duplicate(true)
			jobs[_key(Vector2i(int(job.x), int(job.y)))] = job
	for id in data.get("products", {}): products[str(id)] = maxi(0, int(data.products[id]))


static func valid(data) -> bool:
	if not data is Dictionary: return false
	var saved_jobs = data.get("jobs", [])
	var saved_products = data.get("products", {})
	if not saved_jobs is Array or not saved_products is Dictionary: return false
	var cells := {}
	for job in saved_jobs:
		if not job is Dictionary or not job.has_all(["x", "y", "machine", "input", "output", "ready_day", "ready"]): return false
		if not _number(job.x) or not _number(job.y) or not _number(job.ready_day) or float(job.ready_day) < 0 or not job.ready is bool: return false
		if not MACHINES.has(str(job.machine)) or not job.input is String or not _valid_product_id(str(job.output)): return false
		var key := "%d,%d" % [int(job.x), int(job.y)]
		if cells.has(key): return false
		cells[key] = true
	for id in saved_products:
		if not _valid_product_id(str(id)) or not _number(saved_products[id]) or float(saved_products[id]) < 0: return false
	return true


static func _valid_product_id(id: String) -> bool:
	return id == "mayonnaise" or id == "cheese" or (id.begins_with("pickles:") and not id.trim_prefix("pickles:").is_empty())


static func _number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
