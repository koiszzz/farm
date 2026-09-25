extends Node2D

const ORE_DEPOSIT_ART: Texture2D = preload("res://assets/art/runtime_generated/ore_deposits_v1.svg")
const BEACH_COLLECTIBLES_ART: Texture2D = preload("res://assets/art/runtime_generated/beach_collectibles_v1.png")
const ORE_DEPOSIT_INDEX := {"copper_ore": 0, "iron_ore": 1, "coal": 2, "quartz": 3, "earth_crystal": 4, "amethyst": 5, "frozen_tear": 6, "fire_quartz": 7}

var game

func _ready() -> void:
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	if game == null or game.navigation == null or game.farm == null: return
	if game.Mining.is_mine(game.current_map_id):
		_draw_mine()
	for item in game.homestead.available(game.current_map_id, game.farm.day, game.navigation):
		var p: Vector2 = game.world.cell_center_to_screen(item.cell)
		draw_rect(Rect2(p + Vector2(-9, 2), Vector2(20, 5)), Color(0.22, 0.20, 0.10, 0.2))
		match str(item.kind):
			"shell":
				var pickup_index := 0 if str(item.key).ends_with(":0") or str(item.key).ends_with(":2") else 1
				var frame_size := BEACH_COLLECTIBLES_ART.get_size() / Vector2(4, 2)
				var source_rect := Rect2(Vector2(pickup_index, 0) * frame_size, frame_size)
				draw_texture_rect_region(BEACH_COLLECTIBLES_ART, Rect2(p + Vector2(-14, -17), Vector2(28, 28)), source_rect)
			"wood":
				draw_line(p + Vector2(-9, 1), p + Vector2(9, -5), Color("674226"), 7)
				draw_line(p + Vector2(-8, -1), p + Vector2(8, -7), Color("c18a4c"), 3)
				draw_line(p, p + Vector2(0, -9), Color("956432"), 3)
			"stone":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 2), p + Vector2(-8, -6), p + Vector2(0, -10), p + Vector2(9, -5), p + Vector2(11, 2)]), Color("737e7c"))
				draw_line(p + Vector2(-7, -5), p + Vector2(0, -8), Color("bac5ae"), 3)
			"berry":
				draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 7)), Color("3f7434"))
				for i in 3:
					draw_rect(Rect2(p + Vector2(-6 + i * 5, -8 + i % 2 * 3), Vector2(5, 5)), Color("c9556d"))
					draw_rect(Rect2(p + Vector2(-6 + i * 5, -8 + i % 2 * 3), Vector2(2, 2)), Color("f5afa1"))
			"mushroom":
				draw_rect(Rect2(p + Vector2(-2, -6), Vector2(5, 9)), Color("f1d4a1"))
				draw_rect(Rect2(p + Vector2(-8, -9), Vector2(17, 5)), Color("ae5e3b"))
				draw_rect(Rect2(p + Vector2(-5, -13), Vector2(11, 5)), Color("d28a52"))
				draw_rect(Rect2(p + Vector2(-3, -11), Vector2(3, 2)), Color("f2d1a0"))
	if game._is_farm_area():
		var base: Vector2 = game.world.cell_center_to_screen(game.pet.home_cell) + Vector2(32, 0)
		draw_rect(Rect2(base + Vector2(-13, -11), Vector2(26, 22)), Color("865832"))
		draw_rect(Rect2(base + Vector2(-10, -9), Vector2(20, 17)), Color("cc9950"))
		draw_colored_polygon(PackedVector2Array([base + Vector2(-17, -10), base + Vector2(0, -25), base + Vector2(17, -10)]), Color("ad5430"))
		draw_line(base + Vector2(-17, -10), base + Vector2(0, -25), Color("e3a24d"), 2)
		draw_rect(Rect2(base + Vector2(-5, -4), Vector2(10, 14)), Color("513c29"))
		draw_rect(Rect2(base + Vector2(-21, 16), Vector2(18, 7)), Color("7b6254"))
		draw_rect(Rect2(base + Vector2(-19, 16), Vector2(14, 3)), Color("d8af67") if game.homestead.fed_day == game.farm.day else Color("394a4e"))


func _draw_mine() -> void:
	for cell in game.Mining.cells_for_floor(game.current_map_id):
		var deposit: Dictionary = game.mining.vein(game.current_map_id, cell, game.farm.day)
		if deposit.is_empty(): continue
		var p: Vector2 = game.world.cell_center_to_screen(cell)
		draw_rect(Rect2(p + Vector2(-13, 7), Vector2(26, 5)), Color("373542"))
		var ore_index := int(ORE_DEPOSIT_INDEX.get(str(deposit.material), 0))
		draw_texture_rect_region(ORE_DEPOSIT_ART, Rect2(p - Vector2(16, 16), Vector2.ONE * 32.0), Rect2(Vector2(ore_index * 32, 0), Vector2(32, 32)))
		if game.mining.damage.has(deposit.key): draw_polyline(PackedVector2Array([p + Vector2(-2, -13), p + Vector2(1, -5), p + Vector2(-4, 3)]), Color("343544"), 2)
	var ladders := [Vector2i(18, 24)]
	if game.current_map_id != "mine_3": ladders.append(Vector2i(18, 4))
	for cell in ladders:
		var p: Vector2 = game.world.cell_center_to_screen(cell)
		draw_rect(Rect2(p - Vector2(12, 12), Vector2(24, 24)), Color("262630"))
		for x in [-8, 8]: draw_line(p + Vector2(x, -13), p + Vector2(x, 13), Color("b6926b"), 3)
		for y in [-9, -3, 3, 9]: draw_line(p + Vector2(-8, y), p + Vector2(8, y), Color("d6b27b"), 2)
