extends Control
## Regras: cards numerados 1/2/3 + botão COMEÇAR com contagem "PREPARE-SE 3,2,1".


var _rules_view: Control
var _countdown_view: Control
var _countdown_label: Label

func _ready() -> void:
	GameManager.current_state = GameManager.State.RULES
	UIStyle.style_bg(self)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	outer.add_child(UIStyle.make_brand_header())

	_rules_view = _build_rules_view()
	outer.add_child(_rules_view)

	_countdown_view = _build_countdown_view()
	_countdown_view.visible = false
	outer.add_child(_countdown_view)

func _build_rules_view() -> Control:
	var container := CenterContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.custom_minimum_size = Vector2(780, 0)
	container.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 26)
	margin.add_child(root)

	root.add_child(UIStyle.make_eyebrow("Como jogar"))
	root.add_child(UIStyle.make_title("As regras", 56))
	root.add_child(_spacer(6))

	root.add_child(UIStyle.make_rule_row(1, "Toque no botão que ACENDER o mais rápido possível."))
	root.add_child(UIStyle.make_rule_row(2, "Cada acerto vale pontos. Sequências rápidas dão multiplicador."))
	root.add_child(UIStyle.make_rule_row(3, "Você tem 30 segundos. Boa sorte!"))

	root.add_child(_spacer(10))

	var start_button := UIStyle.make_primary_button("COMEÇAR")
	start_button.pressed.connect(_on_start_pressed)
	root.add_child(start_button)

	return container

func _build_countdown_view() -> Control:
	var container := CenterContainer.new()
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 30)
	container.add_child(root)

	root.add_child(UIStyle.make_eyebrow("Prepare-se"))

	_countdown_label = UIStyle.make_title("3", 220, UIStyle.GREEN)
	root.add_child(_countdown_label)

	return container

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _on_start_pressed() -> void:
	Audio.play_click()
	_rules_view.visible = false
	_countdown_view.visible = true
	_show_countdown_glow()
	_run_countdown()

## Central green glow from the Figma "Prepare-se / 3" screen. Added straight
## onto this Control (not inside the CenterContainer, which would ignore
## anchors) and placed just above the base background so it sits behind the
## number. Fades in for a smooth entrance.
func _show_countdown_glow() -> void:
	if not ResourceLoader.exists("res://assets/bg/bg_countdown.png"):
		return
	var glow := TextureRect.new()
	glow.texture = load("res://assets/bg/bg_countdown.png")
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.anchor_right = 1.0
	glow.anchor_bottom = 1.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate.a = 0.0
	add_child(glow)
	# Sit right above the base bg layers (index 0/1), below the outer content.
	move_child(glow, 2)
	var tween := create_tween()
	tween.tween_property(glow, "modulate:a", 1.0, 0.25)

func _run_countdown() -> void:
	for n in [3, 2, 1]:
		_countdown_label.text = str(n)
		_countdown_label.scale = Vector2(0.6, 0.6)
		_countdown_label.pivot_offset = _countdown_label.size / 2.0
		Audio.play_countdown()
		var tween := create_tween()
		tween.tween_property(_countdown_label, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(1.0).timeout
	Audio.play_go()
	GameManager.start_game()
