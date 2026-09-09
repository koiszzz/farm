extends SceneTree

const Inventory = preload("res://scripts/inventory_state.gd")
var failures := 0
var checks := 0


func _init() -> void:
	var inventory = Inventory.new()
	var items := ["tool:hoe", "tool:seed", "tool:water", "seed:parsnip", "food:parsnip", "material:wood"]
	inventory.initialize(items, ["tool:hoe", "tool:seed", "tool:water"])
	expect(inventory.capacity == 25 and inventory.backpack.size() == 25, "backpack starts with 25 slots")
	expect(inventory.hotbar.size() == 10, "hotbar always has 10 slots")
	expect(inventory.hotbar.slice(0, 3) == ["tool:hoe", "tool:seed", "tool:water"], "default tools enter the hotbar")
	var hoe_index: int = inventory.backpack.find("tool:hoe")
	expect(inventory.move_backpack(hoe_index, 24) and inventory.backpack[24] == "tool:hoe", "items can move to any backpack slot")
	expect(inventory.assign_hotbar("food:parsnip", 9) and inventory.hotbar[9] == "food:parsnip", "any held item can be assigned to key 0")
	inventory.expand()
	expect(inventory.capacity == 30 and inventory.backpack.size() == 30, "backpack expands repeatedly in five-slot rows")
	inventory.expand()
	expect(inventory.capacity == 35, "backpack expansion is repeatable")
	var copy = Inventory.new()
	expect(copy.restore(JSON.parse_string(JSON.stringify(inventory.snapshot()))), "layout restores from JSON")
	expect(copy.snapshot() == inventory.snapshot(), "layout JSON round trip preserves arbitrary positions")
	copy.ensure_items(["tool:hoe", "material:stone"])
	expect(not "food:parsnip" in copy.backpack and not "food:parsnip" in copy.hotbar, "depleted items leave backpack and hotbar")
	expect("material:stone" in copy.backpack, "newly acquired items enter a free backpack slot")
	var invalid := copy.snapshot()
	invalid.backpack[1] = invalid.backpack[0]
	expect(not Inventory.valid(invalid), "duplicate backpack item records are rejected")
	print("Inventory state: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)


func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error(message)
