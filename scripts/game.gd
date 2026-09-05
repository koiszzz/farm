extends Node2D

const MapDataScript = preload("res://scripts/map_data.gd")
const WorldRendererScript = preload("res://scripts/world_renderer.gd")
const AvatarRendererScript = preload("res://scripts/avatar_renderer.gd")
const CharacterCreatorScript = preload("res://scripts/character_creator.gd")
const FarmStateScript = preload("res://scripts/farm_state.gd")
const ArtActorScript = preload("res://scripts/art_actor.gd")
const Calendar = preload("res://scripts/life_calendar.gd")
const VillageScript = preload("res://scripts/village_life.gd")
const LifePanelScript = preload("res://scripts/life_panel.gd")
var village = VillageScript.new()
var life_panel
var clock_minutes := 360
var clock_elapsed := 0.0
var energy := 100
var autosave_enabled := true
var save_path := "user://farm_life_v1.json"
var hud_day: Label
const TOOLS_ART: Texture2D = preload("res://assets/art/source_generated/mvp_tools_and_seeds_source_v1.png")
const NPC_ART := {
	"florist": preload("res://assets/art/source_generated/npc_florist_uniform_actions_source_v1.png"),
	"shopkeeper": preload("res://assets/art/source_generated/npc_shopkeeper_uniform_actions_source_v1.png"),
	"fisherman": preload("res://assets/art/source_generated/npc_fisherman_uniform_actions_source_v1.png"),
}

const MOVE_SECONDS := 0.12
const WALK_FRAME_SECONDS := 0.055

var navigation: MapData
var world: WorldRenderer
var player: AvatarRenderer
var player_body: CharacterBody2D
var game_camera: Camera2D
var collision_root: Node2D
var creator: CharacterCreator
var farm = null
var current_map_id := "farm_outdoor"
var current_tool := "hoe"
var current_seed_index := 0
var current_seed_ids := ["parsnip", "turnip", "tomato", "pumpkin"]
var player_cell := Vector2i.ZERO
var pending_cell := Vector2i.ZERO
var move_target := Vector2.ZERO
var move_from_cell := Vector2i.ZERO
var move_origin := Vector2.ZERO
var moving := false
var transition_lock_frames := 0
var walk_phase := false
var walk_animation_elapsed := 0.0
var hud_status: Label
var hud_location: Label
var hud_hint: Label
var hud_tool_icon: TextureRect
var npcs: Dictionary = {}


func _ready() -> void:
	get_tree().auto_accept_quit = false
	navigation = MapDataScript.new()
	if not navigation.load_data():
		push_error("Failed to load navigation data: %s" % navigation.load_errors)
		return
	world = WorldRendererScript.new()
	add_child(world)
	collision_root = Node2D.new()
	collision_root.name = "WorldColliders"
	add_child(collision_root)
	farm = FarmStateScript.new()
	if not farm.bind(navigation, "farm_outdoor").get("ok", false):
		push_error("Failed to bind farm state.")
		return
	farm.cell_changed.connect(_on_farm_cell_changed)
	farm.inventory_changed.connect(_on_farm_inventory_changed)
	farm.gold_changed.connect(_on_farm_gold_changed)
	farm.day_advanced.connect(_on_farm_day_advanced)
	world.set_farm_state(farm)
	player = AvatarRendererScript.new()
	player.pixel_scale = 0.13
	player.z_index = 4
	player_body = CharacterBody2D.new()
	player_body.name = "PlayerBody"
	player_body.collision_layer = 2
	player_body.collision_mask = 1
	add_child(player_body)
	player_body.add_child(player)
	var player_shape := CollisionShape2D.new()
	var player_footprint := RectangleShape2D.new()
	player_footprint.size = Vector2(18, 14)
	player_shape.shape = player_footprint
	player_shape.position = Vector2(0, 17)
	player_body.add_child(player_shape)
	game_camera = Camera2D.new()
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 10.0
	player_body.add_child(game_camera)
	game_camera.make_current()
	_build_hud()
	_change_map("farm_outdoor", navigation.get_spawn("farm_outdoor"))
	creator = CharacterCreatorScript.new()
	add_child(creator)
	creator.customization_confirmed.connect(_on_customization_confirmed)
	life_panel = LifePanelScript.new()
	add_child(life_panel)
	if autosave_enabled:
		_load_game()
	_update_farm_hud()
	_set_status("WASD 移动 · E 使用工具 · F 互动 · Tab 日历 · I 背包 · R 居民。农舍或农场按 N 休息。")
	if not autosave_enabled and FileAccess.file_exists(save_path):
		_set_status("存档损坏且备份不可用；已保留原文件并停止自动覆盖。当前为临时游玩。")


func _physics_process(delta: float) -> void:
	if navigation == null or creator == null or creator.visible:
		return
	if life_panel != null and life_panel.visible:
		return
	clock_elapsed += delta
	if clock_elapsed >= 7.0:
		clock_elapsed -= 7.0
		clock_minutes += 10
		_update_farm_hud()
		if clock_minutes >= 1440:
			_advance_day(false)
			return
	if transition_lock_frames > 0:
		transition_lock_frames -= 1
		return
	_update_player_movement(delta)
	_update_npcs(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if life_panel != null and life_panel.visible:
		if event.keycode == KEY_ESCAPE: life_panel.close()
		get_viewport().set_input_as_handled()
		return
	if not creator.visible and not moving:
		match event.keycode:
			KEY_TAB: _open_calendar()
			KEY_I: _open_inventory()
			KEY_R: _open_people()
			KEY_G: _open_gifts(_nearby_npc_actor())
			KEY_F5: _set_status("存档已保存。" if _save_game() else "存档失败，请检查磁盘空间。")
		if event.keycode in [KEY_TAB, KEY_I, KEY_R, KEY_G, KEY_F5]:
			get_viewport().set_input_as_handled()
			return
	if event.keycode == KEY_C:
		creator.open(player.get_customization())
		_set_status("可以调整外观；确认后返回农场。")
		get_viewport().set_input_as_handled()
		return
	if creator.visible:
		return
	if event.keycode == KEY_F:
		_interact()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M:
		world.show_routes = not world.show_routes
		world.queue_redraw()
		_set_status("导航标注：%s" % ("已显示" if world.show_routes else "已隐藏"))
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_E:
		_farm_action()
		get_viewport().set_input_as_handled()
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		current_tool = ["hoe", "seed", "water", "harvest"][event.keycode - KEY_1]
		_update_farm_hud()
		_set_status("已选择%s。按 E 对面前格子使用。" % _tool_name())
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_Q:
		current_seed_index = (current_seed_index + 1) % current_seed_ids.size()
		_update_farm_hud()
		_set_status("当前种子：%s。" % _seed_name(_current_seed_id()))
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_N:
		_ask_sleep()
		get_viewport().set_input_as_handled()
		return


func _update_player_movement(delta: float) -> void:
	if moving:
		walk_animation_elapsed += delta
		var frame_index := int(floor(walk_animation_elapsed / WALK_FRAME_SECONDS)) % 2
		player.set_pose(player.facing, "walk_a" if frame_index == 0 else "walk_b")
		var desired_position := player_body.position.move_toward(move_target, world.TILE_SIZE / MOVE_SECONDS * delta)
		var motion := desired_position - player_body.position
		if player_body.test_move(player_body.global_transform, motion):
			# A failed movement must return to the last confirmed grid cell.  Do
			# not derive this from a half-updated physics position: during a map
			# transition that can be stale and send the actor to the world origin.
			player_cell = move_from_cell
			pending_cell = move_from_cell
			player_body.position = _avatar_position_for(move_from_cell)
			move_target = player_body.position
			moving = false
			player.set_pose(player.facing, "idle")
			_set_status("前方有障碍物。")
			return
		player_body.position = desired_position
		if player_body.position.distance_to(move_target) < 0.1:
			player_body.position = move_target
			player_cell = pending_cell
			moving = false
			player.set_pose(player.facing, "idle")
			_after_arrival()
		return
	_begin_move(_pressed_direction())


func _begin_move(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	# Turning toward occupied soil must still work so the crop can be tended.
	player.set_pose(_facing_for(direction), "idle")
	var next_cell := player_cell + direction
	var crop_occupied: bool = current_map_id == "farm_outdoor" and farm.is_crop_occupied(next_cell)
	if not navigation.is_walkable(current_map_id, next_cell, crop_occupied):
		_set_status("前方有障碍物。")
		return
	move_from_cell = player_cell
	move_origin = player_body.position
	pending_cell = next_cell
	walk_phase = not walk_phase
	walk_animation_elapsed = 0.0
	player.set_pose(_facing_for(direction), "walk_a")
	move_target = _avatar_position_for(pending_cell)
	moving = true


func _pressed_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	return Vector2i.ZERO


func _after_arrival() -> void:
	var exit := navigation.exit_at(current_map_id, player_cell)
	if not exit.is_empty():
		var arrival := _as_cell(exit.get("arrival", []))
		_change_map(str(exit.get("target", "farm_outdoor")), arrival)
		return
	var interaction := navigation.interaction_at(current_map_id, player_cell)
	if not interaction.is_empty():
		_set_status("站在交互点：按 F 使用 %s。" % _interaction_name(str(interaction.get("target", "设施"))))
	else:
		_set_status("%s · 格子 %d, %d" % [_location_name(), player_cell.x, player_cell.y])


func _interact() -> void:
	if moving: return
	var interaction := navigation.interaction_at(current_map_id, player_cell)
	if not interaction.is_empty():
		# Doorways and counters are precise authored tiles.  They win over a
		# nearby NPC so an NPC route can never make a building impossible to enter.
		player.set_pose(player.facing, "use")
		var target := str(interaction.get("target", ""))
		match target:
			"farmhouse_interior":
				_change_map("farmhouse_interior", navigation.get_spawn("farmhouse_interior"))
			"general_store_interior":
				_change_map("general_store_interior", navigation.get_spawn("general_store_interior"))
			"clinic_interior":
				_change_map("clinic_interior", navigation.get_spawn("clinic_interior"))
			"cafe_interior":
				_change_map("cafe_interior", navigation.get_spawn("cafe_interior"))
			"bed": _ask_sleep()
			"chest": _open_inventory()
			"fireplace": _set_status("壁炉：屋内很温暖。")
			"shop_counter": _open_shop()
			"clinic_counter": _set_status("诊所柜台：治疗与体力恢复服务将在这里提供。")
			"cafe_counter": _set_status("咖啡馆柜台：今天的热饮和点心正在准备。")
			"shipping_box":
				var shipping: Dictionary = farm.ship_all()
				_set_status("出货箱：售出 %d 金币。当前金币 %d。" % [int(shipping.get("earned", 0)), int(shipping.get("gold", farm.get_gold()))])
				_update_farm_hud()
				_save_game()
			"well": _set_status("水井：角色在正确站位，后续用于填充浇水壶。")
			"notice_board": _open_festival()
			_: _set_status("%s：该场景将在后续开放。" % _interaction_name(target))
		return
	var nearby_npc := _nearby_npc_actor()
	if not nearby_npc.is_empty():
		player.set_pose(player.facing, "use")
		_open_dialogue(nearby_npc)
		return
	_set_status("请站到紫色交互格上，或靠近 NPC 后再按 F。")


func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
	if not navigation.has_map(next_map_id):
		_set_status("未知地图：%s" % next_map_id)
		return
	current_map_id = next_map_id
	var size := navigation.get_map_size(current_map_id)
	var map_size_px: Vector2 = Vector2(size) * WorldRenderer.TILE_SIZE
	world.configure(navigation, current_map_id, Vector2.ZERO)
	_rebuild_world_collisions()
	game_camera.limit_left = 0
	game_camera.limit_top = 44
	game_camera.limit_right = int(map_size_px.x)
	game_camera.limit_bottom = int(map_size_px.y)
	game_camera.reset_smoothing()
	player_cell = next_cell if navigation.is_walkable(current_map_id, next_cell) else navigation.get_spawn(current_map_id)
	pending_cell = player_cell
	player_body.position = _avatar_position_for(player_cell)
	move_from_cell = player_cell
	move_origin = player_body.position
	move_target = player_body.position
	moving = false
	transition_lock_frames = 1
	player.set_pose("down", "idle")
	_spawn_map_npcs()
	_update_location()
	_update_farm_hud()
	_set_status("进入%s。粉色出口可切换场景，紫色格可互动。" % _location_name())


func _rebuild_world_collisions() -> void:
	if collision_root == null:
		return
	for child in collision_root.get_children():
		# Removal from the physics tree must be immediate.  queue_free() alone
		# leaves the old map's StaticBody2D active until frame end, so a map
		# transition can make the player collide with invisible prior-scene walls.
		collision_root.remove_child(child)
		child.queue_free()
	var map_size := navigation.get_map_size(current_map_id)
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var crop_occupied: bool = current_map_id == "farm_outdoor" and farm.is_crop_occupied(cell)
			if navigation.is_walkable(current_map_id, cell, crop_occupied):
				continue
			var obstacle := StaticBody2D.new()
			obstacle.name = "Obstacle_%d_%d" % [x, y]
			obstacle.collision_layer = 1
			obstacle.collision_mask = 0
			obstacle.position = world.cell_center_to_screen(cell)
			var shape_node := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2.ONE * (WorldRenderer.TILE_SIZE - 2.0)
			shape_node.shape = shape
			obstacle.add_child(shape_node)
			collision_root.add_child(obstacle)


func _spawn_map_npcs() -> void:
	for state_value in npcs.values():
		var state: Dictionary = state_value
		if is_instance_valid(state.get("node")):
			state.node.queue_free()
	npcs.clear()
	if current_map_id != "town_square":
		return
	for actor in navigation.get_npc_routes(current_map_id):
		var route: Array[Vector2i] = _npc_walk_route(navigation.get_npc_route(current_map_id, str(actor)))
		if route.is_empty():
			continue
		var npc = ArtActorScript.new()
		npc.z_index = 3
		npc.configure(NPC_ART.get(actor, NPC_ART.get("florist")), 0.13)
		npc.set_pose("down", "idle")
		var start_index := mini(7, route.size() - 1) if str(actor) == "florist" else 0
		npc.position = _avatar_position_for(route[start_index]) + Vector2(0, 1)
		var name_tag := Label.new()
		name_tag.text = str(VillageScript.PEOPLE.get(actor, {}).get("name", actor))
		name_tag.position = Vector2(-28, -43)
		name_tag.size.x = 56
		name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_tag.add_theme_color_override("font_outline_color", Color("423729"))
		name_tag.add_theme_constant_override("outline_size", 4)
		npc.add_child(name_tag)
		add_child(npc)
		npcs[actor] = {"node": npc, "route": route, "index": start_index, "timer": 0.0}


func _npc_walk_route(checkpoints: Array[Vector2i]) -> Array[Vector2i]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, navigation.get_map_size(current_map_id))
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			grid.set_point_solid(Vector2i(x, y), not navigation.is_walkable(current_map_id, Vector2i(x, y)))
	var route: Array[Vector2i] = []
	for index in checkpoints.size():
		var segment := grid.get_id_path(checkpoints[index], checkpoints[(index + 1) % checkpoints.size()])
		for step in range(segment.size() - 1): route.append(segment[step])
	return route


func _nearby_npc_actor() -> String:
	if current_map_id != "town_square":
		return ""
	var closest := ""
	var nearest_distance := WorldRenderer.TILE_SIZE * 1.65
	for actor in npcs.keys():
		var state: Dictionary = npcs[actor]
		var route: Array = state.get("route", [])
		var distance: float = player_body.position.distance_to(state.node.position)
		if not route.is_empty() and distance < nearest_distance:
			closest = str(actor)
			nearest_distance = distance
	return closest


func _update_npcs(delta: float) -> void:
	for actor in npcs.keys():
		var state: Dictionary = npcs[actor]
		var npc = state.node
		# Stop to greet an approaching player. Panels pause the village clock.
		if npc.position.distance_to(player_body.position) < 50:
			npc.set_pose(npc.facing, "idle")
			continue
		var target: Vector2 = _avatar_position_for(state.route[state.index]) + Vector2(0, 1)
		if npc.position.distance_to(target) < 0.5:
			state.timer = float(state.timer) + delta
			npc.set_pose(npc.facing, "idle")
			# A slower evening stroll; festival days keep the square lively.
			if state.timer >= (2.5 if clock_minutes >= 1080 else 0.8):
				state.timer = 0.0
				state.index = (int(state.index) + 1) % state.route.size()
		else:
			var direction: Vector2 = target - npc.position
			npc.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "walk_a" if Time.get_ticks_msec() % 400 < 200 else "walk_b")
			npc.position = npc.position.move_toward(target, 34.0 * delta)


func _avatar_position_for(cell: Vector2i) -> Vector2:
	return world.cell_center_to_screen(cell)


func _cell_from_world_position(position: Vector2) -> Vector2i:
	var local := position - world.origin
	return Vector2i(floori(local.x / WorldRenderer.TILE_SIZE), floori(local.y / WorldRenderer.TILE_SIZE))


func _facing_for(direction: Vector2i) -> String:
	if direction.x < 0: return "left"
	if direction.x > 0: return "right"
	if direction.y < 0: return "up"
	return "down"


func _as_cell(value) -> Vector2i:
	if value is Vector2i: return value
	if value is Array and value.size() >= 2: return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var strip := ColorRect.new()
	strip.color = Color("#203545", 0.94)
	strip.position = Vector2(0, 0)
	strip.size = Vector2(1152, 84)
	layer.add_child(strip)
	hud_location = Label.new()
	hud_location.position = Vector2(24, 8)
	hud_location.add_theme_font_size_override("font_size", 21)
	hud_location.add_theme_color_override("font_color", Color("#fff3d5"))
	layer.add_child(hud_location)
	hud_hint = Label.new()
	hud_hint.position = Vector2(514, 12)
	hud_hint.text = "移动 WASD / 方向键 · F 互动 · C 换装 · M 导航"
	hud_hint.add_theme_color_override("font_color", Color("#c9dfc4"))
	layer.add_child(hud_hint)
	hud_hint.position = Vector2(24, 48)
	hud_hint.add_theme_font_size_override("font_size", 16)
	hud_day = Label.new()
	hud_day.position = Vector2(400, 10)
	hud_day.add_theme_color_override("font_color", Color("fff3d5"))
	hud_day.add_theme_font_size_override("font_size", 19)
	layer.add_child(hud_day)
	hud_tool_icon = TextureRect.new()
	hud_tool_icon.position = Vector2(1088, 2)
	hud_tool_icon.size = Vector2(48, 38)
	hud_tool_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(hud_tool_icon)
	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(22, 574)
	status_panel.size = Vector2(760, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff3d7", 0.94)
	style.border_color = Color("#6e503c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	status_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(status_panel)
	hud_status = Label.new()
	hud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_status.add_theme_color_override("font_color", Color("#483b34"))
	status_panel.add_child(hud_status)


func _update_location() -> void:
	if hud_location != null:
		hud_location.text = "花溪农场 · %s" % _location_name()


func _location_name() -> String:
	if current_map_id == "farm_outdoor": return "露天农场"
	if current_map_id == "farmhouse_interior": return "农舍内景"
	if current_map_id == "general_store_interior": return "杂货店内景"
	if current_map_id == "clinic_interior": return "诊所内景"
	if current_map_id == "cafe_interior": return "咖啡馆内景"
	return "花溪镇广场"


func _interaction_name(target: String) -> String:
	var names := {"farmhouse_interior": "农舍门", "general_store_interior": "杂货店门", "clinic_interior": "诊所门", "cafe_interior": "咖啡馆门", "shipping_box": "出货箱", "well": "水井", "notice_board": "公告板", "bed": "床铺", "chest": "储物箱", "fireplace": "壁炉", "shop_counter": "杂货店柜台", "clinic_counter": "诊所柜台", "cafe_counter": "咖啡馆柜台"}
	return str(names.get(target, "设施"))


func _set_status(message: String) -> void:
	if hud_status != null:
		hud_status.text = "  " + message


func _on_customization_confirmed(data: Dictionary) -> void:
	player.set_customization(data)
	creator.close()
	_set_status("角色已创建。沿粉色出口前往城镇，或按 C 随时重新编辑外观。")
	_save_game()


func _farm_action() -> void:
	if moving: return
	if energy < 2:
		_set_status("体力不足，回家休息或从背包吃一份作物。")
		return
	if current_map_id != "farm_outdoor":
		_set_status("耕种工具只能在农场户外使用。")
		return
	var target_cell := player_cell + _facing_delta(player.facing)
	if not navigation.is_in_bounds(current_map_id, target_cell):
		_set_status("面前没有可操作的土地。")
		return
	player.set_pose(player.facing, "use")
	var result: Dictionary
	match current_tool:
		"hoe": result = farm.till(target_cell)
		"seed": result = farm.plant(target_cell, _current_seed_id())
		"water": result = farm.water(target_cell)
		"harvest": result = farm.harvest(target_cell)
		_: result = {"ok": false, "message": "未知工具"}
	if bool(result.get("ok", false)):
		energy -= 2
		_rebuild_world_collisions()
		var action := str(result.get("action", ""))
		match action:
			"till": _set_status("翻地完成。选择种子后按 E 播种。")
			"plant": _set_status("播下%s；每日浇水后会成长。" % _seed_name(_current_seed_id()))
			"water": _set_status("浇水完成。按 N 结束当天。")
			"harvest": _set_status("收获%s，前往出货箱站位按 F 出售。" % _seed_name(str(result.get("item_id", "parsnip"))))
	else:
		_set_status("这种作物不适合当前季节，请在背包查看种植季节。" if str(result.get("code", "")) == "wrong_season" else _farm_error(str(result.get("code", ""))))
	world.queue_redraw()
	_update_farm_hud()
	_save_game()


func _advance_day(_is_raining: bool) -> void:
	var result: Dictionary = farm.advance_day(Calendar.weather(farm.day) == "雨")
	if bool(result.get("ok", false)):
		clock_minutes = 360
		clock_elapsed = 0.0
		energy = 100
		_change_map("farm_outdoor", navigation.get_spawn("farm_outdoor"))
		var event := Calendar.festival(farm.day)
		_set_status("%s，%s。%s%s" % [Calendar.label(farm.day), Calendar.weather(farm.day), "今日%s：去城镇公告板参加。" % event.name if not event.is_empty() else "新的一天开始了。", " 换季清理了 %d 格过季作物。" % result.expired_cells.size() if not result.expired_cells.is_empty() else ""])
		world.queue_redraw()
		_update_farm_hud()
		_save_game()


func _facing_delta(facing: String) -> Vector2i:
	match facing:
		"left": return Vector2i.LEFT
		"right": return Vector2i.RIGHT
		"up": return Vector2i.UP
		_: return Vector2i.DOWN


func _current_seed_id() -> String:
	return str(current_seed_ids[current_seed_index])


func _tool_name() -> String:
	return {"hoe": "锄头", "seed": "种子", "water": "浇水壶", "harvest": "收获"}.get(current_tool, "工具")


func _seed_name(seed_id: String) -> String:
	return {"parsnip": "防风草", "turnip": "芜菁", "tomato": "番茄", "pumpkin": "南瓜"}.get(seed_id, seed_id)


func _farm_error(code: String) -> String:
	return {"not_tillable": "这里不是地图标注的可耕种土地。", "already_tilled": "这格已经翻过地了。", "not_tilled": "先用锄头翻地。", "occupied": "这格已经种了作物。", "out_of_seeds": "这种种子用完了，按 Q 换一种。", "already_watered": "今天已经浇过水。", "not_mature": "作物尚未成熟。", "empty": "这里没有可以收获的作物。"}.get(code, "现在不能这样操作。")


func _update_farm_hud() -> void:
	if hud_hint == null or farm == null:
		return
	if hud_day != null:
		hud_day.text = "%s  %02d:%02d  %s · %d 金 · 体力 %d" % [Calendar.label(farm.day), clock_minutes / 60, clock_minutes % 60, Calendar.weather(farm.day), farm.gold, energy]
	hud_hint.text = "[%s] 1锄 2种 3水 4收 · %s×%d · Q换种 E使用 F互动 · Tab日历 I背包 R居民 N休息 F5保存" % [_tool_name(), _seed_name(_current_seed_id()), farm.get_seed_count(_current_seed_id())]
	_update_tool_icon()


func _update_tool_icon() -> void:
	if hud_tool_icon == null:
		return
	var source_size := TOOLS_ART.get_size()
	var cell_width := source_size.x / 4.0
	var cell_height := source_size.y / 2.0
	var indices := {"water": Vector2i(0, 0), "hoe": Vector2i(1, 0), "harvest": Vector2i(0, 1), "seed": Vector2i(1 + current_seed_index, 1)}
	var index: Vector2i = Vector2i(indices.get(current_tool, Vector2i(1, 0)))
	index.x = mini(index.x, 3)
	var atlas := AtlasTexture.new()
	atlas.atlas = TOOLS_ART
	atlas.region = Rect2(Vector2(index) * Vector2(cell_width, cell_height), Vector2(cell_width, cell_height))
	hud_tool_icon.texture = atlas


func _on_farm_cell_changed(_cell: Vector2i, _state: Dictionary) -> void:
	if world != null:
		world.queue_redraw()


func _on_farm_inventory_changed(_kind: String, _id: String, _amount: int) -> void:
	_update_farm_hud()


func _on_farm_gold_changed(_total: int, _delta: int) -> void:
	_update_farm_hud()


func _on_farm_day_advanced(_day: int, _is_raining: bool, _result: Dictionary) -> void:
	_update_farm_hud()

func _ask_sleep() -> void:
	if moving: return
	if current_map_id not in ["farm_outdoor", "farmhouse_interior"]:
		_set_status("请回农场或农舍休息。午夜会自动回家。")
		return
	life_panel.open("休息到明天？")
	life_panel.paragraph("今天是%s。休息会结算已浇水作物的生长并恢复体力。\n明日天气：%s。换季后不适合新季节的作物会被清理。" % [Calendar.label(farm.day), Calendar.weather(farm.day + 1)])
	life_panel.action("结束今天并保存", func():
		life_panel.close()
		_advance_day(false))

func _open_calendar(month_day := -1) -> void:
	var shown_day: int = farm.day if month_day < 1 else month_day
	life_panel.open("花溪日历 · " + Calendar.label(shown_day))
	var date := Calendar.date(shown_day)
	life_panel.paragraph("每季 28 天 · 雨天自动浇水 · 冬季休耕\n今日天气：%s，明日：%s。节日全天在镇中心公告板参加。" % [Calendar.weather(farm.day), Calendar.weather(farm.day + 1)])
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	life_panel.content.add_child(grid)
	for weekday in Calendar.WEEKDAYS:
		var title := Label.new()
		title.text = "周" + weekday
		title.add_theme_color_override("font_color", Color("483b34"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(title)
	for number in range(1, 29):
		var absolute_day: int = shown_day - int(date.day) + number
		var event := Calendar.festival(absolute_day)
		var button := Button.new()
		button.custom_minimum_size = Vector2(93, 46)
		button.text = "%d%s" % [number, " · 今天" if absolute_day == farm.day else ""]
		if not event.is_empty(): button.text += "\n节日"
		for person in VillageScript.PEOPLE.values():
			if (absolute_day - 1) % 112 + 1 == person.birthday: button.text += "\n生日"
		button.pressed.connect(_open_date.bind(absolute_day))
		grid.add_child(button)
	for event in Calendar.FESTIVALS:
		if event.season == date.season:
			life_panel.paragraph("%s%d日 · %s：%s。" % [Calendar.SEASONS[event.season], event.day, event.name, event.activity])
	if shown_day > 28: life_panel.action("上一季", _open_calendar.bind(maxi(1, shown_day - 28)))
	life_panel.action("下一季", _open_calendar.bind(shown_day + 28))

func _open_date(day: int) -> void:
	life_panel.open(Calendar.label(day))
	life_panel.paragraph("天气：" + Calendar.weather(day))
	var event := Calendar.festival(day)
	if not event.is_empty():
		life_panel.paragraph("%s\n%s。地点：花溪镇公告板。奖励 %d 金币与全体友好度。" % [event.name, event.activity, event.reward])
	for person in VillageScript.PEOPLE.values():
		if (day - 1) % 112 + 1 == person.birthday:
			life_panel.paragraph("%s的生日！当天送礼获得三倍友好度。" % person.name)
	life_panel.action("返回月历", _open_calendar)

func _open_inventory() -> void:
	life_panel.open("农场背包 · %d 金币" % farm.gold)
	life_panel.paragraph("收获的作物可以出货、送礼、参加节日，或食用恢复 20 点体力。")
	for item in current_seed_ids:
		var crop: Dictionary = farm.get_crop_definition(item)
		var seasons: Array[String] = []
		for season in crop.seasons: seasons.append(Calendar.SEASONS[season])
		life_panel.paragraph("%s · 种子 %d / 收获 %d\n%s季种植 · %d 天成熟 · 售价 %d 金币%s" % [crop.label, farm.get_seed_count(item), farm.get_harvest_count(item), "、".join(seasons), crop.grow_days, crop.sell_price, " · 采收后 3 天再结果" if crop.has("regrow") else ""])
		if farm.get_harvest_count(item) > 0: life_panel.action("食用一份" + crop.label, _eat.bind(item))

func _eat(item: String) -> void:
	if energy >= 100:
		life_panel.paragraph("现在体力充足。")
		return
	if farm.get_harvest_count(item) <= 0: return
	farm.harvest_inventory[item] -= 1
	energy = mini(100, energy + 20)
	_update_farm_hud()
	_save_game()
	_open_inventory()

func _open_people() -> void:
	life_panel.open("花溪居民")
	life_panel.paragraph("每天聊天 +20；每天可送一份作物。喜爱礼物 +60，其他作物 +25，生日礼物三倍。靠近居民按 F 聊天，G 送礼。")
	for actor in VillageScript.PEOPLE:
		var person: Dictionary = VillageScript.PEOPLE[actor]
		var relation: Dictionary = village.bond(actor)
		life_panel.paragraph("%s · %s · %d / 1000\n生日 %s · 喜爱%s\n今天：%s / %s" % [person.name, person.job, relation.points, Calendar.label(person.birthday), _seed_name(person.likes), "已聊天" if relation.talk_day == farm.day else "未聊天", "已送礼" if relation.gift_day == farm.day else "未送礼"])

func _open_dialogue(actor: String) -> void:
	life_panel.open("和居民聊聊")
	life_panel.paragraph(village.talk(actor, farm.day))
	life_panel.action("送一份农场礼物", _open_gifts.bind(actor))
	_save_game()

func _open_gifts(actor: String) -> void:
	if actor.is_empty():
		_set_status("请靠近一位居民后再送礼。")
		return
	life_panel.open("送给" + str(VillageScript.PEOPLE[actor].name))
	life_panel.paragraph("每天可以送一份作物，礼物会从背包扣除。")
	for item in current_seed_ids:
		if farm.get_harvest_count(item) > 0:
			life_panel.action("%s ×%d" % [_seed_name(item), farm.get_harvest_count(item)], _give_gift.bind(actor, item))

func _give_gift(actor: String, item: String) -> void:
	var message: String = village.gift(actor, item, farm)
	life_panel.open("居民的回应")
	life_panel.paragraph(message)
	_update_farm_hud()
	_save_game()

func _open_shop() -> void:
	life_panel.open("阿谷的种子铺 · %d 金币" % farm.gold)
	life_panel.paragraph("种子全年出售，请按季节播种；可在背包查看生长天数。")
	for item in current_seed_ids:
		var crop: Dictionary = farm.get_crop_definition(item)
		life_panel.action("买一包%s · %d 金币（已有 %d）" % [crop.label, crop.seed_price, farm.get_seed_count(item)], _buy_seed.bind(item))

func _buy_seed(item: String) -> void:
	var result: Dictionary = farm.buy_seed(item)
	_open_shop()
	life_panel.paragraph("购买成功。" if result.ok else result.message)
	_update_farm_hud()
	_save_game()

func _open_festival() -> void:
	life_panel.open("花溪镇公告板")
	var event := Calendar.festival(farm.day)
	if event.is_empty():
		life_panel.paragraph("今天没有节日。每一季我们都会相聚，带上你亲手种的收获吧。")
		life_panel.action("查看日历", _open_calendar)
		return
	life_panel.paragraph("%s\n\n%s。\n奖励 %d 金币，居民友好度 +40。每年每场活动只可领奖一次。" % [event.name, event.activity, event.reward])
	life_panel.action("参加活动 / 领取奖励", _join_festival)

func _join_festival() -> void:
	if current_map_id != "town_square": return
	life_panel.open("节日活动")
	life_panel.paragraph(village.join_festival(farm))
	_update_farm_hud()
	_save_game()

func _save_game() -> bool:
	if not autosave_enabled: return false
	var data := {"version": 1, "farm": farm.snapshot(), "village": village.snapshot(), "map": current_map_id, "cell": [player_cell.x, player_cell.y], "appearance": player.get_customization(), "clock": clock_minutes, "energy": energy}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null: return _save_failure()
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return _save_failure()
	if FileAccess.file_exists(save_path) and _valid_save(_read_save(save_path)):
		if DirAccess.copy_absolute(save_path, save_path + ".bak") != OK: return _save_failure()
	if DirAccess.rename_absolute(save_path + ".tmp", save_path) != OK: return _save_failure()
	return true

func _save_failure() -> bool:
	_set_status("保存失败，进度仍在当前游戏中。请检查磁盘空间或权限，再按 F5 保存。")
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not autosave_enabled or _save_game(): get_tree().quit()

func _load_game() -> void:
	if not FileAccess.file_exists(save_path): return
	var data = _read_save(save_path)
	if not _valid_save(data):
		data = _read_save(save_path + ".bak") if FileAccess.file_exists(save_path + ".bak") else null
	if not _valid_save(data):
		autosave_enabled = false
		push_warning("存档无法读取，已保留原文件并停用自动覆盖。")
		return
	farm.restore(data.farm)
	village.restore(data.village)
	clock_minutes = clampi(int(data.get("clock", 360)), 360, 1430)
	energy = clampi(int(data.get("energy", 100)), 0, 100)
	player.set_customization(data.get("appearance", {}))
	_change_map(str(data.get("map", "farm_outdoor")), _as_cell(data.get("cell", [17, 16])))

func _read_save(path: String):
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data

func _valid_save(data) -> bool:
	if not data is Dictionary or not _save_number(data.get("version")) or int(data.version) != 1: return false
	if not data.get("farm") is Dictionary or not data.get("village") is Dictionary: return false
	var saved_farm: Dictionary = data.farm
	if not _save_number(saved_farm.get("day")) or not _save_number(saved_farm.get("gold")): return false
	if not _save_number(data.get("clock")) or not _save_number(data.get("energy")): return false
	if not saved_farm.get("plots") is Array or not saved_farm.get("seeds") is Dictionary or not saved_farm.get("harvest") is Dictionary: return false
	for inventory in [saved_farm.seeds, saved_farm.harvest]:
		for item in inventory:
			if not farm.crop_definitions.has(item) or not _save_number(inventory[item]): return false
	for plot in saved_farm.plots:
		if not plot is Dictionary or not plot.get("state") is Dictionary or not plot.has("x") or not plot.has("y"): return false
		if not _save_number(plot.x) or not _save_number(plot.y) or not _save_number(plot.state.get("growth")): return false
		if not plot.state.get("seed") is String: return false
		for flag in ["tilled", "watered", "mature"]:
			if not plot.state.get(flag) is bool: return false
		if str(plot.state.get("seed", "")) != "" and not farm.crop_definitions.has(str(plot.state.seed)): return false
	for key in ["bonds", "visits", "claimed"]:
		if not data.village.get(key) is Dictionary: return false
	for relation in data.village.bonds.values():
		if not relation is Dictionary or not relation.has_all(["points", "talk_day", "gift_day"]): return false
		for key in ["points", "talk_day", "gift_day"]:
			if not _save_number(relation[key]): return false
	for visits in data.village.visits.values():
		if not visits is Array: return false
	return navigation.has_map(str(data.get("map", ""))) and data.get("cell") is Array and data.cell.size() == 2 and _save_number(data.cell[0]) and _save_number(data.cell[1]) and data.get("appearance") is Dictionary

func _save_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
