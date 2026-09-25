extends SceneTree


const MapDataService = preload("res://scripts/map_data.gd")
const FarmStateService = preload("res://scripts/farm_state.gd")

var _failed := false


func _init() -> void:
	var navigation = MapDataService.new()
	_expect(navigation.load_data(), "navigation data should load")
	var farm = FarmStateService.new()
	_expect(farm.bind(navigation, "farm_outdoor").get("ok", false), "farm should bind to the outdoor farm map")

	var cell := Vector2i(3, 15)
	_expect(not farm.till(Vector2i(1, 1)).get("ok", true), "grass must not be tillable")
	_expect(farm.till(cell).get("ok", false), "tillable soil should be tillable")
	_expect(not farm.till(cell).get("ok", true), "a cell cannot be tilled twice")
	_expect(farm.plant(cell, "parsnip").get("ok", false), "a seed can be planted on tilled soil")
	_expect(farm.get_seed_count("parsnip") == 5, "planting consumes exactly one seed")
	_expect(farm.is_crop_occupied(cell), "a planted crop should occupy its cell")
	_expect(not farm.harvest(cell).get("ok", true), "an immature crop cannot be harvested")

	_expect(farm.water(cell).get("ok", false), "a planted plot should be waterable")
	for _day in 3:
		var advance_result = farm.advance_day()
		_expect(advance_result.get("ok", false), "day advance should complete")
		if _day < 2:
			if farm.Calendar.weather(farm.day) == "雨":
				_expect(farm.get_cell_state(cell).watered, "rain should water plots on the new day")
			else:
				_expect(farm.water(cell).get("ok", false), "a dry new day should require watering")
	_expect(farm.get_cell_state(cell).get("growth", 0) == 3, "watered crop should grow once per day")
	_expect(not farm.get_cell_state(cell).get("mature", true), "parsnip should not mature before day four")

	_expect(farm.advance_day(true).get("ok", false), "rain should advance crops without manual watering")
	_expect(farm.get_cell_state(cell).get("mature", false), "four watered/rainy days should mature parsnip")
	_expect(not farm.get_cell_state(cell).get("watered", true), "day advance should clear visual water state")
	var harvest_result = farm.harvest(cell)
	_expect(harvest_result.get("ok", false), "mature crop should harvest")
	_expect(farm.get_harvest_count("parsnip") == 1, "harvest should enter harvest inventory")
	_expect(not farm.is_crop_occupied(cell), "harvest should clear crop occupancy while preserving tilled soil")

	var previous_gold := farm.get_gold()
	var shipping_result = farm.ship("parsnip")
	_expect(shipping_result.get("ok", false), "harvested crop should ship")
	_expect(farm.get_gold() == previous_gold + 35, "shipping should credit crop sale value")
	_expect(farm.get_harvest_count("parsnip") == 0, "shipping should remove item from harvest inventory")

	farm.day = 28
	_expect(farm.get_crop_growing_window("parsnip") == 1, "single-season crops should show one remaining growing day on spring 28")
	_expect(farm.get_crop_growing_window("strawberry") == 1, "late strawberries should show the short spring window")
	farm.day = 56
	_expect(farm.get_crop_growing_window("corn") == 29, "corn should remain plantable across the summer-to-fall boundary")
	farm.day = 1
	_expect(farm.get_crop_growing_window("unknown") == 0, "unknown seeds should have no growing window")

	if _failed:
		quit(1)
		return
	print("FarmState tests passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("FarmState test failed: %s" % message)
