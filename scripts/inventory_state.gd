class_name InventoryState
extends RefCounted

signal changed

const INITIAL_CAPACITY := 25
const EXPANSION_SIZE := 5
const HOTBAR_SIZE := 10

var capacity := INITIAL_CAPACITY
var backpack: Array = []
var hotbar: Array = []
var selected_hotbar := 0


func _init() -> void:
	backpack.resize(capacity)
	backpack.fill("")
	hotbar.resize(HOTBAR_SIZE)
	hotbar.fill("")


func initialize(item_keys: Array, hotbar_defaults: Array = []) -> void:
	ensure_items(item_keys)
	if hotbar.all(func(value): return str(value).is_empty()):
		for index in mini(HOTBAR_SIZE, hotbar_defaults.size()):
			var item_key := str(hotbar_defaults[index])
			if item_key in backpack:
				hotbar[index] = item_key
	changed.emit()


func ensure_items(item_keys: Array) -> void:
	var available := {}
	for value in item_keys:
		var item_key := str(value)
		if not item_key.is_empty(): available[item_key] = true
	for index in backpack.size():
		if not str(backpack[index]).is_empty() and not available.has(str(backpack[index])):
			backpack[index] = ""
	for index in hotbar.size():
		if not str(hotbar[index]).is_empty() and not available.has(str(hotbar[index])):
			hotbar[index] = ""
	for value in item_keys:
		var item_key := str(value)
		if item_key.is_empty() or item_key in backpack: continue
		var empty_index := backpack.find("")
		if empty_index < 0:
			expand(EXPANSION_SIZE, false)
			empty_index = backpack.find("")
		backpack[empty_index] = item_key
	changed.emit()


func expand(amount := EXPANSION_SIZE, notify := true) -> void:
	var added := maxi(1, amount)
	capacity += added
	backpack.resize(capacity)
	for index in range(capacity - added, capacity): backpack[index] = ""
	if notify: changed.emit()


func move_backpack(from_index: int, to_index: int) -> bool:
	if not _valid_backpack_index(from_index) or not _valid_backpack_index(to_index): return false
	if from_index == to_index: return true
	var displaced = backpack[to_index]
	backpack[to_index] = backpack[from_index]
	backpack[from_index] = displaced
	changed.emit()
	return true


func assign_hotbar(item_key: String, index: int) -> bool:
	if not _valid_hotbar_index(index) or not item_key in backpack: return false
	hotbar[index] = item_key
	selected_hotbar = index
	changed.emit()
	return true


func swap_hotbar(from_index: int, to_index: int) -> bool:
	if not _valid_hotbar_index(from_index) or not _valid_hotbar_index(to_index): return false
	var displaced = hotbar[to_index]
	hotbar[to_index] = hotbar[from_index]
	hotbar[from_index] = displaced
	selected_hotbar = to_index
	changed.emit()
	return true


func clear_hotbar(index: int) -> bool:
	if not _valid_hotbar_index(index): return false
	hotbar[index] = ""
	changed.emit()
	return true


func select_hotbar(index: int) -> void:
	selected_hotbar = posmod(index, HOTBAR_SIZE)
	changed.emit()


func snapshot() -> Dictionary:
	return {
		"capacity": capacity,
		"backpack": backpack.duplicate(),
		"hotbar": hotbar.duplicate(),
		"selected_hotbar": selected_hotbar,
	}


func restore(data: Dictionary) -> bool:
	if not valid(data): return false
	capacity = int(data.capacity)
	backpack = data.backpack.duplicate()
	hotbar = data.hotbar.duplicate()
	selected_hotbar = clampi(int(data.get("selected_hotbar", 0)), 0, HOTBAR_SIZE - 1)
	changed.emit()
	return true


static func valid(data) -> bool:
	if not data is Dictionary: return false
	if not _finite_number(data.get("capacity")) or int(data.capacity) < INITIAL_CAPACITY: return false
	if not data.get("backpack") is Array or data.backpack.size() != int(data.capacity): return false
	if not data.get("hotbar") is Array or data.hotbar.size() != HOTBAR_SIZE: return false
	if data.has("selected_hotbar") and (not _finite_number(data.selected_hotbar) or int(data.selected_hotbar) < 0 or int(data.selected_hotbar) >= HOTBAR_SIZE): return false
	var seen := {}
	for value in data.backpack:
		if not value is String: return false
		if value.is_empty(): continue
		if seen.has(value): return false
		seen[value] = true
	for value in data.hotbar:
		if not value is String: return false
		if not value.is_empty() and not seen.has(value): return false
	return true


static func _finite_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _valid_backpack_index(index: int) -> bool:
	return index >= 0 and index < backpack.size()


func _valid_hotbar_index(index: int) -> bool:
	return index >= 0 and index < hotbar.size()
