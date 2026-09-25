extends Node2D

const MapDataScript = preload("res://scripts/map_data.gd")
const ValleyWorldScript = preload("res://scripts/valley_world_builder.gd")
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
const UISkin = preload("res://scripts/farm_ui_skin.gd")
const CenterLightTransitionScript = preload("res://scripts/center_light_transition.gd")
const FishingMinigameViewScript = preload("res://scripts/fishing_minigame_view.gd")
const SpringFestivalHuntScript = preload("res://scripts/spring_festival_hunt.gd")
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
var farm_music
var tool_buttons: Array[Button] = []
const TOOL_IDS := ["hoe", "seed", "water", "harvest", "scythe", "fish", "pickaxe", "sword"]
const Mining = preload("res://scripts/mining_state.gd")
const Fishing = preload("res://scripts/fishing_state.gd")
const Community = preload("res://scripts/community_state.gd")
const Crafting = preload("res://scripts/crafting_state.gd")
const Skills = preload("res://scripts/skill_state.gd")
const Animals = preload("res://scripts/animal_state.gd")
const ChickenActor = preload("res://scripts/chicken_actor.gd")
const DuckActor = preload("res://scripts/duck_actor.gd")
const CowActor = preload("res://scripts/cow_actor.gd")
const Processing = preload("res://scripts/processing_state.gd")
const Combat = preload("res://scripts/combat_state.gd")
const MonsterActor = preload("res://scripts/monster_actor.gd")
const Orchard = preload("res://scripts/orchard_state.gd")
var mining = Mining.new()
var fishing = Fishing.new()
var community = Community.new()
var crafting = Crafting.new()
var skills = Skills.new()
var animals = Animals.new()
var processing = Processing.new()
var combat = Combat.new()
var orchard = Orchard.new()
var chicken_actors: Dictionary = {}
var duck_actors: Dictionary = {}
var cow_actors: Dictionary = {}
var monster_actors: Dictionary = {}
var combat_invulnerability := 0.0
var current_sapling_id := "apple"
const TOOLS_ART: Texture2D = preload("res://assets/art/source_generated/mvp_tools_and_seeds_source_v1.png")
const INVENTORY_ICONS := {
	"fish_tool": preload("res://assets/art/runtime_generated/inventory_icons/fishing_rod_v1.png"),
	"wood": preload("res://assets/art/runtime_generated/inventory_icons/wood_v1.png"),
	"stone": preload("res://assets/art/runtime_generated/inventory_icons/stone_v1.png"),
	"berry": preload("res://assets/art/runtime_generated/inventory_icons/wild_berry_v1.png"),
	"mushroom": preload("res://assets/art/runtime_generated/inventory_icons/mushroom_v1.png"),
	"fish_food": preload("res://assets/art/runtime_generated/inventory_icons/creek_fish_v1.png"),
	"duck_egg": preload("res://assets/art/runtime_generated/inventory_icons/duck_egg_v1.svg"),
}
const FISH_ART: Texture2D = preload("res://assets/art/runtime_generated/fish_icons_v1.svg")
const FISH_ICON_INDEX := {"sardine": 0, "flounder": 1, "catfish": 2, "night_eel": 3, "red_snapper": 4, "squid": 5, "tuna": 6, "creek_fish": 7}
const ORE_DEPOSIT_ART: Texture2D = preload("res://assets/art/runtime_generated/ore_deposits_v1.svg")
const ORE_INVENTORY_ICON_INDEX := {"copper_ore": 0, "iron_ore": 1, "coal": 2, "quartz": 3, "earth_crystal": 4, "amethyst": 5, "frozen_tear": 6, "fire_quartz": 7}
const GOODS_ART: Texture2D = preload("res://assets/art/runtime_generated/backpack_goods_v1.svg")
const GOODS_ICON_INDEX := {
	"fruit:apple": 0, "fruit:orange": 1, "fruit:peach": 2, "fruit:pomegranate": 3,
	"animal:egg": 4, "animal:duck_egg": 5, "animal:milk": 6,
	"artisan:mayonnaise": 7, "artisan:cheese": 8, "artisan:pickles": 9,
	"meal:trail_mix": 10, "meal:fish_stew": 11, "meal:pumpkin_soup": 12, "meal:miner_lunch": 13,
	"meal:field_salad": 14, "meal:sea_skewer": 15, "meal:miner_rice": 16, "meal:berry_tart": 17,
	"placeable:sprinkler": 18, "placeable:mayo_machine": 19, "placeable:preserves_jar": 20, "placeable:cheese_press": 21,
	"sapling:apple": 22, "sapling:orange": 23, "sapling:peach": 24, "sapling:pomegranate": 25,
	"bait": 26, "tackle:cork_bobber": 27,
}
const NPC_ART := {
	"florist": preload("res://assets/art/runtime_generated/florist_walk_v2.png"),
	"shopkeeper": preload("res://assets/art/runtime_generated/shopkeeper_walk_v2.png"),
	"fisherman": preload("res://assets/art/runtime_generated/fisherman_walk_v2.png"),
	"mayor": preload("res://assets/art/runtime_generated/mayor_walk_v1.png"),
	"carpenter": preload("res://assets/art/runtime_generated/carpenter_walk_v1.png"),
	"doctor": preload("res://assets/art/runtime_generated/doctor_walk_v1.png"),
	"cook": preload("res://assets/art/runtime_generated/cook_walk_v1.png"),
	"ranger": preload("res://assets/art/runtime_generated/ranger_walk_v1.png"),
	"teacher": preload("res://assets/art/runtime_generated/teacher_walk_v1.png"),
	"child": preload("res://assets/art/runtime_generated/child_walk_v1.png"),
}
const NPC_CAST_IDLE_ART: Texture2D = preload("res://assets/art/runtime_generated/resident_idle_cast_v1.png")
const NPC_CAST_COLUMNS := {
	"florist": 0, "shopkeeper": 1, "fisherman": 2, "mayor": 3, "carpenter": 4,
	"doctor": 5, "cook": 6, "ranger": 7, "teacher": 8, "child": 9,
}
const NPC_WALK_TINTS := {
	"florist": Color.WHITE, "shopkeeper": Color("e6c6a5"), "fisherman": Color("b9d2de"),
	"mayor": Color.WHITE, "carpenter": Color.WHITE, "doctor": Color.WHITE,
	"cook": Color.WHITE, "ranger": Color.WHITE, "teacher": Color.WHITE, "child": Color.WHITE,
}

const WALK_SPEED := 128.0
const STREAM_COLLISION_POOL_SIZE := 512
const RESIDENT_BUMP_SECONDS := 0.03

var navigation: MapData
var world: WorldRenderer
var _world_cache: Dictionary = {}
var _world_cache_order: Array[String] = []
const WORLD_CACHE_LIMIT := 3
var player: AvatarRenderer
var player_body: CharacterBody2D
var game_camera: Camera2D
var scene_transition: CenterLightTransitionScript
var collision_root: StaticBody2D
var creator: CharacterCreator
var farm = null
var current_map_id := "valley_world"
var continuous_world_enabled := false
var force_continuous_world_for_qa := false
var collision_stream_center := Vector2i(-999, -999)
var collision_stream_bounds := Rect2i()
var collision_stream_map_id := ""
var collision_view_refresh_pending := false
var pending_collision_additions: Array[Vector2i] = []
var pending_collision_removals: Array[Vector2i] = []
const COLLISION_STREAM_BUDGET := 12
var active_collision_cells: Dictionary = {}
var animal_collision_cells: Array[Vector2i] = []
var collision_shape_pool: Array[CollisionShape2D] = []
var streamed_collision_shape: RectangleShape2D
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1536, 864), Vector2i(1920, 1080)]
const CAMERA_ZOOMS := [1.5, 1.75, 2.0]
var display_size_index := 1
var camera_zoom_index := 2
var display_config_path := "user://display.cfg"
var display_apply_error := ""
var audio_volume_percent := 100
var sfx_volume_percent := 100
var current_tool := "hoe"
var current_seed_index := 0
var current_seed_ids := ["parsnip", "turnip", "cauliflower", "potato", "green_bean", "strawberry", "tomato", "blueberry", "corn", "pepper", "melon", "pumpkin", "cranberry", "eggplant", "yam", "bok_choy", "powdermelon", "winter_root", "snow_yam", "crystal_berry"]
var player_cell := Vector2i.ZERO
var moving := false
var footstep_distance := 0.0
var queued_use := ""
var queued_use_cell := Vector2i(-1, -1)
var transition_lock_frames := 0
var hud_status: Label
var hud_status_panel: PanelContainer
var hud_status_tween: Tween
var hud_context: Label
var hud_location: Label
var hud_hint: Label
var hud_tool_icon: TextureRect
var hud_hotbar_info: Label
var hud_hotbar_hover_index := -1
var npcs: Dictionary = {}
var resident_schedule := ""
var _resident_bump_elapsed: Dictionary = {}
var _resident_pass_through: Dictionary = {}
var actor_action = preload("res://scripts/actor_action.gd").new()
var entering_door := false
var occlusion_shadow: Sprite2D
var fish_count: int:
	get: return fishing.total_count()
	set(value): fishing.set_legacy_count(maxi(0, value))
var fishing_stage := ""
var fishing_elapsed := 0.0
var hooked_fish: Dictionary = {}
var fishing_view
var festival_hunt
var fishing_reel_held := false
var fishing_fish_position := 0.5
var fishing_fish_velocity := 0.0
var fishing_direction_change := 0.0
var fishing_bar_center := 0.5
var fishing_bar_velocity := 0.0
var fishing_bar_height := 0.3
var fishing_catch_progress := 0.0
var fishing_treasure_available := false
var fishing_treasure_secured := false
var fishing_treasure_position := 0.5
var fishing_treasure_progress := 0.0


func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_window().size_changed.connect(_on_window_size_changed)
	_ensure_audio_buses()
	_load_display_preferences()
	navigation = MapDataScript.new()
	if not navigation.load_data():
		push_error("Failed to load navigation data: %s" % navigation.load_errors)
		return
	continuous_world_enabled = force_continuous_world_for_qa
	if continuous_world_enabled:
		navigation.build_contiguous_world()
	else:
		navigation.build_regions()
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
	world.set_animal_state(animals)
	world.set_processing_state(processing)
	world.set_orchard_state(orchard)
	world.set_community_state(community)
	pet = preload("res://scripts/companion_actor.gd").new()
	pet.model = homestead
	pet.navigation = navigation
	pet.farm = farm
	pet.animals = animals
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
	farm_music = preload("res://scripts/farm_music.gd").new()
	farm_music.game = self
	add_child(farm_music)
	player = AvatarRendererScript.new()
	player.pixel_scale = 0.13
	player.z_index = 0
	player_body = CharacterBody2D.new()
	player_body.name = "PlayerBody"
	player_body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
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
	game_camera.zoom = Vector2.ONE * CAMERA_ZOOMS[camera_zoom_index]
	game_camera.position_smoothing_enabled = false
	game_camera.position_smoothing_speed = 10.0
	player_body.add_child(game_camera)
	game_camera.make_current()
	_sync_inventory()
	inventory_state.initialize(_inventory_items().keys(), _default_hotbar_items())
	_build_hud()
	var fishing_layer := CanvasLayer.new()
	fishing_layer.layer = 15
	add_child(fishing_layer)
	fishing_view = FishingMinigameViewScript.new()
	fishing_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fishing_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fishing_layer.add_child(fishing_view)
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
	_set_status("WASD 移动 · E 使用工具 · F 互动 · L 技能 · K 制作。农舍或农场按 N 休息。")
	if not autosave_enabled and FileAccess.file_exists(save_path):
		_set_status("存档损坏且备份不可用；已保留原文件并停止自动覆盖。当前为临时游玩。")


func _process(_delta: float) -> void:
	if player_body == null: return
	if hud_context != null:
		var blocked: bool = entering_door or creator == null or creator.visible or (life_panel != null and life_panel.visible) or (inventory_panel != null and inventory_panel.visible) or (festival_hunt != null and festival_hunt.active) or not actor_action.kind.is_empty()
		hud_context.text = "" if blocked else _context_text()
		hud_context.visible = not hud_context.text.is_empty()
		if hud_hotbar_info != null: hud_hotbar_info.visible = not blocked and not hud_hotbar_info.text.is_empty()
	player_body.z_index = clampi(int(player_body.position.y), -4096, 4096)
	for state in npcs.values(): state.node.z_index = clampi(int(state.node.position.y), -4096, 4096)
	var body: Sprite2D = player._body
	occlusion_shadow.texture = body.texture
	occlusion_shadow.region_rect = body.region_rect
	occlusion_shadow.transform = body.global_transform
	occlusion_shadow.visible = player.visible and not entering_door and world.is_actor_occluded(player_body.position)


func _physics_process(delta: float) -> void:
	if navigation == null or creator == null or creator.visible:
		return
	if entering_door: return
	if inventory_panel != null and inventory_panel.visible:
		_stop_player()
		return
	if life_panel != null and life_panel.visible:
		_stop_player()
		return
	_process_collision_stream_queue()
	if pet.visible: pet.tick(delta, player_body.position, clock_minutes)
	_tick_chickens(delta)
	_tick_ducks(delta)
	_tick_cows(delta)
	_tick_monsters(delta)
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
	if fishing_stage in ["waiting", "playing"]:
		fishing_elapsed += delta
		player.set_pose(player.facing, "fish")
		player.action_progress = 0.65
		var wait_seconds := float(hooked_fish.get("wait", 2.0))
		if fishing_stage == "waiting" and fishing_elapsed >= wait_seconds:
			fishing_stage = "playing"
			fishing_elapsed = 0.0
			_set_status("鱼咬钩了！按住 E 或鼠标左键，让操作条追住鱼。")
		if fishing_stage == "playing":
			_advance_fishing_minigame(delta)
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
	if festival_hunt != null and festival_hunt.active:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			festival_hunt.cancel()
		get_viewport().set_input_as_handled()
		return
	if inventory_panel != null and inventory_panel.visible:
		if event is InputEventKey:
			inventory_panel.handle_key(event)
			if event.pressed: get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and fishing_stage == "playing":
		fishing_reel_held = event.pressed
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		feedback.hovered = _cell_from_world_position(get_viewport_transform().affine_inverse() * event.position)
		feedback.use_mouse = true
		return
	if event is InputEventMouseButton and event.pressed:
		_handle_mouse(event)
		return
	if event is InputEventKey and event.keycode == KEY_E and fishing_stage == "playing":
		fishing_reel_held = event.pressed
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	feedback.use_mouse = false
	if entering_door: return
	if not fishing_stage.is_empty():
		if event.keycode == KEY_ESCAPE:
			_cancel_fishing()
		get_viewport().set_input_as_handled()
		return
	if life_panel != null and life_panel.visible:
		if event.keycode == KEY_ESCAPE:
			life_panel.close()
		elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_F] and is_instance_valid(life_panel.dialogue_text):
			life_panel.reveal_dialogue()
		get_viewport().set_input_as_handled()
		return
	if not actor_action.kind.is_empty():
		get_viewport().set_input_as_handled()
		return
	if not creator.visible:
		match event.keycode:
			KEY_TAB: _open_calendar()
			KEY_I: _open_inventory()
			KEY_R: _open_people()
			KEY_P: _open_pet()
			KEY_M: _open_world_map()
			KEY_K: _open_crafting()
			KEY_L: _open_skills()
			KEY_J: _open_character_card()
			KEY_F10: _open_display_settings()
			KEY_F11: _toggle_fullscreen()
			KEY_G: _open_gifts(_interaction_npc_actor())
			KEY_F5: _set_status("存档已保存。" if _save_game() else "存档失败，请检查磁盘空间。")
		if event.keycode in [KEY_TAB, KEY_I, KEY_R, KEY_P, KEY_M, KEY_K, KEY_L, KEY_J, KEY_G, KEY_F5, KEY_F10, KEY_F11]:
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
	if entering_door or not actor_action.kind.is_empty() or not fishing_stage.is_empty() or (festival_hunt != null and festival_hunt.active) or (creator != null and creator.visible) or (life_panel != null and life_panel.visible):
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
	if festival_hunt != null and festival_hunt.active: return
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
		"placeable": _place_structure(str(item.get("structure_id", "")))
		"sapling":
			current_tool = "sapling"
			current_sapling_id = str(item.get("tree_id", "apple"))
			_plant_sapling_action(current_sapling_id)
		_:
			_set_status("%s不是工具或食物，不能直接使用。" % str(item.get("name", "这个物品")))
			_update_farm_hud()

func _handle_mouse(event: InputEventMouseButton) -> void:
	if entering_door or creator.visible or life_panel.visible or (inventory_panel != null and inventory_panel.visible): return
	if not actor_action.kind.is_empty(): return
	if not fishing_stage.is_empty():
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var direction := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
		inventory_state.select_hotbar(inventory_state.selected_hotbar + direction)
		var item: Dictionary = _inventory_items().get(str(inventory_state.hotbar[inventory_state.selected_hotbar]), {})
		if str(item.get("kind", "")) == "tool": current_tool = str(item.get("tool_id", current_tool))
		elif str(item.get("kind", "")) == "sapling":
			current_tool = "sapling"
			current_sapling_id = str(item.get("tree_id", current_sapling_id))
		farm_audio.play("select")
		_update_farm_hud()
		get_viewport().set_input_as_handled()
		return
	var cell := _cell_from_world_position(get_viewport_transform().affine_inverse() * event.position)
	var direction := cell - player_cell
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
	if current_tool == "sword": return Mining.is_mine(current_map_id) and _monster_in_sword_arc() != null
	if current_tool == "pickaxe": return not mining.vein(current_map_id, cell, farm.day).is_empty()
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
	return pet != null and pet.visible and pet.position.distance_to(player_body.position) < 52 and navigation.has_clear_line(current_map_id, player_body.position, pet.position)

func _nearby_pickup() -> Dictionary:
	for item in homestead.available(current_map_id, farm.day, navigation):
		var difference: Vector2i = item.cell - player_cell
		if absi(difference.x) + absi(difference.y) <= 1 and navigation.has_clear_line(current_map_id, player_body.position, world.cell_center_to_screen(item.cell)): return item
	return {}

func _context_text() -> String:
	var target := _interaction_target()
	match str(target.get("kind", "")):
		"facility": return "F / 右键 · " + _interaction_name(str(target.record.get("target", "")))
		"pickup": return "F 拾取" + str(Homestead.RESOURCE_NAMES[target.item.kind])
		"animal": return "F 抚摸小鸡"
		"duck": return "F 抚摸小鸭"
		"cow": return "F 挤牛奶" if _cow_milk_hint(str(target.get("id", ""))) else "F 抚摸奶牛"
		"orchard": return "F 摘" + str(Orchard.TREE_TYPES[str(target.tree.type)].name)
		"pet": return "P 麦麦在休息" if pet.sleeping else "F 摸摸麦麦 · P 照料"
		"npc": return "F 交谈 · G 送礼"
	return ""


func _interaction_target() -> Dictionary:
	for cell in [player_cell, player_cell + _facing_delta(player.facing)]:
		var record := navigation.interaction_at(current_map_id, cell)
		if not record.is_empty() and navigation.has_clear_line(current_map_id, player_body.position, world.cell_center_to_screen(cell)):
			return {"kind": "facility", "record": record, "cell": cell}
		if animals.coop_built and _is_farm_area(cell) and _animal_local_cell(cell) == Animals.COOP_INTERACTION_CELL:
			return {"kind": "facility", "record": {"target": "coop"}, "cell": cell}
		if animals.barn_built and _is_farm_area(cell) and _animal_local_cell(cell) == Animals.BARN_INTERACTION_CELL:
			return {"kind": "facility", "record": {"target": "barn"}, "cell": cell}
		if _is_farm_area(cell):
			var fruit_tree: Dictionary = orchard.tree(_animal_local_cell(cell))
			if not fruit_tree.is_empty() and orchard.has_fruit(fruit_tree, farm.day):
				return {"kind": "orchard", "cell": cell, "tree": fruit_tree}
		var structure_id: String = farm.structure_at(cell) if _is_farm_area(cell) else ""
		if Processing.is_machine(structure_id):
			return {"kind": "facility", "record": {"target": "processing_machine", "machine": structure_id}, "cell": cell}
	var item := _nearby_pickup()
	if not item.is_empty(): return {"kind": "pickup", "item": item}
	var poultry := _nearby_poultry()
	if not poultry.is_empty(): return poultry
	var cow_id := _nearby_cow_id()
	if not cow_id.is_empty(): return {"kind": "cow", "id": cow_id}
	if _pet_is_near(): return {"kind": "pet"}
	var actor := _nearby_npc_actor()
	if not actor.is_empty(): return {"kind": "npc", "actor": actor}
	return {}


func _interaction_npc_actor() -> String:
	var target := _interaction_target()
	return str(target.get("actor", "")) if str(target.get("kind", "")) == "npc" else ""


func _nearby_chicken_id() -> String:
	for id in chicken_actors:
		var actor = chicken_actors[id]
		if actor.visible and actor.position.distance_to(player_body.position) < 48.0:
			return str(id)
	return ""


func _nearby_duck_id() -> String:
	for id in duck_actors:
		var actor = duck_actors[id]
		if actor.visible and actor.position.distance_to(player_body.position) < 48.0:
			return str(id)
	return ""


func _nearby_poultry() -> Dictionary:
	var closest_kind := ""
	var closest_id := ""
	var closest_distance := 52.0
	for id in chicken_actors:
		var actor = chicken_actors[id]
		var distance: float = actor.position.distance_to(player_body.position)
		if actor.visible and distance < closest_distance:
			closest_distance = distance
			closest_kind = "animal"
			closest_id = str(id)
	for id in duck_actors:
		var actor = duck_actors[id]
		var distance: float = actor.position.distance_to(player_body.position)
		if actor.visible and distance < closest_distance:
			closest_distance = distance
			closest_kind = "duck"
			closest_id = str(id)
	return {"kind": closest_kind, "id": closest_id} if not closest_id.is_empty() else {}


func _nearby_cow_id() -> String:
	for id in cow_actors:
		var actor = cow_actors[id]
		if actor.visible and actor.position.distance_to(player_body.position) < 58.0:
			return str(id)
	return ""


func _cow_milk_hint(id: String) -> bool:
	var entry: Dictionary = animals.cow(id)
	if entry.is_empty(): return false
	return int(entry.age) >= 1 and int(entry.milked_day) != farm.day and (int(entry.fed_day) == farm.day or int(entry.fed_day) == farm.day - 1)


func _interact_cow(id: String) -> void:
	if not cow_actors.has(id) or not actor_action.kind.is_empty(): return
	var actor = cow_actors[id]
	if not actor.visible or actor.position.distance_to(player_body.position) >= 62.0: return
	var direction: Vector2 = actor.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "pet")
	var milky := _cow_milk_hint(id)
	actor_action.start("pet", func():
		var result: Dictionary = animals.milk_cow(id, farm.day) if milky else animals.pet_cow(id, farm.day)
		if result.ok:
			actor.show_affection()
			farm_audio.play("pet")
			if milky:
				_sync_inventory()
				_update_farm_hud()
		_set_status(str(result.message))
		_save_game())


func _pet_chicken(id: String) -> void:
	if not chicken_actors.has(id) or not actor_action.kind.is_empty(): return
	var actor = chicken_actors[id]
	if not actor.visible or actor.position.distance_to(player_body.position) >= 52.0: return
	var direction: Vector2 = actor.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "pet")
	actor_action.start("pet", func():
		var result: Dictionary = animals.pet(id, farm.day)
		if result.ok:
			actor.show_affection()
			farm_audio.play("pet")
		_set_status(str(result.message))
		_save_game())


func _pet_duck(id: String) -> void:
	if not duck_actors.has(id) or not actor_action.kind.is_empty(): return
	var actor = duck_actors[id]
	if not actor.visible or actor.position.distance_to(player_body.position) >= 52.0: return
	var direction: Vector2 = actor.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "pet")
	actor_action.start("pet", func():
		var result: Dictionary = animals.pet_duck(id, farm.day)
		if result.ok:
			actor.show_affection()
			farm_audio.play("pet")
		_set_status(str(result.message))
		_save_game())

func _collect_pickup(item: Dictionary) -> void:
	if not actor_action.kind.is_empty(): return
	actor_action.start("harvest", func():
		if homestead.collect(item, farm.day):
			var amount := skills.forage_amount()
			if amount > 1: homestead.resources[item.kind] += amount - 1
			var growth := _gain_skill("foraging", 7)
			farm_audio.play("harvest")
			feedback.burst(world.cell_center_to_screen(item.cell), "+%d %s" % [amount, Homestead.RESOURCE_NAMES[item.kind]])
			scenery.refresh()
			_sync_inventory()
			_update_farm_hud()
			_set_status("拾取了%s ×%d，已放入背包。%s" % [Homestead.RESOURCE_NAMES[item.kind], amount, growth])
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
	life_panel.paragraph("坐下来休息片刻吧。当前体力 %d / 100，生命 %d / %d，金币 %d。" % [energy, combat.health, Combat.MAX_HEALTH, farm.gold])
	life_panel.action("治疗 · 30 金，恢复全部体力" if clinic else "热饮和点心 · 15 金，恢复 35 体力", func():
		var price := 30 if clinic else 15
		if energy >= _energy_cap() and (not clinic or combat.health >= Combat.MAX_HEALTH):
			life_panel.paragraph("你现在精神很好，暂时不需要恢复。")
			return
		if farm.gold < price:
			life_panel.paragraph("金币不足，改天再来吧。")
			return
		farm.gold -= price
		energy = mini(_energy_cap(), energy + (_energy_cap() if clinic else 35))
		if clinic: combat.heal_full()
		_update_farm_hud()
		_save_game()
		_open_service(kind))

func _update_player_movement(delta: float) -> void:
	if entering_door or not actor_action.kind.is_empty() or not fishing_stage.is_empty():
		_stop_player()
		return
	if not queued_use.is_empty():
		_stop_player()
		_perform_queued_use()
		return
	var direction := Vector2(_pressed_direction()).normalized()
	player.running = Input.is_key_pressed(KEY_SHIFT)
	if direction == Vector2.ZERO:
		_stop_player()
		return
	var facing := player.facing
	if direction.x == 0: facing = "up" if direction.y < 0 else "down"
	elif direction.y == 0: facing = "left" if direction.x < 0 else "right"
	elif Vector2(_facing_delta(facing)).dot(direction) <= 0:
		facing = "left" if direction.x < 0 else "right"
	player.set_pose(facing, "idle")
	var before := player_body.position
	player_body.velocity = direction * WALK_SPEED * (1.65 if player.running else 1.0)
	var motion := player_body.velocity * delta
	var resident_contacts: Dictionary = {}
	# Explicit delta keeps motion deterministic in replay and gameplay tests.
	# Sliding preserves wall movement; residents yield only after a brief bump.
	for contact in 3:
		var collision := player_body.move_and_collide(motion)
		if collision == null: break
		var collider = collision.get_collider()
		if collider is StaticBody2D and collider.name == "ResidentFootBody":
			var resident_id := str(collider.get_parent().name).trim_prefix("Resident_")
			resident_contacts[resident_id] = true
			var blocked_for := float(_resident_bump_elapsed.get(resident_id, 0.0)) + delta
			if blocked_for >= RESIDENT_BUMP_SECONDS:
				# Like the familiar soft push-through in farm sims, one resident
				# cannot permanently seal a narrow doorway or the only road tile.
				collider.collision_layer = 0
				_resident_pass_through[resident_id] = collider
				_resident_bump_elapsed.erase(resident_id)
				motion = collision.get_remainder()
			else:
				_resident_bump_elapsed[resident_id] = blocked_for
				motion = collision.get_remainder().slide(collision.get_normal())
		else:
			motion = collision.get_remainder().slide(collision.get_normal())
		if motion.length_squared() < 0.000001: break
	for resident_id in _resident_bump_elapsed.keys():
		if resident_contacts.has(resident_id): continue
		var resident_state: Dictionary = npcs.get(resident_id, {})
		if resident_state.is_empty() or not is_instance_valid(resident_state.get("node")) or player_body.position.distance_to(resident_state.node.position) > 24.0:
			_resident_bump_elapsed.erase(resident_id)
	var bounds := Vector2(navigation.get_map_size(current_map_id)) * WorldRenderer.TILE_SIZE
	player_body.position = player_body.position.clamp(Vector2(9, 7), bounds - Vector2(9, 7))
	var distance := before.distance_to(player_body.position)
	moving = distance > 0.001
	if moving:
		player.advance_stride(distance)
		footstep_distance += distance
		var footfall_spacing := 40.0 if player.running else 32.0
		while footstep_distance >= footfall_spacing:
			footstep_distance -= footfall_spacing
			farm_audio.play_footstep(_footstep_surface(player_body.position), player.running)
		player.set_pose(facing, "walk")
	else:
		# A stopped or blocked farmer returns to a planted first pose. Resuming
		# from a frozen airborne phase makes the feet pop into motion.
		player.stride = 0.0
		player.set_pose(facing, "idle")
	var old_cell := player_cell
	player_cell = _cell_from_world_position(player_body.position)
	if player_cell != old_cell:
		_stream_world(false)
		_after_arrival()


func _footstep_surface(world_position: Vector2) -> String:
	var cell := _cell_from_world_position(world_position)
	var surface := str(navigation.get_cell_layers(current_map_id, cell).get("surface", "grass"))
	match surface:
		"sand": return "sand"
		"boardwalk": return "wood"
		"cave_floor": return "stone"
		"tillable": return "soil"
		"path": return "wood" if current_map_id.ends_with("_interior") else "path"
		_: return "grass"


func _stop_player() -> void:
	moving = false
	player_body.velocity = Vector2.ZERO
	player.stride = 0.0
	player.set_pose(player.facing, "idle")

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

func _pressed_direction() -> Vector2i:
	var horizontal := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var vertical := int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	return Vector2i(horizontal, vertical)

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
	if festival_hunt != null and festival_hunt.active: return
	if entering_door or not actor_action.kind.is_empty(): return
	if moving:
		queued_use = "interact"
		queued_use_cell = Vector2i(-1, -1)
		return
	var selected := _interaction_target()
	var interaction: Dictionary = selected.get("record", {})
	var door_cell: Vector2i = selected.get("cell", player_cell)
	if not interaction.is_empty():
		# Doorways and counters are precise authored tiles.  They win over a
		# nearby NPC so an NPC route can never make a building impossible to enter.
		player.set_pose(player.facing, "use")
		var target := str(interaction.get("target", ""))
		if target.ends_with("_interior") and navigation.has_map(target):
			_enter_door(target, navigation.get_spawn(target), door_cell)
			return
		match target:
			"mine_return":
				_change_map("cave", Vector2i(18, 25))
			"mine_down":
				var floor_number := 2 if current_map_id == "cave" else 3
				if int(mining.tools.pickaxe) < floor_number - 1:
					_set_status("下层岩石坚硬，需要%s镐。可在镇上种子铺委托升级。" % ("铜" if floor_number == 2 else "铁"))
				else:
					mining.deepest = maxi(mining.deepest, floor_number)
					_change_map("mine_%d" % floor_number, Vector2i(18, 23))
					_save_game()
			"signpost":
				_stop_player()
				life_panel.open(str(interaction.get("title", "路标")))
				life_panel.paragraph(str(interaction.get("text", "")))
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
			"fireplace": _open_crafting()
			"shop_counter": _open_shop()
			"clinic_counter": _open_service("clinic")
			"cafe_counter": _open_service("cafe")
			"coop": _open_coop()
			"barn": _open_barn()
			"processing_machine": _open_processing_machine(door_cell)
			"shipping_box":
				var shipping: Dictionary = farm.ship_all(skills.crop_price_multiplier())
				var forage_earned: int = homestead.ship() + fishing.ship()
				farm.gold += forage_earned
				var animal_earned: int = animals.ship(farm)
				var artisan_earned: int = processing.ship(farm)
				var orchard_earned: int = orchard.ship(farm)
				_sync_inventory()
				_set_status("出货箱：售出 %d 金币。当前金币 %d。" % [int(shipping.get("earned", 0)) + forage_earned + animal_earned + artisan_earned + orchard_earned, farm.gold])
				_update_farm_hud()
				_save_game()
			"well":
				homestead.water = Homestead.WATER_CAPACITY
				_update_farm_hud()
				_set_status("清凉的井水装满了浇水壶（24 / 24）。")
				feedback.burst(player_body.position, "补满水", Color("a8e5f1"))
				_save_game()
			"notice_board": _open_festival()
			"community_center": _open_community_center()
			_: _set_status("%s：该场景将在后续开放。" % _interaction_name(target))
		return
	var pickup: Dictionary = selected.get("item", {})
	if not pickup.is_empty():
		_collect_pickup(pickup)
		return
	if selected.get("kind", "") == "animal":
		_pet_chicken(str(selected.get("id", "")))
		return
	if selected.get("kind", "") == "duck":
		_pet_duck(str(selected.get("id", "")))
		return
	if selected.get("kind", "") == "cow":
		_interact_cow(str(selected.get("id", "")))
		return
	if selected.get("kind", "") == "orchard":
		_collect_orchard_fruit(selected.cell)
		return
	if selected.get("kind", "") == "pet":
		_pet_dog()
		return
	var nearby_npc := str(selected.get("actor", ""))
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
		door_tween.tween_method(_set_door_open, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Start covering as the facade animation nears its last frames, then keep
		# the scene swap gated on the door reaching its fully open pose.
		await get_tree().create_timer(0.11).timeout
		await scene_transition.play_gated(_change_map.bind(target, arrival), door_tween.finished, Callable(door_tween, "is_running"))
	else:
		# Interior exits deliberately have no door-leaf animation.
		await scene_transition.play(_change_map.bind(target, arrival))
	world.active_door = Vector2i(-1, -1)
	world.door_open = 0.0
	world.queue_redraw()
	entering_door = false


func _set_door_open(value: float) -> void:
	world.door_open = value
	world.queue_redraw()


func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
	if festival_hunt != null and festival_hunt.active and next_map_id != "town_square": festival_hunt.cancel()
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
	animal_collision_cells.clear()
	footstep_distance = 0.0
	var size := navigation.get_map_size(current_map_id)
	var map_size_px: Vector2 = Vector2(size) * WorldRenderer.TILE_SIZE
	_activate_world(current_map_id)
	world.configure(navigation, current_map_id, Vector2.ZERO, next_cell)
	world.refresh_season()
	collision_stream_center = Vector2i(-999, -999)
	game_camera.limit_left = 0
	game_camera.limit_top = 44
	game_camera.limit_right = int(map_size_px.x)
	game_camera.limit_bottom = int(map_size_px.y)
	game_camera.offset = Vector2.ZERO
	player_cell = next_cell if navigation.is_walkable(current_map_id, next_cell) else navigation.get_spawn(current_map_id)
	player_body.position = _avatar_position_for(player_cell)
	# Teleport first, then reset smoothing. Otherwise the centre-light reveal can
	# expose a frame interpolated from the previous map's unrelated coordinates.
	game_camera.reset_smoothing()
	moving = false
	transition_lock_frames = 1
	player.set_pose("down", "idle")
	_stream_world(true)
	if Mining.is_mine(current_map_id):
		for cell in Mining.cells_for_floor(current_map_id): _sync_collision_cell(cell)
	_spawn_map_npcs()
	if pet != null:
		pet.home_cell = navigation.to_contiguous_world("farm_outdoor", Vector2i(21, 11)) if continuous_world_enabled else Vector2i(21, 11)
		pet.world_map_id = current_map_id
		pet.visible = current_map_id == "valley_world" or current_map_id == "farm_outdoor"
		pet.reset_home()
		pet.rebuild_grid()
		pet.tick(0, player_body.position, clock_minutes)
		scenery.refresh()
	_sync_chicken_actors()
	_sync_duck_actors()
	_sync_cow_actors()
	_sync_monster_actors()
	_update_location()
	_update_farm_hud()
	_set_status("%s · WASD 行走，Shift 跑步；走到门口自动进入，F 与设施互动。" % _location_name())


func _activate_world(map_id: String) -> void:
	if world.map_id.is_empty():
		_world_cache[map_id] = world
	elif world.map_id != map_id:
		world.active_door = Vector2i(-1, -1)
		world.door_open = 0.0
		world.hide()
		world.set_process(false)
		if _world_cache.has(map_id):
			world = _world_cache[map_id]
		else:
			world = WorldRendererScript.new()
			add_child(world)
			world.set_farm_state(farm)
			world.set_animal_state(animals)
			world.set_processing_state(processing)
			world.set_orchard_state(orchard)
			world.set_community_state(community)
			_world_cache[map_id] = world
	world.show()
	world.set_process(true)
	_world_cache_order.erase(map_id)
	_world_cache_order.append(map_id)
	while _world_cache_order.size() > WORLD_CACHE_LIMIT:
		var evicted: String = _world_cache_order.pop_front()
		var old_world: WorldRenderer = _world_cache[evicted]
		_world_cache.erase(evicted)
		old_world.queue_free()


func _rebuild_world_collisions(immediate := true) -> void:
	if collision_root == null:
		return
	var map_size := navigation.get_map_size(current_map_id)
	var bounds := Rect2i(Vector2i.ZERO, map_size)
	if current_map_id == "valley_world":
		var visible_pixels := get_viewport_rect().size
		var camera_zoom := game_camera.zoom
		var collision_margin := Vector2i(3, 3)
		var collision_radius := Vector2i(
			ceili(visible_pixels.x / maxf(camera_zoom.x, 0.01) / WorldRenderer.TILE_SIZE * 0.5) + collision_margin.x,
			ceili(visible_pixels.y / maxf(camera_zoom.y, 0.01) / WorldRenderer.TILE_SIZE * 0.5) + collision_margin.y
		)
		bounds = Rect2i(player_cell - collision_radius, collision_radius * 2 + Vector2i.ONE).intersection(bounds)
	if not immediate and current_map_id == "valley_world" and collision_stream_map_id == current_map_id:
		_schedule_collision_stream(bounds)
		return
	pending_collision_additions.clear()
	pending_collision_removals.clear()
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


func _schedule_collision_stream(bounds: Rect2i) -> void:
	pending_collision_additions.clear()
	pending_collision_removals.clear()
	for cell_value in active_collision_cells.keys():
		var cell: Vector2i = cell_value
		if not bounds.has_point(cell): pending_collision_removals.append(cell)
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if not active_collision_cells.has(cell): pending_collision_additions.append(cell)
	collision_stream_bounds = bounds
	collision_stream_map_id = current_map_id


func _process_collision_stream_queue() -> void:
	var processed := 0
	while processed < COLLISION_STREAM_BUDGET and not pending_collision_additions.is_empty():
		var cell: Vector2i = pending_collision_additions.pop_front()
		if collision_stream_bounds.has_point(cell) and not active_collision_cells.has(cell): _sync_collision_cell(cell)
		processed += 1
	while processed < COLLISION_STREAM_BUDGET and not pending_collision_removals.is_empty():
		var cell: Vector2i = pending_collision_removals.pop_front()
		if not collision_stream_bounds.has_point(cell) and active_collision_cells.has(cell): _release_collision_cell(cell)
		processed += 1


func _on_window_size_changed() -> void:
	if collision_view_refresh_pending:
		return
	collision_view_refresh_pending = true
	call_deferred("_refresh_collision_view")


func _refresh_collision_view() -> void:
	collision_view_refresh_pending = false
	if world == null or navigation == null:
		return
	_stream_world(true)


func _prime_collision_pool() -> void:
	for index in STREAM_COLLISION_POOL_SIZE:
		var shape_node := CollisionShape2D.new()
		shape_node.name = "PooledObstacle_%d" % index
		shape_node.position = Vector2(-100000, -100000)
		shape_node.shape = streamed_collision_shape
		collision_root.add_child(shape_node)
		collision_shape_pool.append(shape_node)


func _sync_collision_cell(cell: Vector2i) -> void:
	var crop_occupied: bool = _is_farm_area(cell) and farm.is_field_occupied(cell)
	var animal_solid: bool = _is_farm_area(cell) and animals.is_solid(_animal_local_cell(cell))
	var tree_solid: bool = _is_farm_area(cell) and orchard.is_solid(_animal_local_cell(cell))
	var needs_collision: bool = not navigation.is_walkable(current_map_id, cell, crop_occupied) or not mining.vein(current_map_id, cell, farm.day).is_empty() or animal_solid or tree_solid
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


func _animal_map_offset() -> Vector2i:
	return navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO) if current_map_id == "valley_world" else Vector2i.ZERO


func _animal_local_cell(cell: Vector2i) -> Vector2i:
	return cell - _animal_map_offset()


func _animal_world_cell(cell: Vector2i) -> Vector2i:
	return cell + _animal_map_offset()


func _refresh_animal_collisions() -> void:
	if current_map_id not in ["farm_outdoor", "valley_world"]:
		return
	for previous in animal_collision_cells:
		if collision_stream_bounds.has_point(previous): _sync_collision_cell(previous)
	animal_collision_cells.clear()
	for local_cell in animals.structure_cells():
		var cell := _animal_world_cell(local_cell)
		animal_collision_cells.append(cell)
		if collision_stream_bounds.has_point(cell): _sync_collision_cell(cell)
	for tree in orchard.trees:
		var cell := _animal_world_cell(Vector2i(int(tree.x), int(tree.y)))
		animal_collision_cells.append(cell)
		if collision_stream_bounds.has_point(cell): _sync_collision_cell(cell)
	pet.rebuild_grid()


func _sync_chicken_actors() -> void:
	var retained := {}
	for index in animals.chickens.size():
		var entry: Dictionary = animals.chickens[index]
		var id := str(entry.id)
		var actor = chicken_actors.get(id)
		if actor == null:
			actor = ChickenActor.new()
			actor.name = id
			add_child(actor)
			chicken_actors[id] = actor
		actor.configure(id, index, _animal_map_offset())
		actor.visible = animals.coop_built and current_map_id in ["farm_outdoor", "valley_world"] and clock_minutes < 1200 and Calendar.weather(farm.day) != "雨"
		retained[id] = true
	for id in chicken_actors.keys():
		if retained.has(id): continue
		chicken_actors[id].queue_free()
		chicken_actors.erase(id)


func _tick_chickens(delta: float) -> void:
	if current_map_id not in ["farm_outdoor", "valley_world"] or not animals.coop_built:
		for actor in chicken_actors.values(): actor.hide()
		return
	var roam: Array[Vector2i] = animals.roam_cells()
	for actor in chicken_actors.values():
		actor.set_map_offset(_animal_map_offset())
		actor.tick(delta, roam, clock_minutes, Calendar.weather(farm.day))


func _sync_duck_actors() -> void:
	var retained := {}
	for index in animals.ducks.size():
		var entry: Dictionary = animals.ducks[index]
		var id := str(entry.id)
		var actor = duck_actors.get(id)
		if actor == null:
			actor = DuckActor.new()
			actor.name = id
			add_child(actor)
			duck_actors[id] = actor
		actor.configure(id, index, _animal_map_offset())
		actor.visible = animals.coop_built and current_map_id in ["farm_outdoor", "valley_world"] and clock_minutes < 1200 and Calendar.weather(farm.day) != "雨"
		retained[id] = true
	for id in duck_actors.keys():
		if retained.has(id): continue
		duck_actors[id].queue_free()
		duck_actors.erase(id)


func _tick_ducks(delta: float) -> void:
	if current_map_id not in ["farm_outdoor", "valley_world"] or not animals.coop_built:
		for actor in duck_actors.values(): actor.hide()
		return
	var roam: Array[Vector2i] = animals.roam_cells()
	for actor in duck_actors.values():
		actor.set_map_offset(_animal_map_offset())
		actor.tick(delta, roam, clock_minutes, Calendar.weather(farm.day))


func _sync_cow_actors() -> void:
	var retained := {}
	for index in animals.cows.size():
		var entry: Dictionary = animals.cows[index]
		var id := str(entry.id)
		var actor = cow_actors.get(id)
		if actor == null:
			actor = CowActor.new()
			actor.name = id
			add_child(actor)
			cow_actors[id] = actor
		actor.configure(id, index, _animal_map_offset())
		actor.visible = animals.barn_built and current_map_id in ["farm_outdoor", "valley_world"] and clock_minutes < 1200 and Calendar.weather(farm.day) != "雨"
		retained[id] = true
	for id in cow_actors.keys():
		if retained.has(id): continue
		cow_actors[id].queue_free()
		cow_actors.erase(id)


func _tick_cows(delta: float) -> void:
	if current_map_id not in ["farm_outdoor", "valley_world"] or not animals.barn_built:
		for actor in cow_actors.values(): actor.hide()
		return
	var roam: Array[Vector2i] = animals.barn_roam_cells()
	for actor in cow_actors.values():
		actor.set_map_offset(_animal_map_offset())
		actor.tick(delta, roam, clock_minutes, Calendar.weather(farm.day))


func _sync_monster_actors() -> void:
	for actor in monster_actors.values():
		if is_instance_valid(actor): actor.queue_free()
	monster_actors.clear()
	if not Mining.is_mine(current_map_id): return
	for entry in combat.ensure_map(current_map_id, farm.day):
		var actor = MonsterActor.new()
		actor.name = "Monster_" + str(entry.id).replace(":", "_")
		add_child(actor)
		actor.configure(entry, navigation, mining, combat)
		monster_actors[str(entry.id)] = actor


func _tick_monsters(delta: float) -> void:
	combat_invulnerability = maxf(0.0, combat_invulnerability - delta)
	if not Mining.is_mine(current_map_id): return
	for id in monster_actors.keys():
		var actor = monster_actors[id]
		if not is_instance_valid(actor): continue
		actor.tick(delta, player_body.position, farm.day)
		if combat_invulnerability > 0.0 or actor.position.distance_to(player_body.position) >= 25.0: continue
		var entry: Dictionary = combat.monster(str(id))
		if entry.is_empty(): continue
		var damage: int = int(Combat.DEFINITIONS[str(entry.type)].damage)
		var result: Dictionary = combat.take_damage(damage)
		combat_invulnerability = 1.0
		var away: Vector2 = (player_body.position - Vector2(actor.position)).normalized()
		var candidate: Vector2 = player_body.position + away * 18.0
		var cell := _cell_from_world_position(candidate)
		if navigation.is_walkable(current_map_id, cell):
			player_body.position = candidate
			player_cell = cell
		_update_farm_hud()
		_set_status("受到%d点伤害，生命剩余%d。" % [int(result.damage), int(result.health)])
		if bool(result.fainted):
			_faint_in_mine()
			return


func _monster_in_sword_arc():
	var direction := Vector2(_facing_delta(player.facing))
	var best = null
	var best_distance := 57.0
	for actor in monster_actors.values():
		if not is_instance_valid(actor): continue
		var offset: Vector2 = actor.position - player_body.position
		var distance := offset.length()
		if distance <= 0.01 or distance >= best_distance or direction.dot(offset.normalized()) < 0.15: continue
		if not navigation.has_clear_line(current_map_id, player_body.position, actor.position): continue
		best = actor
		best_distance = distance
	return best


func _sword_action() -> void:
	if not Mining.is_mine(current_map_id):
		_set_status("长剑主要用于矿洞防身。")
		return
	var map_id := current_map_id
	actor_action.start("sword", func():
		if current_map_id != map_id: return
		var actor = _monster_in_sword_arc()
		if actor == null:
			_set_status("挥剑落空；靠近怪物并面向它。")
			return
		var id: String = str(actor.monster_id)
		var result: Dictionary = combat.strike(id, skills.combat_damage())
		if not bool(result.get("ok", false)): return
		actor.show_hit(player_body.position)
		if bool(result.defeated):
			var drop := str(result.drop)
			homestead.resources[drop] = int(homestead.resources.get(drop, 0)) + int(result.amount)
			var growth := _gain_skill("combat", int(result.xp))
			feedback.burst(actor.position, "%s +%d" % [Homestead.RESOURCE_NAMES[drop], int(result.amount)])
			monster_actors.erase(id)
			actor.queue_free()
			_sync_inventory()
			_set_status("击败怪物，获得%s×%d。%s" % [Homestead.RESOURCE_NAMES[drop], int(result.amount), growth])
		else:
			_set_status("命中怪物，剩余生命 %d / %d。" % [int(result.health), int(result.max_health)])
		_update_farm_hud()
		_save_game())
	player.action_progress = 0.0
	player.set_pose(player.facing, "sword")


func _faint_in_mine() -> void:
	var lost := mini(100, maxi(10, farm.gold / 10)) if farm.gold > 0 else 0
	if lost > 0:
		farm.gold -= lost
		farm.gold_changed.emit(farm.gold, -lost)
	combat.health = Combat.MAX_HEALTH / 2
	clock_minutes = mini(1320, clock_minutes + 120)
	_change_map("farm_outdoor", navigation.get_spawn("farm_outdoor"))
	_set_status("你在矿洞中昏倒，被送回农场；丢失%d金币，生命恢复至%d。" % [lost, combat.health])
	_save_game()


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
		_rebuild_world_collisions(force)


func _spawn_map_npcs() -> void:
	resident_schedule = _resident_signature()
	var present: Dictionary = {}
	for actor in VillageScript.PEOPLE:
		var activity_map: String = _scheduled_activity_map(str(actor))
		if current_map_id == "valley_world":
			if activity_map.ends_with("_interior"): continue
		elif activity_map != current_map_id: continue
		present[actor] = activity_map
	for actor in npcs.keys():
		if present.has(actor): continue
		var stale: Dictionary = npcs[actor]
		if is_instance_valid(stale.get("node")): stale.node.queue_free()
		_resident_bump_elapsed.erase(str(actor))
		_resident_pass_through.erase(str(actor))
		npcs.erase(actor)
	for actor in present:
		var activity_map: String = str(present[actor])
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
			if npcs.has(actor):
				npcs[actor].node.queue_free()
				_resident_bump_elapsed.erase(str(actor))
				_resident_pass_through.erase(str(actor))
				npcs.erase(actor)
			continue
		if npcs.has(actor):
			var retained: Dictionary = npcs[actor]
			retained.route = route
			retained.index = clampi(int(retained.index), 0, route.size() - 1)
			continue
		var npc = ArtActorScript.new()
		npc.name = "Resident_" + str(actor)
		npc.z_index = 3
		var walk_columns := 8 if str(actor) in ["mayor", "carpenter", "doctor", "cook", "ranger", "teacher", "child"] else 4
		npc.configure(_npc_walk_texture(actor), _npc_idle_texture(actor), 0.13, _npc_idle_column(actor), 10, 3, NPC_WALK_TINTS.get(actor, Color.WHITE), not NPC_ART.has(str(actor)), walk_columns, 4)
		npc.set_pose("down", "idle")
		var resident_body := StaticBody2D.new()
		resident_body.name = "ResidentFootBody"
		resident_body.collision_layer = 1
		resident_body.collision_mask = 0
		var resident_footprint := CollisionShape2D.new()
		var resident_circle := CircleShape2D.new()
		resident_circle.radius = 7.0
		resident_footprint.shape = resident_circle
		resident_body.add_child(resident_footprint)
		npc.add_child(resident_body)
		var start_index := mini(7, route.size() - 1) if str(actor) == "florist" else 0
		npc.position = _avatar_position_for(route[start_index]) + Vector2(0, 1)
		add_child(npc)
		npcs[actor] = {"node": npc, "route": route, "index": start_index, "timer": 0.0}


func _scheduled_activity_map(actor: String) -> String:
	var map_id: String = str(village.activity(actor, farm.day, clock_minutes).map)
	if continuous_world_enabled:
		if map_id == "beach": return "riverside"
		if map_id == "countryside": return "farm_outdoor"
	return map_id

func _resident_signature() -> String:
	var signature := ""
	for actor in VillageScript.PEOPLE: signature += actor + _scheduled_activity_map(str(actor))
	return signature


func _npc_walk_texture(actor: String) -> Texture2D:
	return NPC_ART.get(actor, NPC_ART["florist"])


func _npc_idle_texture(actor: String) -> Texture2D:
	return NPC_CAST_IDLE_ART


func _npc_idle_column(actor: String) -> int:
	return int(NPC_CAST_COLUMNS.get(actor, 0))


func _npc_walk_route(checkpoints: Array[Vector2i]) -> Array[Vector2i]:
	return navigation.patrol_route(current_map_id, checkpoints)


func _nearby_npc_actor() -> String:
	var closest := ""
	var nearest_distance := WorldRenderer.TILE_SIZE * 1.65
	for actor in npcs.keys():
		var state: Dictionary = npcs[actor]
		var route: Array = state.get("route", [])
		var distance: float = player_body.position.distance_to(state.node.position)
		if not route.is_empty() and distance < nearest_distance and navigation.has_clear_line(current_map_id, player_body.position, state.node.position):
			closest = str(actor)
			nearest_distance = distance
	return closest


func _update_npcs(delta: float) -> void:
	for actor in npcs.keys():
		var state: Dictionary = npcs[actor]
		var npc = state.node
		if _resident_pass_through.has(actor):
			var resident_body = _resident_pass_through[actor]
			if not is_instance_valid(resident_body) or player_body.position.distance_to(npc.position) > 22.0:
				if is_instance_valid(resident_body): resident_body.collision_layer = 1
				_resident_pass_through.erase(actor)
		# Stop to greet an approaching player. Panels pause the village clock.
		if npc.position.distance_to(player_body.position) < 50 and navigation.has_clear_line(current_map_id, npc.position, player_body.position):
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
	strip.size = Vector2(1280, 58)
	layer.add_child(strip)
	hud_location = Label.new()
	hud_location.position = Vector2(18, 10)
	hud_location.size = Vector2(232, 30)
	hud_location.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud_location.add_theme_font_size_override("font_size", 18)
	hud_location.add_theme_color_override("font_color", Color("#fff3d5"))
	layer.add_child(hud_location)
	hud_hint = Label.new()
	hud_hint.position = Vector2(824, 14)
	hud_hint.size = Vector2(265, 24)
	hud_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_hint.add_theme_color_override("font_color", Color("#edd4a3"))
	layer.add_child(hud_hint)
	hud_hint.add_theme_font_size_override("font_size", 14)
	hud_day = Label.new()
	hud_day.position = Vector2(260, 10)
	hud_day.size = Vector2(560, 30)
	hud_day.add_theme_color_override("font_color", Color("fff3d5"))
	hud_day.add_theme_font_size_override("font_size", 15)
	layer.add_child(hud_day)
	hud_tool_icon = TextureRect.new()
	hud_tool_icon.position = Vector2(1100, 12)
	hud_tool_icon.size = Vector2(30, 30)
	hud_tool_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_tool_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(hud_tool_icon)
	hud_status_panel = PanelContainer.new()
	hud_status_panel.position = Vector2(22, 590)
	hud_status_panel.size = Vector2(760, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff3d7", 0.94)
	style.border_color = Color("#86542e")
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	style.shadow_color = Color(0.20, 0.12, 0.04, 0.28)
	style.shadow_size = 4
	hud_status_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(hud_status_panel)
	hud_status = Label.new()
	hud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_status.add_theme_color_override("font_color", Color("#483b34"))
	hud_status_panel.add_child(hud_status)
	hud_context = Label.new()
	hud_context.position = Vector2(26, 559)
	hud_context.add_theme_font_size_override("font_size", 18)
	hud_context.add_theme_color_override("font_color", Color("fff3d5"))
	hud_context.add_theme_color_override("font_outline_color", Color("493726"))
	hud_context.add_theme_constant_override("outline_size", 6)
	var context_style := StyleBoxFlat.new()
	context_style.bg_color = Color("70482d", 0.94)
	context_style.set_content_margin_all(5)
	context_style.set_corner_radius_all(3)
	hud_context.add_theme_stylebox_override("normal", context_style)
	hud_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_context)
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
	hud_hotbar_info.position = Vector2(900, 590)
	hud_hotbar_info.size = Vector2(220, 48)
	hud_hotbar_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_hotbar_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_hotbar_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_hotbar_info.add_theme_font_size_override("font_size", 16)
	hud_hotbar_info.add_theme_stylebox_override("normal", style)
	hud_hotbar_info.add_theme_color_override("font_color", Color("483b34"))
	hud_hotbar_info.add_theme_color_override("font_outline_color", Color("493526"))
	hud_hotbar_info.add_theme_constant_override("outline_size", 0)
	layer.add_child(hud_hotbar_info)
	var display_button := Button.new()
	display_button.position = Vector2(1162, 10)
	display_button.size = Vector2(102, 36)
	display_button.text = "设置 F10"
	display_button.focus_mode = Control.FOCUS_NONE
	display_button.pressed.connect(_open_display_settings)
	layer.add_child(display_button)

func _load_display_preferences() -> void:
	var config := ConfigFile.new()
	var config_loaded := config.load(display_config_path) == OK
	if config_loaded:
		display_size_index = clampi(int(config.get_value("display", "size", 1)), 0, WINDOW_SIZES.size() - 1)
		camera_zoom_index = clampi(int(config.get_value("display", "camera_zoom_index", camera_zoom_index)), 0, CAMERA_ZOOMS.size() - 1)
		var legacy_volume := clampi(int(config.get_value("audio", "volume_percent", 100)), 0, 100)
		audio_volume_percent = clampi(int(config.get_value("audio", "music_volume_percent", legacy_volume)), 0, 100)
		sfx_volume_percent = clampi(int(config.get_value("audio", "sfx_volume_percent", legacy_volume)), 0, 100)
	_apply_audio_volume()
	if DisplayServer.get_name() == "headless" or not config_loaded: return
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
	config.load(display_config_path)
	config.set_value("display", "size", display_size_index)
	config.set_value("display", "camera_zoom_index", camera_zoom_index)
	config.set_value("display", "fullscreen", get_window().mode != Window.MODE_WINDOWED)
	config.set_value("audio", "volume_percent", audio_volume_percent)
	config.set_value("audio", "music_volume_percent", audio_volume_percent)
	config.set_value("audio", "sfx_volume_percent", sfx_volume_percent)
	config.save(display_config_path)


func _ensure_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			bus_index = AudioServer.bus_count
			AudioServer.add_bus(bus_index)
			AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")


func _apply_audio_volume() -> void:
	_set_bus_volume("Music", audio_volume_percent)
	_set_bus_volume("SFX", sfx_volume_percent)


func _set_bus_volume(bus_name: String, percent: int) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0: return
	var volume := clampf(float(percent) / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.0001)))


func _set_audio_volume(value: float) -> void:
	audio_volume_percent = clampi(roundi(value), 0, 100)
	_apply_audio_volume()
	_save_display_preferences()


func _set_sfx_volume(value: float) -> void:
	sfx_volume_percent = clampi(roundi(value), 0, 100)
	_apply_audio_volume()
	_save_display_preferences()

func _set_camera_zoom(index: int) -> void:
	camera_zoom_index = clampi(index, 0, CAMERA_ZOOMS.size() - 1)
	if is_instance_valid(game_camera): game_camera.zoom = Vector2.ONE * CAMERA_ZOOMS[camera_zoom_index]
	_save_display_preferences()
	_open_display_settings()

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
	life_panel.open("设置 · 画面与声音")
	var fullscreen := DisplayServer.get_name() != "headless" and get_window().mode != Window.MODE_WINDOWED
	if not display_apply_error.is_empty(): life_panel.paragraph("⚠ " + display_apply_error)
	var resolution_label := Label.new()
	resolution_label.text = "窗口尺寸"
	resolution_label.add_theme_font_size_override("font_size", 18)
	resolution_label.add_theme_color_override("font_color", Color("493829"))
	life_panel.section("显示")
	life_panel.content.add_child(resolution_label)
	var resolution_row := HBoxContainer.new()
	resolution_row.add_theme_constant_override("separation", 7)
	life_panel.content.add_child(resolution_row)
	for index in WINDOW_SIZES.size():
		var size: Vector2i = WINDOW_SIZES[index]
		var size_button := Button.new()
		size_button.text = "%d × %d\n%s" % [size.x, size.y, ["紧凑", "推荐", "大窗口"][index]]
		size_button.custom_minimum_size = Vector2(216, 46)
		size_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_button.add_theme_font_size_override("font_size", 15)
		if index == display_size_index:
			var active_style := StyleBoxFlat.new()
			active_style.bg_color = Color("d9bf87")
			active_style.border_color = Color("a6653c")
			active_style.set_border_width_all(3)
			active_style.set_corner_radius_all(0)
			size_button.add_theme_stylebox_override("normal", active_style)
		size_button.pressed.connect(_set_window_size.bind(index))
		resolution_row.add_child(size_button)
	var fullscreen_button := Button.new()
	fullscreen_button.text = "退出全屏" if fullscreen else "切换到全屏"
	fullscreen_button.custom_minimum_size.y = 36
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	life_panel.content.add_child(fullscreen_button)
	life_panel.section("镜头距离")
	var zoom_row := HBoxContainer.new()
	zoom_row.add_theme_constant_override("separation", 7)
	life_panel.content.add_child(zoom_row)
	for index in CAMERA_ZOOMS.size():
		var zoom_button := Button.new()
		zoom_button.text = ["远景", "标准", "近景"][index] + "\n%.2f×" % CAMERA_ZOOMS[index]
		zoom_button.custom_minimum_size = Vector2(120, 42)
		zoom_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		zoom_button.set_meta("camera_zoom_index", index)
		zoom_button.add_theme_font_size_override("font_size", 15)
		if index == camera_zoom_index:
			var active_zoom_style := StyleBoxFlat.new()
			active_zoom_style.bg_color = Color("d9bf87")
			active_zoom_style.border_color = Color("a6653c")
			active_zoom_style.set_border_width_all(3)
			active_zoom_style.set_corner_radius_all(0)
			zoom_button.add_theme_stylebox_override("normal", active_zoom_style)
		zoom_button.pressed.connect(_set_camera_zoom.bind(index))
		zoom_row.add_child(zoom_button)
	life_panel.section("声音")
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 18)
	life_panel.content.add_child(volume_row)
	volume_row.add_child(_build_audio_volume_control("背景音乐", audio_volume_percent, _set_audio_volume))
	volume_row.add_child(_build_audio_volume_control("动作音效", sfx_volume_percent, _set_sfx_volume))
	life_panel.section("操作速查")
	var controls := Label.new()
	controls.text = "移动 WASD / 方向键 · 奔跑 Shift · 工具 E · 互动/阅读 F\n背包 I · 角色卡 J · 地图 M · 制作 K · 技能 L · 设置 F10"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("684b35"))
	life_panel.content.add_child(controls)


func _build_audio_volume_control(title: String, initial_value: int, setter: Callable) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("493829"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title_label)
	var value_label := Label.new()
	value_label.text = "%d%%" % initial_value
	value_label.custom_minimum_size.x = 48
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color("765033"))
	heading.add_child(value_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider_track := StyleBoxFlat.new()
	slider_track.bg_color = Color("b49a6c")
	slider_track.set_content_margin(SIDE_TOP, 8)
	slider_track.set_content_margin(SIDE_BOTTOM, 8)
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = Color("79985a")
	slider_fill.set_content_margin(SIDE_TOP, 8)
	slider_fill.set_content_margin(SIDE_BOTTOM, 8)
	slider.add_theme_stylebox_override("slider", slider_track)
	slider.add_theme_stylebox_override("grabber_area", slider_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_fill.duplicate())
	slider.add_theme_icon_override("grabber", preload("res://assets/art/runtime_generated/ui_slider_grabber_v1.svg"))
	slider.add_theme_icon_override("grabber_highlight", preload("res://assets/art/runtime_generated/ui_slider_grabber_v1.svg"))
	column.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d%%" % roundi(value)
		setter.call(value))
	return column


func _update_location() -> void:
	if hud_location != null:
		hud_location.text = "花溪谷 · %s" % _location_name()


func _location_name() -> String:
	if current_map_id.begins_with("mine_"): return "青石矿洞 · 第%s层" % current_map_id.trim_prefix("mine_")
	var regional_titles: Dictionary = preload("res://scripts/region_world_builder.gd").TITLES
	if regional_titles.has(current_map_id): return regional_titles[current_map_id]
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
	var names := {"farmhouse_interior": "农舍门", "general_store_interior": "杂货店门", "clinic_interior": "诊所门", "cafe_interior": "咖啡馆门", "shipping_box": "出货箱", "well": "水井", "notice_board": "公告板", "bed": "床铺", "chest": "储物箱", "fireplace": "壁炉", "shop_counter": "杂货店柜台", "clinic_counter": "诊所柜台", "cafe_counter": "咖啡馆柜台", "coop": "鸡舍巢箱", "barn": "牛棚草料槽", "processing_machine": "加工机器"}
	return "阅读路标" if target == "signpost" else "返回洞口" if target == "mine_return" else "进入下层" if target == "mine_down" else str(names.get(target, "设施"))


func _set_status(message: String) -> void:
	if hud_status != null:
		hud_status.text = "  " + message
	if hud_status_panel == null:
		return
	if hud_status_tween != null and hud_status_tween.is_valid():
		hud_status_tween.kill()
	hud_status_panel.show()
	hud_status_panel.modulate.a = 1.0
	hud_status_tween = create_tween()
	hud_status_tween.tween_interval(4.5)
	hud_status_tween.tween_property(hud_status_panel, "modulate:a", 0.0, 0.35)
	hud_status_tween.tween_callback(hud_status_panel.hide)


func _on_customization_confirmed(data: Dictionary) -> void:
	player.set_customization(data)
	creator.close()
	_set_status("角色已创建。沿农场西侧道路前往城镇，按 C 可编辑外观。")
	_save_game()


func _plant_sapling_action(tree_id: String) -> void:
	if not actor_action.kind.is_empty(): return
	if moving:
		queued_use = "tool"
		queued_use_cell = Vector2i(-1, -1)
		return
	if not _is_farm_area():
		_set_status("果树只能种在农场空草地上。")
		return
	var target_cell := player_cell + _facing_delta(player.facing)
	var map_id := current_map_id
	actor_action.start("seed", func():
		if current_map_id != map_id: return
		var result: Dictionary = orchard.plant(target_cell, tree_id, current_map_id, farm.day, navigation, farm, animals)
		_set_status(str(result.message))
		if result.ok:
			_refresh_orchard_world()
			_sync_inventory()
			_update_farm_hud()
			_save_game())
	player.action_progress = 0.0
	player.set_pose(player.facing, "seed")


func _collect_orchard_fruit(world_cell: Vector2i) -> void:
	var local_cell := _animal_local_cell(world_cell)
	var result: Dictionary = orchard.collect(local_cell, farm.day)
	_set_status(str(result.message))
	if bool(result.get("ok", false)):
		_sync_inventory()
		_update_farm_hud()
		_save_game()
		world.queue_redraw()


func _farm_action() -> void:
	if festival_hunt != null and festival_hunt.active: return
	if not actor_action.kind.is_empty(): return
	if moving:
		queued_use = "tool"
		queued_use_cell = Vector2i(-1, -1)
		return
	if current_tool == "sword":
		_sword_action()
		return
	if current_tool == "sapling":
		_plant_sapling_action(current_sapling_id)
		return
	if current_tool == "pickaxe":
		var structure_cell := player_cell + _facing_delta(player.facing)
		if _is_farm_area(structure_cell) and not farm.structure_at(structure_cell).is_empty():
			_remove_structure(structure_cell)
			return
		_mine_action()
		return
	if current_tool == "fish":
		_start_fishing()
		return
	if current_tool == "water" and homestead.water <= 0:
		_set_status("水壶空了，去水井按 F 补满。")
		return
	if energy < (1 if int(mining.tools.get(current_tool, 0)) > 0 else 2):
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
	actor_action.duration *= 1.0 - int(mining.tools.get(selected_tool, 0)) * 0.15
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
		energy -= 1 if int(mining.tools.get(selected_tool, 0)) > 0 else 2
		if selected_tool == "water": homestead.water = maxi(0, homestead.water - 1)
		pet.rebuild_grid()
		feedback.burst(world.cell_center_to_screen(target_cell), "+1" if selected_tool in ["harvest", "scythe"] else "", Color("a8e5f1") if selected_tool == "water" else Color("f3d16c"))
		var action := str(result.get("action", ""))
		match action:
			"till": _set_status("翻地完成。选择种子后按 E 播种。")
			"plant": _set_status("播下%s；每日浇水后会成长。" % _seed_name(_current_seed_id()))
			"water": _set_status("浇水完成。按 N 结束当天。")
			"harvest":
				var item_id := str(result.get("item_id", "parsnip"))
				var crop: Dictionary = farm.get_crop_definition(item_id)
				var growth: String = _gain_skill("farming", 20 + int(crop.get("sell_price", 0)) / 10)
				_set_status("收获%s，前往出货箱站位按 F 出售。%s" % [_seed_name(item_id), growth])
	else:
		_set_status("这种作物不适合当前季节，请在背包查看种植季节。" if str(result.get("code", "")) == "wrong_season" else _farm_error(str(result.get("code", ""))))
	world.queue_redraw()
	_update_farm_hud()
	_save_game()


func _mine_action() -> void:
	var cell := player_cell + _facing_delta(player.facing)
	var deposit: Dictionary = mining.vein(current_map_id, cell, farm.day)
	if deposit.is_empty():
		_set_status("面朝矿石再挥动镐子。")
		return
	var energy_cost := skills.mining_energy_cost()
	if energy < energy_cost:
		_set_status("体力不足，吃些食物或返回农场休息。")
		return
	if int(mining.tools.pickaxe) < int(deposit.required):
		_set_status("岩石太硬，先到种子铺的工匠柜台升级镐子。")
		return
	var map_id := current_map_id
	actor_action.start("pickaxe", func():
		if current_map_id != map_id: return
		var result: Dictionary = mining.strike(map_id, cell, farm.day)
		if not result.ok: return
		energy -= energy_cost
		if result.complete:
			homestead.resources[result.material] += int(result.amount)
			var growth := _gain_skill("mining", 15 + int(deposit.required) * 10)
			_sync_collision_cell(cell)
			feedback.burst(world.cell_center_to_screen(cell), "%s +%d" % [Homestead.RESOURCE_NAMES[result.material], result.amount])
			if not growth.is_empty(): _set_status("%s%s" % [Homestead.RESOURCE_NAMES[result.material], growth])
		else: feedback.burst(world.cell_center_to_screen(cell), "岩石出现裂纹")
		farm_audio.play("hoe")
		scenery.refresh()
		_sync_inventory()
		_update_farm_hud()
		_save_game())
	player.action_progress = 0.0
	player.set_pose(player.facing, "pickaxe")


func _place_structure(structure_id: String) -> void:
	if not Crafting.PLACEABLES.has(structure_id) or int(crafting.crafted_items.get(structure_id, 0)) <= 0: return
	if not _is_farm_area():
		_set_status("农场设施只能安装在农场耕地区域。")
		return
	var cell := player_cell + _facing_delta(player.facing)
	var result: Dictionary = farm.place_structure(cell, structure_id)
	if not result.ok:
		_set_status(str(result.message))
		return
	crafting.consume_item(structure_id)
	_sync_collision_cell(cell)
	pet.rebuild_grid()
	world.queue_redraw()
	_sync_inventory()
	_update_farm_hud()
	_set_status("已安装%s。%s" % [Crafting.PLACEABLES[structure_id].name, Crafting.PLACEABLES[structure_id].description])
	_save_game()


func _remove_structure(cell: Vector2i) -> void:
	var structure_id: String = farm.structure_at(cell)
	if Processing.is_machine(structure_id) and not processing.can_remove(cell):
		_set_status("机器里还有原料或成品，收取后才能拆除。")
		return
	if energy < skills.mining_energy_cost():
		_set_status("体力不足，无法拆除设施。")
		return
	actor_action.start("pickaxe", func():
		var result: Dictionary = farm.remove_structure(cell)
		if not result.ok: return
		energy -= skills.mining_energy_cost()
		crafting.add_item(str(result.structure))
		_sync_collision_cell(cell)
		pet.rebuild_grid()
		world.queue_redraw()
		_sync_inventory()
		_update_farm_hud()
		_set_status("已拆下%s，放回背包。" % Crafting.PLACEABLES[str(result.structure)].name)
		_save_game())
	player.action_progress = 0.0
	player.set_pose(player.facing, "pickaxe")


func _start_fishing() -> void:
	if energy < 2 or not fishing_stage.is_empty(): return
	var target := player_cell + _facing_delta(player.facing)
	if navigation.get_cell_class(current_map_id, target) != "water":
		_set_status("站在池塘或河岸边，面向水面再按 E 抛竿。")
		return
	fishing_stage = "casting"
	fishing_elapsed = 0.0
	hooked_fish = fishing.prepare(current_map_id, farm.day, clock_minutes, Calendar.weather(farm.day))
	if fishing.use_bait(): hooked_fish.wait = maxf(0.2, float(hooked_fish.get("wait", 2.0)) * 0.5)
	var difficulty := float(hooked_fish.get("difficulty", 0.35))
	var tackle_bonus := float(Fishing.TACKLES.cork_bobber.bar_bonus) if fishing.cork_bobber_equipped else 0.0
	fishing_bar_height = clampf(0.39 - difficulty * 0.22 + skills.fishing_window_bonus() * 0.30 + tackle_bonus, 0.15, 0.52)
	if village.has_milestone("fisherman", 2): fishing_bar_height = minf(0.55, fishing_bar_height + 0.06)
	fishing_treasure_available = randf() < minf(0.72, float(hooked_fish.get("treasure_chance", 0.16)) + float(skills.level("fishing")) * 0.025)
	fishing_treasure_secured = false
	fishing_treasure_position = randf_range(0.16, 0.84)
	fishing_treasure_progress = 0.0
	fishing_fish_position = 0.5
	fishing_fish_velocity = 0.0
	fishing_direction_change = 0.25
	fishing_bar_center = 0.5
	fishing_bar_velocity = 0.0
	fishing_reel_held = false
	fishing_catch_progress = 0.12
	actor_action.start("fish", func():
		energy -= 2
		_sync_inventory()
		_update_farm_hud()
		_save_game(), func():
		fishing_stage = "waiting"
		fishing_elapsed = 0.0
		_set_status("浮漂已落水，等待咬钩；Esc 收竿。")
	)
	fishing_view.set_state(false)


func _advance_fishing_minigame(delta: float) -> void:
	var difficulty := float(hooked_fish.get("difficulty", 0.35))
	fishing_direction_change -= delta
	if fishing_direction_change <= 0.0:
		var sign_direction := -1.0 if randf() < 0.5 else 1.0
		fishing_fish_velocity = sign_direction * randf_range(0.20, 0.43 + difficulty * 0.48)
		fishing_direction_change = randf_range(0.38, 0.92 - difficulty * 0.22)
	fishing_fish_position += fishing_fish_velocity * delta
	if fishing_fish_position < 0.0:
		fishing_fish_position = 0.0
		fishing_fish_velocity = absf(fishing_fish_velocity)
	elif fishing_fish_position > 1.0:
		fishing_fish_position = 1.0
		fishing_fish_velocity = -absf(fishing_fish_velocity)
	var reel_acceleration := 3.6 if fishing_reel_held else -3.0
	fishing_bar_velocity = clampf(fishing_bar_velocity + reel_acceleration * delta, -1.55, 1.55)
	fishing_bar_center += fishing_bar_velocity * delta
	var half_bar := fishing_bar_height * 0.5
	if fishing_bar_center < half_bar:
		fishing_bar_center = half_bar
		fishing_bar_velocity = maxf(0.0, fishing_bar_velocity) * 0.2
	elif fishing_bar_center > 1.0 - half_bar:
		fishing_bar_center = 1.0 - half_bar
		fishing_bar_velocity = minf(0.0, fishing_bar_velocity) * 0.2
	var overlap := absf(fishing_fish_position - fishing_bar_center) <= half_bar
	fishing_catch_progress = clampf(fishing_catch_progress + delta * (0.38 if overlap else -0.22), 0.0, 1.0)
	var treasure_overlap := fishing_treasure_available and absf(fishing_treasure_position - fishing_bar_center) <= half_bar
	if fishing_treasure_available:
		fishing_treasure_progress = clampf(fishing_treasure_progress + delta * (0.58 if treasure_overlap and overlap else -0.18), 0.0, 1.0)
		if fishing_treasure_progress >= 1.0:
			fishing_treasure_available = false
			fishing_treasure_secured = true
	fishing_view.set_state(true, str(hooked_fish.get("name", "鱼")), fishing_fish_position, fishing_bar_center, fishing_bar_height, fishing_catch_progress, fishing_treasure_available, fishing_treasure_position, fishing_treasure_progress, fishing_treasure_secured)
	if fishing_catch_progress >= 1.0:
		fishing_stage = "reeling"
		fishing_reel_held = false
		fishing_view.set_state(false)
		actor_action.start("fish", _catch_fish, _finish_fishing)
	elif fishing_catch_progress <= 0.0:
		_cancel_fishing()
		_set_status("鱼挣脱了，调整提竿节奏再试一次。")


func _catch_fish() -> void:
	var id := str(hooked_fish.get("id", "creek_fish"))
	if not fishing.catch_fish(id):
		_cancel_fishing()
		return
	var treasure_message := ""
	if fishing_treasure_secured:
		var treasure: Dictionary = fishing.claim_treasure(int(hooked_fish.get("cast_id", 0)), id)
		if not treasure.is_empty():
			var material := str(treasure.material)
			var amount := int(treasure.amount)
			homestead.resources[material] = int(homestead.resources.get(material, 0)) + amount
			treasure_message = " 宝箱中找到%s ×%d。" % [str(Homestead.RESOURCE_NAMES.get(material, material)), amount]
	_sync_inventory()
	_update_farm_hud()
	var growth := _gain_skill("fishing", 20 + int(Fishing.DEFINITIONS[id].price) / 5)
	_set_status("钓到一条%s！这种鱼共有 %d 条。%s%s" % [Fishing.DEFINITIONS[id].name, int(fishing.inventory[id]), treasure_message, growth])
	_save_game()


func _finish_fishing() -> void:
	fishing_stage = ""
	hooked_fish.clear()
	fishing_reel_held = false
	fishing_treasure_available = false
	fishing_treasure_secured = false
	if fishing_view != null: fishing_view.set_state(false)


func _cancel_fishing() -> void:
	fishing_stage = ""
	hooked_fish.clear()
	fishing_reel_held = false
	fishing_treasure_available = false
	fishing_treasure_secured = false
	if fishing_view != null: fishing_view.set_state(false)
	actor_action.cancel()
	player.set_pose(player.facing, "idle")


func _advance_day(_is_raining: bool) -> void:
	var animal_result: Dictionary = animals.advance_day(farm.day)
	var result: Dictionary = farm.advance_day(Calendar.weather(farm.day) == "雨")
	if bool(result.get("ok", false)):
		var processing_result: Dictionary = processing.advance_day(farm.day)
		clock_minutes = 360
		clock_elapsed = 0.0
		energy = _energy_cap()
		combat.sync_day(farm.day)
		combat.heal_full()
		_refresh_orchard_world()
		_change_map("farm_outdoor", navigation.get_spawn("farm_outdoor"))
		var event := Calendar.festival(farm.day)
		_set_status("%s，%s。%s%s%s%s%s" % [Calendar.label(farm.day), Calendar.weather(farm.day), "今日%s：去城镇公告板参加。" % event.name if not event.is_empty() else "新的一天开始了。", " 换季清理了 %d 格过季作物。" % result.expired_cells.size() if not result.expired_cells.is_empty() else "", " 鸡舍新产鸡蛋%d枚。" % int(animal_result.produced) if int(animal_result.produced) > 0 else "", " 新产鸭蛋%d枚。" % int(animal_result.duck_produced) if int(animal_result.duck_produced) > 0 else "", " %d台加工机器已经完成。" % int(processing_result.completed) if int(processing_result.completed) > 0 else ""])
		world.queue_redraw()
		_sync_chicken_actors()
		_sync_duck_actors()
		_sync_cow_actors()
		_sync_inventory()
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
	return {"hoe": "锄头", "seed": "种子", "water": "浇水壶", "harvest": "采收", "scythe": "镰刀", "fish": "鱼竿", "pickaxe": "镐子", "sword": "长剑"}.get(current_tool, "工具")


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
	var tool_names := {"hoe": "锄头", "seed": "种子袋", "water": "浇水壶", "harvest": "采收篮", "scythe": "镰刀", "fish": "鱼竿", "pickaxe": "镐子", "sword": "长剑"}
	var tool_short := {"hoe": "锄头", "seed": "种子", "water": "水壶", "harvest": "采收", "scythe": "镰刀", "fish": "鱼竿", "pickaxe": "镐子", "sword": "长剑"}
	var tool_descriptions := {
		"hoe": "翻松面前可耕地。快捷栏数字键会立即挥动工具，E 可继续使用当前工具。",
		"seed": "把当前选择的种子播进已翻松的土地。按 Q 切换种类；当前是%s。" % _seed_name(_current_seed_id()),
		"water": "给面前的土地浇水。当前水量 %d / %d，可在水井补满。" % [homestead.water, Homestead.WATER_CAPACITY],
		"harvest": "采下已经成熟的作物，并把收获放进背包。",
		"scythe": "收割面前已经成熟的作物。",
		"fish": "站在水边面向水面抛竿；鱼咬钩后按住 E 或鼠标左键追住鱼。",
		"pickaxe": "面对矿石按 E 开采。当前等级：%s。矿石与煤炭可在种子铺用于升级工具。" % ["普通", "铜", "铁"][int(mining.tools.pickaxe)],
		"sword": "矿洞防身武器。靠近怪物并面向它按 E 挥砍；当前伤害%d点。" % skills.combat_damage(),
	}
	for tool_id in TOOL_IDS:
		result["tool:" + tool_id] = {"kind": "tool", "type_label": "工具", "tool_id": tool_id, "name": tool_names[tool_id], "short_name": tool_short[tool_id], "count": 1, "description": tool_descriptions[tool_id], "icon": _tool_texture(tool_id)}
		if mining.tools.has(tool_id) and int(mining.tools[tool_id]) > 0:
			result["tool:" + tool_id].name = ["", "铜", "铁"][int(mining.tools[tool_id])] + tool_names[tool_id]
	for tree_id in orchard.saplings:
		var sapling_count: int = int(orchard.saplings[tree_id])
		if sapling_count <= 0: continue
		var tree: Dictionary = Orchard.TREE_TYPES[str(tree_id)]
		result["sapling:" + str(tree_id)] = {"kind": "sapling", "type_label": "果树苗", "tree_id": str(tree_id), "name": str(tree.sapling_name), "short_name": str(tree.sapling_name), "count": sapling_count, "description": "%s季成熟结果，栽下后无需浇水；选中后在农场空草地按E种植。" % Calendar.SEASONS[int(tree.season)], "icon": _goods_icon("sapling:" + str(tree_id))}
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
			result["food:" + item_id] = {"kind": "food", "type_label": "食物", "name": str(crop.label), "short_name": str(crop.label), "count": food_count, "description": "农场收获，可食用恢复 20 点体力，也可送礼或出货（%d 金）。" % int(crop.sell_price), "icon": _crop_icon(item_id, 3), "gift_kind": "crop", "gift_id": item_id}
	for kind in homestead.resources:
		var amount := int(homestead.resources[kind])
		if amount <= 0: continue
		var edible: bool = kind in ["berry", "mushroom"]
		var resource_name: String = str(Homestead.RESOURCE_NAMES[kind])
		var rare_gem: bool = kind in ["earth_crystal", "amethyst", "frozen_tear", "fire_quartz"]
		var item_description := ("矿洞采得的稀有结晶，可出货（%d 金）、送礼或收藏。" % int(Homestead.RESOURCE_PRICES[kind])) if rare_gem else ("野外采集的食物，食用可恢复 %d 点体力。" % (15 if kind == "berry" else 25)) if edible else "建造与制作使用的基础材料，不能从快捷栏直接使用。"
		result[("food:" if edible else "material:") + str(kind)] = {"kind": "food" if edible else "material", "type_label": "食物" if edible else "矿物收藏" if rare_gem else "材料（不可直接使用）", "name": resource_name, "short_name": resource_name, "count": amount, "description": item_description, "icon": _resource_icon(str(kind)), "gift_kind": "resource", "gift_id": str(kind)}
	for tree_id in orchard.fruits:
		var fruit_count: int = int(orchard.fruits[tree_id])
		if fruit_count <= 0: continue
		var fruit: Dictionary = Orchard.TREE_TYPES[str(tree_id)]
		result["food:fruit:" + str(tree_id)] = {"kind": "food", "type_label": "果园收获", "name": str(fruit.name), "short_name": str(fruit.name), "count": fruit_count, "description": "果树成熟季节采下的鲜果，可恢复%d体力或出货%d金币。" % [int(fruit.energy), int(fruit.fruit_price)], "icon": _goods_icon("fruit:" + str(tree_id)), "gift_kind": "fruit", "gift_id": str(tree_id)}
	for fish_id in fishing.inventory:
		var fish_amount := int(fishing.inventory[fish_id])
		if fish_amount <= 0: continue
		var fish: Dictionary = Fishing.DEFINITIONS[fish_id]
		var key := "food:fish" if fish_id == "creek_fish" else "food:fish:" + str(fish_id)
		result[key] = {"kind": "food", "type_label": "鱼获", "name": fish.name, "short_name": fish.name, "count": fish_amount, "description": "%s鱼获，食用恢复%d点体力，出货价%d金。出现条件与地点可在鱼类图鉴查看。" % ["海水" if fish.habitat == "ocean" else "淡水", fish.energy, fish.price], "icon": _fish_icon(str(fish_id)), "gift_kind": "fish", "gift_id": str(fish_id)}
	if fishing.bait_count > 0:
		result["bait"] = {"kind": "bait", "type_label": "钓鱼装备", "name": "鱼饵", "short_name": "鱼饵", "count": fishing.bait_count, "description": "装在玻璃纤维鱼竿或铱金鱼竿上；每次抛竿消耗1份，让鱼更快咬钩。", "icon": _goods_icon("bait")}
	if fishing.cork_bobber_owned:
		result["tackle:cork_bobber"] = {"kind": "tackle", "type_label": "钓鱼装备", "name": "软木浮标", "short_name": "软木浮标", "count": 1, "description": "安装在铱金鱼竿上，可扩大追鱼操作条。", "icon": _goods_icon("tackle:cork_bobber")}
	for meal_id in crafting.meals:
		var meal_amount := int(crafting.meals[meal_id])
		if meal_amount <= 0: continue
		var recipe: Dictionary = Crafting.RECIPES[meal_id]
		result["food:meal:" + str(meal_id)] = {"kind": "food", "type_label": "料理", "name": recipe.name, "short_name": str(recipe.name), "count": meal_amount, "description": "亲手制作的料理，食用恢复%d点体力。" % int(recipe.energy), "icon": _goods_icon("meal:" + str(meal_id)), "gift_kind": "meal", "gift_id": str(meal_id)}
	if animals.eggs > 0:
		result["food:egg"] = {"kind": "food", "type_label": "畜产品", "name": "新鲜鸡蛋", "short_name": "鸡蛋", "count": animals.eggs, "description": "鸡舍产出的新鲜鸡蛋，可食用恢复12点体力，或以%d金币出货。" % Animals.EGG_PRICE, "icon": _goods_icon("animal:egg"), "gift_kind": "animal", "gift_id": "egg"}
	if animals.duck_eggs > 0:
		result["food:duck_egg"] = {"kind": "food", "type_label": "畜产品", "name": "新鲜鸭蛋", "short_name": "鸭蛋", "count": animals.duck_eggs, "description": "鸡舍成年鸭留下的鸭蛋，可食用恢复%d点体力，或以%d金币出货；也能放入蛋黄酱机。" % [Animals.DUCK_EGG_ENERGY, Animals.DUCK_EGG_PRICE], "icon": INVENTORY_ICONS.duck_egg, "gift_kind": "animal", "gift_id": "duck_egg"}
	if animals.milk > 0:
		result["food:milk"] = {"kind": "food", "type_label": "畜产品", "name": "新鲜牛奶", "short_name": "牛奶", "count": animals.milk, "description": "牛棚产出的新鲜牛奶，可食用恢复%d点体力、以%d金币出货，或放入奶酪机加工。" % [Animals.MILK_ENERGY, Animals.MILK_PRICE], "icon": _goods_icon("animal:milk"), "gift_kind": "animal", "gift_id": "milk"}
	for product_id in processing.products:
		var product_count := int(processing.products[product_id])
		if product_count <= 0: continue
		var product: Dictionary = processing.product_definition(str(product_id), farm)
		var product_icon_id := "artisan:pickles" if str(product_id).begins_with("pickles:") else "artisan:" + str(product_id)
		result["food:artisan:" + str(product_id)] = {"kind": "food", "type_label": "加工品", "name": product.name, "short_name": product.name, "count": product_count, "description": "农场加工品，食用恢复%d点体力，出货价%d金币。" % [product.energy, product.price], "icon": _goods_icon(product_icon_id), "gift_kind": "artisan", "gift_id": str(product_id)}
	for structure_id in Crafting.PLACEABLES:
		var structure_count := int(crafting.crafted_items.get(structure_id, 0))
		if structure_count <= 0: continue
		var placeable: Dictionary = Crafting.PLACEABLES[structure_id]
		result["placeable:" + str(structure_id)] = {"kind": "placeable", "type_label": "农场设施", "structure_id": structure_id, "name": placeable.name, "short_name": placeable.name, "count": structure_count, "description": "放入快捷栏并使用，在面前空耕地安装。%s 用镐子可拆回背包。" % placeable.description, "icon": _goods_icon("placeable:" + str(structure_id))}
	return result


func _crop_icon(item_id: String, stage: int) -> Texture2D:
	var visual: Array = WorldRendererScript.crop_visual(item_id)
	if visual.size() < 2 or not visual[0] is Texture2D: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = visual[0]
	atlas.region = SpriteAtlasScript.frame(visual[0], Vector2i(4, 4), clampi(stage, 0, 3), int(visual[1])).region
	return atlas


func _resource_icon(resource_id: String) -> Texture2D:
	if not ORE_INVENTORY_ICON_INDEX.has(resource_id): return INVENTORY_ICONS.get(resource_id)
	var atlas := AtlasTexture.new()
	atlas.atlas = ORE_DEPOSIT_ART
	atlas.region = Rect2(Vector2(int(ORE_INVENTORY_ICON_INDEX[resource_id]) * 32, 0), Vector2(32, 32))
	return atlas


func _goods_icon(item_id: String) -> Texture2D:
	if not GOODS_ICON_INDEX.has(item_id): return null
	var atlas := AtlasTexture.new()
	atlas.atlas = GOODS_ART
	var index := int(GOODS_ICON_INDEX[item_id])
	atlas.region = Rect2(Vector2((index % 7) * 32, floori(float(index) / 7.0) * 32), Vector2(32, 32))
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
		hud_day.text = "%s  %02d:%02d  %s · %d 金 · 体力 %d · 生命 %d" % [Calendar.label(farm.day), clock_minutes / 60, clock_minutes % 60, Calendar.weather(farm.day), farm.gold, energy, combat.health]
	hud_hint.text = "%s×%d · 水 %d/24" % [_seed_name(_current_seed_id()), farm.get_seed_count(_current_seed_id()), homestead.water]
	hud_hint.visible = _is_farm_area()
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
	if index < 0:
		hud_hotbar_info.text = ""
		hud_hotbar_info.hide()
		return
	var item_key := str(inventory_state.hotbar[index])
	var item: Dictionary = _inventory_items().get(item_key, {})
	if item.is_empty():
		hud_hotbar_info.text = ""
		hud_hotbar_info.hide()
		return
	var count := int(item.get("count", 1))
	hud_hotbar_info.text = "%s%s" % [str(item.get("name", item_key)), " ×%d" % count if count > 1 else ""]
	hud_hotbar_info.position.x = 900
	hud_hotbar_info.show()


func _item_symbol(item: Dictionary) -> String:
	var key := str(item.get("tool_id", item.get("name", "")))
	return {"sword": "†", "scythe": "◒", "fish": "◇", "木材": "▤", "石料": "◆", "野莓": "●", "蘑菇": "♠", "溪鱼": "◇", "新鲜鸡蛋": "○", "铜制洒水器": "✣"}.get(key, "◆")


func _update_tool_icon() -> void:
	if hud_tool_icon == null:
		return
	hud_tool_icon.texture = _tool_texture(current_tool)


func _tool_texture(tool_id: String) -> Texture2D:
	if tool_id == "sword": return load("res://assets/art/runtime_generated/sword_icon.svg")
	if tool_id == "pickaxe": return load("res://assets/art/runtime_generated/pickaxe_icon.svg")
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


func _open_crafting() -> void:
	life_panel.open("随身制作与炉灶")
	life_panel.paragraph("按 K 可随时查看配方；农舍壁炉也能打开这里。配方由技能、居民关系和矿洞探索解锁，制作失败不会扣除材料。")
	for id in Crafting.RECIPES:
		var recipe: Dictionary = Crafting.RECIPES[id]
		if not crafting.is_unlocked(id, village, mining, skills):
			var unlock: Array = recipe.unlock
			var hint := "%s达到%d级后解锁" % [Skills.NAMES[str(unlock[1])], int(unlock[2])] if unlock[0] == "skill" else "深入矿洞后解锁" if unlock[0] == "mine" else "与%s成为朋友后解锁" % VillageScript.PEOPLE[str(unlock[1])].name
			life_panel.paragraph("？？？ · " + hint)
			continue
		var parts: Array[String] = []
		for item in recipe.ingredients: parts.append(crafting.ingredient_label(item, farm, homestead, fishing))
		var output: Array = recipe.get("output", [])
		var purpose := "农场设施 · %s" % Crafting.PLACEABLES[str(output[1])].description if not output.is_empty() else "恢复%d体力" % int(recipe.energy)
		life_panel.paragraph("%s · %s\n%s" % [recipe.name, purpose, " · ".join(parts)])
		life_panel.action("制作 " + str(recipe.name), _craft_recipe.bind(str(id)))


func _craft_recipe(id: String) -> void:
	var result: Dictionary = crafting.craft(id, farm, homestead, fishing, village, mining, skills)
	_sync_inventory()
	_update_farm_hud()
	_open_crafting()
	life_panel.paragraph("%s已经放进背包。" % result.name if result.ok else str(result.message))
	if result.ok: _save_game()


func _open_skills() -> void:
	life_panel.open("生活技能")
	life_panel.paragraph("收获、钓鱼、敲碎矿石和野外采集会积累对应经验。技能效果立即生效，2级会解锁一份料理。")
	for skill in Skills.ORDER:
		var progress: Dictionary = skills.progress(skill)
		var experience_text := "经验已满" if int(progress.level) >= 10 else "%d / %d" % [int(progress.earned), int(progress.needed)]
		life_panel.paragraph("%s · %d级 · %s\n%s" % [Skills.NAMES[skill], int(progress.level), experience_text, skills.perk_text(skill)])
	life_panel.action("查看已解锁配方", _open_crafting)


func _gain_skill(skill: String, amount: int) -> String:
	var result: Dictionary = skills.gain(skill, amount)
	if not bool(result.get("level_up", false)): return ""
	return " %s提升至%d级！" % [Skills.NAMES[skill], int(result.new_level)]


func _open_character_card() -> void:
	life_panel.open("角色卡 · 农场主人")
	var portrait_frame := CenterContainer.new()
	portrait_frame.custom_minimum_size = Vector2(90, 118)
	var avatar = preload("res://scripts/avatar_renderer.gd").new()
	avatar.pixel_scale = 0.35
	avatar.customization = player.get_customization()
	avatar.facing = "down"
	avatar.action = "idle"
	avatar.position = Vector2(64, 104)
	portrait_frame.add_child(avatar)
	var profile_row := HBoxContainer.new()
	profile_row.add_theme_constant_override("separation", 12)
	life_panel.content.add_child(profile_row)
	profile_row.add_child(portrait_frame)
	var season_index := int((farm.day - 1) / 28) % Calendar.SEASONS.size()
	var summary := GridContainer.new()
	summary.columns = 3
	summary.add_theme_constant_override("h_separation", 10)
	summary.add_theme_constant_override("v_separation", 8)
	profile_row.add_child(summary)
	summary.add_child(_character_info_card("今日", "%s · 第 %d 天" % [Calendar.SEASONS[season_index], ((farm.day - 1) % 28) + 1]))
	summary.add_child(_character_info_card("农场收入", "%d 金币" % farm.gold))
	summary.add_child(_character_info_card("所在地点", _location_name()))
	summary.add_child(_character_info_card("天气", Calendar.weather(farm.day)))
	var fishing_gear: String = str({"bamboo": "竹竿", "fiberglass": "玻纤竿", "iridium": "铱金竿"}.get(str(fishing.rod().id), str(fishing.rod().name)))
	if bool(fishing.rod().bait_slot): fishing_gear += " · 饵%d" % fishing.bait_count
	if fishing.cork_bobber_equipped: fishing_gear += " · 浮标"
	summary.add_child(_character_info_card("钓鱼装备", fishing_gear))
	var vitality := VBoxContainer.new()
	vitality.add_theme_constant_override("separation", 5)
	life_panel.content.add_child(vitality)
	_add_character_meter(vitality, "体力", energy, _energy_cap(), Color("75a95d"))
	_add_character_meter(vitality, "生命", combat.health, Combat.MAX_HEALTH, Color("bd6653"))
	life_panel.section("技能成长")
	var skill_grid := GridContainer.new()
	skill_grid.columns = 2
	skill_grid.add_theme_constant_override("h_separation", 8)
	skill_grid.add_theme_constant_override("v_separation", 7)
	life_panel.content.add_child(skill_grid)
	for skill in Skills.ORDER:
		var progress: Dictionary = skills.progress(skill)
		skill_grid.add_child(_character_skill_card(skill, progress))


func _character_skill_card(skill: String, progress: Dictionary) -> PanelContainer:
	var level := clampi(int(progress.level), 0, 10)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 44)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UISkin.card(Color("efe2c2"), Color("c3a675")))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	card.add_child(row)
	var badge_panel := PanelContainer.new()
	badge_panel.custom_minimum_size = Vector2(28, 28)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = {"farming": Color("d7bc78"), "fishing": Color("80aaa4"), "mining": Color("989495"), "foraging": Color("8ba36a"), "combat": Color("bd7962")}.get(skill, Color("c0a16e"))
	badge_style.border_color = Color("80664a")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(0)
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	row.add_child(badge_panel)
	var badge := Label.new()
	badge.text = {"farming": "耕", "fishing": "钓", "mining": "矿", "foraging": "采", "combat": "战"}.get(skill, "技")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 15)
	badge.add_theme_color_override("font_color", Color("493829"))
	badge_panel.add_child(badge)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 1)
	row.add_child(details)
	var heading := HBoxContainer.new()
	details.add_child(heading)
	var name_label := Label.new()
	name_label.text = str(Skills.NAMES[skill])
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color("493829"))
	heading.add_child(name_label)
	var level_label := Label.new()
	level_label.text = "满级" if level >= 10 else "%d级" % level
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", Color("765033"))
	heading.add_child(level_label)
	var skill_bar := ProgressBar.new()
	skill_bar.custom_minimum_size.y = 8
	skill_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_bar.show_percentage = false
	skill_bar.max_value = 1.0
	skill_bar.value = 1.0 if level >= 10 else float(progress.earned) / maxf(1.0, float(progress.needed))
	_style_character_progress(skill_bar, Color("83a95b"))
	details.add_child(skill_bar)
	return card


func _character_info_card(title: String, value: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 54)
	card.add_theme_stylebox_override("panel", UISkin.card(Color("eadbb8"), Color("b79a69")))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	card.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", Color("876a42"))
	column.add_child(heading)
	var detail := Label.new()
	detail.text = value
	detail.add_theme_font_size_override("font_size", 14 if title == "钓鱼装备" else 18)
	detail.add_theme_color_override("font_color", Color("493829"))
	column.add_child(detail)
	return card


func _add_character_meter(parent: VBoxContainer, title: String, value: int, maximum: int, tint: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 56
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("493829"))
	row.add_child(label)
	var meter := ProgressBar.new()
	meter.custom_minimum_size = Vector2(0, 18)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.max_value = maxi(1, maximum)
	meter.value = clampi(value, 0, maximum)
	meter.show_percentage = false
	_style_character_progress(meter, tint)
	row.add_child(meter)
	var number := Label.new()
	number.text = "%d / %d" % [value, maximum]
	number.custom_minimum_size.x = 76
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.add_theme_color_override("font_color", Color("765033"))
	row.add_child(number)


func _style_character_progress(meter: ProgressBar, tint: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("ded0aa")
	background.border_color = Color("9f8459")
	background.set_border_width_all(1)
	background.set_corner_radius_all(0)
	meter.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = tint
	fill.border_color = tint.darkened(0.22)
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(0)
	meter.add_theme_stylebox_override("fill", fill)


func _map_marker_position(target_map: String, world_position: Vector2) -> Vector2:
	var source_position := world_position / WorldRenderer.TILE_SIZE
	if current_map_id == target_map:
		return source_position
	if Mining.is_mine(current_map_id) and target_map == "cave":
		return source_position
	if target_map == "valley_world":
		if current_map_id in ["farm_outdoor", "town_square", "riverside"]:
			return Vector2(navigation.to_contiguous_world(current_map_id, Vector2i.ZERO)) + source_position
		return Vector2(-1, -1)
	if current_map_id == "valley_world":
		var world_cell := Vector2i(floori(source_position.x), floori(source_position.y))
		if navigation.zone_at(current_map_id, world_cell) == target_map:
			return source_position - Vector2(navigation.to_contiguous_world(target_map, Vector2i.ZERO))
	return Vector2(-1, -1)


func _map_forage_positions(target_map: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var source_maps: Array = ["farm_outdoor", "town_square", "riverside"] if target_map == "valley_world" else [target_map]
	for source_map in source_maps:
		for item in homestead.available(source_map, farm.day, navigation):
			var cell: Vector2i = item.cell
			if target_map == "valley_world": cell = navigation.to_contiguous_world(source_map, cell)
			result.append(Vector2(cell) + Vector2.ONE * 0.5)
	return result


func _open_world_map(selected := "") -> void:
	var selected_map: String = "valley_world" if selected.is_empty() else selected
	var names := {"valley_world": "花溪谷全域", "farm_outdoor": "农场", "town_square": "花溪镇", "riverside": "花溪河畔", "countryside": "郊区林地", "beach": "风铃沙滩", "cave": "青石山洞", "mine_2": "青石矿洞二层", "mine_3": "青石矿洞三层", "farmhouse_interior": "农舍", "general_store_interior": "种子铺", "clinic_interior": "诊所", "cafe_interior": "咖啡馆"}
	life_panel.open("花溪大地图 · " + str(names.get(selected_map, selected_map)))
	life_panel.paragraph("地图仅供旅行手册查阅；路标说明请走近阅读。")
	var overview = preload("res://scripts/map_overview.gd").new()
	overview.navigation = navigation
	overview.map_id = selected_map
	overview.current_map_id = current_map_id
	overview.player_cell = player_cell
	overview.player_position = _map_marker_position(selected_map, player_body.position)
	overview.show_player = overview.player_position.x >= 0.0 and overview.player_position.y >= 0.0
	var selected_size := Vector2(ValleyWorldScript.SIZE) if selected_map == "valley_world" else Vector2(navigation.get_map_size(selected_map))
	overview.forage_positions = _map_forage_positions(selected_map)
	for actor in npcs:
		var state: Dictionary = npcs[actor]
		var resident = state.get("node")
		if not is_instance_valid(resident) or not resident.visible: continue
		var position := _map_marker_position(selected_map, resident.position)
		if position.x >= 0.0 and position.y >= 0.0 and position.x < selected_size.x and position.y < selected_size.y:
			overview.resident_positions.append(position)
			var request: Dictionary = village.request(str(actor), farm.day)
			if not request.is_empty() and not bool(request.get("done", false)):
				overview.request_positions.append(position)
	life_panel.content.add_child(overview)
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 5)
	life_panel.content.add_child(map_row)
	for map_key in ["valley_world", "farm_outdoor", "countryside", "town_square", "beach", "cave"]:
		if not navigation.has_map(map_key) or map_key == selected_map: continue
		var map_button := Button.new()
		map_button.text = str(names[map_key])
		map_button.custom_minimum_size.x = 88
		map_button.pressed.connect(_open_world_map.bind(map_key))
		map_row.add_child(map_button)
	life_panel.action("查看鱼类图鉴", _open_fish_guide)


func _open_fish_guide() -> void:
	life_panel.open("花溪鱼类图鉴 · 已发现 %d / %d" % [fishing.caught.size(), Fishing.DEFINITIONS.size()])
	life_panel.paragraph("当前装备：%s%s%s" % [str(fishing.rod().name), " · 鱼饵 ×%d" % fishing.bait_count if bool(fishing.rod().bait_slot) else " · 未解锁鱼饵槽", " · 软木浮标已装配" if fishing.cork_bobber_equipped else " · 浮标未装配"])
	life_panel.paragraph("累计钓获 %d 条鱼 · 开启宝箱 %d 个" % [fishing.total_caught(), fishing.treasure_chests])
	for id in Fishing.DEFINITIONS:
		var fish: Dictionary = Fishing.DEFINITIONS[id]
		var seasons: Array[String] = []
		for season in fish.seasons: seasons.append(Calendar.SEASONS[int(season)])
		var discovered: bool = fishing.caught.has(id)
		var conditions := "%s · %s · %02d:00–%02d:00 · %s" % ["海水" if fish.habitat == "ocean" else "淡水", "、".join(seasons), int(fish.hours[0]), int(fish.hours[1]), "任意天气" if fish.weather == "any" else fish.weather]
		var title := str(fish.name) if discovered else "？？？"
		var details := "累计%d条 · 出货%d金 · 恢复%d体力\n%s" % [int(fishing.caught[id]), int(fish.price), int(fish.energy), conditions] if discovered else "尚未发现 · 出现线索\n" + conditions
		life_panel.item_card(_fish_icon(str(id)), title, details)
	life_panel.action("返回大地图", _open_world_map)

func _fish_icon(fish_id: String) -> Texture2D:
	if not FISH_ICON_INDEX.has(fish_id): return INVENTORY_ICONS.fish_food
	var atlas := AtlasTexture.new()
	atlas.atlas = FISH_ART
	var index := int(FISH_ICON_INDEX[fish_id])
	atlas.region = Rect2(Vector2((index % 4) * 32, floori(float(index) / 4.0) * 32), Vector2(32, 32))
	return atlas

func _eat(item: String) -> void:
	_eat_inventory_item("food:" + item)


func _eat_inventory_item(item_key: String) -> void:
	var item: Dictionary = _inventory_items().get(item_key, {})
	if str(item.get("kind", "")) != "food":
		_set_status("这个物品不能食用。")
		return
	if energy >= _energy_cap():
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
	elif item_id == "fish" or item_id.begins_with("fish:"):
		var fish_id := "creek_fish" if item_id == "fish" else item_id.trim_prefix("fish:")
		if not fishing.consume(fish_id): return
		restored = int(Fishing.DEFINITIONS[fish_id].energy)
	elif item_id.begins_with("meal:"):
		var meal_id := item_id.trim_prefix("meal:")
		if not crafting.consume(meal_id): return
		restored = int(Crafting.RECIPES[meal_id].energy)
	elif item_id == "egg":
		if not animals.consume_egg(): return
		restored = 12
	elif item_id == "duck_egg":
		if not animals.consume_duck_egg(): return
		restored = Animals.DUCK_EGG_ENERGY
	elif item_id == "milk":
		if not animals.consume_milk(): return
		restored = Animals.MILK_ENERGY
	elif item_id.begins_with("fruit:"):
		var tree_id := item_id.trim_prefix("fruit:")
		if not Orchard.TREE_TYPES.has(tree_id) or not orchard.consume(tree_id): return
		restored = int(Orchard.TREE_TYPES[tree_id].energy)
	elif item_id.begins_with("artisan:"):
		var product_id := item_id.trim_prefix("artisan:")
		if not processing.consume(product_id): return
		restored = int(processing.product_definition(product_id, farm).energy)
	else:
		return
	energy = mini(_energy_cap(), energy + restored)
	_sync_inventory()
	_update_farm_hud()
	_set_status("食用了%s，恢复 %d 点体力。" % [str(item.get("name", "食物")), restored])
	_save_game()
	if inventory_panel != null and inventory_panel.visible: inventory_panel.refresh()

func _open_people() -> void:
	life_panel.open("花溪居民")
	life_panel.paragraph("每天聊天 +20；每天可送一份作物、鱼获、采集物、果实、料理或畜产品。最爱 +80、喜欢 +45、普通 +20、不喜欢 -20、讨厌 -40；生日礼物效果 ×8。靠近居民按 F 聊天，G 送礼。")
	for actor in VillageScript.PEOPLE:
		var person: Dictionary = VillageScript.PEOPLE[actor]
		var relation: Dictionary = village.bond(actor)
		life_panel.paragraph("现在：" + str(village.activity(actor, farm.day, clock_minutes).label))
		life_panel.paragraph("%s · %s · %d / 1000 · 关系事件 %d / 2\n生日 %s · 喜爱%s\n今天：%s / %s" % [person.name, person.job, relation.points, int(village.milestones.get(actor, 0)), Calendar.label(person.birthday), _seed_name(person.likes), "已聊天" if relation.talk_day == farm.day else "未聊天", "已送礼" if relation.gift_day == farm.day else "未送礼"])

func _open_dialogue(actor: String) -> void:
	_stop_player()
	if npcs.has(actor):
		var npc = npcs[actor].node
		var toward: Vector2 = player_body.position - npc.position
		var direction := Vector2i(0, signi(int(toward.y))) if absf(toward.y) > absf(toward.x) else Vector2i(signi(int(toward.x)), 0)
		npc.set_pose(_facing_for(direction), "idle")
		player.set_pose(_facing_for(-direction), "idle")
	var person: Dictionary = VillageScript.PEOPLE[actor]
	life_panel.open(str(person.name) + " · " + str(person.job))
	var portrait := _npc_idle_texture(actor)
	var frame: Dictionary = preload("res://scripts/sprite_atlas.gd").frame(portrait, Vector2i(10, 3), _npc_idle_column(actor), 0)
	var region: Rect2 = frame.region
	region.size.y *= 0.65
	var dialogue_location := current_map_id
	if current_map_id == "valley_world": dialogue_location = navigation.zone_at(current_map_id, player_cell)
	if dialogue_location == "riverside": dialogue_location = "beach"
	if dialogue_location in ["western_forest", "forest_crossing", "farm_country", "eastern_lakes"]: dialogue_location = "countryside"
	life_panel.dialogue(portrait, region, village.talk(actor, farm.day, clock_minutes, dialogue_location))
	var milestone: Dictionary = village.available_milestone(actor)
	if not milestone.is_empty():
		_open_friendship_event(actor, milestone, portrait, region)
		_save_game()
		return
	var wanted: Dictionary = village.request(actor, farm.day)
	if not wanted.done:
		var requested_entry := _request_inventory_entry(wanted)
		var held := int(requested_entry.get("item", {}).get("count", 0))
		var type_label := str({"crop": "作物", "resource": "采集物/矿物", "fruit": "果园水果", "fish": "鱼获", "meal": "料理", "animal": "畜产品", "artisan": "加工品"}.get(str(wanted.kind), "物品"))
		life_panel.action("今日委托 · %s（%s，持有%d）" % [wanted.label, type_label, held], _deliver_request.bind(actor))
	else: life_panel.paragraph("今日委托已完成，谢谢你的帮助。")
	if actor == "fisherman" and current_map_id == "beach":
		life_panel.action("查看海边渔具铺", _open_fishing_rod_shop)
	life_panel.action("送一份农场礼物", _open_gifts.bind(actor))
	_save_game()


func _open_friendship_event(actor: String, event: Dictionary, portrait: Texture2D, region: Rect2) -> void:
	life_panel.open("关系事件 · " + str(event.title))
	var beats: Array = event.get("beats", [])
	var first_line := str(beats[0]) if not beats.is_empty() else str(event.text)
	life_panel.story_dialogue(portrait, region, str(VillageScript.PEOPLE[actor].name), first_line)
	for beat_index in range(1, beats.size()): life_panel.paragraph(str(beats[beat_index]))
	life_panel.paragraph("你会怎么回应？选择会决定这次关系事件带来的帮助。")
	for choice_index in range(event.choices.size()):
		var choice: Dictionary = event.choices[choice_index]
		life_panel.action(str(choice.label), _resolve_friendship_event.bind(actor, int(event.level), choice_index))
	life_panel.action("稍后再聊", life_panel.close)


func _resolve_friendship_event(actor: String, level: int, choice_index: int) -> void:
	if not npcs.has(actor): return
	var event: Dictionary = village.claim_milestone(actor, level, choice_index)
	if event.is_empty(): return
	var reward_text := _apply_friendship_reward(event.reward)
	_save_game()
	_update_farm_hud()
	life_panel.open("关系加深 · " + str(event.title))
	life_panel.paragraph(str(event.choice_reply))
	life_panel.paragraph(reward_text)
	life_panel.action("继续聊天", _open_dialogue.bind(actor))


func _energy_cap() -> int:
	return 110 if village != null and village.has_milestone("doctor", 2) else 100


func _apply_friendship_reward(reward: Array) -> String:
	var kind := str(reward[0])
	var id := str(reward[1])
	var amount := int(reward[2])
	match kind:
		"seed":
			farm.add_seeds(id, amount)
			_sync_inventory()
			return "获得%s种子 ×%d。" % [_seed_name(id), amount]
		"resource":
			homestead.resources[id] = int(homestead.resources.get(id, 0)) + amount
			_sync_inventory()
			return "获得%s ×%d。" % [Homestead.RESOURCE_NAMES[id], amount]
		"gold":
			farm.gold += amount
			farm.gold_changed.emit(farm.gold, amount)
			return "获得%d金币。" % amount
		"energy":
			energy = _energy_cap()
			return "体力已恢复。"
		"perk":
			if id == "energy_cap": energy = mini(_energy_cap(), energy + 10)
			return {"seed_discount": "已解锁种子九折。", "fishing_window": "追鱼操作条永久加宽。", "energy_cap": "体力上限永久提高到110。"}.get(id, "已解锁新的友情帮助。")
	return ""

func _deliver_request(actor: String) -> void:
	if _nearby_npc_actor() != actor: return
	var wanted: Dictionary = village.request(actor, farm.day)
	var message := ""
	var completed := false
	if bool(wanted.get("done", false)):
		message = "今天的委托已经完成，明天再来看看吧。"
	else:
		var requested_entry := _request_inventory_entry(wanted)
		if requested_entry.is_empty():
			message = "行囊里还没有%s；带回来后再来找我吧。" % str(wanted.get("label", "这件物品"))
		elif not village.can_deliver_request(actor, farm.day, str(wanted.kind), str(wanted.item)):
			message = "这不是今天需要的委托物品。"
		elif not _consume_gift_item(str(requested_entry.key), requested_entry.item):
			message = "行囊里已经没有这份物品了。"
		else:
			var result: Dictionary = village.complete_request(actor, farm)
			message = str(result.get("message", "委托完成。"))
			completed = bool(result.get("ok", false))
	if completed:
		farm_audio.play("gift")
		_sync_inventory()
	_update_farm_hud()
	_save_game()
	_open_dialogue(actor)
	life_panel.paragraph(message)


func _request_inventory_entry(request_data: Dictionary) -> Dictionary:
	if request_data.is_empty(): return {}
	var items := _inventory_items()
	for key in items:
		var item: Dictionary = items[key]
		if str(item.get("gift_kind", "")) == str(request_data.get("kind", "")) and str(item.get("gift_id", "")) == str(request_data.get("item", "")):
			return {"key": str(key), "item": item}
	return {}

func _open_gifts(actor: String) -> void:
	if actor.is_empty():
		_set_status("请靠近一位居民后再送礼。")
		return
	life_panel.open("送给" + str(VillageScript.PEOPLE[actor].name))
	var birthday := posmod(farm.day - 1, 112) + 1 == int(VillageScript.PEOPLE[actor].birthday)
	life_panel.paragraph("每天可以送一份礼物，作物、鱼获、采集物、鲜果、料理和畜产品都会从行囊扣除。生日礼物效果 ×8。")
	var items := _inventory_items()
	for item_key in items:
		var item: Dictionary = items[item_key]
		if not item.has("gift_id") or int(item.get("count", 0)) <= 0: continue
		var preview: Dictionary = village.gift_value(actor, str(item.gift_id), farm.day)
		var tier := str(preview.get("tier", "neutral"))
		var tier_label := str({"loved": "最爱", "liked": "喜欢", "neutral": "普通", "disliked": "不喜欢", "hated": "讨厌"}.get(tier, "普通"))
		var points := int(preview.get("points", 0))
		life_panel.action("%s ×%d · %s %+d%s" % [item.name, int(item.count), tier_label, points, "（生日）" if birthday else ""], _give_gift.bind(actor, str(item_key)))
	if life_panel.content.get_child_count() <= 2:
		life_panel.paragraph("行囊里暂时没有可送的礼物；作物、鱼和采集物都可以留作心意。")

func _give_gift(actor: String, item: String) -> void:
	if not actor_action.kind.is_empty(): return
	if _interaction_npc_actor() != actor:
		_set_status("请面向并靠近要送礼的居民。")
		return
	life_panel.close()
	var direction: Vector2 = npcs[actor].node.position - player_body.position
	player.set_pose(_facing_for(Vector2i(signi(int(direction.x)), signi(int(direction.y)))), "gift")
	actor_action.start("gift", _commit_gift.bind(actor, item), func():
		life_panel.open("居民的回应")
		life_panel.paragraph(_gift_response)
	)

var _gift_response := ""

func _commit_gift(actor: String, item: String) -> void:
	if not VillageScript.PEOPLE.has(actor):
		_gift_response = "这里没有这位居民。"
		return
	var item_data: Dictionary = _inventory_items().get(item, {})
	if item_data.is_empty() or not item_data.has("gift_id"):
		_gift_response = "这件物品不适合作为礼物。"
		return
	if int(village.bond(actor).gift_day) == farm.day:
		_gift_response = "今天已经送过礼物，明天再来吧。"
		return
	var preview: Dictionary = village.gift_value(actor, str(item_data.gift_id), farm.day)
	if not bool(preview.get("ok", false)):
		_gift_response = str(preview.get("message", "这件礼物无法送出。"))
		return
	if not _consume_gift_item(item, item_data):
		_gift_response = "行囊里已经没有这份礼物了。"
		return
	var result: Dictionary = village.record_gift(actor, str(item_data.gift_id), farm.day)
	if not bool(result.get("ok", false)):
		_gift_response = str(result.get("message", "现在不能送礼。"))
		return
	_gift_response = "%s：%s 友好度 %+d。%s" % [result.name, result.response, int(result.points), "生日让这份心意格外珍贵。" if bool(result.birthday) else ""]
	farm_audio.play("gift")
	if npcs.has(actor): feedback.burst(npcs[actor].node.position, "♡", Color("f298ae"))
	_sync_inventory()
	_update_farm_hud()
	_save_game()
	if inventory_panel != null and inventory_panel.visible: inventory_panel.refresh()


func _consume_gift_item(item_key: String, item: Dictionary) -> bool:
	var gift_id := str(item.get("gift_id", ""))
	var gift_kind := str(item.get("gift_kind", ""))
	match gift_kind:
		"crop":
			if farm.get_harvest_count(gift_id) <= 0: return false
			farm.harvest_inventory[gift_id] -= 1
			farm.inventory_changed.emit("harvest", gift_id, farm.get_harvest_count(gift_id))
		"resource":
			if int(homestead.resources.get(gift_id, 0)) <= 0: return false
			homestead.resources[gift_id] -= 1
		"fruit":
			if not orchard.consume(gift_id): return false
		"fish":
			if not fishing.consume(gift_id): return false
		"meal":
			if not crafting.consume(gift_id): return false
		"animal":
			match gift_id:
				"egg":
					if not animals.consume_egg(): return false
				"duck_egg":
					if not animals.consume_duck_egg(): return false
				"milk":
					if not animals.consume_milk(): return false
				_: return false
		"artisan":
			if not processing.consume(gift_id): return false
		_:
			return false
	return true

func _open_shop() -> void:
	life_panel.open("阿谷的种子铺 · %d 金币" % farm.gold)
	life_panel.action("工匠柜台 · 升级工具", _open_workshop)
	life_panel.action("杉月的农场工程 · 鸡舍与家禽", _open_ranch_shop)
	var season: int = Calendar.date(farm.day).season
	life_panel.paragraph("本季供应 · %s。跨季作物在仍适宜的下一季会继续生长。%s" % [Calendar.SEASONS[season], " 好友价九折已生效。" if village.has_milestone("shopkeeper", 2) else ""])
	for item in current_seed_ids:
		var crop: Dictionary = farm.get_crop_definition(item)
		if not season in crop.seasons: continue
		var growing_window: int = farm.get_crop_growing_window(item)
		var maturity_note := "%d天成熟 · 单收%d金 · 适种%d天" % [int(crop.grow_days), int(crop.sell_price), growing_window]
		if growing_window < int(crop.grow_days):
			maturity_note += " · 季末来不及收"
		life_panel.action("买%s种子 · %d金（%s；已有%d）" % [crop.label, _seed_price(item), maturity_note, farm.get_seed_count(item)], _buy_seed.bind(item))
	life_panel.paragraph("果园树苗全年供应，四个季节各有一种果树结果。树苗不需浇水，栽下28天后成熟。")
	for tree_id in Orchard.TREE_TYPES:
		var tree: Dictionary = Orchard.TREE_TYPES[tree_id]
		var price := _sapling_price(str(tree_id))
		life_panel.action("购买%s · %d金币（已有%d）" % [tree.sapling_name, price, int(orchard.saplings.get(tree_id, 0))], _buy_sapling.bind(str(tree_id)))


func _seed_price(item: String) -> int:
	var base := int(farm.get_crop_definition(item).get("seed_price", 15))
	return maxi(1, floori(base * 0.9)) if village.has_milestone("shopkeeper", 2) else base

func _buy_seed(item: String) -> void:
	var result: Dictionary = farm.buy_seed(item, 1, _seed_price(item))
	_open_shop()
	life_panel.paragraph("购买成功。" if result.ok else result.message)
	_update_farm_hud()
	_save_game()


func _sapling_price(tree_id: String) -> int:
	var base := int(Orchard.TREE_TYPES[tree_id].sapling_price)
	return maxi(1, floori(base * 0.9)) if village.has_milestone("shopkeeper", 2) else base


func _buy_sapling(tree_id: String) -> void:
	var result: Dictionary = orchard.buy_sapling(tree_id, farm, _sapling_price(tree_id))
	_sync_inventory()
	_update_farm_hud()
	_open_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _open_ranch_shop() -> void:
	life_panel.open("杉月的农场工程 · %d 金币" % farm.gold)
	if not animals.coop_built:
		life_panel.paragraph("在农场东侧建造一座木鸡舍和围栏。建成后最多饲养%d只鸡。" % Animals.CAPACITY)
		life_panel.action("建造鸡舍 · %d金 / 木材%d / 石料%d" % [Animals.COOP_COST.gold, Animals.COOP_COST.wood, Animals.COOP_COST.stone], _build_coop)
		return
	life_panel.paragraph("鸡舍已建成 · %d / %d只鸡 · 干草%d份。成年鸡在前一天吃饱后会把鸡蛋留在巢箱。" % [animals.chickens.size(), Animals.CAPACITY, animals.hay])
	if animals.chickens.size() + animals.ducks.size() < Animals.CAPACITY:
		life_panel.action("领养一只小鸡 · %d金" % Animals.CHICKEN_PRICE, _buy_chicken)
		life_panel.action("领养一只小鸭 · %d金" % Animals.DUCK_PRICE, _buy_duck)
	life_panel.paragraph("鸡和鸭共用四个鸡舍床位与干草；鸭子长大并吃饱后，会在巢箱留下价值更高的鸭蛋。")
	if not animals.barn_built:
		life_panel.paragraph("也可以在农田东南建造一座大牛棚和围栏，建成后最多饲养%d头奶牛；奶牛吃饱后每天可以挤一桶牛奶。" % Animals.BARN_CAPACITY)
		life_panel.action("建造牛棚 · %d金 / 木材%d / 石料%d" % [Animals.BARN_COST.gold, Animals.BARN_COST.wood, Animals.BARN_COST.stone], _build_barn)
	else:
		life_panel.paragraph("牛棚已建成 · %d / %d头奶牛。前一天吃饱的成年奶牛，第二天可以挤奶。" % [animals.cows.size(), Animals.BARN_CAPACITY])
		if animals.cows.size() < Animals.BARN_CAPACITY:
			life_panel.action("领养一头奶牛 · %d金" % Animals.COW_PRICE, _buy_cow)
	life_panel.action("购买干草×5 · %d金" % (Animals.HAY_PRICE * 5), _buy_hay)
	life_panel.action("返回种子铺", _open_shop)


func _build_barn() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.build_barn(farm, homestead.resources)
	_refresh_animal_world()
	_sync_inventory()
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _buy_cow() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.buy_cow(farm)
	_sync_cow_actors()
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _build_coop() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.build_coop(farm, homestead.resources)
	_refresh_animal_world()
	_sync_inventory()
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _buy_chicken() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.buy_chicken(farm)
	_sync_chicken_actors()
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _buy_duck() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.buy_duck(farm)
	_sync_duck_actors()
	_sync_inventory()
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _buy_hay() -> void:
	if current_map_id != "general_store_interior": return
	var result: Dictionary = animals.buy_hay(farm, 5)
	_update_farm_hud()
	_open_ranch_shop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _open_coop() -> void:
	if not animals.coop_built: return
	life_panel.open("东篱鸡舍 · %d / %d" % [animals.chickens.size() + animals.ducks.size(), Animals.CAPACITY])
	life_panel.paragraph("干草 %d份 · 鸡蛋 %d枚（巢箱 %d）· 鸭蛋 %d枚（巢箱 %d）\n晴天白天，鸡鸭会在围栏里活动；靠近后按F抚摸。" % [animals.hay, animals.eggs, animals.nest_eggs, animals.duck_eggs, animals.duck_nest_eggs])
	if animals.nest_eggs > 0: life_panel.action("收取巢箱里的鸡蛋×%d" % animals.nest_eggs, _collect_eggs)
	if animals.duck_nest_eggs > 0: life_panel.action("收取巢箱里的鸭蛋×%d" % animals.duck_nest_eggs, _collect_duck_eggs)
	if not animals.chickens.is_empty(): life_panel.action("给所有未喂食的小鸡添草", _feed_all_chickens)
	if not animals.ducks.is_empty(): life_panel.action("给所有未喂食的小鸭添草", _feed_all_ducks)
	for entry in animals.chickens:
		life_panel.paragraph("%s · %s · 亲密度%d / 1000\n今天：%s / %s" % [entry.name, "成年" if int(entry.age) >= 1 else "幼年", int(entry.affection), "已抚摸" if int(entry.petted_day) == farm.day else "未抚摸", "已喂食" if int(entry.fed_day) == farm.day else "未喂食"])
		if int(entry.petted_day) != farm.day:
			life_panel.action("在鸡舍里抚摸%s" % entry.name, _pet_chicken_in_coop.bind(str(entry.id)))
	for entry in animals.ducks:
		life_panel.paragraph("%s · %s · 亲密度%d / 1000\n今天：%s / %s" % [entry.name, "成年" if int(entry.age) >= 1 else "幼年", int(entry.affection), "已抚摸" if int(entry.petted_day) == farm.day else "未抚摸", "已喂食" if int(entry.fed_day) == farm.day else "未喂食"])
		if int(entry.petted_day) != farm.day:
			life_panel.action("在鸡舍里抚摸%s" % entry.name, _pet_duck_in_coop.bind(str(entry.id)))


func _feed_all_chickens() -> void:
	var result: Dictionary = animals.feed_all(farm.day)
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _feed_all_ducks() -> void:
	var result: Dictionary = animals.feed_all_ducks(farm.day)
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _pet_chicken_in_coop(id: String) -> void:
	var result: Dictionary = animals.pet(id, farm.day)
	if result.ok and chicken_actors.has(id): chicken_actors[id].show_affection()
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _pet_duck_in_coop(id: String) -> void:
	var result: Dictionary = animals.pet_duck(id, farm.day)
	if result.ok and duck_actors.has(id): duck_actors[id].show_affection()
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _collect_eggs() -> void:
	var result: Dictionary = animals.collect_eggs()
	_sync_inventory()
	_update_farm_hud()
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _collect_duck_eggs() -> void:
	var result: Dictionary = animals.collect_duck_eggs()
	_sync_inventory()
	_update_farm_hud()
	_open_coop()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _open_barn() -> void:
	if not animals.barn_built: return
	life_panel.open("南坡牛棚 · %d / %d" % [animals.cows.size(), Animals.BARN_CAPACITY])
	life_panel.paragraph("干草 %d份 · 背包牛奶 %d桶\n晴天白天，奶牛会在围栏内活动；靠近后按F抚摸或挤奶。" % [animals.hay, animals.milk])
	if not animals.cows.is_empty(): life_panel.action("给所有未喂食的奶牛添草", _feed_all_cows)
	for entry in animals.cows:
		var milk_text := "已挤奶" if int(entry.milked_day) == farm.day else ("可以挤奶" if int(entry.age) >= 1 and (int(entry.fed_day) == farm.day or int(entry.fed_day) == farm.day - 1) else "今天无奶")
		life_panel.paragraph("%s · %s · 亲密度%d / 1000\n今天：%s / %s / %s" % [entry.name, "成年" if int(entry.age) >= 1 else "小牛", int(entry.affection), "已抚摸" if int(entry.petted_day) == farm.day else "未抚摸", "已喂食" if int(entry.fed_day) == farm.day else "未喂食", milk_text])
		var id := str(entry.id)
		if int(entry.petted_day) != farm.day:
			life_panel.action("在牛棚里抚摸%s" % entry.name, _pet_cow_in_barn.bind(id))
		if int(entry.age) >= 1 and int(entry.milked_day) != farm.day:
			life_panel.action("给%s挤奶" % entry.name, _milk_cow_in_barn.bind(id))


func _feed_all_cows() -> void:
	var result: Dictionary = animals.feed_all_cows(farm.day)
	_open_barn()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _pet_cow_in_barn(id: String) -> void:
	var result: Dictionary = animals.pet_cow(id, farm.day)
	if result.ok and cow_actors.has(id): cow_actors[id].show_affection()
	_open_barn()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _milk_cow_in_barn(id: String) -> void:
	var result: Dictionary = animals.milk_cow(id, farm.day)
	_sync_inventory()
	_update_farm_hud()
	_open_barn()
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _open_processing_machine(cell: Vector2i) -> void:
	var machine_id: String = farm.structure_at(cell)
	if not Processing.is_machine(machine_id): return
	var machine: Dictionary = Processing.MACHINES[machine_id]
	life_panel.open(str(machine.name))
	life_panel.paragraph(str(machine.description))
	var job: Dictionary = processing.job_at(cell)
	if not job.is_empty():
		var output: Dictionary = processing.product_definition(str(job.output), farm)
		if bool(job.ready):
			life_panel.paragraph("加工完成：%s。" % output.name)
			life_panel.action("收取%s" % output.name, _collect_processed.bind(cell))
		else:
			life_panel.paragraph("正在加工%s，明早可以收取。" % output.name)
		return
	if machine_id == "mayo_machine":
		life_panel.paragraph("背包鸡蛋：%d枚 · 鸭蛋：%d枚。" % [animals.eggs, animals.duck_eggs])
		if animals.eggs > 0: life_panel.action("放入一枚鸡蛋", _start_processing.bind(cell, machine_id, "egg"))
		if animals.duck_eggs > 0: life_panel.action("放入一枚鸭蛋", _start_processing.bind(cell, machine_id, "duck_egg"))
	elif machine_id == "cheese_press":
		life_panel.paragraph("背包牛奶：%d桶。" % animals.milk)
		if animals.milk > 0: life_panel.action("放入一桶牛奶", _start_processing.bind(cell, machine_id, "milk"))
	else:
		var found := false
		for crop_id in farm.harvest_inventory:
			var amount: int = farm.get_harvest_count(str(crop_id))
			if amount <= 0: continue
			found = true
			var crop: Dictionary = farm.get_crop_definition(str(crop_id))
			life_panel.action("放入%s（已有%d）" % [crop.label, amount], _start_processing.bind(cell, machine_id, str(crop_id)))
		if not found: life_panel.paragraph("背包里没有可以腌制的作物。")


func _start_processing(cell: Vector2i, machine_id: String, input_id: String) -> void:
	var result: Dictionary = processing.start(cell, machine_id, input_id, farm.day, farm, animals)
	_sync_inventory()
	world.queue_redraw()
	_open_processing_machine(cell)
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _collect_processed(cell: Vector2i) -> void:
	var result: Dictionary = processing.collect(cell, farm)
	_sync_inventory()
	world.queue_redraw()
	_open_processing_machine(cell)
	life_panel.paragraph(str(result.message))
	if result.ok: _save_game()


func _refresh_animal_world() -> void:
	for cached_world in _world_cache.values():
		cached_world.set_animal_state(animals)
		cached_world.queue_redraw()
	world.set_animal_state(animals)
	_refresh_animal_collisions()
	_sync_chicken_actors()
	_sync_cow_actors()
	_refresh_orchard_world()


func _refresh_orchard_world() -> void:
	for cached_world in _world_cache.values():
		cached_world.set_orchard_state(orchard)
	if world != null: world.set_orchard_state(orchard)
	_refresh_animal_collisions()
	if pet != null: pet.rebuild_grid()


func _open_workshop() -> void:
	life_panel.open("工匠柜台 · %d 金币" % farm.gold)
	life_panel.paragraph("带回矿石和煤炭，委托工匠锻造。铜镐可开采第二层，铁镐可进入第三层。升级锄头和浇水壶可减少体力消耗并加快动作。出货箱会保留铜矿、铁矿和煤炭。")
	for tool in ["pickaxe", "hoe", "water"]:
		var cost: Dictionary = mining.upgrade_cost(tool)
		var label: String = {"pickaxe": "镐子", "hoe": "锄头", "water": "浇水壶"}[tool]
		if cost.is_empty(): life_panel.paragraph(label + " · 已达铁级")
		else: life_panel.action("%s → %s级 · %d 金 / %s×5 / 煤炭×%d" % [label, "铜" if int(mining.tools[tool]) == 0 else "铁", cost.gold, Homestead.RESOURCE_NAMES[cost.ore], cost.coal], _upgrade_tool.bind(tool))


func _open_fishing_rod_shop() -> void:
	life_panel.open("老江的海边渔具铺 · %d 金币" % farm.gold)
	var current: Dictionary = fishing.rod()
	var slot_info := "鱼饵槽已开放" if bool(current.bait_slot) else "无鱼饵槽"
	if int(current.tackle_slots) > 0: slot_info += " · 浮标槽已开放"
	else: slot_info += " · 无浮标槽"
	life_panel.paragraph("当前装备：%s · %s" % [str(current.name), slot_info])
	var next: Dictionary = fishing.next_rod()
	if next.is_empty():
		life_panel.paragraph("鱼竿已经升级到最高级。")
	else:
		var offer := "%s · %d 金币 · 钓鱼%d级解锁 · %s" % [str(next.name), int(next.price), int(next.skill_level), "鱼饵与浮标槽" if int(next.tackle_slots) > 0 else "鱼饵槽"]
		if skills.level("fishing") < int(next.skill_level):
			life_panel.paragraph("下一阶：" + offer)
		else:
			life_panel.action("购买" + offer, _upgrade_fishing_rod)
	if bool(current.bait_slot):
		life_panel.paragraph("鱼饵库存：%d · 每10份50金币；装有鱼饵时，每次抛竿等待时间减半。" % fishing.bait_count)
		life_panel.action("购买鱼饵 ×10 · 50金币", _buy_fishing_bait)
	if int(current.tackle_slots) > 0:
		if skills.level("fishing") < int(Fishing.TACKLES.cork_bobber.skill_level):
			life_panel.paragraph("软木浮标 · 钓鱼%d级解锁 · 750金币 · 操作条加宽5%%。" % int(Fishing.TACKLES.cork_bobber.skill_level))
		elif fishing.cork_bobber_owned:
			life_panel.action("取下软木浮标" if fishing.cork_bobber_equipped else "装上软木浮标", _toggle_cork_bobber)
		else:
			life_panel.action("购买并装上软木浮标 · 750金币 · 操作条加宽5%", _buy_cork_bobber)
	life_panel.action("以后再来", _open_dialogue.bind("fisherman"))


func _upgrade_fishing_rod() -> void:
	if current_map_id != "beach": return
	var result: Dictionary = fishing.upgrade_rod(farm, skills.level("fishing"))
	_sync_inventory()
	_update_farm_hud()
	_open_fishing_rod_shop()
	life_panel.paragraph(str(result.message))
	if bool(result.get("ok", false)): _save_game()


func _buy_fishing_bait() -> void:
	if current_map_id != "beach": return
	var result: Dictionary = fishing.buy_bait(farm, 10)
	_sync_inventory()
	_update_farm_hud()
	_open_fishing_rod_shop()
	life_panel.paragraph(str(result.message))
	if bool(result.get("ok", false)): _save_game()


func _buy_cork_bobber() -> void:
	if current_map_id != "beach": return
	var result: Dictionary = fishing.buy_cork_bobber(farm, skills.level("fishing"))
	_sync_inventory()
	_update_farm_hud()
	_open_fishing_rod_shop()
	life_panel.paragraph(str(result.message))
	if bool(result.get("ok", false)): _save_game()


func _toggle_cork_bobber() -> void:
	if current_map_id != "beach" or not fishing.cork_bobber_owned or int(fishing.rod().tackle_slots) <= 0: return
	fishing.cork_bobber_equipped = not fishing.cork_bobber_equipped
	_update_farm_hud()
	_open_fishing_rod_shop()
	life_panel.paragraph("软木浮标已装配。" if fishing.cork_bobber_equipped else "软木浮标已收进行囊。")
	_save_game()


func _upgrade_tool(tool: String) -> void:
	if current_map_id != "general_store_interior": return
	var success: bool = mining.upgrade(tool, farm, homestead.resources)
	_sync_inventory()
	_update_farm_hud()
	_open_workshop()
	life_panel.paragraph("锻造完成，升级后的工具已放回背包。" if success else "金币或材料不足，未扣除任何物品。")
	if success: _save_game()

func _open_festival() -> void:
	life_panel.open("花溪镇公告板")
	life_panel.action("社区修复计划 · %d / %d" % [community.completed.size(), Community.BUNDLES.size()], _open_community_board)
	var event := Calendar.festival(farm.day)
	if event.is_empty():
		life_panel.paragraph("今天没有节日。每一季我们都会相聚，带上你亲手种的收获吧。")
		life_panel.action("查看日历", _open_calendar)
		return
	if event.id == "blossom":
		if village.claimed.has(str(farm.day)):
			life_panel.paragraph("春日寻花活动已经完成，和大家一起继续享受节日吧。")
			return
		if village.festival_hunt_complete(farm.day):
			life_panel.paragraph("六枚春日印花都找齐了！活动奖励已经准备好。\n%s" % event.activity)
			life_panel.action("领取春日会奖励", _join_festival)
		else:
			life_panel.paragraph("镇上藏了六枚春日印花。走进场景寻找它们，限时60秒；找到全部印花后回到公告板领取奖励。\n\n%s" % event.activity)
			life_panel.action("开始寻花挑战", _start_spring_festival_hunt)
		return
	life_panel.paragraph("%s\n\n%s。\n奖励 %d 金币，居民友好度 +40。每年每场活动只可领奖一次。" % [event.name, event.activity, event.reward])
	life_panel.action("参加活动 / 领取奖励", _join_festival)


func _start_spring_festival_hunt() -> void:
	if current_map_id != "town_square" or village.festival_hunt_complete(farm.day): return
	life_panel.close()
	if festival_hunt != null: festival_hunt.queue_free()
	festival_hunt = SpringFestivalHuntScript.new()
	festival_hunt.game = self
	add_child(festival_hunt)
	festival_hunt.start()
	queued_use = ""
	queued_use_cell = Vector2i(-1, -1)
	_set_status("春日寻花开始：在花溪镇走近印花即可收集。")


func _on_spring_hunt_finished(success: bool, found_count: int, elapsed_seconds: float) -> void:
	if success and village.record_spring_festival_hunt(farm.day, found_count, elapsed_seconds):
		_set_status("找齐六枚春日印花！返回公告板领取节日奖励。")
		_save_game()
	elif not success:
		_set_status("时间到了，今天仍可返回公告板再试一次。")


func _open_community_center() -> void:
	life_panel.open("花溪社区会堂")
	if community.grand_reward:
		life_panel.paragraph("社区会堂已经修复，镇民们在这里筹备聚会和节庆。它如今是花溪镇共同生活的地方。")
	else:
		life_panel.paragraph("这座会堂曾是镇民相聚的地方，现在屋顶和门窗都需要修缮。把农产、鱼获、林地材料和矿物交到东侧公告板，帮助大家一点点恢复它。")
	life_panel.paragraph("修复进度 · %d / %d 组物资" % [community.completed.size(), Community.BUNDLES.size()])
	life_panel.action("查看公告板与捐献清单", _open_community_board)


func _open_community_board() -> void:
	life_panel.open("花溪社区修复 · %d / %d" % [community.completed.size(), Community.BUNDLES.size()])
	life_panel.paragraph("把农场、河海、林地和矿洞的物资逐项交到公告板。每次捐献都会记下进度，可以分几天慢慢完成。")
	for id in Community.BUNDLES:
		var bundle: Dictionary = Community.BUNDLES[id]
		if community.completed.has(id):
			life_panel.paragraph("✓ %s · 已完成" % bundle.name)
			continue
		life_panel.paragraph(str(bundle.name))
		for item_index in bundle.items.size():
			var item: Array = bundle.items[item_index]
			var given := community.donated_count(str(id), item_index)
			var required := int(item[2])
			var held := community.count_item(item, farm, homestead, fishing)
			life_panel.paragraph("%s · 已交 %d/%d · 持有 %d" % [community.item_name(item, farm, homestead, fishing), given, required, held])
			if given < required and held > 0:
				life_panel.action("捐献%s · %d件" % [community.item_name(item, farm, homestead, fishing), mini(held, required - given)], _donate_bundle_item.bind(str(id), item_index))
		if community.can_complete(str(id), farm, homestead, fishing):
			life_panel.action("备齐后一次捐献 · " + str(bundle.name), _donate_bundle.bind(str(id)))
	if community.grand_reward: life_panel.paragraph("花溪社区的四项修复已经全部完成。镇民会一直记得你的帮助。")
	life_panel.action("返回公告板", _open_festival)


func _donate_bundle(id: String) -> void:
	var result: Dictionary = community.donate(id, farm, homestead, fishing)
	_apply_community_result(result)


func _donate_bundle_item(id: String, item_index: int) -> void:
	var result: Dictionary = community.donate_item(id, item_index, farm, homestead, fishing)
	_apply_community_result(result)
	_open_community_board()
	var message := str(result.get("message", ""))
	if result.get("bundle_complete", false): message = "%s完成，奖励已经发放。" % result.name
	life_panel.paragraph(message)


func _apply_community_result(result: Dictionary) -> void:
	if not result.get("ok", false) or result.get("partial", false):
		if result.get("ok", false):
			if world != null: world.set_community_state(community)
			_sync_inventory()
			_save_game()
		return
	var reward: Array = result.reward
	if reward[0] == "gold":
		farm.gold += int(reward[1])
		farm.gold_changed.emit(farm.gold, int(reward[1]))
	elif reward[0] == "backpack": inventory_state.expand(int(reward[1]))
	if result.grand:
		farm.gold += 1000
		farm.gold_changed.emit(farm.gold, 1000)
		for actor in VillageScript.PEOPLE:
			var relation: Dictionary = village.bond(str(actor))
			relation.points = mini(1000, int(relation.points) + 100)
	if world != null: world.set_community_state(community)
	_sync_inventory()
	_update_farm_hud()
	_save_game()

func _join_festival() -> void:
	if current_map_id != "town_square": return
	life_panel.open("节日活动")
	life_panel.paragraph(village.join_festival(farm))
	_update_farm_hud()
	_save_game()

func _save_game() -> bool:
	if not autosave_enabled: return false
	var data := {"version": 1, "world_layout": 2 if continuous_world_enabled else 3, "farm": farm.snapshot(), "village": village.snapshot(), "homestead": homestead.snapshot(), "mining": mining.snapshot(), "fishing": fishing.snapshot(), "community": community.snapshot(), "crafting": crafting.snapshot(), "skills": skills.snapshot(), "animals": animals.snapshot(), "processing": processing.snapshot(), "combat": combat.snapshot(), "orchard": orchard.snapshot(), "inventory_layout": inventory_state.snapshot(), "map": current_map_id, "cell": [player_cell.x, player_cell.y], "appearance": player.get_customization(), "clock": clock_minutes, "energy": energy, "fish_count": fish_count}
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
	if not continuous_world_enabled: preload("res://scripts/region_world_builder.gd").migrate(data, navigation)
	farm.restore(data.farm)
	village.restore(data.village)
	homestead.restore(data.get("homestead", {}))
	mining.restore(data.get("mining", {}))
	if data.has("fishing"): fishing.restore(data.fishing)
	else: fish_count = maxi(0, int(data.get("fish_count", 0)))
	community.restore(data.get("community", {}))
	crafting.restore(data.get("crafting", {}))
	skills.restore(data.get("skills", {}))
	animals.restore(data.get("animals", {}))
	processing.restore(data.get("processing", {}))
	combat.restore(data.get("combat", {}))
	orchard.restore(data.get("orchard", {}))
	_refresh_animal_world()
	for cached_world in _world_cache.values(): cached_world.set_processing_state(processing)
	pet.rebuild_grid()
	clock_minutes = clampi(int(data.get("clock", 360)), 360, 1430)
	energy = clampi(int(data.get("energy", 100)), 0, _energy_cap())
	if data.has("inventory_layout"): inventory_state.restore(data.inventory_layout)
	_sync_inventory()
	var restored_item: Dictionary = _inventory_items().get(str(inventory_state.hotbar[inventory_state.selected_hotbar]), {})
	if str(restored_item.get("kind", "")) == "tool": current_tool = str(restored_item.get("tool_id", current_tool))
	elif str(restored_item.get("kind", "")) == "sapling":
		current_tool = "sapling"
		current_sapling_id = str(restored_item.get("tree_id", "apple"))
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
	for row in data.get("farm", {}).get("structures", []):
		row.x = int(row.x) + farm_offset.x
		row.y = int(row.y) + farm_offset.y
	for row in data.get("processing", {}).get("jobs", []):
		row.x = int(row.x) + farm_offset.x
		row.y = int(row.y) + farm_offset.y

func _read_save(path: String):
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data

func _valid_save(data) -> bool:
	if not data is Dictionary or not _save_number(data.get("version")) or int(data.version) != 1: return false
	if data.has("world_layout") and (not _save_number(data.world_layout) or int(data.world_layout) not in [1, 2, 3]): return false
	if data.has("homestead") and not Homestead.valid(data.homestead): return false
	if data.has("mining") and not Mining.valid(data.mining): return false
	if data.has("fishing") and not Fishing.valid(data.fishing): return false
	if data.has("community") and not Community.valid(data.community): return false
	if data.has("crafting") and not Crafting.valid(data.crafting): return false
	if data.has("skills") and not Skills.valid(data.skills): return false
	if data.has("animals") and not Animals.valid(data.animals): return false
	if data.has("processing") and not Processing.valid(data.processing): return false
	if data.has("combat") and not Combat.valid(data.combat): return false
	if data.has("orchard") and not Orchard.valid(data.orchard): return false
	if data.has("inventory_layout") and not InventoryStateScript.valid(data.inventory_layout): return false
	if not data.get("farm") is Dictionary or not data.get("village") is Dictionary: return false
	if data.village.has("hunts") and not data.village.hunts is Dictionary: return false
	if data.has("fish_count") and (not _save_number(data.fish_count) or float(data.fish_count) < 0): return false
	for hunt in data.village.get("hunts", {}).values():
		if not hunt is Dictionary or not hunt.has_all(["found", "seconds"]): return false
		if not _save_number(hunt.found) or not _save_number(hunt.seconds): return false
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
	var saved_structures := {}
	if saved_farm.has("structures"):
		if not saved_farm.structures is Array: return false
		for structure in saved_farm.structures:
			if not structure is Dictionary or not structure.has_all(["x", "y", "id"]): return false
			if not _save_number(structure.x) or not _save_number(structure.y) or str(structure.id) not in FarmStateScript.STRUCTURE_IDS: return false
			saved_structures["%d,%d" % [int(structure.x), int(structure.y)]] = str(structure.id)
	if data.has("processing"):
		for job in data.processing.jobs:
			var key := "%d,%d" % [int(job.x), int(job.y)]
			if str(saved_structures.get(key, "")) != str(job.machine): return false
			var output_id := str(job.output)
			if output_id.begins_with("pickles:") and not farm.crop_definitions.has(output_id.trim_prefix("pickles:")): return false
		for product_id in data.processing.products:
			if str(product_id).begins_with("pickles:") and not farm.crop_definitions.has(str(product_id).trim_prefix("pickles:")): return false
	for key in ["bonds", "visits", "claimed"]:
		if not data.village.get(key) is Dictionary: return false
	if not data.village.get("request_days", {}) is Dictionary: return false
	if data.village.has("milestones"):
		if not data.village.milestones is Dictionary: return false
		for actor in data.village.milestones:
			if not VillageScript.PEOPLE.has(actor) or not _save_number(data.village.milestones[actor]) or int(data.village.milestones[actor]) < 0 or int(data.village.milestones[actor]) > 2: return false
	for day in data.village.get("request_days", {}).values():
		if not _save_number(day) or float(day) < 0: return false
	for relation in data.village.bonds.values():
		if not relation is Dictionary or not relation.has_all(["points", "talk_day", "gift_day"]): return false
		for key in ["points", "talk_day", "gift_day"]:
			if not _save_number(relation[key]): return false
	for visits in data.village.visits.values():
		if not visits is Array: return false
	var saved_map := str(data.get("map", ""))
	var saved_layout := int(data.get("world_layout", 1))
	var map_is_available := navigation.has_map(saved_map)
	# Old continuous-world saves are converted to regional coordinates before
	# restoring the player, so validating them must not construct that whole map.
	var map_can_be_migrated := saved_layout == 2 and saved_map == "valley_world" and not continuous_world_enabled
	return (map_is_available or map_can_be_migrated) and data.get("cell") is Array and data.cell.size() == 2 and _save_number(data.cell[0]) and _save_number(data.cell[1]) and data.get("appearance") is Dictionary

func _save_number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))
