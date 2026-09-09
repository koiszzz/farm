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
const InventoryStateScript = preload("res://scripts/inventory_state.gd")
const InventoryPanelScript = preload("res://scripts/inventory_panel.gd")
const SpriteAtlasScript = preload("res://scripts/sprite_atlas.gd")
const CenterLightTransitionScript = preload("res://scripts/center_light_transition.gd")
var village = VillageScript.new()
var life_panel
var inventory_panel
var inventory_state = InventoryStateScript.new()
var clock_minutes := 360
var clock_elapsed := 0.0
var energy := 100
var autosave_enabled := true
var save_path := "user://farm_life_v1.json"
var hud_day: Label
const Homestead = preload("res://scripts/homestead_life.gd")
var homestead = Homestead.new()
var pet
var feedback
var scenery
var ambience
var farm_audio
var tool_buttons: Array[Button] = []
const TOOL_IDS := ["hoe", "seed", "water", "harvest", "scythe", "fish"]
const TOOLS_ART: Texture2D = preload("res://assets/art/source_generated/mvp_tools_and_seeds_source_v1.png")
const INVENTORY_ICONS := {
	"fish_tool": preload("res://assets/art/runtime_generated/inventory_icons/fishing_rod_v1.png"),
	"wood": preload("res://assets/art/runtime_generated/inventory_icons/wood_v1.png"),
	"stone": preload("res://assets/art/runtime_generated/inventory_icons/stone_v1.png"),
	"berry": preload("res://assets/art/runtime_generated/inventory_icons/wild_berry_v1.png"),
	"mushroom": preload("res://assets/art/runtime_generated/inventory_icons/mushroom_v1.png"),
	"fish_food": preload("res://assets/art/runtime_generated/inventory_icons/creek_fish_v1.png"),
}
const NPC_ART := {
	"florist": preload("res://assets/art/runtime_generated/florist_walk_v2.png"),
	"shopkeeper": preload("res://assets/art/runtime_generated/shopkeeper_walk_v2.png"),
	"fisherman": preload("res://assets/art/runtime_generated/fisherman_walk_v2.png"),
}
const NPC_IDLE_ART := {
	"florist": preload("res://assets/art/runtime_generated/florist_idle_v1.png"),
	"shopkeeper": preload("res://assets/art/runtime_generated/shopkeeper_idle_v1.png"),
	"fisherman": preload("res://assets/art/runtime_generated/fisherman_idle_v1.png"),
}

const MOVE_SECONDS := 0.25
const WALK_FRAME_SECONDS := 0.055
const STREAM_COLLISION_POOL_SIZE := 512

var navigation: MapData
var world: WorldRenderer
var player: AvatarRenderer
var player_body: CharacterBody2D
var game_camera: Camera2D
var scene_transition: CenterLightTransitionScript
var collision_root: StaticBody2D
var creator: CharacterCreator
var farm = null
var current_map_id := "valley_world"
var continuous_world_enabled := true
var force_continuous_world_for_qa := false
var collision_stream_center := Vector2i(-999, -999)
var collision_stream_bounds := Rect2i()
var collision_stream_map_id := ""
var active_collision_cells: Dictionary = {}
var collision_shape_pool: Array[CollisionShape2D] = []
var streamed_collision_shape: RectangleShape2D
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1536, 864), Vector2i(1920, 1080)]
var display_size_index := 1
var display_config_path := "user://display.cfg"
var display_apply_error := ""
var current_tool := "hoe"
var current_seed_index := 0
var current_seed_ids := ["parsnip", "turnip", "cauliflower", "potato", "green_bean", "strawberry", "tomato", "blueberry", "corn", "pepper", "melon", "pumpkin", "cranberry", "eggplant", "yam", "bok_choy", "powdermelon", "winter_root", "snow_yam", "crystal_berry"]
var player_cell := Vector2i.ZERO
var pending_cell := Vector2i.ZERO
var move_target := Vector2.ZERO
var move_from_cell := Vector2i.ZERO
var move_origin := Vector2.ZERO
var moving := false
var queued_use := ""
var queued_use_cell := Vector2i(-1, -1)
var transition_lock_frames := 0
var walk_phase := false
var walk_animation_elapsed := 0.0
var hud_status: Label
var hud_location: Label
var hud_hint: Label
var hud_tool_icon: TextureRect
var hud_hotbar_info: Label
var hud_hotbar_hover_index := -1
var npcs: Dictionary = {}
var resident_schedule := ""
var actor_action = preload("res://scripts/actor_action.gd").new()
var entering_door := false
var occlusion_shadow: Sprite2D
var fish_count := 0
var fishing_stage := ""
var fishing_elapsed := 0.0


func _ready() -> void:
	get_tree().auto_accept_quit = false
	_load_display_preferences()
	navigation = MapDataScript.new()
	if not navigation.load_data():
		push_error("Failed to load navigation data: %s" % navigation.load_errors)
		return
	navigation.build_contiguous_world()
	if not autosave_enabled and not force_continuous_world_for_qa:
		continuous_world_enabled = false
	current_map_id = "valley_world" if continuous_world_enabled else "farm_outdoor"
	world = WorldRendererScript.new()
	add_child(world)
	collision_root = StaticBody2D.new()
	collision_root.name = "WorldColliders"
	collision_root.collision_layer = 1
	collision_root.collision_mask = 0
	add_child(collision_root)
	streamed_collision_shape = RectangleShape2D.new()
	streamed_collision_shape.size = Vector2.ONE * (WorldRenderer.TILE_SIZE - 2.0)
	_prime_collision_pool()
	farm = FarmStateScript.new()
	if not farm.bind(navigation, current_map_id).get("ok", false):
		push_error("Failed to bind farm state.")
		return
	farm.cell_changed.connect(_on_farm_cell_changed)
	farm.inventory_changed.connect(_on_farm_inventory_changed)
	farm.gold_changed.connect(_on_farm_gold_changed)
	farm.day_advanced.connect(_on_farm_day_advanced)
	world.set_farm_state(farm)
	pet = preload("res://scripts/companion_actor.gd").new()
	pet.model = homestead
	pet.navigation = navigation
	pet.farm = farm
	add_child(pet)
	pet.rebuild_grid()
	scenery = preload("res://scripts/homestead_scenery.gd").new()
	scenery.game = self
	add_child(scenery)
	feedback = preload("res://scripts/world_feedback.gd").new()
	feedback.game = self
	add_child(feedback)
	ambience = preload("res://scripts/weather_ambience.gd").new()
	ambience.game = self
	add_child(ambience)
	farm_audio = preload("res://scripts/farm_audio.gd").new()
	add_child(farm_audio)
	player = AvatarRendererScript.new()
	player.pixel_scale = 0.13
	player.z_index = 0
	player_body = CharacterBody2D.new()
	player_body.name = "PlayerBody"
	player_body.collision_layer = 2
	player_body.collision_mask = 1
	add_child(player_body)
	player_body.add_child(player)
	occlusion_shadow = Sprite2D.new()
	occlusion_shadow.centered = false
	occlusion_shadow.region_enabled = true
	occlusion_shadow.region_filter_clip_enabled = true
	occlusion_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	occlusion_shadow.z_index = 4090
	var highlight_material := ShaderMaterial.new()
	highlight_material.shader = preload("res://assets/art/character_creator/occluded_avatar.gdshader")
	occlusion_shadow.material = highlight_material
	add_child(occlusion_shadow)
	var player_shape := CollisionShape2D.new()
	var player_footprint := RectangleShape2D.new()
	player_footprint.size = Vector2(18, 14)
	player_shape.shape = player_footprint
	player_shape.position = Vector2.ZERO
	player_body.add_child(player_shape)
	game_camera = Camera2D.new()
	game_camera.position_smoothing_enabled = true
	game_camera.position_smoothing_speed = 10.0
	player_body.add_child(game_camera)
	game_camera.make_current()
	_sync_inventory()
	inventory_state.initialize(_inventory_items().keys(), _default_hotbar_items())
	_build_hud()
	scene_transition = CenterLightTransitionScript.new()
	add_child(scene_transition)
	_change_map(current_map_id, navigation.get_spawn(current_map_id))
	creator = CharacterCreatorScript.new()
	add_child(creator)
	creator.customization_confirmed.connect(_on_customization_confirmed)
	life_panel = LifePanelScript.new()
	add_child(life_panel)
	inventory_panel = InventoryPanelScript.new()
	add_child(inventory_panel)
	inventory_panel.layout_changed.connect(_on_inventory_layout_changed)
	if autosave_enabled:
		_load_game()
	_update_farm_hud()
	_set_status("WASD 移动 · E 使用工具 · F 互动 · Tab 日历 · I 背包 · R 居民。农舍或农场按 N 休息。")
	if not autosave_enabled and FileAccess.file_exists(save_path):
		_set_status("存档损坏且备份不可用；已保留原文件并停止自动覆盖。当前为临时游玩。")


func _process(_delta: float) -> void:
	if player_body == null: return
	player_body.z_index = int(player_body.position.y)
	for state in npcs.values(): state.node.z_index = int(state.node.position.y)
	var body: Sprite2D = player._body
	occlusion_shadow.texture = body.texture
	occlusion_shadow.region_rect = body.region_rect
	occlusion_shadow.transform = body.global_transform
	occlusion_shadow.visible = player.visible and not entering_door and world.is_actor_occluded(player_body.position)


func _physics_process(delta: float) -> void:
	if navigation == null or creator == null or creator.visible:
		return
	if entering_door: return
	if life_panel != null and life_panel.visible:
		return
	if pet.visible: pet.tick(delta, player_body.position, clock_minutes)
	clock_elapsed += delta
	if clock_elapsed >= 7.0:
		clock_elapsed -= 7.0
		clock_minutes += 10
		if _resident_signature() != resident_schedule: _spawn_map_npcs()
		_update_farm_hud()
		if clock_minutes >= 1440:
			_advance_day(false)
			return
	if transition_lock_frames > 0:
		transition_lock_frames -= 1
		return
	if fishing_stage in ["waiting", "bite"]:
		fishing_elapsed += delta
		player.set_pose(player.facing, "fish")
		player.action_progress = 0.65
		if fishing_stage == "waiting" and fishing_elapsed >= 2.0:
			fishing_stage = "bite"
			fishing_elapsed = 0.0
			_set_status("鱼咬钩了！现在按 E 提竿！")
		elif fishing_stage == "bite" and fishing_elapsed >= 1.4:
			_cancel_fishing()
			_set_status("鱼游走了，再试一次。")
		_update_npcs(delta)
		return
	if not actor_action.kind.is_empty():
		actor_action.advance(delta)
		player.action_progress = actor_action.progress()
		player.set_pose(player.facing, actor_action.kind if not actor_action.kind.is_empty() else "idle")
		_update_npcs(delta)
		return
	_update_player_movement(delta)
	_update_npcs(delta)


func _unhandled_input(event: InputEvent) -> void:
	if inventory_panel != null and inventory_panel.visible:
		if event is InputEventKey:
			inventory_panel.handle_key(event)
			if event.pressed: get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		feedback.hovered = _cell_from_world_position(get_viewport_transform().affine_inverse() * event.position)
		feedback.use_mouse = true
		return
	if event is InputEventMouseButton and event.pressed:
		_handle_mouse(event)
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	feedback.use_mouse = false
	if entering_door: return
	if not fishing_stage.is_empty():
		if event.keycode == KEY_ESCAPE:
			_cancel_fishing()
		elif event.keycode == KEY_E and fishing_stage == "bite":
			fishing_stage = "reeling"
			actor_action.start("fish", _catch_fish, _cancel_fishing)
		get_viewport().set_input_as_handled()
		return
	if life_panel != null and life_panel.visible:
		if event.keycode == KEY_ESCAPE: life_panel.close()
		get_viewport().set_input_as_handled()
		return
	if not actor_action.kind.is_empty():
		get_viewport().set_input_as_handled()
		return
	if not creator.visible and not moving:
		match event.keycode:
			KEY_TAB: _open_calendar()
			KEY_I: _open_inventory()
			KEY_R: _open_people()
			KEY_P: _open_pet()
			KEY_M: _open_world_map()
			KEY_F10: _open_display_settings()
			KEY_F11: _toggle_fullscreen()
			KEY_G: _open_gifts(_nearby_npc_actor())
			KEY_F5: _set_status("存档已保存。" if _save_game() else "存档失败，请检查磁盘空间。")
		if event.keycode in [KEY_TAB, KEY_I, KEY_R, KEY_P, KEY_M, KEY_G, KEY_F5, KEY_F10, KEY_F11]:
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
	elif event.keycode == KEY_F3:
		world.show_routes = not world.show_routes
		world.queue_redraw()
		_set_status("导航标注：%s" % ("已显示" if world.show_routes else "已隐藏"))
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_E:
		_farm_action()
		get_viewport().set_input_as_handled()
		return
	var hotbar_index := _hotbar_index_for_key(event.keycode)
	if hotbar_index >= 0:
		_use_hotbar(hotbar_index)
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


func _select_tool(index: int) -> void:
	if entering_door or not actor_action.kind.is_empty() or not fishing_stage.is_empty() or (creator != null and creator.visible) or (life_panel != null and life_panel.visible):
		_update_farm_hud()
		return
	current_tool = TOOL_IDS[posmod(index, TOOL_IDS.size())]
	farm_audio.play("select")
	_update_farm_hud()


func _hotbar_index_for_key(keycode: int) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9: return int(keycode - KEY_1)
	if keycode == KEY_0: return 9
	return -1


func _use_hotbar(index: int) -> void:
	if index < 0 or index >= InventoryStateScript.HOTBAR_SIZE: return
	inventory_state.select_hotbar(index)
	var item_key := str(inventory_state.hotbar[index])
	if item_key.is_empty():
		_set_status("快捷栏第 %s 格是空的；打开背包可设置任意物品。" % (str(index + 1) if index < 9 else "0"))
		_update_farm_hud()
		return
	var item: Dictionary = _inventory_items().get(item_key, {})
	match str(item.get("kind", "item")):
		"tool":
			current_tool = str(item.get("tool_id", "hoe"))
			farm_audio.play("select")
			_update_farm_hud()
			_farm_action()
		"food": _eat_inventory_item(item_key)
		_:
			_set_status("%s不是工具或食物，不能直接使用。" % str(item.get("name", "这个物品")))
			_update_farm_hud()

func _handle_mouse(event: InputEventMouseButton) -> void:
	if entering_door or creator.visible or life_panel.visible or (inventory_panel != null and inventory_panel.visible): return
	if not actor_action.kind.is_empty(): return
	if not fishing_stage.is_empty():
		if event.button_index == MOUSE_BUTTON_LEFT and fishing_stage == "bite":
			fishing_stage = "reeling"
			actor_action.start("fish", _catch_fish, _cancel_fishing)
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		inventory_state.select_hotbar(inventory_state.selected_hotbar + direction)
		var item: Dictionary = _inventory_items().get(str(inventory_state.hotbar[inventory_state.selected_hotbar]), {})
		if str(item.get("kind", "")) == "tool": current_tool = str(item.get("tool_id", current_tool))
		farm_audio.play("select")
		_update_farm_hud()
		get_viewport().set_input_as_handled()
		return
	var cell := _cell_from_world_position(get_viewport_transform().affine_inverse() * event.position)
	var direction := cell - (pending_cell if moving else player_cell)
	if absi(direction.x) + absi(direction.y) > 1:
		_set_status("走近一点，对相邻格子使用工具或互动。")
		return
	if moving and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		queued_use = "tool" if event.button_index == MOUSE_BUTTON_LEFT else "interact"
		queued_use_cell = cell
		get_viewport().set_input_as_handled()
		return
	if direction != Vector2i.ZERO: player.set_pose(_facing_for(direction), "idle")
	if event.button_index == MOUSE_BUTTON_LEFT and direction != Vector2i.ZERO: _farm_action()
	elif event.button_index == MOUSE_BUTTON_RIGHT: _interact()
	get_viewport().set_input_as_handled()

func _tool_can_target(cell: Vector2i) -> bool:
	if current_tool == "fish": return navigation.get_cell_class(current_map_id, cell) == "water"
	if not _is_farm_area(cell): return false
	var plot: Dictionary = farm.get_cell_state(cell)
	if plot.is_empty(): return false
	match current_tool:
		"hoe": return not plot.get("tilled", false)
		"seed": return plot.get("tilled", false) and str(plot.get("seed", "")).is_empty() and farm.get_seed_count(_current_seed_id()) > 0
		"water": return plot.get("tilled", false) and not plot.get("watered", false) and homestead.water > 0
		"harvest", "scythe": return plot.get("mature", false)
	return false

func _pet_is_near() -> bool:
	return pet != null and pet.visible and pet.position.distance_to(player_body.position) < 52

func _nearby_pickup() -> Dictionary:
	for item in homestead.available(current_map_id, farm.day, navigation):
		var difference: Vector2i = item.cell - player_cell
		if absi(difference.x) + absi(difference.y) <= 1: return item
	return {}

func _context_text() -> String:
	var interaction := navigation.interaction_at(current_map_id, player_cell)
	if interaction.is_empty(): interaction = navigation.interaction_at(current_map_id, player_cell + _facing_delta(player.facing))
	if not interaction.is_empty(): return "F / 右键 · " + _interaction_name(str(interaction.get("target", "")))
	var item := _nearby_pickup()
	if not item.is_empty(): return "F 拾取" + str(Homestead.RESOURCE_NAMES[item.kind])
	if _pet_is_near(): return "P 麦麦在休息" if pet.sleeping else "F 摸摸麦麦 · P 照料"
	var actor := _nearby_npc_actor()
	if not actor.is_empty(): return "F 交谈 · G 送礼"
	return ""

func _collect_pickup(item: Dictionary) -> void:
	if not actor_action.kind.is_empty(): return
	actor_action.start("harvest", func():
		if homestead.collect(item, farm.day):
			farm_audio.play("harvest")
			feedback.burst(world.cell_center_to_screen(item.cell), "+1 " + str(Homestead.RESOURCE_NAMES[item.kind]))
			scenery.refresh()
			_sync_inventory()
			_update_farm_hud()
			_set_status("拾取了%s，已放入背包。" % Homestead.RESOURCE_NAMES[item.kind])
			_save_game())
	player.set_pose(player.facing, "harvest")

func _pet_dog() -> void:
	if not _pet_is_near() or not actor_action.kind.is_empty(): return
	var direction: Vector2 = pet.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "pet")
	pet.affection = 1.2
	actor_action.start("pet", func():
		farm_audio.play("pet")
		_set_status(homestead.pet(farm.day))
		pet.affection = 1.5
		_save_game())

func _open_pet() -> void:
	life_panel.open("麦麦 · 农场伙伴")
	life_panel.paragraph("亲密度 %d / 1000 · %s\n每天抚摸 +20，喂食 +30。20:00 后回窝休息。\n今天：%s / %s" % [homestead.pet_points, "正在跟随你" if homestead.following else "在家等你", "已抚摸" if homestead.pet_day == farm.day else "还没抚摸", "已喂食" if homestead.fed_day == farm.day else "还没喂食"])
	if _pet_is_near():
		life_panel.action("摸摸麦麦", func(): life_panel.close(); _pet_dog())
		life_panel.action("喂一份野莓点心（已有 %d）" % homestead.resources.berry, func():
			var message: String = homestead.feed(farm.day)
			pet.affection = 1.5
			scenery.refresh()
			_sync_inventory()
			_update_farm_hud()
			_save_game()
			_open_pet()
			life_panel.paragraph(message))
	else: life_panel.paragraph("靠近麦麦后可以抚摸或喂食；它会在农场陪着你。")
	life_panel.action("回窝等我" if homestead.following else "跟我散步", func():
		homestead.following = not homestead.following
		_save_game()
		_open_pet())

func _open_service(kind: String) -> void:
	var clinic := kind == "clinic"
	life_panel.open("花溪诊所" if clinic else "花溪咖啡馆")
	life_panel.paragraph("坐下来休息片刻吧。当前体力 %d / 100，金币 %d。" % [energy, farm.gold])
	life_panel.action("治疗 · 30 金，恢复全部体力" if clinic else "热饮和点心 · 15 金，恢复 35 体力", func():
		var price := 30 if clinic else 15
		if energy >= 100:
			life_panel.paragraph("你现在精神很好，暂时不需要恢复。")
			return
		if farm.gold < price:
			life_panel.paragraph("金币不足，改天再来吧。")
			return
		farm.gold -= price
		energy = mini(100, energy + (100 if clinic else 35))
		_update_farm_hud()
		_save_game()
		_open_service(kind))

func _update_player_movement(delta: float) -> void:
	if moving:
		walk_animation_elapsed += delta
		var frame_index := int(floor(walk_animation_elapsed / WALK_FRAME_SECONDS)) % 2
		player.set_pose(player.facing, "walk_a" if frame_index == 0 else "walk_b")
		player.running = Input.is_key_pressed(KEY_SHIFT)
		var desired_position := player_body.position.move_toward(move_target, world.TILE_SIZE / MOVE_SECONDS * (1.65 if player.running else 1.0) * delta)
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
		player.advance_stride(motion.length())
		if player_body.position.distance_to(move_target) < 0.1:
			player_body.position = move_target
			player_cell = pending_cell
			moving = false
			_stream_world(false)
			_after_arrival()
			if not entering_door and not queued_use.is_empty():
				_perform_queued_use()
				return
			if transition_lock_frames == 0:
				_begin_move(_pressed_direction())
			if not moving:
				player.set_pose(player.facing, "idle")
		return
	_begin_move(_pressed_direction())


func _perform_queued_use() -> void:
	var kind := queued_use
	var target := queued_use_cell
	queued_use = ""
	queued_use_cell = Vector2i(-1, -1)
	if target != Vector2i(-1, -1):
		var direction := target - player_cell
		if absi(direction.x) + absi(direction.y) > 1: return
		if direction != Vector2i.ZERO: player.set_pose(_facing_for(direction), "idle")
	if kind == "tool": _farm_action()
	elif kind == "interact": _interact()

func _begin_move(direction: Vector2i) -> void:
	if entering_door or not fishing_stage.is_empty() or not actor_action.kind.is_empty(): return
	if direction == Vector2i.ZERO:
		return
	# Turning toward occupied soil must still work so the crop can be tended.
	player.set_pose(_facing_for(direction), "idle")
	var next_cell := player_cell + direction
	var crop_occupied: bool = _is_farm_area(next_cell) and farm.is_crop_occupied(next_cell)
	if not navigation.is_walkable(current_map_id, next_cell, crop_occupied):
		_set_status("前方有障碍物。")
		return
	move_from_cell = player_cell
	move_origin = player_body.position
	pending_cell = next_cell
	walk_phase = not walk_phase
	# Preserve the stride phase across adjacent cells.
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
		if current_map_id.ends_with("_interior"):
			_enter_door(str(exit.get("target", "farm_outdoor")), arrival, player_cell)
		else:
			_change_map(str(exit.get("target", "farm_outdoor")), arrival)
		return
	var interaction := navigation.interaction_at(current_map_id, player_cell)
	var target := str(interaction.get("target", ""))
	if target.ends_with("_interior") and navigation.has_map(target):
		_enter_door(target, navigation.get_spawn(target), player_cell)
		return
	if not interaction.is_empty():
		_set_status("站在交互点：按 F 使用 %s。" % _interaction_name(str(interaction.get("target", "设施"))))
	else:
		_set_status("%s · 沿道路探索，靠近设施或居民时会显示互动提示。" % _location_name())


func _interact() -> void:
	if entering_door or not actor_action.kind.is_empty(): return
	if moving:
		queued_use = "interact"
		queued_use_cell = Vector2i(-1, -1)
		return
	var interaction := navigation.interaction_at(current_map_id, player_cell)
	var door_cell := player_cell
	if interaction.is_empty():
		door_cell = player_cell + _facing_delta(player.facing)
		interaction = navigation.interaction_at(current_map_id, door_cell)
	if not interaction.is_empty():
		# Doorways and counters are precise authored tiles.  They win over a
		# nearby NPC so an NPC route can never make a building impossible to enter.
		player.set_pose(player.facing, "use")
		var target := str(interaction.get("target", ""))
		if target.ends_with("_interior") and navigation.has_map(target):
			_enter_door(target, navigation.get_spawn(target), door_cell)
			return
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
			"clinic_counter": _open_service("clinic")
			"cafe_counter": _open_service("cafe")
			"shipping_box":
				var shipping: Dictionary = farm.ship_all()
				var forage_earned: int = homestead.ship()
				farm.gold += forage_earned
				_sync_inventory()
				_set_status("出货箱：售出 %d 金币。当前金币 %d。" % [int(shipping.get("earned", 0)) + forage_earned, farm.gold])
				_update_farm_hud()
				_save_game()
			"well":
				homestead.water = Homestead.WATER_CAPACITY
				_update_farm_hud()
				_set_status("清凉的井水装满了浇水壶（24 / 24）。")
				feedback.burst(player_body.position, "补满水", Color("a8e5f1"))
				_save_game()
			"notice_board": _open_festival()
			_: _set_status("%s：该场景将在后续开放。" % _interaction_name(target))
		return
	var pickup := _nearby_pickup()
	if not pickup.is_empty():
		_collect_pickup(pickup)
		return
	if _pet_is_near():
		_pet_dog()
		return
	var nearby_npc := _nearby_npc_actor()
	if not nearby_npc.is_empty():
		player.set_pose(player.facing, "use")
		_open_dialogue(nearby_npc)
		return
	_set_status("靠近门口并面向门按 F 进入，或靠近居民按 F 交谈。")


func _enter_door(target: String, arrival: Vector2i, door_cell: Vector2i) -> void:
	if entering_door: return
	entering_door = true
	moving = false
	player.set_pose(player.facing, "idle")
	var leaving_interior := current_map_id.ends_with("_interior")
	if not leaving_interior:
		world.active_door = door_cell
		world.door_open = 0.0
		var door_tween := create_tween()
		door_tween.tween_method(_set_door_open, 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await door_tween.finished
	# Interior exits deliberately have no door-leaf animation. Both directions
	# are covered before swapping, then the new scene is revealed from its light.
	await scene_transition.play(_change_map.bind(target, arrival))
	world.active_door = Vector2i(-1, -1)
	world.door_open = 0.0
	world.queue_redraw()
	entering_door = false


func _set_door_open(value: float) -> void:
	world.door_open = value
	world.queue_redraw()


func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
	if continuous_world_enabled and next_map_id in ["farm_outdoor", "town_square", "riverside"]:
		next_cell = navigation.to_contiguous_world(next_map_id, next_cell)
		next_map_id = "valley_world"
	if not navigation.has_map(next_map_id):
		_set_status("未知地图：%s" % next_map_id)
		return
	actor_action.cancel()
	queued_use = ""
	queued_use_cell = Vector2i(-1, -1)
	if feedback != null: feedback.bursts.clear()
	fishing_stage = ""
	current_map_id = next_map_id
	var size := navigation.get_map_size(current_map_id)
	var map_size_px: Vector2 = Vector2(size) * WorldRenderer.TILE_SIZE
	world.configure(navigation, current_map_id, Vector2.ZERO)
	collision_stream_center = Vector2i(-999, -999)
	game_camera.limit_left = 0
	game_camera.limit_top = 44
	game_camera.limit_right = int(map_size_px.x)
	game_camera.limit_bottom = int(map_size_px.y)
	player_cell = next_cell if navigation.is_walkable(current_map_id, next_cell) else navigation.get_spawn(current_map_id)
	pending_cell = player_cell
	player_body.position = _avatar_position_for(player_cell)
	# Teleport first, then reset smoothing. Otherwise the centre-light reveal can
	# expose a frame interpolated from the previous map's unrelated coordinates.
	game_camera.reset_smoothing()
	move_from_cell = player_cell
	move_origin = player_body.position
	move_target = player_body.position
	moving = false
	transition_lock_frames = 1
	player.set_pose("down", "idle")
	_stream_world(true)
	_spawn_map_npcs()
	if pet != null:
		pet.home_cell = navigation.to_contiguous_world("farm_outdoor", Vector2i(21, 11)) if continuous_world_enabled else Vector2i(21, 11)
		pet.world_map_id = current_map_id
		pet.visible = current_map_id == "valley_world" or current_map_id == "farm_outdoor"
		pet.reset_home()
		pet.rebuild_grid()
		pet.tick(0, player_body.position, clock_minutes)
		scenery.refresh()
	_update_location()
	_update_farm_hud()
	_set_status("%s · WASD 行走，Shift 跑步；走到门口自动进入，F 与设施互动。" % _location_name())


func _rebuild_world_collisions() -> void:
	if collision_root == null:
		return
	var map_size := navigation.get_map_size(current_map_id)
	var bounds := Rect2i(Vector2i.ZERO, map_size)
	if current_map_id == "valley_world":
		bounds = Rect2i(player_cell - Vector2i(30, 20), Vector2i(61, 41)).intersection(bounds)
	var old_bounds := collision_stream_bounds
	if collision_stream_map_id != current_map_id:
		old_bounds = Rect2i()
		for cell_value in active_collision_cells.keys():
			_release_collision_cell(cell_value)
	for cell_value in active_collision_cells.keys():
		var cell: Vector2i = cell_value
		if not bounds.has_point(cell):
			_release_collision_cell(cell)
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if old_bounds.has_point(cell):
				continue
			_sync_collision_cell(cell)
	collision_stream_bounds = bounds
	collision_stream_map_id = current_map_id


func _prime_collision_pool() -> void:
	for index in STREAM_COLLISION_POOL_SIZE:
		var shape_node := CollisionShape2D.new()
		shape_node.name = "PooledObstacle_%d" % index
		shape_node.position = Vector2(-100000, -100000)
		shape_node.shape = streamed_collision_shape
		collision_root.add_child(shape_node)
		collision_shape_pool.append(shape_node)


func _sync_collision_cell(cell: Vector2i) -> void:
	var crop_occupied: bool = _is_farm_area(cell) and farm.is_crop_occupied(cell)
	var needs_collision := not navigation.is_walkable(current_map_id, cell, crop_occupied)
	if not needs_collision:
		if active_collision_cells.has(cell):
			_release_collision_cell(cell)
		return
	if active_collision_cells.has(cell):
		return
	var shape_node: CollisionShape2D
	if collision_shape_pool.is_empty():
		shape_node = CollisionShape2D.new()
		shape_node.shape = streamed_collision_shape
		collision_root.add_child(shape_node)
	else:
		shape_node = collision_shape_pool.pop_back()
	shape_node.name = "Obstacle_%d_%d" % [cell.x, cell.y]
	shape_node.position = world.cell_center_to_screen(cell)
	active_collision_cells[cell] = shape_node


func _release_collision_cell(cell: Vector2i) -> void:
	if not active_collision_cells.has(cell):
		return
	var stale_shape: CollisionShape2D = active_collision_cells[cell]
	# Recycle nodes in place. Removing and allocating hundreds of physics nodes
	# here used to block the main thread at every streaming boundary.
	stale_shape.name = "PooledObstacle_%d" % stale_shape.get_instance_id()
	stale_shape.position = Vector2(-100000, -100000)
	collision_shape_pool.append(stale_shape)
	active_collision_cells.erase(cell)

func _stream_world(force: bool) -> void:
	if world == null: return
	world.set_stream_center(player_cell, force)
	if force or current_map_id != "valley_world" or player_cell.distance_to(collision_stream_center) >= 7:
		collision_stream_center = player_cell
		_rebuild_world_collisions()


func _spawn_map_npcs() -> void:
	resident_schedule = _resident_signature()
	for state_value in npcs.values():
		var state: Dictionary = state_value
		if is_instance_valid(state.get("node")):
			state.node.queue_free()
	npcs.clear()
	for actor in VillageScript.PEOPLE:
		var activity_map: String = str(village.activity(actor, farm.day, clock_minutes).map)
		if current_map_id == "valley_world":
			if activity_map.ends_with("_interior"): continue
		elif activity_map != current_map_id: continue
		var route_map := activity_map if current_map_id == "valley_world" else current_map_id
		var checkpoints: Array[Vector2i] = navigation.get_npc_route(route_map, str(actor))
		if current_map_id == "valley_world":
			for index in checkpoints.size(): checkpoints[index] = navigation.to_contiguous_world(route_map, checkpoints[index])
		if checkpoints.is_empty():
			var actor_index: int = VillageScript.PEOPLE.keys().find(actor)
			var loops := {
				"town_square": [[Vector2i(8, 17), Vector2i(17, 17), Vector2i(17, 23), Vector2i(8, 23)], [Vector2i(22, 13), Vector2i(31, 13), Vector2i(31, 20), Vector2i(22, 20)], [Vector2i(34, 16), Vector2i(41, 16), Vector2i(41, 23), Vector2i(34, 23)]],
				"farm_outdoor": [[Vector2i(17, 12), Vector2i(24, 12), Vector2i(24, 17), Vector2i(17, 17)]],
				"riverside": [[Vector2i(14, 14), Vector2i(20, 14), Vector2i(20, 18), Vector2i(14, 18)]],
			}
			var choices: Array = loops.get(route_map, [[Vector2i(14, 10), Vector2i(21, 10), Vector2i(21, 14), Vector2i(14, 14)]])
			var candidates: Array = choices[actor_index % choices.size()].duplicate()
			if current_map_id == "valley_world":
				for index in candidates.size(): candidates[index] = navigation.to_contiguous_world(route_map, candidates[index])
			for candidate in candidates:
				if navigation.is_walkable(current_map_id, candidate): checkpoints.append(candidate)
		var route: Array[Vector2i] = _npc_walk_route(checkpoints)
		if route.is_empty():
			continue
		var npc = ArtActorScript.new()
		npc.z_index = 3
		npc.configure(NPC_ART.get(actor, NPC_ART.get("florist")), NPC_IDLE_ART.get(actor, NPC_IDLE_ART.get("florist")), 0.13)
		var clothes_tints := [Color.WHITE, Color("e6c6a5"), Color("b9d2de"), Color("e3b7c2"), Color("c6d8a7"), Color("d7c1e6"), Color("f2d493"), Color("b6d8cf"), Color("e4bea2"), Color("c7c9e4")]
		npc.modulate = clothes_tints[VillageScript.PEOPLE.keys().find(actor) % clothes_tints.size()]
		npc.set_pose("down", "idle")
		var start_index := mini(7, route.size() - 1) if str(actor) == "florist" else 0
		npc.position = _avatar_position_for(route[start_index]) + Vector2(0, 1)
		add_child(npc)
		npcs[actor] = {"node": npc, "route": route, "index": start_index, "timer": 0.0}

func _resident_signature() -> String:
	var signature := ""
	for actor in VillageScript.PEOPLE: signature += actor + str(village.activity(actor, farm.day, clock_minutes).map)
	return signature


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
			var toward: Vector2 = player_body.position - npc.position
			npc.set_pose(_facing_for(Vector2i(signi(int(toward.x)), signi(int(toward.y)))), "idle")
			continue
		var target: Vector2 = _avatar_position_for(state.route[state.index]) + Vector2(0, 1)
		if npc.position.distance_to(target) < 0.5:
			state.timer = float(state.timer) + delta
			var pause := 1.8 if int(state.index) == 0 else 0.0
			if state.timer < pause:
				npc.set_pose(npc.facing, "idle")
				continue
			state.timer = 0.0
			state.index = (int(state.index) + 1) % state.route.size()
			target = _avatar_position_for(state.route[state.index]) + Vector2(0, 1)
		var direction: Vector2 = target - npc.position
		npc.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "walk_a")
		npc.running = Calendar.weather(farm.day) == "雨" or clock_minutes >= 1080
		var next_position: Vector2 = npc.position.move_toward(target, (78.0 if npc.running else 44.0) * delta)
		npc.advance_stride(npc.position.distance_to(next_position))
		npc.position = next_position


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
	var strip := Panel.new()
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("70482d", 0.97)
	frame.border_color = Color("d8a456")
	frame.set_border_width_all(3)
	frame.shadow_color = Color(0.16, 0.10, 0.04, 0.35)
	frame.shadow_size = 4
	strip.add_theme_stylebox_override("panel", frame)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.position = Vector2(0, 0)
	strip.size = Vector2(1280, 84)
	layer.add_child(strip)
	hud_location = Label.new()
	hud_location.position = Vector2(24, 8)
	hud_location.add_theme_font_size_override("font_size", 21)
	hud_location.add_theme_color_override("font_color", Color("#fff3d5"))
	layer.add_child(hud_location)
	hud_hint = Label.new()
	hud_hint.position = Vector2(514, 12)
	hud_hint.text = "移动 WASD / 方向键 · F 互动 · C 换装 · M 导航"
	hud_hint.add_theme_color_override("font_color", Color("#edd4a3"))
	layer.add_child(hud_hint)
	hud_hint.position = Vector2(24, 48)
	hud_hint.add_theme_font_size_override("font_size", 16)
	hud_day = Label.new()
	hud_day.position = Vector2(400, 10)
	hud_day.add_theme_color_override("font_color", Color("fff3d5"))
	hud_day.add_theme_font_size_override("font_size", 19)
	layer.add_child(hud_day)
	hud_tool_icon = TextureRect.new()
	hud_tool_icon.position = Vector2(1212, 2)
	hud_tool_icon.size = Vector2(48, 38)
	hud_tool_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(hud_tool_icon)
	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(22, 590)
	status_panel.size = Vector2(760, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff3d7", 0.94)
	style.border_color = Color("#86542e")
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	style.shadow_color = Color(0.20, 0.12, 0.04, 0.28)
	style.shadow_size = 4
	status_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(status_panel)
	hud_status = Label.new()
	hud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_status.add_theme_color_override("font_color", Color("#483b34"))
	status_panel.add_child(hud_status)
	var bar_panel := PanelContainer.new()
	bar_panel.position = Vector2(207, 646)
	bar_panel.size = Vector2(866, 70)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color("70482d", 0.94)
	bar_style.border_color = Color("d8a456")
	bar_style.set_border_width_all(3)
	bar_style.set_corner_radius_all(7)
	bar_style.set_content_margin_all(5)
	bar_panel.add_theme_stylebox_override("panel", bar_style)
	layer.add_child(bar_panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar_panel.add_child(bar)
	for index in InventoryStateScript.HOTBAR_SIZE:
		var button := Button.new()
		button.custom_minimum_size = Vector2(80, 54)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("eed3a0")
		normal.border_color = Color("805331")
		normal.set_border_width_all(3)
		var selected := normal.duplicate()
		selected.bg_color = Color("ffecac")
		selected.border_color = Color("ef9a39")
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("pressed", selected)
		button.add_theme_stylebox_override("hover", selected)
		button.add_theme_color_override("font_color", Color("533c28"))
		button.add_theme_color_override("font_pressed_color", Color("533c28"))
		button.add_theme_color_override("font_hover_color", Color("533c28"))
		button.add_theme_constant_override("icon_max_width", 30)
		button.pressed.connect(_use_hotbar.bind(index))
		button.mouse_entered.connect(_show_hotbar_info.bind(index))
		button.mouse_exited.connect(_show_hotbar_info.bind(-1))
		bar.add_child(button)
		tool_buttons.append(button)
	hud_hotbar_info = Label.new()
	hud_hotbar_info.position = Vector2(207, 608)
	hud_hotbar_info.size = Vector2(220, 34)
	hud_hotbar_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hotbar_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_hotbar_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_hotbar_info.add_theme_font_size_override("font_size", 16)
	hud_hotbar_info.add_theme_color_override("font_color", Color("fff1cf"))
	hud_hotbar_info.add_theme_color_override("font_outline_color", Color("493526"))
	hud_hotbar_info.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud_hotbar_info)
	var display_button := Button.new()
	display_button.position = Vector2(1168, 44)
	display_button.size = Vector2(96, 32)
	display_button.text = "显示 F10"
	display_button.focus_mode = Control.FOCUS_NONE
	display_button.pressed.connect(_open_display_settings)
	layer.add_child(display_button)

func _load_display_preferences() -> void:
	if DisplayServer.get_name() == "headless": return
	var config := ConfigFile.new()
	if config.load(display_config_path) == OK:
		display_size_index = clampi(int(config.get_value("display", "size", 1)), 0, WINDOW_SIZES.size() - 1)
		if _display_is_embedded():
			display_apply_error = "当前由 Godot 编辑器嵌入运行，宿主窗口不允许游戏切换分辨率或全屏。请禁用嵌入运行后重新启动游戏。"
			return
		var window := get_window()
		if bool(config.get_value("display", "fullscreen", false)):
			window.mode = Window.MODE_FULLSCREEN
		else:
			window.mode = Window.MODE_WINDOWED
			window.size = WINDOW_SIZES[display_size_index]

func _save_display_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "size", display_size_index)
	config.set_value("display", "fullscreen", get_window().mode != Window.MODE_WINDOWED)
	config.save(display_config_path)

func _set_window_size(index: int) -> void:
	display_size_index = clampi(index, 0, WINDOW_SIZES.size() - 1)
	if DisplayServer.get_name() == "headless": return
	if _display_is_embedded():
		display_apply_error = "当前由 Godot 编辑器嵌入运行，宿主窗口尺寸固定。已为此项目禁用嵌入运行，请重启编辑器后再试。"
		_open_display_settings()
		return
	display_apply_error = ""
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.size = WINDOW_SIZES[display_size_index]
	_save_display_preferences()
	_open_display_settings()
	call_deferred("_verify_display_change", false, WINDOW_SIZES[display_size_index])

func _toggle_fullscreen() -> void:
	if DisplayServer.get_name() == "headless": return
	if _display_is_embedded():
		display_apply_error = "当前由 Godot 编辑器嵌入运行，宿主窗口只支持窗口化。已为此项目禁用嵌入运行，请重启编辑器后再试。"
		if life_panel != null: _open_display_settings()
		return
	display_apply_error = ""
	var window := get_window()
	var fullscreen := window.mode != Window.MODE_WINDOWED
	window.mode = Window.MODE_WINDOWED if fullscreen else Window.MODE_FULLSCREEN
	if fullscreen: window.size = WINDOW_SIZES[display_size_index]
	_save_display_preferences()
	if life_panel != null and life_panel.visible: _open_display_settings()
	call_deferred("_verify_display_change", not fullscreen, WINDOW_SIZES[display_size_index])

func _display_is_embedded() -> bool:
	return "--wid" in OS.get_cmdline_args()

func _verify_display_change(expect_fullscreen: bool, expected_size: Vector2i) -> void:
	var window := get_window()
	var fullscreen := window.mode != Window.MODE_WINDOWED
	if fullscreen != expect_fullscreen or (not expect_fullscreen and window.size != expected_size):
		display_apply_error = "窗口切换请求未生效。请确认游戏以独立窗口运行，而不是运行在 Godot 编辑器的嵌入游戏窗口中。"
		if life_panel != null and life_panel.visible: _open_display_settings()

func _open_display_settings() -> void:
	life_panel.open("显示设置")
	var fullscreen := DisplayServer.get_name() != "headless" and get_window().mode != Window.MODE_WINDOWED
	var current_display := "全屏" if fullscreen else "%d × %d" % [WINDOW_SIZES[display_size_index].x, WINDOW_SIZES[display_size_index].y]
	life_panel.paragraph("画面保持等比缩放和最近邻像素边缘。当前：%s。\nF10 打开设置，F11 快速切换全屏。" % current_display)
	if not display_apply_error.is_empty(): life_panel.paragraph("⚠ " + display_apply_error)
	for index in WINDOW_SIZES.size():
		var size: Vector2i = WINDOW_SIZES[index]
		life_panel.action("%d × %d · %s" % [size.x, size.y, ["紧凑", "推荐", "大窗口"][index]], _set_window_size.bind(index))
	life_panel.action("退出全屏" if fullscreen else "全屏游戏", _toggle_fullscreen)


func _update_location() -> void:
	if hud_location != null:
		hud_location.text = "花溪农场 · %s" % _location_name()


func _location_name() -> String:
	if current_map_id == "valley_world":
		return {"farm_outdoor": "露天农场", "town_square": "花溪镇", "riverside": "花溪河畔", "western_forest": "西林", "forest_crossing": "溪桥林道", "farm_country": "农场乡野", "eastern_lakes": "东湖林地"}.get(navigation.zone_at(current_map_id, player_cell), "花溪谷")
	if current_map_id == "riverside": return "花溪河畔"
	if current_map_id == "farm_outdoor": return "露天农场"
	if current_map_id == "farmhouse_interior": return "农舍内景"
	if current_map_id == "general_store_interior": return "杂货店内景"
	if current_map_id == "clinic_interior": return "诊所内景"
	if current_map_id == "cafe_interior": return "咖啡馆内景"
	return "花溪镇广场"

func _is_farm_area(cell := Vector2i(-999, -999)) -> bool:
	var checked: Vector2i = player_cell if cell == Vector2i(-999, -999) else cell
	return current_map_id == "farm_outdoor" or (current_map_id == "valley_world" and navigation.zone_at(current_map_id, checked) == "farm_outdoor")


func _interaction_name(target: String) -> String:
	var names := {"farmhouse_interior": "农舍门", "general_store_interior": "杂货店门", "clinic_interior": "诊所门", "cafe_interior": "咖啡馆门", "shipping_box": "出货箱", "well": "水井", "notice_board": "公告板", "bed": "床铺", "chest": "储物箱", "fireplace": "壁炉", "shop_counter": "杂货店柜台", "clinic_counter": "诊所柜台", "cafe_counter": "咖啡馆柜台"}
	return str(names.get(target, "设施"))


func _set_status(message: String) -> void:
	if hud_status != null:
		hud_status.text = "  " + message


func _on_customization_confirmed(data: Dictionary) -> void:
	player.set_customization(data)
	creator.close()
	_set_status("角色已创建。沿农场西侧道路前往城镇，按 C 可编辑外观。")
	_save_game()


func _farm_action() -> void:
	if not actor_action.kind.is_empty(): return
	if moving:
		queued_use = "tool"
		queued_use_cell = Vector2i(-1, -1)
		return
	if current_tool == "fish":
		_start_fishing()
		return
	if current_tool == "water" and homestead.water <= 0:
		_set_status("水壶空了，去水井按 F 补满。")
		return
	if energy < 2:
		_set_status("体力不足，回家休息或从背包吃一份作物。")
		return
	if not _is_farm_area():
		_set_status("耕种工具只能在农场户外使用。")
		return
	var target_cell := player_cell + _facing_delta(player.facing)
	if pet.visible and _cell_from_world_position(pet.position) == target_cell:
		_set_status("麦麦正站在那里，等它走开再使用工具吧。")
		return
	if not navigation.is_in_bounds(current_map_id, target_cell):
		_set_status("面前没有可操作的土地。")
		return
	var selected_tool := current_tool
	var selected_seed := _current_seed_id()
	actor_action.start(selected_tool, _commit_farm_action.bind(target_cell, selected_tool, selected_seed))
	player.action_progress = 0.0
	player.set_pose(player.facing, selected_tool)


func _commit_farm_action(target_cell: Vector2i, selected_tool: String, selected_seed: String) -> void:
	var result: Dictionary
	match selected_tool:
		"hoe": result = farm.till(target_cell)
		"seed": result = farm.plant(target_cell, selected_seed)
		"water": result = farm.water(target_cell)
		"harvest", "scythe": result = farm.harvest(target_cell)
		_: result = {"ok": false, "message": "未知工具"}
	if bool(result.get("ok", false)):
		farm_audio.play(selected_tool)
		energy -= 2
		if selected_tool == "water": homestead.water = maxi(0, homestead.water - 1)
		pet.rebuild_grid()
		feedback.burst(world.cell_center_to_screen(target_cell), "+1" if selected_tool in ["harvest", "scythe"] else "", Color("a8e5f1") if selected_tool == "water" else Color("f3d16c"))
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


func _start_fishing() -> void:
	if energy < 2 or not fishing_stage.is_empty(): return
	var target := player_cell + _facing_delta(player.facing)
	if navigation.get_cell_class(current_map_id, target) != "water":
		_set_status("站在池塘或河岸边，面向水面再按 E 抛竿。")
		return
	fishing_stage = "casting"
	fishing_elapsed = 0.0
	actor_action.start("fish", func():
		energy -= 2
		_update_farm_hud()
		_save_game(), func():
		fishing_stage = "waiting"
		fishing_elapsed = 0.0
		_set_status("浮漂已落水，等待咬钩；Esc 收竿。")
	)


func _catch_fish() -> void:
	fish_count += 1
	_sync_inventory()
	_update_farm_hud()
	_set_status("钓到一条溪鱼！背包中有 %d 条。" % fish_count)
	_save_game()


func _cancel_fishing() -> void:
	fishing_stage = ""
	actor_action.cancel()
	player.set_pose(player.facing, "idle")


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
	return {"hoe": "锄头", "seed": "种子", "water": "浇水壶", "harvest": "采收", "scythe": "镰刀", "fish": "鱼竿"}.get(current_tool, "工具")


func _seed_name(seed_id: String) -> String:
	if farm != null:
		var definition: Dictionary = farm.get_crop_definition(seed_id)
		if not definition.is_empty(): return str(definition.get("label", seed_id))
	return seed_id


func _default_hotbar_items() -> Array:
	var result: Array = []
	for tool_id in TOOL_IDS: result.append("tool:" + tool_id)
	return result


func _inventory_items() -> Dictionary:
	var result := {}
	var tool_names := {"hoe": "锄头", "seed": "种子袋", "water": "浇水壶", "harvest": "采收篮", "scythe": "镰刀", "fish": "鱼竿"}
	var tool_short := {"hoe": "锄头", "seed": "种子", "water": "水壶", "harvest": "采收", "scythe": "镰刀", "fish": "鱼竿"}
	var tool_descriptions := {
		"hoe": "翻松面前可耕地。快捷栏数字键会立即挥动工具，E 可继续使用当前工具。",
		"seed": "把当前选择的种子播进已翻松的土地。按 Q 切换种类；当前是%s。" % _seed_name(_current_seed_id()),
		"water": "给面前的土地浇水。当前水量 %d / %d，可在水井补满。" % [homestead.water, Homestead.WATER_CAPACITY],
		"harvest": "采下已经成熟的作物，并把收获放进背包。",
		"scythe": "收割面前已经成熟的作物。",
		"fish": "站在水边面向水面抛竿；鱼咬钩后按 E 提竿。",
	}
	for tool_id in TOOL_IDS:
		result["tool:" + tool_id] = {"kind": "tool", "type_label": "工具", "tool_id": tool_id, "name": tool_names[tool_id], "short_name": tool_short[tool_id], "count": 1, "description": tool_descriptions[tool_id], "icon": _tool_texture(tool_id)}
	for item_id in current_seed_ids:
		var crop: Dictionary = farm.get_crop_definition(item_id) if farm != null else {}
		if crop.is_empty(): continue
		var seasons: Array[String] = []
		for season in crop.get("seasons", []): seasons.append(Calendar.SEASONS[int(season)])
		var seed_count: int = farm.get_seed_count(item_id)
		if seed_count > 0:
			result["seed:" + item_id] = {"kind": "seed", "type_label": "种子（不可直接使用）", "name": str(crop.label) + "种子", "short_name": str(crop.label), "count": seed_count, "description": "%s季种植，%d 天成熟。把种子袋工具放入快捷栏并按 Q 选中这种种子后播种。" % ["、".join(seasons), int(crop.grow_days)], "icon": _crop_icon(item_id, 0)}
		var food_count: int = farm.get_harvest_count(item_id)
		if food_count > 0:
			result["food:" + item_id] = {"kind": "food", "type_label": "食物", "name": str(crop.label), "short_name": str(crop.label), "count": food_count, "description": "农场收获，可食用恢复 20 点体力，也可送礼或出货（%d 金）。" % int(crop.sell_price), "icon": _crop_icon(item_id, 3)}
	for kind in homestead.resources:
		var amount := int(homestead.resources[kind])
		if amount <= 0: continue
		var edible: bool = kind in ["berry", "mushroom"]
		result[("food:" if edible else "material:") + str(kind)] = {"kind": "food" if edible else "material", "type_label": "食物" if edible else "材料（不可直接使用）", "name": str(Homestead.RESOURCE_NAMES[kind]), "short_name": str(Homestead.RESOURCE_NAMES[kind]), "count": amount, "description": ("野外采集的食物，食用可恢复 %d 点体力。" % (15 if kind == "berry" else 25)) if edible else "建造与制作使用的基础材料，不能从快捷栏直接使用。", "icon": INVENTORY_ICONS[kind]}
	if fish_count > 0:
		result["food:fish"] = {"kind": "food", "type_label": "食物", "name": "溪鱼", "short_name": "溪鱼", "count": fish_count, "description": "从河流或池塘钓到的新鲜溪鱼，食用恢复 30 点体力。", "icon": INVENTORY_ICONS.fish_food}
	return result


func _crop_icon(item_id: String, stage: int) -> Texture2D:
	var visual: Array = WorldRendererScript.crop_visual(item_id)
	if visual.size() < 2 or not visual[0] is Texture2D: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = visual[0]
	atlas.region = SpriteAtlasScript.frame(visual[0], Vector2i(4, 4), clampi(stage, 0, 3), int(visual[1])).region
	return atlas


func _sync_inventory() -> void:
	if farm == null: return
	inventory_state.ensure_items(_inventory_items().keys())


func _on_inventory_layout_changed() -> void:
	_update_farm_hud()
	_save_game()


func _farm_error(code: String) -> String:
	return {"not_tillable": "这里不是地图标注的可耕种土地。", "already_tilled": "这格已经翻过地了。", "not_tilled": "先用锄头翻地。", "occupied": "这格已经种了作物。", "out_of_seeds": "这种种子用完了，按 Q 换一种。", "already_watered": "今天已经浇过水。", "not_mature": "作物尚未成熟。", "empty": "这里没有可以收获的作物。"}.get(code, "现在不能这样操作。")


func _update_farm_hud() -> void:
	if hud_hint == null or farm == null:
		return
	if hud_day != null:
		hud_day.text = "%s  %02d:%02d  %s · %d 金 · 体力 %d" % [Calendar.label(farm.day), clock_minutes / 60, clock_minutes % 60, Calendar.weather(farm.day), farm.gold, energy]
	hud_hint.text = "%s×%d · 水 %d/24 · E使用当前工具 · 1–9/0使用快捷栏 · I背包 · Tab日历" % [_seed_name(_current_seed_id()), farm.get_seed_count(_current_seed_id()), homestead.water]
	var items := _inventory_items()
	for index in tool_buttons.size():
		var button: Button = tool_buttons[index]
		var item_key := str(inventory_state.hotbar[index])
		var item: Dictionary = items.get(item_key, {})
		var key_label := str(index + 1) if index < 9 else "0"
		button.text = key_label + ("\n" + _item_symbol(item) if not item.is_empty() and not (item.get("icon") is Texture2D) else "")
		button.set_pressed_no_signal(index == inventory_state.selected_hotbar)
		button.tooltip_text = str(item.get("name", "空快捷栏"))
		button.icon = item.get("icon") if item.get("icon") is Texture2D else null
		button.expand_icon = true
	_show_hotbar_info(hud_hotbar_hover_index)
	_update_tool_icon()


func _show_hotbar_info(index: int) -> void:
	hud_hotbar_hover_index = index
	if hud_hotbar_info == null: return
	var shown_index: int = inventory_state.selected_hotbar if index < 0 else index
	var item_key := str(inventory_state.hotbar[shown_index])
	var item: Dictionary = _inventory_items().get(item_key, {})
	if item.is_empty():
		hud_hotbar_info.hide()
		return
	var count := int(item.get("count", 1))
	hud_hotbar_info.text = "%s%s" % [str(item.get("name", item_key)), " ×%d" % count if count > 1 else ""]
	hud_hotbar_info.position.x = clampf(207.0 + shown_index * 84.0 - 70.0, 8.0, 1052.0)
	hud_hotbar_info.show()


func _item_symbol(item: Dictionary) -> String:
	var key := str(item.get("tool_id", item.get("name", "")))
	return {"scythe": "◒", "fish": "◇", "木材": "▤", "石料": "◆", "野莓": "●", "蘑菇": "♠", "溪鱼": "◇"}.get(key, "◆")


func _update_tool_icon() -> void:
	if hud_tool_icon == null:
		return
	hud_tool_icon.texture = _tool_texture(current_tool)


func _tool_texture(tool_id: String) -> Texture2D:
	if tool_id == "fish": return INVENTORY_ICONS.fish_tool
	var source_size := TOOLS_ART.get_size()
	var cell_size := Vector2(source_size.x / 4.0, source_size.y / 2.0)
	var indices := {"water": Vector2i(0, 0), "hoe": Vector2i(1, 0), "harvest": Vector2i(0, 1), "scythe": Vector2i(0, 1), "seed": Vector2i(1 + current_seed_index, 1)}
	var index: Vector2i = Vector2i(indices.get(tool_id, Vector2i(1, 0)))
	index.x = mini(index.x, 3)
	var atlas := AtlasTexture.new()
	atlas.atlas = TOOLS_ART
	atlas.region = Rect2(Vector2(index) * cell_size, cell_size)
	return atlas


func _on_farm_cell_changed(cell: Vector2i, _state: Dictionary) -> void:
	if world != null:
		world.queue_redraw()
	if collision_stream_bounds.has_point(cell):
		_sync_collision_cell(cell)


func _on_farm_inventory_changed(_kind: String, _id: String, _amount: int) -> void:
	_sync_inventory()
	_update_farm_hud()
	if inventory_panel != null and inventory_panel.visible: inventory_panel.refresh()


func _on_farm_gold_changed(_total: int, _delta: int) -> void:
	_update_farm_hud()


func _on_farm_day_advanced(_day: int, _is_raining: bool, _result: Dictionary) -> void:
	_update_farm_hud()
	if world != null: world.refresh_season()
	if scenery != null: scenery.refresh()

func _ask_sleep() -> void:
	if moving: return
	if not _is_farm_area() and current_map_id != "farmhouse_interior":
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
	_sync_inventory()
	if life_panel.visible: life_panel.close()
	inventory_panel.open(self)


func _open_world_map(selected := "") -> void:
	var selected_map: String = ("valley_world" if continuous_world_enabled else current_map_id) if selected.is_empty() else selected
	var names := {"valley_world": "花溪谷全域", "farm_outdoor": "农场", "town_square": "花溪镇", "riverside": "花溪河畔", "farmhouse_interior": "农舍", "general_store_interior": "种子铺", "clinic_interior": "诊所", "cafe_interior": "咖啡馆"}
	life_panel.open("花溪大地图 · " + str(names.get(selected_map, selected_map)))
	life_panel.paragraph("花溪镇—溪桥林道—农场—东湖林地—河畔组成连续世界。户外行走时周边区域会动态载入，不再在区域边界切换画面。房屋内部仍通过门进入。")
	var overview = preload("res://scripts/map_overview.gd").new()
	overview.navigation = navigation
	overview.map_id = selected_map
	overview.player_cell = player_cell
	overview.show_player = selected_map == current_map_id
	life_panel.content.add_child(overview)
	if not continuous_world_enabled:
		for map_key in ["farm_outdoor", "town_square", "riverside"]:
			if map_key != selected_map: life_panel.action("查看" + str(names[map_key]), _open_world_map.bind(map_key))

func _eat(item: String) -> void:
	_eat_inventory_item("food:" + item)


func _eat_inventory_item(item_key: String) -> void:
	var item: Dictionary = _inventory_items().get(item_key, {})
	if str(item.get("kind", "")) != "food":
		_set_status("这个物品不能食用。")
		return
	if energy >= 100:
		_set_status("现在体力充足，不需要进食。")
		return
	var item_id := item_key.trim_prefix("food:")
	var restored := 20
	if farm.crop_definitions.has(item_id):
		if farm.get_harvest_count(item_id) <= 0: return
		farm.harvest_inventory[item_id] -= 1
		farm.inventory_changed.emit("harvest", item_id, farm.get_harvest_count(item_id))
	elif item_id in ["berry", "mushroom"]:
		if int(homestead.resources.get(item_id, 0)) <= 0: return
		homestead.resources[item_id] -= 1
		restored = 15 if item_id == "berry" else 25
	elif item_id == "fish":
		if fish_count <= 0: return
		fish_count -= 1
		restored = 30
	else:
		return
	energy = mini(100, energy + restored)
	_sync_inventory()
	_update_farm_hud()
	_set_status("食用了%s，恢复 %d 点体力。" % [str(item.get("name", "食物")), restored])
	_save_game()
	if inventory_panel != null and inventory_panel.visible: inventory_panel.refresh()

func _open_people() -> void:
	life_panel.open("花溪居民")
	life_panel.paragraph("每天聊天 +20；每天可送一份作物。喜爱礼物 +60，其他作物 +25，生日礼物三倍。靠近居民按 F 聊天，G 送礼。")
	for actor in VillageScript.PEOPLE:
		var person: Dictionary = VillageScript.PEOPLE[actor]
		var relation: Dictionary = village.bond(actor)
		life_panel.paragraph("现在：" + str(village.activity(actor, farm.day, clock_minutes).label))
		life_panel.paragraph("%s · %s · %d / 1000\n生日 %s · 喜爱%s\n今天：%s / %s" % [person.name, person.job, relation.points, Calendar.label(person.birthday), _seed_name(person.likes), "已聊天" if relation.talk_day == farm.day else "未聊天", "已送礼" if relation.gift_day == farm.day else "未送礼"])

func _open_dialogue(actor: String) -> void:
	var person: Dictionary = VillageScript.PEOPLE[actor]
	life_panel.open(str(person.name) + " · " + str(person.job))
	var frame: Dictionary = preload("res://scripts/sprite_atlas.gd").frame(NPC_ART[actor], Vector2i(4, 4), 1, 0)
	var region: Rect2 = frame.region
	region.size.y *= 0.65
	life_panel.dialogue(NPC_ART[actor], region, village.talk(actor, farm.day, clock_minutes))
	var wanted: Dictionary = village.request(actor, farm.day)
	if not wanted.done:
		life_panel.action("今日委托：带来一份" + _seed_name(wanted.item), _deliver_request.bind(actor))
	else: life_panel.paragraph("今日委托已完成，谢谢你的帮助。")
	life_panel.action("送一份农场礼物", _open_gifts.bind(actor))
	_save_game()

func _deliver_request(actor: String) -> void:
	if _nearby_npc_actor() != actor: return
	var message: String = village.deliver(actor, farm)
	_update_farm_hud()
	_save_game()
	_open_dialogue(actor)
	life_panel.paragraph(message)

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
	if not actor_action.kind.is_empty(): return
	if _nearby_npc_actor() != actor: return
	life_panel.close()
	var direction: Vector2 = npcs[actor].node.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "gift")
	actor_action.start("gift", _commit_gift.bind(actor, item), func():
		life_panel.open("居民的回应")
		life_panel.paragraph(_gift_response)
	)

var _gift_response := ""

func _commit_gift(actor: String, item: String) -> void:
	var message: String = village.gift(actor, item, farm)
	_gift_response = message
	farm_audio.play("gift")
	if npcs.has(actor): feedback.burst(npcs[actor].node.position, "♡", Color("f298ae"))
	_update_farm_hud()
	_save_game()

func _open_shop() -> void:
	life_panel.open("阿谷的种子铺 · %d 金币" % farm.gold)
	var season: int = Calendar.date(farm.day).season
	life_panel.paragraph("本季供应 · %s。跨季作物在仍适宜的下一季会继续生长。" % Calendar.SEASONS[season])
	for item in current_seed_ids:
		var crop: Dictionary = farm.get_crop_definition(item)
		if not season in crop.seasons: continue
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
	var data := {"version": 1, "world_layout": 2 if continuous_world_enabled else 1, "farm": farm.snapshot(), "village": village.snapshot(), "homestead": homestead.snapshot(), "inventory_layout": inventory_state.snapshot(), "map": current_map_id, "cell": [player_cell.x, player_cell.y], "appearance": player.get_customization(), "clock": clock_minutes, "energy": energy, "fish_count": fish_count}
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
	if continuous_world_enabled and int(data.get("world_layout", 1)) < 2: _migrate_save_to_contiguous(data)
	farm.restore(data.farm)
	village.restore(data.village)
	homestead.restore(data.get("homestead", {}))
	pet.rebuild_grid()
	clock_minutes = clampi(int(data.get("clock", 360)), 360, 1430)
	energy = clampi(int(data.get("energy", 100)), 0, 100)
	fish_count = maxi(0, int(data.get("fish_count", 0)))
	if data.has("inventory_layout"): inventory_state.restore(data.inventory_layout)
	_sync_inventory()
	var restored_item: Dictionary = _inventory_items().get(str(inventory_state.hotbar[inventory_state.selected_hotbar]), {})
	if str(restored_item.get("kind", "")) == "tool": current_tool = str(restored_item.get("tool_id", current_tool))
	player.set_customization(data.get("appearance", {}))
	_change_map(str(data.get("map", "farm_outdoor")), _as_cell(data.get("cell", [17, 16])))

func _migrate_save_to_contiguous(data: Dictionary) -> void:
	data.world_layout = 2
	var old_map := str(data.get("map", "farm_outdoor"))
	if old_map in ["farm_outdoor", "town_square", "riverside"]:
		var old_cell := _as_cell(data.get("cell", [17, 16]))
		var world_cell := navigation.to_contiguous_world(old_map, old_cell)
		data.map = "valley_world"
		data.cell = [world_cell.x, world_cell.y]
	var farm_offset := navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO)
	for row in data.get("farm", {}).get("plots", []):
		row.x = int(row.x) + farm_offset.x
		row.y = int(row.y) + farm_offset.y

func _read_save(path: String):
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data

func _valid_save(data) -> bool:
	if not data is Dictionary or not _save_number(data.get("version")) or int(data.version) != 1: return false
	if data.has("world_layout") and (not _save_number(data.world_layout) or int(data.world_layout) not in [1, 2]): return false
	if data.has("homestead") and not Homestead.valid(data.homestead): return false
	if data.has("inventory_layout") and not InventoryStateScript.valid(data.inventory_layout): return false
	if not data.get("farm") is Dictionary or not data.get("village") is Dictionary: return false
	if data.has("fish_count") and (not _save_number(data.fish_count) or float(data.fish_count) < 0): return false
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
	if not data.village.get("request_days", {}) is Dictionary: return false
	for day in data.village.get("request_days", {}).values():
		if not _save_number(day) or float(day) < 0: return false
	for relation in data.village.bonds.values():
		if not relation is Dictionary or not relation.has_all(["points", "talk_day", "gift_day"]): return false
		for key in ["points", "talk_day", "gift_day"]:
			if not _save_number(relation[key]): return false
	for visits in data.village.visits.values():
		if not visits is Array: return false
	return navigation.has_map(str(data.get("map", ""))) and data.get("cell") is Array and data.cell.size() == 2 and _save_number(data.cell[0]) and _save_number(data.cell[1]) and data.get("appearance") is Dictionary

func _save_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
