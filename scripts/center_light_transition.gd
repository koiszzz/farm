class_name CenterLightTransition
extends CanvasLayer

## Covers the previous scene, swaps while fully black, then reveals the newly
## loaded scene from the centre like eyes adjusting after leaving darkness.

const COVER_SECONDS := 0.16
const BLACK_HOLD_SECONDS := 0.04
const REVEAL_SECONDS := 0.50

var overlay: ColorRect
var material_instance: ShaderMaterial
var running := false


func _ready() -> void:
	layer = 200
	overlay = ColorRect.new()
	overlay.name = "CenterLightReveal"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	material_instance = ShaderMaterial.new()
	material_instance.shader = preload("res://assets/art/runtime_generated/center_light_reveal.gdshader")
	material_instance.set_shader_parameter("blackness", 0.0)
	material_instance.set_shader_parameter("reveal_radius", -0.1)
	overlay.material = material_instance
	overlay.visible = false
	add_child(overlay)


func play(scene_swap: Callable, reveal_center := Vector2(0.5, 0.5)) -> void:
	if running:
		return
	running = true
	overlay.visible = true
	material_instance.set_shader_parameter("reveal_center", reveal_center)
	material_instance.set_shader_parameter("reveal_radius", -0.1)
	material_instance.set_shader_parameter("blackness", 0.0)
	var cover := create_tween()
	cover.tween_method(_set_blackness, 0.0, 1.0, COVER_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await cover.finished
	if scene_swap.is_valid():
		scene_swap.call()
	await get_tree().create_timer(BLACK_HOLD_SECONDS).timeout
	var reveal := create_tween()
	reveal.tween_method(_set_reveal_radius, -0.1, 1.25, REVEAL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await reveal.finished
	overlay.visible = false
	material_instance.set_shader_parameter("blackness", 0.0)
	running = false


func _set_blackness(value: float) -> void:
	material_instance.set_shader_parameter("blackness", value)


func _set_reveal_radius(value: float) -> void:
	material_instance.set_shader_parameter("reveal_radius", value)
