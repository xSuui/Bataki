extends CanvasLayer
## Transition
## ----------
## Small fade-to-black between scene changes so the totem feels smooth
## instead of doing hard cuts (matches the reference video's screen
## transitions). Lives on its own CanvasLayer on top of everything so it
## survives `change_scene_to_file` calls untouched.

var _rect: ColorRect

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)

## Fades to black, swaps the scene, fades back in. ~0.35s round trip by
## default — quick enough to not feel sluggish on a totem, but enough to
## soften the cut.
func change_scene(path: String, fade_out: float = 0.16, fade_in: float = 0.20) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP # block taps mid-transition
	var out_tween := create_tween()
	out_tween.tween_property(_rect, "color:a", 1.0, fade_out)
	await out_tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame # let the new scene finish entering the tree

	var in_tween := create_tween()
	in_tween.tween_property(_rect, "color:a", 0.0, fade_in)
	await in_tween.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
