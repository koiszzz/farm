## Pure farm-domain state for a single tillable map.
##
## This service has no scene or rendering dependencies. The game can listen to
## its signals (or inspect returned result dictionaries) and redraw only the
## cells that changed.
class_name FarmState
extends RefCounted

const Calendar = preload("res://scripts/life_calendar.gd")


const DEFAULT_GOLD := 100
const DEFAULT_SEEDS := {
	"parsnip": 6,
	"turnip": 4,
	"tomato": 4,
	"pumpkin": 2,
}
const DEFAULT_CROPS := {
	"parsnip": {"grow_days": 4, "sell_price": 35, "seed_price": 15, "seasons": [0], "label": "防风草"},
	"turnip": {"grow_days": 3, "sell_price": 28, "seed_price": 12, "seasons": [0, 2], "label": "芜菁"},
	"tomato": {"grow_days": 5, "sell_price": 52, "seed_price": 30, "seasons": [1], "regrow": 3, "label": "番茄"},
	"pumpkin": {"grow_days": 7, "sell_price": 95, "seed_price": 45, "seasons": [2], "label": "南瓜"},
}


signal cell_changed(cell: Vector2i, state: Dictionary)
signal inventory_changed(inventory_kind: String, item_id: String, amount: int)
signal gold_changed(total: int, delta: int)
signal day_advanced(day: int, is_raining: bool, result: Dictionary)


var navigation = null
var map_id := ""
var day := 1
var gold := DEFAULT_GOLD
var seed_inventory: Dictionary = DEFAULT_SEEDS.duplicate(true)
var harvest_inventory: Dictionary = {}
var crop_definitions: Dictionary = DEFAULT_CROPS.duplicate(true)

## Only changed tillable cells are stored. A missing valid cell is unworked soil.
var _plots: Dictionary = {}


func bind(map_data, target_map_id := "farm_outdoor") -> Dictionary:
	navigation = map_data
	map_id = target_map_id
	if navigation == null:
		return _failure("bind", "missing_navigation", "MapData is required.")
	if not navigation.has_method("has_map") or not navigation.has_map(map_id):
		navigation = null
		map_id = ""
		return _failure("bind", "unknown_map", "The requested map is unavailable.")
	return _success("bind", {"map_id": map_id, "day": day})


func reset(starting_gold := DEFAULT_GOLD, initial_seeds: Dictionary = {}) -> Dictionary:
	day = 1
	gold = max(0, starting_gold)
	seed_inventory = DEFAULT_SEEDS.duplicate(true) if initial_seeds.is_empty() else _positive_inventory(initial_seeds)
	harvest_inventory.clear()
	_plots.clear()
	gold_changed.emit(gold, 0)
	return _success("reset", {"gold": gold, "day": day})


func get_cell_state(cell: Vector2i) -> Dictionary:
	if not _is_tillable(cell):
		return {}
	return _plot_for(cell).duplicate(true)


func is_crop_occupied(cell: Vector2i) -> bool:
	return not str(get_cell_state(cell).get("seed", "")).is_empty()


func till(cell: Vector2i) -> Dictionary:
	if not _is_tillable(cell):
		return _failure("till", "not_tillable", "Only authored tillable cells can be tilled.", cell)
	var plot := _plot_for(cell)
	if bool(plot.get("tilled", false)):
		return _failure("till", "already_tilled", "This cell is already tilled.", cell, plot)
	plot["tilled"] = true
	plot["watered"] = Calendar.weather(day) == "雨"
	_save_plot(cell, plot)
	return _success("till", {"cell": cell, "state": get_cell_state(cell)})


func plant(cell: Vector2i, seed_id: String) -> Dictionary:
	if not _is_tillable(cell):
		return _failure("plant", "not_tillable", "Only authored tillable cells can be planted.", cell)
	if not crop_definitions.has(seed_id):
		return _failure("plant", "unknown_seed", "No crop definition exists for this seed.", cell)
	if not Calendar.date(day).season in crop_definitions[seed_id].get("seasons", [0, 1, 2, 3]):
		return _failure("plant", "wrong_season", "这种作物不适合当前季节。", cell)
	var plot := _plot_for(cell)
	if not bool(plot.get("tilled", false)):
		return _failure("plant", "not_tilled", "Till the soil before planting.", cell, plot)
	if not str(plot.get("seed", "")).is_empty():
		return _failure("plant", "occupied", "A crop already occupies this cell.", cell, plot)
	var available := get_seed_count(seed_id)
	if available <= 0:
		return _failure("plant", "out_of_seeds", "There are no seeds of this type left.", cell, plot)

	seed_inventory[seed_id] = available - 1
	plot["seed"] = seed_id
	plot["growth"] = 0
	plot["mature"] = false
	plot["watered"] = bool(plot.get("watered", false)) or Calendar.weather(day) == "雨"
	_save_plot(cell, plot)
	inventory_changed.emit("seed", seed_id, available - 1)
	return _success("plant", {"cell": cell, "seed_id": seed_id, "state": get_cell_state(cell)})


## Watering an empty tilled cell is valid and is cleared at the next day tick.
func water(cell: Vector2i) -> Dictionary:
	if not _is_tillable(cell):
		return _failure("water", "not_tillable", "Only authored tillable cells can be watered.", cell)
	var plot := _plot_for(cell)
	if not bool(plot.get("tilled", false)):
		return _failure("water", "not_tilled", "Till the soil before watering.", cell, plot)
	if bool(plot.get("watered", false)):
		return _failure("water", "already_watered", "This cell is already watered today.", cell, plot)
	plot["watered"] = true
	_save_plot(cell, plot)
	return _success("water", {"cell": cell, "state": get_cell_state(cell)})


func harvest(cell: Vector2i) -> Dictionary:
	if not _is_tillable(cell):
		return _failure("harvest", "not_tillable", "Only authored tillable cells can be harvested.", cell)
	var plot := _plot_for(cell)
	var seed_id := str(plot.get("seed", ""))
	if seed_id.is_empty():
		return _failure("harvest", "empty", "There is no crop to harvest.", cell, plot)
	if not bool(plot.get("mature", false)):
		return _failure("harvest", "not_mature", "This crop is still growing.", cell, plot)

	var harvested_total := get_harvest_count(seed_id) + 1
	harvest_inventory[seed_id] = harvested_total
	plot["seed"] = ""
	plot["growth"] = 0
	plot["mature"] = false
	plot["watered"] = false
	var regrow := int(crop_definitions[seed_id].get("regrow", 0))
	if regrow > 0:
		plot["seed"] = seed_id
		plot["growth"] = int(crop_definitions[seed_id].grow_days) - regrow
	_save_plot(cell, plot)
	inventory_changed.emit("harvest", seed_id, harvested_total)
	return _success("harvest", {"cell": cell, "item_id": seed_id, "amount": 1, "state": get_cell_state(cell)})


## Settle the departing day's water, then apply the arriving day's weather.
func advance_day(is_raining := false) -> Dictionary:
	if not is_bound():
		return _failure("advance_day", "not_bound", "Bind MapData before advancing the farm.")
	var grown_cells: Array[Vector2i] = []
	var matured_cells: Array[Vector2i] = []
	var cleared_water_cells: Array[Vector2i] = []
	for cell in _plots.keys():
		var plot: Dictionary = _plots[cell]
		var seed_id := str(plot.get("seed", ""))
		var was_watered := bool(plot.get("watered", false))
		var did_grow := not seed_id.is_empty() and not bool(plot.get("mature", false)) and (was_watered or is_raining)
		if did_grow:
			plot["growth"] = int(plot.get("growth", 0)) + 1
			grown_cells.append(cell)
			var crop = crop_definitions.get(seed_id, {})
			if crop is Dictionary and int(plot["growth"]) >= int(crop.get("grow_days", 1)):
				plot["mature"] = true
				matured_cells.append(cell)
		if was_watered:
			cleared_water_cells.append(cell)
		if was_watered or did_grow or not seed_id.is_empty():
			plot["watered"] = false
			_save_plot(cell, plot)

	day += 1
	var expired: Array[Vector2i] = []
	for cell in _plots:
		var plot: Dictionary = _plots[cell]
		var seed_id := str(plot.get("seed", ""))
		if not seed_id.is_empty() and not Calendar.date(day).season in crop_definitions[seed_id].get("seasons", [0, 1, 2, 3]):
			plot["seed"] = ""
			plot["growth"] = 0
			plot["mature"] = false
			expired.append(cell)
		plot["watered"] = Calendar.weather(day) == "雨" and bool(plot.get("tilled", false))
		_save_plot(cell, plot)
	var result := _success("advance_day", {
		"day": day,
		"is_raining": is_raining,
		"grown_cells": grown_cells,
		"matured_cells": matured_cells,
		"cleared_water_cells": cleared_water_cells,
		"expired_cells": expired,
	})
	day_advanced.emit(day, is_raining, result.duplicate(true))
	return result


func ship(item_id: String, amount: int = 1) -> Dictionary:
	if not crop_definitions.has(item_id):
		return _failure("ship", "unknown_item", "This item cannot be shipped.")
	var available := get_harvest_count(item_id)
	if available <= 0:
		return _failure("ship", "empty_inventory", "There is no harvested item to ship.")
	var requested: int = available if amount < 0 else amount
	if requested <= 0:
		return _failure("ship", "invalid_amount", "Shipping amount must be positive.")
	var shipped: int = min(available, requested)
	var remaining: int = available - shipped
	harvest_inventory[item_id] = remaining
	var crop: Dictionary = crop_definitions[item_id]
	var earned: int = shipped * int(crop.get("sell_price", 0))
	gold += earned
	inventory_changed.emit("harvest", item_id, remaining)
	gold_changed.emit(gold, earned)
	return _success("ship", {"item_id": item_id, "amount": shipped, "earned": earned, "gold": gold})


func ship_all() -> Dictionary:
	var total_earned := 0
	var shipped: Dictionary = {}
	for item_id in harvest_inventory.keys().duplicate():
		var amount := get_harvest_count(str(item_id))
		if amount <= 0:
			continue
		var result := ship(str(item_id), amount)
		if bool(result.get("ok", false)):
			shipped[item_id] = int(result.get("amount", 0))
			total_earned += int(result.get("earned", 0))
	return _success("ship_all", {"shipped": shipped, "earned": total_earned, "gold": gold})


func add_seeds(seed_id: String, amount: int) -> Dictionary:
	if not crop_definitions.has(seed_id):
		return _failure("add_seeds", "unknown_seed", "No crop definition exists for this seed.")
	if amount <= 0:
		return _failure("add_seeds", "invalid_amount", "Seed amount must be positive.")
	var total := get_seed_count(seed_id) + amount
	seed_inventory[seed_id] = total
	inventory_changed.emit("seed", seed_id, total)
	return _success("add_seeds", {"seed_id": seed_id, "amount": amount, "total": total})


func get_seed_count(seed_id: String) -> int:
	return max(0, int(seed_inventory.get(seed_id, 0)))


func buy_seed(seed_id: String, amount := 1) -> Dictionary:
	if not crop_definitions.has(seed_id) or amount <= 0 or amount > 99:
		return _failure("buy_seed", "invalid_amount", "购买数量无效。")
	var price := int(crop_definitions[seed_id].get("seed_price", 15)) * amount
	if gold < price: return _failure("buy_seed", "poor", "金币不足。")
	gold -= price
	add_seeds(seed_id, amount)
	gold_changed.emit(gold, -price)
	return _success("buy_seed", {"cost": price})


func snapshot() -> Dictionary:
	var plots: Array = []
	for cell in _plots:
		plots.append({"x": cell.x, "y": cell.y, "state": _plots[cell].duplicate(true)})
	return {"day": day, "gold": gold, "seeds": seed_inventory.duplicate(true), "harvest": harvest_inventory.duplicate(true), "plots": plots}


func restore(data: Dictionary) -> void:
	day = maxi(1, int(data.get("day", 1)))
	gold = maxi(0, int(data.get("gold", DEFAULT_GOLD)))
	seed_inventory = _positive_inventory(data.get("seeds", {}))
	harvest_inventory = _positive_inventory(data.get("harvest", {}))
	for item in data.get("seeds", {}): seed_inventory[item] = maxi(0, int(data.seeds[item]))
	for item in data.get("harvest", {}): harvest_inventory[item] = maxi(0, int(data.harvest[item]))
	_plots.clear()
	for row in data.get("plots", []):
		var cell := Vector2i(int(row.x), int(row.y))
		if _is_tillable(cell):
			var state: Dictionary = row.state.duplicate(true)
			state["growth"] = int(state.get("growth", 0))
			_save_plot(cell, state)


func get_harvest_count(item_id: String) -> int:
	return max(0, int(harvest_inventory.get(item_id, 0)))


func get_gold() -> int:
	return gold


func get_crop_definition(seed_id: String) -> Dictionary:
	var crop = crop_definitions.get(seed_id, {})
	return crop.duplicate(true) if crop is Dictionary else {}


func get_plots() -> Dictionary:
	return _plots.duplicate(true)


func is_bound() -> bool:
	return navigation != null and not map_id.is_empty() and navigation.has_method("has_map") and navigation.has_map(map_id)


func _is_tillable(cell: Vector2i) -> bool:
	return is_bound() and navigation.has_method("is_tillable") and navigation.is_tillable(map_id, cell)


func _plot_for(cell: Vector2i) -> Dictionary:
	var plot = _plots.get(cell, {})
	if plot is Dictionary:
		return plot.duplicate(true) if not plot.is_empty() else _new_plot()
	return _new_plot()


func _new_plot() -> Dictionary:
	return {"tilled": false, "seed": "", "watered": false, "growth": 0, "mature": false}


func _save_plot(cell: Vector2i, plot: Dictionary) -> void:
	_plots[cell] = plot.duplicate(true)
	cell_changed.emit(cell, get_cell_state(cell))


func _success(action: String, values: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "action": action}
	result.merge(values, true)
	return result


func _failure(action: String, code: String, message: String, cell = null, state: Dictionary = {}) -> Dictionary:
	var result := {"ok": false, "action": action, "code": code, "message": message}
	if cell is Vector2i:
		result["cell"] = cell
	if not state.is_empty():
		result["state"] = state.duplicate(true)
	return result


func _positive_inventory(source: Dictionary) -> Dictionary:
	var result := {}
	for item_id in source.keys():
		var amount: int = max(0, int(source[item_id]))
		if amount > 0:
			result[str(item_id)] = amount
	return result
