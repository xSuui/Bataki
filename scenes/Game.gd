extends Control
## Jogo: grade 3x3, um botão aceso por vez. UI-only file — all scoring math
## lives in GameManager; this script just renders state and forwards taps.


var _score_box: PanelContainer
var _timer_box: PanelContainer
var _streak_row: HBoxContainer
var _streak_label: Label
var _combo_badge_slot: Control
var _combo_popup: Label
var _grid_buttons: Array = []

func _ready() -> void:
	GameManager.current_state = GameManager.State.GAME
	UIStyle.style_bg(self)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 22)
	add_child(root)

	root.add_child(_build_hud())

	var streak_wrap := CenterContainer.new()
	_streak_row = HBoxContainer.new()
	_streak_row.add_theme_constant_override("separation", 12)
	streak_wrap.add_child(_streak_row)
	root.add_child(streak_wrap)

	var seq_eyebrow := UIStyle.make_eyebrow("Sequência", UIStyle.TEXT_MUTED)
	_streak_row.add_child(seq_eyebrow)
	_streak_label = Label.new()
	_streak_label.text = "0"
	_streak_label.add_theme_color_override("font_color", UIStyle.TEXT_WHITE)
	_streak_label.add_theme_font_size_override("font_size", 24)
	_streak_row.add_child(_streak_label)
	_combo_badge_slot = Control.new()
	_combo_badge_slot.custom_minimum_size = Vector2(0, 0)
	_streak_row.add_child(_combo_badge_slot)

	var grid_margin := MarginContainer.new()
	grid_margin.add_theme_constant_override("margin_left", 50)
	grid_margin.add_theme_constant_override("margin_right", 50)
	grid_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(grid_margin)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 28)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_margin.add_child(grid)

	for i in range(GameManager.GRID_SIZE):
		var b := UIStyle.make_grid_button()
		b.pressed.connect(_on_grid_button_pressed.bind(i))
		# Wrap in a 1:1 AspectRatioContainer so the target is always a true
		# circle, regardless of how the GridContainer stretches the cell.
		var aspect := AspectRatioContainer.new()
		aspect.ratio = 1.0
		aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
		aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		aspect.add_child(b)
		grid.add_child(aspect)
		_grid_buttons.append(b)

	var sair_button := UIStyle.make_text_button("Sair")
	sair_button.pressed.connect(func(): GameManager.go_home())
	var sair_wrap := CenterContainer.new()
	sair_wrap.add_theme_constant_override("margin_bottom", 30)
	sair_wrap.add_child(sair_button)
	root.add_child(sair_wrap)

	_combo_popup = UIStyle.make_title("COMBO!", 70, UIStyle.GREEN)
	_combo_popup.set_anchors_preset(Control.PRESET_CENTER)
	_combo_popup.modulate.a = 0.0
	_combo_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combo_popup)

	GameManager.score_changed.connect(_on_score_changed)
	GameManager.combo_triggered.connect(_on_combo)
	GameManager.round_time_changed.connect(_on_time_changed)
	GameManager.round_finished.connect(func(): Audio.play_finish())

	_light_up(GameManager.pick_new_target(-1))
	GameManager.begin_round_timer()

func _build_hud() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 24)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	_score_box = UIStyle.make_hud_box("Pontos", "0", UIStyle.GREEN)
	_score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_score_box)

	_timer_box = UIStyle.make_hud_box("Tempo", "%ds" % int(GameManager.GAME_DURATION), UIStyle.TEXT_WHITE)
	_timer_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_timer_box)

	return margin

func _on_grid_button_pressed(index: int) -> void:
	if index == GameManager.active_index:
		GameManager.register_hit()
		Audio.play_hit()
		_burst_particles(_grid_buttons[index], UIStyle.GREEN)
		_flash_button(_grid_buttons[index], UIStyle.SUCCESS_COLOR)
		await get_tree().create_timer(0.12).timeout
		if not is_inside_tree():
			return
		_light_up(GameManager.pick_new_target(index))
	else:
		GameManager.register_miss()
		Audio.play_miss()
		_flash_button(_grid_buttons[index], UIStyle.ERROR_COLOR)
		_shake_screen()

## Quick particle burst radiating out from a target when it's hit. Built in
## code (CPUParticles2D) so there are no scene/asset dependencies — it spawns,
## fires once, and frees itself.
func _burst_particles(anchor: Control, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.5
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 480.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	p.color = color
	p.z_index = 50
	add_child(p)
	# Center the emitter on the tapped target.
	p.global_position = anchor.global_position + anchor.size / 2.0
	p.emitting = true
	# Self-cleanup: when the one-shot burst finishes, the node frees itself.
	# Using the built-in `finished` signal (instead of a timer capturing `p`)
	# avoids "lambda capture was freed" if the scene changes mid-burst.
	p.finished.connect(p.queue_free)

func _light_up(index: int) -> void:
	for i in range(_grid_buttons.size()):
		if i != index:
			UIStyle.set_grid_button_idle(_grid_buttons[i])
	UIStyle.set_grid_button_lit(_grid_buttons[index], UIStyle.GREEN)
	var b: Button = _grid_buttons[index]
	b.pivot_offset = b.size / 2.0
	b.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.tween_property(b, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash_button(b: Button, color: Color) -> void:
	b.pivot_offset = b.size / 2.0
	var was_active := (_grid_buttons.find(b) == GameManager.active_index)
	UIStyle.set_grid_button_lit(b, color)
	var tween := create_tween()
	tween.tween_property(b, "scale", Vector2(1.12, 1.12), 0.08)
	tween.tween_property(b, "scale", Vector2(1.0, 1.0), 0.12)
	if not was_active:
		await get_tree().create_timer(0.18).timeout
		if is_instance_valid(b):
			UIStyle.set_grid_button_idle(b)

func _on_score_changed(new_score: int, streak: int, multiplier: int) -> void:
	var score_value: Label = _score_box.get_node("VBoxContainer/Value")
	score_value.text = str(new_score)
	_streak_label.text = str(streak)

	for child in _combo_badge_slot.get_children():
		child.queue_free()
	if multiplier > 1:
		_combo_badge_slot.add_child(UIStyle.make_combo_badge(multiplier))

func _shake_screen() -> void:
	var original_pos := position
	var tween := create_tween()
	var offsets := [Vector2(-14, 0), Vector2(12, 0), Vector2(-8, 0), Vector2(6, 0), Vector2(0, 0)]
	for o in offsets:
		tween.tween_property(self, "position", original_pos + o, 0.035)
	tween.tween_property(self, "position", original_pos, 0.035)

func _on_combo(multiplier: int) -> void:
	Audio.play_combo()
	# Bigger celebratory burst from the currently lit target on a combo.
	if GameManager.active_index >= 0 and GameManager.active_index < _grid_buttons.size():
		_burst_particles(_grid_buttons[GameManager.active_index], UIStyle.GREEN_LIGHT)
	_combo_popup.text = "COMBO x%d!" % multiplier
	_combo_popup.modulate.a = 0.0
	_combo_popup.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(_combo_popup, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(_combo_popup, "scale", Vector2(1.2, 1.2), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.4)
	tween.tween_property(_combo_popup, "modulate:a", 0.0, 0.3)
	_flash_screen(UIStyle.GREEN)

func _flash_screen(color: Color) -> void:
	var flash := ColorRect.new()
	flash.color = Color(color.r, color.g, color.b, 0.28)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.35)
	tween.tween_callback(flash.queue_free)

func _on_time_changed(seconds_left: float) -> void:
	var timer_value: Label = _timer_box.get_node("VBoxContainer/Value")
	timer_value.text = "%ds" % int(seconds_left)
	UIStyle.set_hud_box_danger(_timer_box, seconds_left <= 5.0)
