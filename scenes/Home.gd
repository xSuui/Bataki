extends Control
## Home (attract screen). Layout order matches Figma: small eyebrow at the
## top, big BATAKI wordmark + tagline + CTA in the middle, Branch77 footer
## branding pinned at the bottom (this screen is the only one where the
## Branch77 mark sits at the bottom instead of the top).


func _ready() -> void:
	GameManager.current_state = GameManager.State.HOME
	UIStyle.style_bg(self)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_top", 90)
	root.add_child(top_margin)
	var eyebrow := UIStyle.make_eyebrow("Arcade · Reaction Game")
	top_margin.add_child(eyebrow)

	var mid_spacer_top := Control.new()
	mid_spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid_spacer_top)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 28)
	var center_wrap := CenterContainer.new()
	root.add_child(center_wrap)
	center_wrap.add_child(center)

	var title := UIStyle.make_title("BATAKI", 130, UIStyle.TEXT_WHITE)
	center.add_child(title)

	var underline := ColorRect.new()
	underline.color = UIStyle.GREEN
	underline.custom_minimum_size = Vector2(220, 5)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var underline_wrap := CenterContainer.new()
	underline_wrap.add_child(underline)
	center.add_child(underline_wrap)

	var tagline := UIStyle.make_label("Acenda. Toque. Repita.", 30, UIStyle.TEXT_MUTED_LIGHT)
	center.add_child(tagline)

	var tagline2 := RichTextLabel.new()
	tagline2.bbcode_enabled = true
	tagline2.fit_content = true
	tagline2.scroll_active = false
	tagline2.custom_minimum_size = Vector2(600, 40)
	tagline2.add_theme_font_size_override("normal_font_size", 30)
	tagline2.add_theme_color_override("default_color", UIStyle.TEXT_MUTED_LIGHT)
	tagline2.text = "[center]Teste seu reflexo em [color=#93FC56]30 segundos[/color].[/center]"
	center.add_child(tagline2)

	center.add_child(_spacer(10))

	var play_button := UIStyle.make_primary_button("JOGAR", 170)
	play_button.custom_minimum_size.x = 500
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.pressed.connect(_on_play_pressed)
	var play_wrap := CenterContainer.new()
	play_wrap.add_child(play_button)
	center.add_child(play_wrap)

	var hint := UIStyle.make_eyebrow("Toque para começar", UIStyle.TEXT_MUTED)
	center.add_child(hint)

	var mid_spacer_bottom := Control.new()
	mid_spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid_spacer_bottom)

	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	var footer_wrap := MarginContainer.new()
	footer_wrap.add_theme_constant_override("margin_bottom", 60)
	footer_wrap.add_child(footer)
	root.add_child(footer_wrap)
	footer.add_child(UIStyle.make_brand_header())

	_pulse(play_button)

func _on_play_pressed() -> void:
	Audio.play_click()
	GameManager.start_form()

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

## Subtle "breathing" scale animation on the CTA so the idle totem still
## feels alive and inviting.
func _pulse(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", Vector2(1.04, 1.04), 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
